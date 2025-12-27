// lib/main.dart
import 'package:flutter/material.dart';

import 'core/app_globals.dart';
import 'core/notification_service.dart';
import 'core/notification_sync.dart';
import 'theme/theme_controller.dart';

import 'dashboard/dashboard_page.dart';
import 'pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App-level persisted settings (anon opt-in, dates, etc.)
  await loadAppGlobals();

  // Theme controller expects a ValueNotifier<Color>
  final themeController = ThemeController(seedColor: appThemeColor);
  await themeController.load();

  // Local notifications init
  await NotificationService.instance.init();

  // Sync all notification triggers based on current prefs + saved baby dates
  await NotificationSync.syncAll();

  runApp(BabyTrackerApp(themeController: themeController));
}

class BabyTrackerApp extends StatefulWidget {
  final ThemeController themeController;
  const BabyTrackerApp({super.key, required this.themeController});

  @override
  State<BabyTrackerApp> createState() => _BabyTrackerAppState();
}

class _BabyTrackerAppState extends State<BabyTrackerApp> {
  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (_, seed, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Baby Tracker',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: widget.themeController.mode,
          home: DashboardPage(themeController: widget.themeController),
          routes: {
            '/settings': (_) =>
                SettingsPage(themeController: widget.themeController),
          },
        );
      },
    );
  }
}
