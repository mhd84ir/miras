import 'package:content_compiler/src/model/content.dart';

/// Validates a loaded [ContentBundle]: ID formats and uniqueness, reference
/// integrity, per-exercise-type prompt schemas, and Persian text hygiene.
///
/// Content IDs are stable and human-readable (docs/DATA_MODEL.md): renaming
/// a published ID is forbidden, so getting them right here matters.
class Validator {
  Validator(this.bundle);

  final ContentBundle bundle;
  final issues = <ContentIssue>[];

  static final _chapterId = RegExp(r'^[a-z][a-z0-9_]*$');
  static final _vocabId = RegExp(r'^vocab\.[a-z][a-z0-9_]*$');
  static final _asciiDigits = RegExp('[0-9]');
  static final _latinLetters = RegExp('[a-zA-Z]');

  List<ContentIssue> validate() {
    _checkIds();
    _checkReferences();
    _checkExercisePrompts();
    _checkPersianText();
    return issues;
  }

  // ---------------------------------------------------------------- IDs

  void _checkIds() {
    final seen = <String, String>{}; // id -> file
    void unique(String id, String file, String path) {
      final prior = seen[id];
      if (prior != null) {
        issues.add(
          ContentIssue.error(file, path, 'duplicate id "$id" (also in $prior)'),
        );
      } else {
        seen[id] = file;
      }
    }

    final positions = <int, String>{};
    for (final c in bundle.chapters) {
      if (!_chapterId.hasMatch(c.id)) {
        issues.add(
          ContentIssue.error(
            c.sourceFile,
            'id',
            'chapter id "${c.id}" must match ${_chapterId.pattern}',
          ),
        );
      }
      unique(c.id, c.sourceFile, 'id');
      final prior = positions[c.position];
      if (prior != null) {
        issues.add(
          ContentIssue.error(
            c.sourceFile,
            'position',
            'position ${c.position} already used by chapter "$prior"',
          ),
        );
      }
      positions[c.position] = c.id;

      if (c.lessons.isEmpty) {
        issues.add(
          ContentIssue.error(c.sourceFile, 'lessons', 'chapter has no lessons'),
        );
      }

      for (final l in c.lessons) {
        final expected = RegExp('^${RegExp.escape(c.id)}\\.l\\d{2}\$');
        if (!expected.hasMatch(l.id)) {
          issues.add(
            ContentIssue.error(
              l.sourceFile,
              'id',
              'lesson id "${l.id}" must match "${c.id}.lNN"',
            ),
          );
        }
        unique(l.id, l.sourceFile, 'id');
        if (l.exercises.isEmpty) {
          issues.add(
            ContentIssue.error(
              l.sourceFile,
              'exercises',
              'lesson has no exercises',
            ),
          );
        }
        for (final e in l.exercises) {
          final expectedE = RegExp('^${RegExp.escape(l.id)}\\.e\\d{2}\$');
          if (!expectedE.hasMatch(e.id)) {
            issues.add(
              ContentIssue.error(
                e.sourceFile,
                'exercises[${e.position}].id',
                'exercise id "${e.id}" must match "${l.id}.eNN"',
              ),
            );
          }
          unique(e.id, e.sourceFile, 'exercises[${e.position}].id');
          if (e.difficulty < 1 || e.difficulty > 3) {
            issues.add(
              ContentIssue.error(
                e.sourceFile,
                'exercises[${e.position}].difficulty',
                'difficulty must be 1–3',
              ),
            );
          }
        }
      }

      for (final v in c.verses) {
        final expected = RegExp('^${RegExp.escape(c.id)}\\.v\\d{3}\$');
        if (!expected.hasMatch(v.id)) {
          issues.add(
            ContentIssue.error(
              v.sourceFile,
              'verses[${v.position}].id',
              'verse id "${v.id}" must match "${c.id}.vNNN"',
            ),
          );
        }
        unique(v.id, v.sourceFile, 'verses[${v.position}].id');
      }

      for (final vi in c.vocab) {
        if (!_vocabId.hasMatch(vi.id)) {
          issues.add(
            ContentIssue.error(
              vi.sourceFile,
              'items.id',
              'vocab id "${vi.id}" must match ${_vocabId.pattern}',
            ),
          );
        }
        unique(vi.id, vi.sourceFile, 'items.id');
      }

      for (final r in c.retellings) {
        final expected = RegExp('^${RegExp.escape(c.id)}\\.r\\d{2}\$');
        if (!expected.hasMatch(r.id)) {
          issues.add(
            ContentIssue.error(
              r.sourceFile,
              'sections[${r.position}].id',
              'retelling id "${r.id}" must match "${c.id}.rNN"',
            ),
          );
        }
        unique(r.id, r.sourceFile, 'sections[${r.position}].id');
      }
    }
  }

  // --------------------------------------------------------- references

  late final Set<String> _verseIds = bundle.allVerses.map((v) => v.id).toSet();
  late final Set<String> _vocabIds = bundle.allVocab.map((v) => v.id).toSet();
  late final Set<String> _retellingIds = bundle.allRetellings
      .map((r) => r.id)
      .toSet();

  void _checkReferences() {
    for (final vi in bundle.allVocab) {
      final ref = vi.exampleVerseId;
      if (ref != null && !_verseIds.contains(ref)) {
        issues.add(
          ContentIssue.error(
            vi.sourceFile,
            '${vi.id}.example_verse',
            'unknown verse "$ref"',
          ),
        );
      }
    }
    for (final v in bundle.allVerses) {
      for (final ref in v.vocabularyIds) {
        if (!_vocabIds.contains(ref)) {
          issues.add(
            ContentIssue.error(
              v.sourceFile,
              '${v.id}.vocabulary',
              'unknown vocab "$ref"',
            ),
          );
        }
      }
    }
  }

  // ------------------------------------------------------------ prompts

  void _checkExercisePrompts() {
    for (final e in bundle.allExercises) {
      final where = '${e.id}.prompt';
      void err(String msg) =>
          issues.add(ContentIssue.error(e.sourceFile, where, msg));

      switch (e.type) {
        case ExerciseType.vocabIntro:
          _requireRef(e, 'vocabId', _vocabIds, 'vocab');
        case ExerciseType.verseIntro:
          _requireRef(e, 'verseId', _verseIds, 'verse');
        case ExerciseType.storySection:
          _requireRef(e, 'retellingId', _retellingIds, 'retelling section');
        case ExerciseType.matching:
          final pairs = _stringList(e, 'pairs');
          if (pairs == null) break;
          if (pairs.length < 2 || pairs.length > 6) {
            err('matching needs 2–6 pairs, got ${pairs.length}');
          }
          if (pairs.toSet().length != pairs.length) {
            err('matching pairs contain duplicates');
          }
          for (final id in pairs) {
            if (!_vocabIds.contains(id)) err('unknown vocab "$id" in pairs');
          }
        case ExerciseType.multipleChoice:
        case ExerciseType.comprehension:
          _requireString(e, 'question');
          _checkOptions(e);
          final vocabRef = e.prompt['vocabId'];
          if (vocabRef is String && !_vocabIds.contains(vocabRef)) {
            err('unknown vocab "$vocabRef"');
          }
        case ExerciseType.cloze:
          final verse = _requireRef(e, 'verseId', _verseIds, 'verse');
          final hemistich = _requireHemistich(e);
          final blank = e.prompt['blankToken'];
          final options = _checkOptions(e);
          if (verse == null || hemistich == null || blank is! int) {
            if (blank is! int) err('missing integer "blankToken"');
            break;
          }
          final v = bundle.allVerses.firstWhere((x) => x.id == verse);
          final tokens = (hemistich == 1 ? v.hemistich1 : v.hemistich2).split(
            ' ',
          );
          if (blank < 0 || blank >= tokens.length) {
            err(
              'blankToken $blank out of range '
              '(hemistich has ${tokens.length} tokens)',
            );
          } else if (options != null) {
            final correctIndex = e.prompt['correctIndex']! as int;
            if (options[correctIndex] != tokens[blank]) {
              err(
                'options[correctIndex] "${options[correctIndex]}" does not '
                'equal the blanked token "${tokens[blank]}"',
              );
            }
          }
        case ExerciseType.listening:
          _requireRef(e, 'vocabId', _vocabIds, 'vocab');
          _checkOptions(e);
        case ExerciseType.hemistichAssembly:
          _requireRef(e, 'verseId', _verseIds, 'verse');
          _requireHemistich(e);
          final distractors = e.prompt['distractors'];
          if (distractors != null &&
              (distractors is! List || distractors.any((d) => d is! String))) {
            err('"distractors" must be a list of strings');
          }
        case ExerciseType.sequencing:
          final events = e.prompt['events'];
          final order = _stringList(e, 'correctOrder');
          if (events is! List || events.any((x) => x is! Map)) {
            err('missing "events" list of {id, text}');
            break;
          }
          final ids = <String>[];
          for (final ev in events.cast<Map<Object?, Object?>>()) {
            final id = ev['id'];
            final text = ev['text'];
            if (id is! String || text is! String || text.isEmpty) {
              err('each event needs string "id" and non-empty "text"');
            } else {
              ids.add(id);
            }
          }
          if (events.length < 3 || events.length > 6) {
            err('sequencing needs 3–6 events, got ${events.length}');
          }
          if (order == null) break;
          if (ids.toSet().length != ids.length) err('duplicate event ids');
          if (order.length != ids.length ||
              order.toSet().difference(ids.toSet()).isNotEmpty ||
              ids.toSet().difference(order.toSet()).isNotEmpty) {
            err('"correctOrder" must be a permutation of event ids');
          }
      }
    }
  }

  String? _requireRef(Exercise e, String key, Set<String> known, String kind) {
    final v = e.prompt[key];
    if (v is! String || v.isEmpty) {
      issues.add(
        ContentIssue.error(e.sourceFile, '${e.id}.prompt', 'missing "$key"'),
      );
      return null;
    }
    if (!known.contains(v)) {
      issues.add(
        ContentIssue.error(
          e.sourceFile,
          '${e.id}.prompt',
          'unknown $kind "$v"',
        ),
      );
      return null;
    }
    return v;
  }

  void _requireString(Exercise e, String key) {
    final v = e.prompt[key];
    if (v is! String || v.isEmpty) {
      issues.add(
        ContentIssue.error(e.sourceFile, '${e.id}.prompt', 'missing "$key"'),
      );
    }
  }

  int? _requireHemistich(Exercise e) {
    final v = e.prompt['hemistich'];
    if (v is int && (v == 1 || v == 2)) return v;
    issues.add(
      ContentIssue.error(
        e.sourceFile,
        '${e.id}.prompt',
        '"hemistich" must be 1 or 2',
      ),
    );
    return null;
  }

  List<String>? _stringList(Exercise e, String key) {
    final v = e.prompt[key];
    if (v is List && v.every((x) => x is String)) return v.cast<String>();
    issues.add(
      ContentIssue.error(
        e.sourceFile,
        '${e.id}.prompt',
        'missing string list "$key"',
      ),
    );
    return null;
  }

  List<String>? _checkOptions(Exercise e) {
    final options = _stringList(e, 'options');
    if (options == null) return null;
    void err(String msg) =>
        issues.add(ContentIssue.error(e.sourceFile, '${e.id}.prompt', msg));
    if (options.length < 2 || options.length > 5) {
      err('needs 2–5 options, got ${options.length}');
    }
    if (options.toSet().length != options.length) {
      err('options contain duplicates');
    }
    final idx = e.prompt['correctIndex'];
    if (idx is! int || idx < 0 || idx >= options.length) {
      err('"correctIndex" must be an integer within options range');
      return null;
    }
    return options;
  }

  // -------------------------------------------------------- text hygiene

  void _checkPersianText() {
    void check(String file, String path, String text) {
      if (_asciiDigits.hasMatch(text)) {
        issues.add(
          ContentIssue.error(
            file,
            path,
            'ASCII digits in Persian text — use Persian digits (۰–۹): "$text"',
          ),
        );
      }
      if (_latinLetters.hasMatch(text)) {
        issues.add(
          ContentIssue.warning(
            file,
            path,
            'Latin letters in Persian text: "$text"',
          ),
        );
      }
    }

    for (final c in bundle.chapters) {
      check(c.sourceFile, 'title', c.title);
      check(c.sourceFile, 'summary', c.summary);
      for (final v in c.verses) {
        check(v.sourceFile, '${v.id}.hemistich1', v.hemistich1);
        check(v.sourceFile, '${v.id}.hemistich2', v.hemistich2);
        check(v.sourceFile, '${v.id}.meaning', v.meaning);
      }
      for (final vi in c.vocab) {
        check(vi.sourceFile, '${vi.id}.word', vi.word);
        check(vi.sourceFile, '${vi.id}.meaning', vi.meaning);
      }
      for (final r in c.retellings) {
        check(r.sourceFile, '${r.id}.body', r.body);
      }
    }
  }
}
