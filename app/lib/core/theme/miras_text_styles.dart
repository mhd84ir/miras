import 'package:flutter/material.dart';

/// Miras type scale (docs/DESIGN_SYSTEM.md §3).
///
/// Persian body text needs a taller line-height than Latin (≥1.6); the `height`
/// values below encode the scale's absolute line-heights.
abstract final class MirasTextStyles {
  static const uiFontFamily = 'Vazirmatn';
  static const displayFontFamily = 'Estedad';

  /// Verse face is under evaluation (M0 exit criterion, see the design-system
  /// gallery's couplet comparison). Placeholder until the decision is made.
  static const verseFontFamily = 'Vazirmatn';

  /// Chapter titles, celebrations.
  static const display = TextStyle(
    fontFamily: displayFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 40 / 28,
  );

  /// Screen titles.
  static const headline = TextStyle(
    fontFamily: displayFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 32 / 22,
  );

  /// Card titles, lesson names.
  static const title = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 28 / 18,
  );

  /// Default text.
  static const body = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 26 / 16,
  );

  /// Secondary text.
  static const bodySmall = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 22 / 14,
  );

  /// Labels, counters.
  static const caption = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 18 / 12,
  );

  /// بیت display — used by CoupletView.
  static const verse = TextStyle(
    fontFamily: verseFontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 20,
    height: 40 / 20,
  );

  /// Modern-Persian meaning shown under verses.
  static const verseMeaning = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 26 / 15,
  );

  /// Button labels.
  static const button = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
  );
}
