import 'package:bordeaux_elisabeth/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates between operations screens', (tester) async {
    await tester.pumpWidget(const BordeauxApp(screenshotMode: true));
    await tester.pumpAndSettle();

    expect(find.text('Operations board'), findsOneWidget);

    await tester.tap(find.text('Leads'));
    await tester.pumpAndSettle();
    expect(find.text('Lead management'), findsOneWidget);

    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();
    expect(find.text('Staff training'), findsOneWidget);

    await tester.tap(find.text('Visitors'));
    await tester.pumpAndSettle();
    expect(find.text('Visitor desk'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings and privacy'), findsOneWidget);
  });

  testWidgets('creates a local lead record in memory', (tester) async {
    await tester.pumpWidget(const BordeauxApp(screenshotMode: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leads'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-lead')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('lead-company')),
      'Bassin Logistics',
    );
    await tester.enterText(find.byKey(const Key('lead-owner')), 'Camille Roy');
    await tester.tap(find.byKey(const Key('save-record')));
    await tester.pumpAndSettle();

    expect(find.text('Bassin Logistics'), findsOneWidget);
    expect(find.textContaining('Camille Roy'), findsOneWidget);
  });
}
