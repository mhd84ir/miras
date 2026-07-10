import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/haptics/haptics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late StreamController<bool> enabled;
  late VibratorHapticsService service;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('miras/haptics'), (
          call,
        ) async {
          calls.add(call);
          return null;
        });
    enabled = StreamController<bool>();
    service = VibratorHapticsService(enabled: enabled.stream);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('miras/haptics'), null);
    await enabled.close();
  });

  test('toggle off means zero vibrator calls (M8 pass criterion)', () async {
    enabled.add(false);
    await Future<void>.delayed(Duration.zero);

    await service.success();
    await service.failure();
    await service.celebrate();

    expect(calls, isEmpty);
  });

  test('enabled again, every effect reaches the channel', () async {
    enabled
      ..add(false)
      ..add(true);
    await Future<void>.delayed(Duration.zero);

    await service.success();
    await service.failure();
    await service.celebrate(); // two pulses

    expect(calls, hasLength(4));
    expect(calls.first.method, 'vibrate');
    expect(
      (calls.first.arguments as Map<Object?, Object?>)['durationMs'],
      25,
    );
  });

  test('haptics default on before the first settings emission', () async {
    await service.success();
    expect(calls, hasLength(1));
  });

  test('success is shorter and lighter than failure', () async {
    await service.success();
    await service.failure();

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
  });

  test('a missing channel implementation is a silent no-op', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('miras/haptics'), null);

    // Must not throw (tests, future iOS until the channel exists there).
    await service.success();
  });
}
