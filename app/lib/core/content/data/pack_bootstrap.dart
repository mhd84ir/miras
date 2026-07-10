import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Materializes the bundled content pack as a real file (SQLite cannot open
/// Flutter assets directly), replacing the installed copy only when the
/// bundled pack actually differs.
///
/// The decision reads the bundled `pack_meta.json` sidecar (~100 bytes) and
/// the installed pack's `content_pack` row — never whole-file bytes
/// (ADR-0010). This is also the seam where a downloaded pack will win over
/// the bundled one once CDN delivery ships.
Future<File> ensureContentPack({
  @visibleForTesting Directory? supportDir,
  @visibleForTesting AssetBundle? bundle,
}) async {
  final assets = bundle ?? rootBundle;
  final dir = supportDir ?? await getApplicationSupportDirectory();
  final target = File(p.join(dir.path, 'content', 'miras_content.db'));

  if (target.existsSync() && await _matchesBundled(assets, target)) {
    return target;
  }

  final bundled = await assets.load('assets/content/miras_content.db');
  target.parent.createSync(recursive: true);
  await target.writeAsBytes(bundled.buffer.asUint8List(), flush: true);
  return target;
}

Future<bool> _matchesBundled(AssetBundle assets, File installed) async {
  try {
    final meta =
        jsonDecode(await assets.loadString('assets/content/pack_meta.json'))
            as Map<String, dynamic>;
    final db = sqlite3.open(installed.path, mode: OpenMode.readOnly);
    try {
      final row = db
          .select('SELECT pack_version, checksum FROM content_pack')
          .single;
      return row['pack_version'] == meta['pack_version'] &&
          row['checksum'] == meta['checksum'];
    } finally {
      db.close();
    }
    // Deliberately broad: a missing sidecar throws FlutterError (an Error),
    // a corrupt installed pack throws SqliteException — either way the
    // answer is "replace with the bundled copy", never a boot failure.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return false;
  }
}
