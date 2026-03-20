import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/data/order_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';

const List<Color> _dashboardGradientA = [
  Color(0xFF7C7BFF),
  Color(0xFF5FD9C1),
];

const List<Color> _dashboardGradientB = [
  Color(0xFFFFB86C),
  Color(0xFFFF8FA2),
];

const List<Color> _dashboardGradientC = [
  Color(0xFF6C63FF),
  Color(0xFFB06AFF),
];

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final myStoreAsync = ref.watch(myStoreProvider);
    final myProductsAsync = ref.watch(myProductsProvider);
    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context)!;

    if (user == null || user.role != 'seller') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                size: 80,
                color: AppPalette.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.sellerPanelTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sellerBecomeSellerDesc,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pushNamed('store-apply'),
                icon: const Icon(Icons.store_mall_directory_outlined),
                label: Text(l10n.sellerBecomeSeller),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.storeSoftBlue.withOpacity(0.3),
      appBar: AppBar(
        title: Text(
          l10n.sellerPanelTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              myStoreAsync.whenData((store) {
                if (store != null) {
                  context.pushNamed(
                    'store-detail',
                    pathParameters: {'storeId': store.id},
                  );
                }
              });
            },
            icon: const Icon(Icons.store_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myStoreProvider);
          ref.invalidate(myProductsProvider);
          ref.invalidate(sellerOrderStatsProvider);
          ref.invalidate(sellerRevenueChartProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: myStoreAsync.when(
                  data: (store) {
                    if (store == null) {
                      return _NoStoreCard(
                        onCreateStore: () => context.pushNamed('store-apply'),
                      );
                    }
                    return _StoreInfoCard(storeName: store.name);
                  },
                  loading: () => const _StoreInfoSkeleton(),
                  error: (e, _) => _ErrorCard(
                    message: l10n.sellerStoreLoadErr,
                    onRetry: () => ref.invalidate(myStoreProvider),
                  ),
                ),
              ),
            ),
            // Sipariş ve Gelir İstatistikleri
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer(
                  builder: (context, ref, _) {
                    final orderStatsAsync = ref.watch(sellerOrderStatsProvider);
                    return orderStatsAsync.when(
                      data: (stats) => _OrderStatsCard(
                        totalRevenue: stats.totalRevenue,
                        pendingOrders: stats.activeOrders,
                        totalOrders: stats.totalOrders,
                        onTap: () => context.pushNamed('seller-orders'),
                      ),
                      loading: () => Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      error: (e, _) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(AppLocalizations.of(context)!.sellerOrderStatsLoadErr)),
                            TextButton(
                              onPressed: () => ref.invalidate(sellerOrderStatsProvider),
                              child: Text(AppLocalizations.of(context)!.sellerRetry),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: myProductsAsync.when(
                  data: (products) => _StatsGrid(
                    totalProducts: products.length,
                    activeProducts: products.where((p) => p.isActive).length,
                    lowStockProducts: products.where((p) => p.stock <= 3).length,
                  ),
                  loading: () => const _StatsGridSkeleton(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context)!.sellerProductStatsLoadErr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Gelir grafiği
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Consumer(
                  builder: (context, ref, _) {
                    final chartAsync = ref.watch(sellerRevenueChartProvider);
                    return chartAsync.when(
                      data: (points) => _RevenueChartCard(points: points),
                      loading: () => const SizedBox(
                        height: 180,
                        child: Card(child: Center(child: CircularProgressIndicator())),
                      ),
                      error: (_, __) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.sellerRevenueChartLoadErr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _QuickActionsCard(
                  onAddProduct: () => context.pushNamed('store-add-product'),
                  onManageProducts: () => context.pushNamed('product-management'),
                  onViewStore: () {
                    myStoreAsync.whenData((store) {
                      if (store != null) {
                        context.pushNamed(
                          'store-detail',
                          pathParameters: {'storeId': store.id},
                        );
                      }
                    });
                  },
                  onViewOrders: () => context.pushNamed('seller-orders'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: myProductsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final lowStockProducts = products.where((p) => p.stock <= 3 && p.stock > 0).toList();
                    final outOfStockProducts = products.where((p) => p.stock <= 0).toList();

                    if (lowStockProducts.isEmpty && outOfStockProducts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sellerAttentionProducts,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (outOfStockProducts.isNotEmpty)
                          _AlertCard(
                            title: l10n.sellerOutOfStock,
                            count: outOfStockProducts.length,
                            icon: Icons.inventory_2_outlined,
                            color: Colors.red,
                            products: outOfStockProducts.take(3).toList(),
                          ),
                        if (lowStockProducts.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _AlertCard(
                            title: l10n.sellerLowStock,
                            count: lowStockProducts.length,
                            icon: Icons.warning_amber_outlined,
                            color: Colors.orange,
                            products: lowStockProducts.take(3).toList(),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStoreCard extends StatelessWidget {
  const _NoStoreCard({required this.onCreateStore});

  final VoidCallback onCreateStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _dashboardGradientB,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.storeSecondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.sellerNoStore,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.sellerNoStoreDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreateStore,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_business),
            label: Text(
              AppLocalizations.of(context)!.sellerCreateStore,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  const _StoreInfoCard({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _dashboardGradientA,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.storePrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_mall_directory,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.sellerActiveStore,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _OrderStatsCard extends StatelessWidget {
  const _OrderStatsCard({
    required this.totalRevenue,
    required this.pendingOrders,
    required this.totalOrders,
    required this.onTap,
  });

  final double totalRevenue;
  final int pendingOrders;
  final int totalOrders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11998e).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.sellerTotalRevenue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\u20BA${totalRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 70,
              color: Colors.white.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pending_actions,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pendingOrders',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.sellerPendingOrders,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.sellerTotalOrdersCount(totalOrders),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
  });

  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: AppLocalizations.of(context)!.sellerTotalProducts,
            value: totalProducts.toString(),
            icon: Icons.inventory_2_outlined,
            gradient: _dashboardGradientA,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: AppLocalizations.of(context)!.productMgmtActive,
            value: activeProducts.toString(),
            icon: Icons.check_circle_outline,
            gradient: _dashboardGradientC,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: AppLocalizations.of(context)!.sellerLowStock,
            value: lowStockProducts.toString(),
            icon: Icons.warning_amber_outlined,
            gradient: _dashboardGradientB,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends ConsumerStatefulWidget {
  const _QuickActionsCard({
    required this.onAddProduct,
    required this.onManageProducts,
    required this.onViewStore,
    required this.onViewOrders,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onManageProducts;
  final VoidCallback onViewStore;
  final VoidCallback onViewOrders;

  @override
  ConsumerState<_QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<_QuickActionsCard> {
  bool _isSeeding = false;

  Future<void> _handleSeedDemoProducts() async {
    if (_isSeeding) return;

    // Confirm dialog
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        title: Text(dl10n.sellerDemoProductsTitle),
        content: Text(dl10n.sellerDemoProductsContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dl10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dl10n.sellerDemoProductsContinue),
          ),
        ],
      );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);

    try {
      final repo = ref.read(storeRepositoryProvider);
      final result = await repo.seedDemoProducts();

      if (!mounted) return;

      // Refresh data
      ref.invalidate(myProductsProvider);
      ref.invalidate(myStoreProvider);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.sellerDemoProductsAdded(result.productsCreated),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sellerErrGeneric(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sellerQuickActions,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _QuickActionButton(
            icon: Icons.add_box_outlined,
            label: l10n.sellerAddProduct,
            color: AppPalette.storePrimary,
            onTap: widget.onAddProduct,
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.settings_outlined,
            label: l10n.sellerManageProducts,
            color: AppPalette.storeAccent,
            onTap: widget.onManageProducts,
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.store_outlined,
            label: l10n.sellerViewStore,
            color: Colors.teal,
            onTap: widget.onViewStore,
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.receipt_long_outlined,
            label: l10n.sellerMyOrders,
            color: AppPalette.storeSecondary,
            onTap: widget.onViewOrders,
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: _isSeeding ? Icons.hourglass_empty : Icons.rocket_launch_outlined,
            label: _isSeeding ? l10n.sellerDemoProductsLoading : l10n.sellerDemoProducts,
            color: Colors.purple,
            onTap: _isSeeding ? () {} : _handleSeedDemoProducts,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.products,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$title ($count)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...products.map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.sellerStockLabel(product.stock as int),
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }
}

class _StoreInfoSkeleton extends StatelessWidget {
  const _StoreInfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _dashboardGradientA,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ─── Revenue Chart ────────────────────────────────────────────────────────────

class _RevenueChartCard extends StatefulWidget {
  final List<RevenueChartPoint> points;
  const _RevenueChartCard({required this.points});

  @override
  State<_RevenueChartCard> createState() => _RevenueChartCardState();
}

class _RevenueChartCardState extends State<_RevenueChartCard> {
  bool _showRevenue = true; // toggle: gelir ↔ sipariş sayısı

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pts = widget.points;
    if (pts.isEmpty) return const SizedBox.shrink();

    final maxRevenue = pts.fold<double>(0, (m, p) => p.revenue > m ? p.revenue : m);
    final maxOrders  = pts.fold<int>(0, (m, p) => p.orders > m ? p.orders : m);
    final maxY = _showRevenue
        ? (maxRevenue == 0 ? 1.0 : maxRevenue * 1.2)
        : (maxOrders == 0 ? 1.0 : maxOrders * 1.2);

    final bars = pts.asMap().entries.map((e) {
      final val = _showRevenue ? e.value.revenue : e.value.orders.toDouble();
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: val,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C7BFF), Color(0xFF5FD9C1)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.sellerLast6Months,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true,  label: Text(AppLocalizations.of(context)!.sellerChartRevenue)),
                  ButtonSegment(value: false, label: Text(AppLocalizations.of(context)!.sellerChartOrders)),
                ],
                selected: {_showRevenue},
                onSelectionChanged: (s) => setState(() => _showRevenue = s.first),
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY / 4,
                      getTitlesWidget: (val, meta) {
                        String label;
                        if (_showRevenue) {
                          label = val >= 1000
                              ? '${(val / 1000).toStringAsFixed(1)}k'
                              : val.toStringAsFixed(0);
                        } else {
                          label = val.toInt().toString();
                        }
                        return Text(
                          label,
                          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= pts.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            pts[idx].shortLabel,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final p = pts[group.x];
                      final label = _showRevenue
                          ? '₺${p.revenue.toStringAsFixed(0)}'
                          : AppLocalizations.of(context)!.sellerOrderCountTooltip(p.orders);
                      return BarTooltipItem(
                        label,
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _dashboardGradientA,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _dashboardGradientC,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _dashboardGradientB,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
