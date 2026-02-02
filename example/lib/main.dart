import 'package:flutter/material.dart';
import 'package:flutter_any_download/flutter_any_download.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Any Download Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DownloadDemoPage(),
    );
  }
}

class DownloadDemoPage extends StatefulWidget {
  const DownloadDemoPage({super.key});

  @override
  State<DownloadDemoPage> createState() => _DownloadDemoPageState();
}

class _DownloadDemoPageState extends State<DownloadDemoPage> {
  final FlutterAnyDownload _downloader = FlutterAnyDownload();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _filenameController = TextEditingController();

  bool _isDownloading = false;
  double _progress = 0.0;
  String _status = 'Ready';
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _initializeDownloader();

    // Sample URL - PDF file
    _urlController.text = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    _filenameController.text = 'sample_file.pdf';
  }

  Future<void> _initializeDownloader() async {
    await _downloader.initialize();
    await _downloader.requestNotificationPermission();
  }

  Future<void> _startDownload() async {
    if (_urlController.text.isEmpty || _filenameController.text.isEmpty) {
      _showSnackBar('Please enter URL and filename');
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _status = 'Starting download...';
      _downloadedFilePath = null;
    });

    final result = await _downloader.downloadFile(
      url: _urlController.text,
      filename: _filenameController.text,
      saveToDownloadsFolder: true,
      showNotification: true,
      onProgress: (downloaded, total) {
        setState(() {
          _progress = downloaded / total;
          _status = 'Downloading: ${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB / ${(total / 1024 / 1024).toStringAsFixed(2)} MB';
        });
      },
      onComplete: (filePath) {
        setState(() {
          _isDownloading = false;
          _status = 'Download completed!';
          _downloadedFilePath = filePath;
        });
        _showSnackBar('Download completed: $filePath');
      },
      onError: (error) {
        setState(() {
          _isDownloading = false;
          _status = 'Download failed: $error';
        });
        _showSnackBar('Download failed: $error');
      },
    );

    if (!result.success) {
      setState(() {
        _isDownloading = false;
        _status = result.message;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Any Download Demo'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Download Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Download URL',
                        hintText: 'https://example.com/file.pdf',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _filenameController,
                      decoration: const InputDecoration(
                        labelText: 'Filename',
                        hintText: 'my_file.pdf',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.insert_drive_file),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isDownloading) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: _downloadedFilePath != null ? Colors.green[50] : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _downloadedFilePath != null
                            ? Icons.check_circle
                            : Icons.download,
                        size: 48,
                        color: _downloadedFilePath != null
                            ? Colors.green
                            : Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_downloadedFilePath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _downloadedFilePath!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startDownload,
              icon: const Icon(Icons.download),
              label: const Text('Start Download'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isDownloading
                  ? () {
                _downloader.cancelAllDownloads();
                setState(() {
                  _isDownloading = false;
                  _status = 'Download cancelled';
                });
              }
                  : null,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Download'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('✓ HTTP stream-based download'),
                    const Text('✓ Real-time progress notification'),
                    const Text('✓ Same notification ID updates'),
                    const Text('✓ Download completion notification'),
                    const Text('✓ Saves to Android Downloads folder'),
                    const Text('✓ Android 13+ notification permission'),
                    const Text('✓ Tap notification to open file'),
                    const Text('✓ Cancel download support'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _filenameController.dispose();
    super.dispose();
  }
}
