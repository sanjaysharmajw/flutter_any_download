// Download task model for tracking downloads

import 'download_status.dart';

class DownloadTask {
  final String id;
  final String url;
  final String filename;
  final String savePath;
  DownloadStatus status;
  int downloadedBytes;
  int totalBytes;
  String? error;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.savePath,
    this.status = DownloadStatus.idle,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  /// Get download progress as percentage (0-100)
  int get progressPercent {
    if (totalBytes == 0) return 0;
    return ((downloadedBytes / totalBytes) * 100).toInt();
  }

  /// Get download progress as fraction (0.0-1.0)
  double get progressFraction {
    if (totalBytes == 0) return 0.0;
    return downloadedBytes / totalBytes;
  }

  /// Get downloaded size in MB
  double get downloadedMB => downloadedBytes / 1024 / 1024;

  /// Get total size in MB
  double get totalMB => totalBytes / 1024 / 1024;

  /// Get formatted download progress string
  String get progressString {
    return '${downloadedMB.toStringAsFixed(2)} MB / ${totalMB.toStringAsFixed(2)} MB';
  }

  /// Check if download is in progress
  bool get isDownloading => status == DownloadStatus.downloading;

  /// Check if download is completed
  bool get isCompleted => status == DownloadStatus.completed;

  /// Check if download failed
  bool get isFailed => status == DownloadStatus.failed;

  /// Check if download was cancelled
  bool get isCancelled => status == DownloadStatus.cancelled;

  /// Update progress
  void updateProgress(int downloaded, int total) {
    downloadedBytes = downloaded;
    totalBytes = total;
    status = DownloadStatus.downloading;
  }

  /// Mark as completed
  void complete() {
    status = DownloadStatus.completed;
  }

  /// Mark as failed
  void fail(String errorMessage) {
    status = DownloadStatus.failed;
    error = errorMessage;
  }

  /// Mark as cancelled
  void cancel() {
    status = DownloadStatus.cancelled;
  }

  @override
  String toString() {
    return 'DownloadTask(id: $id, filename: $filename, status: ${status.displayName}, progress: $progressPercent%)';
  }
}