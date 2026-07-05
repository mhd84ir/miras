import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_theme.dart';

/// Pumps [child] inside the real app theme, `fa` locale, and RTL — every
/// component golden goes through here so RTL correctness is what gets
/// snapshotted, per docs/ARCHITECTURE.md §8.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size surfaceSize = const Size(400, 700),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildMirasTheme(brightness),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: appChild!,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder goldenSubject() => find.byType(MaterialApp);
