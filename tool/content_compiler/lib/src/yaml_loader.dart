import 'dart:io';

import 'package:content_compiler/src/model/content.dart';
import 'package:content_compiler/src/persian_normalizer.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Loads authored YAML from a content directory into a [ContentBundle].
///
/// Structural problems (missing files, wrong types, absent required fields)
/// are collected as [ContentIssue] errors; affected items are skipped so a
/// single pass reports as many problems as possible.
class YamlLoader {
  YamlLoader(this.contentDir);

  final Directory contentDir;
  final issues = <ContentIssue>[];

  ContentBundle load() {
    final chaptersDir = Directory(p.join(contentDir.path, 'chapters'));
    if (!chaptersDir.existsSync()) {
      issues.add(
        ContentIssue.error('chapters/', '-', 'chapters directory not found'),
      );
      return ContentBundle(chapters: []);
    }

    final chapters = <ChapterContent>[];
    final dirs = chaptersDir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final dir in dirs) {
      final chapter = _loadChapter(dir);
      if (chapter != null) chapters.add(chapter);
    }
    return ContentBundle(chapters: chapters);
  }

  ChapterContent? _loadChapter(Directory dir) {
    final file = _rel(p.join(dir.path, 'chapter.yaml'));
    final root = _readMap(p.join(dir.path, 'chapter.yaml'));
    if (root == null) return null;

    final r = _Reader(file, 'chapter', root, issues);
    final id = r.string('id');
    final position = r.integer('position');
    final title = r.persian('title');
    final subtitle = r.persian('subtitle');
    final summary = r.persian('summary');
    if (id == null || position == null || title == null) return null;

    final vocab = _loadVocab(dir, id);
    final verses = _loadVerses(dir, id);
    final retellings = _loadRetelling(dir, id);

    final lessons = <Lesson>[];
    final lessonPaths = r.stringList('lessons') ?? const [];
    for (final (i, rel) in lessonPaths.indexed) {
      final lesson = _loadLesson(p.join(dir.path, rel), id, i);
      if (lesson != null) lessons.add(lesson);
    }

    return ChapterContent(
      id: id,
      position: position,
      title: title,
      subtitle: subtitle ?? '',
      summary: summary ?? '',
      coverAsset: r.optionalString('cover_asset'),
      lessons: lessons,
      vocab: vocab,
      verses: verses,
      retellings: retellings,
      sourceFile: file,
    );
  }

  List<VocabItem> _loadVocab(Directory dir, String chapterId) {
    final path = p.join(dir.path, 'vocab.yaml');
    final root = _readMap(path);
    if (root == null) return const [];
    final file = _rel(path);

    final items = <VocabItem>[];
    for (final (i, node) in _mapList(root, 'items', file).indexed) {
      final r = _Reader(file, 'items[$i]', node, issues);
      final id = r.string('id');
      final word = r.persian('word');
      final pronunciation = r.string('pronunciation');
      final meaning = r.persian('meaning');
      if (id == null ||
          word == null ||
          pronunciation == null ||
          meaning == null) {
        continue;
      }
      items.add(
        VocabItem(
          id: id,
          chapterId: chapterId,
          word: word,
          pronunciation: pronunciation,
          meaning: meaning,
          etymology: r.optionalPersian('etymology'),
          exampleVerseId: r.optionalString('example_verse'),
          ttsText: r.optionalPersian('tts_text'),
          sourceFile: file,
        ),
      );
    }
    return items;
  }

  List<Verse> _loadVerses(Directory dir, String chapterId) {
    final path = p.join(dir.path, 'verses.yaml');
    final root = _readMap(path);
    if (root == null) return const [];
    final file = _rel(path);

    final verses = <Verse>[];
    for (final (i, node) in _mapList(root, 'verses', file).indexed) {
      final r = _Reader(file, 'verses[$i]', node, issues);
      final id = r.string('id');
      final h1 = r.persian('hemistich1');
      final h2 = r.persian('hemistich2');
      final meaning = r.persian('meaning');
      if (id == null || h1 == null || h2 == null || meaning == null) continue;
      verses.add(
        Verse(
          id: id,
          chapterId: chapterId,
          position: i,
          hemistich1: h1,
          hemistich2: h2,
          meaning: meaning,
          interpretation: r.optionalPersian('interpretation'),
          vocabularyIds: r.stringList('vocabulary') ?? const [],
          source: r.optionalString('source'),
          sourceFile: file,
        ),
      );
    }
    return verses;
  }

  List<RetellingSection> _loadRetelling(Directory dir, String chapterId) {
    final path = p.join(dir.path, 'retelling.yaml');
    final root = _readMap(path);
    if (root == null) return const [];
    final file = _rel(path);

    final sections = <RetellingSection>[];
    for (final (i, node) in _mapList(root, 'sections', file).indexed) {
      final r = _Reader(file, 'sections[$i]', node, issues);
      final id = r.string('id');
      final body = r.persian('body');
      if (id == null || body == null) continue;
      sections.add(
        RetellingSection(
          id: id,
          chapterId: chapterId,
          position: i,
          body: body,
          illustrationAsset: r.optionalString('illustration_asset'),
          sourceFile: file,
        ),
      );
    }
    return sections;
  }

  Lesson? _loadLesson(String path, String chapterId, int position) {
    final root = _readMap(path);
    if (root == null) return null;
    final file = _rel(path);

    final r = _Reader(file, 'lesson', root, issues);
    final id = r.string('id');
    final typeName = r.string('type');
    final title = r.persian('title');
    if (id == null || typeName == null || title == null) return null;

    final type = LessonType.values.asNameMap()[typeName];
    if (type == null) {
      issues.add(
        ContentIssue.error(
          file,
          'type',
          'unknown lesson type "$typeName" — expected one of '
              '${LessonType.values.map((t) => t.name).join(', ')}',
        ),
      );
      return null;
    }

    final exercises = <Exercise>[];
    for (final (i, node) in _mapList(root, 'exercises', file).indexed) {
      final er = _Reader(file, 'exercises[$i]', node, issues);
      final eid = er.string('id');
      final etypeName = er.string('type');
      if (eid == null || etypeName == null) continue;
      final etype = ExerciseType.values.asNameMap()[etypeName];
      if (etype == null) {
        issues.add(
          ContentIssue.error(
            file,
            'exercises[$i].type',
            'unknown exercise type "$etypeName"',
          ),
        );
        continue;
      }
      final prompt = node['prompt'];
      if (prompt is! YamlMap) {
        issues.add(
          ContentIssue.error(
            file,
            'exercises[$i].prompt',
            'missing prompt map',
          ),
        );
        continue;
      }
      exercises.add(
        Exercise(
          id: eid,
          lessonId: id,
          position: i,
          type: etype,
          prompt: _normalizeJson(prompt)! as Map<String, Object?>,
          difficulty: er.optionalInteger('difficulty') ?? 1,
          sourceFile: file,
        ),
      );
    }

    return Lesson(
      id: id,
      chapterId: chapterId,
      position: position,
      type: type,
      title: title,
      exercises: exercises,
      sourceFile: file,
    );
  }

  /// Converts YAML nodes to plain JSON-compatible structures, normalizing all
  /// string values as Persian text.
  Object? _normalizeJson(Object? node) {
    return switch (node) {
      YamlMap() => {
        for (final e in node.entries) e.key.toString(): _normalizeJson(e.value),
      },
      YamlList() => [for (final v in node) _normalizeJson(v)],
      String() => normalizePersian(node),
      _ => node,
    };
  }

  List<YamlMap> _mapList(YamlMap root, String key, String file) {
    final node = root[key];
    if (node is! YamlList) {
      issues.add(ContentIssue.error(file, key, 'missing list "$key"'));
      return const [];
    }
    final maps = <YamlMap>[];
    for (final (i, item) in node.indexed) {
      if (item is YamlMap) {
        maps.add(item);
      } else {
        issues.add(
          ContentIssue.error(file, '$key[$i]', 'expected a mapping'),
        );
      }
    }
    return maps;
  }

  YamlMap? _readMap(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      issues.add(ContentIssue.error(_rel(path), '-', 'file not found'));
      return null;
    }
    final Object? doc;
    try {
      doc = loadYaml(file.readAsStringSync());
    } on YamlException catch (e) {
      issues.add(ContentIssue.error(_rel(path), '-', 'invalid YAML: $e'));
      return null;
    }
    if (doc is! YamlMap) {
      issues.add(
        ContentIssue.error(_rel(path), '-', 'expected a top-level mapping'),
      );
      return null;
    }
    return doc;
  }

  String _rel(String path) => p.relative(path, from: contentDir.path);
}

/// Typed field access over a [YamlMap] that records issues on failure.
class _Reader {
  _Reader(this.file, this.path, this.map, this.issues);

  final String file;
  final String path;
  final YamlMap map;
  final List<ContentIssue> issues;

  String? string(String key) {
    final v = map[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    issues.add(
      ContentIssue.error(file, '$path.$key', 'missing or empty string "$key"'),
    );
    return null;
  }

  /// Required Persian-text field: normalized on load.
  String? persian(String key) {
    final v = string(key);
    return v == null ? null : normalizePersian(v);
  }

  String? optionalString(String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is String && v.trim().isNotEmpty) return v.trim();
    issues.add(
      ContentIssue.error(
        file,
        '$path.$key',
        '"$key" must be a non-empty string',
      ),
    );
    return null;
  }

  String? optionalPersian(String key) {
    final v = optionalString(key);
    return v == null ? null : normalizePersian(v);
  }

  int? integer(String key) {
    final v = map[key];
    if (v is int) return v;
    issues.add(
      ContentIssue.error(file, '$path.$key', 'missing integer "$key"'),
    );
    return null;
  }

  int? optionalInteger(String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is int) return v;
    issues.add(
      ContentIssue.error(file, '$path.$key', '"$key" must be an integer'),
    );
    return null;
  }

  List<String>? stringList(String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is YamlList && v.every((e) => e is String)) {
      return v.cast<String>().toList();
    }
    issues.add(
      ContentIssue.error(
        file,
        '$path.$key',
        '"$key" must be a list of strings',
      ),
    );
    return null;
  }
}
