import 'package:integration_test/integration_test_driver.dart';

/// Host-side driver: `flutter drive --driver=test_driver/integration_test.dart`
/// writes each test's reportData (the perf report) to
/// build/integration_response_data.json.
Future<void> main() => integrationDriver();
