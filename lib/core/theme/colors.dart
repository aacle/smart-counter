import 'package:flutter/material.dart';

/// OLED-optimized color palette for Smart Naam Jap 2.0
/// Pure black backgrounds save battery on OLED screens
class AppColors {
  AppColors._();

  // === Background Colors (OLED Optimized) ===
  /// Pure black for OLED screens - pixels completely off
  static const Color background = Color(0xFF000000);
  
  /// Slightly elevated surface for cards
  static const Color surface = Color(0xFF0A0A0A);
  
  /// Card backgrounds with subtle elevation
  static const Color cardBackground = Color(0xFF121212);

  // === Primary Colors (Spiritual Gold) ===
  /// Main accent - warm spiritual gold
  static const Color primary = Color(0xFFFFD700);
  
  /// Lighter gold for highlights
  static const Color primaryLight = Color(0xFFFFE44D);
  
  /// Darker gold for pressed states
  static const Color primaryDark = Color(0xFFCCAA00);

  // === Secondary Colors (Deep Amber) ===
  static const Color secondary = Color(0xFFFF8C00);
  static const Color secondaryLight = Color(0xFFFFAD33);

  // === Accent Colors ===
  /// Success green for mala completion
  static const Color success = Color(0xFF00E676);
  
  /// Soft glow color for beads
  static const Color glow = Color(0xFFFFD700);
  
  /// Inactive bead color
  static const Color beadInactive = Color(0xFF2A2A2A);
  
  /// Active bead color
  static const Color beadActive = Color(0xFFFFD700);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF666666);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const RadialGradient glowGradient = RadialGradient(
    colors: [
      Color(0x40FFD700),
      Color(0x00FFD700),
    ],
  );
}
