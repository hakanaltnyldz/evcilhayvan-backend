import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/store/data/order_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_refresh_indicator.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);
    final statsAsync = ref.watch(sellerOrderStatsProvider);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.sellerOrdersTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(sellerOrdersProvider);
              ref.invalidate(sellerOrderStatsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppPalette.storePrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppPalette.storePrimary,
          tabs: [
            Tab(text: l10n.sellerOrdersTabAll),
            Tab(text: l10n.sellerOrdersTabPending),
            Tab(text: l10n.sellerOrdersTabProcessing),
            Tab(text: l10n.sellerOrdersTabShipped),
            Tab(text: l10n.sellerOrdersTabCompleted),
            const Tab(text: 'Iadeler'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats summary
          statsAsync.when(
            data: (stats) => _StatsSummary(stats: stats),
            loading: () =>
                const SizedBox(height: 100, child: Center(child: PawLoading())),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final returnOrders = orders
                    .where((order) => order.hasReturnRequest)
                    .toList();
                if (orders.isEmpty) {
                  // Don't use TabBarView when there are no orders
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _EmptyState(),
                      _EmptyState(),
                      _EmptyState(),
                      _EmptyState(),
                      _EmptyState(),
                      _ReturnsEmptyState(),
                    ],
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OrdersList(orders: orders, dateFormat: _dateFormat),
                    _OrdersList(
                      orders: orders
                          .where((o) => o.status == OrderStatus.pending)
                          .toList(),
                      dateFormat: _dateFormat,
                    ),
                    _OrdersList(
                      orders: orders
                          .where((o) => o.status == OrderStatus.processing)
                          .toList(),
                      dateFormat: _dateFormat,
                    ),
                    _OrdersList(
                      orders: orders
                          .where((o) => o.status == OrderStatus.shipped)
                          .toList(),
                      dateFormat: _dateFormat,
                    ),
                    _OrdersList(
                      orders: orders
                          .where(
                            (o) =>
                                o.status == OrderStatus.delivered ||
                                o.status == OrderStatus.cancelled,
                          )
                          .toList(),
                      dateFormat: _dateFormat,
                    ),
                    _ReturnsList(orders: returnOrders, dateFormat: _dateFormat),
                  ],
                );
              },
              loading: () => const Center(child: PawLoading()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.sellerOrdersLoadErr(e.toString())),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(sellerOrdersProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.storesListRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats});

  final OrderStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52B788).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: l10n.sellerOrdersStatTotal,
            value: stats.totalOrders.toString(),
            icon: Icons.receipt_long,
          ),
          _StatItem(
            label: l10n.sellerOrdersStatPending,
            value: stats.activeOrders.toString(),
            icon: Icons.pending_actions,
          ),
          _StatItem(
            label: l10n.sellerOrdersStatSales,
            value: stats.totalItemsSold.toString(),
            icon: Icons.shopping_bag,
          ),
          _StatItem(
            label: l10n.sellerOrdersStatRevenue,
            value: '₺${stats.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.monetization_on,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      icon: Icons.receipt_long_outlined,
      title: AppLocalizations.of(context)!.sellerOrdersEmpty,
      subtitle: AppLocalizations.of(context)!.sellerOrdersEmptyDesc,
    );
  }
}

class _ReturnsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AnimatedEmptyState(
      icon: Icons.assignment_return_outlined,
      title: 'Iade talebi yok',
      subtitle: 'Musterilerden gelen iade talepleri burada listelenecek.',
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.orders, required this.dateFormat});

  final List<OrderModel> orders;
  final DateFormat dateFormat;

  Future<void> _handleStatusUpdate(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    String newStatus,
  ) async {
    String? trackingNumber;
    String? carrier;

    // "Kargoya Ver" için tracking dialog göster
    if (newStatus == 'shipped' && context.mounted) {
      final result = await _showTrackingDialog(context);
      if (result == null) return; // iptal edildi
      trackingNumber = result.$1;
      carrier = result.$2;
    }

    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(
        order.id,
        newStatus,
        trackingNumber: trackingNumber,
        carrier: carrier,
      );
      ref.invalidate(sellerOrdersProvider);
      ref.invalidate(sellerOrderStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.sellerOrdersStatusUpdated,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.sellerOrdersStatusError(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Kargo firması + takip no dialog'u.
  /// Returns (trackingNumber, carrier) or null if cancelled.
  Future<(String, String)?> _showTrackingDialog(BuildContext context) async {
    final trackingCtrl = TextEditingController();
    String selectedCarrier = 'yurtici';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Color(0xFF52B788),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Kargo Bilgisi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kargo Firması',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCarrier,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'yurtici',
                      child: Text('Yurtiçi Kargo'),
                    ),
                    DropdownMenuItem(value: 'ptt', child: Text('PTT Kargo')),
                    DropdownMenuItem(value: 'aras', child: Text('Aras Kargo')),
                    DropdownMenuItem(value: 'mng', child: Text('MNG Kargo')),
                    DropdownMenuItem(
                      value: 'surat',
                      child: Text('Sürat Kargo'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Diğer')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedCarrier = v ?? 'yurtici'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Takip Numarası',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: trackingCtrl,
                  maxLength: 60,
                  decoration: InputDecoration(
                    hintText: 'Örn: 12345678901',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Takip numarası giriniz';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(
                    ctx,
                  ).pop((trackingCtrl.text.trim(), selectedCarrier));
                }
              },
              child: const Text(
                'Kargoya Ver',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    trackingCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return AnimatedEmptyState(
        icon: Icons.receipt_long_outlined,
        title: AppLocalizations.of(context)!.sellerOrdersCategoryEmpty,
      );
    }

    return PawRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sellerOrdersProvider);
        ref.invalidate(sellerOrderStatsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(
                order: order,
                dateFormat: dateFormat,
                onStatusUpdate: (newStatus) =>
                    _handleStatusUpdate(context, ref, order, newStatus),
              )
              .animate(
                delay: Duration(milliseconds: (index * 55).clamp(0, 440)),
              )
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(begin: 0.06, duration: 280.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _ReturnsList extends ConsumerWidget {
  const _ReturnsList({required this.orders, required this.dateFormat});

  final List<OrderModel> orders;
  final DateFormat dateFormat;

  Future<void> _handleResolve(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    String status,
  ) async {
    final note = await _showDecisionDialog(
      context,
      approve: status == 'approved',
    );
    if (note == null) return;

    try {
      await ref
          .read(orderRepositoryProvider)
          .resolveSellerReturnRequest(order.id, status, note: note);
      ref.invalidate(sellerOrdersProvider);
      ref.invalidate(sellerOrderStatsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Iade talebi onaylandi.'
                : 'Iade talebi reddedildi.',
          ),
          backgroundColor: status == 'approved'
              ? const Color(0xFF2D6A4F)
              : Colors.red,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Iade islemi basarisiz: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showDecisionDialog(
    BuildContext context, {
    required bool approve,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(approve ? 'Iadeyi Onayla' : 'Iadeyi Reddet'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: approve
                ? 'Musteriye iletilecek not (opsiyonel)'
                : 'Red nedeni veya aciklama',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve
                  ? const Color(0xFF2D6A4F)
                  : Colors.red.shade600,
            ),
            child: Text(
              approve ? 'Onayla' : 'Reddet',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return _ReturnsEmptyState();
    }

    return PawRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sellerOrdersProvider);
        ref.invalidate(sellerOrderStatsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _ReturnCard(
                order: order,
                dateFormat: dateFormat,
                onResolve: (status) =>
                    _handleResolve(context, ref, order, status),
              )
              .animate(
                delay: Duration(milliseconds: (index * 55).clamp(0, 440)),
              )
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(begin: 0.06, duration: 280.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({
    required this.order,
    required this.dateFormat,
    required this.onResolve,
  });

  final OrderModel order;
  final DateFormat dateFormat;
  final void Function(String status) onResolve;

  @override
  Widget build(BuildContext context) {
    final returnRequest = order.returnRequest!;
    final statusColor = _returnStatusColor(returnRequest.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    returnRequest.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  returnRequest.requestedAt != null
                      ? dateFormat.format(returnRequest.requestedAt!)
                      : dateFormat.format(order.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.buyerName ?? 'Musteri bilgisi yok',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      'TL ${(order.sellerTotal ?? order.totalAmount).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppPalette.storePrimary,
                      ),
                    ),
                  ],
                ),
                if ((order.buyerEmail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.buyerEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  returnRequest.reason,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (returnRequest.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    returnRequest.description,
                    style: TextStyle(
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ...order.items.map((item) => _OrderItemRow(item: item)),
                if (returnRequest.resolvedNote != null &&
                    returnRequest.resolvedNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      returnRequest.resolvedNote!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (returnRequest.isPending &&
                    !order.containsOnlySellerItems) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.24),
                      ),
                    ),
                    child: const Text(
                      'Bu sipariste baska satici urunleri de oldugu icin iade karari admin panelinden verilmelidir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (returnRequest.isPending && order.sellerCanResolveReturn)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onResolve('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onResolve('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Onayla'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.dateFormat,
    required this.onStatusUpdate,
  });

  final OrderModel order;
  final DateFormat dateFormat;
  final Function(String) onStatusUpdate;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return const Color(0xFF2D6A4F);
      case OrderStatus.shipped:
        return const Color(0xFF52B788);
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(order.status);
    final returnRequest = order.returnRequest;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (returnRequest != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _returnStatusColor(
                        returnRequest.status,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Iade: ${returnRequest.displayName}',
                      style: TextStyle(
                        color: _returnStatusColor(returnRequest.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  dateFormat.format(order.createdAt),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Order items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Buyer info
                if (order.buyerName != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.buyerName!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (order.buyerEmail != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.buyerEmail!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Items
                ...order.items.map((item) => _OrderItemRow(item: item)),
                const SizedBox(height: 12),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.sellerOrdersItemCount(order.itemCount),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₺${(order.sellerTotal ?? order.totalAmount).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.storePrimary,
                      ),
                    ),
                  ],
                ),
                if (returnRequest != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _returnStatusColor(
                        returnRequest.status,
                      ).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _returnStatusColor(
                          returnRequest.status,
                        ).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          returnRequest.reason,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (returnRequest.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            returnRequest.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          if (order.status != OrderStatus.cancelled &&
              order.status != OrderStatus.delivered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.subtleBackground,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (order.status == OrderStatus.pending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onStatusUpdate('processing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(l10n.sellerOrdersPrepare),
                      ),
                    ),
                  if (order.status == OrderStatus.processing) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onStatusUpdate('shipped'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52B788),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.local_shipping, size: 18),
                        label: Text(l10n.sellerOrdersShip),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.shipped) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onStatusUpdate('delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(l10n.sellerOrdersDelivered),
                      ),
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

Color _returnStatusColor(String status) {
  switch (status) {
    case 'approved':
      return const Color(0xFF2D6A4F);
    case 'rejected':
      return Colors.red.shade600;
    default:
      return Colors.orange.shade700;
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (item.image != null) {
      imageUrl = item.image!.startsWith('http')
          ? item.image
          : '${AppConfig.current.apiBaseUrl}${item.image}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    Icons.image_outlined,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppLocalizations.of(context)!.sellerOrdersItemQty(
                    item.quantity,
                    item.price.toStringAsFixed(2),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
