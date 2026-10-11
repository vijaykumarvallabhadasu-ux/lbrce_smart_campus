# LBRCE Smart Campus Navigator (Flutter)

A starter Flutter app with live GPS, searchable campus places, bookmarks, editable per-building coordinates, straight-line distance, and Google Maps walking directions.

## Run in your existing project

1. Back up your current project.
2. Copy `lib/main.dart`, `pubspec.yaml`, and `test/widget_test.dart` from this package into your Flutter project, replacing those files.
3. Keep your generated `android/` folder.
4. Add Android location permissions as shown in `android_notes/AndroidManifest-permissions.txt`.
5. Run these commands from the project root:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

## Android permissions

Edit `android/app/src/main/AndroidManifest.xml` and put these two lines directly inside the `<manifest>` element, before `<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

The app requests location permission while in use; it does not need background location access.

## How to set individual building GPS pins

Individual building coordinates are not guessed. The official LBRCE website publishes the general college pin `16.749072, 80.634794`; the app uses that only for the general college entrance/campus pin. For each department/library/canteen/etc.:

1. On a phone, open Google Maps and stand near the exact building.
2. Long-press the exact building location on the map to drop a pin.
3. Copy the displayed latitude and longitude.
4. In this app, open the matching place and tap **Set / edit GPS pin**.
5. Enter both coordinates and tap **Save**. They are stored locally on that device.

Until a building pin is saved, the directions button asks Google Maps to search for the place name and college. Verify the destination before walking. GPS readings inside buildings may be inaccurate.

## Features

- Current GPS location (foreground only)
- Place search and category filters
- Per-place details and bookmarks
- Manually verified per-building coordinates stored with SharedPreferences
- Google Maps walking directions
- Straight-line distance when both current and destination coordinates are available

## Important

The app needs a real Android phone or an emulator with location enabled to test GPS. The app has not been run on your device, so run `flutter analyze`, `flutter test`, and `flutter run`; share any errors if they occur.
