import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3_lib;

part 'content_database.g.dart';

/// Drift schema mirroring the content pack (docs/DATA_MODEL.md §1).
/// The pack is produced by tool/content_compiler; the app NEVER writes to it.

class ChapterRows extends Table {
  @override
  String get tableName => 'chapters';

  TextColumn get id => text()();
  IntColumn get position => integer()();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  TextColumn get summary => text()();
  TextColumn get coverAsset => text().named('cover_asset').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LessonRows extends Table {
  @override
  String get tableName => 'lessons';

  TextColumn get id => text()();
  TextColumn get chapterId => text().named('chapter_id')();
  IntColumn get position => integer()();
  TextColumn get type => text()();
  TextColumn get title => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExerciseRows extends Table {
  @override
  String get tableName => 'exercises';

  TextColumn get id => text()();
  TextColumn get lessonId => text().named('lesson_id')();
  IntColumn get position => integer()();
  TextColumn get type => text()();
  TextColumn get promptJson => text().named('prompt_json')();
  IntColumn get difficulty => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VocabularyItemRows extends Table {
  @override
  String get tableName => 'vocabulary_items';

  TextColumn get id => text()();
  TextColumn get word => text()();
  TextColumn get pronunciation => text()();
  TextColumn get meaning => text()();
  TextColumn get etymology => text().nullable()();
  TextColumn get audioAsset => text().named('audio_asset').nullable()();
  TextColumn get exampleVerseId =>
      text().named('example_verse_id').nullable()();
  TextColumn get firstChapterId => text().named('first_chapter_id')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VerseRows extends Table {
  @override
  String get tableName => 'verses';

  TextColumn get id => text()();
  TextColumn get chapterId => text().named('chapter_id')();
  IntColumn get position => integer()();
  TextColumn get hemistich1 => text().named('hemistich_1')();
  TextColumn get hemistich2 => text().named('hemistich_2')();
  TextColumn get meaning => text()();
  TextColumn get interpretation => text().nullable()();
  TextColumn get audioAsset => text().named('audio_asset').nullable()();
  TextColumn get source => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VerseVocabularyRows extends Table {
  @override
  String get tableName => 'verse_vocabulary';

  TextColumn get verseId => text().named('verse_id')();
  TextColumn get vocabularyItemId => text().named('vocabulary_item_id')();

  @override
  Set<Column<Object>> get primaryKey => {verseId, vocabularyItemId};
}

class CreditRows extends Table {
  @override
  String get tableName => 'credits';

  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get url => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RetellingRows extends Table {
  @override
  String get tableName => 'retellings';

  TextColumn get id => text()();
  TextColumn get chapterId => text().named('chapter_id')();
  IntColumn get position => integer()();
  TextColumn get body => text()();
  TextColumn get illustrationAsset =>
      text().named('illustration_asset').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ChapterRows,
    LessonRows,
    ExerciseRows,
    VocabularyItemRows,
    VerseRows,
    VerseVocabularyRows,
    RetellingRows,
    CreditRows,
  ],
)
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.e);

  /// Opens an existing pack file read-only — any accidental write throws,
  /// enforcing the "app never writes to the content store" invariant.
  factory ContentDatabase.openPack(File packFile) {
    final db = sqlite3_lib.sqlite3.open(
      packFile.path,
      mode: sqlite3_lib.OpenMode.readOnly,
    );
    return ContentDatabase(NativeDatabase.opened(db));
  }

  // v2: credits table (narration attribution, ADR-0011).
  @override
  int get schemaVersion => 2;

  /// The pack ships with its schema already created (and `user_version` set
  /// by the compiler); the app must never attempt DDL on it.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {},
    onUpgrade: (_, _, _) async {},
  );
}
