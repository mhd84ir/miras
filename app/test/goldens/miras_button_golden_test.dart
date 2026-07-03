import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/widgets/miras_button.dart';

import 'golden_harness.dart';

void main() {
  Widget buttons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MirasButton(label: 'شروع یادگیری', onPressed: () {}),
        const SizedBox(height: 12),
        MirasButton(
          label: 'ادامه',
          variant: MirasButtonVariant.secondary,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        MirasButton(
          label: 'رد شدن',
          variant: MirasButtonVariant.text,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        const MirasButton(label: 'غیرفعال', onPressed: null),
      ],
    );
  }

  testWidgets('MirasButton variants — light', (tester) async {
    await pumpGolden(tester, buttons(), surfaceSize: const Size(360, 400));
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/miras_button_light.png'),
    );
  });

  testWidgets('MirasButton variants — dark', (tester) async {
    await pumpGolden(
      tester,
      buttons(),
      brightness: Brightness.dark,
      surfaceSize: const Size(360, 400),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/miras_button_dark.png'),
    );
  });
}
