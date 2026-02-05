# Flutter Any Download

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue.svg)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.0.0-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A production-ready, cross-platform download manager for Flutter applications with real-time progress notifications and comprehensive platform integration.

---

## Overview

Flutter Any Download provides a unified API for managing file downloads across iOS and Android platforms. The package handles platform-specific notification systems, permission management, and file storage automatically while providing developers with granular control through callbacks and configuration options.

### Key Features

- **Cross-Platform Consistency**: Single API works seamlessly on iOS and Android with platform-optimized behavior
- **Real-Time Progress Tracking**: Live download progress via both system notifications and programmatic callbacks
- **Smart Notification Management**: Platform-aware notification behavior with automatic permission handling
- **Robust Error Handling**: Comprehensive error detection with user-facing notifications
- **Cancellation Support**: Cancel individual or all downloads with proper cleanup
- **File System Integration**: Automatic file opening on download completion with platform-specific handlers
- **Production Ready**: Extensive validation, error recovery, and edge case handling

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_any_download: ^1.0.0
```

Required peer dependencies (add these as well):

```yaml
dependencies:
  http: ^1.1.0
  path_provider: ^2.1.1
  flutter_local_notifications: ^16.3.0
  permission_handler: ^11.0.1
  open_filex: ^4.3.4
  url_launcher: ^6.2.1
```

Install dependencies:

```bash
flutter pub get
```

---

## Platform Configuration

### Android Setup

#### 1. Manifest Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Network access -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Storage access (legacy support) -->
    <uses-permission 
        android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="32" />
    <uses-permission 
        android:name="android.permission.READ_EXTERNAL_STORAGE" 
        android:maxSdkVersion="32" />
    
    <!-- Notification permission (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application android:label="YourApp">
        <!-- Application configuration -->
    </application>
</manifest>
```

#### 2. Build Configuration

Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.yourapp"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

### iOS Setup

#### 1. Minimum Platform Version

Update `ios/Podfile`:

```ruby
platform :ios, '12.0'

# Ensure this appears at the top of the file
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

#### 2. Privacy Permissions

Add to `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- File storage access -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We need permission to save downloaded files to your device</string>
    
    <!-- Local network access (if downloading from local servers) -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>Access to local network is required to download files from network sources</string>
    
    <!-- File provider capabilities -->
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
    <key>UIFileSharingEnabled</key>
    <true/>
</dict>
```

#### 3. Background Modes (Optional - Recommended)

For improved notification reliability during background operations:

**Using Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select the Runner target
3. Navigate to "Signing & Capabilities"
4. Click "+ Capability" and add "Background Modes"
5. Enable:
    - Background fetch
    - Remote notifications

**Manual Configuration** (`ios/Runner/Info.plist`):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## Quick Start

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_any_download/flutter_any_download.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize download manager
  await FlutterAnyDownload().initialize();
  
  runApp(MyApp());
}

class DownloadExample extends StatefulWidget {
  @override
  _DownloadExampleState createState() => _DownloadExampleState();
}

class _DownloadExampleState extends State<DownloadExample> {
  Future<void> _downloadFile() async {
    final result = await FlutterAnyDownload().downloadFile(
      url: 'https://example.com/document.pdf',
      filename: 'document.pdf',
      showNotification: true,
      saveToDownloadsFolder: true,
    );
    
    if (result.success) {
      print('Download completed: ${result.filePath}');
    } else {
      print('Download failed: ${result.message}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Download Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: _downloadFile,
          child: Text('Download File'),
        ),
      ),
    );
  }
}
```

---

## API Reference

### Initialization

#### `initialize()`

Initializes the download manager and notification system. Must be called before any download operations.

```dart
await FlutterAnyDownload().initialize();
```

**Note**: Safe to call multiple times. Subsequent calls are no-ops.

---

### Permission Management

#### `requestNotificationPermission()`

Requests notification permission from the user. Platform behavior varies:

- **iOS**: Displays system permission dialog on first request
- **Android 13+**: Displays permission dialog
- **Android <13**: Auto-granted, returns `true`

```dart
final bool granted = await FlutterAnyDownload().requestNotificationPermission();

if (!granted) {
  // Handle permission denial
  // iOS: Direct user to Settings
  // Android: Show rationale or continue without notifications
}
```

**Returns**: `Future<bool>` - `true` if permission granted, `false` otherwise

**Best Practice**: Request permission before starting downloads to ensure notifications display properly.

---

### Download Operations

#### `downloadFile()`

Downloads a file from the specified URL with optional progress notifications and callbacks.

```dart
Future<DownloadResult> downloadFile({
  required String url,
  required String filename,
  bool saveToDownloadsFolder = true,
  bool showNotification = true,
  Function(int downloaded, int total)? onProgress,
  Function(String filePath)? onComplete,
  Function(String error)? onError,
})
```

**Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `url` | `String` | Yes | - | Full URL of the file to download |
| `filename` | `String` | Yes | - | Destination filename (with extension) |
| `saveToDownloadsFolder` | `bool` | No | `true` | Save to system Downloads folder (Android only; iOS uses app Documents) |
| `showNotification` | `bool` | No | `true` | Display progress and completion notifications |
| `onProgress` | `Function(int, int)?` | No | `null` | Callback invoked on download progress |
| `onComplete` | `Function(String)?` | No | `null` | Callback invoked on successful completion |
| `onError` | `Function(String)?` | No | `null` | Callback invoked on download failure |

**Returns**: `Future<DownloadResult>`

```dart
class DownloadResult {
  final bool success;        // true if download completed successfully
  final String? filePath;    // Absolute path to downloaded file (null on failure)
  final String message;      // Human-readable status or error message
}
```

**Example with Callbacks**:

```dart
await FlutterAnyDownload().downloadFile(
  url: 'https://cdn.example.com/large-file.zip',
  filename: 'archive.zip',
  showNotification: true,
  
  onProgress: (downloaded, total) {
    final percent = (downloaded / total * 100).toInt();
    print('Download progress: $percent%');
    // Update UI progress indicator
  },
  
  onComplete: (filePath) {
    print('File saved to: $filePath');
    // Navigate to file viewer or show success message
  },
  
  onError: (error) {
    print('Download error: $error');
    // Show error dialog or retry option
  },
);
```

---

#### `cancelAllDownloads()`

Cancels all active downloads and dismisses notifications.

```dart
await FlutterAnyDownload().cancelAllDownloads();
```

**Note**: Partial downloads are deleted from disk automatically.

---

## Advanced Usage

### Production-Ready Download Manager

```dart
import 'package:flutter/material.dart';
import 'package:flutter_any_download/flutter_any_download.dart';
import 'dart:io';

class ProductionDownloadManager extends StatefulWidget {
  @override
  _ProductionDownloadManagerState createState() => _ProductionDownloadManagerState();
}

class _ProductionDownloadManagerState extends State<ProductionDownloadManager> {
  double _progress = 0.0;
  String _status = 'Ready to download';
  bool _isDownloading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeManager();
  }
  
  Future<void> _initializeManager() async {
    await FlutterAnyDownload().initialize();
    
    // Pre-request notification permission on iOS
    if (Platform.isIOS) {
      final granted = await FlutterAnyDownload().requestNotificationPermission();
      
      if (!granted) {
        setState(() {
          _status = 'Notification permission required';
        });
        
        _showPermissionDialog();
      }
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable Notifications'),
        content: Text(
          'Allow notifications to track download progress and receive completion alerts.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Open app settings (requires permission_handler)
              await openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startDownload() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _status = 'Initializing download...';
    });
    
    try {
      final result = await FlutterAnyDownload().downloadFile(
        url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        filename: 'sample_${DateTime.now().millisecondsSinceEpoch}.pdf',
        showNotification: true,
        saveToDownloadsFolder: Platform.isAndroid,
        
        onProgress: (downloaded, total) {
          if (mounted) {
            setState(() {
              _progress = downloaded / total;
              _status = 'Downloading: ${(_progress * 100).toInt()}% '
                       '(${_formatBytes(downloaded)} / ${_formatBytes(total)})';
            });
          }
        },
        
        onComplete: (filePath) {
          if (mounted) {
            setState(() {
              _status = 'Completed: $filePath';
              _progress = 1.0;
              _isDownloading = false;
            });
            
            _showCompletionSnackBar(filePath);
          }
        },
        
        onError: (error) {
          if (mounted) {
            setState(() {
              _status = 'Error: $error';
              _progress = 0.0;
              _isDownloading = false;
            });
            
            _showErrorDialog(error);
          }
        },
      );
      
      if (!result.success && mounted) {
        _showErrorDialog(result.message);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Exception: $e';
          _isDownloading = false;
        });
      }
    }
  }
  
  void _showCompletionSnackBar(String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download completed successfully'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Implement file viewer navigation
          },
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }
  
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Download Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload(); // Retry
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Manager'),
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress indicator
            Container(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isDownloading ? Colors.blue : Colors.green,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isDownloading)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Downloading',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Status message
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            
            SizedBox(height: 40),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startDownload,
                  icon: Icon(Icons.download),
                  label: Text('Start Download'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: _isDownloading
                      ? () async {
                          await FlutterAnyDownload().cancelAllDownloads();
                          setState(() {
                            _status = 'Download cancelled';
                            _progress = 0.0;
                            _isDownloading = false;
                          });
                        }
                      : null,
                  icon: Icon(Icons.cancel),
                  label: Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Platform-Specific Behavior

### Android

**Storage Location**:
- `saveToDownloadsFolder: true` → `/storage/emulated/0/Download/`
- `saveToDownloadsFolder: false` → App-specific directory

**Notifications**:
- Progress notifications appear as "ongoing" (non-dismissible)
- Updates on every 1% progress change
- Completion notification is dismissible with sound/vibration

**Permissions**:
- Auto-granted on Android <13
- Requires user approval on Android 13+

**File Opening**:
- Uses system file manager integration
- Opens with default app for file type

### iOS

**Storage Location**:
- Always saves to app's Documents directory (`saveToDownloadsFolder` parameter ignored)
- Accessible via Files app under "On My iPhone" → Your App

**Notifications**:
- All notifications are dismissible by user
- Updates every 10% (battery optimization)
- Uses time-sensitive interruption level for completion

**Permissions**:
- Always requires explicit user permission
- Permission dialog shown on first request
- If denied, must enable manually in Settings

**File Opening**:
- Limited to app sandbox
- Requires share sheet for external apps
- Cannot access system-wide Downloads folder

**Background Behavior**:
- Notifications may be throttled when app is backgrounded
- Enable Background Modes for improved reliability

---

## iOS Notification Limitations

Due to iOS platform restrictions, notification behavior differs from Android:

### Permission Management

**Mandatory Permission**: iOS requires explicit user permission before any notifications can be displayed. The permission dialog appears when first requested and can only be shown once. If denied, users must manually enable notifications in Settings.

```dart
// Best practice: Check permission before downloads
final granted = await FlutterAnyDownload().requestNotificationPermission();

if (!granted && Platform.isIOS) {
  // Guide user to Settings
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enable Notifications'),
      content: Text(
        'To receive download progress updates, please enable notifications in Settings.'
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await openAppSettings(); // From permission_handler package
          },
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

### Notification Update Frequency

**Throttled Updates**: iOS notifications update every 10% progress change (vs. Android's 1%) to conserve battery and reduce notification spam. This is intentional and follows iOS best practices.

```dart
// iOS progress sequence: 0% → 10% → 20% → 30% ... → 100%
// Android progress sequence: 0% → 1% → 2% → 3% ... → 100%
```

### Background Restrictions

**Throttling**: When the app is in the background, iOS may throttle or delay notifications. To improve reliability:

1. Enable Background Modes in Xcode (see setup instructions)
2. Set completion notifications as "time-sensitive"
3. Consider local notification scheduling for critical updates

### Notification Persistence

**No Ongoing Notifications**: Unlike Android's persistent progress notifications, iOS notifications can always be dismissed by the user. Once dismissed, progress updates will not reappear until the next notification trigger (every 10%).

### Simulator Testing

**Physical Device Required**: iOS Simulator has inconsistent notification behavior. Always test on physical devices for accurate validation of notification functionality.

```dart
if (kDebugMode) {
  print('⚠️ Testing on iOS Simulator - notifications may not appear');
  print('✅ Test on physical device for production validation');
}
```

### File System Limitations

**App Sandbox Only**: Downloaded files are restricted to the app's Documents directory. Users cannot directly save to or access the system-wide Downloads folder like on Android.

**Sharing Files**:
```dart
// Recommend using share_plus package for file export
import 'package:share_plus/share_plus.dart';

await Share.shareXFiles([XFile(downloadedFilePath)], 
  text: 'Downloaded file'
);
```

---

## Troubleshooting

### Common Issues

#### Android: "Notifications not appearing (Android 13+)"

**Cause**: Missing notification permission

**Solution**:
```dart
// Add to AndroidManifest.xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

// Request at runtime
await FlutterAnyDownload().requestNotificationPermission();
```

#### Android: "Downloads not appearing in Downloads folder"

**Cause**: Storage permission or incorrect folder path

**Solution**:
1. Verify manifest permissions include `WRITE_EXTERNAL_STORAGE`
2. Ensure `saveToDownloadsFolder: true` is set
3. Check Android 10+ scoped storage compatibility

#### iOS: "Notifications not appearing at all"

**Cause**: Multiple possible causes

**Solution Checklist**:
1. ✅ Test on physical device (not Simulator)
2. ✅ Verify permission granted: Settings → Your App → Notifications
3. ✅ Check `Info.plist` has required keys
4. ✅ Ensure iOS version ≥ 12.0
5. ✅ Call `initialize()` before downloads

#### iOS: "Cannot open downloaded files"

**Cause**: iOS sandbox restrictions

**Solution**:
```dart
// Option 1: Use share sheet
import 'package:share_plus/share_plus.dart';
await Share.shareXFiles([XFile(filePath)]);

// Option 2: Implement in-app file viewer
// Use packages like flutter_pdfview, image_picker, etc.
```

#### iOS: "Permission dialog not showing second time"

**Cause**: iOS only shows permission dialog once per app install

**Solution**:
```dart
// Direct users to Settings if permission previously denied
if (!permissionGranted) {
  await openAppSettings();
}
```

### Debug Logging

Enable debug logs to troubleshoot issues:

```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  // Package automatically prints debug logs in debug mode
  // Look for logs prefixed with:
  // ✅ - Success operations
  // ❌ - Errors
  // 📱 - iOS-specific logs
  // 🔔 - Notification events
  // 📊 - Progress updates
}
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.1.0 | HTTP client for file downloads |
| `path_provider` | ^2.1.1 | Platform directory access |
| `flutter_local_notifications` | ^16.3.0 | Local notification system |
| `permission_handler` | ^11.0.1 | Runtime permission management |
| `open_filex` | ^4.3.4 | File opening integration |
| `url_launcher` | ^6.2.1 | URL and file URI launching |

---

## Requirements

**Flutter SDK**: ≥ 3.0.0  
**Dart SDK**: ≥ 2.17.0  
**Android**: API Level 21+ (Android 5.0 Lollipop)  
**iOS**: 12.0+

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For major changes, please open an issue first to discuss proposed changes.

---

## Support

**Issues**: [GitHub Issues](https://github.com/yourusername/flutter_any_download/issues)  
**Documentation**: [API Reference](https://pub.dev/documentation/flutter_any_download/latest/)  
**Discussions**: [GitHub Discussions](https://github.com/yourusername/flutter_any_download/discussions)

---

## Changelog

### Version 1.0.0 (Initial Release)

**Features**:
- Cross-platform download support (iOS and Android)
- Real-time progress notifications with platform-specific optimizations
- Comprehensive permission management
- Download cancellation support
- File opening integration
- Progress callbacks for UI integration
- Robust error handling and recovery

**Platform Support**:
- Android: API 21+ with full notification support
- iOS: 12.0+ with platform-optimized notification behavior

**Known Limitations**:
- iOS: Files save to app Documents directory only (system Downloads folder not accessible)
- iOS: Notification updates throttled to 10% intervals per platform best practices
- iOS Simulator: Inconsistent notification behavior (use physical device for testing)

---

## Acknowledgments

Built with Flutter's cross-platform capabilities and leveraging native platform APIs for optimal performance and user experience.

---

**⭐ If you find this package useful, please star it on [GitHub](https://github.com/yourusername/flutter_any_download)!**