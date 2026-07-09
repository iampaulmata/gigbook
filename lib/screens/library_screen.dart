import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/drive_sync_provider.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/song_list_tile.dart';
import 'song_view_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final driveSync = context.watch<DriveSyncProvider>();
    var songs = library.filtered;
    if (_favoritesOnly) songs = songs.where((s) => s.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search songs…',
                  border: InputBorder.none,
                ),
                onChanged: library.setQuery,
              )
            : const Text('GigBook'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  library.setQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _favoritesOnly ? Icons.star : Icons.star_outline,
              color: _favoritesOnly
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: _favoritesOnly ? 'Show all' : 'Favourites only',
            onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
          ),
        ],
      ),
      body: Column(
        children: [
          if (driveSync.shouldShowSetupPrompt)
            _DriveSyncPromptBanner(driveSync: driveSync),
          Expanded(
            child: library.loading
                ? const Center(child: CircularProgressIndicator())
                : songs.isEmpty
                    ? _EmptyState(
                        favoritesOnly: _favoritesOnly,
                        hasQuery: library.query.isNotEmpty,
                      )
                    : ListView.separated(
                        itemCount: songs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final song = songs[i];
                          return SongListTile(
                            song: song,
                            onTap: () => _openSong(context, song),
                            onToggleFavorite: () => context
                                .read<LibraryProvider>()
                                .toggleFavorite(song),
                            onDelete: () => _confirmDelete(context, song),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportMenu(context),
        tooltip: 'Import songs',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openSong(BuildContext context, Song song) {
    final settings = context.read<SettingsProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongViewScreen(
          song: song,
          initialShowChords: settings.showChords,
          initialFontSize: settings.fontSize,
          initialScrollSpeed: settings.scrollSpeed,
          initialScrollPxPerBeat: settings.scrollPxPerBeat,
        ),
      ),
    );
  }

  Future<void> _showImportMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<_ImportChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Import files'),
              subtitle: const Text('Pick one or more .cho/.pro/.txt files'),
              onTap: () => Navigator.pop(ctx, _ImportChoice.files),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Import folder'),
              subtitle: const Text('Import every song file in a folder'),
              onTap: () => Navigator.pop(ctx, _ImportChoice.folder),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final library = context.read<LibraryProvider>();
    final result = choice == _ImportChoice.files
        ? await library.importFiles()
        : await library.importFolder();
    if (!context.mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    final imported = result.imported.length;
    final skipped = result.skipped;
    final String message;
    if (imported == 0 && skipped == 0) {
      message = 'No files imported';
    } else {
      final parts = <String>[
        imported == 1 ? '1 song imported' : '$imported songs imported',
      ];
      if (skipped > 0) {
        parts.add(skipped == 1 ? '1 skipped' : '$skipped skipped');
      }
      message = parts.join(' · ');
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete(BuildContext context, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete song'),
        content: Text('Delete "${song.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<LibraryProvider>().deleteSong(song.id!);
    }
  }
}

enum _ImportChoice { files, folder }

class _DriveSyncPromptBanner extends StatelessWidget {
  final DriveSyncProvider driveSync;
  const _DriveSyncPromptBanner({required this.driveSync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(Icons.cloud_outlined, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Auto-sync songs from Google Drive',
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: driveSync.pickRootFolder,
              child: const Text('Set up'),
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onSecondaryContainer),
              tooltip: 'Dismiss',
              onPressed: driveSync.dismissSetupPrompt,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool favoritesOnly;
  final bool hasQuery;

  const _EmptyState({required this.favoritesOnly, required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final String msg;
    if (hasQuery) {
      msg = 'No songs match your search.';
    } else if (favoritesOnly) {
      msg = 'No favourites yet.\nTap the ★ on a song to add it.';
    } else {
      msg = 'No songs yet.\nTap + to import .cho, .pro or .txt files.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
