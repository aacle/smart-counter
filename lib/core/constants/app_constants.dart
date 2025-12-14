/// App-wide constants for Smart Naam Jap 2.0
library;

/// The standard Mala size - 108 beads
const int kMalaSize = 108;

/// Quarter Mala - for milestone haptic feedback
const int kQuarterMala = 27;

/// Haptic feedback intervals
const int kHapticMilestone = 10;

/// Animation durations
const Duration kCountAnimationDuration = Duration(milliseconds: 150);
const Duration kMalaCompleteAnimationDuration = Duration(milliseconds: 800);
const Duration kBreathingAnimationDuration = Duration(seconds: 4);

/// Session auto-save interval
const Duration kAutoSaveInterval = Duration(seconds: 30);
