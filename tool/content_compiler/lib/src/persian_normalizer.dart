/// Persian text normalization for authored content.
///
/// Normalization happens ONLY here at compile time — the app trusts pack text
/// byte-for-byte (docs/DATA_MODEL.md invariant 5).
library;

const zwnj = '‌';

/// Characters silently removed: zero-width space, BOM, directional marks
/// (authored content is pure Persian; bidi marks are copy-paste noise).
const _strippedChars = ['​', '﻿', '‎', '‏'];

/// Arabic → Persian letter forms.
const _letterMap = {
  'ي': 'ی', // ي → ی
  'ى': 'ی', // ى → ی
  'ك': 'ک', // ك → ک
};

/// Arabic-Indic digits (U+0660–0669) → Persian digits (U+06F0–06F9).
/// ASCII digits are intentionally NOT converted: they are flagged by the
/// validator instead, since they usually indicate an authoring mistake.
const _digitMap = {
  '٠': '۰',
  '١': '۱',
  '٢': '۲',
  '٣': '۳',
  '٤': '۴',
  '٥': '۵',
  '٦': '۶',
  '٧': '۷',
  '٨': '۸',
  '٩': '۹',
};

String normalizePersian(String input) {
  var text = input;

  for (final ch in _strippedChars) {
    text = text.replaceAll(ch, '');
  }
  _letterMap.forEach((from, to) => text = text.replaceAll(from, to));
  _digitMap.forEach((from, to) => text = text.replaceAll(from, to));

  // ه + combining hamza above → ۀ (single code point).
  text = text.replaceAll('هٔ', 'ۀ');

  // ZWNJ hygiene: collapse runs, and drop ZWNJ that touches whitespace or
  // string edges (it only means something between two joined letters).
  text = text
      .replaceAll(RegExp('$zwnj+'), zwnj)
      .replaceAll(RegExp('$zwnj(?=\\s)'), '')
      .replaceAll(RegExp('(?<=\\s)$zwnj'), '')
      .replaceAll(RegExp('^$zwnj|$zwnj\$'), '');

  // Whitespace hygiene: collapse internal runs, trim edges.
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

  return text;
}
