// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dama/main.dart';
import 'package:dama/providers/game_provider.dart';

void main() {
  testWidgets('Dama app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: DamaApp(),
      ),
    );

    // Verify that our app shows the DAMA title
    expect(find.text('DAMA'), findsOneWidget);
    expect(find.text('Classic Checkers Game'), findsOneWidget);

    // Verify that game mode buttons are present
    expect(find.text('Play vs Human'), findsOneWidget);
    expect(find.text('Play vs AI'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
  });

  testWidgets('AI difficulty dialog test', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: DamaApp(),
      ),
    );

    // Tap the "Play vs AI" button
    await tester.tap(find.text('Play vs AI'));
    await tester.pumpAndSettle();

    // Verify that difficulty dialog appears
    expect(find.text('Choose AI Difficulty'), findsOneWidget);
    expect(find.text('🟢 Easy (2 moves ahead)'), findsOneWidget);
    expect(find.text('🟡 Medium (4 moves ahead)'), findsOneWidget);
    expect(find.text('🔴 Hard (6 moves ahead)'), findsOneWidget);
  });

  testWidgets('How to Play dialog test', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: DamaApp(),
      ),
    );

    // Tap the "How to Play" button
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();

    // Verify that rules dialog appears
    expect(find.text('How to Play Turkish Dama'), findsOneWidget);
    expect(find.text('Objective'), findsOneWidget);
    expect(find.text('Movement'), findsOneWidget);
    expect(find.text('Capturing'), findsOneWidget);
  });
}
