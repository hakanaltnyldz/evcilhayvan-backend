import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/store/data/order_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

class SellerFinancialsScreen extends ConsumerWidget {
  const SellerFinancialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(sellerRevenueChartProvider);
    final statsAsync = ref.watch(sellerOrderStatsProvider);
    final productStatsAsync = ref.watch(sellerProductStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Finansal Rapor',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(sellerRevenueChartProvider);
              ref.invalidate(sellerOrderStatsProvider);
              ref.invalidate(sellerProductStatsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sellerRevenueChartProvider);
          ref.invalidate(sellerOrderStatsProvider);
          ref.invalidate(sellerProductStatsProvider);
          await Future.wait([
            ref.read(sellerRevenueChartProvider.future).catchError((_) => <RevenueChartPoint>[]),
            ref.read(sellerOrderStatsProvider.future).catchError((_) => null),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Revenue comparison cards ──────────────────────────────
            statsAsync.when(
              data: (stats) => _RevenueComparisonCard(stats: stats),
              loading: () => _cardSkeleton(120),
              error: (e, _) => _errorCard('İstatistikler yüklenemedi', () => ref.invalidate(sellerOrderStatsProvider)),
            ),
            const SizedBox(height: 16),

            // ── Revenue bar chart (6 months) ──────────────────────────
            _SectionTitle(title: 'Aylık Gelir (Son 6 Ay)', icon: Icons.bar_chart_outlined),
            const SizedBox(height: 8),
            chartAsync.when(
              data: (points) => _RevenueBarChart(points: points),
              loading: () => _cardSkeleton(200),
              error: (e, _) => _errorCard('Grafik yüklenemedi', () => ref.invalidate(sellerRevenueChartProvider)),
            ),
            const SizedBox(height: 24),

            // ── Top products ──────────────────────────────────────────
            _SectionTitle(title: 'En Çok Satan Ürünler', icon: Icons.star_outline),
            const SizedBox(height: 8),
            productStatsAsync.when(
              data: (data) {
                final topProducts = (data['topProducts'] as List<Map<String, dynamic>>?) ?? [];
                if (topProducts.isEmpty) {
                  return _emptyState('Henüz satış verisi yok');
                }
                return _TopProductsList(products: topProducts);
              },
              loading: () => _cardSkeleton(180),
              error: (e, _) => _errorCard('Ürün verileri yüklenemedi', () => ref.invalidate(sellerProductStatsProvider)),
            ),
            const SizedBox(height: 24),

            // ── Order status breakdown ────────────────────────────────
            _SectionTitle(title: 'Sipariş Durumu Dağılımı', icon: Icons.pie_chart_outline),
            const SizedBox(height: 8),
            productStatsAsync.when(
              data: (data) {
                final breakdown = data['orderStatusBreakdown'] as Map<String, dynamic>? ?? {};
                return _OrderStatusBreakdown(breakdown: breakdown);
              },
              loading: () => _cardSkeleton(160),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _cardSkeleton(double height) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: PawLoading()),
    );
  }

  Widget _errorCard(String msg, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.orange))),
          TextButton(onPressed: onRetry, child: const Text('Yenile')),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ),
    );
  }
}

// ─── Revenue Comparison Card ──────────────────────────────────────────────────

class _RevenueComparisonCard extends StatelessWidget {
  final OrderStats stats;
  const _RevenueComparisonCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final thisMonth = stats.revenueThisMonth;
    final lastMonth = 0.0; // backend doesn't track last month separately; show 0
    final diff = lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth * 100) : 0.0;
    final isUp = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPalette.primary, AppPalette.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Toplam Gelir', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${stats.totalRevenue.toStringAsFixed(2)} ₺',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Bu Ay',
                  value: '${thisMonth.toStringAsFixed(2)} ₺',
                  valueColor: Colors.white,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _MiniStat(
                  label: 'Geçen Ay',
                  value: '${lastMonth.toStringAsFixed(2)} ₺',
                  valueColor: Colors.white70,
                ),
              ),
              if (lastMonth > 0) ...[
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(
                  child: _MiniStat(
                    label: 'Değişim',
                    value: '${isUp ? '+' : ''}${diff.toStringAsFixed(1)}%',
                    valueColor: isUp ? const Color(0xFF6EF5C3) : const Color(0xFFFF8FA2),
                    icon: isUp ? Icons.trending_up : Icons.trending_down,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PillStat(label: '${stats.totalOrders} Sipariş'),
              const SizedBox(width: 8),
              _PillStat(label: '${stats.activeOrders} Aktif'),
              const SizedBox(width: 8),
              _PillStat(label: 'Ort. ${stats.averageOrderValue.toStringAsFixed(0)} ₺'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;
  const _MiniStat({required this.label, required this.value, required this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: valueColor, size: 14),
              Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  const _PillStat({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Revenue Bar Chart ────────────────────────────────────────────────────────

class _RevenueBarChart extends StatelessWidget {
  final List<RevenueChartPoint> points;
  const _RevenueBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Grafik verisi yok', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final maxRevenue = points.map((p) => p.revenue).fold(0.0, (a, b) => a > b ? a : b);
    final barGroups = points.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.revenue,
            gradient: LinearGradient(
              colors: [AppPalette.primary, AppPalette.primary.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxRevenue * 1.2,
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, _) {
                  if (value == 0) return const Text('');
                  final label = value >= 1000
                      ? '${(value / 1000).toStringAsFixed(1)}K'
                      : value.toStringAsFixed(0);
                  return Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      points[idx].shortLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final p = points[group.x];
                return BarTooltipItem(
                  '${p.shortLabel}\n${rod.toY.toStringAsFixed(0)} ₺\n${p.orders} sipariş',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top Products List ────────────────────────────────────────────────────────

class _TopProductsList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: products.asMap().entries.map((e) {
          final idx = e.key;
          final p = e.value;
          final name = p['name']?.toString() ?? 'Ürün';
          final soldCount = (p['soldCount'] as num?)?.toInt() ?? 0;
          final revenue = (p['revenue'] as num?)?.toDouble() ?? 0.0;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppPalette.primary.withOpacity(0.12),
              child: Text('${idx + 1}', style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('$soldCount adet satıldı', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Text(
              '${revenue.toStringAsFixed(0)} ₺',
              style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Order Status Breakdown ───────────────────────────────────────────────────

class _OrderStatusBreakdown extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _OrderStatusBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('Beklemede', breakdown['pending'] ?? 0, const Color(0xFFFFB86C)),
      ('Hazırlanıyor', breakdown['processing'] ?? 0, const Color(0xFF74B9FF)),
      ('Kargoda', breakdown['shipped'] ?? 0, const Color(0xFF6C5CE7)),
      ('Teslim', breakdown['delivered'] ?? 0, const Color(0xFF00B894)),
      ('İptal', breakdown['cancelled'] ?? 0, const Color(0xFFFF7675)),
    ];
    final total = statuses.fold<int>(0, (s, e) => s + (e.$2 as int));
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: statuses.map((s) {
          final count = s.$2 as int;
          final pct = count / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(s.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(s.$3),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s.$3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}
