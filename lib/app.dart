import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'features/counter/presentation/counter_screen.dart';
import 'features/settings/providers/settings_provider.dart';

/// Smart Naam Jap 2.0 - Distraction-free spiritual counter
class SmartNaamJapApp extends ConsumerWidget {
  const SmartNaamJapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch the selectedTheme to minimize rebuilds
    final selectedTheme = ref.watch(
      settingsProvider.select((s) => s.selectedTheme),
    );
    
    // Apply the current theme
    AppColors.setTheme(selectedTheme);
    
    return MaterialApp(
      title: 'Smart Naam Jap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CounterScreen(),
    );
  }
}
