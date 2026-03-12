import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart' as store_data;
import 'package:evcilhayvan_mobil2/features/store/domain/models/store_model.dart';
import 'package:evcilhayvan_mobil2/features/store/presentation/widgets/store_category_chips.dart';
import 'package:evcilhayvan_mobil2/features/store/presentation/widgets/store_product_card.dart';
import 'package:evcilhayvan_mobil2/features/store/providers/store_providers.dart' as catalog;

const List<Color> _storeBoldBackground = [
  Color(0xFFF5F2FF),
  Color(0xFFE9FBFF),
  Color(0xFFFFF1E2),
];

const List<Color> _storeHeroGradient = [
  Color(0xFF2F1BFF),
  Color(0xFF00C2FF),
  Color(0xFFFFC857),
];

const List<Color> _storeCardGradientA = [
  Color(0xFF3C2BFF),
  Color(0xFF00B8FF),
];

const List<Color> _storeCardGradientB = [
  Color(0xFFFF4D6D),
  Color(0xFFFFB347),
];

const List<Color> _storeAccentGradient = [
  Color(0xFF00C2FF),
  Color(0xFF5EFCE8),
];

class StoreHomeScreen extends ConsumerStatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  ConsumerState<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends ConsumerState<StoreHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String? _selectedCategory;
  String _query = '';

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final next = text.trim();
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  void _clearFilters() {
    if (_selectedCategory == null && _query.isEmpty && _searchController.text.isEmpty) {
      return;
    }
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
      _query = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = catalog.storeProductsProvider((
      category: _selectedCategory,
      q: _query.isNotEmpty ? _query : null,
    ));

    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(catalog.categoriesProvider);
    final storesAsync = ref.watch(store_data.storeDiscoverProvider);
    final user = ref.watch(authProvider);
    final myStoreAsync =
        user?.role == 'seller' ? ref.watch(store_data.myStoreProvider) : null;
    final hasFilters = _selectedCategory != null || _query.isNotEmpty;
    final myStoreId = myStoreAsync?.valueOrNull?.id;

    return Scaffold(
      body: ModernBackground(
        colors: _storeBoldBackground,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(productsProvider.future),
                ref.refresh(catalog.categoriesProvider.future),
                ref.refresh(store_data.storeDiscoverProvider.future),
                if (myStoreAsync != null)
                  ref.refresh(store_data.myStoreProvider.future),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onCartTap: () =>
                              context.pushNamed('store-new-cart'),
                          onFavoritesTap: () =>
                              context.pushNamed('favorites'),
                          onOrdersTap: () =>
                              context.push('/store/orders'),
                        ),
                        const SizedBox(height: 14),
                        const _HeroCard(),
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const _InfoBanner(message: 'Kategori bulunamadı.');
                            }
                            return StoreCategoryChips(
                              categories: categories,
                              selectedCategoryId: _selectedCategory,
                              onSelected: (value) => setState(() => _selectedCategory = value),
                            );
                          },
                          loading: () => const _CategorySkeletonRow(),
                          error: (e, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _InfoBanner(message: 'Kategoriler yüklenemedi.'),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () => ref.invalidate(catalog.categoriesProvider),
                                child: const Text('Yeniden dene'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user == null || user.role != 'seller')
                          _SellerCTA(onTap: () {
                            if (user == null) {
                              context.goNamed('login');
                            } else {
                              context.pushNamed('store-apply');
                            }
                          })
                        else if (myStoreAsync != null)
                          myStoreAsync.when(
                            data: (store) {
                              // store burada StoreModel? (nullable) olabilir
                              if (store == null) {
                              // Satıcının henüz mağazası yoksa CTA göster
                                return _SellerCTA(
                                  onTap: () =>
                                      context.pushNamed('store-apply'),
                                );
                              }
                              // Artık store kesinlikle null değil
                              return _MyStoreMiniCard(store: store);
                            },
                            loading: () => const _MiniCardSkeleton(),
                            error: (e, _) =>
                                Text('Mağazanız alınamadı: $e'),
                          ),
                        const SizedBox(height: 14),
                        const _SectionHeader(
                          title: 'Öne çıkan mağazalar',
                        ),
                        const SizedBox(height: 8),
                        storesAsync.when(
                          data: (stores) {
                            if (stores.isEmpty) {
                              return const _InfoBanner(
                                message: 'Öne çıkan mağaza bulunamadı.',
                              );
                            }
                            return _StoreCarousel(stores: stores);
                          },
                          loading: () => const _StoreCarouselSkeleton(),
                          error: (e, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _InfoBanner(
                                message: 'Mağazalar yüklenemedi.',
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(store_data.storeDiscoverProvider),
                                child: const Text('Yeniden dene'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionHeader(
                          title: 'Ürünler',
                          actionLabel: hasFilters ? 'Filtreleri temizle' : null,
                          onActionTap: hasFilters ? _clearFilters : null,
                        ),
                      ],
                    ),
                  ),
                ),
                productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              const Text('Ürün bulunamadı.'),
                              if (hasFilters)
                                TextButton(
                                  onPressed: _clearFilters,
                                  child: const Text('Filtreleri temizle'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return StoreProductCard(
                              product: product,
                              isOwnProduct: myStoreId != null && product.store?.id == myStoreId,
                              badge: product.stock <= 0
                                  ? 'Tükendi'
                                  : (product.stock <= 3
                                      ? 'Son ${product.stock}'
                                      : null),
                              onTap: () => context.pushNamed(
                                'store-new-product',
                                pathParameters: {'id': product.id},
                              ),
                            );
                          },
                          childCount: products.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const _ProductSkeletonSliver(),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          const _InfoBanner(
                            message: 'Ürünler yüklenemedi.',
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => ref.invalidate(productsProvider),
                            child: const Text('Yeniden dene'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onChanged,
    required this.onCartTap,
    required this.onFavoritesTap,
    required this.onOrdersTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCartTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onOrdersTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _storeCardGradientA,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.pets, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _storeAccentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.storePrimary.withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppPalette.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Ürün veya mağaza ara',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: _storeAccentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Ara',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.receipt_long_outlined,
          onPressed: onOrdersTap,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.favorite_border,
          onPressed: onFavoritesTap,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.shopping_bag_outlined,
          onPressed: onCartTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _storeCardGradientB,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppPalette.storeSecondary.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _storeHeroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppPalette.storePrimary.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canlı Mağaza',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gerçek mağazalar ve gerçek ürünler burada.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Hızlı keşfet',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerCTA extends StatelessWidget {
  const _SellerCTA({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: _storeCardGradientB,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.storeSecondary.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mağaza aç, ürünlerini vitrine çıkar!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dakikalar içinde başvur, petseverlere ulaş.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppPalette.onBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.store_mall_directory_outlined),
            label: const Text('Mağaza Aç'),
          ),
        ],
      ),
    );
  }
}

class _MyStoreMiniCard extends StatelessWidget {
  const _MyStoreMiniCard({required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = (store.description ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _storeCardGradientA,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.storePrimary.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: _storeCardGradientA,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                store.name.isNotEmpty
                    ? store.name[0].toUpperCase()
                    : 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description.isNotEmpty ? description : 'Açıklama eklenmemiş.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.pushNamed(
                'store-detail',
                pathParameters: {'storeId': store.id},
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCarousel extends StatelessWidget {
  const _StoreCarousel({required this.stores});

  final List<StoreModel> stores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stores.isEmpty) {
      return const Text('Şimdilik öne çıkan mağaza yok.');
    }
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final store = stores[index];
          final description = (store.description ?? '').trim();
          final logoUrl = _resolveMediaUrl(store.logoUrl);
          return Container(
            width: 240,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: index.isEven
                    ? _storeCardGradientA
                    : _storeCardGradientB,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.storePrimary.withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: logoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _LogoFallback(name: store.name),
                              ),
                            )
                          : _LogoFallback(name: store.name),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        store.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    description.isNotEmpty ? description : 'Açıklama yok.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () => context.pushNamed(
                        'store-detail',
                        pathParameters: {'storeId': store.id},
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mağazaya git'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'E',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onActionTap,
    this.actionLabel,
  });

  final String title;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canShowAction = actionLabel != null && onActionTap != null;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (canShowAction)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.storePrimary.withOpacity(0.12),
            AppPalette.storeAccent.withOpacity(0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.storePrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppPalette.storePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCardSkeleton extends StatelessWidget {
  const _MiniCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }
}

class _CategorySkeletonRow extends StatelessWidget {
  const _CategorySkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Container(
          width: index == 0 ? 70 : 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }
}

class _StoreCarouselSkeleton extends StatelessWidget {
  const _StoreCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: index.isEven ? _storeCardGradientA : _storeCardGradientB,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductSkeletonSliver extends StatelessWidget {
  const _ProductSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _ProductSkeletonCard(),
          childCount: 6,
        ),
      ),
    );
  }
}

class _ProductSkeletonCard extends StatelessWidget {
  const _ProductSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: _storeCardGradientA,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppPalette.storeSoftBlue.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 12,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: 70,
              decoration: BoxDecoration(
                color: AppPalette.storePrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
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
