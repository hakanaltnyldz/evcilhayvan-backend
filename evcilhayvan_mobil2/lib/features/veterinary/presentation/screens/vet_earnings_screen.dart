import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Veteriner Kazanc Raporu'),
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
              'Kazanc raporu yuklenemedi: $error',
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
                      'Bu Ay',
                      _currency(summary.thisMonthRevenue),
                      'Tamamlanan randevu geliri',
                      Icons.calendar_month_outlined,
                      const Color(0xFF2D6A4F),
                    ),
                    _metricCard(
                      context,
                      'Bekleyen Gelir',
                      _currency(summary.upcomingRevenue),
                      'Onayli randevulardan beklenen',
                      Icons.trending_up_rounded,
                      const Color(0xFF1D3557),
                    ),
                    _metricCard(
                      context,
                      'Ort. Muayene',
                      _currency(summary.averageCompletedFee),
                      'Tamamlanan randevu ortalamasi',
                      Icons.payments_outlined,
                      Colors.orange.shade700,
                    ),
                    _metricCard(
                      context,
                      'No Show',
                      '${summary.noShowAppointments}',
                      'Gelmeyen hasta sayisi',
                      Icons.person_off_outlined,
                      Colors.red.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Ucret Politikasi',
                  'Klinik panelinden guncellenen mevcut randevu fiyatlari.',
                  Column(
                    children: [
                      _feeRow(
                        context,
                        'Klinik muayene ucreti',
                        _currency(summary.clinicConsultationFee),
                      ),
                      const Divider(height: 22),
                      _feeRow(
                        context,
                        'Online gorusme ucreti',
                        _currency(summary.onlineConsultationFee),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Son 14 Gun',
                  'Gunluk bazda kapanan randevu sayisi ve ciro.',
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
                  'Aylik Trend',
                  'Son 6 aydaki tamamlanan randevu gelirleri.',
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
                                _currency(item.revenue),
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
                  'Randevu Tipi Dagilimi',
                  'Klinik ve online gorusmelerin ciro katkisi.',
                  summary.typeBreakdown.isEmpty
                      ? const Text(
                          'Henuz tamamlanan randevu bulunmuyor.',
                          style: TextStyle(color: Colors.grey),
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
                                          item.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${item.appointments} randevu',
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
                                    _currency(item.revenue),
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
                  'Son Tamamlananlar',
                  'En son kapanan randevulardan gelir akisi.',
                  summary.recentCompleted.isEmpty
                      ? const Text(
                          'Kayit bulunmuyor.',
                          style: TextStyle(color: Colors.grey),
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
                                          '${item.ownerName} • ${item.type == 'online' ? 'Online' : 'Klinik'}',
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
                                              'tr_TR',
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
                                    _currency(item.feeAmount),
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
              _heroChip('Toplam ${summary.totalAppointments} randevu'),
              _heroChip('${summary.confirmedAppointments} onayli'),
              _heroChip('${summary.completedAppointments} tamamlandi'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _currency(summary.totalRevenue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.vetName} icin toplam tamamlanan gelir',
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

String _currency(double value) => NumberFormat.currency(
  locale: 'tr_TR',
  symbol: 'TL',
  decimalDigits: 0,
).format(value);
