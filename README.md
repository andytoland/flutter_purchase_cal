# flutter_purchase_calc

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
samples, guidance on mobile development, and a full API reference.

## Running on iPhone 16e Simulator

To run the app specifically on the iPhone 16e simulator, ensure the simulator is open and run:

```bash
flutter run -d "iPhone 16e"
```

If the simulator is not open, you can open it with:

```bash
open -a Simulator
```

## Google Maps Configuration

The app uses Google Maps for picking locations. You must add your API Key to the configuration:

**iOS**:
Open `ios/Runner/AppDelegate.swift` and add `GMSServices.provideAPIKey("YOUR_API_KEY")`.
Or update `ios/Runner/Info.plist` if using a key in plist (depending on setup).  
_Currently placeholder `YOUR_API_KEY_HERE` is in `Info.plist`._

**Android**:
Open `android/app/src/main/AndroidManifest.xml` and add your key in the `meta-data` tag.
