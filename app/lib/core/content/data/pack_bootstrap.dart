import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Materializes the bundled content pack as a real file (SQLite cannot open
/// Flutter assets directly) and keeps it in sync with the bundled bytes.
///
/// Comparison is by content: the pack is ~100 KB, so hashing both sides on
/// startup is cheaper than being clever. When CDN-delivered packs arrive
/// (post-MVP), this becomes "bundled pack as fallback, downloaded pack wins".
Future<File> ensureContentPack({
  @visibleForTesting Directory? supportDir,
}) async {
  final dir = supportDir ?? await getApplicationSupportDirectory();
  final target = File(p.join(dir.path, 'content', 'miras_content.db'));

  final bundled = await rootBundle.load('assets/content/miras_content.db');
  final bundledBytes = bundled.buffer.asUint8List();

  if (!target.existsSync() ||
      !_sameContent(bundledBytes, await target.readAsBytes())) {
    target.parent.createSync(recursive: true);
    await target.writeAsBytes(bundledBytes, flush: true);
  }
  return target;
}

bool _sameContent(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
