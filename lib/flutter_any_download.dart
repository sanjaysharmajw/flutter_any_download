library flutter_any_download;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

export 'src/download_status.dart';
export 'src/download_task.dart';

/// Simple, easy-to-use download manager for Flutter (iOS & Android)
/// With FIXED iOS notification support
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
  int _lastNotificationProgress = -1;
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

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _initializeIOS() async {
    // iOS ke liye PEHLE permission request karo
    await _requestIOSPermissions();

    // Phir plugin initialize karo with onDidReceiveLocalNotification
    final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        if (kDebugMode) {
          print('📱 iOS Legacy notification received: $title');
        }
      },
    );

    final initSettings = InitializationSettings(iOS: iOSSettings);

    final bool? initialized = await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

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

  Future<void> _onNotificationTap(NotificationResponse response) async {
    final path = response.payload;
    if (path == null || path.isEmpty) return;

    if (kDebugMode) {
      print('🔔 Notification tapped: $path');
    }

    try {
      if (Platform.isAndroid) {
        await OpenFilex.open(path);
      } else if (Platform.isIOS) {
        final uri = Uri.file(path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error opening file: $e');
    }
  }

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
    _lastNotificationProgress = -1;

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

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final file = File(savePath);
      final sink = file.openWrite();
      int downloaded = 0;

      // Show initial notification
      if (showNotification) {
        await _showProgressNotification(filename, 0, 100);
        _lastNotificationProgress = 0;
      }

      await for (final chunk in response.stream) {
        if (cancelToken.isCancelled) {
          await sink.close();
          client.close();
          if (await file.exists()) await file.delete();
          throw Exception('Download cancelled');
        }

        sink.add(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          final progress = ((downloaded / contentLength) * 100).toInt();

          // iOS: Update every 5% to reduce notification spam
          final shouldUpdate = Platform.isIOS
              ? (progress % 5 == 0 && progress != _lastNotificationProgress)
              : (progress != _lastNotificationProgress);

          if (showNotification && shouldUpdate) {
            await _showProgressNotification(filename, progress, 100);
            _lastNotificationProgress = progress;

            if (kDebugMode && progress % 25 == 0) {
              print('📊 Progress: $progress%');
            }
          }

          onProgress?.call(downloaded, contentLength);
        }
      }

      await sink.close();
      client.close();
      _downloadTasks.remove(taskId);

      // File write complete
      await Future.delayed(const Duration(milliseconds: 300));

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

  Future<String> _getSavePath(String filename, bool useDownloadsFolder) async {
    if (Platform.isAndroid && useDownloadsFolder) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        return '${downloads.path}/$filename';
      }
    }

    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$filename';
  }

  // ---------------------------------------------------------------------------
  // iOS FIXED NOTIFICATIONS
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
        // iOS ke liye proper progress notification
        details = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
            subtitle: 'Progress: $progress%',
            badgeNumber: progress,
            threadIdentifier: 'download_$_notificationCounter',
            // iOS 15+ interruption level
            interruptionLevel: InterruptionLevel.passive,
          ),
        );
      } else {
        return;
      }

      await _notificationsPlugin.show(
        _baseNotificationId,
        'Downloading: $filename',
        'Downloaded: $progress%',
        details,
      );

      if (kDebugMode && Platform.isIOS && progress % 25 == 0) {
        print('🔔 iOS notification shown: $progress%');
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
      // Cancel progress notification
      await _notificationsPlugin.cancel(_baseNotificationId);

      // iOS ke liye delay zaruri hai
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
      } else if (Platform.isIOS) {
        // iOS ke liye HIGH PRIORITY completion notification
        details = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,    // MUST be true
            presentBadge: true,    // MUST be true
            presentSound: true,    // Sound bajao
            subtitle: 'Tap to open file',
            badgeNumber: 1,
            threadIdentifier: 'download_complete_$_notificationCounter',
            // iOS 15+ ke liye TIME SENSITIVE
            interruptionLevel: InterruptionLevel.timeSensitive,
            // iOS attachment for better visibility (optional)
            attachments: [],
          ),
        );
      } else {
        return;
      }

      // Different ID for completion notification
      final completionId = _baseNotificationId + 1000 + _notificationCounter;

      await _notificationsPlugin.show(
        completionId,
        '✅ $filename',
        'Download Complete! Tap to open',
        details,
        payload: filePath,
      );

      if (kDebugMode) {
        print('✅ Completion notification shown (ID: $completionId)');
        if (Platform.isIOS) {
          print('📱 iOS notification with sound and time-sensitive priority');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Completed notification error: $e');
        print('Stack: ${StackTrace.current}');
      }
    }
  }

  Future<void> _showErrorNotification(String filename, String error) async {
    try {
      await _notificationsPlugin.cancel(_baseNotificationId);
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
        errorId,
        '❌ Download Failed',
        filename,
        details,
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