import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miras/core/content/data/pack_bootstrap.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, Uint8List> assets;

  @override
  Future<ByteData> load(String key) async {
    final data = assets[key];
    if (data == null) throw StateError('missing asset: $key');
    return ByteData.sublistView(data);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('miras_bootstrap'));
  tearDown(() => tmp.deleteSync(recursive: true));

  /// A minimal but real pack DB: just the content_pack row the bootstrap
  /// reads.
  Uint8List packBytes({
    required int version,
    required String checksum,
    String builtAt = '2026-07-09T00:00:00Z',
  }) {
    final path = p.join(
      tmp.path,
      'gen_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    sqlite3.open(path)
      ..execute(
        'CREATE TABLE content_pack (pack_version INTEGER, '
        'schema_version INTEGER, checksum TEXT, built_at TEXT)',
      )
      ..execute('INSERT INTO content_pack VALUES (?, 1, ?, ?)', [
        version,
        checksum,
        builtAt,
      ])
      ..close();
    final bytes = File(path).readAsBytesSync();
    File(path).deleteSync();
    return bytes;
  }

  _FakeBundle bundleWith({
    required Uint8List db,
    required int version,
    required String checksum,
    bool includeMeta = true,
  }) => _FakeBundle({
    'assets/content/miras_content.db': db,
    if (includeMeta)
      'assets/content/pack_meta.json': Uint8List.fromList(
        utf8.encode(
          jsonEncode({'pack_version': version, 'checksum': checksum}),
        ),
      ),
  });

  File installedFile() => File(p.join(tmp.path, 'content', 'miras_content.db'));

  test('fresh install copies the bundled pack', () async {
    final bundledDb = packBytes(version: 2, checksum: 'aaa');
    final target = await ensureContentPack(
      supportDir: tmp,
      bundle: bundleWith(db: bundledDb, version: 2, checksum: 'aaa'),
    );

    expect(target.readAsBytesSync(), bundledDb);
  });

  test(
    'matching version+checksum keeps the installed pack untouched',
    () async {
      // Same identity, different bytes (built_at differs) — proving the
      // decision is the version check, not a byte compare.
      final installed = packBytes(
        version: 2,
        checksum: 'aaa',
        builtAt: 'installed-build',
      );
      installedFile()
        ..createSync(recursive: true)
        ..writeAsBytesSync(installed);
      final bundledDb = packBytes(version: 2, checksum: 'aaa');

      final target = await ensureContentPack(
        supportDir: tmp,
        bundle: bundleWith(db: bundledDb, version: 2, checksum: 'aaa'),
      );

      expect(target.readAsBytesSync(), installed);
    },
  );

  test('a different checksum replaces the installed pack', () async {
    installedFile()
      ..createSync(recursive: true)
      ..writeAsBytesSync(packBytes(version: 2, checksum: 'old'));
    final bundledDb = packBytes(version: 2, checksum: 'new');

    final target = await ensureContentPack(
      supportDir: tmp,
      bundle: bundleWith(db: bundledDb, version: 2, checksum: 'new'),
    );

    expect(target.readAsBytesSync(), bundledDb);
  });

  test('a corrupt installed pack is replaced, not fatal', () async {
    installedFile()
      ..createSync(recursive: true)
      ..writeAsBytesSync(Uint8List.fromList(List.filled(64, 7)));
    final bundledDb = packBytes(version: 2, checksum: 'aaa');

    final target = await ensureContentPack(
      supportDir: tmp,
      bundle: bundleWith(db: bundledDb, version: 2, checksum: 'aaa'),
    );

    expect(target.readAsBytesSync(), bundledDb);
  });

  test('a missing sidecar falls back to copying the bundled pack', () async {
    installedFile()
      ..createSync(recursive: true)
      ..writeAsBytesSync(packBytes(version: 2, checksum: 'aaa'));
    final bundledDb = packBytes(version: 2, checksum: 'aaa');

    final target = await ensureContentPack(
      supportDir: tmp,
      bundle: bundleWith(
        db: bundledDb,
        version: 2,
        checksum: 'aaa',
        includeMeta: false,
      ),
    );

    expect(target.readAsBytesSync(), bundledDb);
  });
}
