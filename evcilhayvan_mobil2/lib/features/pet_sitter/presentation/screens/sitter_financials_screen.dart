import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
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
    final summaryAsync = ref.watch(_sitterFinancialsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kazanc Raporu'),
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
              'Finans raporu yuklenemedi: $error',
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
                      'Bu Ay',
                      _currency(summary.thisMonthRevenue),
                      'Aylik tahsil edilen gelir',
                      Icons.calendar_month_outlined,
                      const Color(0xFF2D6A4F),
                    ),
                    _metricCard(
                      context,
                      'Pipeline',
                      _currency(summary.pipelineRevenue),
                      'Aktif ve onayli islerden beklenen',
                      Icons.trending_up_rounded,
                      const Color(0xFF1D3557),
                    ),
                    _metricCard(
                      context,
                      'Duraklayan',
                      _currency(summary.pausedRevenue),
                      '${summary.pausedBookings} is odemesi durdu',
                      Icons.pause_circle_outline,
                      Colors.orange.shade700,
                    ),
                    _metricCard(
                      context,
                      'Tamamlanan',
                      '${summary.completedBookings}',
                      'Gelire donusen is sayisi',
                      Icons.task_alt_outlined,
                      Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Son 14 Gun',
                  'Gunluk kazanclari ve tamamlanan is adetlerini izleyin.',
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
                  'Aylik Trend',
                  'Son 6 aydaki gelir dagilimi.',
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
                  'Hizmet Bazli Gelir',
                  'Hangi hizmetin daha cok ciro ve hacim uretdigini gosterir.',
                  summary.serviceBreakdown.isEmpty
                      ? const Text(
                          'Henuz finansal hareket bulunmuyor.',
                          style: TextStyle(color: Colors.grey),
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
                                          item.serviceLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${item.bookings} is tamamlandi',
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
                  'Son Tahsilatlar',
                  'Yeni tamamlanan islerden olusan yakin gelir kayitlari.',
                  summary.recentCompleted.isEmpty
                      ? const Text(
                          'Tamamlanmis is kaydi yok.',
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
                                          item.serviceLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.petName} • ${item.ownerName}',
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
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context, SitterFinancialSummaryModel summary) {
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
              _heroChip('Toplam ${summary.totalBookings} rezervasyon'),
              _heroChip('${summary.pendingBookings} bekleyen talep'),
              _heroChip('${summary.activeBookings} aktif hizmet'),
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
          const Text(
            'Toplam tahsil edilen gelir',
            style: TextStyle(color: Colors.white70),
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

String _currency(double value) => NumberFormat.currency(
  locale: 'tr_TR',
  symbol: 'TL',
  decimalDigits: 0,
).format(value);
