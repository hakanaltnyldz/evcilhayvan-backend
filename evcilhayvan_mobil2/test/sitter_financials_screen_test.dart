import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/pet_sitter/data/repositories/pet_sitter_repository.dart';
import 'package:evcilhayvan_mobil2/features/pet_sitter/domain/models/sitter_financial_summary_model.dart';
import 'package:evcilhayvan_mobil2/features/pet_sitter/presentation/screens/sitter_financials_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePetSitterRepository extends PetSitterRepository {
  _FakePetSitterRepository(this.summary) : super(ApiClient());

  final SitterFinancialSummaryModel summary;

  @override
  Future<SitterFinancialSummaryModel> getMyFinancialSummary() async => summary;
}

void main() {
  testWidgets('Sitter financials screen shows summary cards and recent items', (
    WidgetTester tester,
  ) async {
    final summary = SitterFinancialSummaryModel(
      totalRevenue: 5400,
      thisMonthRevenue: 2200,
      pipelineRevenue: 900,
      pausedRevenue: 120,
      totalBookings: 14,
      pendingBookings: 2,
      acceptedBookings: 3,
      activeBookings: 1,
      completedBookings: 8,
      cancelledBookings: 1,
      pausedBookings: 1,
      dailyTrend: [
        SitterFinancePoint(key: 'd1', label: 'Pzt', revenue: 150, bookings: 1),
        SitterFinancePoint(key: 'd2', label: 'Sal', revenue: 250, bookings: 2),
      ],
      monthlyTrend: [
        SitterFinancePoint(key: 'm1', label: 'Nis', revenue: 2200, bookings: 8),
      ],
      serviceBreakdown: [
        SitterServiceBreakdown(
          serviceType: 'walking',
          serviceLabel: 'Gezdirme',
          revenue: 3000,
          bookings: 10,
        ),
      ],
      recentCompleted: [
        SitterRecentCompletedItem(
          id: 'done-1',
          serviceType: 'walking',
          serviceLabel: 'Gezdirme',
          revenue: 350,
          ownerName: 'Ayse',
          petName: 'Boncuk',
          completedAt: DateTime(2026, 4, 21),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petSitterRepositoryProvider.overrideWithValue(
            _FakePetSitterRepository(summary),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('tr', 'TR')],
          home: const SitterFinancialsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kazanc Raporu'), findsOneWidget);
    expect(find.text('Toplam 14 rezervasyon'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hizmet Bazli Gelir'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Hizmet Bazli Gelir'), findsOneWidget);
    expect(find.text('Gezdirme'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.textContaining('Boncuk'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Boncuk'), findsOneWidget);
    expect(find.textContaining('Ayse'), findsOneWidget);
  });
}
