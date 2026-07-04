import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/app.dart';
import 'package:miras/core/content/content_providers.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/home_path/domain/lesson_progress.dart';

import '../helpers/fakes.dart';

void main() {
  Widget app({FakeProgressRepository? progress}) {
    return ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(
          FakeContentRepository(
            chapterList: const [Fixtures.chapter],
            lessonMap: const {'zahak': Fixtures.lessons},
          ),
        ),
        progressRepositoryProvider.overrideWithValue(
          progress ?? FakeProgressRepository(),
        ),
      ],
      child: const MirasApp(),
    );
  }

  testWidgets('home path renders chapter and lessons in RTL', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final title = find.text('ضحاک و کاوهٔ آهنگر');
    expect(title, findsOneWidget);
    expect(find.text('واژگان ۱'), findsOneWidget);
    expect(find.text('تمرین ۱'), findsOneWidget);
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);
  });

  testWidgets('second lesson is locked until the first is completed', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // First node unlocked (type icon), second locked (lock icon).
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);
  });

  testWidgets('completed lesson shows stars and unlocks the next one', (
    tester,
  ) async {
    final progress = FakeProgressRepository(
      initial: {
        'zahak.l01': LessonProgress(
          lessonId: 'zahak.l01',
          stars: 3,
          bestAccuracy: 1,
          completedAt: DateTime.utc(2026),
        ),
      },
    );
    await tester.pumpWidget(app(progress: progress));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
  });

  testWidgets('bottom navigation switches to the library', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();

    expect(find.text('داستان ضحاک ماردوش و قیام کاوه.'), findsOneWidget);
  });
}
