import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/db/user_database.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';

void main() {
  late UserDatabase db;
  late DriftGamificationRepository repo;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
    repo = DriftGamificationRepository(
      db,
      clock: () => DateTime.utc(2026, 7, 9, 12),
    );
    await repo.ensureSeeded();
  });

  tearDown(() => db.close());

  test(
    'seeded profile defaults: sounds and haptics on, notifications off',
    () async {
      final profile = await repo.watchProfile().first;
      expect(profile.soundEnabled, isTrue);
      expect(profile.hapticsEnabled, isTrue);
      expect(profile.notificationsEnabled, isFalse);
      expect(profile.onboarded, isFalse);
    },
  );

  test('haptics and sound toggles round-trip through the store', () async {
    await repo.setHapticsEnabled(enabled: false);
    await repo.setSoundEnabled(enabled: false);

    final profile = await repo.watchProfile().first;
    expect(profile.hapticsEnabled, isFalse);
    expect(profile.soundEnabled, isFalse);
  });

  test('installedAt is the seeded profile creation time', () async {
    expect(await repo.installedAt(), DateTime.utc(2026, 7, 9, 12));
  });
}
