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

### 🐧 Debian / Linux Headless Setup Guide

If you are setting up this project on a fresh Debian/Linux machine without Android Studio, follow these exact steps to set up the Android toolchain headlessly.

**1. Install System Prerequisites**
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev default-jdk xz-utils git curl unzip libglu1-mesa
```

**2. Install Flutter (via Snap)**
The recommended way to install Flutter on Linux is via snap.
```bash
sudo apt install snapd
sudo snap install flutter --classic
```

**3. Headless Android SDK Setup**
Run this script to download and install the Android Command Line Tools, accept licenses, and install the required Platform and Build Tools.
```bash
# Set environment variables (Add these to your ~/.bashrc)
export JAVA_HOME="/usr/lib/jvm/default-java"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Download Command Line Tools
mkdir -p $HOME/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
unzip -q cmdline-tools.zip -d $HOME/Android/Sdk/cmdline-tools
mv $HOME/Android/Sdk/cmdline-tools/cmdline-tools $HOME/Android/Sdk/cmdline-tools/latest
rm cmdline-tools.zip

# Accept licenses and install platforms
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-36" "build-tools;28.0.3"

# Tell Flutter where the SDK is
flutter config --android-sdk "$ANDROID_HOME"
flutter doctor
```

### 📱 Wireless Debugging (Android 11+)
1. Enable **Wireless debugging** in Developer Options on your phone.
2. Tap "Pair device with pairing code".
3. In your terminal, run: `adb pair <IP>:<PORT>`
4. Look at the main Wireless Debugging screen for the active port, then run: `adb connect <IP>:<NEW_PORT>`

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

### Triggering a Play Store Release
To automatically build a signed `.aab` file and create a GitHub Release:

1. **Bump Version:** Update `pubspec.yaml` (e.g., `version: 1.0.1+2`. You **must** increment the `+2` build number).
2. **Commit Changes:** `git commit -am "chore: bump version to 1.0.1"`
3. **Create Tag:** `git tag v1.0.1`
4. **Push Tag:** `git push origin v1.0.1`

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
