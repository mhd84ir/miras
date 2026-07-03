import 'package:flutter/material.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/router/app_router.dart';
import 'package:miras/core/theme/miras_theme.dart';

class MirasApp extends StatelessWidget {
  const MirasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: appRouter,
      theme: buildMirasTheme(Brightness.light),
      // Persian-only for phase 1; setting the locale makes the entire app RTL.
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
