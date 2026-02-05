// library;
//
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// export 'src/download_status.dart';
// export 'src/download_task.dart';
//
// /// Main download manager class with iOS and Android support.
// class FlutterAnyDownload {
//   static final FlutterAnyDownload _instance = FlutterAnyDownload._internal();
//   factory FlutterAnyDownload() => _instance;
//   FlutterAnyDownload._internal();
//
//   final FlutterLocalNotificationsPlugin _notificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   final Map<String, CancelToken> _downloadTasks = {};
//   bool _isInitialized = false;
//   static const int _notificationId = 1001;
//
//   /// Tracks the last percentage we pushed to the notification so that we only
//   /// update it when the value actually changes.
//   int _lastNotificationProgress = -1;
//
//   // ---------------------------------------------------------------------------
//   // Initialisation
//   // ---------------------------------------------------------------------------
//
//   /// Initialise the download manager and the local-notifications plugin.
//   ///
//   /// Safe to call multiple times – only the first call does real work.
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     try {
//       // Build InitializationSettings with ONLY the current platform's settings.
//       final InitializationSettings initSettings;
//
//       if (Platform.isAndroid) {
//         initSettings = const InitializationSettings(
//           android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//         );
//       } else if (Platform.isIOS) {
//         // iOS ke liye notification settings - permissions manually request karenge
//         final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
//           requestAlertPermission: false,
//           requestBadgePermission: false,
//           requestSoundPermission: false,
//           onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
//             // iOS 10 se pehle ke liye (legacy)
//             if (kDebugMode) {
//               print('📱 Legacy iOS notification received: $title');
//             }
//           },
//         );
//
//         initSettings = InitializationSettings(iOS: iOSSettings);
//       } else {
//         // Desktop / web
//         _isInitialized = true;
//         return;
//       }
//
//       // Plugin initialize karo
//       final bool? initialized = await _notificationsPlugin.initialize(
//         initSettings,
//         onDidReceiveNotificationResponse: _onNotificationTap,
//       );
//
//       if (kDebugMode) {
//         print('✅ Notification plugin initialized: $initialized for ${Platform.isIOS ? "iOS" : "Android"}');
//       }
//
//       // iOS ke liye explicitly permission request karo
//       if (Platform.isIOS) {
//         await _requestIOSPermissions();
//       }
//
//       _isInitialized = true;
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error initializing notifications: $e');
//       }
//       _isInitialized = true; // Mark as initialized to prevent infinite retry
//     }
//   }
//
//   /// iOS ke liye notification permissions request karo
//   Future<bool> _requestIOSPermissions() async {
//     try {
//       final iosPlugin = _notificationsPlugin
//           .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
//
//       if (iosPlugin == null) {
//         if (kDebugMode) {
//           print('❌ iOS plugin not found');
//         }
//         return false;
//       }
//
//       final bool? granted = await iosPlugin.requestPermissions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//
//       if (kDebugMode) {
//         print('📱 iOS notification permission: ${granted == true ? "GRANTED ✅" : "DENIED ❌"}');
//       }
//
//       return granted ?? false;
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error requesting iOS permissions: $e');
//       }
//       return false;
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Notification tap handler
//   // ---------------------------------------------------------------------------
//
//   /// Called when the user taps a notification.  The payload contains the
//   /// absolute path of the downloaded file.
//   Future<void> _onNotificationTap(NotificationResponse response) async {
//     final String? path = response.payload;
//     if (path == null || path.isEmpty) return;
//
//     if (kDebugMode) {
//       print('🔔 Notification tapped with payload: $path');
//     }
//
//     if (Platform.isAndroid) {
//       try {
//         await OpenFilex.open(path);
//       } catch (e) {
//         if (kDebugMode) {
//           print('❌ Error opening file on Android: $e');
//         }
//       }
//     } else if (Platform.isIOS) {
//       try {
//         final Uri uri = Uri.file(path);
//         final bool canLaunch = await canLaunchUrl(uri);
//
//         if (kDebugMode) {
//           print('Can launch file URI: $canLaunch');
//         }
//
//         if (canLaunch) {
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } else {
//           // Try alternative approach
//           final String shareableUri = 'shareddocuments://$path';
//           final Uri fallbackUri = Uri.parse(shareableUri);
//
//           if (await canLaunchUrl(fallbackUri)) {
//             await launchUrl(fallbackUri);
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print('❌ Error opening file on iOS: $e');
//         }
//       }
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Permission
//   // ---------------------------------------------------------------------------
//
//   /// Request notification permission.
//   ///
//   /// * Android 13+ – uses permission_handler for POST_NOTIFICATIONS.
//   /// * iOS – asks the plugin for alert / badge / sound permission.
//   Future<bool> requestNotificationPermission() async {
//     if (Platform.isAndroid) {
//       // Android 13+ ke liye
//       try {
//         final PermissionStatus status = await Permission.notification.request();
//
//         if (kDebugMode) {
//           print('📱 Android notification permission: ${status.toString()}');
//         }
//
//         return status.isGranted;
//       } catch (e) {
//         if (kDebugMode) {
//           print('Android notification permission error: $e');
//         }
//         return true; // Below Android 13, automatically granted
//       }
//     } else if (Platform.isIOS) {
//       try {
//         final iosPlugin = _notificationsPlugin
//             .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
//
//         if (iosPlugin == null) {
//           if (kDebugMode) {
//             print('❌ iOS plugin not found');
//           }
//           return false;
//         }
//
//         final bool? granted = await iosPlugin.requestPermissions(
//           alert: true,
//           badge: true,
//           sound: true,
//         );
//
//         if (kDebugMode) {
//           print('📱 iOS notification permission: ${granted == true ? "GRANTED ✅" : "DENIED ❌"}');
//         }
//
//         return granted ?? false;
//       } catch (e) {
//         if (kDebugMode) {
//           print('❌ iOS permission request error: $e');
//         }
//         return false;
//       }
//     }
//     return true;
//   }
//
//   // ---------------------------------------------------------------------------
//   // Download
//   // ---------------------------------------------------------------------------
//
//   /// Download a file from [url], write it to disk as [filename], and
//   /// (optionally) show live progress in a local notification.
//   Future<DownloadResult> downloadFile({
//     required String url,
//     required String filename,
//     bool saveToDownloadsFolder = true,
//     bool showNotification = true,
//     Function(int, int)? onProgress,
//     Function(String)? onComplete,
//     Function(String)? onError,
//   }) async {
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
//     final CancelToken cancelToken = CancelToken();
//     _downloadTasks[taskId] = cancelToken;
//
//     _lastNotificationProgress = -1;
//
//     try {
//       // Permission check - iOS ke liye mandatory
//       if (showNotification) {
//         final bool permissionGranted = await requestNotificationPermission();
//         if (kDebugMode) {
//           print('🔔 Notification permission for download: ${permissionGranted ? "YES ✅" : "NO ❌"}');
//         }
//
//         if (!permissionGranted) {
//           if (kDebugMode) {
//             print('⚠️  Warning: Notification permission not granted. Notifications will not show.');
//           }
//           // iOS me permission nahi hai to notification disable kar do
//           if (Platform.isIOS) {
//             showNotification = false;
//           }
//         }
//       }
//
//       final String savePath = await _getSavePath(filename, saveToDownloadsFolder);
//
//       if (kDebugMode) {
//         print('💾 Download save path: $savePath');
//       }
//
//       final http.Client client = http.Client();
//       final http.Request request = http.Request('GET', Uri.parse(url));
//       final http.StreamedResponse response = await client.send(request);
//
//       if (response.statusCode != 200) {
//         client.close();
//         throw Exception('HTTP ${response.statusCode}');
//       }
//
//       final int contentLength = response.contentLength ?? 0;
//       final File file = File(savePath);
//       final IOSink sink = file.openWrite();
//       int downloaded = 0;
//
//       // Initial notification show karo
//       if (showNotification) {
//         await _showProgressNotification(filename, 0, 100);
//         _lastNotificationProgress = 0;
//
//         if (kDebugMode) {
//           print('🔔 Initial progress notification shown');
//         }
//       }
//
//       await for (final List<int> chunk in response.stream) {
//         if (cancelToken.isCancelled) {
//           await sink.close();
//           client.close();
//           if (await file.exists()) await file.delete();
//           throw Exception('Download cancelled');
//         }
//
//         sink.add(chunk);
//         downloaded += chunk.length;
//
//         if (contentLength > 0) {
//           final int progress = ((downloaded / contentLength) * 100).toInt();
//
//           // Progress update - iOS ke liye har 10% par update
//           final bool shouldUpdate = Platform.isIOS
//               ? (progress % 10 == 0 && progress != _lastNotificationProgress)
//               : (progress != _lastNotificationProgress);
//
//           if (showNotification && shouldUpdate) {
//             await _showProgressNotification(filename, progress, 100);
//             _lastNotificationProgress = progress;
//
//             if (kDebugMode && progress % 20 == 0) {
//               print('📊 Progress: $progress%');
//             }
//           }
//
//           onProgress?.call(downloaded, contentLength);
//         }
//       }
//
//       await sink.close();
//       client.close();
//       _downloadTasks.remove(taskId);
//
//       // File write complete hone ka wait
//       await Future.delayed(const Duration(milliseconds: 200));
//
//       if (showNotification) {
//         // iOS me turant notification show karo
//         await _showCompletedNotification(filename, savePath);
//
//         if (kDebugMode) {
//           print('✅ Download completed notification shown immediately');
//         }
//       }
//
//       onComplete?.call(savePath);
//
//       return DownloadResult(
//         success: true,
//         filePath: savePath,
//         message: 'Download completed successfully',
//       );
//     } catch (e) {
//       _downloadTasks.remove(taskId);
//
//       if (showNotification) {
//         await _showErrorNotification(filename, e.toString());
//       }
//
//       onError?.call(e.toString());
//
//       return DownloadResult(
//         success: false,
//         filePath: null,
//         message: 'Download failed: $e',
//       );
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // File-path helpers
//   // ---------------------------------------------------------------------------
//
//   /// Return the destination path for [filename].
//   Future<String> _getSavePath(String filename, bool useDownloadsFolder) async {
//     if (Platform.isAndroid && useDownloadsFolder) {
//       final Directory downloads = Directory('/storage/emulated/0/Download');
//       if (await downloads.exists()) {
//         return '${downloads.path}/$filename';
//       }
//     }
//
//     // iOS always lands here
//     final Directory docs = await getApplicationDocumentsDirectory();
//     return '${docs.path}/$filename';
//   }
//
//   // ---------------------------------------------------------------------------
//   // Notification helpers
//   // ---------------------------------------------------------------------------
//
//   /// Show (or update) the ongoing progress notification.
//   Future<void> _showProgressNotification(
//       String filename,
//       int progress,
//       int maxProgress,
//       ) async {
//     try {
//       NotificationDetails details;
//
//       if (Platform.isAndroid) {
//         details = NotificationDetails(
//           android: AndroidNotificationDetails(
//             'download_channel',
//             'Downloads',
//             channelDescription: 'Download progress notifications',
//             importance: Importance.low,
//             priority: Priority.low,
//             showProgress: true,
//             maxProgress: maxProgress,
//             progress: progress,
//             ongoing: true,
//             autoCancel: false,
//             playSound: false,
//             onlyAlertOnce: true,
//           ),
//         );
//       } else if (Platform.isIOS) {
//         // iOS ke liye notification with body text
//         details = NotificationDetails(
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: false,
//             badgeNumber: progress,
//             threadIdentifier: 'download_progress',
//           ),
//         );
//       } else {
//         return;
//       }
//
//       await _notificationsPlugin.show(
//         _notificationId,
//         'Downloading: $filename',
//         'Progress: $progress%',
//         details,
//       );
//
//       if (kDebugMode && Platform.isIOS) {
//         print('🔔 iOS Progress notification sent: $progress%');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error showing progress notification: $e');
//       }
//     }
//   }
//
//   /// Replace the progress notification with a "completed" notification.
//   /// iOS me bina delay ke turant show hota hai
//   Future<void> _showCompletedNotification(
//       String filename,
//       String filePath,
//       ) async {
//     try {
//       // Previous notification cancel karo
//       await _notificationsPlugin.cancel(_notificationId);
//
//       // Notification clear hone ka wait
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       NotificationDetails details;
//
//       if (Platform.isAndroid) {
//         details = NotificationDetails(
//           android: AndroidNotificationDetails(
//             'download_channel',
//             'Downloads',
//             channelDescription: 'Download completion notifications',
//             importance: Importance.high,
//             priority: Priority.high,
//             autoCancel: true,
//             playSound: true,
//             showProgress: false,
//             ongoing: false,
//             enableVibration: true,
//             visibility: NotificationVisibility.public,
//           ),
//         );
//       } else if (Platform.isIOS) {
//         // iOS ke liye high priority completion notification
//         details = NotificationDetails(
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//             badgeNumber: 0,
//             threadIdentifier: 'download_complete',
//             // iOS 15+ ke liye interruption level
//             interruptionLevel: InterruptionLevel.timeSensitive,
//           ),
//         );
//       } else {
//         return;
//       }
//
//       // New completion notification show karo
//       await _notificationsPlugin.show(
//         _notificationId + 1, // Different ID for completion
//         filename,
//         'Download Complete! Tap to open',
//         details,
//         payload: filePath,
//       );
//
//       if (kDebugMode) {
//         print('✅ Completed notification shown for: $filename');
//         print('📂 File path: $filePath');
//         if (Platform.isIOS) {
//           print('🔔 iOS completion notification ID: ${_notificationId + 1}');
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error showing completed notification: $e');
//         print('Stack trace: ${StackTrace.current}');
//       }
//     }
//   }
//
//   /// Replace the progress notification with a "failed" notification.
//   Future<void> _showErrorNotification(String filename, String error) async {
//     try {
//       await _notificationsPlugin.cancel(_notificationId);
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       NotificationDetails details;
//
//       if (Platform.isAndroid) {
//         details = NotificationDetails(
//           android: AndroidNotificationDetails(
//             'download_channel',
//             'Downloads',
//             channelDescription: 'Download notifications',
//             importance: Importance.high,
//             priority: Priority.high,
//             showProgress: false,
//             ongoing: false,
//             autoCancel: true,
//             playSound: true,
//             enableVibration: true,
//             visibility: NotificationVisibility.public,
//           ),
//         );
//       } else if (Platform.isIOS) {
//         details = NotificationDetails(
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//             badgeNumber: 0,
//             threadIdentifier: 'download_error',
//             interruptionLevel: InterruptionLevel.timeSensitive,
//           ),
//         );
//       } else {
//         return;
//       }
//
//       await _notificationsPlugin.show(
//         _notificationId + 2, // Different ID for error
//         filename,
//         'Download Failed: ${error.length > 50 ? error.substring(0, 50) + '...' : error}',
//         details,
//       );
//
//       if (kDebugMode) {
//         print('❌ Error notification shown for: $filename');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error showing error notification: $e');
//       }
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Cancellation
//   // ---------------------------------------------------------------------------
//
//   /// Cancel every in-flight download and dismiss the notification.
//   Future<void> cancelAllDownloads() async {
//     for (final CancelToken token in _downloadTasks.values) {
//       token.cancel();
//     }
//     _downloadTasks.clear();
//     await _notificationsPlugin.cancelAll();
//   }
// }
//
// // ---------------------------------------------------------------------------
// // Supporting classes
// // ---------------------------------------------------------------------------
//
// /// Lightweight cancellation token checked on every stream chunk.
// class CancelToken {
//   bool _isCancelled = false;
//   bool get isCancelled => _isCancelled;
//   void cancel() => _isCancelled = true;
// }
//
// /// Returned by [FlutterAnyDownload.downloadFile].
// class DownloadResult {
//   final bool success;
//   final String? filePath;
//   final String message;
//
//   DownloadResult({
//     required this.success,
//     required this.filePath,
//     required this.message,
//   });
// }