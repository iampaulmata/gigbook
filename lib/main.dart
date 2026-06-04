import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/library_provider.dart';
import 'providers/setlist_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..loadSongs()),
        ChangeNotifierProvider(
            create: (_) => SetlistProvider()..loadSetlists()),
      ],
      child: const GigBookApp(),
    ),
  );
}
