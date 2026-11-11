# PawPal — Dog Walking Companion 🐾

An academic Flutter/Dart mobile app prototype for keeping track of dogs and walks. This repository contains my original app-level source code and dependency configuration.

## Features demonstrated in the source code

- Create, edit and delete dog profiles, with optional photos from the device gallery.
- Start and finish walks with a timer and GPS-based distance tracking.
- View a walk history, daily walking-goal indicators and a summary of activity.
- Share walk summaries using the device's sharing interface.
- Save dog profiles and walk history locally with `shared_preferences`.

## Technologies

Flutter, Dart, `geolocator`, `image_picker`, `shared_preferences`, and `share_plus`.

## Repository layout

```text
lib/
  main.dart          # App startup, tabs and local persistence
  home_screen.dart   # Activity dashboard
  dogs_screen.dart   # Dog model and profile management
  walks_screen.dart  # Walk model, GPS tracking, history and sharing
pubspec.yaml          # Dependencies and Dart SDK constraint
```

## Run locally

**Requirements:** Flutter SDK compatible with Dart 3.10, Android Studio or Xcode (or a physical test device), and the relevant platform tools.

This upload is the **Flutter application source**, not a complete, generated Flutter platform project. On a machine with Flutter installed, from this folder run:

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

`flutter create` generates missing Android/iOS scaffolding. Before testing GPS or photo selection, configure platform permissions as described below. Depending on your installed SDK version or platform, dependency updates may be needed.

### GPS / photos: platform permissions

- **Android:** Add `android.permission.ACCESS_COARSE_LOCATION` and `android.permission.ACCESS_FINE_LOCATION` to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, outside `<application>`). The application also needs permission at runtime, which the Dart code requests.
- **iOS:** In `ios/Runner/Info.plist`, provide `NSLocationWhenInUseUsageDescription` (e.g. "PawPal uses your location to measure walk distances") and `NSPhotoLibraryUsageDescription` (e.g. "PawPal lets you select a photo for your dog profile").
- Use a physical mobile device for representative GPS tests; simulators may need a simulated location.

## Current status / limitations

- Source files and imports checked for consistency. **Not compiled, run, or device-tested in this preparation environment.**
- This repository does not include generated platform folders, signed app builds, or app-store distribution configuration.
- Walk distances depend on GPS signal and permissions; position noise may affect results.
- Information is stored locally on the device using shared preferences; it is not synchronised to a server.
- This is a learning/portfolio project, not a production or safety-critical location tracking product.

## Privacy

No API keys or real user data are included in this repository. Avoid committing any device-specific configuration, keys, or private location histories.
