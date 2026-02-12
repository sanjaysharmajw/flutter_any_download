// =============================================================================
// FLUTTER ANY DOWNLOAD - USAGE EXAMPLES
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_any_download/flutter_any_download.dart';

// =============================================================================
// EXAMPLE 1: BASIC SETUP (main.dart)
// =============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the download manager once at app startup
  await FlutterAnyDownload.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download Manager Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DownloadExamplesScreen(),
    );
  }
}

// =============================================================================
// EXAMPLE 2: SIMPLE DOWNLOAD BUTTON
// =============================================================================

class SimpleDownloadExample extends StatefulWidget {
  const SimpleDownloadExample({Key? key}) : super(key: key);

  @override
  State<SimpleDownloadExample> createState() => _SimpleDownloadExampleState();
}

class _SimpleDownloadExampleState extends State<SimpleDownloadExample> {
  String _status = 'Ready to download';
  bool _isDownloading = false;

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _status = 'Downloading...';
    });

    // Simple one-liner download
    final result = await FlutterAnyDownload.instance.download(
      url: 'https://www.princexml.com/samples/icelandic/dictionary.pdf',
      filename: 'sample.pdf',
    );

    setState(() {
      _isDownloading = false;
      if (result.success) {
        _status = 'Downloaded to: ${result.filePath}';
      } else {
        _status = 'Error: ${result.message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isDownloading ? null : _downloadFile,
          child: const Text('Download PDF'),
        ),
        const SizedBox(height: 20),
        Text(_status),
      ],
    );
  }
}

// =============================================================================
// EXAMPLE 3: DOWNLOAD WITH PROGRESS BAR
// =============================================================================

class ProgressDownloadExample extends StatefulWidget {
  const ProgressDownloadExample({Key? key}) : super(key: key);

  @override
  State<ProgressDownloadExample> createState() => _ProgressDownloadExampleState();
}

class _ProgressDownloadExampleState extends State<ProgressDownloadExample> {
  double _progress = 0.0;
  String _status = 'Ready';
  bool _isDownloading = false;

  Future<void> _downloadWithProgress() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _status = 'Starting download...';
    });

    final result = await FlutterAnyDownload.instance.download(
      url: 'https://getsamplefiles.com/download/zip/sample-5.zip',
      filename: 'large_file.zip',
      onProgress: (downloaded, total) {
        setState(() {
          _progress = downloaded / total;
          _status = 'Downloaded ${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB / ${(total / 1024 / 1024).toStringAsFixed(2)} MB';
        });
      },
      onComplete: (path) {
        print('Download completed: $path');
      },
      onError: (error) {
        print('Download error: $error');
      },
    );

    setState(() {
      _isDownloading = false;
      if (result.success) {
        _status = 'Download complete! ✅';
      } else {
        _status = 'Download failed ❌';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 20),
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(_status),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : _downloadWithProgress,
            icon: const Icon(Icons.download),
            label: const Text('Download Large File'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 4: SILENT DOWNLOAD (No Notifications)
// =============================================================================

class SilentDownloadExample extends StatelessWidget {
  const SilentDownloadExample({Key? key}) : super(key: key);

  Future<void> _downloadSilently(BuildContext context) async {
    // Download without showing notifications (useful for app data/configs)
    final result = await FlutterAnyDownload.instance.downloadSilent(
      url: 'https://jsonplaceholder.typicode.com/posts',
      filename: 'data.json',
      saveToDownloads: false, // Save to app directory
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Downloaded silently!' : 'Failed: ${result.message}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _downloadSilently(context),
        child: const Text('Silent Download (No Notifications)'),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 5: MULTIPLE DOWNLOADS
// =============================================================================

class MultipleDownloadsExample extends StatefulWidget {
  const MultipleDownloadsExample({Key? key}) : super(key: key);

  @override
  State<MultipleDownloadsExample> createState() => _MultipleDownloadsExampleState();
}

class _MultipleDownloadsExampleState extends State<MultipleDownloadsExample> {
  final List<DownloadItem> _downloads = [];

  Future<void> _downloadMultipleFiles() async {
    final files = [
      {'url': 'https://www.princexml.com/samples/invoice-colorful/invoicesample.pdf', 'name': 'file1.pdf'},
      {'url': 'https://www.princexml.com/samples/invoice-plain/index.pdf', 'name': 'file2.pdf'},
      {'url': 'https://www.princexml.com/samples/textbook/somatosensory.pdf', 'name': 'file3.pdf'},
    ];

    for (var file in files) {
      final item = DownloadItem(filename: file['name']!, status: 'Downloading...');
      setState(() => _downloads.add(item));

      final result = await FlutterAnyDownload.instance.download(
        url: file['url']!,
        filename: file['name']!,
        onProgress: (downloaded, total) {
          final progress = (downloaded / total * 100).toInt();
          setState(() {
            item.status = 'Progress: $progress%';
          });
        },
      );

      setState(() {
        item.status = result.success ? '✅ Complete' : '❌ Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _downloads.isEmpty ? _downloadMultipleFiles : null,
          child: const Text('Download 3 Files'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _downloads.length,
            itemBuilder: (context, index) {
              final item = _downloads[index];
              return ListTile(
                leading: const Icon(Icons.file_download),
                title: Text(item.filename),
                subtitle: Text(item.status),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DownloadItem {
  final String filename;
  String status;

  DownloadItem({required this.filename, required this.status});
}

// =============================================================================
// EXAMPLE 6: PERMISSION HANDLING
// =============================================================================

class PermissionExample extends StatefulWidget {
  const PermissionExample({Key? key}) : super(key: key);

  @override
  State<PermissionExample> createState() => _PermissionExampleState();
}

class _PermissionExampleState extends State<PermissionExample> {
  bool? _permissionGranted;

  Future<void> _checkPermission() async {
    final granted = await FlutterAnyDownload.instance.areNotificationsEnabled();
    setState(() => _permissionGranted = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await FlutterAnyDownload.instance.requestPermission();
    setState(() => _permissionGranted = granted);

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Downloads will work but without notifications.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Notification Permission: ${_permissionGranted == null ? "Checking..." : _permissionGranted! ? "✅ Granted" : "❌ Denied"}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _requestPermission,
          child: const Text('Request Permission'),
        ),
      ],
    );
  }
}

// =============================================================================
// EXAMPLE 7: CANCEL DOWNLOADS
// =============================================================================

class CancelDownloadExample extends StatefulWidget {
  const CancelDownloadExample({Key? key}) : super(key: key);

  @override
  State<CancelDownloadExample> createState() => _CancelDownloadExampleState();
}

class _CancelDownloadExampleState extends State<CancelDownloadExample> {
  bool _isDownloading = false;

  Future<void> _startLongDownload() async {
    setState(() => _isDownloading = true);

    final result = await FlutterAnyDownload.instance.download(
      url: 'https://getsamplefiles.com/download/zip/sample-4.zip',
      filename: 'very_large_file.zip',
    );

    setState(() => _isDownloading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _cancelDownload() async {
    await FlutterAnyDownload.instance.cancelAll();
    setState(() => _isDownloading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isDownloading ? null : _startLongDownload,
          child: const Text('Start Large Download'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isDownloading ? _cancelDownload : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel All Downloads'),
        ),
      ],
    );
  }
}

// =============================================================================
// EXAMPLE 8: DOWNLOAD DIFFERENT FILE TYPES
// =============================================================================

class FileTypesExample extends StatelessWidget {
  const FileTypesExample({Key? key}) : super(key: key);

  Future<void> _downloadFile(String url, String filename) async {
    final result = await FlutterAnyDownload.instance.download(
      url: url,
      filename: filename,
    );
    print('Download result: ${result.message}');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDownloadButton(
          'Download PDF',
          Icons.picture_as_pdf,
              () => _downloadFile(
            'https://www.princexml.com/samples/newsletter/drylab.pdf',
            'drylab.pdf',
          ),
        ),
        _buildDownloadButton(
          'Download Image',
          Icons.image,
              () => _downloadFile(
            'https://www.pexels.com/photo/contrasting-architectural-styles-in-urban-setting-35581905/',
            'urban.jpg',
          ),
        ),
        _buildDownloadButton(
          'Download Video',
          Icons.video_file,
              () => _downloadFile(
            'https://www.pexels.com/video/dramatic-cliffs-overlooking-ocean-at-sunset-30605373/',
            'dramatic.mp4',
          ),
        ),
        _buildDownloadButton(
          'Download ZIP',
          Icons.folder_zip,
              () => _downloadFile(
            'https://getsamplefiles.com/download/zip/sample-3.zip',
            'archive.zip',
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}

// =============================================================================
// MAIN SCREEN WITH ALL EXAMPLES
// =============================================================================

class DownloadExamplesScreen extends StatefulWidget {
  const DownloadExamplesScreen({Key? key}) : super(key: key);

  @override
  State<DownloadExamplesScreen> createState() => _DownloadExamplesScreenState();
}

class _DownloadExamplesScreenState extends State<DownloadExamplesScreen> {
  int _currentIndex = 0;

  final List<Widget> _examples = const [
    SimpleDownloadExample(),
    ProgressDownloadExample(),
    SilentDownloadExample(),
    MultipleDownloadsExample(),
    PermissionExample(),
    CancelDownloadExample(),
    FileTypesExample(),
  ];

  final List<String> _titles = const [
    'Simple Download',
    'Progress Bar',
    'Silent Download',
    'Multiple Downloads',
    'Permissions',
    'Cancel Downloads',
    'File Types',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _examples[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Simple'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_off), label: 'Silent'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Multiple'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Permission'),
          BottomNavigationBarItem(icon: Icon(Icons.cancel), label: 'Cancel'),
          BottomNavigationBarItem(icon: Icon(Icons.file_present), label: 'Types'),
        ],
      ),
    );
  }
}