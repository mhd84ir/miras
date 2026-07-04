import 'dart:convert';
import 'dart:io';

import 'package:content_compiler/content_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test(
    'valid fixture loads, validates cleanly, and round-trips through a pack',
    () async {
      final loader = YamlLoader(Directory('test/fixtures/valid'));
      final bundle = loader.load();
      final issues = [...loader.issues, ...Validator(bundle).validate()];
      expect(
        issues.where((i) => i.severity == IssueSeverity.error),
        isEmpty,
        reason: issues.join('\n'),
      );

      final tmp = Directory.systemTemp.createTempSync('miras_pack_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final dbFile = File(p.join(tmp.path, 'pack.db'));
      PackWriter(bundle: bundle, packVersion: 7).write(dbFile);

      final db = sqlite3.open(dbFile.path, mode: OpenMode.readOnly);
      addTearDown(db.close);

      final pack = db.select('SELECT * FROM content_pack').single;
      expect(pack['pack_version'], 7);
      expect(pack['schema_version'], contentSchemaVersion);
      expect(pack['checksum'], hasLength(64));

      expect(db.select('SELECT * FROM chapters'), hasLength(1));
      expect(db.select('SELECT * FROM lessons'), hasLength(2));
      expect(db.select('SELECT * FROM exercises'), hasLength(5));
      expect(db.select('SELECT * FROM vocabulary_items'), hasLength(2));
      expect(db.select('SELECT * FROM verse_vocabulary'), hasLength(2));

      final verse = db.select('SELECT * FROM verses').single;
      expect(verse['hemistich_1'], 'به نام خداوند جان و خرد');
      expect(verse['source'], 'ganjoor:/ferdousi/shahname/aghaz/sh1#0');

      final cloze = db
          .select(
            "SELECT prompt_json FROM exercises WHERE type = 'cloze'",
          )
          .single;
      final prompt =
          jsonDecode(cloze['prompt_json'] as String) as Map<String, dynamic>;
      expect(prompt['blankToken'], 5);
      expect(prompt['options'], contains('خرد'));
    },
  );

  test('identical content produces an identical checksum (deterministic)', () {
    final bundleA = YamlLoader(Directory('test/fixtures/valid')).load();
    final bundleB = YamlLoader(Directory('test/fixtures/valid')).load();

    final tmp = Directory.systemTemp.createTempSync('miras_pack_det');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final a = File(p.join(tmp.path, 'a.db'));
    final b = File(p.join(tmp.path, 'b.db'));
    PackWriter(bundle: bundleA, packVersion: 1).write(a);
    PackWriter(bundle: bundleB, packVersion: 1).write(b);

    String checksum(File f) {
      final db = sqlite3.open(f.path, mode: OpenMode.readOnly);
      try {
        return db.select('SELECT checksum FROM content_pack').single['checksum']
            as String;
      } finally {
        db.close();
      }
    }

    expect(checksum(a), checksum(b));
  });

  test('missing files and broken structure produce clear errors', () {
    final tmp = Directory.systemTemp.createTempSync('miras_invalid');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final chapterDir = Directory(p.join(tmp.path, 'chapters/broken'))
      ..createSync(recursive: true);
    File(p.join(chapterDir.path, 'chapter.yaml')).writeAsStringSync('''
id: broken
position: 1
title: "فصل شکسته"
subtitle: "س"
summary: "خ"
lessons:
  - lessons/missing.yaml
''');

    final loader = YamlLoader(Directory(tmp.path));
    final bundle = loader.load();
    final issues = [...loader.issues, ...Validator(bundle).validate()];
    final messages = issues.map((i) => i.toString()).join('\n');

    expect(messages, contains('vocab.yaml'));
    expect(messages, contains('file not found'));
    expect(messages, contains('missing.yaml'));
    expect(messages, contains('no lessons'));
  });
}
