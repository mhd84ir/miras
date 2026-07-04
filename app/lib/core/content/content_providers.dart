import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/content/content_repository.dart';

/// Overridden with the real pack-backed repository during bootstrap
/// (see main.dart); tests override it with fakes.
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => throw UnimplementedError(
    'contentRepositoryProvider must be overridden at app bootstrap',
  ),
);
