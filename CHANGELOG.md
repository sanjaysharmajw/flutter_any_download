## 1.2.0

* **New:** `downloadMultiple()` — download a batch of files sequentially or concurrently in one call, with per-item progress/complete/error callbacks, instead of hand-writing a loop
* **New:** `cancel(taskId)` to cancel a single in-flight download; pair it with the new `onTaskCreated` callback on `download()` to get the id
* **New:** `activeDownloads` getter exposes live `DownloadTask`s (progress, status) for building a "multiple downloads" screen — these model classes were previously exported but unused internally
* **Fix:** Concurrent downloads no longer share one hardcoded notification id — each download now gets its own progress/complete/error notification lane, so simultaneous downloads display independent progress bars instead of overwriting each other
* **Fix:** Task ids are now generated from a monotonic counter instead of `DateTime.now().millisecondsSinceEpoch`, which could collide (and silently drop a tracked download) when two downloads started in the same millisecond
* **Fix:** Cancelling a download now returns `DownloadResult(cancelled: true, ...)` and skips the "❌ Download Failed" notification, instead of surfacing a user-initiated cancel as an error
* **Breaking (undocumented API only):** Removed the internal-use duplicate methods `downloadFile()`, `requestNotificationPermission()` and `cancelAllDownloads()` — they were unused thin wrappers around `download()`, `requestPermission()` and `cancelAll()` respectively and were never mentioned in the README; use the documented method names instead
* **Docs:** README updated with `downloadMultiple`, single-download cancellation, and `activeDownloads` usage

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
