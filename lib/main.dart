import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'features/auth/auth_service.dart';
import 'services/home_widget_service.dart';
import 'services/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use bundled Outfit font — no network request needed on first launch
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Appwrite client (must happen before any auth calls)
  AuthService.instance.initialize();

  // Restore reminders if they were previously enabled (non-blocking)
  ReminderService.instance.restoreRemindersIfEnabled();

  // Initialize Home Widget Service
  await HomeWidgetService.initialize();

  // Lock to portrait mode for better experience during counting
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: SmartNaamJapApp(),
    ),
  );
}
