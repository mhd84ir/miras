import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/router/app_router.dart';
import 'package:miras/core/theme/miras_theme.dart';
import 'package:miras/features/gamification/application/stats_providers.dart';

class MirasApp extends ConsumerStatefulWidget {
  const MirasApp({this.initialLocation = AppRoutes.home, super.key});

  /// Set to /onboarding on first run (decided at bootstrap).
  final String initialLocation;

  @override
  ConsumerState<MirasApp> createState() => _MirasAppState();
}

class _MirasAppState extends ConsumerState<MirasApp> {
  // Created once: recreating the router on rebuild would reset navigation.
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  Widget build(BuildContext context) {
    final themeMode =
        ref.watch(profileProvider).value?.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: _router,
      theme: buildMirasTheme(Brightness.light),
      darkTheme: buildMirasTheme(Brightness.dark),
      themeMode: themeMode,
      // Persian-only for phase 1; setting the locale makes the entire app RTL.
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
