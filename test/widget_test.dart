import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storyteller/app.dart';

void main() {
  testWidgets('StoryTeller smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StoryTellerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
