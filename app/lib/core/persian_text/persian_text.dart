import 'package:intl/intl.dart';

/// Persian text and number utilities.
///
/// All user-facing numbers go through these helpers (DESIGN_SYSTEM.md §3);
/// raw `toString()` values must never reach the UI.
abstract final class PersianText {
  static const _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  static final _decimalFormat = NumberFormat.decimalPattern('fa');

  /// Replaces ASCII digits in [value] with Persian digits (۰–۹).
  ///
  /// Use for pre-formatted strings (times, verse references). For plain
  /// numbers prefer [number], which also applies Persian grouping separators.
  static String digits(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(_persianDigits[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Formats [value] with Persian digits and locale-correct grouping,
  /// e.g. `1234567` → «۱٬۲۳۴٬۵۶۷».
  static String number(num value) => _decimalFormat.format(value);
}
