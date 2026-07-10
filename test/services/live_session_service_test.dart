import 'package:flutter_test/flutter_test.dart';

import 'package:gigbook/services/live_session_service.dart';

void main() {
  group('LiveSessionMessage.scrollFraction', () {
    test('toJson includes scrollFraction', () {
      final message = LiveSessionMessage(
        title: 'Amazing Grace',
        artist: 'John Newton',
        scrollFraction: 0.42,
      );
      expect(message.toJson()['scrollFraction'], 0.42);
    });

    test('fromJson round-trips a given scrollFraction', () {
      final message = LiveSessionMessage.fromJson({
        'title': 'Amazing Grace',
        'artist': 'John Newton',
        'scrollFraction': 0.75,
      });
      expect(message.scrollFraction, 0.75);
    });

    test('fromJson defaults scrollFraction to 0.0 when the key is absent',
        () {
      final message = LiveSessionMessage.fromJson({
        'title': 'Amazing Grace',
        'artist': 'John Newton',
      });
      expect(message.scrollFraction, 0.0);
    });

    test('constructor defaults scrollFraction to 0.0', () {
      final message =
          LiveSessionMessage(title: 'Amazing Grace', artist: 'John Newton');
      expect(message.scrollFraction, 0.0);
    });
  });
}
