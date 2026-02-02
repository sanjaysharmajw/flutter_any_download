import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_any_download_platform_interface.dart';

/// An implementation of [FlutterAnyDownloadPlatform] that uses method channels.
class MethodChannelFlutterAnyDownload extends FlutterAnyDownloadPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_any_download');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
