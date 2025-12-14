import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/counter/presentation/counter_screen.dart';

/// Smart Naam Jap 2.0 - Distraction-free spiritual counter
class SmartNaamJapApp extends StatelessWidget {
  const SmartNaamJapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Naam Jap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CounterScreen(),
    );
  }
}
