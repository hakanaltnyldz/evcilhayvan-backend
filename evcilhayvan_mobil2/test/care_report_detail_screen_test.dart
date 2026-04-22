import 'package:evcilhayvan_mobil2/features/pet_sitter/domain/models/care_report_model.dart';
import 'package:evcilhayvan_mobil2/features/pet_sitter/domain/models/sitter_booking_model.dart';
import 'package:evcilhayvan_mobil2/features/pet_sitter/presentation/screens/care_report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Care report detail renders booking summary and notes', (
    WidgetTester tester,
  ) async {
    final booking = SitterBookingModel(
      id: 'booking-1',
      petName: 'Boncuk',
      serviceType: 'walking',
      startDate: DateTime(2026, 4, 22, 10),
      endDate: DateTime(2026, 4, 22, 11),
      status: 'completed',
    );

    final report = CareReportModel(
      id: 'report-1',
      bookingId: 'booking-1',
      day: 1,
      mood: 'great',
      notes: 'Parkta enerjisi cok iyiydi.',
      activities: const ['walk', 'play'],
      timestamp: DateTime(2026, 4, 22, 10, 30),
      sharedWithOwnerAt: DateTime(2026, 4, 22, 10, 45),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('tr', 'TR')],
        home: CareReportDetailScreen(booking: booking, report: report),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1. Gun Raporu'), findsAtLeastNWidgets(1));
    expect(find.text('Boncuk'), findsOneWidget);
    expect(find.text('Musteriye gonderildi'), findsOneWidget);
    expect(find.text('Parkta enerjisi cok iyiydi.'), findsOneWidget);
    expect(find.text('Yemek yedi'), findsOneWidget);
    expect(find.text('Yuruyus'), findsOneWidget);
    expect(find.text('Oyun'), findsOneWidget);
  });
}
