import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test bootstrap: loads the real Persian fonts (so golden tests verify
/// actual glyph shaping, not the Ahem placeholder) and installs a slightly
/// tolerant golden comparator to absorb cross-platform anti-aliasing noise.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  _installTolerantGoldenComparator();
  await testMain();
}

Future<void> _loadFonts() async {
  const families = <String, List<String>>{
    'Vazirmatn': [
      'Vazirmatn-Regular.ttf',
      'Vazirmatn-Medium.ttf',
      'Vazirmatn-SemiBold.ttf',
      'Vazirmatn-Bold.ttf',
    ],
    'Estedad': ['Estedad-SemiBold.ttf', 'Estedad-Bold.ttf'],
    'Amiri': ['Amiri-Regular.ttf'],
    'NotoNaskhArabic': ['NotoNaskhArabic.ttf'],
  };

  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// Allows up to 0.5% pixel difference so goldens generated on macOS still pass
/// on Linux CI (font rasterization differs marginally between platforms).
/// Real layout/typography regressions differ by far more than this.
class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(super.testFile);

  static const _maxDiffRatio = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _maxDiffRatio) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

void _installTolerantGoldenComparator() {
  final previous = goldenFileComparator;
  if (previous is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenFileComparator(
      Uri.parse('${previous.basedir}config_test.dart'),
    );
  }
}
