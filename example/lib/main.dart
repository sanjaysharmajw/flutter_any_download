import 'package:flutter/material.dart';
import 'package:flutter_any_download/flutter_any_download.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the download manager
  await FlutterAnyDownload.instance.initialize();
  // Request permission for iOS
  await FlutterAnyDownload.instance.requestPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
      home: const DownloadHomePage(),
    );
  }
}

class DownloadHomePage extends StatelessWidget {
  const DownloadHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFFA855F7).withValues(alpha:0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha:0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Download Manager',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fast, reliable file downloads',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _FeatureCard(
                      title: 'Simple',
                      subtitle: 'Quick download',
                      icon: Icons.download_rounded,
                      gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SimpleDownloadPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Progress',
                      subtitle: 'Track download',
                      icon: Icons.trending_up,
                      gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressDownloadPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Silent',
                      subtitle: 'No notifications',
                      icon: Icons.notifications_off_rounded,
                      gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SilentDownloadPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Multiple',
                      subtitle: 'Batch download',
                      icon: Icons.file_copy_rounded,
                      gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MultipleDownloadsPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Permission',
                      subtitle: 'Manage access',
                      icon: Icons.security_rounded,
                      gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PermissionPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      title: 'File Types',
                      subtitle: 'All formats',
                      icon: Icons.folder_rounded,
                      gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FileTypesPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleDownloadPage extends StatefulWidget {
  const SimpleDownloadPage({super.key});
  @override
  State<SimpleDownloadPage> createState() => _SimpleDownloadPageState();
}

class _SimpleDownloadPageState extends State<SimpleDownloadPage> {
  String _status = 'Ready to download';
  bool _isDownloading = false;
  bool _isSuccess = false;

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _status = 'Downloading...';
      _isSuccess = false;
    });

    final result = await FlutterAnyDownload.instance.download(
      url: 'https://www.princexml.com/samples/icelandic/dictionary.pdf',
      filename: 'sample_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    setState(() {
      _isDownloading = false;
      _isSuccess = result.success;
      if (result.success) {
        _status = 'Download complete! ✅';
      } else {
        _status = 'Error: ${result.message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Download'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6366F1).withValues(alpha:0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _isDownloading ? 1 : 0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _isSuccess
                                  ? Colors.green.withValues(alpha:0.1)
                                  : const Color(0xFF6366F1).withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.download_rounded,
                              size: 64,
                              color: _isSuccess ? Colors.green : const Color(0xFF6366F1),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadFile,
                        icon: _isDownloading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.download_rounded),
                        label: Text(_isDownloading ? 'Downloading...' : 'Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressDownloadPage extends StatefulWidget {
  const ProgressDownloadPage({super.key});
  @override
  State<ProgressDownloadPage> createState() => _ProgressDownloadPageState();
}

class _ProgressDownloadPageState extends State<ProgressDownloadPage>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _status = 'Ready';
  bool _isDownloading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadWithProgress() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _status = 'Starting download...';
    });

    _controller.repeat();

    final result = await FlutterAnyDownload.instance.download(
      url: 'https://getsamplefiles.com/download/zip/sample-5.zip',
      filename: 'large_file_${DateTime.now().millisecondsSinceEpoch}.zip',
      onProgress: (downloaded, total) {
        setState(() {
          _progress = downloaded / total;
          _status =
          '${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB / ${(total / 1024 / 1024).toStringAsFixed(2)} MB';
        });
      },
    );

    _controller.stop();

    setState(() {
      _isDownloading = false;
      if (result.success) {
        _progress = 1.0;
        _status = 'Download complete! ✅';
      } else {
        _status = 'Download failed ❌';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Download'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEC4899).withValues(alpha:0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFEC4899),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                            if (_isDownloading)
                              RotationTransition(
                                turns: _controller,
                                child: const Icon(
                                  Icons.downloading_rounded,
                                  color: Color(0xFFEC4899),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Linear Progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEC4899),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadWithProgress,
                        icon: const Icon(Icons.file_download_rounded),
                        label: const Text('Download Large File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SilentDownloadPage extends StatelessWidget {
  const SilentDownloadPage({super.key});
  Future<void> _downloadSilently(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            SizedBox(width: 16),
            Text('Downloading silently...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    final result = await FlutterAnyDownload.instance.downloadSilent(
      url: 'https://jsonplaceholder.typicode.com/posts',
      filename: 'data_${DateTime.now().millisecondsSinceEpoch}.json',
      saveToDownloads: false,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                result.success ? 'Downloaded silently!' : 'Failed: ${result.message}',
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? const Color(0xFF10B981) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Silent Download'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF10B981).withValues(alpha:0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_rounded,
                        size: 64,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Silent Download',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Downloads files in the background without showing notifications. Perfect for app data and configurations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadSilently(context),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download Silently'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MultipleDownloadsPage extends StatefulWidget {
  const MultipleDownloadsPage({super.key});
  @override
  State<MultipleDownloadsPage> createState() => _MultipleDownloadsPageState();
}

class _MultipleDownloadsPageState extends State<MultipleDownloadsPage> {
  final List<DownloadItem> _downloads = [];
  bool _isDownloading = false;

  Future<void> _downloadMultipleFiles() async {
    setState(() {
      _isDownloading = true;
      _downloads.clear();
    });

    final files = [
      {
        'url': 'https://www.princexml.com/samples/invoice-colorful/invoicesample.pdf',
        'name': 'invoice_1.pdf'
      },
      {
        'url': 'https://www.princexml.com/samples/invoice-plain/index.pdf',
        'name': 'invoice_2.pdf'
      },
      {
        'url': 'https://www.princexml.com/samples/textbook/somatosensory.pdf',
        'name': 'textbook.pdf'
      },
    ];

    for (var file in files) {
      final item = DownloadItem(
        filename: file['name']!,
        status: 'Waiting...',
        progress: 0.0,
        isComplete: false,
      );
      setState(() => _downloads.add(item));

      setState(() => item.status = 'Downloading...');

      final result = await FlutterAnyDownload.instance.download(
        url: file['url']!,
        filename: '${DateTime.now().millisecondsSinceEpoch}_${file['name']!}',
        onProgress: (downloaded, total) {
          setState(() {
            item.progress = downloaded / total;
            item.status = '${(item.progress * 100).toInt()}%';
          });
        },
      );

      setState(() {
        item.isComplete = result.success;
        item.status = result.success ? 'Complete' : 'Failed';
      });

      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Downloads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF59E0B).withValues(alpha:0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading || _downloads.isNotEmpty
                      ? null
                      : _downloadMultipleFiles,
                  icon: const Icon(Icons.file_download_rounded),
                  label: const Text('Start Batch Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _downloads.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_copy_rounded,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No downloads yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _downloads.length,
                itemBuilder: (context, index) {
                  final item = _downloads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.isComplete
                                      ? Colors.green.withValues(alpha:0.1)
                                      : const Color(0xFFF59E0B).withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.isComplete
                                      ? Icons.check_circle_rounded
                                      : Icons.description_rounded,
                                  color: item.isComplete
                                      ? Colors.green
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.filename,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!item.isComplete) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadItem {
  final String filename;
  String status;
  double progress;
  bool isComplete;

  DownloadItem({
    required this.filename,
    required this.status,
    this.progress = 0.0,
    this.isComplete = false,
  });
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await FlutterAnyDownload.instance.areNotificationsEnabled();
    setState(() => _permissionGranted = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await FlutterAnyDownload.instance.requestPermission();
    setState(() => _permissionGranted = granted);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                granted ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  granted
                      ? 'Permission granted!'
                      : 'Permission denied. Downloads will work without notifications.',
                ),
              ),
            ],
          ),
          backgroundColor: granted ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF3B82F6).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (_permissionGranted ?? false)
                            ? Colors.green.withValues(alpha:0.1)
                            : const Color(0xFF3B82F6).withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (_permissionGranted ?? false)
                            ? Icons.check_circle_rounded
                            : Icons.security_rounded,
                        size: 64,
                        color: (_permissionGranted ?? false)
                            ? Colors.green
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _permissionGranted == null
                          ? 'Checking...'
                          : _permissionGranted!
                          ? 'Notifications Enabled'
                          : 'Notifications Disabled',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _permissionGranted == null
                          ? 'Checking notification permission status...'
                          : _permissionGranted!
                          ? 'You will receive download progress notifications.'
                          : 'Enable notifications to see download progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _requestPermission,
                        icon: const Icon(Icons.security_rounded),
                        label: const Text('Request Permission'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FileTypesPage extends StatelessWidget {
  const FileTypesPage({super.key});

  Future<void> _downloadFile(
      BuildContext context,
      String url,
      String filename,
      String type,
      ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $type...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final result = await FlutterAnyDownload.instance.download(
      url: url,
      filename: '${DateTime.now().millisecondsSinceEpoch}_$filename',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                result.success
                    ? '$type downloaded successfully!'
                    : 'Failed: ${result.message}',
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Types'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEF4444).withValues(alpha:0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FileTypeCard(
              title: 'PDF Document',
              subtitle: 'Portable Document Format',
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.red,
              onTap: () => _downloadFile(
                context,
                'https://www.princexml.com/samples/newsletter/drylab.pdf',
                'document.pdf',
                'PDF',
              ),
            ),
            _FileTypeCard(
              title: 'ZIP Archive',
              subtitle: 'Compressed file',
              icon: Icons.folder_zip_rounded,
              color: Colors.orange,
              onTap: () => _downloadFile(
                context,
                'https://getsamplefiles.com/download/zip/sample-3.zip',
                'archive.zip',
                'ZIP',
              ),
            ),
            _FileTypeCard(
              title: 'JSON Data',
              subtitle: 'JavaScript Object Notation',
              icon: Icons.data_object_rounded,
              color: Colors.blue,
              onTap: () => _downloadFile(
                context,
                'https://jsonplaceholder.typicode.com/posts',
                'data.json',
                'JSON',
              ),
            ),
            _FileTypeCard(
              title: 'Text File',
              subtitle: 'Plain text document',
              icon: Icons.text_snippet_rounded,
              color: Colors.green,
              onTap: () => _downloadFile(
                context,
                'https://www.w3.org/TR/PNG/iso_8859-1.txt',
                'text.txt',
                'TXT',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FileTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}