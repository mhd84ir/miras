import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/app.dart';

void main() {
  testWidgets('home screen renders in Persian with RTL directionality', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MirasApp()));
    await tester.pumpAndSettle();

    final title = find.text('میراث');
    expect(title, findsOneWidget);
    expect(find.text('شروع یادگیری'), findsOneWidget);
    expect(find.text('به نام خداوند جان و خرد'), findsOneWidget);

    // The fa locale must flip the whole tree to RTL.
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);
  });
}
