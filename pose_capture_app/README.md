# Pose Capture App

Flutter app for real-time human pose estimation, skeleton overlay, and CSV/JSON recording.

## Current Scope

Implemented in Dart/Flutter:

- Camera preview and front/back camera switching
- ML Kit pose detector in stream mode
- Input image conversion for Android NV21 and iOS BGRA camera streams
- Skeleton overlay with display-only front-camera mirroring
- Start/stop recording
- Session ID generation
- CSV row generation and buffered file flush
- Session metadata JSON
- Share action for generated files
- Unit tests for CSV output, session IDs, recording files, and coordinate conversion

## Setup

This workspace did not have `flutter` or `dart` available on PATH during implementation, so native platform scaffolding and verification could not be generated here.

On a machine with Flutter installed:

```bash
cd pose_capture_app
flutter create --platforms=android,ios .
flutter pub get
flutter format .
flutter analyze
flutter test
```

If Flutter asks whether to overwrite existing Dart files, keep the existing project files.

## Android

Add this permission to `android/app/src/main/AndroidManifest.xml` if the generated Android project does not already include it:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

ML Kit packages generally require Android minSdk 21 or newer. Check the generated `android/app/build.gradle` before running on a device.

Run on a device:

```bash
flutter devices
flutter run
```

## iOS

Add this to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>骨格推定および動作計測のためにカメラを使用します。</string>
```

Check the current ML Kit package requirements and set the generated iOS deployment target accordingly before building in Xcode.

Then run from Xcode or:

```bash
flutter run
```

## Recording Output

Files are saved in the app documents directory:

- `pose_<session_id>.csv`
- `pose_<session_id>.json`

CSV columns:

```text
session_id,timestamp_ms,frame_index,joint,x,y,z,confidence,image_width,image_height,camera_lens,rotation_deg
```

Coordinates are saved in camera image coordinates. Front camera mirroring is only applied when drawing the overlay.

## Known Constraints

- Real device verification is still required for Android and iOS.
- ML Kit `z` is relative depth, not an absolute distance.
- Pose FPS depends heavily on device performance, lighting, and camera format.
- `flutter pub outdated` could not be run because Flutter was unavailable in this environment.
