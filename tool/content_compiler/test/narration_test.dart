import 'package:content_compiler/content_compiler.dart';
import 'package:test/test.dart';

const _xml = '''
<DesktopGanjoorPoemAudioList>
  <PoemAudio>
    <OneSecondBugFix>1000</OneSecondBugFix>
    <SyncArray>
      <SyncInfo><VerseOrder>0</VerseOrder><AudioMiliseconds>1686</AudioMiliseconds></SyncInfo>
      <SyncInfo><VerseOrder>1</VerseOrder><AudioMiliseconds>4836</AudioMiliseconds></SyncInfo>
      <SyncInfo><VerseOrder>2</VerseOrder><AudioMiliseconds>9186</AudioMiliseconds></SyncInfo>
      <SyncInfo><VerseOrder>3</VerseOrder><AudioMiliseconds>14286</AudioMiliseconds></SyncInfo>
    </SyncArray>
  </PoemAudio>
</DesktopGanjoorPoemAudioList>
''';

void main() {
  group('parseSyncXml', () {
    test('reads 0-based hemistich starts in milliseconds', () {
      final starts = parseSyncXml(_xml);
      expect(starts, {0: 1686, 1: 4836, 2: 9186, 3: 14286});
    });

    test('applies the OneSecondBugFix time scale', () {
      final scaled = parseSyncXml(
        _xml.replaceFirst(
          '<OneSecondBugFix>1000</OneSecondBugFix>',
          '<OneSecondBugFix>500</OneSecondBugFix>',
        ),
      );
      expect(scaled[0], 3372);
    });

    test('keeps the −1 title marker when present', () {
      // Observed in real files (e.g. recitation 22796) BEFORE hemistich 0:
      // −1 is the poem-title announcement, not an end-of-audio bound.
      final starts = parseSyncXml(
        _xml.replaceFirst(
          '<SyncInfo><VerseOrder>0</VerseOrder>',
          '<SyncInfo><VerseOrder>-1</VerseOrder>'
              '<AudioMiliseconds>500</AudioMiliseconds></SyncInfo>'
              '<SyncInfo><VerseOrder>0</VerseOrder>',
        ),
      );
      expect(starts[-1], 500);
      expect(starts[0], 1686);
    });
  });

  group('coupletRangeMs', () {
    final starts = parseSyncXml(_xml);

    test('a couplet spans its first hemistich to the next couplet', () {
      expect(coupletRangeMs(starts, 0), (startMs: 1686, endMs: 9186));
    });

    test('the last couplet runs to end of file without a marker', () {
      expect(coupletRangeMs(starts, 1), (startMs: 9186, endMs: null));
    });

    test('the −1 title marker never serves as an end bound', () {
      // A title marker at the START of the audio must not truncate the
      // final couplet into a negative range (the sohrab sh1 regression).
      final withTitle = Map<int, int>.of(starts)..[-1] = 500;
      expect(coupletRangeMs(withTitle, 1), (startMs: 9186, endMs: null));
    });

    test('a couplet missing from the sync is a hard error', () {
      expect(() => coupletRangeMs(starts, 7), throwsStateError);
    });

    test('an out-of-order sync is a hard error, not a garbled clip', () {
      final broken = Map<int, int>.of(starts)..[2] = 100;
      expect(() => coupletRangeMs(broken, 0), throwsStateError);
    });
  });

  group('parseGanjoorRef', () {
    test('splits path and couplet index', () {
      expect(
        parseGanjoorRef('ganjoor:/ferdousi/shahname/zahak/sh1#3'),
        (path: '/ferdousi/shahname/zahak/sh1', couplet: 3),
      );
    });

    test('rejects malformed refs', () {
      expect(() => parseGanjoorRef('zahak/sh1#3'), throwsFormatException);
    });
  });
}
