import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/sitter_financial_summary_model.dart';

final _sitterFinancialsProvider =
    FutureProvider.autoDispose<SitterFinancialSummaryModel>((ref) {
      return ref.watch(petSitterRepositoryProvider).getMyFinancialSummary();
    });

class SitterFinancialsScreen extends ConsumerWidget {
  const SitterFinancialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(_sitterFinancialsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.sitterFinanceTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_sitterFinancialsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.sitterFinanceLoadError(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (summary) {
          final maxDailyRevenue = summary.dailyTrend.fold<double>(
            1,
            (max, item) => item.revenue > max ? item.revenue : max,
          );

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_sitterFinancialsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _hero(context, summary),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricCard(
                      context,
                      l10n.sitterFinanceThisMonth,
                      _currency(context, summary.thisMonthRevenue),
                      l10n.sitterFinanceThisMonthSub,
                      Icons.calendar_month_outlined,
                      const Color(0xFF2D6A4F),
                    ),
                    _metricCard(
                      context,
                      l10n.sitterFinancePipeline,
                      _currency(context, summary.pipelineRevenue),
                      l10n.sitterFinancePipelineSub,
                      Icons.trending_up_rounded,
                      const Color(0xFF1D3557),
                    ),
                    _metricCard(
                      context,
                      l10n.sitterFinancePaused,
                      _currency(context, summary.pausedRevenue),
                      l10n.sitterFinancePausedSub(summary.pausedBookings),
                      Icons.pause_circle_outline,
                      Colors.orange.shade700,
                    ),
                    _metricCard(
                      context,
                      l10n.sitterFinanceCompleted,
                      '${summary.completedBookings}',
                      l10n.sitterFinanceCompletedSub,
                      Icons.task_alt_outlined,
                      Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.sitterFinanceLast14Days,
                  l10n.sitterFinanceLast14DaysDesc,
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: summary.dailyTrend.map((item) {
                          final height = item.revenue <= 0
                              ? 12.0
                              : 18 + (item.revenue / maxDailyRevenue) * 90;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    item.bookings > 0 ? '${item.bookings}' : '',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF52B788),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.sitterFinanceMonthlyTrend,
                  l10n.sitterFinanceMonthlyTrendDesc,
                  Column(
                    children: summary.monthlyTrend.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(width: 64, child: Text(item.label)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: summary.totalRevenue <= 0
                                      ? 0
                                      : item.revenue / summary.totalRevenue,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2D6A4F),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 92,
                              child: Text(
                                _currency(context, item.revenue),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.sitterFinanceServiceRevenue,
                  l10n.sitterFinanceServiceRevenueDesc,
                  summary.serviceBreakdown.isEmpty
                      ? Text(
                          l10n.sitterFinanceNoMovements,
                          style: const TextStyle(color: Colors.grey),
                        )
                      : Column(
                          children: summary.serviceBreakdown.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _serviceLabel(l10n, item.serviceType),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          l10n.sitterFinanceCompletedJobs(
                                            item.bookings,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currency(context, item.revenue),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.sitterFinanceRecentPayments,
                  l10n.sitterFinanceRecentPaymentsDesc,
                  summary.recentCompleted.isEmpty
                      ? Text(
                          l10n.sitterFinanceNoCompleted,
                          style: const TextStyle(color: Colors.grey),
                        )
                      : Column(
                          children: summary.recentCompleted.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.35),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFD8F3DC),
                                    child: Icon(
                                      Icons.payments_outlined,
                                      color: Color(0xFF2D6A4F),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _serviceLabel(l10n, item.serviceType),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_fallbackPetName(l10n, item.petName)} • ${_fallbackOwnerName(l10n, item.ownerName)}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (item.completedAt != null)
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                              Localizations.localeOf(
                                                context,
                                              ).toString(),
                                            ).format(
                                              item.completedAt!.toLocal(),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currency(context, item.revenue),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context, SitterFinancialSummaryModel summary) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(l10n.sitterFinanceTotalBookings(summary.totalBookings)),
              _heroChip(
                l10n.sitterFinancePendingRequests(summary.pendingBookings),
              ),
              _heroChip(
                l10n.sitterFinanceActiveServices(summary.activeBookings),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _currency(context, summary.totalRevenue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.sitterFinanceTotalRevenueLabel,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget _metricCard(
  BuildContext context,
  String title,
  String value,
  String subtitle,
  IconData icon,
  Color accent,
) {
  final width = (MediaQuery.of(context).size.width - 44) / 2;
  return Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

Widget _section(
  BuildContext context,
  String title,
  String subtitle,
  Widget child,
) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

String _currency(BuildContext context, double value) => NumberFormat.currency(
  locale: Localizations.localeOf(context).toString(),
  symbol: 'TL',
  decimalDigits: 0,
).format(value);

String _serviceLabel(AppLocalizations l10n, String serviceType) {
  switch (serviceType) {
    case 'walking':
      return l10n.sitterServiceWalkingLabel;
    case 'home_sitting':
      return l10n.sitterServiceHomeSittingLabel;
    case 'boarding':
      return l10n.sitterServiceBoardingLabel;
    case 'daycare':
      return l10n.sitterServiceDaycareLabel;
    case 'grooming':
      return l10n.sitterServiceGroomingLabel;
    default:
      return serviceType;
  }
}

String _fallbackPetName(AppLocalizations l10n, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty || trimmed == 'Pet' ? l10n.bookingsPetFallback : value;
}

String _fallbackOwnerName(AppLocalizations l10n, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty || trimmed == 'Musteri'
      ? l10n.bookingsCustomerLabel
      : value;
}
