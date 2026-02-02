// // This is a basic Flutter integration test.
// //
// // Since integration tests run in a full Flutter application, they can interact
// // with the host side of a plugin implementation, unlike Dart unit tests.
// //
// // For more information about Flutter integration tests, please see
// // https://flutter.dev/to/integration-testing
//
//
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
//
// import 'package:flutter_any_download/flutter_any_download.dart';
//
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   testWidgets('getPlatformVersion test', (WidgetTester tester) async {
//     final FlutterAnyDownload plugin = FlutterAnyDownload();
//     final String? version = await plugin.getPlatformVersion();
//     // The version string depends on the host platform running the test, so
//     // just assert that some non-empty string is returned.
//     expect(version?.isNotEmpty, true);
//   });
// }
