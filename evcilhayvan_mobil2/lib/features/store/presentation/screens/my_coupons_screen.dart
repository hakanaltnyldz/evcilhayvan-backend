// lib/features/store/presentation/screens/my_coupons_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final availableCouponsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final dio = ApiClient().dio;
      final res = await dio.get('/api/coupons/available');
      return List<Map<String, dynamic>>.from(res.data['coupons'] ?? []);
    });

final couponUsageHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final dio = ApiClient().dio;
      final res = await dio.get('/api/coupon-usage/my');
      return List<Map<String, dynamic>>.from(res.data['usages'] ?? []);
    });

// ── Screen ─────────────────────────────────────────────────────────────────

class MyCouponsScreen extends ConsumerStatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  ConsumerState<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends ConsumerState<MyCouponsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyCoupon(String code) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.couponsCopied(code)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat(
      'dd.MM.yyyy',
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.couponsMyCouponsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.couponsAvailableTab),
            Tab(text: l10n.couponsHistoryTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableTab(dateFmt: dateFmt, onCopy: _copyCoupon),
          _UsageHistoryTab(dateFmt: dateFmt),
        ],
      ),
    );
  }
}

// ── Available Coupons Tab ───────────────────────────────────────────────────

class _AvailableTab extends ConsumerWidget {
  final DateFormat dateFmt;
  final void Function(String) onCopy;
  const _AvailableTab({required this.dateFmt, required this.onCopy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(availableCouponsProvider);
    return couponsAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) {
        final l10n = AppLocalizations.of(context)!;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                l10n.couponsLoadError,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => ref.invalidate(availableCouponsProvider),
                child: Text(l10n.couponsRetry),
              ),
            ],
          ),
        );
      },
      data: (coupons) {
        final l10n = AppLocalizations.of(context)!;
        if (coupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 64,
                  color: AppPalette.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(l10n.couponsEmptyTitle),
                const SizedBox(height: 8),
                Text(
                  l10n.couponsEmptySubtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(availableCouponsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: coupons.length,
            itemBuilder: (_, i) => _CouponCard(
              coupon: coupons[i],
              dateFmt: dateFmt,
              onCopy: onCopy,
            ),
          ),
        );
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final DateFormat dateFmt;
  final void Function(String) onCopy;
  const _CouponCard({
    required this.coupon,
    required this.dateFmt,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isPercent = coupon['discountType'] == 'percentage';
    final value = coupon['discountValue'];
    final label = isPercent ? '%$value İndirim' : '₺$value İndirim';
    final code = coupon['code'] as String? ?? '';
    final remaining = coupon['remainingUses'] ?? 1;
    final validUntil = coupon['validUntil'] != null
        ? dateFmt.format(
            DateTime.tryParse(coupon['validUntil']) ?? DateTime.now(),
          )
        : '—';
    final minPurchase = coupon['minPurchaseAmount'] ?? 0;
    final maxDiscount = coupon['maxDiscountAmount'];
    final firstOrderOnly = coupon['firstOrderOnly'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppPalette.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top section — discount info
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isPercent
                          ? const Color(0xFF2D6A4F)
                          : const Color(0xFFFF7A59))
                      .withOpacity(0.12),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPercent
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFFFF7A59),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (firstOrderOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'İlk Sipariş',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '$remaining kullanım hakkı',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Middle — code + copy
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coupon['description'] != null)
                        Text(
                          coupon['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppPalette.primary.withOpacity(0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Text(
                              code,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppPalette.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => onCopy(code),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            color: AppPalette.primary,
                            tooltip: 'Kopyala',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom — conditions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: AppLocalizations.of(
                    context,
                  )!.couponsValidUntil(validUntil),
                ),
                if (minPurchase > 0) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Min. ₺$minPurchase',
                  ),
                ],
                if (maxDiscount != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.arrow_downward,
                    label: 'Maks. ₺$maxDiscount',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── Usage History Tab ───────────────────────────────────────────────────────

class _UsageHistoryTab extends ConsumerWidget {
  final DateFormat dateFmt;
  const _UsageHistoryTab({required this.dateFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(couponUsageHistoryProvider);
    return usageAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Geçmiş yüklenemedi'),
            TextButton(
              onPressed: () => ref.invalidate(couponUsageHistoryProvider),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (usages) {
        if (usages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 64,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                const Text('Henüz kupon kullanmadınız'),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(couponUsageHistoryProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: usages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = usages[i];
              final coupon = u['couponId'] as Map?;
              final order = u['orderId'] as Map?;
              final discount = u['discountAmount'] ?? 0;
              final original = u['originalAmount'] ?? 0;
              final final_ = u['finalAmount'] ?? 0;
              final date = u['createdAt'] != null
                  ? dateFmt.format(
                      DateTime.tryParse(u['createdAt']) ?? DateTime.now(),
                    )
                  : '—';
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    coupon?['code'] ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₺${original.toString()} → ₺${final_.toString()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (order?['status'] != null)
                        Text(
                          'Sipariş: ${order!['status']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-₺$discount',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
