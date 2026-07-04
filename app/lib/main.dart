import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/app.dart';
import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/data/content_database.dart';
import 'package:miras/core/content/data/drift_content_repository.dart';
import 'package:miras/core/content/data/pack_bootstrap.dart';
import 'package:miras/core/db/user_database.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The pack copy is ~100 KB; doing it before runApp keeps every screen's
  // data path synchronous and spinner-free.
  final packFile = await ensureContentPack();
  final contentDb = ContentDatabase.openPack(packFile);
  final userDb = UserDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(
          DriftContentRepository(contentDb),
        ),
        progressRepositoryProvider.overrideWithValue(
          DriftProgressRepository(userDb),
        ),
      ],
      child: const MirasApp(),
    ),
  );
}
