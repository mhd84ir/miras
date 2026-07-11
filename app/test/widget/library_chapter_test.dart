import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/audio/audio_service.dart';
import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/features/library/presentation/library_chapter_screen.dart';

import '../goldens/golden_harness.dart';
import '../helpers/fakes.dart';

class _RecordingAudioService implements AudioService {
  final played = <String>[];

  @override
  Stream<bool> get playing => const Stream.empty();

  @override
  Future<void> playAsset(String assetPath) async => played.add(assetPath);

  @override
  Future<void> stop() async {}
}

void main() {
  final strings = lookupAppLocalizations(const Locale('fa'));

  const narrated = Verse(
    id: 'zahak.v001',
    chapterId: 'zahak',
    position: 0,
    hemistich1: 'چو ضحاک شد بر جهان شهریار',
    hemistich2: 'بر او سالیان انجمن شد هزار',
    meaning: 'چون ضحاک فرمانروای جهان شد، هزار سال پادشاهی کرد.',
    audioAsset: 'audio/abc123.mp3',
  );
  const silent = Verse(
    id: 'zahak.v002',
    chapterId: 'zahak',
    position: 1,
    hemistich1: 'نهان گشت کردار فرزانگان',
    hemistich2: 'پراگنده شد کام دیوانگان',
    meaning: 'رفتار خردمندان پنهان شد.',
  );

  late _RecordingAudioService audio;

  Widget screen({List<Credit> credits = const []}) {
    audio = _RecordingAudioService();
    return ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(
          FakeContentRepository(
            verseMap: const {'zahak.v001': narrated, 'zahak.v002': silent},
            creditList: credits,
          ),
        ),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: const LibraryChapterScreen(chapterId: 'zahak'),
    );
  }

  const credit = Credit(
    id: 'narration:zahak:فرید حامد',
    kind: 'narration',
    name: 'فرید حامد',
    url: 'https://t.me/GouyaKetab',
  );

  testWidgets('narrated verses get a play button; silent ones do not', (
    tester,
  ) async {
    await pumpGolden(tester, screen(credits: const [credit]));

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    expect(audio.played, ['audio/abc123.mp3']);
  });

  testWidgets('the خوانش credit appears when narration is present', (
    tester,
  ) async {
    // Chapter-scoped rows repeat the same narrator; the footer dedupes.
    const duplicate = Credit(
      id: 'narration:jamshid:فرید حامد',
      kind: 'narration',
      name: 'فرید حامد',
    );
    await pumpGolden(tester, screen(credits: const [credit, duplicate]));

    await tester.scrollUntilVisible(
      find.text(strings.libraryNarrationCredit('فرید حامد')),
      200,
    );
    expect(
      find.text(strings.libraryNarrationCredit('فرید حامد')),
      findsOneWidget,
    );
  });

  testWidgets('no credit row without narration credits', (tester) async {
    await pumpGolden(tester, screen());

    expect(find.textContaining('خوانش از'), findsNothing);
  });
}
