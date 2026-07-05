@Tags(['tools'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/widgets/tazhib_rosette.dart';

/// One-shot generator for the launcher icon source PNGs
/// (assets/launcher/). Run explicitly with:
///   flutter test --tags tools test/tools/generate_launcher_icon_test.dart
/// then `dart run flutter_launcher_icons`. Excluded from normal runs.
void main() {
  testWidgets('generate launcher icon PNGs', (tester) async {
    Future<void> render(Widget widget, String path) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1024));
      await tester.pumpWidget(RepaintBoundary(child: widget));
      await tester.pumpAndSettle();

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    // Full legacy icon: rosette on lapis.
    await render(
      const ColoredBox(
        color: Color(0xFF26619C),
        child: Center(
          child: TazhibRosette(
            size: 720,
            color: Color(0xFFD9B44A),
            strokeWidth: 22,
          ),
        ),
      ),
      'assets/launcher/icon.png',
    );

    // Adaptive foreground: rosette on transparent, inside the ~66% safe zone.
    await render(
      const Center(
        child: TazhibRosette(
          size: 560,
          color: Color(0xFFD9B44A),
          strokeWidth: 22,
        ),
      ),
      'assets/launcher/icon_fg.png',
    );

    await tester.binding.setSurfaceSize(null);
    expect(File('assets/launcher/icon.png').existsSync(), isTrue);
  });
}
