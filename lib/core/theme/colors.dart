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
          primary: Color(0xFFE0B252),
          primaryLight: Color(0xFFEDC878),
          primaryDark: Color(0xFFB8902F),
          secondary: Color(0xFFD99A4A),
          secondaryLight: Color(0xFFE8B873),
          glow: Color(0xFFE0B252),
          beadActive: Color(0xFFE0B252),
        );
      case AppThemeColor.sacredEmerald:
        return const ThemeColorPalette(
          primary: Color(0xFF5BAE7F),
          primaryLight: Color(0xFF7FC499),
          primaryDark: Color(0xFF3F8A5E),
          secondary: Color(0xFF4FAA9E),
          secondaryLight: Color(0xFF78C2B8),
          glow: Color(0xFF5BAE7F),
          beadActive: Color(0xFF5BAE7F),
        );
      case AppThemeColor.celestialPurple:
        return const ThemeColorPalette(
          primary: Color(0xFF9D7BCC),
          primaryLight: Color(0xFFB89BDB),
          primaryDark: Color(0xFF7A5DAA),
          secondary: Color(0xFF8A6FBF),
          secondaryLight: Color(0xFFA893D4),
          glow: Color(0xFF9D7BCC),
          beadActive: Color(0xFF9D7BCC),
        );
      case AppThemeColor.oceanBlue:
        return const ThemeColorPalette(
          primary: Color(0xFF5B8DEF),
          primaryLight: Color(0xFF82A8F2),
          primaryDark: Color(0xFF4070C9),
          secondary: Color(0xFF4F86D6),
          secondaryLight: Color(0xFF7AA5E6),
          glow: Color(0xFF5B8DEF),
          beadActive: Color(0xFF5B8DEF),
        );
      case AppThemeColor.lotusPink:
        return const ThemeColorPalette(
          primary: Color(0xFFE879A6),
          primaryLight: Color(0xFFF099BD),
          primaryDark: Color(0xFFC45A88),
          secondary: Color(0xFFD96B9A),
          secondaryLight: Color(0xFFEA93B5),
          glow: Color(0xFFE879A6),
          beadActive: Color(0xFFE879A6),
        );
      case AppThemeColor.sunriseOrange:
        return const ThemeColorPalette(
          primary: Color(0xFFE8924A),
          primaryLight: Color(0xFFF0AC72),
          primaryDark: Color(0xFFC2742F),
          secondary: Color(0xFFD9824A),
          secondaryLight: Color(0xFFE8A070),
          glow: Color(0xFFE8924A),
          beadActive: Color(0xFFE8924A),
        );
      case AppThemeColor.pureWhite:
        return const ThemeColorPalette(
          primary: Color(0xFFEDEDED),
          primaryLight: Color(0xFFFFFFFF),
          primaryDark: Color(0xFFC8C8C8),
          secondary: Color(0xFFBDBDBD),
          secondaryLight: Color(0xFFE0E0E0),
          glow: Color(0xFFEDEDED),
          beadActive: Color(0xFFEDEDED),
        );
      case AppThemeColor.sacredRed:
        return const ThemeColorPalette(
          primary: Color(0xFFE05A5A),
          primaryLight: Color(0xFFED7E7E),
          primaryDark: Color(0xFFB84545),
          secondary: Color(0xFFD95555),
          secondaryLight: Color(0xFFEA8080),
          glow: Color(0xFFE05A5A),
          beadActive: Color(0xFFE05A5A),
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

