import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/setlist_provider.dart';
import '../providers/settings_provider.dart';
import 'song_view_screen.dart';

class SetlistDetailScreen extends StatefulWidget {
  final Setlist setlist;
  const SetlistDetailScreen({super.key, required this.setlist});

  @override
  State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs = await context
        .read<SetlistProvider>()
        .getSongs(widget.setlist.id!);
    if (mounted) {
      setState(() {
        _songs = songs;
        _loading = false;
      });
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final song = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, song);
    });
    final ids = _songs.map((s) => s.id!).toList();
    await context
        .read<SetlistProvider>()
        .reorder(widget.setlist.id!, ids);
  }

  Future<void> _removeSong(Song song) async {
    await context
        .read<SetlistProvider>()
        .removeSong(widget.setlist.id!, song.id!);
    setState(() => _songs.remove(song));
  }

  void _openSong(int index) {
    final settings = context.read<SettingsProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongViewScreen(
          song: _songs[index],
          setlistSongs: List.from(_songs),
          setlistIndex: index,
          initialShowChords: settings.showChords,
          initialFontSize: settings.fontSize,
          initialScrollSpeed: settings.scrollSpeed,
        ),
      ),
    );
  }

  Future<void> _showAddSongSheet() async {
    final allSongs = context.read<LibraryProvider>().songs;
    final inSetlist = _songs.map((s) => s.id).toSet();
    final available =
        allSongs.where((s) => !inSetlist.contains(s.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All songs are already in this setlist.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddSongSheet(
        available: available,
        onAdd: (song) async {
          await context
              .read<SetlistProvider>()
              .addSong(widget.setlist.id!, song.id!);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add song',
            onPressed: _showAddSongSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No songs in this setlist yet.\nTap + to add some.',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: _songs.length,
                  onReorder: _reorder,
                  itemBuilder: (context, i) {
                    final song = _songs[i];
                    return ListTile(
                      key: ValueKey(song.id),
                      leading: Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      title: Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: song.artist.isNotEmpty
                          ? Text(song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove from setlist',
                            onPressed: () => _removeSong(song),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                      onTap: () => _openSong(i),
                    );
                  },
                ),
    );
  }
}

// ─── Add song bottom sheet ─────────────────────────────────────────────────────

class _AddSongSheet extends StatefulWidget {
  final List<Song> available;
  final Future<void> Function(Song) onAdd;

  const _AddSongSheet({required this.available, required this.onAdd});

  @override
  State<_AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<_AddSongSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.available
        : widget.available
            .where((s) =>
                s.title.toLowerCase().contains(_query) ||
                s.artist.toLowerCase().contains(_query))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const ListTile(title: Text('Add song to setlist')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase()),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final song = filtered[i];
                return ListTile(
                  title: Text(song.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: song.artist.isNotEmpty
                      ? Text(song.artist,
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  onTap: () async {
                    await widget.onAdd(song);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
