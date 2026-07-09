import 'package:flutter/foundation.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/drive_sync_service.dart';

class DriveSyncProvider extends ChangeNotifier {
  static const _keyRootUri = 'drive_sync_root_uri';
  static const _keyRootName = 'drive_sync_root_name';
  static const _keyLastSyncedAt = 'drive_sync_last_synced_at';
  static const _keyPromptDismissed = 'drive_sync_prompt_dismissed';

  final _safUtil = SafUtil();

  String? _rootUri;
  String? _rootName;
  DateTime? _lastSyncedAt;
  bool _isSyncing = false;
  DriveSyncSummary? _lastSyncSummary;
  bool _permissionLost = false;
  String? _lastSyncError;
  bool _promptDismissed = false;

  String? get rootUri => _rootUri;
  String? get rootName => _rootName;
  bool get isConfigured => _rootUri != null;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isSyncing => _isSyncing;
  DriveSyncSummary? get lastSyncSummary => _lastSyncSummary;
  bool get permissionLost => _permissionLost;
  String? get lastSyncError => _lastSyncError;
  bool get shouldShowSetupPrompt => !isConfigured && !_promptDismissed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _rootUri = prefs.getString(_keyRootUri);
    _rootName = prefs.getString(_keyRootName);
    final lastMs = prefs.getInt(_keyLastSyncedAt);
    _lastSyncedAt =
        lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;
    _promptDismissed = prefs.getBool(_keyPromptDismissed) ?? false;
    notifyListeners();
  }

  Future<void> dismissSetupPrompt() async {
    _promptDismissed = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromptDismissed, true);
  }

  Future<void> pickRootFolder() async {
    final picked =
        await _safUtil.pickDirectory(persistablePermission: true);
    if (picked == null) return;

    _rootUri = picked.uri;
    _rootName = picked.name;
    _permissionLost = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRootUri, picked.uri);
    await prefs.setString(_keyRootName, picked.name);

    await sync();
  }

  Future<void> forgetFolder() async {
    final uri = _rootUri;
    if (uri != null) {
      try {
        await _safUtil.releasePersistedPermission(uri);
      } catch (_) {
        // Already gone/inaccessible — nothing more to release.
      }
    }
    _rootUri = null;
    _rootName = null;
    _lastSyncedAt = null;
    _lastSyncSummary = null;
    _permissionLost = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRootUri);
    await prefs.remove(_keyRootName);
    await prefs.remove(_keyLastSyncedAt);
  }

  /// Called on app startup — a no-op if no folder has been configured yet.
  Future<void> autoSyncIfConfigured() async {
    if (_rootUri == null) return;
    await sync();
  }

  Future<void> sync() async {
    final uri = _rootUri;
    if (uri == null || _isSyncing) return;

    final hasPermission = await _safUtil.hasPersistedPermission(uri);
    if (!hasPermission) {
      _permissionLost = true;
      notifyListeners();
      return;
    }

    _isSyncing = true;
    notifyListeners();
    try {
      _lastSyncSummary = await DriveSyncService.sync(uri);
      _lastSyncedAt = DateTime.now();
      _permissionLost = false;
      _lastSyncError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _keyLastSyncedAt, _lastSyncedAt!.millisecondsSinceEpoch);
    } catch (e) {
      // The sync didn't complete, so any prior summary no longer reflects
      // what's on disk — clear it rather than risk re-showing stale results.
      _lastSyncSummary = null;
      _lastSyncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ─── Conflict resolution ──────────────────────────────────────────────────

  Future<void> keepLocalSong(SongConflict conflict) async {
    await DriveSyncService.keepLocalSong(conflict);
    _dropSongConflict(conflict);
  }

  Future<void> useRemoteSong(SongConflict conflict) async {
    await DriveSyncService.useRemoteSong(conflict);
    _dropSongConflict(conflict);
  }

  Future<void> keepLocalSetlist(SetlistConflict conflict) async {
    await DriveSyncService.keepLocalSetlist(conflict);
    _dropSetlistConflict(conflict);
  }

  Future<void> useRemoteSetlist(SetlistConflict conflict) async {
    await DriveSyncService.useRemoteSetlist(conflict);
    _dropSetlistConflict(conflict);
  }

  void _dropSongConflict(SongConflict conflict) {
    final summary = _lastSyncSummary;
    if (summary == null) return;
    _lastSyncSummary = DriveSyncSummary(
      newSongs: summary.newSongs,
      updatedSongs: summary.updatedSongs,
      newSetlists: summary.newSetlists,
      updatedSetlists: summary.updatedSetlists,
      missingCount: summary.missingCount,
      songConflicts: summary.songConflicts
          .where((c) => c.songId != conflict.songId)
          .toList(),
      setlistConflicts: summary.setlistConflicts,
      unmatchedSetlistSongs: summary.unmatchedSetlistSongs,
    );
    notifyListeners();
  }

  void _dropSetlistConflict(SetlistConflict conflict) {
    final summary = _lastSyncSummary;
    if (summary == null) return;
    _lastSyncSummary = DriveSyncSummary(
      newSongs: summary.newSongs,
      updatedSongs: summary.updatedSongs,
      newSetlists: summary.newSetlists,
      updatedSetlists: summary.updatedSetlists,
      missingCount: summary.missingCount,
      songConflicts: summary.songConflicts,
      setlistConflicts: summary.setlistConflicts
          .where((c) => c.setlistId != conflict.setlistId)
          .toList(),
      unmatchedSetlistSongs: summary.unmatchedSetlistSongs,
    );
    notifyListeners();
  }
}
