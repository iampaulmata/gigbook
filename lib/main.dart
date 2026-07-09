import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/drive_sync_provider.dart';
import 'providers/library_provider.dart';
import 'providers/live_session_provider.dart';
import 'providers/setlist_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsProvider();
  await settings.load();

  final driveSync = DriveSyncProvider();
  await driveSync.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..loadSongs()),
        ChangeNotifierProvider(
            create: (_) => SetlistProvider()..loadSetlists()),
        ChangeNotifierProvider.value(value: driveSync),
        ChangeNotifierProvider(create: (_) => LiveSessionProvider()),
      ],
      child: const GigBookApp(),
    ),
  );
}
