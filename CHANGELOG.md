## 1.1.9

* **Bug fix:** Fixed resource leak — `IOSink` and `http.Client` are now properly closed when a network exception occurs mid-stream
* **Bug fix:** Fixed `..withValues()` cascade operator bug in example app — alpha transparency was not being applied on 8 UI elements
* **Refactor:** Merged redundant duplicate branches for Android 10 and Android 11+ in `_getSavePath` (both used identical scoped storage logic)
* **Refactor:** Moved `_lastNotificationProgress` from a shared instance variable to a per-download local variable, fixing potential interference between concurrent downloads
* **Cleanup:** Removed `lib/demo.dart` — file contained only commented-out duplicate code
* **Docs:** Updated README with correct dependency versions, fixed code typo, corrected `WRITE_EXTERNAL_STORAGE` `maxSdkVersion` (28, not 32), and full professional rewrite

## 1.1.8

* In Android 10: PathAccessException - Cannot open file - Solved

## 1.1.7

* Minor bug fixed

## 1.1.6

* Minor bug fixed

## 1.1.5

* iOS Notification issue fixed

## 1.1.1

* Initial release
* Cross-platform download support (iOS & Android)
* Real-time progress notifications
* Cancellation support
* File opening integration
* Comprehensive error handling
