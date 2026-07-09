import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/drive_sync_provider.dart';
import 'providers/library_provider.dart';
import 'providers/live_session_provider.dart';
import 'providers/setlist_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/library_screen.dart';
import 'screens/setlists_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/song_view_screen.dart';
import 'services/song_matcher.dart';
import 'theme/app_theme.dart';

const _liveFollowRouteName = 'liveFollow';

/// Tracks whether the live-session follow route is currently the top of the
/// navigation stack, so `_HomeShellState` knows whether to push a fresh
/// route or replace the existing one as the host advances through a set —
/// kept accurate even if the user manually backs out of it.
class _LiveFollowRouteObserver extends NavigatorObserver {
  bool active = false;

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name == _liveFollowRouteName) active = true;
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings.name == _liveFollowRouteName) active = false;
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (route.settings.name == _liveFollowRouteName) active = false;
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute?.settings.name == _liveFollowRouteName &&
        newRoute?.settings.name != _liveFollowRouteName) {
      active = false;
    }
    if (newRoute?.settings.name == _liveFollowRouteName) active = true;
  }
}

final _liveFollowRouteObserver = _LiveFollowRouteObserver();

class GigBookApp extends StatelessWidget {
  const GigBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => MaterialApp(
        title: 'GigBook',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        home: const _HomeShell(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [_liveFollowRouteObserver],
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tab = 0;
  int? _lastHandledLiveSeq;
  String? _lastFollowedSongKey;

  static const _tabs = [
    LibraryScreen(),
    SetlistsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupSync());
    context.read<LiveSessionProvider>().addListener(_onLiveSessionChange);
  }

  @override
  void dispose() {
    context.read<LiveSessionProvider>().removeListener(_onLiveSessionChange);
    super.dispose();
  }

  void _onLiveSessionChange() {
    final liveSession = context.read<LiveSessionProvider>();

    if (!liveSession.isFollowing) {
      _lastFollowedSongKey = null;
      if (_liveFollowRouteObserver.active) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    if (liveSession.paused) return;
    if (liveSession.latestSeq == _lastHandledLiveSeq) return;
    final message = liveSession.latestMessage;
    if (message == null) return;
    _lastHandledLiveSeq = liveSession.latestSeq;

    // Only navigate when the song itself changed (or the live view isn't
    // showing at all, e.g. the user backed out manually) — playback-state-only
    // updates (play/pause/speed) for the song already on screen are handled
    // reactively by that SongViewScreen instance itself, so a full
    // push/replace here doesn't reset its scroll position.
    final songKey = SongMatcher.key(message.title, message.artist);
    final isNewSong =
        songKey != _lastFollowedSongKey || !_liveFollowRouteObserver.active;
    if (!isNewSong) return;

    final library = context.read<LibraryProvider>().songs;
    final song = SongMatcher.find(library, message.title, message.artist);
    if (song == null) {
      _lastFollowedSongKey = songKey;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Host is viewing "${message.title}" — not in your library')),
      );
      return;
    }

    _lastFollowedSongKey = songKey;
    final settings = context.read<SettingsProvider>();
    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: _liveFollowRouteName),
      builder: (_) => SongViewScreen(
        song: song,
        setlistName: message.setlistName,
        liveFollowing: true,
        initialAutoScrollActive: message.isPlaying,
        initialLiveScrollSpeed: message.scrollSpeedPxPerSec,
        initialShowChords: settings.showChords,
        initialFontSize: settings.fontSize,
      ),
    );

    final navigator = Navigator.of(context);
    if (_liveFollowRouteObserver.active) {
      navigator.pushReplacement(route);
    } else {
      navigator.push(route);
    }
  }

  Future<void> _runStartupSync() async {
    final driveSync = context.read<DriveSyncProvider>();
    await driveSync.autoSyncIfConfigured();
    if (!mounted) return;

    final summary = driveSync.lastSyncSummary;
    if (summary == null) return;
    final notable = summary.hasChanges ||
        summary.hasConflicts ||
        summary.unmatchedSetlistSongs.isNotEmpty;
    if (!notable) return;

    await context.read<LibraryProvider>().loadSongs();
    if (!mounted) return;
    await context.read<SetlistProvider>().loadSetlists();
    if (!mounted) return;

    final parts = <String>[];
    if (summary.newSongs > 0) parts.add('${summary.newSongs} new songs');
    if (summary.updatedSongs > 0) {
      parts.add('${summary.updatedSongs} updated songs');
    }
    if (summary.newSetlists > 0) {
      parts.add('${summary.newSetlists} new setlists');
    }
    if (summary.updatedSetlists > 0) {
      parts.add('${summary.updatedSetlists} updated setlists');
    }
    if (summary.missingCount > 0) {
      parts.add('${summary.missingCount} no longer in Drive');
    }
    if (summary.unmatchedSetlistSongs.isNotEmpty) {
      final n = summary.unmatchedSetlistSongs.length;
      parts.add(n == 1
          ? '1 setlist song not found locally'
          : '$n setlist songs not found locally');
    }
    if (summary.hasConflicts) {
      final n = summary.songConflicts.length + summary.setlistConflicts.length;
      parts.add(n == 1 ? '1 sync conflict to review' : '$n sync conflicts to review');
    }

    if (parts.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Synced from Drive: ${parts.join(', ')}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = context.watch<DriveSyncProvider>().isSyncing;
    return Scaffold(
      body: Column(
        children: [
          if (isSyncing) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: IndexedStack(index: _tab, children: _tabs)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Setlists',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
