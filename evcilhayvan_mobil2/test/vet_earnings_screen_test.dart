import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/veterinary/data/repositories/appointment_repository.dart';
import 'package:evcilhayvan_mobil2/features/veterinary/domain/models/vet_earnings_summary_model.dart';
import 'package:evcilhayvan_mobil2/features/veterinary/presentation/screens/vet_earnings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppointmentRepository extends AppointmentRepository {
  _FakeAppointmentRepository(this.summary) : super(ApiClient());

  final VetEarningsSummaryModel summary;

  @override
  Future<VetEarningsSummaryModel> getVetEarningsSummary() async => summary;
}

void main() {
  testWidgets('Vet earnings screen shows fees and recent appointments', (
    WidgetTester tester,
  ) async {
    final summary = VetEarningsSummaryModel(
      vetId: 'vet-1',
      vetName: 'Mutlu Pati Klinigi',
      totalRevenue: 7800,
      thisMonthRevenue: 3200,
      upcomingRevenue: 1100,
      averageCompletedFee: 400,
      totalAppointments: 24,
      pendingAppointments: 2,
      confirmedAppointments: 5,
      completedAppointments: 15,
      cancelledAppointments: 1,
      noShowAppointments: 1,
      clinicConsultationFee: 600,
      onlineConsultationFee: 350,
      dailyTrend: [
        VetEarningsPoint(
          key: 'd1',
          label: 'Pzt',
          revenue: 300,
          appointments: 1,
        ),
        VetEarningsPoint(
          key: 'd2',
          label: 'Sal',
          revenue: 500,
          appointments: 2,
        ),
      ],
      monthlyTrend: [
        VetEarningsPoint(
          key: 'm1',
          label: 'Nis',
          revenue: 3200,
          appointments: 8,
        ),
      ],
      typeBreakdown: [
        VetEarningsBreakdownItem(
          type: 'clinic',
          label: 'Klinik',
          revenue: 6200,
          appointments: 12,
        ),
      ],
      recentCompleted: [
        VetRecentCompletedItem(
          id: 'appt-1',
          petName: 'Mars',
          ownerName: 'Hakan',
          type: 'clinic',
          feeAmount: 450,
          completedAt: DateTime(2026, 4, 20),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(
            _FakeAppointmentRepository(summary),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('tr', 'TR')],
          home: const VetEarningsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Veteriner Kazanc Raporu'), findsOneWidget);
    expect(find.text('Toplam 24 randevu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ucret Politikasi'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Ucret Politikasi'), findsOneWidget);
    expect(find.text('Klinik muayene ucreti'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Randevu Tipi Dagilimi'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Randevu Tipi Dagilimi'), findsOneWidget);
    expect(find.text('Klinik'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Mars'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Mars'), findsOneWidget);
    expect(find.textContaining('Hakan'), findsOneWidget);
  });
}
