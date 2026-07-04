import 'package:flutter_test/flutter_test.dart';

import 'package:miras/features/gamification/domain/xp_rules.dart';

void main() {
  test('lesson XP includes the perfect bonus only at 100%', () {
    expect(XpRules.forLesson(accuracy: 1), 15);
    expect(XpRules.forLesson(accuracy: 0.99), 10);
    expect(XpRules.forLesson(accuracy: 0), 10);
  });

  test('review XP includes the all-correct bonus', () {
    expect(XpRules.forReview(allCorrect: true), 10);
    expect(XpRules.forReview(allCorrect: false), 5);
  });
}
