import 'package:flutter/material.dart';

/// Available theme colors for the app
enum AppThemeColor {
  divineGold,      // 🌟 Current default - warm spiritual gold
  sacredEmerald,   // 🌿 Calming nature-inspired green
  celestialPurple, // 💫 Mystical and spiritual purple
  oceanBlue,       // 🔵 Peaceful blue tones
  lotusPink,       // 🌺 Gentle pink for devotion
  sunriseOrange,   // ☀️ Energetic warm orange
  pureWhite,       // ❄️ Minimalist pure white
  sacredRed,       // ❤️ Passionate devotional red
}

/// Extension for theme display names and icons
extension AppThemeColorExtension on AppThemeColor {
  String get displayName {
    switch (this) {
      case AppThemeColor.divineGold:
        return 'Divine Gold';
      case AppThemeColor.sacredEmerald:
        return 'Sacred Emerald';
      case AppThemeColor.celestialPurple:
        return 'Celestial Purple';
      case AppThemeColor.oceanBlue:
        return 'Ocean Blue';
      case AppThemeColor.lotusPink:
        return 'Lotus Pink';
      case AppThemeColor.sunriseOrange:
        return 'Sunrise Orange';
      case AppThemeColor.pureWhite:
        return 'Pure White';
      case AppThemeColor.sacredRed:
        return 'Sacred Red';
    }
  }

  String get emoji {
    switch (this) {
      case AppThemeColor.divineGold:
        return '🌟';
      case AppThemeColor.sacredEmerald:
        return '🌿';
      case AppThemeColor.celestialPurple:
        return '💫';
      case AppThemeColor.oceanBlue:
        return '🔵';
      case AppThemeColor.lotusPink:
        return '🌺';
      case AppThemeColor.sunriseOrange:
        return '☀️';
      case AppThemeColor.pureWhite:
        return '❄️';
      case AppThemeColor.sacredRed:
        return '❤️';
    }
  }
}

/// Color palette for each theme
class ThemeColorPalette {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryLight;
  final Color glow;
  final Color beadActive;

  const ThemeColorPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.glow,
    required this.beadActive,
  });

  /// Get palette for a specific theme
  static ThemeColorPalette forTheme(AppThemeColor theme) {
    switch (theme) {
      case AppThemeColor.divineGold:
        return const ThemeColorPalette(
          primary: Color(0xFFFFD700),
          primaryLight: Color(0xFFFFE44D),
          primaryDark: Color(0xFFCCAA00),
          secondary: Color(0xFFFF8C00),
          secondaryLight: Color(0xFFFFAD33),
          glow: Color(0xFFFFD700),
          beadActive: Color(0xFFFFD700),
        );
      case AppThemeColor.sacredEmerald:
        return const ThemeColorPalette(
          primary: Color(0xFF00C853),
          primaryLight: Color(0xFF5EFC82),
          primaryDark: Color(0xFF009624),
          secondary: Color(0xFF00E676),
          secondaryLight: Color(0xFF66FFA6),
          glow: Color(0xFF00C853),
          beadActive: Color(0xFF00C853),
        );
      case AppThemeColor.celestialPurple:
        return const ThemeColorPalette(
          primary: Color(0xFFAA00FF),
          primaryLight: Color(0xFFD500F9),
          primaryDark: Color(0xFF7B00B2),
          secondary: Color(0xFFE040FB),
          secondaryLight: Color(0xFFEA80FC),
          glow: Color(0xFFAA00FF),
          beadActive: Color(0xFFAA00FF),
        );
      case AppThemeColor.oceanBlue:
        return const ThemeColorPalette(
          primary: Color(0xFF2962FF),
          primaryLight: Color(0xFF768FFF),
          primaryDark: Color(0xFF0039CB),
          secondary: Color(0xFF448AFF),
          secondaryLight: Color(0xFF83B9FF),
          glow: Color(0xFF2962FF),
          beadActive: Color(0xFF2962FF),
        );
      case AppThemeColor.lotusPink:
        return const ThemeColorPalette(
          primary: Color(0xFFFF4081),
          primaryLight: Color(0xFFFF79B0),
          primaryDark: Color(0xFFC60055),
          secondary: Color(0xFFFF80AB),
          secondaryLight: Color(0xFFFFB2CC),
          glow: Color(0xFFFF4081),
          beadActive: Color(0xFFFF4081),
        );
      case AppThemeColor.sunriseOrange:
        return const ThemeColorPalette(
          primary: Color(0xFFFF6D00),
          primaryLight: Color(0xFFFF9E40),
          primaryDark: Color(0xFFC43C00),
          secondary: Color(0xFFFF9100),
          secondaryLight: Color(0xFFFFC246),
          glow: Color(0xFFFF6D00),
          beadActive: Color(0xFFFF6D00),
        );
      case AppThemeColor.pureWhite:
        return const ThemeColorPalette(
          primary: Color(0xFFFFFFFF),
          primaryLight: Color(0xFFFFFFFF),
          primaryDark: Color(0xFFE0E0E0),
          secondary: Color(0xFFBDBDBD),
          secondaryLight: Color(0xFFE0E0E0),
          glow: Color(0xFFFFFFFF),
          beadActive: Color(0xFFFFFFFF),
        );
      case AppThemeColor.sacredRed:
        return const ThemeColorPalette(
          primary: Color(0xFFFF1744),
          primaryLight: Color(0xFFFF616F),
          primaryDark: Color(0xFFC4001D),
          secondary: Color(0xFFFF5252),
          secondaryLight: Color(0xFFFF867F),
          glow: Color(0xFFFF1744),
          beadActive: Color(0xFFFF1744),
        );
    }
  }
}

/// OLED-optimized color palette for Smart Naam Jap 2.0
/// Pure black backgrounds save battery on OLED screens
/// Accent colors are now dynamic based on selected theme
class AppColors {
  AppColors._();

  // Current theme - updated by settings provider
  static AppThemeColor _currentTheme = AppThemeColor.divineGold;
  
  static void setTheme(AppThemeColor theme) {
    _currentTheme = theme;
  }
  
  static AppThemeColor get currentTheme => _currentTheme;
  
  static ThemeColorPalette get palette => ThemeColorPalette.forTheme(_currentTheme);

  // === Background Colors (OLED Optimized - never change) ===
  /// Pure black for OLED screens - pixels completely off
  static const Color background = Color(0xFF000000);
  
  /// Slightly elevated surface for cards
  static const Color surface = Color(0xFF0A0A0A);
  
  /// Card backgrounds with subtle elevation
  static const Color cardBackground = Color(0xFF121212);

  // === Primary Colors (Dynamic based on theme) ===
  /// Main accent color
  static Color get primary => palette.primary;
  
  /// Lighter variant for highlights
  static Color get primaryLight => palette.primaryLight;
  
  /// Darker variant for pressed states
  static Color get primaryDark => palette.primaryDark;

  // === Secondary Colors (Dynamic) ===
  static Color get secondary => palette.secondary;
  static Color get secondaryLight => palette.secondaryLight;

  // === Accent Colors ===
  /// Success green for mala completion
  static const Color success = Color(0xFF00E676);
  
  /// Soft glow color for beads
  static Color get glow => palette.glow;
  
  /// Inactive bead color
  static const Color beadInactive = Color(0xFF2A2A2A);
  
  /// Active bead color
  static Color get beadActive => palette.beadActive;

  // === Text Colors ===
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF666666);

  // === Gradients ===
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static RadialGradient get glowGradient => RadialGradient(
    colors: [
      glow.withValues(alpha: 0.25),
      glow.withValues(alpha: 0.0),
    ],
  );
}

