library flutter_any_download;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

export 'src/download_status.dart';
export 'src/download_task.dart';

/// Main download manager class
class FlutterAnyDownload {
  static final FlutterAnyDownload _instance = FlutterAnyDownload._internal();
  factory FlutterAnyDownload() => _instance;
  FlutterAnyDownload._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final Map<String, CancelToken> _downloadTasks = {};
  bool _isInitialized = false;
  static const int _notificationId = 1001;

  // To prevent too frequent notification updates
  int _lastNotificationProgress = -1;

  /// Initialize the download manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      await OpenFilex.open(response.payload!);
    }
  }

  /// Request notification permission for Android 13+
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Download file with progress tracking
  Future<DownloadResult> downloadFile({
    required String url,
    required String filename,
    bool saveToDownloadsFolder = true,
    bool showNotification = true,
    Function(int, int)? onProgress,
    Function(String)? onComplete,
    Function(String)? onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = CancelToken();
    _downloadTasks[taskId] = cancelToken;

    // Reset progress tracking
    _lastNotificationProgress = -1;

    try {
      // Request notification permission
      if (showNotification) {
        await requestNotificationPermission();
      }

      // Get save path
      final savePath = await _getSavePath(filename, saveToDownloadsFolder);

      // Start download
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
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

      await for (var chunk in response.stream) {
        if (cancelToken.isCancelled) {
          await sink.close();
          client.close();
          await file.delete();
          throw Exception('Download cancelled');
        }

        sink.add(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          final progress = ((downloaded / contentLength) * 100).toInt();

          // Update notification only if progress changed by at least 1%
          // This prevents too many notification updates
          if (showNotification && progress != _lastNotificationProgress) {
            await _showProgressNotification(filename, progress, 100);
            _lastNotificationProgress = progress;
          }

          // Callback
          onProgress?.call(downloaded, contentLength);
        }
      }

      await sink.close();
      client.close();
      _downloadTasks.remove(taskId);

      // Small delay to ensure stream is fully closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Show completion notification - this will replace the progress notification
      if (showNotification) {
        await _showCompletedNotification(filename, savePath);
      }

      onComplete?.call(savePath);

      return DownloadResult(
        success: true,
        filePath: savePath,
        message: 'Download completed successfully',
      );
    } catch (e) {
      _downloadTasks.remove(taskId);

      // Small delay before showing error notification
      await Future.delayed(const Duration(milliseconds: 100));

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

  /// Get save path based on user preference
  Future<String> _getSavePath(String filename, bool useDownloadsFolder) async {
    if (useDownloadsFolder && Platform.isAndroid) {
      // Try to use Downloads folder (Android 10+)
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return '${directory.path}/$filename';
      }
    }

    // Fallback to app directory
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  /// Show progress notification
  Future<void> _showProgressNotification(
      String filename,
      int progress,
      int maxProgress,
      ) async {
    final androidDetails = AndroidNotificationDetails(
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
      onlyAlertOnce: true, // Prevents sound/vibration on updates
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      'Downloading $filename',
      '$progress%',
      notificationDetails,
    );
  }

  /// Show completed notification
  Future<void> _showCompletedNotification(
      String filename,
      String filePath,
      ) async {
    // Cancel any existing notification first
    await _notificationsPlugin.cancel(_notificationId);

    // Small delay to ensure previous notification is cleared
    await Future.delayed(const Duration(milliseconds: 50));

    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Download completion notifications',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
      showProgress: false, // Hide progress bar - CRITICAL
      ongoing: false, // Not ongoing anymore - CRITICAL
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      'Download Completed',
      filename,
      notificationDetails,
      payload: filePath,
    );
  }

  /// Show error notification
  Future<void> _showErrorNotification(String filename, String error) async {
    // Cancel any existing notification first
    await _notificationsPlugin.cancel(_notificationId);

    // Small delay to ensure previous notification is cleared
    await Future.delayed(const Duration(milliseconds: 50));

    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Download notifications',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false, // Hide progress bar - CRITICAL
      ongoing: false, // Not ongoing anymore - CRITICAL
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      'Download Failed',
      filename,
      notificationDetails,
    );
  }

  /// Cancel all downloads
  Future<void> cancelAllDownloads() async {
    for (var token in _downloadTasks.values) {
      token.cancel();
    }
    _downloadTasks.clear();

    // Cancel notification
    await _notificationsPlugin.cancel(_notificationId);
  }
}

/// Cancel token for download tasks
class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// Download result class
class DownloadResult {
  final bool success;
  final String? filePath;
  final String message;

  DownloadResult({
    required this.success,
    required this.filePath,
    required this.message,
  });
}
