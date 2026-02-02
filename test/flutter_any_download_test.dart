// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_any_download/flutter_any_download.dart';
// import 'package:flutter_any_download/flutter_any_download_platform_interface.dart';
// import 'package:flutter_any_download/flutter_any_download_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockFlutterAnyDownloadPlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterAnyDownloadPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final FlutterAnyDownloadPlatform initialPlatform = FlutterAnyDownloadPlatform.instance;
//
//   test('$MethodChannelFlutterAnyDownload is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelFlutterAnyDownload>());
//   });
//
//   test('getPlatformVersion', () async {
//     FlutterAnyDownload flutterAnyDownloadPlugin = FlutterAnyDownload();
//     MockFlutterAnyDownloadPlatform fakePlatform = MockFlutterAnyDownloadPlatform();
//     FlutterAnyDownloadPlatform.instance = fakePlatform;
//
//     expect(await flutterAnyDownloadPlugin.getPlatformVersion(), '42');
//   });
// }
