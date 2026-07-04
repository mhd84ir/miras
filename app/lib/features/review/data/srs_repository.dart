import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/db/user_database.dart';
import 'package:miras/features/review/domain/srs_card.dart';

/// Persistence for FSRS cards (docs/DATA_MODEL.md §2, §5).
abstract interface class SrsRepository {
  /// Creates fresh, immediately-due cards for vocab not yet tracked.
  Future<void> ensureCards(List<String> vocabularyItemIds, DateTime now);

  Future<void> saveCard(SrsCard card);

  /// Due cards ordered by due time, capped at [limit].
  Future<List<SrsCard>> dueCards(DateTime now, {int limit = 20});

  Stream<int> watchDueCount(DateTime now);

  /// Number of words ever encountered (for profile stats).
  Future<int> trackedCount();
}

class DriftSrsRepository implements SrsRepository {
  DriftSrsRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final UserDatabase _db;
  final DateTime Function() _now;

  String get _ts => _now().toUtc().toIso8601String();

  @override
  Future<void> ensureCards(
    List<String> vocabularyItemIds,
    DateTime now,
  ) async {
    await _db.batch((batch) {
      for (final id in vocabularyItemIds) {
        final card = SrsCard.fresh(id, now);
        batch.insert(
          _db.srsCardRows,
          _companion(card),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  @override
  Future<void> saveCard(SrsCard card) async {
    await _db.into(_db.srsCardRows).insertOnConflictUpdate(_companion(card));
  }

  @override
  Future<List<SrsCard>> dueCards(DateTime now, {int limit = 20}) async {
    final rows =
        await (_db.select(_db.srsCardRows)
              ..where(
                (t) => t.dueAt.isSmallerOrEqualValue(
                  now.toUtc().toIso8601String(),
                ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
              ..limit(limit))
            .get();
    return rows.map(_from).toList();
  }

  @override
  Stream<int> watchDueCount(DateTime now) {
    final count = _db.srsCardRows.vocabularyItemId.count();
    final query = _db.selectOnly(_db.srsCardRows)
      ..addColumns([count])
      ..where(
        _db.srsCardRows.dueAt.isSmallerOrEqualValue(
          now.toUtc().toIso8601String(),
        ),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  @override
  Future<int> trackedCount() async {
    final count = _db.srsCardRows.vocabularyItemId.count();
    final query = _db.selectOnly(_db.srsCardRows)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  SrsCardRowsCompanion _companion(SrsCard card) => SrsCardRowsCompanion(
    vocabularyItemId: Value(card.vocabularyItemId),
    state: Value(card.state.name),
    stability: Value(card.stability),
    difficulty: Value(card.difficulty),
    dueAt: Value(card.dueAt.toUtc().toIso8601String()),
    lastReviewedAt: Value(
      card.lastReviewedAt?.toUtc().toIso8601String(),
    ),
    reps: Value(card.reps),
    lapses: Value(card.lapses),
    createdAt: Value(_ts),
    updatedAt: Value(_ts),
  );

  SrsCard _from(SrsCardRow r) => SrsCard(
    vocabularyItemId: r.vocabularyItemId,
    state: SrsState.values.byName(r.state),
    stability: r.stability,
    difficulty: r.difficulty,
    dueAt: DateTime.parse(r.dueAt),
    lastReviewedAt: r.lastReviewedAt == null
        ? null
        : DateTime.parse(r.lastReviewedAt!),
    reps: r.reps,
    lapses: r.lapses,
  );
}

/// Overridden with the Drift-backed implementation at bootstrap.
final srsRepositoryProvider = Provider<SrsRepository>(
  (ref) => throw UnimplementedError(
    'srsRepositoryProvider must be overridden at app bootstrap',
  ),
);
