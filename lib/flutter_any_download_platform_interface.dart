import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_any_download_method_channel.dart';

abstract class FlutterAnyDownloadPlatform extends PlatformInterface {
  /// Constructs a FlutterAnyDownloadPlatform.
  FlutterAnyDownloadPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAnyDownloadPlatform _instance = MethodChannelFlutterAnyDownload();

  /// The default instance of [FlutterAnyDownloadPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAnyDownload].
  static FlutterAnyDownloadPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAnyDownloadPlatform] when
  /// they register themselves.
  static set instance(FlutterAnyDownloadPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
