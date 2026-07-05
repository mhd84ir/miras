import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/content/models.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/couplet_view.dart';
import 'package:miras/core/widgets/tazhib_rosette.dart';
import 'package:miras/features/home_path/application/path_providers.dart';
import 'package:miras/features/home_path/presentation/widgets/lesson_path_node.dart';

import 'golden_harness.dart';

void main() {
  testWidgets('tazhib rosette', (tester) async {
    await pumpGolden(
      tester,
      const TazhibRosette(size: 220, color: MirasColorsRef.zarrin),
      surfaceSize: const Size(300, 300),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/tazhib_rosette.png'),
    );
  });

  testWidgets('couplet — dark theme', (tester) async {
    await pumpGolden(
      tester,
      const CoupletView(
        hemistich1: 'چو ضحاک شد بر جهان شهریار',
        hemistich2: 'بر او سالیان انجمن شد هزار',
      ),
      brightness: Brightness.dark,
      surfaceSize: const Size(360, 260),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/couplet_view_dark.png'),
    );
  });

  testWidgets('lesson path nodes — dark theme', (tester) async {
    await pumpGolden(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LessonPathNode(
            node: const LessonNode(
              lesson: Lesson(
                id: 'zahak.l01',
                chapterId: 'zahak',
                position: 0,
                type: LessonType.vocab,
                title: 'واژگان ۱ — مرداس و ابلیس',
              ),
              status: LessonNodeStatus.completed,
              stars: 3,
            ),
            onTap: () {},
          ),
          LessonPathNode(
            node: const LessonNode(
              lesson: Lesson(
                id: 'zahak.l02',
                chapterId: 'zahak',
                position: 1,
                type: LessonType.practice,
                title: 'تمرین واژگان ۱',
              ),
              status: LessonNodeStatus.available,
            ),
            onTap: () {},
          ),
        ],
      ),
      brightness: Brightness.dark,
      surfaceSize: const Size(400, 260),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/lesson_path_nodes_dark.png'),
    );
  });

  testWidgets('type scale at 1.3x font scale', (tester) async {
    await pumpGolden(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('چو ایران نباشد تن من مباد', style: MirasTextStyles.headline),
          Text('چو ایران نباشد تن من مباد', style: MirasTextStyles.body),
          Text(
            'داستان‌های شاهنامه؛ می‌خوانیم و می‌آموزیم',
            style: MirasTextStyles.bodySmall,
          ),
        ],
      ),
      textScaler: const TextScaler.linear(1.3),
      surfaceSize: const Size(420, 300),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/typography_scaled_1_3.png'),
    );
  });
}

/// Static color refs for const contexts in tests.
abstract final class MirasColorsRef {
  static const zarrin = Color(0xFFC9A227);
}
