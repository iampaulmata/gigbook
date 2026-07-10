import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/live_session_provider.dart';
import '../providers/setlist_provider.dart';
import '../services/drive_sync_service.dart';
import '../services/song_matcher.dart';
import '../widgets/chordpro_renderer.dart';
import 'edit_lyrics_screen.dart';
import 'edit_song_screen.dart';

class SongViewScreen extends StatefulWidget {
  final Song song;
  final List<Song>? setlistSongs;
  final int? setlistIndex;
  final String? setlistName;
  final double initialFontSize;
  final bool initialShowChords;
  final double initialScrollSpeed;
  final double initialScrollPxPerBeat;

  /// True when this screen is showing a live session host's broadcast
  /// (read-only follow) rather than the user's own browsing — hides local
  /// playback controls and reacts to the host's play/pause/speed instead.
  final bool liveFollowing;
  final bool initialAutoScrollActive;
  final double initialLiveScrollSpeed;

  const SongViewScreen({
    super.key,
    required this.song,
    this.setlistSongs,
    this.setlistIndex,
    this.setlistName,
    this.initialFontSize = 18.0,
    this.initialShowChords = true,
    this.initialScrollSpeed = 50.0,
    this.initialScrollPxPerBeat = 10.0,
    this.liveFollowing = false,
    this.initialAutoScrollActive = false,
    this.initialLiveScrollSpeed = 50.0,
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
  DateTime? _lastScrollBroadcastAt;
  static const _scrollBroadcastThrottle = Duration(milliseconds: 120);

  late double _fontSize;
  late bool _showChords;
  late double _scrollSpeed;
  late double _scrollPxPerBeat;
  late bool _matchTempo;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _index = widget.setlistIndex;
    _fontSize = widget.initialFontSize;
    _showChords = widget.initialShowChords;
    _scrollSpeed =
        widget.liveFollowing ? widget.initialLiveScrollSpeed : widget.initialScrollSpeed;
    _scrollPxPerBeat = widget.initialScrollPxPerBeat;
    _matchTempo = _song.tempo != null;
    if (_song.id != null) {
      AppDatabase.instance.touchSong(_song.id!);
    }
    if (widget.liveFollowing) {
      context.read<LiveSessionProvider>().addListener(_onLiveFollowUpdate);
      if (widget.initialAutoScrollActive) _startAutoScroll();
    } else {
      _broadcastNowPlaying();
    }
  }

  /// A no-op unless this device is hosting a live session — safe to call
  /// unconditionally on every song/playback change.
  void _broadcastNowPlaying() {
    context.read<LiveSessionProvider>().broadcastNowPlaying(
          setlistName: widget.setlistName,
          song: _song,
          isPlaying: _autoScrollActive,
          scrollSpeedPxPerSec: _effectiveScrollSpeed,
          scrollFraction: _currentScrollFraction,
        );
  }

  /// How far through the song this view is currently scrolled, as a
  /// proportion of its own scrollable extent — see [LiveSessionMessage
  /// .scrollFraction] for why this is proportional rather than a raw pixel
  /// offset.
  double get _currentScrollFraction {
    if (!_scrollController.hasClients) return 0.0;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return 0.0;
    return (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
  }

  /// Broadcasts the host's current scroll position, throttled to
  /// [_scrollBroadcastThrottle] while dragging so a live session doesn't get
  /// a message per pixel — [force] bypasses the throttle so the position the
  /// host actually stops on is always sent (used on scroll-end).
  void _maybeBroadcastScrollPosition({bool force = false}) {
    if (widget.liveFollowing) return;
    final now = DateTime.now();
    if (!force &&
        _lastScrollBroadcastAt != null &&
        now.difference(_lastScrollBroadcastAt!) < _scrollBroadcastThrottle) {
      return;
    }
    _lastScrollBroadcastAt = now;
    _broadcastNowPlaying();
  }

  /// Reacts to the host's playback broadcasts while following — only for
  /// messages about this same song, and only calling start/stop when the
  /// desired state actually differs so an already-running scroll isn't
  /// restarted (which would reset its position).
  void _onLiveFollowUpdate() {
    final message = context.read<LiveSessionProvider>().latestMessage;
    if (message == null) return;
    if (SongMatcher.key(message.title, message.artist) !=
        SongMatcher.key(_song.title, _song.artist)) {
      return;
    }
    _scrollSpeed = message.scrollSpeedPxPerSec;
    if (message.isPlaying != _autoScrollActive) {
      if (message.isPlaying) {
        _startAutoScroll();
      } else {
        _stopAutoScroll();
      }
    }
  }

  double get _effectiveScrollSpeed {
    if (widget.liveFollowing) return _scrollSpeed;
    final tempo = _song.tempo;
    if (_matchTempo && tempo != null) {
      return _scrollPxPerBeat * (tempo / 60.0);
    }
    return _scrollSpeed;
  }

  @override
  void dispose() {
    if (widget.liveFollowing) {
      context.read<LiveSessionProvider>().removeListener(_onLiveFollowUpdate);
    }
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
    if (!widget.liveFollowing) _broadcastNowPlaying();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final target = pos.pixels + _effectiveScrollSpeed * 0.05;
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
    if (mounted) {
      setState(() => _autoScrollActive = false);
      if (!widget.liveFollowing) _broadcastNowPlaying();
    }
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
    _broadcastNowPlaying();
  }

  // ─── Song editing ─────────────────────────────────────────────────────────

  Future<void> _editSong() async {
    final updated = await Navigator.push<Song>(
      context,
      MaterialPageRoute(builder: (_) => EditSongScreen(song: _song)),
    );
    if (updated != null && mounted) {
      final toSave = _stampLocalEdit(updated);
      context.read<LibraryProvider>().updateSong(toSave);
      setState(() => _song = toSave);
      _pushToDrive(toSave);
    }
  }

  Future<void> _editLyrics() async {
    final updated = await Navigator.push<Song>(
      context,
      MaterialPageRoute(builder: (_) => EditLyricsScreen(song: _song)),
    );
    if (updated != null && mounted) {
      final toSave = _stampLocalEdit(updated);
      context.read<LibraryProvider>().updateSong(toSave);
      setState(() {
        _song = toSave;
        _matchTempo = _song.tempo != null;
      });
      _pushToDrive(toSave);
    }
  }

  /// Marks a Drive-linked song as edited locally since its last sync pull, so
  /// a later Drive sync can detect a conflict instead of silently
  /// overwriting this edit with the remote version.
  Song _stampLocalEdit(Song song) => song.sourceUri != null
      ? song.copyWith(localEditedAt: DateTime.now())
      : song;

  /// Best-effort push of a linked song's edit back to its file in the synced
  /// Drive folder. The local save above already happened regardless of
  /// network/Drive availability — if this fails, [_stampLocalEdit]'s
  /// `localEditedAt` stays set, so the existing pull-sync conflict detection
  /// remains the fallback safety net until this succeeds (next edit or sync).
  Future<void> _pushToDrive(Song song) async {
    if (song.sourceUri == null) return;
    try {
      await DriveSyncService.pushSongEdit(song);
      if (mounted) await context.read<LibraryProvider>().loadSongs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved locally, but could not sync to Drive: $e')),
        );
      }
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_song.artist.isNotEmpty)
                  Flexible(
                    child: Text(_song.artist,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                if (_song.artist.isNotEmpty && _song.tempo != null)
                  const SizedBox(width: 8),
                if (_song.tempo != null) _BpmPulse(bpm: _song.tempo!),
              ],
            ),
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
                case _MenuAction.editLyrics:
                  _editLyrics();
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
                value: _MenuAction.editLyrics,
                child: ListTile(
                  leading: Icon(Icons.edit_note_outlined),
                  title: Text('Edit lyrics'),
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is UserScrollNotification) {
                  if (_autoScrollActive) _stopAutoScroll();
                } else if (n is ScrollUpdateNotification) {
                  _maybeBroadcastScrollPosition();
                } else if (n is ScrollEndNotification) {
                  _maybeBroadcastScrollPosition(force: true);
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                // A follower's screen is driven entirely by the host's
                // broadcast position — their own drag gestures must not
                // move it independently (FR-003).
                physics: widget.liveFollowing
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: ChordProRenderer(
                  content: _song.content,
                  showChords: _showChords,
                  fontSize: _fontSize,
                ),
              ),
            ),
          ),

          // Auto-scroll speed panel — hidden for a live follower, who
          // doesn't control playback themselves.
          if (_showSpeedPanel && !widget.liveFollowing)
            _SpeedPanel(
              speed: _scrollSpeed,
              active: _autoScrollActive,
              tempo: _song.tempo,
              matchTempo: _matchTempo,
              pxPerBeat: _scrollPxPerBeat,
              onSpeedChanged: (v) {
                setState(() => _scrollSpeed = v);
                _broadcastNowPlaying();
              },
              onMatchTempoChanged: (v) {
                setState(() => _matchTempo = v);
                _broadcastNowPlaying();
              },
              onPxPerBeatChanged: (v) {
                setState(() => _scrollPxPerBeat = v);
                _broadcastNowPlaying();
              },
              onStop: () {
                _stopAutoScroll();
                setState(() => _showSpeedPanel = false);
              },
            ),

        ],
      ),
      bottomNavigationBar: _inSetlist
          ? _SetlistNavBar(
              current: _index!,
              total: widget.setlistSongs!.length,
              onPrev: _index! > 0 ? () => _goTo(_index! - 1) : null,
              onNext: _index! < widget.setlistSongs!.length - 1
                  ? () => _goTo(_index! + 1)
                  : null,
            )
          : null,
      floatingActionButton: widget.liveFollowing
          ? null
          : FloatingActionButton(
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
  final int? tempo;
  final bool matchTempo;
  final double pxPerBeat;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<bool> onMatchTempoChanged;
  final ValueChanged<double> onPxPerBeatChanged;
  final VoidCallback onStop;

  const _SpeedPanel({
    required this.speed,
    required this.active,
    required this.tempo,
    required this.matchTempo,
    required this.pxPerBeat,
    required this.onSpeedChanged,
    required this.onMatchTempoChanged,
    required this.onPxPerBeatChanged,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useTempo = tempo != null && matchTempo;
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tempo != null)
            Row(
              children: [
                const Icon(Icons.speed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    useTempo
                        ? 'Matching tempo — $tempo BPM'
                        : 'Manual speed',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Switch(value: matchTempo, onChanged: onMatchTempoChanged),
              ],
            ),
          Row(
            children: [
              if (tempo == null) ...[
                const Icon(Icons.speed, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: useTempo
                    ? Slider(
                        value: pxPerBeat,
                        min: 2,
                        max: 40,
                        divisions: 38,
                        label: '${pxPerBeat.round()} px/beat',
                        onChanged: onPxPerBeatChanged,
                      )
                    : Slider(
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
        ],
      ),
    );
  }
}

// ─── BPM pulse indicator ────────────────────────────────────────────────────

class _BpmPulse extends StatefulWidget {
  final int bpm;
  const _BpmPulse({required this.bpm});

  @override
  State<_BpmPulse> createState() => _BpmPulseState();
}

class _BpmPulseState extends State<_BpmPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _beatDuration(widget.bpm),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _BpmPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      _controller.duration = _beatDuration(widget.bpm);
      _controller.repeat();
    }
  }

  Duration _beatDuration(int bpm) =>
      Duration(milliseconds: (60000 / bpm).round().clamp(150, 2000));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final t = _controller.value;
            final scale = 1.0 + (1 - t) * 0.5;
            final opacity = 0.35 + (1 - t) * 0.65;
            return Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Icon(Icons.circle,
              size: 8, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 4),
        Text('${widget.bpm} BPM', style: theme.textTheme.bodySmall),
      ],
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
      child: SafeArea(
        top: false,
        child: Padding(
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
        ),
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

enum _MenuAction { edit, editLyrics, addToSetlist, delete }
