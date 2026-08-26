import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_any_download/flutter_any_download.dart';

void main() {
  group('DownloadTask', () {
    test('reports zero progress before any bytes arrive', () {
      final task = DownloadTask(
        id: '1',
        url: 'https://example.com/file.pdf',
        filename: 'file.pdf',
        savePath: '/tmp/file.pdf',
      );

      expect(task.progressPercent, 0);
      expect(task.progressFraction, 0.0);
      expect(task.status, DownloadStatus.idle);
    });

    test('updateProgress computes percent, fraction and MB, and marks downloading', () {
      final task = DownloadTask(
        id: '1',
        url: 'https://example.com/file.pdf',
        filename: 'file.pdf',
        savePath: '/tmp/file.pdf',
      );

      task.updateProgress(50 * 1024 * 1024, 100 * 1024 * 1024);

      expect(task.progressPercent, 50);
      expect(task.progressFraction, 0.5);
      expect(task.downloadedMB, closeTo(50, 0.01));
      expect(task.totalMB, closeTo(100, 0.01));
      expect(task.isDownloading, isTrue);
    });

    test('complete/fail/cancel transition status and expose flags', () {
      final task = DownloadTask(
        id: '1',
        url: 'https://example.com/file.pdf',
        filename: 'file.pdf',
        savePath: '/tmp/file.pdf',
      );

      task.complete();
      expect(task.isCompleted, isTrue);
      expect(task.status.isFinished, isTrue);

      task.fail('network error');
      expect(task.isFailed, isTrue);
      expect(task.error, 'network error');

      task.cancel();
      expect(task.isCancelled, isTrue);
    });
  });

  group('FlutterAnyDownload', () {
    test('activeDownloads is empty when nothing is in flight', () {
      expect(FlutterAnyDownload.instance.activeDownloads, isEmpty);
    });

    test('cancel returns false for an unknown task id', () {
      expect(FlutterAnyDownload.instance.cancel('does-not-exist'), isFalse);
    });
  });

  group('DownloadResult', () {
    test('defaults cancelled to false and taskId to null', () {
      final result = DownloadResult(
        success: true,
        filePath: '/tmp/file.pdf',
        message: 'Download completed successfully',
      );

      expect(result.cancelled, isFalse);
      expect(result.taskId, isNull);
    });
  });
}
