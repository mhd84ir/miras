/// Pure helpers for آوای گنجور recitation import (ADR-0011): parsing the
/// Desktop-Ganjoor sync XML and mapping authored `source:` refs to couplet
/// time ranges. All IO lives in the importer; this file is unit-tested math.
library;

/// Start time (ms) per 0-based hemistich order, from a recitation sync XML.
///
/// `OneSecondBugFix` is the legacy time-scale marker (1000 = plain
/// milliseconds); a `VerseOrder` of −1, when present, marks end-of-audio and
/// is kept so it can serve as the final couplet's end bound.
Map<int, int> parseSyncXml(String xml) {
  final fixMatch = RegExp(
    r'<OneSecondBugFix>(\d+)</OneSecondBugFix>',
  ).firstMatch(xml);
  final fix = int.parse(fixMatch?.group(1) ?? '1000');

  final starts = <int, int>{};
  final entries = RegExp(
    r'<SyncInfo>\s*<VerseOrder>(-?\d+)</VerseOrder>\s*'
    r'<AudioMiliseconds>(\d+)</AudioMiliseconds>\s*</SyncInfo>',
  );
  for (final m in entries.allMatches(xml)) {
    starts[int.parse(m.group(1)!)] = int.parse(m.group(2)!) * 1000 ~/ fix;
  }
  return starts;
}

/// The time slice for 0-based [coupletIndex]: from its first hemistich's
/// start to the next couplet's start (or the −1 end marker); a null end
/// means "to end of file". Throws [StateError] when the recitation has no
/// sync entry for the couplet — silence would otherwise ship as content.
({int startMs, int? endMs}) coupletRangeMs(
  Map<int, int> starts,
  int coupletIndex,
) {
  final start = starts[2 * coupletIndex];
  if (start == null) {
    throw StateError('no sync entry for couplet $coupletIndex');
  }
  return (startMs: start, endMs: starts[2 * coupletIndex + 2] ?? starts[-1]);
}

/// Splits an authored provenance ref `ganjoor:<path>#<couplet-index>`.
({String path, int couplet}) parseGanjoorRef(String source) {
  final m = RegExp(r'^ganjoor:([^#]+)#(\d+)$').firstMatch(source);
  if (m == null) {
    throw FormatException('not a ganjoor source ref: $source');
  }
  return (path: m.group(1)!, couplet: int.parse(m.group(2)!));
}
