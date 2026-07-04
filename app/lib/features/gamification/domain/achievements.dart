import 'package:flutter/foundation.dart';

/// The static achievement catalog. IDs are persisted (docs/DATA_MODEL.md §2)
/// and must never be renamed; adding new achievements is always safe.
///
/// Titles/descriptions are Persian content, defined here rather than in ARB
/// because they are catalog data (like lesson content), not UI chrome.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

abstract final class Achievements {
  static const firstLesson = Achievement(
    id: 'first_lesson',
    title: 'نخستین گام',
    description: 'اولین درس را به پایان رساندی',
  );

  static const perfectLesson = Achievement(
    id: 'perfect_lesson',
    title: 'بی‌خطا',
    description: 'درسی را با دقت ۱۰۰٪ تمام کردی',
  );

  static const firstReview = Achievement(
    id: 'first_review',
    title: 'یادسپار',
    description: 'اولین جلسهٔ مرور را انجام دادی',
  );

  static const streak7 = Achievement(
    id: 'streak_7',
    title: 'هفت‌خوان',
    description: 'هفت روز پیاپی تمرین کردی',
  );

  static const streak30 = Achievement(
    id: 'streak_30',
    title: 'پیوستهٔ پولادین',
    description: 'سی روز پیاپی تمرین کردی',
  );

  static const vocab20 = Achievement(
    id: 'vocab_20',
    title: 'گنجینهٔ واژگان',
    description: 'بیست واژهٔ کهن آموختی',
  );

  static const chapterComplete = Achievement(
    id: 'chapter_complete',
    title: 'پایان داستان',
    description: 'همهٔ درس‌های یک فصل را کامل کردی',
  );

  static const List<Achievement> all = [
    firstLesson,
    perfectLesson,
    firstReview,
    streak7,
    streak30,
    vocab20,
    chapterComplete,
  ];
}
