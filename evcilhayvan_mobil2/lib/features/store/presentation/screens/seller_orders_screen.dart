import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/store/data/order_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
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
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats summary
          statsAsync.when(
            data: (stats) => _StatsSummary(stats: stats),
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: PawLoading()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  // Don't use TabBarView when there are no orders
                  return TabBarView(
                    controller: _tabController,
                    children: List.generate(5, (_) => _EmptyState()),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OrdersList(orders: orders, dateFormat: _dateFormat),
                    _OrdersList(
                      orders: orders.where((o) => o.status == OrderStatus.pending).toList(),
                      dateFormat: _dateFormat,
                    ),
                    _OrdersList(
                      orders: orders.where((o) => o.status == OrderStatus.processing).toList(),
                      dateFormat: _dateFormat,
                    ),
                    _OrdersList(
                      orders: orders.where((o) => o.status == OrderStatus.shipped).toList(),
                      dateFormat: _dateFormat,
                    ),
                    _OrdersList(
                      orders: orders
                          .where((o) =>
                              o.status == OrderStatus.delivered ||
                              o.status == OrderStatus.cancelled)
                          .toList(),
                      dateFormat: _dateFormat,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: PawLoading()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.sellerOrdersEmpty,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.sellerOrdersEmptyDesc,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({
    required this.orders,
    required this.dateFormat,
  });

  final List<OrderModel> orders;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.sellerOrdersCategoryEmpty,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
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
            onStatusUpdate: (newStatus) async {
              try {
                final repo = ref.read(orderRepositoryProvider);
                await repo.updateOrderStatus(order.id, newStatus);
                ref.invalidate(sellerOrdersProvider);
                ref.invalidate(sellerOrderStatsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.sellerOrdersStatusUpdated),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.sellerOrdersStatusError(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          );
        },
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      Icon(Icons.person_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              ],
            ),
          ),
          // Actions
          if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.subtleBackground,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                ? Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.outlineVariant)
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
                  AppLocalizations.of(context)!.sellerOrdersItemQty(item.quantity, item.price.toStringAsFixed(2)),
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