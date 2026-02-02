/// Download status enumeration
enum DownloadStatus {
  /// Download is queued
  queued,
  
  /// Download is in progress
  downloading,
  
  /// Download completed successfully
  completed,
  
  /// Download failed
  failed,
  
  /// Download was cancelled
  cancelled,
}
