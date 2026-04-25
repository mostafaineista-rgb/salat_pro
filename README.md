# Salat Pro - Flutter Mobile App

A complete, elegant Islamic prayer times and Qibla app built with Flutter.

## Features
- **Prayer Times**: Automatic location detection with countdown timer.
- **Qibla Direction**: Real-time compass.
- **Moon Phase**: Detailed moon status and Hijri month info.
- **Azkar**: Morning and evening supplications with a tap counter.
- **Adhan Notifications**: Alerts for daily prayers (configurable).
- **Multilingual**: Supports Arabic and English.
- **Modern UI**: Dark and Light mode support with elegant Islamic design.

## Project Structure
```text
lib/
  main.dart             # App Entry & Navigation
  models/               # Data structures
  providers/            # State management (Provider)
  screens/              # App pages (Home, Qibla, etc.)
  services/             # External services (Notifications, API)
  utils/                # Helper functions & constants
  widgets/              # Reusable UI components
```

## Setup Instructions
1. **Open the project** in Android Studio.
2. **Install dependencies**: Run `flutter pub get` in the terminal.
3. **Permissions**: The app requires Location and Notification permissions.
4. **Adhan Sound**:
   - Place your `adhan.mp3` file in `assets/sounds/`.
   - Also place it in `android/app/src/main/res/raw/adhan.mp3` for Android notifications.
5. **Run**: Select a device and press the Play button.

## Technical Details
- State Management: **Provider**
- Local Storage: **shared_preferences**
- Location: **geolocator**
- Notifications: **flutter_local_notifications**
- Prayer Calculation: **adhan**
- Hijri Date: **hijri**
- Qibla: **flutter_qiblah**
- Icons: **font_awesome_flutter**
- Fonts: **Google Fonts (Outfit)**

## Notes
- Astronomical calculations for moon phases may differ slightly from official moon sightings.
- Ensure the device has a compass sensor for the Qibla feature.
