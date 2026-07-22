import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hk_life_simulator/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HKLifeSimulatorApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
