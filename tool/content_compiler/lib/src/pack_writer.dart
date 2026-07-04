import 'dart:convert';
import 'dart:io';

import 'package:content_compiler/src/model/content.dart';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

/// Content-store schema version understood by the app (docs/DATA_MODEL.md).
const contentSchemaVersion = 1;

/// Writes a [ContentBundle] into a SQLite content pack.
///
/// The pack is the single runtime artifact: the app opens it read-only and
/// never sees YAML. Schema mirrors docs/DATA_MODEL.md §1.
class PackWriter {
  PackWriter({
    required this.bundle,
    required this.packVersion,
    this.audioAssets = const {},
  });

  final ContentBundle bundle;
  final int packVersion;

  /// content id (vocab/verse) → pack-relative audio asset path.
  final Map<String, String> audioAssets;

  void write(File dbFile) {
    if (dbFile.existsSync()) dbFile.deleteSync();
    dbFile.parent.createSync(recursive: true);

    final db = sqlite3.open(dbFile.path);
    try {
      db.execute('''
        PRAGMA journal_mode = OFF;
        PRAGMA synchronous = OFF;

        CREATE TABLE content_pack (
          pack_version INTEGER NOT NULL,
          schema_version INTEGER NOT NULL,
          checksum TEXT NOT NULL,
          built_at TEXT NOT NULL
        );
        CREATE TABLE chapters (
          id TEXT PRIMARY KEY,
          position INTEGER NOT NULL,
          title TEXT NOT NULL,
          subtitle TEXT NOT NULL,
          summary TEXT NOT NULL,
          cover_asset TEXT
        );
        CREATE TABLE lessons (
          id TEXT PRIMARY KEY,
          chapter_id TEXT NOT NULL REFERENCES chapters(id),
          position INTEGER NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL
        );
        CREATE TABLE exercises (
          id TEXT PRIMARY KEY,
          lesson_id TEXT NOT NULL REFERENCES lessons(id),
          position INTEGER NOT NULL,
          type TEXT NOT NULL,
          prompt_json TEXT NOT NULL,
          difficulty INTEGER NOT NULL
        );
        CREATE TABLE vocabulary_items (
          id TEXT PRIMARY KEY,
          word TEXT NOT NULL,
          pronunciation TEXT NOT NULL,
          meaning TEXT NOT NULL,
          etymology TEXT,
          audio_asset TEXT,
          example_verse_id TEXT,
          first_chapter_id TEXT NOT NULL REFERENCES chapters(id)
        );
        CREATE TABLE verses (
          id TEXT PRIMARY KEY,
          chapter_id TEXT NOT NULL REFERENCES chapters(id),
          position INTEGER NOT NULL,
          hemistich_1 TEXT NOT NULL,
          hemistich_2 TEXT NOT NULL,
          meaning TEXT NOT NULL,
          interpretation TEXT,
          audio_asset TEXT,
          source TEXT
        );
        CREATE TABLE verse_vocabulary (
          verse_id TEXT NOT NULL REFERENCES verses(id),
          vocabulary_item_id TEXT NOT NULL REFERENCES vocabulary_items(id),
          PRIMARY KEY (verse_id, vocabulary_item_id)
        );
        CREATE TABLE retellings (
          id TEXT PRIMARY KEY,
          chapter_id TEXT NOT NULL REFERENCES chapters(id),
          position INTEGER NOT NULL,
          body TEXT NOT NULL,
          illustration_asset TEXT
        );

        CREATE INDEX idx_lessons_chapter ON lessons(chapter_id, position);
        CREATE INDEX idx_exercises_lesson ON exercises(lesson_id, position);
        CREATE INDEX idx_verses_chapter ON verses(chapter_id, position);

        BEGIN;
      ''');
      for (final c in bundle.chapters) {
        db.execute(
          'INSERT INTO chapters VALUES (?, ?, ?, ?, ?, ?)',
          [c.id, c.position, c.title, c.subtitle, c.summary, c.coverAsset],
        );
        for (final l in c.lessons) {
          db.execute(
            'INSERT INTO lessons VALUES (?, ?, ?, ?, ?)',
            [l.id, c.id, l.position, l.type.name, l.title],
          );
          for (final e in l.exercises) {
            db.execute(
              'INSERT INTO exercises VALUES (?, ?, ?, ?, ?, ?)',
              [
                e.id,
                l.id,
                e.position,
                e.type.name,
                jsonEncode(e.prompt),
                e.difficulty,
              ],
            );
          }
        }
        for (final vi in c.vocab) {
          db.execute(
            'INSERT INTO vocabulary_items VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              vi.id,
              vi.word,
              vi.pronunciation,
              vi.meaning,
              vi.etymology,
              audioAssets[vi.id],
              vi.exampleVerseId,
              c.id,
            ],
          );
        }
        for (final v in c.verses) {
          db.execute(
            'INSERT INTO verses VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              v.id,
              c.id,
              v.position,
              v.hemistich1,
              v.hemistich2,
              v.meaning,
              v.interpretation,
              audioAssets[v.id],
              v.source,
            ],
          );
          for (final vocabId in v.vocabularyIds) {
            db.execute(
              'INSERT INTO verse_vocabulary VALUES (?, ?)',
              [v.id, vocabId],
            );
          }
        }
        for (final r in c.retellings) {
          db.execute(
            'INSERT INTO retellings VALUES (?, ?, ?, ?, ?)',
            [r.id, c.id, r.position, r.body, r.illustrationAsset],
          );
        }
      }

      db
        ..execute('INSERT INTO content_pack VALUES (?, ?, ?, ?)', [
          packVersion,
          contentSchemaVersion,
          _checksum(),
          DateTime.now().toUtc().toIso8601String(),
        ])
        ..execute('COMMIT');
    } finally {
      db.close();
    }
  }

  /// Deterministic digest over all content, so identical content always
  /// yields the same checksum regardless of build time or machine.
  String _checksum() {
    final canonical = StringBuffer();
    final chapters = [...bundle.chapters]..sort((a, b) => a.id.compareTo(b.id));
    for (final c in chapters) {
      canonical.write(
        '${c.id}|${c.position}|${c.title}|${c.subtitle}|${c.summary}',
      );
      for (final l in c.lessons) {
        canonical.write('${l.id}|${l.type.name}|${l.title}');
        for (final e in l.exercises) {
          canonical.write(
            '${e.id}|${e.type.name}|${jsonEncode(e.prompt)}|${e.difficulty}',
          );
        }
      }
      for (final vi in c.vocab) {
        canonical
          ..write('${vi.id}|${vi.word}|${vi.pronunciation}|')
          ..write('${vi.meaning}|${vi.etymology}');
      }
      for (final v in c.verses) {
        canonical
          ..write('${v.id}|${v.hemistich1}|${v.hemistich2}|')
          ..write('${v.meaning}|${v.interpretation}');
      }
      for (final r in c.retellings) {
        canonical.write('${r.id}|${r.body}');
      }
    }
    return sha256.convert(utf8.encode(canonical.toString())).toString();
  }
}
