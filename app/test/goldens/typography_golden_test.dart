import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/theme/miras_text_styles.dart';

import 'golden_harness.dart';

void main() {
  testWidgets('type scale — light', (tester) async {
    const sample = 'چو ایران نباشد تن من مباد';
    const zwnjSample = 'داستان‌های شاهنامه؛ می‌خوانیم و می‌آموزیم';

    await pumpGolden(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sample, style: MirasTextStyles.display),
          Text(sample, style: MirasTextStyles.headline),
          Text(sample, style: MirasTextStyles.title),
          Text(sample, style: MirasTextStyles.body),
          Text(sample, style: MirasTextStyles.bodySmall),
          Text(sample, style: MirasTextStyles.caption),
          SizedBox(height: 16),
          // ZWNJ rendering check: joined pairs must stay visually attached.
          Text(zwnjSample, style: MirasTextStyles.body),
        ],
      ),
      surfaceSize: const Size(420, 460),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/typography_light.png'),
    );
  });
}
