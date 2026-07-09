import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/setlist.dart';
import '../providers/library_provider.dart';
import '../providers/setlist_provider.dart';
import '../services/setlist_share_service.dart';
import 'setlist_detail_screen.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final setlists = context.watch<SetlistProvider>().setlists;

    return Scaffold(
      appBar: AppBar(title: const Text('Setlists')),
      body: setlists.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No setlists yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          : ListView.separated(
              itemCount: setlists.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final setlist = setlists[i];
                return ListTile(
                  title: Text(setlist.name),
                  leading: const Icon(Icons.queue_music),
                  trailing: PopupMenuButton<_Action>(
                    onSelected: (action) {
                      if (action == _Action.rename) {
                        _renameDialog(context, setlist);
                      } else {
                        _confirmDelete(context, setlist);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _Action.rename,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SetlistDetailScreen(setlist: setlist),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMenu(context),
        tooltip: 'New setlist',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<_CreateChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New setlist'),
              onTap: () => Navigator.pop(ctx, _CreateChoice.newSetlist),
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text('Import setlist'),
              subtitle: const Text('From a shared .gigbook-setlist.json file'),
              onTap: () => Navigator.pop(ctx, _CreateChoice.import),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == _CreateChoice.newSetlist) {
      await _createDialog(context);
    } else {
      await _importSetlist(context);
    }
  }

  Future<void> _importSetlist(BuildContext context) async {
    final library = context.read<LibraryProvider>().songs;
    SetlistImportResult? result;
    try {
      result = await SetlistShareService.pickAndParse(library);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
      return;
    }
    if (result == null || !context.mounted) return;

    final setlistProvider = context.read<SetlistProvider>();
    final setlist = await setlistProvider.createSetlist(result.name);
    for (final song in result.matchedSongs) {
      await setlistProvider.addSong(setlist.id!, song.id!);
    }
    if (!context.mounted) return;

    final matchedCount = result.matchedSongs.length;
    final missingCount = result.missingSongs.length;
    final message = missingCount == 0
        ? 'Imported "${result.name}" — $matchedCount songs.'
        : 'Imported "${result.name}" — $matchedCount songs, '
            '$missingCount not found in your library: '
            '${result.missingSongs.join(", ")}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  Future<void> _createDialog(BuildContext context) async {
    final name = await _nameDialog(context, title: 'New setlist');
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<SetlistProvider>().createSetlist(name);
    }
  }

  Future<void> _renameDialog(BuildContext context, Setlist setlist) async {
    final name = await _nameDialog(context,
        title: 'Rename setlist', initial: setlist.name);
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<SetlistProvider>().renameSetlist(setlist.id!, name);
    }
  }

  Future<String?> _nameDialog(BuildContext context,
      {required String title, String initial = ''}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Setlist name'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Setlist setlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete setlist'),
        content: Text(
            'Delete "${setlist.name}"? Songs will not be deleted.'),
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
      await context.read<SetlistProvider>().deleteSetlist(setlist.id!);
    }
  }
}

enum _Action { rename, delete }

enum _CreateChoice { newSetlist, import }
