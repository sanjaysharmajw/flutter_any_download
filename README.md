![Logo](https://github.com/sanjaysharmajw/flutter_any_download/blob/main/screenshots/download.jpeg?raw=true)

# flutter_any_download

A simple, production-ready download manager for Flutter with real-time progress notifications, cancellation support, and seamless iOS & Android compatibility.

---

## Screenshots

<p align="center">
  <img src="https://github.com/sanjaysharmajw/flutter_any_download/blob/main/screenshots/Screenshot_20260428_121801.png?raw=true" width="220" alt="Home Screen" />
  &nbsp;&nbsp;
  <img src="https://github.com/sanjaysharmajw/flutter_any_download/blob/main/screenshots/Screenshot_20260428_121916.png?raw=true" width="220" alt="Progress Download" />
  &nbsp;&nbsp;
  <img src="https://github.com/sanjaysharmajw/flutter_any_download/blob/main/screenshots/Screenshot_20260428_121829.png?raw=true" width="220" alt="Multiple Downloads" />
</p>

<p align="center">
  <b>Home Screen</b> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <b>Progress Download</b> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <b>Multiple Downloads</b>
</p>

## Demo

<p align="center">
  <img src="https://github.com/sanjaysharmajw/flutter_any_download/blob/main/screenshots/demo.gif?raw=true" width="280" alt="Demo Recording" />
</p>

---

## Features

- **Simple API** — Download any file in 3 lines of code
- **Progress Notifications** — Built-in notification bar with live download progress
- **iOS & Android Support** — Fully functional notifications on both platforms
- **Progress Callbacks** — Track download progress, completion, and errors in your UI
- **Cancellation** — Cancel individual or all active downloads at any time
- **Silent Downloads** — Download files without showing any notifications
- **Multiple File Downloads** — Download several files sequentially or in batches
- **iOS Foreground Notifications** — Notifications display even when the app is in the foreground
- **File Path Access** — Get the saved file path via callbacks or `DownloadResult`
- **Android Scoped Storage** — Handles Android 9 / 10 / 11+ storage correctly

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_any_download: ^1.1.9
```

This package bundles all required dependencies internally. No additional packages are needed.

---

## Quick Start

### 1. Initialize (call once in `main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterAnyDownload.instance.initialize();

  // Required for iOS — request notification permission at startup
  await FlutterAnyDownload.instance.requestPermission();

  runApp(MyApp());
}
```

### 2. Download a File

```dart
final result = await FlutterAnyDownload.instance.download(
  url: 'https://example.com/file.pdf',
  filename: 'document.pdf',
);

if (result.success) {
  print('Saved to: ${result.filePath}');
} else {
  print('Error: ${result.message}');
}
```

---

## Usage Examples

### Basic Download

```dart
ElevatedButton(
  onPressed: () async {
    final result = await FlutterAnyDownload.instance.download(
      url: 'https://example.com/sample.pdf',
      filename: 'my_file.pdf',
    );

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: ${result.filePath}')),
      );
    }
  },
  child: const Text('Download File'),
);
```

### Download with Progress Callback

```dart
double progress = 0.0;

await FlutterAnyDownload.instance.download(
  url: 'https://example.com/large_file.zip',
  filename: 'archive.zip',
  onProgress: (downloaded, total) {
    setState(() {
      progress = downloaded / total;
    });
  },
  onComplete: (filePath) {
    print('Download complete: $filePath');
  },
  onError: (error) {
    print('Download failed: $error');
  },
);
```

### Silent Download (No Notifications)

```dart
final result = await FlutterAnyDownload.instance.downloadSilent(
  url: 'https://example.com/config.json',
  filename: 'config.json',
  saveToDownloads: false,
);

if (result.success) {
  final file = File(result.filePath!);
  final contents = await file.readAsString();
  print('Config loaded: $contents');
}
```

### Download Multiple Files

```dart
Future<void> downloadMultiple() async {
  final files = [
    {'url': 'https://example.com/file1.pdf', 'name': 'file1.pdf'},
    {'url': 'https://example.com/file2.pdf', 'name': 'file2.pdf'},
    {'url': 'https://example.com/file3.pdf', 'name': 'file3.pdf'},
  ];

  for (int i = 0; i < files.length; i++) {
    final result = await FlutterAnyDownload.instance.download(
      url: files[i]['url']!,
      filename: files[i]['name']!,
      onComplete: (filePath) {
        print('Downloaded ${i + 1}/${files.length}: $filePath');
      },
    );
  }
}
```

### Request & Check Notification Permission

```dart
// Check current status
bool enabled = await FlutterAnyDownload.instance.areNotificationsEnabled();

// Request permission (Android 13+ and iOS)
bool granted = await FlutterAnyDownload.instance.requestPermission();

if (!granted) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permission Required'),
      content: const Text(
        'Enable notifications to see download progress.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

### Cancel All Downloads

```dart
await FlutterAnyDownload.instance.cancelAll();
```

### Full Widget with Progress Bar

```dart
class DownloadWidget extends StatefulWidget {
  const DownloadWidget({super.key});

  @override
  State<DownloadWidget> createState() => _DownloadWidgetState();
}

class _DownloadWidgetState extends State<DownloadWidget> {
  double _progress = 0.0;
  bool _isDownloading = false;
  String _status = 'Ready';
  String? _filePath;

  Future<void> _download() async {
    setState(() {
      _isDownloading = true;
      _status = 'Downloading...';
      _filePath = null;
    });

    final result = await FlutterAnyDownload.instance.download(
      url: 'https://example.com/file.zip',
      filename: 'download.zip',
      onProgress: (downloaded, total) {
        setState(() {
          _progress = downloaded / total;
          _status =
              '${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB / '
              '${(total / 1024 / 1024).toStringAsFixed(2)} MB';
        });
      },
      onComplete: (filePath) {
        setState(() => _filePath = filePath);
      },
    );

    setState(() {
      _isDownloading = false;
      _status = result.success ? 'Complete ✅' : 'Failed ❌';
      if (result.success) _filePath = result.filePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 20),
        Text('${(_progress * 100).toInt()}%'),
        Text(_status),
        if (_filePath != null) ...[
          const SizedBox(height: 10),
          const Text('Saved at:', style: TextStyle(fontWeight: FontWeight.bold)),
          SelectableText(_filePath!, style: const TextStyle(fontSize: 12)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isDownloading ? null : _download,
          child: const Text('Download'),
        ),
      ],
    );
  }
}
```

---

## Platform Configuration

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Notifications (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Storage (Android 9 and below only) -->
    <uses-permission
        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />
    <uses-permission
        android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />

    <application>
        <!-- your app configuration -->
    </application>
</manifest>
```

Update `android/app/build.gradle`:

```gradle
android {
    compileSdk 35

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 35
    }
}
```

### iOS

#### 1. `ios/Runner/Info.plist`

```xml
<!-- Background modes for notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<key>NSUserNotificationAlertStyle</key>
<string>alert</string>

<!-- File sharing -->
<key>UISupportsDocumentBrowser</key>
<true/>

<key>UIFileSharingEnabled</key>
<true/>

<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

#### 2. `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Show notifications while app is in foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}
```

#### 3. `ios/Podfile`

```ruby
platform :ios, '12.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

#### 4. Clean Build (required after iOS config changes)

```bash
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## API Reference

### `initialize()`

Initialize the download manager. Call once in `main()` before `runApp`.

```dart
await FlutterAnyDownload.instance.initialize();
```

### `download()`

Download a file with full control.

```dart
Future<DownloadResult> download({
  required String url,
  required String filename,
  bool showNotification = true,
  bool saveToDownloads = true,
  ProgressCallback? onProgress,
  SuccessCallback? onComplete,
  ErrorCallback? onError,
})
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `url` | `String` | required | URL of the file to download |
| `filename` | `String` | required | Name to save the file as |
| `showNotification` | `bool` | `true` | Show progress notification |
| `saveToDownloads` | `bool` | `true` | Save to Downloads folder (Android) |
| `onProgress` | `ProgressCallback?` | `null` | Called with (downloaded, total) bytes |
| `onComplete` | `SuccessCallback?` | `null` | Called with the saved file path |
| `onError` | `ErrorCallback?` | `null` | Called with error message |

### `downloadSilent()`

Download without notifications.

```dart
Future<DownloadResult> downloadSilent({
  required String url,
  required String filename,
  bool saveToDownloads = false,
})
```

### `requestPermission()`

Request notification permission (required for iOS; Android 13+).

```dart
Future<bool> requestPermission()
```

### `areNotificationsEnabled()`

Check if notification permission is granted.

```dart
Future<bool> areNotificationsEnabled()
```

### `cancelAll()`

Cancel all active downloads.

```dart
Future<void> cancelAll()
```

### Callbacks

```dart
typedef ProgressCallback = void Function(int downloaded, int total);
typedef SuccessCallback  = void Function(String filePath);
typedef ErrorCallback    = void Function(String error);
```

### `DownloadResult`

```dart
class DownloadResult {
  final bool    success;   // true if download succeeded
  final String? filePath;  // absolute path to file (null on failure)
  final String  message;   // human-readable status message
}
```

---

## File Save Locations

| Platform | `saveToDownloads: true` | `saveToDownloads: false` |
|---|---|---|
| Android 10+ | App-specific external storage | App documents directory |
| Android 9 and below | `/storage/emulated/0/Download/` | App documents directory |
| iOS | App documents directory | App documents directory |

Access the exact path via `result.filePath` or the `onComplete` callback.

---

## Accessing Downloaded Files

### Via `DownloadResult`

```dart
final result = await FlutterAnyDownload.instance.download(
  url: 'https://example.com/file.pdf',
  filename: 'document.pdf',
);

if (result.success && result.filePath != null) {
  final file = File(result.filePath!);
  // use file
}
```

### Via `onComplete` Callback

```dart
await FlutterAnyDownload.instance.download(
  url: 'https://example.com/file.pdf',
  filename: 'document.pdf',
  onComplete: (filePath) {
    final file = File(filePath);
    // use file
  },
);
```

### Opening Files (optional, add separately)

```yaml
# pubspec.yaml
dependencies:
  open_filex: ^4.3.0
```

```dart
import 'package:open_filex/open_filex.dart';

await FlutterAnyDownload.instance.download(
  url: 'https://example.com/file.pdf',
  filename: 'document.pdf',
  onComplete: (filePath) async {
    await OpenFilex.open(filePath);
  },
);
```

---

## Troubleshooting

### Notifications not showing on Android

1. Confirm permission is granted:
   ```dart
   await FlutterAnyDownload.instance.requestPermission();
   ```
2. Check `targetSdkVersion` is 33 or higher in `build.gradle`.
3. On the device: **Settings → Apps → Your App → Notifications → ON**.

### Notifications not showing on iOS

1. Verify `Info.plist` has all required keys (see iOS Configuration above).
2. Verify `AppDelegate.swift` sets `UNUserNotificationCenter.current().delegate = self`.
3. Run a **clean build** after any iOS config change.
4. Call `requestPermission()` at app startup — this is mandatory.
5. **Test on a real device** — notifications do not work in the iOS Simulator.
6. On the device: **Settings → Your App → Notifications → Allow Notifications: ON**.
7. Check Xcode console for diagnostic logs:
   ```
   ✅ FlutterAnyDownload initialized successfully
   🔔 iOS notification permission: ✅ GRANTED
   📊 Progress: 25%
   ✅ Completion notification shown
   ```

### File not found after download

Check the path from `result.filePath`:

```dart
final result = await FlutterAnyDownload.instance.download(...);
print('Saved at: ${result.filePath}');
```

---

## Best Practices

- Call `initialize()` once in `main()` before `runApp`.
- Call `requestPermission()` early at app startup, especially on iOS.
- Always check `result.success` and handle failures gracefully.
- Use `onProgress` to display progress indicators for large files.
- Call `cancelAll()` when navigating away from a download screen.
- Store file paths returned from callbacks for later use.
- Always test notifications on a real device (not a simulator).
- Do a clean build after modifying `Info.plist` or `AppDelegate.swift` on iOS.

---

## Common Mistakes

**Forgetting to request permission:**

```dart
// Wrong
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterAnyDownload.instance.initialize();
  runApp(MyApp()); // ← missing requestPermission()
}

// Correct
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterAnyDownload.instance.initialize();
  await FlutterAnyDownload.instance.requestPermission(); // ← required
  runApp(MyApp());
}
```

**Not storing the file path:**

```dart
// Wrong
await FlutterAnyDownload.instance.download(url: url, filename: filename);
// How do I access the file now?

// Correct
final result = await FlutterAnyDownload.instance.download(
  url: url,
  filename: filename,
);
if (result.success) {
  final filePath = result.filePath; // use this
}
```

---

If this package helped you, please leave a ⭐ on [GitHub](https://github.com/sanjaysharmajw/flutter_any_download).

---

**Made with ❤️ for the Flutter community**
