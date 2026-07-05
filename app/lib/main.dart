import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miras/app.dart';
import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/data/content_database.dart';
import 'package:miras/core/content/data/drift_content_repository.dart';
import 'package:miras/core/content/data/pack_bootstrap.dart';
import 'package:miras/core/db/user_database.dart';
import 'package:miras/core/notifications/notification_service.dart';
import 'package:miras/core/router/app_router.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/review/data/srs_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The pack copy is ~100 KB; doing it before runApp keeps every screen's
  // data path synchronous and spinner-free.
  final packFile = await ensureContentPack();
  final contentDb = ContentDatabase.openPack(packFile);
  final userDb = UserDatabase.open();

  final gamification = DriftGamificationRepository(userDb);
  await gamification.ensureSeeded();
  final onboarded = (await gamification.watchProfile().first).onboarded;

  runApp(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(
          DriftContentRepository(contentDb),
        ),
        progressRepositoryProvider.overrideWithValue(
          DriftProgressRepository(userDb),
        ),
        gamificationRepositoryProvider.overrideWithValue(gamification),
        srsRepositoryProvider.overrideWithValue(DriftSrsRepository(userDb)),
        notificationServiceProvider.overrideWithValue(
          LocalNotificationService(),
        ),
      ],
      child: MirasApp(
        initialLocation: onboarded ? AppRoutes.home : AppRoutes.onboarding,
      ),
    ),
  );
}
