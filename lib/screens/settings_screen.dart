import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/drive_sync_provider.dart';
import '../providers/library_provider.dart';
import '../providers/live_session_provider.dart';
import '../providers/setlist_provider.dart';
import '../providers/settings_provider.dart';
import 'custom_theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final driveSync = context.watch<DriveSyncProvider>();
    final liveSession = context.watch<LiveSessionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(settings.useCustomTheme
                ? 'Custom${settings.activeCustomThemeName != null ? ' (${settings.activeCustomThemeName})' : ''}'
                : _themeName(settings.themeMode)),
            leading: const Icon(Icons.brightness_6_outlined),
            onTap: () => _pickTheme(context, settings),
          ),
          ListTile(
            title: const Text('Custom Theme'),
            subtitle: const Text('Design your own colors'),
            leading: const Icon(Icons.palette_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomThemeScreen()),
            ),
          ),

          // ── Song viewer ────────────────────────────────────────────────
          _SectionHeader('Song viewer'),
          SwitchListTile(
            title: const Text('Show chords by default'),
            subtitle: const Text('Can be toggled per song'),
            secondary: const Icon(Icons.music_note_outlined),
            value: settings.showChords,
            onChanged: settings.setShowChords,
          ),
          ListTile(
            title: const Text('Default font size'),
            subtitle: Text('${settings.fontSize.round()} pt'),
            leading: const Icon(Icons.format_size),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: settings.fontSize > 12
                      ? () => settings.setFontSize(settings.fontSize - 2)
                      : null,
                ),
                Text('${settings.fontSize.round()}',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: settings.fontSize < 32
                      ? () => settings.setFontSize(settings.fontSize + 2)
                      : null,
                ),
              ],
            ),
          ),

          // ── Auto-scroll ────────────────────────────────────────────────
          _SectionHeader('Auto-scroll'),
          ListTile(
            title: const Text('Default scroll speed'),
            subtitle: Text('${settings.scrollSpeed.round()} px / second'),
            leading: const Icon(Icons.speed),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.scrollSpeed,
              min: 10,
              max: 200,
              divisions: 38,
              label: '${settings.scrollSpeed.round()}',
              onChanged: settings.setScrollSpeed,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Slow',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('Fast',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ListTile(
            title: const Text('Tempo-sync scroll intensity'),
            subtitle: Text(
                '${settings.scrollPxPerBeat.round()} px per beat — used when a song has a BPM tag. '
                'Lower = slower scroll for the same tempo.'),
            leading: const Icon(Icons.graphic_eq),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.scrollPxPerBeat,
              min: 2,
              max: 40,
              divisions: 38,
              label: '${settings.scrollPxPerBeat.round()}',
              onChanged: settings.setScrollPxPerBeat,
            ),
          ),
          // ── Google Drive sync ─────────────────────────────────────────
          _SectionHeader('Google Drive sync'),
          if (driveSync.permissionLost)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_outlined,
                    color: theme.colorScheme.onErrorContainer),
                title: Text('Drive folder access needs to be re-granted',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                subtitle: Text('Tap to reconnect',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                onTap: driveSync.pickRootFolder,
              ),
            ),
          ListTile(
            title: Text(driveSync.isConfigured
                ? (driveSync.rootName ?? 'Selected folder')
                : 'No folder selected'),
            subtitle: Text(driveSync.isConfigured
                ? 'Songs and setlists sync from this Drive folder on launch'
                : 'Pick a Drive folder to auto-sync songs and setlists'),
            leading: const Icon(Icons.cloud_outlined),
            trailing: TextButton(
              onPressed: driveSync.pickRootFolder,
              child: Text(driveSync.isConfigured ? 'Change' : 'Choose folder'),
            ),
          ),
          if (driveSync.isConfigured) ...[
            ListTile(
              title: const Text('Last synced'),
              subtitle: Text(driveSync.lastSyncError != null
                  ? 'Failed: ${driveSync.lastSyncError}'
                  : driveSync.lastSyncedAt != null
                      ? _formatDateTime(driveSync.lastSyncedAt!)
                      : 'Never'),
              leading: Icon(Icons.sync,
                  color: driveSync.lastSyncError != null
                      ? theme.colorScheme.error
                      : null),
              trailing: driveSync.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: driveSync.sync,
                      child: const Text('Sync now'),
                    ),
            ),
            ListTile(
              title: const Text('Forget folder'),
              leading: const Icon(Icons.link_off),
              onTap: () => _confirmForget(context, driveSync),
            ),
          ],
          if (driveSync.lastSyncSummary?.hasConflicts ?? false)
            _SyncConflictsCard(driveSync: driveSync),

          // ── Live session ───────────────────────────────────────────────
          _SectionHeader('Live session'),
          if (liveSession.lastError != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_outlined,
                    color: theme.colorScheme.onErrorContainer),
                title: Text('Live session failed',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                subtitle: Text(liveSession.lastError!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            ),
          if (liveSession.role == LiveSessionRole.none)
            ListTile(
              title: const Text('Not in a session'),
              subtitle: const Text(
                  'Host to broadcast your setlist position, or join a bandmate\'s session to follow along. Turn on Location/GPS on both devices — Nearby Connections needs it even though GigBook doesn\'t use your location.'),
              leading: const Icon(Icons.podcasts_outlined),
              trailing: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: liveSession.startHosting,
                    child: const Text('Host'),
                  ),
                  TextButton(
                    onPressed: () => _startJoinFlow(context, liveSession),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ),
          if (liveSession.role == LiveSessionRole.hosting)
            ListTile(
              title: const Text('Hosting'),
              subtitle: Text(liveSession.connectedDeviceCount == 1
                  ? '1 device following'
                  : '${liveSession.connectedDeviceCount} devices following'),
              leading: const Icon(Icons.podcasts),
              trailing: TextButton(
                onPressed: liveSession.stopHosting,
                child: const Text('Stop hosting'),
              ),
            ),
          if (liveSession.role == LiveSessionRole.following) ...[
            ListTile(
              title:
                  Text('Following ${liveSession.followingHostName ?? 'host'}'),
              subtitle: Text(liveSession.isConnectionLive
                  ? 'Connected'
                  : 'Disconnected — waiting to reconnect'),
              leading: Icon(
                liveSession.isConnectionLive ? Icons.podcasts : Icons.sync_problem,
                color:
                    liveSession.isConnectionLive ? null : theme.colorScheme.error,
              ),
              trailing: TextButton(
                onPressed: liveSession.leaveSession,
                child: const Text('Leave'),
              ),
            ),
            SwitchListTile(
              title: const Text('Pause following'),
              subtitle: const Text('Browse your own library without jumping to the host\'s song'),
              value: liveSession.paused,
              onChanged: liveSession.setPaused,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmForget(
      BuildContext context, DriveSyncProvider driveSync) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forget Drive folder'),
        content: const Text(
            'GigBook will stop syncing from this folder. Songs and setlists already imported stay in your library.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Forget')),
        ],
      ),
    );
    if (confirmed == true) await driveSync.forgetFolder();
  }

  Future<void> _startJoinFlow(
      BuildContext context, LiveSessionProvider liveSession) async {
    await liveSession.discoverHosts();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _JoinSessionSheet(liveSession: liveSession),
    );
    if (liveSession.role == LiveSessionRole.none) {
      await liveSession.stopDiscovering();
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$m';
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _pickTheme(
      BuildContext context, SettingsProvider settings) async {
    // Returns either a ThemeMode or the literal string 'custom' — Flutter's
    // ThemeMode enum can't be extended with a 4th value (research.md §1),
    // so "Custom" travels as a separate choice through this dialog.
    final choice = await showDialog<Object>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose theme'),
        children: [
          ...ThemeMode.values.map((mode) {
            return ListTile(
              title: Text(_themeName(mode)),
              leading: !settings.useCustomTheme && mode == settings.themeMode
                  ? const Icon(Icons.check)
                  : const SizedBox(width: 24),
              onTap: () => Navigator.pop(context, mode),
            );
          }),
          ListTile(
            title: const Text('Custom'),
            leading: settings.useCustomTheme
                ? const Icon(Icons.check)
                : const SizedBox(width: 24),
            onTap: () => Navigator.pop(context, 'custom'),
          ),
        ],
      ),
    );

    if (choice == null) return;
    if (choice is ThemeMode) {
      await settings.setThemeMode(choice);
      return;
    }

    // "Custom" selected (FR-009, FR-010, FR-011).
    if (settings.customThemes.isEmpty) {
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomThemeScreen()),
        );
      }
      return;
    }
    final name =
        settings.activeCustomThemeName ?? settings.customThemes.last.name;
    await settings.applyCustomTheme(name);
  }
}

class _SyncConflictsCard extends StatelessWidget {
  final DriveSyncProvider driveSync;
  const _SyncConflictsCard({required this.driveSync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = driveSync.lastSyncSummary;
    if (summary == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Sync conflicts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Edited locally and on Drive since the last sync — choose which version to keep.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
              ),
            ),
            for (final c in summary.songConflicts)
              _ConflictTile(
                title: c.title,
                onKeepMine: () => driveSync.keepLocalSong(c),
                onUseDrive: () async {
                  await driveSync.useRemoteSong(c);
                  if (context.mounted) {
                    await context.read<LibraryProvider>().loadSongs();
                  }
                },
              ),
            for (final c in summary.setlistConflicts)
              _ConflictTile(
                title: c.name,
                onKeepMine: () => driveSync.keepLocalSetlist(c),
                onUseDrive: () async {
                  await driveSync.useRemoteSetlist(c);
                  if (context.mounted) {
                    await context.read<SetlistProvider>().loadSetlists();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ConflictTile extends StatelessWidget {
  final String title;
  final Future<void> Function() onKeepMine;
  final Future<void> Function() onUseDrive;

  const _ConflictTile({
    required this.title,
    required this.onKeepMine,
    required this.onUseDrive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onKeepMine, child: const Text('Keep mine')),
          TextButton(onPressed: onUseDrive, child: const Text('Use Drive')),
        ],
      ),
    );
  }
}

class _JoinSessionSheet extends StatelessWidget {
  final LiveSessionProvider liveSession;
  const _JoinSessionSheet({required this.liveSession});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      builder: (_, controller) => AnimatedBuilder(
        animation: liveSession,
        builder: (context, _) {
          final hosts = liveSession.discoveredHosts;
          return Column(
            children: [
              const ListTile(title: Text('Join a live session')),
              if (hosts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Looking for sessions on this WiFi network…',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: hosts.length,
                    itemBuilder: (_, i) {
                      final host = hosts[i];
                      return ListTile(
                        leading: const Icon(Icons.podcasts_outlined),
                        title: Text(host.name),
                        onTap: () async {
                          await liveSession.joinHost(host);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
