/// A single file to download as part of a batch (see `downloadMultiple`).
class DownloadItem {
  final String url;
  final String filename;

  const DownloadItem({required this.url, required this.filename});
}
