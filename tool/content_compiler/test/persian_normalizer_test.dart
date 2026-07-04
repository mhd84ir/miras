import 'package:content_compiler/content_compiler.dart';
import 'package:test/test.dart';

void main() {
  group('normalizePersian', () {
    test('converts Arabic letter forms to Persian', () {
      expect(normalizePersian('علي'), 'علی');
      expect(normalizePersian('كتاب'), 'کتاب');
    });

    test('converts Arabic-Indic digits, leaves ASCII digits for validator', () {
      expect(normalizePersian('بخش ٣'), 'بخش ۳');
      expect(normalizePersian('بخش 3'), 'بخش 3');
    });

    test('normalizes heh+hamza to single code point', () {
      expect(
        normalizePersian('کاوهٔ آهنگر'.replaceAll(' ', ' ')),
        'کاوۀ آهنگر',
      );
    });

    test('preserves meaningful ZWNJ', () {
      expect(normalizePersian('داستان‌های شاهنامه'), 'داستان‌های شاهنامه');
      expect(normalizePersian('می‌رود'), 'می‌رود');
    });

    test('strips ZWNJ at edges and around spaces, collapses runs', () {
      expect(normalizePersian('‌آغاز‌'), 'آغاز');
      expect(normalizePersian('کتاب‌ ها'), 'کتاب ها');
      expect(normalizePersian('می‌‌رود'), 'می‌رود');
    });

    test('strips directional marks and zero-width space', () {
      expect(normalizePersian('سلام​‎‏ دنیا'), 'سلام دنیا');
    });

    test('collapses whitespace and trims', () {
      expect(normalizePersian('  به   نام  خداوند '), 'به نام خداوند');
    });
  });
}
