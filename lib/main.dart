// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_globals.dart';
import 'core/notification_service.dart';
import 'pages/dashboard_page.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hydrate globals (anon opt-in + baby dates)
  await loadAppGlobals();

  // ✅ Optional: theme seed based on saved gender (kept as in your current flow)
  final prefs = await SharedPreferences.getInstance();
  final savedGender = prefs.getString('gender');
  if (savedGender == 'girl') {
    appThemeColor.value = Colors.pink.shade200;
  } else if (savedGender == 'boy') {
    appThemeColor.value = Colors.blue;
  } else {
    // fallback
    appThemeColor.value = appThemeColor.value; // keep current
  }

  await MobileAds.instance.initialize();
  await NotificationService.instance.init();

  runApp(const BabyTrackerApp());
}

class BabyTrackerApp extends StatefulWidget {
  const BabyTrackerApp({super.key});

  @override
  State<BabyTrackerApp> createState() => _BabyTrackerAppState();
}

class _BabyTrackerAppState extends State<BabyTrackerApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(seedColor: appThemeColor);
    _themeController.load();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, seedColor, _) {
        final lightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );

        return AnimatedBuilder(
          animation: _themeController,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Bebek Takip',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: _themeController.mode,
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [Locale('tr', 'TR')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: DashboardPage(themeController: _themeController),
            );
          },
        );
      },
    );
  }
}
