import 'download_status.dart';

/// Download task model
class DownloadTask {
  /// Unique task ID
  final String id;
  
  /// Download URL
  final String url;
  
  /// Target filename
  final String filename;
  
  /// Current download status
  DownloadStatus status;
  
  /// Downloaded bytes
  int downloadedBytes;
  
  /// Total bytes to download
  int totalBytes;
  
  /// File save path
  String? filePath;
  
  /// Error message if failed
  String? errorMessage;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    this.status = DownloadStatus.queued,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.filePath,
    this.errorMessage,
  });

  /// Get download progress percentage (0-100)
  int get progressPercentage {
    if (totalBytes == 0) return 0;
    return ((downloadedBytes / totalBytes) * 100).toInt();
  }

  /// Check if download is complete
  bool get isComplete => status == DownloadStatus.completed;

  /// Check if download failed
  bool get isFailed => status == DownloadStatus.failed;

  /// Check if download is in progress
  bool get isDownloading => status == DownloadStatus.downloading;

  /// Update progress
  void updateProgress(int downloaded, int total) {
    downloadedBytes = downloaded;
    totalBytes = total;
    if (status == DownloadStatus.queued) {
      status = DownloadStatus.downloading;
    }
  }

  /// Mark as completed
  void markCompleted(String path) {
    status = DownloadStatus.completed;
    filePath = path;
    downloadedBytes = totalBytes;
  }

  /// Mark as failed
  void markFailed(String error) {
    status = DownloadStatus.failed;
    errorMessage = error;
  }

  /// Mark as cancelled
  void markCancelled() {
    status = DownloadStatus.cancelled;
  }
}
