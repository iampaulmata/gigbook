import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import '../services/live_session_service.dart';

enum LiveSessionRole { none, hosting, following }

class LiveSessionProvider extends ChangeNotifier {
  final _host = LiveSessionHost();
  final _client = LiveSessionClient();

  LiveSessionRole _role = LiveSessionRole.none;
  String? _followingHostName;
  bool _isConnectionLive = false;
  bool _paused = false;
  LiveSessionMessage? _latestMessage;
  int _latestSeq = 0;
  String? _lastError;

  LiveSessionRole get role => _role;
  bool get isHosting => _role == LiveSessionRole.hosting;
  bool get isFollowing => _role == LiveSessionRole.following;
  int get connectedDeviceCount => _host.connectedCount;
  List<DiscoveredHost> get discoveredHosts => _client.discoveredHosts;
  String? get followingHostName => _followingHostName;
  bool get isConnectionLive => _isConnectionLive;
  bool get paused => _paused;
  LiveSessionMessage? get latestMessage => _latestMessage;
  int get latestSeq => _latestSeq;
  String? get lastError => _lastError;

  void setPaused(bool value) {
    _paused = value;
    notifyListeners();
  }

  // ─── Hosting ──────────────────────────────────────────────────────────────

  Future<void> startHosting() async {
    if (_role != LiveSessionRole.none) return;
    _lastError = null;
    if (!await _ensurePermissions()) {
      notifyListeners();
      return;
    }
    try {
      await _host.start(_deviceName());
      _role = LiveSessionRole.hosting;
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> stopHosting() async {
    if (_role != LiveSessionRole.hosting) return;
    await _host.stop();
    _role = LiveSessionRole.none;
    notifyListeners();
  }

  /// No-op unless this device is currently hosting — safe to call from every
  /// song navigation and playback-state change regardless of session state.
  void broadcastNowPlaying({
    String? setlistName,
    required Song song,
    bool isPlaying = false,
    double scrollSpeedPxPerSec = 50.0,
  }) {
    if (_role != LiveSessionRole.hosting) return;
    _host.broadcast(LiveSessionMessage(
      setlistName: setlistName,
      title: song.title,
      artist: song.artist,
      isPlaying: isPlaying,
      scrollSpeedPxPerSec: scrollSpeedPxPerSec,
    ));
  }

  // ─── Following ────────────────────────────────────────────────────────────

  Future<void> discoverHosts() async {
    if (_role != LiveSessionRole.none) return;
    _lastError = null;
    if (!await _ensurePermissions()) {
      notifyListeners();
      return;
    }
    try {
      await _client.startDiscovery(_deviceName(), notifyListeners);
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopDiscovering() async {
    await _client.stopDiscovery();
  }

  Future<void> joinHost(DiscoveredHost host) async {
    if (_role != LiveSessionRole.none) return;
    await _client.stopDiscovery();
    try {
      await _client.connect(
        _deviceName(),
        host,
        onMessage: (message) {
          _latestMessage = message;
          _latestSeq++;
          _isConnectionLive = true;
          notifyListeners();
        },
        onDisconnected: () {
          _isConnectionLive = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return;
    }
    _role = LiveSessionRole.following;
    _followingHostName = host.name;
    _isConnectionLive = true;
    notifyListeners();
  }

  Future<void> leaveSession() async {
    if (_role != LiveSessionRole.following) return;
    await _client.disconnect();
    _role = LiveSessionRole.none;
    _followingHostName = null;
    _isConnectionLive = false;
    _latestMessage = null;
    _paused = false;
    notifyListeners();
  }

  /// Nearby Connections needs Bluetooth (scan/advertise/connect), nearby
  /// WiFi devices (Android 13+) and location (older Android, and some OEMs
  /// still tie BLE scanning to it regardless of version) granted at
  /// runtime — the manifest entries alone (bundled by the `nearby_connections`
  /// plugin) aren't enough.
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ].request();

    final denied = statuses.entries
        .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
        .toList();
    if (denied.isNotEmpty) {
      _lastError =
          'Missing permissions: ${denied.map((e) => e.key.toString()).join(', ')}';
      return false;
    }
    return true;
  }

  String _deviceName() {
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty) return host;
    } catch (_) {
      // Not available on this platform — fall through to the default.
    }
    return 'GigBook session';
  }
}
