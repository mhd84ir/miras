import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/persian_text/persian_text.dart';

void main() {
  group('PersianText.digits', () {
    test('converts ASCII digits to Persian digits', () {
      expect(PersianText.digits('12:34'), '۱۲:۳۴');
      expect(PersianText.digits('0123456789'), '۰۱۲۳۴۵۶۷۸۹');
    });

    test('leaves non-digit characters untouched, including ZWNJ', () {
      expect(PersianText.digits('داستان‌ها 2'), 'داستان‌ها ۲');
      expect(PersianText.digits('بیت ۳ از ۵'), 'بیت ۳ از ۵');
    });
  });

  group('PersianText.number', () {
    test('formats with Persian digits and grouping separators', () {
      expect(PersianText.number(0), '۰');
      expect(PersianText.number(42), '۴۲');
      // U+066C (Arabic thousands separator) is the fa-locale grouping mark.
      expect(PersianText.number(1234567), '۱٬۲۳۴٬۵۶۷');
    });
  });
}
