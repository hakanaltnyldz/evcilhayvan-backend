// lib/features/favorites/presentation/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/features/favorites/domain/models/favorite_model.dart';
import 'package:evcilhayvan_mobil2/features/favorites/providers/favorite_providers.dart';
import 'package:evcilhayvan_mobil2/features/favorites/presentation/widgets/favorite_button.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.subtleBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.favoritesTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: context.cardColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.storePrimary,
          unselectedLabelColor: AppPalette.onSurfaceVariant,
          indicatorColor: AppPalette.storePrimary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'İlanlar'),
            Tab(text: 'Ürünler'),
            Tab(text: 'Mağazalar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FavoritesTab(type: null, key: const ValueKey('all')),
          _FavoritesTab(type: 'pet', key: const ValueKey('pet')),
          _FavoritesTab(type: 'product', key: const ValueKey('product')),
          _FavoritesTab(type: 'store', key: const ValueKey('store')),
        ],
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  final String? type;

  const _FavoritesTab({super.key, this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = type == null
        ? ref.watch(favoritesProvider)
        : ref.watch(favoritesByTypeProvider(type!));

    return RefreshIndicator(
      onRefresh: () async {
        if (type == null) {
          ref.invalidate(favoritesProvider);
        } else {
          ref.invalidate(favoritesByTypeProvider(type!));
        }
      },
      child: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return _EmptyState(type: type);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return _FavoriteCard(favorite: favorite)
                  .animate(delay: (index * 55).ms)
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.06);
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const _FavoriteCardSkeleton(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Favoriler yüklenemedi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (type == null) {
                      ref.invalidate(favoritesProvider);
                    } else {
                      ref.invalidate(favoritesByTypeProvider(type!));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteModel favorite;

  const _FavoriteCard({required this.favorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title = '';
    String? subtitle;
    String? imageUrl;
    VoidCallback? onTap;

    // Parse data based on item type
    if (favorite.itemType == 'pet' && favorite.asPet != null) {
      final pet = favorite.asPet!;
      title = pet.name;
      subtitle = '${pet.species} • ${pet.breed}';
      imageUrl = pet.photos.isNotEmpty ? _resolveImageUrl(pet.photos.first) : null;
      onTap = () => context.pushNamed('pet-detail', pathParameters: {'id': pet.id});
    } else if (favorite.itemType == 'product' && favorite.asProduct != null) {
      final product = favorite.asProduct!;
      title = product.title;
      subtitle = '₺${product.price.toStringAsFixed(2)}';
      imageUrl = product.photos.isNotEmpty ? _resolveImageUrl(product.photos.first) : null;
      onTap = () => context.pushNamed('product-detail', pathParameters: {'id': product.id});
    } else if (favorite.itemType == 'store' && favorite.asStore != null) {
      final store = favorite.asStore!;
      title = store.name;
      subtitle = store.description;
      imageUrl = store.logoUrl != null ? _resolveImageUrl(store.logoUrl!) : null;
      onTap = () => context.pushNamed('store-detail', pathParameters: {'storeId': store.id});
    }

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppPalette.storePrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: AppPalette.storeCardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : const ShimmerBox(),
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            title.isNotEmpty ? title[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _TypeChip(type: favorite.itemType),
                  ],
                ),
              ),
              // Favorite button
              FavoriteButton(
                itemType: favorite.itemType,
                itemId: favorite.item is Map
                    ? (favorite.item['_id']?.toString() ??
                        favorite.item['id']?.toString() ??
                        '')
                    : (favorite.itemType == 'pet'
                        ? favorite.asPet!.id
                        : favorite.itemType == 'product'
                            ? favorite.asProduct!.id
                            : favorite.asStore!.id),
                color: AppPalette.storePrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case 'pet':
        label = 'İlan';
        icon = Icons.pets;
        color = AppPalette.primary;
        break;
      case 'product':
        label = 'Ürün';
        icon = Icons.shopping_bag;
        color = AppPalette.storePrimary;
        break;
      case 'store':
        label = 'Mağaza';
        icon = Icons.store;
        color = AppPalette.storeAccent;
        break;
      default:
        label = type;
        icon = Icons.bookmark;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCardSkeleton extends StatelessWidget {
  const _FavoriteCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? type;

  const _EmptyState({this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String message;
    IconData icon;

    switch (type) {
      case 'pet':
        message = 'Henüz favori ilan yok';
        icon = Icons.pets;
        break;
      case 'product':
        message = 'Henüz favori ürün yok';
        icon = Icons.shopping_bag_outlined;
        break;
      case 'store':
        message = 'Henüz favori mağaza yok';
        icon = Icons.store_mall_directory_outlined;
        break;
      default:
        message = AppLocalizations.of(context)!.favoritesEmpty;
        icon = Icons.favorite_border;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppPalette.storeCardGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.storePrimary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(icon, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Beğendiğiniz ${type == 'pet' ? 'ilanları' : type == 'product' ? 'ürünleri' : type == 'store' ? 'mağazaları' : 'öğeleri'} favorilere ekleyin',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveImageUrl(String path) {
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}
