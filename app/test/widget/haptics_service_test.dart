import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/haptics/haptics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('miras/haptics');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'success sends a short light pulse, failure a longer strong one',
    () async {
      const haptics = VibratorHapticsService();

      await haptics.success();
      await haptics.failure();

      expect(calls, hasLength(2));
      expect(calls[0].method, 'vibrate');
      final success = calls[0].arguments as Map<Object?, Object?>;
      final failure = calls[1].arguments as Map<Object?, Object?>;
      expect(
        (success['durationMs']! as int) < (failure['durationMs']! as int),
        isTrue,
      );
      expect(
        (success['amplitude']! as int) < (failure['amplitude']! as int),
        isTrue,
      );
    },
  );

  test('a missing channel implementation is a silent no-op', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    // Must not throw (tests, future iOS until the channel exists there).
    await const VibratorHapticsService().success();
  });
}
