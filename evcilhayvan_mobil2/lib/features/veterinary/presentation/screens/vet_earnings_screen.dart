import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/vet_earnings_summary_model.dart';

final _vetEarningsProvider =
    FutureProvider.autoDispose<VetEarningsSummaryModel>((ref) {
      return ref.watch(appointmentRepositoryProvider).getVetEarningsSummary();
    });

class VetEarningsScreen extends ConsumerWidget {
  const VetEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_vetEarningsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.vetEarningsTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_vetEarningsProvider),
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
              l10n.vetEarningsLoadError(error.toString()),
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
            onRefresh: () async => ref.invalidate(_vetEarningsProvider),
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
                      l10n.vetEarningsThisMonth,
                      _currency(context, summary.thisMonthRevenue),
                      l10n.vetEarningsCompletedRevenue,
                      Icons.calendar_month_outlined,
                      const Color(0xFF2D6A4F),
                    ),
                    _metricCard(
                      context,
                      l10n.vetEarningsPendingRevenue,
                      _currency(context, summary.upcomingRevenue),
                      l10n.vetEarningsExpectedFromConfirmed,
                      Icons.trending_up_rounded,
                      const Color(0xFF1D3557),
                    ),
                    _metricCard(
                      context,
                      l10n.vetEarningsAverageExam,
                      _currency(context, summary.averageCompletedFee),
                      l10n.vetEarningsAverageCompleted,
                      Icons.payments_outlined,
                      Colors.orange.shade700,
                    ),
                    _metricCard(
                      context,
                      l10n.vetEarningsNoShow,
                      '${summary.noShowAppointments}',
                      l10n.vetEarningsNoShowCount,
                      Icons.person_off_outlined,
                      Colors.red.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.vetEarningsFeePolicy,
                  l10n.vetEarningsFeePolicyDesc,
                  Column(
                    children: [
                      _feeRow(
                        context,
                        l10n.vetEarningsClinicFee,
                        _currency(context, summary.clinicConsultationFee),
                      ),
                      const Divider(height: 22),
                      _feeRow(
                        context,
                        l10n.vetEarningsOnlineFee,
                        _currency(context, summary.onlineConsultationFee),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.vetEarningsLast14Days,
                  l10n.vetEarningsLast14DaysDesc,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: summary.dailyTrend.map((item) {
                      final height = item.revenue <= 0
                          ? 12.0
                          : 18 + (item.revenue / maxDailyRevenue) * 90;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              Text(
                                item.appointments > 0
                                    ? '${item.appointments}'
                                    : '',
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
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  l10n.vetEarningsMonthlyTrend,
                  l10n.vetEarningsMonthlyTrendDesc,
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
                  l10n.vetEarningsTypeBreakdown,
                  l10n.vetEarningsTypeBreakdownDesc,
                  summary.typeBreakdown.isEmpty
                      ? Text(
                          l10n.vetEarningsNoCompleted,
                          style: const TextStyle(color: Colors.grey),
                        )
                      : Column(
                          children: summary.typeBreakdown.map((item) {
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
                                          _appointmentTypeLabel(
                                            l10n,
                                            item.type,
                                            item.label,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          l10n.vetEarningsAppointmentCount(
                                            item.appointments,
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
                  l10n.vetEarningsRecentCompleted,
                  l10n.vetEarningsRecentCompletedDesc,
                  summary.recentCompleted.isEmpty
                      ? Text(
                          l10n.vetEarningsNoRecords,
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
                                      Icons.pets_outlined,
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
                                          item.petName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.ownerName} - ${_appointmentTypeLabel(l10n, item.type, item.type)}',
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
                                    _currency(context, item.feeAmount),
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

  Widget _hero(BuildContext context, VetEarningsSummaryModel summary) {
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
              _heroChip(
                l10n.vetEarningsTotalAppointments(summary.totalAppointments),
              ),
              _heroChip(
                l10n.vetEarningsConfirmedCount(summary.confirmedAppointments),
              ),
              _heroChip(
                l10n.vetEarningsCompletedCount(summary.completedAppointments),
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
            l10n.vetEarningsTotalCompletedRevenue(summary.vetName),
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

Widget _feeRow(BuildContext context, String label, String value) {
  return Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

String _appointmentTypeLabel(
  AppLocalizations l10n,
  String type,
  String fallback,
) {
  switch (type.toLowerCase()) {
    case 'online':
      return l10n.apptTypeOnline;
    case 'clinic':
      return l10n.apptTypeClinic;
    default:
      return fallback;
  }
}

String _currency(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.currency(
    locale: locale,
    symbol: locale.startsWith('tr') ? 'TL' : 'TRY',
    decimalDigits: 0,
  ).format(value);
}
