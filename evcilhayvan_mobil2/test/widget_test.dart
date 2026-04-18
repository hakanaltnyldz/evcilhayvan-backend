import 'package:evcilhayvan_mobil2/core/widgets/green_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GreenTile renders title and subtitle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GreenTile(
            icon: Icons.pets,
            title: 'Profil',
            subtitle: 'Hesap ayarlari',
          ),
        ),
      ),
    );

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Hesap ayarlari'), findsOneWidget);
    expect(find.byIcon(Icons.pets), findsOneWidget);
  });
}
