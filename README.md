![Logo](https://github.com/sanjaysharmajw/flutter_any_download/blob/main/screenshots/download.jpeg?raw=true)

# Flutter Any Download 📥

Easy-to-use download manager for Flutter with **working progress notifications** for both iOS and Android.

## ✨ Features

- ✅ **Simple API** - Just 3 lines to download a file
- 📊 **Progress Notifications** - Built-in notification with download progress
- 🔔 **iOS & Android Support** - Works seamlessly on both platforms (Android & iOS notifications)
- 🎯 **Callbacks** - Track progress, completion, and errors
- 🚫 **Cancellation** - Cancel downloads anytime
- 🔕 **Silent Downloads** - Download without notifications
- ⚡ **Multiple Downloads** - Download multiple files simultaneously
- 🍎 **iOS Foreground Notifications** - Shows notifications even when app is open
- 📁 **File Path Access** - Get downloaded file path via callbacks

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
   flutter_any_download: ^1.1.8

   # Required dependencies
   http: ^1.1.0
   path_provider: ^2.1.0
   flutter_local_notifications: ^17.0.0
   permission_handler: ^11.0.0
```

**Note:** This version does not include tap-to-open functionality for a simpler, more focused implementation.

## 🚀 Quick Start

### 1. Initialize (in main.dart)

```dart
void main() async {
   WidgetsFlutterBinding.ensureInitialized();

   // Initialize once at app startup
   await FlutterAnyDownload.instance.initialize();

   // ✅ IMPORTANT FOR iOS: Request permission at startup
   await FlutterAnyDownload.instance.requestPermission();

   runApp(MyApp());
}
```

### 2. Download a File

```dart
// Simple download with notification
final result = await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
);

if (result.success) {
print('Downloaded to: ${result.filePath}');
// Use the file path to access the file
} else {
print('Error: ${result.message}');
}
```

That's it! 🎉

## 📖 Usage Examples

### Basic Download

```dart
ElevatedButton(
onPressed: () async {
final result = await FlutterAnyDownload.instance.download(
url: 'https://example.com/sample.pdf',
filename: 'my_file.pdf',
);

if (result.success) {
// File downloaded successfully
print('File saved at: ${result.filePath}');

// Show success message
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Downloaded to: ${result.filePath}')),
);
}
},
child: Text('Download File'),
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
print('Progress: ${(progress * 100).toInt()}%');
});
},
onComplete: (filePath) {
print('Download completed: $filePath');
// File is ready to use at filePath
},
onError: (error) {
print('Download failed: $error');
},
);
```

### Silent Download (No Notifications)

```dart
// Useful for downloading app data, configs, etc.
final result = await FlutterAnyDownload.instance.downloadSilent(
url: 'https://example.com/config.json',
filename: 'config.json',
saveToDownloads: false, // Save to app directory
);

if (result.success) {
// Use the downloaded file
final file = File(result.filePath!);
final contents = await file.readAsString();
print('Config: $contents');
}
```

### Download Multiple Files

```dart
Future<void> downloadMultipleFiles() async {
   final urls = [
      'https://example.com/file1.pdf',
      'https://example.com/file2.pdf',
      'https://example.com/file3.pdf',
   ];

   for (int i = 0; i < urls.length; i++) {
      final result = await FlutterAnyDownload.instance.download(
         url: urls[i],
         filename: 'file${i + 1}.pdf',
         onComplete: (filePath) {
            print('Downloaded ${i + 1}/3: $filePath');
         },
      );
   }
}
```

### Request Notification Permission

```dart
// Check if notifications are enabled
bool enabled = await FlutterAnyDownload.instance.areNotificationsEnabled();

// Request permission (Android 13+ and iOS)
bool granted = await FlutterAnyDownload.instance.requestPermission();

if (!granted) {
// Show dialog explaining why permission is needed
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text('Permission Required'),
content: Text('Please enable notifications to see download progress.'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text('OK'),
),
],
),
);
}
```

### Cancel Downloads

```dart
// Cancel all active downloads
await FlutterAnyDownload.instance.cancelAll();
```

### Complete Widget Example with Progress Bar

```dart
class DownloadWidget extends StatefulWidget {
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
               _status = '${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB / ${(total / 1024 / 1024).toStringAsFixed(2)} MB';
            });
         },
         onComplete: (filePath) {
            setState(() {
               _filePath = filePath;
            });
         },
      );

      setState(() {
         _isDownloading = false;
         _status = result.success ? 'Complete! ✅' : 'Failed ❌';
         if (result.success) {
            _filePath = result.filePath;
         }
      });
   }

   @override
   Widget build(BuildContext context) {
      return Column(
         children: [
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 20),
            Text('${(_progress * 100).toInt()}%'),
            Text(_status),
            if (_filePath != null) ...[
               SizedBox(height: 10),
               Text('Saved at:', style: TextStyle(fontWeight: FontWeight.bold)),
               SelectableText(_filePath!, style: TextStyle(fontSize: 12)),
            ],
            SizedBox(height: 20),
            ElevatedButton(
               onPressed: _isDownloading ? null : _download,
               child: Text('Download'),
            ),
         ],
      );
   }
}
```

## 📱 Platform Configuration

### Android Configuration

1. Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
   <!-- Internet permission -->
   <uses-permission android:name="android.permission.INTERNET" />

   <!-- Notification permission (Android 13+) -->
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

   <!-- Storage permissions -->
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
           android:maxSdkVersion="32" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
           android:maxSdkVersion="32" />

   <application>
      <!-- Your app configuration -->
   </application>
</manifest>
```

2. Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### iOS Configuration (IMPORTANT - Follow Exactly!)

#### 1. Update `ios/Runner/Info.plist`:

Add these keys to enable notifications and file access:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
   <dict>
      <!-- Your existing keys... -->

      <!-- CRITICAL: Notification permissions -->
      <key>UIBackgroundModes</key>
      <array>
         <string>fetch</string>
         <string>remote-notification</string>
      </array>

      <key>NSUserNotificationAlertStyle</key>
      <string>alert</string>

      <!-- File access permissions -->
      <key>NSPhotoLibraryUsageDescription</key>
      <string>We need access to save your downloaded files</string>

      <key>NSPhotoLibraryAddUsageDescription</key>
      <string>We need permission to save downloaded files</string>

      <!-- Document support -->
      <key>UISupportsDocumentBrowser</key>
      <true/>

      <key>UIFileSharingEnabled</key>
      <true/>

      <key>LSSupportsOpeningDocumentsInPlace</key>
      <true/>
   </dict>
</plist>
```

#### 2. Update `ios/Runner/AppDelegate.swift`:

Replace the entire file with this:

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

      // CRITICAL: Set notification center delegate
      if #available(iOS 10.0, *) {
         UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }

   //CRITICAL: Handle foreground notifications
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

#### 3. Update `ios/Podfile`:

Ensure minimum iOS version:

```ruby
platform :ios, '12.0'

# Post install hook
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

#### 4. Clean Build (MANDATORY):

```bash
cd ios
rm -rf Pods Podfile.lock
cd ..
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

## 🎯 API Reference

### Main Methods

#### `initialize()`
Initialize the download manager. Call once in `main()`.

```dart
await FlutterAnyDownload.instance.initialize();
```

#### `download()`
Download a file with full control over options.

```dart
Future<DownloadResult> download({
required String url,              // File URL
required String filename,         // Save as filename
bool showNotification = true,     // Show progress notification
bool saveToDownloads = true,      // Save to Downloads folder (Android)
ProgressCallback? onProgress,     // Progress callback
SuccessCallback? onComplete,      // Success callback with file path
ErrorCallback? onError,           // Error callback
})
```

#### `downloadSilent()`
Quick download without notifications.

```dart
Future<DownloadResult> downloadSilent({
required String url,
required String filename,
bool saveToDownloads = false,
})
```

#### `requestPermission()`
Request notification permission.

```dart
Future<bool> requestPermission()
```

#### `areNotificationsEnabled()`
Check if notifications are enabled.

```dart
Future<bool> areNotificationsEnabled()
```

#### `cancelAll()`
Cancel all active downloads.

```dart
Future<void> cancelAll()
```

### Callbacks

```dart
typedef ProgressCallback = void Function(int downloaded, int total);
typedef SuccessCallback = void Function(String filePath);
typedef ErrorCallback = void Function(String error);
```

### Download Result

```dart
class DownloadResult {
   final bool success;        // Whether download succeeded
   final String? filePath;    // Path to downloaded file (null if failed)
   final String message;      // Human-readable message
}
```

## 📁 Accessing Downloaded Files

Since this version focuses on notifications only (without tap-to-open), you can access downloaded files through:

### Option 1: Via Callbacks

```dart
await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
onComplete: (filePath) {
print('File available at: $filePath');

// Use the file as needed
final file = File(filePath);
// Process file...
},
);
```

### Option 2: Via DownloadResult

```dart
final result = await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
);

if (result.success && result.filePath != null) {
final file = File(result.filePath!);
// Use file...
}
```

### Option 3: Implement Custom File Opening

If you need to open files, you can add your own logic:

```dart
// Add to pubspec.yaml if needed:
// open_filex: ^4.3.0

import 'package:open_filex/open_filex.dart';

final result = await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
onComplete: (filePath) async {
// Open the file with default app
await OpenFilex.open(filePath);
},
);
```

## 🔧 Advanced Usage

### Custom Save Location

```dart
// Save to Downloads folder (Android only)
await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
saveToDownloads: true,  // Android: /storage/emulated/0/Download
// iOS: App Documents directory
);

// Save to app directory
await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
saveToDownloads: false,  // App's Documents directory
);
```

### Error Handling

```dart
try {
final result = await FlutterAnyDownload.instance.download(
url: 'https://example.com/file.pdf',
filename: 'document.pdf',
onError: (error) {
print('Download error: $error');
},
);

if (!result.success) {
// Handle download failure
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text('Download Failed'),
content: Text(result.message),
),
);
}
} catch (e) {
print('Exception: $e');
}
```

## 🐛 Troubleshooting

### Notifications Not Showing on Android

1. Check if permission is granted:
```dart
bool granted = await FlutterAnyDownload.instance.requestPermission();
```

2. Ensure you're targeting Android 13+ in build.gradle:
```gradle
targetSdkVersion 34
```

3. Check device notification settings:
   - Settings → Apps → Your App → Notifications → ON

### Notifications Not Showing on iOS

**This is the most common issue! Follow these steps:**

1. ✅ **Verify Info.plist** has all required keys (see iOS Configuration above)

2. ✅ **Verify AppDelegate.swift** has the notification delegate setup (see iOS Configuration above)

3. ✅ **Clean build** after making changes:
```bash
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter clean && flutter pub get
cd ios && pod install && cd ..
```

4. ✅ **Request permission explicitly** in your code:
```dart
void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   await FlutterAnyDownload.instance.initialize();
   await FlutterAnyDownload.instance.requestPermission();  // ← CRITICAL!
   runApp(MyApp());
}
```

5. ✅ **Test on REAL DEVICE** (not simulator - notifications don't work properly on simulator)

6. ✅ **Check device settings**:
   - Settings → Your App → Notifications → Allow Notifications: ON
   - Settings → Your App → Notifications → Sounds: ON
   - Settings → Your App → Notifications → Badges: ON

7. ✅ **Check Do Not Disturb** is OFF

8. ✅ **Check Xcode console** for logs:
```
✅ FlutterAnyDownload initialized successfully
🔔 iOS notification permission: ✅ GRANTED
📊 Progress: 25%
✅ Completion notification shown
```

### File Not Found After Download

The file is saved to:
- **Android (saveToDownloads: true)**: `/storage/emulated/0/Download/filename`
- **Android (saveToDownloads: false)**: App's Documents directory
- **iOS**: Always app's Documents directory

Check the `filePath` in `DownloadResult`:
```dart
final result = await FlutterAnyDownload.instance.download(...);
print('File saved at: ${result.filePath}');
```

## 📝 Best Practices

1. **Initialize Once**: Call `initialize()` only once in `main()`
2. **Request Permissions Early**: Request notification permission at app startup (especially for iOS)
3. **Handle Errors**: Always check `result.success` and handle failures
4. **Show Progress**: Use `onProgress` callback for better UX on large files
5. **Cancel When Needed**: Call `cancelAll()` when user navigates away
6. **Test on Real Devices**: Notifications behave differently on simulators (especially iOS)
7. **iOS Clean Builds**: After changing Info.plist or AppDelegate.swift, always do a clean build
8. **Store File Paths**: Save file paths from callbacks for later use

## iOS Notification Features

### What's Fixed in This Version:

- ✅ **Foreground Notifications**: Notifications now show even when app is open
- ✅ **Progress Updates**: Shows download progress every 5% (0% → 5% → 10%...)
- ✅ **Completion Notification**: Shows success notification with sound
- ✅ **Error Notifications**: Shows failure notification if download fails
- ✅ **Proper Permission Flow**: Uses iOS native API correctly
- ✅ **Unique Notification IDs**: No notification collision
- ✅ **Time-Sensitive Priority**: High priority for important notifications
- ✅ **Sound & Badge Support**: Plays sound and shows badge count

### iOS Notification Behavior:

- **Progress Notifications**: Updates every 5% (reduces spam)
- **Completion Notification**: Shows with sound and high priority
- **Badge Count**: Shows download percentage as badge
- **Foreground Display**: Shows notifications even when app is in foreground
- **No Tap Action**: Notifications are informational only (file path provided via callbacks)

## 🚨 Common Mistakes to Avoid

### Wrong - Forgetting Permission Request
```dart
void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   await FlutterAnyDownload.instance.initialize();
   // Missing requestPermission() call!
   runApp(MyApp());
}
```

### Correct - Request Permission
```dart
void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   await FlutterAnyDownload.instance.initialize();
   await FlutterAnyDownload.instance.requestPermission();  // ← Add this!
   runApp(MyApp());
}
```

### Wrong - Not Storing File Path
```dart
await FlutterAnyDownload.instance.download(
url: url,
filename: filename,
);
// How do I access the file now? 🤔
```

### Correct - Store File Path
```dart
String? downloadedFilePath;

final result = await FlutterAnyDownload.instance.download(
    url: url,
    filename: filename,
    onComplete: (filePath) {
d   ownloadedFilePath = filePath;
// Now you can use it!
        },
      );

// Or use result.filePath
if (result.success) {
downloadedFilePath = result.filePath;
}
```

### Wrong - Testing on iOS Simulator
```
Notifications do not work properly in the iOS Simulator.
```

### Correct - Test on Real Device
```
Always test on real iOS device for notifications
```

### Correct - Always Clean Build
```bash
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter clean && flutter pub get
cd ios && pod install && cd ..
```

### What's Included:
- Download progress notifications
- Download completion notifications
- Error notifications
- File path access via callbacks and `DownloadResult`
- iOS & Android support
- All core download functionality

If this package helped you, please give it a ⭐ on GitHub!
---

**Made with ❤️ for Flutter developers**

**Simple, Clean, and Focused on Downloads + Notifications!**