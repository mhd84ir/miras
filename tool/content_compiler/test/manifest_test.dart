import 'dart:io';

import 'package:content_compiler/content_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('buildManifest', () {
    test('is schema-versioned with files sorted by path', () {
      final manifest = buildManifest(
        packVersion: 3,
        schemaVersion: 1,
        checksum: 'abc',
        files: {
          'audio/zz.mp3': (sha256: 'z', bytes: 10),
          'audio/aa.mp3': (sha256: 'a', bytes: 20),
          'miras_content.db': (sha256: 'd', bytes: 30),
        },
        builtAt: DateTime.utc(2026, 7, 9),
      );

      expect(manifest['schema'], 1);
      expect(manifest['pack_version'], 3);
      expect(manifest['checksum'], 'abc');
      final files = manifest['files']! as List<Object?>;
      expect(
        [for (final f in files) (f! as Map<String, Object?>)['path']],
        ['audio/aa.mp3', 'audio/zz.mp3', 'miras_content.db'],
      );
    });
  });

  group('asset-inclusive checksum (ADR-0010)', () {
    late ContentBundle bundle;
    late Directory tmp;

    setUp(() {
      bundle = YamlLoader(Directory('test/fixtures/valid')).load();
      tmp = Directory.systemTemp.createTempSync('miras_checksum');
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    String writePack(String name, Map<String, String> digests) => PackWriter(
      bundle: bundle,
      packVersion: 1,
      assetDigests: digests,
    ).write(File(p.join(tmp.path, '$name.db')));

    test('changed audio bytes change the pack checksum', () {
      final without = writePack('a', const {});
      final withAudio = writePack('b', const {'audio/x.mp3': 'digest1'});
      final changedAudio = writePack('c', const {'audio/x.mp3': 'digest2'});

      expect(without, isNot(withAudio));
      expect(withAudio, isNot(changedAudio));
    });

    test('identical text and assets stay deterministic', () {
      const digests = {'audio/x.mp3': 'digest1', 'audio/y.mp3': 'digest2'};
      expect(writePack('a', digests), writePack('b', digests));
    });

    test('returned checksum matches the stored content_pack row', () {
      final returned = writePack('a', const {'audio/x.mp3': 'digest1'});
      final db = sqlite3.open(
        p.join(tmp.path, 'a.db'),
        mode: OpenMode.readOnly,
      );
      addTearDown(db.close);
      expect(
        db.select('SELECT checksum FROM content_pack').single['checksum'],
        returned,
      );
    });
  });
}
