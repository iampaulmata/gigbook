import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/setlist_provider.dart';
import '../widgets/chordpro_renderer.dart';
import 'edit_song_screen.dart';

class SongViewScreen extends StatefulWidget {
  final Song song;
  final List<Song>? setlistSongs;
  final int? setlistIndex;
  final double initialFontSize;
  final bool initialShowChords;
  final double initialScrollSpeed;

  const SongViewScreen({
    super.key,
    required this.song,
    this.setlistSongs,
    this.setlistIndex,
    this.initialFontSize = 18.0,
    this.initialShowChords = true,
    this.initialScrollSpeed = 50.0,
  });

  @override
  State<SongViewScreen> createState() => _SongViewScreenState();
}

class _SongViewScreenState extends State<SongViewScreen> {
  late Song _song;
  late int? _index;

  final _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _autoScrollActive = false;
  bool _showSpeedPanel = false;

  late double _fontSize;
  late bool _showChords;
  late double _scrollSpeed;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _index = widget.setlistIndex;
    _fontSize = widget.initialFontSize;
    _showChords = widget.initialShowChords;
    _scrollSpeed = widget.initialScrollSpeed;
    if (_song.id != null) {
      AppDatabase.instance.touchSong(_song.id!);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Auto-scroll ──────────────────────────────────────────────────────────

  void _toggleAutoScroll() {
    if (_autoScrollActive) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    setState(() {
      _autoScrollActive = true;
      _showSpeedPanel = true;
    });
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final target = pos.pixels + _scrollSpeed * 0.05;
      if (target >= pos.maxScrollExtent) {
        _scrollController.jumpTo(pos.maxScrollExtent);
        _stopAutoScroll();
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (mounted) setState(() => _autoScrollActive = false);
  }

  // ─── Setlist navigation ───────────────────────────────────────────────────

  bool get _inSetlist =>
      widget.setlistSongs != null && _index != null;

  void _goTo(int newIndex) {
    _stopAutoScroll();
    _scrollController.jumpTo(0);
    final song = widget.setlistSongs![newIndex];
    if (song.id != null) AppDatabase.instance.touchSong(song.id!);
    setState(() {
      _index = newIndex;
      _song = song;
    });
  }

  // ─── Song editing ─────────────────────────────────────────────────────────

  Future<void> _editSong() async {
    final updated = await Navigator.push<Song>(
      context,
      MaterialPageRoute(builder: (_) => EditSongScreen(song: _song)),
    );
    if (updated != null && mounted) {
      context.read<LibraryProvider>().updateSong(updated);
      setState(() => _song = updated);
    }
  }

  Future<void> _addToSetlist() async {
    final setlists = context.read<SetlistProvider>().setlists;
    if (!mounted) return;
    if (setlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No setlists yet — create one first.')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => _AddToSetlistSheet(
        song: _song,
        setlists: setlists,
      ),
    );
  }

  Future<void> _deleteSong() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete song'),
        content: Text('Delete "${_song.title}"? This cannot be undone.'),
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
    if (confirmed == true && mounted) {
      await context.read<LibraryProvider>().deleteSong(_song.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_song.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (_song.artist.isNotEmpty)
              Text(_song.artist,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          // Chords toggle
          IconButton(
            icon: Icon(_showChords ? Icons.music_note : Icons.music_off),
            tooltip: _showChords ? 'Hide chords' : 'Show chords',
            onPressed: () => setState(() => _showChords = !_showChords),
          ),
          // Font size decrease
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'Smaller text',
            onPressed: _fontSize > 12
                ? () => setState(() => _fontSize = (_fontSize - 2).clamp(12, 32))
                : null,
          ),
          // Font size increase
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'Larger text',
            onPressed: _fontSize < 32
                ? () => setState(() => _fontSize = (_fontSize + 2).clamp(12, 32))
                : null,
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              switch (action) {
                case _MenuAction.edit:
                  _editSong();
                case _MenuAction.addToSetlist:
                  _addToSetlist();
                case _MenuAction.delete:
                  _deleteSong();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuAction.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.addToSetlist,
                child: ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text('Add to setlist'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (_autoScrollActive) _stopAutoScroll();
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: ChordProRenderer(
                  content: _song.content,
                  showChords: _showChords,
                  fontSize: _fontSize,
                ),
              ),
            ),
          ),

          // Auto-scroll speed panel
          if (_showSpeedPanel)
            _SpeedPanel(
              speed: _scrollSpeed,
              active: _autoScrollActive,
              onSpeedChanged: (v) => setState(() => _scrollSpeed = v),
              onStop: () {
                _stopAutoScroll();
                setState(() => _showSpeedPanel = false);
              },
            ),

          // Setlist navigation bar
          if (_inSetlist)
            _SetlistNavBar(
              current: _index!,
              total: widget.setlistSongs!.length,
              onPrev: _index! > 0 ? () => _goTo(_index! - 1) : null,
              onNext: _index! < widget.setlistSongs!.length - 1
                  ? () => _goTo(_index! + 1)
                  : null,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAutoScroll,
        tooltip: _autoScrollActive ? 'Pause scroll' : 'Auto-scroll',
        child: Icon(_autoScrollActive ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}

// ─── Speed panel ──────────────────────────────────────────────────────────────

class _SpeedPanel extends StatelessWidget {
  final double speed;
  final bool active;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onStop;

  const _SpeedPanel({
    required this.speed,
    required this.active,
    required this.onSpeedChanged,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.speed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: speed,
              min: 10,
              max: 200,
              divisions: 38,
              label: '${speed.round()} px/s',
              onChanged: onSpeedChanged,
            ),
          ),
          TextButton(onPressed: onStop, child: const Text('Close')),
        ],
      ),
    );
  }
}

// ─── Setlist nav bar ──────────────────────────────────────────────────────────

class _SetlistNavBar extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _SetlistNavBar({
    required this.current,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: onPrev,
            tooltip: 'Previous song',
          ),
          Text(
            '${current + 1} / $total',
            style: theme.textTheme.labelLarge,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: onNext,
            tooltip: 'Next song',
          ),
        ],
      ),
    );
  }
}

// ─── Add-to-setlist bottom sheet ──────────────────────────────────────────────

class _AddToSetlistSheet extends StatelessWidget {
  final Song song;
  final List<dynamic> setlists;

  const _AddToSetlistSheet({required this.song, required this.setlists});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text('Add to setlist')),
        const Divider(height: 1),
        ...setlists.map((setlist) => ListTile(
              title: Text(setlist.name as String),
              onTap: () async {
                await context
                    .read<SetlistProvider>()
                    .addSong(setlist.id as int, song.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Added to ${setlist.name}')),
                  );
                }
              },
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

enum _MenuAction { edit, addToSetlist, delete }
