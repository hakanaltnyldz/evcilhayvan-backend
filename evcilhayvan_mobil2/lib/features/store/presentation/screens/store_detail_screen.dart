import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/store_model.dart';
import 'package:evcilhayvan_mobil2/features/store/presentation/widgets/store_product_card.dart';
import 'package:evcilhayvan_mobil2/features/store/presentation/widgets/store_stats_card.dart';
import 'package:go_router/go_router.dart';

const List<Color> _storeDetailGradient = [
  Color(0xFF2F1BFF),
  Color(0xFF00C2FF),
];

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(_storeProvider(storeId));
    final user = ref.watch(authProvider);
    final isOwner = storeAsync.maybeWhen(
      data: (store) => user?.id == store.owner?.id,
      orElse: () => false,
    );
    final productsAsync = ref.watch(
      isOwner ? myProductsProvider : _storeProductsProvider(storeId),
    );

    Future<void> refreshProducts() async {
      ref.invalidate(_storeProductsProvider(storeId));
      if (isOwner) {
        ref.invalidate(myProductsProvider);
      }
    }

    Future<void> openEdit(ProductModel product) async {
      final result = await context.pushNamed('store-add-product', extra: product);
      if (result == true && context.mounted) {
        await refreshProducts();
      }
    }

    Future<void> toggleProduct(ProductModel product) async {
      final repo = ref.read(storeRepositoryProvider);
      final nextActive = !product.isActive;
      try {
        await repo.updateProduct(
          product.id,
          data: {'isActive': nextActive},
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nextActive ? 'Urun aktif edildi.' : 'Urun pasif edildi.'),
            ),
          );
        }
        await refreshProducts();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Urun guncellenemedi: $e')),
          );
        }
      }
    }

    Future<void> deleteProduct(ProductModel product) async {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Urunu sil'),
          content: const Text('Bu urunu silmek istediginize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgec'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        ),
      );
      if (shouldDelete != true) return;

      final repo = ref.read(storeRepositoryProvider);
      try {
        await repo.deleteProduct(product.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Urun silindi.')),
          );
        }
        await refreshProducts();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Urun silinemedi: $e')),
          );
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mağaza'),
      ),
      body: ModernBackground(
        colors: AppPalette.storeBackground,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: storeAsync.when(
                    data: (store) => _StoreHeader(
                      store: store,
                      isOwner: isOwner,
                    ),
                    loading: () => const _StoreHeaderSkeleton(),
                    error: (e, _) => _ErrorCard(
                      message: 'Mağaza yüklenemedi',
                      detail: e.toString(),
                      onRetry: () => ref.invalidate(_storeProvider(storeId)),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: productsAsync.when(
                    data: (products) => _StoreStatsRow(productsCount: products.length),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: Text('Bu mağazada henüz ürün yok.')),
                        ),
                      );
                    }
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return _StoreProductTile(
                            product: product,
                            isOwner: isOwner,
                            onEdit: isOwner ? () => openEdit(product) : null,
                            onToggle: isOwner ? () => toggleProduct(product) : null,
                            onDelete: isOwner ? () => deleteProduct(product) : null,
                          );
                        },
                        childCount: products.length,
                      ),
                    );
                  },
                  loading: () => const _StoreProductsSkeletonSliver(),
                  error: (e, _) => SliverToBoxAdapter(
                    child: _ErrorCard(
                      message: 'Ürünler yüklenemedi',
                      detail: e.toString(),
                      onRetry: () {
                        ref.invalidate(_storeProductsProvider(storeId));
                        if (isOwner) ref.invalidate(myProductsProvider);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _storeProvider = FutureProvider.family<StoreModel, String>((ref, id) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStore(id);
});

final _storeProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, id) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStoreProducts(id);
});

class _StoreHeader extends ConsumerStatefulWidget {
  const _StoreHeader({required this.store, required this.isOwner});

  final StoreModel store;
  final bool isOwner;

  @override
  ConsumerState<_StoreHeader> createState() => _StoreHeaderState();
}

class _StoreHeaderState extends ConsumerState<_StoreHeader> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/favorites/check',
        queryParameters: {
          'itemType': 'store',
          'itemId': widget.store.id,
        },
      );
      if (mounted && response.data['success'] == true) {
        setState(() => _isFavorite = response.data['isFavorite'] ?? false);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (_isFavorite) {
        await ApiClient().dio.delete('/api/favorites', data: {
          'itemType': 'store',
          'itemId': widget.store.id,
        });
        if (mounted) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilerden kaldırıldı'), backgroundColor: Colors.orange),
          );
        }
      } else {
        await ApiClient().dio.post('/api/favorites', data: {
          'itemType': 'store',
          'itemId': widget.store.id,
        });
        if (mounted) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilere eklendi'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final isOwner = widget.isOwner;
    final theme = Theme.of(context);
    final logoUrl = _resolveMediaUrl(store.logoUrl);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: _storeDetailGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.storePrimary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: logoUrl != null
                    ? Image.network(
                        logoUrl,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _LogoFallback(name: store.name),
                      )
                    : _LogoFallback(name: store.name),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if ((store.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          store.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ),
                    if (store.owner != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              store.owner!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((store.owner!.city ?? '').isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                              Text(
                                store.owner!.city!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isOwner
                    ? () => context.pushNamed('store-add-product')
                    : (_isLoading ? null : _toggleFavorite),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFavorite ? Colors.red.shade50 : Colors.white,
                  foregroundColor: _isFavorite ? Colors.red : AppPalette.onBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isOwner ? Icons.add : (_isFavorite ? Icons.favorite : Icons.favorite_border)),
                label: Text(isOwner ? 'Urun ekle' : (_isFavorite ? 'Favorilerde' : 'Favorilere ekle')),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Paylaş'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _StoreStatsRow extends StatelessWidget {
  const _StoreStatsRow({required this.productsCount});

  final int productsCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: StoreStatsCard(
        icon: Icons.inventory_2_outlined,
        label: 'Toplam ürün',
        value: productsCount.toString(),
        color: AppPalette.storePrimary,
      ),
    );
  }
}

class _StoreHeaderSkeleton extends StatelessWidget {
  const _StoreHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: _storeDetailGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      height: 36,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 36,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreProductsSkeletonSliver extends StatelessWidget {
  const _StoreProductsSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: _storeDetailGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(1.4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        childCount: 4,
      ),
    );
  }
}

class _StoreProductTile extends StatelessWidget {
  const _StoreProductTile({
    required this.product,
    required this.isOwner,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  final ProductModel product;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StoreProductCard(
            product: product,
            showStoreName: false,
            badge: product.stock <= 0
                ? 'Tukendi'
                : (product.stock <= 3 ? 'Son ${product.stock}' : null),
            onTap: () => context.pushNamed(
              'store-new-product',
              pathParameters: {'id': product.id},
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.storeSoftBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Stok: ${product.stock}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: product.isActive
                      ? Colors.green.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: product.isActive ? Colors.green : Colors.black54,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (isOwner)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'toggle') {
                    onToggle?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Duzenle')),
                  PopupMenuItem(value: 'toggle', child: Text('Aktif/Pasif')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPalette.storePrimary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_horiz, color: AppPalette.storePrimary),
                ),
              ),
          ],
        )
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String name;
  const _LogoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      color: Colors.white.withOpacity(0.2),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const _ErrorCard({
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yeniden Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.storePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
