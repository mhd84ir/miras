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

    test('keeps the −1 end-of-audio marker when present', () {
      final starts = parseSyncXml(
        _xml.replaceFirst(
          '</SyncArray>',
          '<SyncInfo><VerseOrder>-1</VerseOrder>'
              '<AudioMiliseconds>20000</AudioMiliseconds></SyncInfo>'
              '</SyncArray>',
        ),
      );
      expect(starts[-1], 20000);
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

    test('the last couplet ends at the −1 marker when present', () {
      final withEnd = Map<int, int>.of(starts)..[-1] = 20000;
      expect(coupletRangeMs(withEnd, 1), (startMs: 9186, endMs: 20000));
    });

    test('a couplet missing from the sync is a hard error', () {
      expect(() => coupletRangeMs(starts, 7), throwsStateError);
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
