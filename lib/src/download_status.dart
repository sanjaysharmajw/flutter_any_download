// Download status enums and constants

enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
  cancelled,
}

extension DownloadStatusExtension on DownloadStatus {
  String get displayName {
    switch (this) {
      case DownloadStatus.idle:
        return 'Ready';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == DownloadStatus.downloading;
  bool get isFinished => this == DownloadStatus.completed ||
      this == DownloadStatus.failed ||
      this == DownloadStatus.cancelled;
}