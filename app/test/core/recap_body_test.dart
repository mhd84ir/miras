import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/notifications/recap_body.dart';

void main() {
  final strings = lookupAppLocalizations(const Locale('fa'));

  test('streak and due reviews compose the full recap', () {
    final body = recapBody(strings, streak: 3, due: 5);
    expect(body, strings.notificationBodyStreakDue('۳', '۵'));
  });

  test('streak alone mentions only the streak', () {
    final body = recapBody(strings, streak: 12, due: 0);
    expect(body, strings.notificationBodyStreak('۱۲'));
  });

  test('due reviews alone mention only the reviews', () {
    final body = recapBody(strings, streak: 0, due: 7);
    expect(body, strings.notificationBodyDue('۷'));
  });

  test('nothing concrete falls back to the generic reminder', () {
    expect(recapBody(strings, streak: 0, due: 0), strings.notificationBody);
  });

  test('no ASCII digits ever appear in a recap body', () {
    for (final (streak, due) in [(3, 5), (12, 0), (0, 7), (0, 0)]) {
      expect(
        recapBody(strings, streak: streak, due: due),
        isNot(matches(RegExp('[0-9]'))),
      );
    }
  });
}
