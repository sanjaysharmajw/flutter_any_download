import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'src/download_item.dart';
import 'src/download_task.dart';

export 'src/download_status.dart';
export 'src/download_task.dart';
export 'src/download_item.dart';

/// Simple, easy-to-use download manager for Flutter (iOS & Android)
/// With iOS notification support (tap-to-open removed)
class FlutterAnyDownload {
  static final FlutterAnyDownload instance = FlutterAnyDownload._internal();
  factory FlutterAnyDownload() => instance;
  FlutterAnyDownload._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Map<String, _ActiveDownload> _activeDownloads = {};
  bool _isInitialized = false;
  bool _iosPermissionGranted = false;
  static const int _baseNotificationId = 1000;
  int _taskCounter = 0;

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
    final DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(iOS: iOSSettings);

    final bool? initialized =
        await _notificationsPlugin.initialize(settings: initSettings);

    if (kDebugMode) {
      print('✅ iOS Plugin initialized: $initialized');
      print('🔔 iOS Permission granted: $_iosPermissionGranted');
    }
  }

  Future<bool> _requestIOSPermissions() async {
    try {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin == null) {
        if (kDebugMode) print('❌ iOS plugin not available');
        return false;
      }

      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _iosPermissionGranted = granted ?? false;

      if (kDebugMode) {
        print(
            '🔔 iOS notification permission: ${_iosPermissionGranted ? "✅ GRANTED" : "❌ DENIED"}');
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

  /// Downloads currently in progress (or awaiting their first progress update).
  ///
  /// Useful for rendering a "multiple downloads" screen without tracking
  /// task state yourself.
  List<DownloadTask> get activeDownloads =>
      _activeDownloads.values.map((d) => d.task).toList(growable: false);

  /// Download a file with progress notifications.
  ///
  /// Pass [onTaskCreated] if you need to [cancel] this specific download
  /// later — it fires synchronously (before any bytes are downloaded) with
  /// the task id to use.
  Future<DownloadResult> download({
    required String url,
    required String filename,
    bool showNotification = true,
    bool saveToDownloads = true,
    ProgressCallback? onProgress,
    SuccessCallback? onComplete,
    ErrorCallback? onError,
    TaskCreatedCallback? onTaskCreated,
  }) async {
    if (!_isInitialized) await initialize();

    final slot = _taskCounter++;
    final taskId = '${DateTime.now().microsecondsSinceEpoch}_$slot';
    final notificationBase = _baseNotificationId + (slot * 10);
    final cancelToken = _CancelToken();

    http.Client? client;
    IOSink? sink;
    DownloadTask? task;
    int lastNotificationProgress = -1;

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

      final savePath = await _getSavePath(filename, saveToDownloads);

      if (kDebugMode) {
        print('💾 Downloading to: $savePath');
      }

      task = DownloadTask(
        id: taskId,
        url: url,
        filename: filename,
        savePath: savePath,
      );
      _activeDownloads[taskId] = _ActiveDownload(task, cancelToken);
      onTaskCreated?.call(taskId);

      if (cancelToken.isCancelled) {
        throw const _DownloadCancelledException();
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

      if (showNotification) {
        await _showProgressNotification(notificationBase, filename, 0, 100);
        lastNotificationProgress = 0;
      }

      await for (final chunk in response.stream) {
        if (cancelToken.isCancelled) {
          throw const _DownloadCancelledException();
        }

        sink.add(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          task.updateProgress(downloaded, contentLength);
          final progress = ((downloaded / contentLength) * 100).toInt();

          // iOS: Update every 5% to reduce notification spam
          final shouldUpdate = Platform.isIOS
              ? (progress % 5 == 0 && progress != lastNotificationProgress)
              : (progress != lastNotificationProgress);

          if (showNotification && shouldUpdate) {
            await _showProgressNotification(
                notificationBase, filename, progress, 100);
            lastNotificationProgress = progress;

            if (kDebugMode && progress % 25 == 0) {
              debugPrint('📊 Progress: $progress%');
            }
          }

          onProgress?.call(downloaded, contentLength);
        }
      }

      await sink.close();
      sink = null;
      client.close();
      client = null;

      // File write complete
      await Future.delayed(const Duration(milliseconds: 300));

      if (!await file.exists()) {
        throw Exception('File was not saved properly');
      }

      task.complete();

      if (showNotification) {
        await _showCompletedNotification(notificationBase, filename, savePath);

        if (kDebugMode) {
          print('✅ Download complete + notification shown');
        }
      }

      onComplete?.call(savePath);

      return DownloadResult(
        success: true,
        filePath: savePath,
        message: 'Download completed successfully',
        taskId: taskId,
      );
    } on _DownloadCancelledException {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close();
      task?.cancel();

      if (task != null) {
        final file = File(task.savePath);
        if (await file.exists()) await file.delete();
      }

      if (showNotification) {
        await _notificationsPlugin.cancel(id: notificationBase);
      }

      return DownloadResult(
        success: false,
        filePath: null,
        message: 'Download cancelled',
        cancelled: true,
        taskId: taskId,
      );
    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close();
      task?.fail(e.toString());

      if (showNotification) {
        await _showErrorNotification(notificationBase, filename, e.toString());
      }

      onError?.call(e.toString());

      return DownloadResult(
        success: false,
        filePath: null,
        message: 'Download failed: $e',
        taskId: taskId,
      );
    } finally {
      _activeDownloads.remove(taskId);
    }
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

  /// Download several files in one call instead of hand-writing a loop.
  ///
  /// Set [concurrent] to `true` to run all downloads in parallel (each gets
  /// its own progress notification); otherwise they run one after another.
  /// [onProgress], [onItemComplete] and [onItemError] are called with the
  /// index of the item in [items] so you can update per-item UI state.
  Future<List<DownloadResult>> downloadMultiple({
    required List<DownloadItem> items,
    bool showNotification = true,
    bool saveToDownloads = true,
    bool concurrent = false,
    BatchProgressCallback? onProgress,
    BatchSuccessCallback? onItemComplete,
    BatchErrorCallback? onItemError,
  }) async {
    Future<DownloadResult> downloadAt(int index) {
      final item = items[index];
      return download(
        url: item.url,
        filename: item.filename,
        showNotification: showNotification,
        saveToDownloads: saveToDownloads,
        onProgress: (downloaded, total) =>
            onProgress?.call(index, downloaded, total),
        onComplete: (filePath) => onItemComplete?.call(index, filePath),
        onError: (error) => onItemError?.call(index, error),
      );
    }

    if (concurrent) {
      return Future.wait(List.generate(items.length, downloadAt));
    }

    final results = <DownloadResult>[];
    for (var i = 0; i < items.length; i++) {
      results.add(await downloadAt(i));
    }
    return results;
  }

  /// Request notification permission (required for iOS; Android 13+).
  Future<bool> requestPermission() async {
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

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      return _iosPermissionGranted;
    }
    return true;
  }

  /// Cancel a single in-flight download by the id passed to [onTaskCreated].
  /// Returns `false` if no matching active download was found (e.g. it
  /// already finished).
  bool cancel(String taskId) {
    final active = _activeDownloads[taskId];
    if (active == null) return false;
    active.cancelToken.cancel();
    return true;
  }

  /// Cancel all active downloads
  Future<void> cancelAll() async {
    for (final active in _activeDownloads.values) {
      active.cancelToken.cancel();
    }
    await _notificationsPlugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // INTERNAL IMPLEMENTATION
  // ---------------------------------------------------------------------------

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
  //
  // Each download gets its own notification id range (base, base+1, base+2)
  // so that concurrent downloads (see downloadMultiple) show independent
  // progress bars instead of overwriting one another.

  Future<void> _showProgressNotification(
    int notificationId,
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
            threadIdentifier: 'download_$notificationId',
            interruptionLevel: InterruptionLevel.passive,
          ),
        );
      } else {
        return;
      }

      await _notificationsPlugin.show(
        id: notificationId,
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
    int notificationBase,
    String filename,
    String filePath,
  ) async {
    try {
      await _notificationsPlugin.cancel(id: notificationBase);
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      NotificationDetails details;

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
        details = NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: 'File saved successfully',
            badgeNumber: 1,
            threadIdentifier: 'download_complete_$notificationBase',
            interruptionLevel: InterruptionLevel.timeSensitive,
            attachments: [],
          ),
        );
      } else {
        return;
      }

      final completionId = notificationBase + 1;

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

  Future<void> _showErrorNotification(
    int notificationBase,
    String filename,
    String error,
  ) async {
    try {
      await _notificationsPlugin.cancel(id: notificationBase);
      await Future.delayed(Platform.isIOS
          ? const Duration(milliseconds: 500)
          : const Duration(milliseconds: 100));

      NotificationDetails details;

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
            threadIdentifier: 'download_error_$notificationBase',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );
      } else {
        return;
      }

      final errorId = notificationBase + 2;
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
}

// ---------------------------------------------------------------------------
// Type Definitions
// ---------------------------------------------------------------------------

typedef ProgressCallback = void Function(int downloaded, int total);
typedef SuccessCallback = void Function(String filePath);
typedef ErrorCallback = void Function(String error);
typedef TaskCreatedCallback = void Function(String taskId);

typedef BatchProgressCallback = void Function(
    int index, int downloaded, int total);
typedef BatchSuccessCallback = void Function(int index, String filePath);
typedef BatchErrorCallback = void Function(int index, String error);

// ---------------------------------------------------------------------------
// Supporting Classes
// ---------------------------------------------------------------------------

class _CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}

class _ActiveDownload {
  final DownloadTask task;
  final _CancelToken cancelToken;
  _ActiveDownload(this.task, this.cancelToken);
}

class _DownloadCancelledException implements Exception {
  const _DownloadCancelledException();
  @override
  String toString() => 'Download cancelled';
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String message;

  /// `true` if this result comes from a user-initiated [FlutterAnyDownload.cancel]
  /// rather than an actual failure.
  final bool cancelled;

  /// The id of the underlying download task (also delivered synchronously
  /// via `onTaskCreated`, if you passed one).
  final String? taskId;

  DownloadResult({
    required this.success,
    required this.filePath,
    required this.message,
    this.cancelled = false,
    this.taskId,
  });

  @override
  String toString() =>
      'DownloadResult(success: $success, path: $filePath, cancelled: $cancelled, message: $message)';
}
