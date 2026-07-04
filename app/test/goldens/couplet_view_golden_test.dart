import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/widgets/couplet_view.dart';

import 'golden_harness.dart';

void main() {
  const hemistich1 = 'به نام خداوند جان و خرد';
  const hemistich2 = 'کزین برتر اندیشه برنگذرد';

  testWidgets('CoupletView stacked (narrow) — light', (tester) async {
    await pumpGolden(
      tester,
      const CoupletView(hemistich1: hemistich1, hemistich2: hemistich2),
      surfaceSize: const Size(360, 260),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/couplet_view_narrow_light.png'),
    );
  });

  testWidgets('CoupletView side-by-side (wide) — light', (tester) async {
    await pumpGolden(
      tester,
      const CoupletView(hemistich1: hemistich1, hemistich2: hemistich2),
      surfaceSize: const Size(700, 220),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/couplet_view_wide_light.png'),
    );
  });
}
