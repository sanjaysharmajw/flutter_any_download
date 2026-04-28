import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

export 'src/download_status.dart';
export 'src/download_task.dart';

/// Simple, easy-to-use download manager for Flutter (iOS & Android)
/// With iOS notification support (tap-to-open removed)
class FlutterAnyDownload {
  static final FlutterAnyDownload instance = FlutterAnyDownload._internal();
  factory FlutterAnyDownload() => instance;
  FlutterAnyDownload._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final Map<String, _CancelToken> _downloadTasks = {};
  bool _isInitialized = false;
  bool _iosPermissionGranted = false;
  static const int _baseNotificationId = 1000;
  int _notificationCounter = 0;

  // ---------------------------------------------------------------------------
  // INITIALIZATION - iOS Fixed
  // ---------------------------------------------------------------------------

  /// Initialize the download manager (call this once in main())
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        await _initializeAndroid();
      } else if (Platform.isIOS) {
        await _initializeIOS();
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ FlutterAnyDownload initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing: $e');
      }
      _isInitialized = true;
    }
  }

  Future<void> _initializeAndroid() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  Future<void> _initializeIOS() async {
    await _requestIOSPermissions();
    final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(iOS: iOSSettings);

    final bool? initialized = await _notificationsPlugin.initialize(settings: initSettings);

    if (kDebugMode) {
      print('✅ iOS Plugin initialized: $initialized');
      print('🔔 iOS Permission granted: $_iosPermissionGranted');
    }
  }

  Future<bool> _requestIOSPermissions() async {
    try {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin == null) {
        if (kDebugMode) print('❌ iOS plugin not available');
        return false;
      }

      // Request permissions
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _iosPermissionGranted = granted ?? false;

      if (kDebugMode) {
        print('🔔 iOS notification permission: ${_iosPermissionGranted ? "✅ GRANTED" : "❌ DENIED"}');
      }

      return _iosPermissionGranted;
    } catch (e) {
      if (kDebugMode) print('❌ iOS permission error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  /// Download a file with progress notifications
  Future<DownloadResult> download({
    required String url,
    required String filename,
    bool showNotification = true,
    bool saveToDownloads = true,
    ProgressCallback? onProgress,
    SuccessCallback? onComplete,
    ErrorCallback? onError,
  }) async {
    return downloadFile(
      url: url,
      filename: filename,
      saveToDownloadsFolder: saveToDownloads,
      showNotification: showNotification,
      onProgress: onProgress,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Quick download without notifications
  Future<DownloadResult> downloadSilent({
    required String url,
    required String filename,
    bool saveToDownloads = false,
  }) async {
    return download(
      url: url,
      filename: filename,
      showNotification: false,
      saveToDownloads: saveToDownloads,
    );
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    return requestNotificationPermission();
  }

  /// Cancel all active downloads
  Future<void> cancelAll() async {
    return cancelAllDownloads();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      return _iosPermissionGranted;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // INTERNAL IMPLEMENTATION
  // ---------------------------------------------------------------------------

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.request();
        return status.isGranted;
      } catch (e) {
        return true;
      }
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }
    return true;
  }

  Future<DownloadResult> downloadFile({
    required String url,
    required String filename,
    bool saveToDownloadsFolder = true,
    bool showNotification = true,
    ProgressCallback? onProgress,
    SuccessCallback? onComplete,
    ErrorCallback? onError,
  }) async {
    if (!_isInitialized) await initialize();

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = _CancelToken();
    _downloadTasks[taskId] = cancelToken;
    int lastNotificationProgress = -1;

    http.Client? client;
    IOSink? sink;

    try {
      // iOS permission check - MANDATORY
      if (showNotification && Platform.isIOS) {
        if (!_iosPermissionGranted) {
          if (kDebugMode) {
            print('⚠️  iOS notification permission not granted. Requesting...');
          }
          _iosPermissionGranted = await _requestIOSPermissions();
        }

        if (!_iosPermissionGranted) {
          if (kDebugMode) {
            print('❌ iOS notifications disabled - permission denied');
          }
          showNotification = false;
        }
      }

      final savePath = await _getSavePath(filename, saveToDownloadsFolder);

      if (kDebugMode) {
        print('💾 Downloading to: $savePath');
      }

      client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final file = File(savePath);
      sink = file.openWrite();
      int downloaded = 0;

      // Show initial notification
      if (showNotification) {
        await _showProgressNotification(filename, 0, 100);
        lastNotificationProgress = 0;
      }

      await for (final chunk in response.stream) {
        if (cancelToken.isCancelled) {
          await sink!.close();
          sink = null;
          client!.close();
          client = null;
          if (await file.exists()) await file.delete();
          throw Exception('Download cancelled');
        }

        sink!.add(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          final progress = ((downloaded / contentLength) * 100).toInt();

          // iOS: Update every 5% to reduce notification spam
          final shouldUpdate = Platform.isIOS
              ? (progress % 5 == 0 && progress != lastNotificationProgress)
              : (progress != lastNotificationProgress);

          if (showNotification && shouldUpdate) {
            await _showProgressNotification(filename, progress, 100);
            lastNotificationProgress = progress;

            if (kDebugMode && progress % 25 == 0) {
              debugPrint('📊 Progress: $progress%');
            }
          }

          onProgress?.call(downloaded, contentLength);
        }
      }

      await sink!.close();
      sink = null;
      client!.close();
      client = null;
      _downloadTasks.remove(taskId);

      // File write complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify file exists before showing completion
      if (!await file.exists()) {
        throw Exception('File was not saved properly');
      }

      // Show completion notification
      if (showNotification) {
        await _showCompletedNotification(filename, savePath);

        if (kDebugMode) {
          print('✅ Download complete + notification shown');
        }
      }

      onComplete?.call(savePath);

      return DownloadResult(
        success: true,
        filePath: savePath,
        message: 'Download completed successfully',
      );
    } catch (e) {
      try { await sink?.close(); } catch (_) {}
      client?.close();
      _downloadTasks.remove(taskId);

      if (showNotification) {
        await _showErrorNotification(filename, e.toString());
      }

      onError?.call(e.toString());

      return DownloadResult(
        success: false,
        filePath: null,
        message: 'Download failed: $e',
      );
    }
  }

  // Future<String> _getSavePath(String filename, bool useDownloadsFolder) async {
  //   if (Platform.isAndroid && useDownloadsFolder) {
  //     final downloads = Directory('/storage/emulated/0/Download');
  //     if (await downloads.exists()) {
  //       return '${downloads.path}/$filename';
  //     }
  //   }
  //
  //   final docs = await getApplicationDocumentsDirectory();
  //   return '${docs.path}/$filename';
  // }


  Future<String> _getSavePath(String filename, bool useDownloadsFolder) async {
    if (Platform.isAndroid) {
      if (useDownloadsFolder) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 29) {
          // Android 10+ — scoped storage, use app-specific external storage
          final dir = await getExternalStorageDirectory();
          if (dir != null) {
            await dir.create(recursive: true);
            return '${dir.path}/$filename';
          }
        } else {
          // Android 9 and below — request legacy storage permission
          final status = await Permission.storage.request();
          if (status.isGranted) {
            final downloads = Directory('/storage/emulated/0/Download');
            if (await downloads.exists()) {
              return '${downloads.path}/$filename';
            }
          }
        }
      }

      // Safe fallback: app-specific external or internal
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      return '${dir.path}/$filename';
    }

    // iOS
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$filename';
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS (TAP-TO-OPEN REMOVED)
  // ---------------------------------------------------------------------------

  Future<void> _showProgressNotification(
      String filename,
      int progress,
      int maxProgress,
      ) async {
    try {
      NotificationDetails details;

      if (Platform.isAndroid) {
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            'download_channel',
            'Downloads',
            channelDescription: 'Download progress notifications',
            importance: Importance.low,
            priority: Priority.low,
            showProgress: true,
            maxProgress: maxProgress,
            progress: progress,
            ongoing: true,
            autoCancel: false,
            playSound: false,
            onlyAlertOnce: true,
          ),
        );
      } else if (Platform.isIOS) {
        details = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
            subtitle: 'Progress: $progress%',
            badgeNumber: progress,
            threadIdentifier: 'download_$_notificationCounter',
            interruptionLevel: InterruptionLevel.passive,
          ),
        );
      } else {
        return;
      }

      await _notificationsPlugin.show(
        id: _baseNotificationId,
        title: 'Downloading: $filename',
        body: 'Downloaded: $progress%',
        notificationDetails: details,
      );

      if (kDebugMode && Platform.isIOS && progress % 25 == 0) {
        debugPrint('🔔 iOS notification shown: $progress%');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Progress notification error: $e');
    }
  }

  Future<void> _showCompletedNotification(
      String filename,
      String filePath,
      ) async {
    try {
      await _notificationsPlugin.cancel(id: _baseNotificationId);
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      NotificationDetails details;
      _notificationCounter++;

      if (Platform.isAndroid) {
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            'download_channel',
            'Downloads',
            channelDescription: 'Download completion notifications',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
            playSound: true,
            showProgress: false,
            ongoing: false,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
        );
      } else if (Platform.isIOS) {   // subtitle: 'Progress: $progress%',
        details = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: 'File saved successfully',
            badgeNumber: 1,
            threadIdentifier: 'download_complete_$_notificationCounter',
            interruptionLevel: InterruptionLevel.timeSensitive,
            attachments: [],
          ),
        );
      } else {
        return;
      }

      final completionId = _baseNotificationId + 1000 + _notificationCounter;

      // NO payload - tap-to-open removed
      await _notificationsPlugin.show(
        id: completionId,
        title: '✅ $filename',
        body: 'Download Complete!',
        notificationDetails: details,
      );


      if (kDebugMode) {
        print('✅ Completion notification shown (ID: $completionId)');
        print('📁 File saved at: $filePath');
        if (Platform.isIOS) {
          print('📱 iOS notification with sound and time-sensitive priority');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Completed notification error: $e');
        print('Stack: $stackTrace');
      }
    }
  }

  Future<void> _showErrorNotification(String filename, String error) async {
    try {
      await _notificationsPlugin.cancel(id: _baseNotificationId);
      await Future.delayed(Platform.isIOS
          ? const Duration(milliseconds: 500)
          : const Duration(milliseconds: 100));

      NotificationDetails details;
      _notificationCounter++;

      if (Platform.isAndroid) {
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            'download_channel',
            'Downloads',
            channelDescription: 'Download notifications',
            importance: Importance.high,
            priority: Priority.high,
            showProgress: false,
            ongoing: false,
            autoCancel: true,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
        );
      } else if (Platform.isIOS) {
        details = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: error.length > 50 ? '${error.substring(0, 50)}...' : error,
            badgeNumber: 1,
            threadIdentifier: 'download_error_$_notificationCounter',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );
      } else {
        return;
      }

      final errorId = _baseNotificationId + 2000 + _notificationCounter;
      await _notificationsPlugin.show(
        id: errorId,
        title: '❌ Download Failed',
        body: filename,
        notificationDetails: details,
      );


      if (kDebugMode) {
        print('❌ Error notification shown (ID: $errorId)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error notification error: $e');
    }
  }

  Future<void> cancelAllDownloads() async {
    for (final token in _downloadTasks.values) {
      token.cancel();
    }
    _downloadTasks.clear();
    await _notificationsPlugin.cancelAll();
  }
}

// ---------------------------------------------------------------------------
// Type Definitions
// ---------------------------------------------------------------------------

typedef ProgressCallback = void Function(int downloaded, int total);
typedef SuccessCallback = void Function(String filePath);
typedef ErrorCallback = void Function(String error);

// ---------------------------------------------------------------------------
// Supporting Classes
// ---------------------------------------------------------------------------

class _CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String message;

  DownloadResult({
    required this.success,
    required this.filePath,
    required this.message,
  });

  @override
  String toString() => 'DownloadResult(success: $success, path: $filePath, message: $message)';
}