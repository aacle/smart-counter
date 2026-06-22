# Smart Naam Jap 2.0 -- Complete App Review

**Package:** `smrt_counter` | **Version:** 2.1.6+14 | **Platform:** Flutter (Android primary, iOS/Web/Desktop supported)
**Last Updated:** 2026-06-13

---

## 1. Core Purpose

A distraction-free spiritual chanting/meditation counter app designed for Hindu/Sikh devotional practice (Naam Jap/Sumiran). Users tap to count mantra repetitions, tracking them in units of "malas" (108 beads).

---

## 2. Screens & Navigation

| Screen | File | Purpose |
|---|---|---|
| Counter Screen | `lib/features/counter/presentation/counter_screen.dart` | Main screen -- tap to count |
| Settings Screen | `lib/features/settings/presentation/settings_screen.dart` | All app configuration |
| Reminder Setup | `lib/features/settings/presentation/reminder_setup_screen.dart` | Configure practice reminders |
| Insights Screen | `lib/features/insights/presentation/insights_screen.dart` | Analytics & statistics |

Navigation is simple push-based (no router). Counter Screen is the home screen.

---

## 3. Features & Functionality (Complete List)

### 3.1 Counting (Core Feature)

- **Tap-to-count** -- Full screen tap area increments the counter (`counter_screen.dart:273`)
- **Volume rocker counting** -- Count using hardware volume buttons without looking at the screen, for pocket/eyes-closed use (`volume_rocker_service.dart`). Debounced at 150ms, resets volume to baseline after each press, hides system volume UI.
- **Auto Chant mode** -- Automatic counting at a configurable interval (0.25s to 5.0s in 11 steps). Plays tick sound + vibration at each interval so user can chant internally without touching the screen (`counter_screen.dart:268-299`).
- **Mala tracking** -- Every 108 counts = 1 mala. Tracks position within current mala (0-107) and total malas completed.
- **Session management** -- Tracks session start time, accumulated "jap time" (only active counting time, with 5-second inactivity timeout), and session count.
- **Session reset** -- Confirmation dialog before resetting. Previous session data is saved to lifetime stats before reset (`counter_screen.dart:309-341`).
- **Day rollover** -- Automatically saves previous day's session and starts fresh on new day (`counter_provider.dart`).

### 3.2 Mala Beads Visualization

- **108-bead circular mala** -- Custom-painted circle of 108 beads using `CustomPainter` (`mala_beads.dart`).
- **Animated bead progression** -- Smooth animation as each bead lights up, with wrap-around handling at 108->0.
- **Quarter marks** -- Beads at positions 0, 27, 54, 81 are slightly larger (10%) for visual reference.
- **Glow effect** -- Radial glow follows the current bead position via `_BeadGlowPainter`.
- **Center deity image** -- Users can place a photo of their deity/guru inside the mala circle. Falls back to showing current bead count if no image is set.
- **Mala completion celebration** -- Visual overlay animation + celebration vibration pattern when a mala is completed.

### 3.3 Counter Display

- **Two interface modes:**
  - **Mala-wise** -- Shows "X of 108" prominently with mala count badge
  - **Count-wise** -- Shows total count in large text with malas as secondary info
- **Odometer animation** -- Each digit animates independently with slide-up transitions when changing (`counter_display.dart:195-260`).
- **Breathing animation** -- Subtle 2% scale oscillation on a 4-second cycle for a meditative feel.
- **Smart number formatting** -- Numbers >= 1,000 get commas, >= 10,000 show as "10.5K", >= 1,000,000 show as "1.5M".

### 3.4 Haptic Feedback System

- **4-tier vibration patterns** (`haptic_service.dart`):
  - Normal count: subtle 10ms tap (amplitude 64)
  - Every 10th count: medium 30ms vibration (amplitude 128)
  - Quarter mala (27/54/81): strong 50ms vibration (amplitude 192)
  - Mala complete (108): celebration pattern `[0,100,50,100,50,300]`

### 3.5 Sound System

- **Tap sound** -- Plays `tap.mp3` on each manual count (low latency AudioPlayer) (`sound_service.dart`)
- **Auto chant tick** -- Strong vibration + medium haptic on auto-count ticks
- **Mala completion sound** -- Celebration vibration pattern

### 3.6 Insights & Analytics

- **Today's Practice hero card** -- Shows today's chants and malas with goal progress bar (`insights_screen.dart`)
- **Calendar Heat Map** -- Visual activity heatmap showing practice consistency over time (`calendar_heat_map.dart`)
- **Streak tracking** -- Current streak (consecutive days with activity) and best streak. Fire emoji for 3+ day streaks.
- **Goal progress tracking** -- Weekly bar chart showing 7-day goal completion with checkmarks
- **Goal achievement rates** -- Weekly rate (X/7), monthly rate (X/30), and active days count
- **Achievement badges** -- "Perfect", "Elite", "Strong" based on weekly goal completion rate
- **Period stats tabs** -- Day / Week / Month / All Time with counts, malas, jap time, averages
- **Lifetime stats** -- Persistent lifetime totals stored in SharedPreferences
- **Motivational cards** -- Context-aware motivational messages based on current performance
- **Share progress** -- Share today's stats as text via system share sheet

### 3.7 Reports

- **Weekly report** -- Auto-shown on Mondays with weekly summary dialog (`weekly_report_dialog.dart`, `report_service.dart`)
- **Monthly report** -- Auto-shown on 1st of month
- **On-demand reports** -- View weekly/monthly reports anytime from Insights tabs
- **Report data includes:** daily progress bars, achievement rate, best/worst days, motivational messages, badges
- **Shareable report card** -- Capture report as PNG image for sharing (`shareable_report_card.dart`)

### 3.8 Goal System

- **Dual goal types:**
  - **Mala-based** -- Set daily goal in malas (e.g., 5 malas = 540 chants)
  - **Count-based** -- Set daily goal in raw chant counts, with presets (108, 216, 540, 1080, 10800)
- **Goal miss notification** -- Banner on counter screen if yesterday's goal was missed (`goal_miss_banner.dart`)
- **Goal celebration** -- Dialog when daily goal is achieved (`goal_celebration_dialog.dart`)
- **Progress visualization** -- Linear progress bar in hero card and circular achievement indicator

### 3.9 Reminders

- **Periodic practice reminders** -- Configurable interval (15min to 2hrs) using `AndroidAlarmManager` for reliable delivery even when app is killed (`reminder_service.dart`)
- **Active time slots** -- 7 predefined time windows (6am-9am through 12am-4am), or custom start/end hours
- **Custom notification sounds** -- System default, Ram Ram (`ram_ram.mp3`), or Radha Radha (`radha_radha.mp3`) via separate notification channels
- **Boot persistence** -- Reminders re-schedule after device reboot via `RECEIVE_BOOT_COMPLETED`
- **Permission handling** -- Requests notification + exact alarm permissions with graceful fallbacks

### 3.10 Settings

**Practice group:**
- Haptic feedback toggle (default: off)
- Tap sound toggle (default: on)
- Volume button counting toggle (default: on)
- Keep screen awake toggle (default: off)

**Appearance group:**
- Display mode (Mala-wise vs Count-wise)
- Custom title (default: "सुमिरन")
- Theme color picker (8 themes)
- Center image (deity/guru photo in mala)

**Goals group:**
- Goal type (Malas vs Counts)
- Daily goal value

**Notifications group:**
- Weekly progress report toggle
- Monthly progress report toggle
- Goal miss reminder toggle
- Practice reminders with full setup screen

**About group:**
- Version info
- Developer credit

### 3.11 Theming

- **8 color themes** (`colors.dart`):
  1. Divine Gold (default)
  2. Sacred Emerald
  3. Celestial Purple
  4. Ocean Blue
  5. Lotus Pink
  6. Sunrise Orange
  7. Pure White
  8. Sacred Red
- **OLED-optimized** -- Pure black background (`#000000`) saves battery on OLED screens
- **Each theme has 7 color variants:** primary, primaryLight, primaryDark, secondary, secondaryLight, glow, beadActive
- **Google Fonts (Outfit)** -- Clean, modern typography throughout

### 3.12 Android Home Screen Widget

- **Native Kotlin widget** (`SmartNaamWidget.kt`) -- shows today's count, malas, and streak
- **Auto-synced** -- Widget data updates every 5 counts via `HomeWidgetService`
- **Click to open** -- Tapping widget launches the app

### 3.13 Rate Us / Feedback

- **Smart rate-us prompts** (`feedback_service.dart`, `rate_us_dialog.dart`) -- Shows after minimum usage (3 days, 1+ mala), with 7-day cooldown between prompts
- **In-app review** -- Uses `in_app_review` for native Play Store review flow
- **Prominent rate button** in Settings screen
- **Never-ask-again** option

### 3.14 Data Persistence

- **Hive** -- Local NoSQL database for daily statistics (`insights_provider.dart`)
- **SharedPreferences** -- Counter state, settings, lifetime stats, report timestamps
- **Auto-save** -- Counter state saves every 10 counts and on app backgrounding
- **All data is local** -- No server/cloud. Fully offline-first.

### 3.15 App Lifecycle Management

- **App pause handling** -- Flushes jap time and saves state when app goes to background (`counter_screen.dart:185-192`)
- **Portrait lock** -- Locked to portrait orientation for counting ergonomics
- **Wakelock** -- Optional screen-awake mode during counting sessions
- **System UI** -- Transparent status bar, black navigation bar

---

## 4. Architecture

```
lib/
  main.dart              Entry point (init Hive, reminders, widget, orientation)
  app.dart               MaterialApp with dynamic theming via Riverpod

  core/
    constants/           Mala size (108), animation durations, haptic intervals
    theme/               8-color theme system, OLED dark theme, Google Fonts

  features/
    counter/
      domain/            CounterState (immutable, JSON-serializable)
      presentation/      CounterScreen + 4 widgets (MalaBeads, CounterDisplay, CountButton, SessionStats)
      providers/         CounterNotifier (StateNotifier) + lifetimeStatsProvider

    insights/
      domain/            DailyStats, PeriodStats models
      presentation/      InsightsScreen + 5 widgets (HeatMap, GoalCelebration, GoalMiss, ShareableReport, WeeklyReport)
      providers/         InsightsNotifier (StateNotifier)

    settings/
      domain/            SettingsState (25+ configurable fields)
      presentation/      SettingsScreen, ReminderSetupScreen, SettingsTile widget
      providers/         SettingsNotifier (StateNotifier)

    common/
      rate_us_dialog.dart

  services/
    feedback_service.dart       Rate-us prompt logic
    haptic_service.dart         4-tier vibration patterns
    home_widget_service.dart    Android widget sync
    reminder_service.dart       Background alarm notifications
    report_service.dart         Weekly/monthly report generation
    share_progress_service.dart Widget-to-image sharing
    sound_service.dart          Audio playback + tick feedback
    volume_rocker_service.dart  Hardware button counting
```

**State management:** Flutter Riverpod (StateNotifier pattern)
**Local storage:** Hive + SharedPreferences
**Architecture pattern:** Feature-based clean architecture (domain/presentation/providers per feature)

---

## 5. CI/CD

- **GitHub Actions** (`.github/workflows/build.yml`):
  - Triggers on push to main/master, tags, PRs, manual dispatch
  - Builds signed APK + AAB with secrets-based keystore
  - Auto-creates GitHub Release with artifacts on `v*` tags

---

## 6. Platform Support

| Platform | Status | Notes |
|---|---|---|
| Android | Primary | Home widget, alarm reminders, volume rocker, Play Store integration |
| iOS | Scaffold present | Basic Flutter support, some Android-specific features may not work |
| Web | Scaffold present | PWA manifest configured |
| Linux/macOS/Windows | Scaffold present | Default Flutter desktop templates |

---

## 7. Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` ^2.6.1 | State management |
| `hive` + `hive_flutter` | Offline-first local database |
| `shared_preferences` | Simple key-value persistence |
| `vibration` ^2.0.0 | Haptic feedback patterns |
| `volume_controller` ^2.0.7 | Volume rocker detection |
| `audioplayers` ^6.0.0 | Sound playback |
| `wakelock_plus` ^1.2.10 | Screen wake lock |
| `flutter_local_notifications` ^18.0.1 | Notification display |
| `android_alarm_manager_plus` ^4.0.4 | Background alarms |
| `home_widget` ^0.6.0 | Android home screen widget |
| `google_fonts` ^6.2.1 | Outfit font family |
| `flutter_animate` ^4.5.2 | UI animations |
| `in_app_review` ^2.0.10 | Play Store review prompt |
| `image_picker` ^1.1.2 | Deity image selection |
| `share_plus` ^12.0.1 | System share sheet |
| `sensors_plus` ^6.1.1 | Device sensors |
| `package_info_plus` ^9.0.0 | App version info |

---

## 8. Assets

```
assets/
  icon/
    app_icon.png           App launcher icon source
  sounds/
    tap.mp3                Tap count sound effect
    ram_ram.mp3            Ram Ram chant (reminder sound)
    radha_radha.mp3        Radha Radha chant (reminder sound)
```

---

## 9. Android Permissions

| Permission | Purpose |
|---|---|
| `INTERNET` | Google Fonts, in-app review |
| `POST_NOTIFICATIONS` | Practice reminders |
| `SCHEDULE_EXACT_ALARM` | Reliable alarm delivery |
| `USE_EXACT_ALARM` | Exact alarm scheduling |
| `VIBRATE` | Haptic feedback |
| `WAKE_LOCK` | Background alarm processing |
| `RECEIVE_BOOT_COMPLETED` | Restore reminders after reboot |
| `ACCESS_NOTIFICATION_POLICY` | Notification channel management |

---

## Changelog

| Date | Changes |
|---|---|
| 2026-06-13 | Initial comprehensive review document created |
