import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

const _serviceId = 'com.gigbook.gigbook.livesession';
const _strategy = Strategy.P2P_STAR;

/// A "now playing" broadcast from the session host to its followers.
class LiveSessionMessage {
  final String? setlistName;
  final String title;
  final String artist;
  final bool isPlaying;
  final double scrollSpeedPxPerSec;

  /// How far through the song the sender's view is scrolled, as
  /// `pixels / maxScrollExtent` clamped to `[0.0, 1.0]` — proportional
  /// rather than a raw pixel offset so it still maps to the right passage
  /// on a receiving device with a different screen size or font/chord
  /// display settings.
  final double scrollFraction;

  const LiveSessionMessage({
    this.setlistName,
    required this.title,
    required this.artist,
    this.isPlaying = false,
    this.scrollSpeedPxPerSec = 50.0,
    this.scrollFraction = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'setlistName': setlistName,
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
        'scrollSpeedPxPerSec': scrollSpeedPxPerSec,
        'scrollFraction': scrollFraction,
      };

  factory LiveSessionMessage.fromJson(Map<String, dynamic> json) =>
      LiveSessionMessage(
        setlistName: json['setlistName'] as String?,
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        isPlaying: json['isPlaying'] as bool? ?? false,
        scrollSpeedPxPerSec:
            (json['scrollSpeedPxPerSec'] as num?)?.toDouble() ?? 50.0,
        scrollFraction: (json['scrollFraction'] as num?)?.toDouble() ?? 0.0,
      );
}

/// A host discovered nearby, ready to join.
class DiscoveredHost {
  final String endpointId;
  final String name;

  const DiscoveredHost({required this.endpointId, required this.name});
}

Uint8List _encode(LiveSessionMessage message) =>
    Uint8List.fromList(utf8.encode(jsonEncode(message.toJson())));

LiveSessionMessage? _decode(Uint8List bytes) {
  try {
    return LiveSessionMessage.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Runs on the bandleader's device: advertises a session over Nearby
/// Connections (BLE for discovery, WiFi Direct/Hotspot for data — fully
/// peer-to-peer, no shared WiFi network required) and pushes "now playing"
/// messages to every connected bandmate.
///
/// Incoming connection requests are accepted automatically without a
/// confirmation prompt on either device — reasonable for a same-room,
/// trusted-band scenario, unlike Nearby Connections' typical "confirm this
/// code on both screens" pairing flow.
class LiveSessionHost {
  final _nearby = Nearby();
  final _connectedEndpoints = <String>{};

  /// The most recently broadcast message, resent to any endpoint that
  /// connects afterwards so a bandmate joining or reconnecting mid-song
  /// catches up immediately instead of waiting for the host's next move.
  LiveSessionMessage? _lastMessage;

  int get connectedCount => _connectedEndpoints.length;

  Future<void> start(String hostName) async {
    await _nearby.startAdvertising(
      hostName,
      _strategy,
      serviceId: _serviceId,
      onConnectionInitiated: (endpointId, info) {
        _nearby.acceptConnection(
          endpointId,
          onPayLoadRecieved: (_, __) {
            // The host doesn't expect incoming payloads from followers.
          },
        );
      },
      onConnectionResult: (endpointId, status) {
        if (status == Status.CONNECTED) {
          _connectedEndpoints.add(endpointId);
          final lastMessage = _lastMessage;
          if (lastMessage != null) {
            _nearby.sendBytesPayload(endpointId, _encode(lastMessage));
          }
        } else {
          _connectedEndpoints.remove(endpointId);
        }
      },
      onDisconnected: (endpointId) {
        _connectedEndpoints.remove(endpointId);
      },
    );
  }

  void broadcast(LiveSessionMessage message) {
    _lastMessage = message;
    final bytes = _encode(message);
    for (final endpointId in List.of(_connectedEndpoints)) {
      _nearby.sendBytesPayload(endpointId, bytes);
    }
  }

  Future<void> stop() async {
    await _nearby.stopAdvertising();
    await _nearby.stopAllEndpoints();
    _connectedEndpoints.clear();
    _lastMessage = null;
  }
}

/// Runs on a bandmate's device: discovers nearby hosts and connects to one
/// to follow along.
class LiveSessionClient {
  final _nearby = Nearby();
  final _discovered = <String, DiscoveredHost>{};
  String? _connectedEndpointId;

  List<DiscoveredHost> get discoveredHosts => _discovered.values.toList();

  /// [onChange] fires whenever the discovered list changes (host found or
  /// lost).
  Future<void> startDiscovery(String myName, void Function() onChange) async {
    _discovered.clear();
    await _nearby.startDiscovery(
      myName,
      _strategy,
      serviceId: _serviceId,
      onEndpointFound: (endpointId, endpointName, serviceId) {
        _discovered[endpointId] =
            DiscoveredHost(endpointId: endpointId, name: endpointName);
        onChange();
      },
      onEndpointLost: (endpointId) {
        if (endpointId != null) _discovered.remove(endpointId);
        onChange();
      },
    );
  }

  Future<void> stopDiscovery() async {
    await _nearby.stopDiscovery();
  }

  Future<void> connect(
    String myName,
    DiscoveredHost host, {
    required void Function(LiveSessionMessage) onMessage,
    required void Function() onDisconnected,
  }) async {
    await _nearby.requestConnection(
      myName,
      host.endpointId,
      onConnectionInitiated: (endpointId, info) {
        _nearby.acceptConnection(
          endpointId,
          onPayLoadRecieved: (_, payload) {
            if (payload.type != PayloadType.BYTES || payload.bytes == null) {
              return;
            }
            final message = _decode(payload.bytes!);
            if (message != null) onMessage(message);
          },
        );
      },
      onConnectionResult: (endpointId, status) {
        if (status == Status.CONNECTED) {
          _connectedEndpointId = endpointId;
        } else {
          _connectedEndpointId = null;
          onDisconnected();
        }
      },
      onDisconnected: (endpointId) {
        _connectedEndpointId = null;
        onDisconnected();
      },
    );
  }

  Future<void> disconnect() async {
    final endpointId = _connectedEndpointId;
    _connectedEndpointId = null;
    if (endpointId != null) {
      await _nearby.disconnectFromEndpoint(endpointId);
    }
  }
}
