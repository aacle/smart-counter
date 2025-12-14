# Smart Naam Jap 2.0 

![App Icon](assets/icon/app_icon.png)

**Distraction-free spiritual counter for chanting meditation.**

Smart Naam Jap 2.0 is a refined, offline-first Flutter application designed to enhance your meditation practice. It combines a premium OLED-friendly design with practical features like haptic feedback, volume rocker control, and comprehensive session insights.

## ✨ Key Features

*   **📿 Digital Mala Beads**: Experience the tactile feel of traditional chanting with digital beads and haptic feedback.
*   **🔇 Distraction-Free**: Clean, minimal interface designed to keep you focused on your mantra.
*   **📱 OLED-Friendly Theme**: True black dark mode to save battery and reduce eye strain during night sessions.
*   **🔊 Volume Rocker Control**: Count without looking at the screen using your device's volume buttons.
*   **📊 Advanced Insights**: Track your progress with detailed daily stats, session history, and streak monitoring.
*   **🔔 Smart Reminders**: Reliable local notifications to keep your practice consistent.
*   **💾 Offline-First**: All data is stored locally using Hive, ensuring privacy and zero lag.
*   **⚡ Efficient**: Optimized for performance and battery life using Flutter Riverpod.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/)
*   **State Management**: [Riverpod](https://riverpod.dev/)
*   **Local Database**: [Hive](https://docs.hivedb.dev/)
*   **Audio**: [Flutter Sound](https://pub.dev/packages/flutter_sound)
*   **Sensors**: [Sensors Plus](https://pub.dev/packages/sensors_plus) & [Vibration](https://pub.dev/packages/vibration)
*   **Background Tasks**: [Android Alarm Manager Plus](https://pub.dev/packages/android_alarm_manager_plus)
*   **CI/CD**: GitHub Actions

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (3.10.4 or higher)
*   Dart SDK
*   Android Studio / Xcode (for mobile development)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/smrt_counter.git
    cd smrt_counter
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 🤖 CI/CD & Building

This project uses **GitHub Actions** for automated builds and releases.

### Workflows

*   **Build Android & iOS**: Triggers on push to `main` or `master`. Builds APK, AAB, and unsigned IPA.
*   **Create Release**: Triggers on pushing a tag starting with `v` (e.g., `v1.0.0`). Automatically packages artifacts and creates a GitHub Release.

### Manual Build Commands

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS (Unsigned):**
```bash
flutter build ios --release --no-codesign
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
