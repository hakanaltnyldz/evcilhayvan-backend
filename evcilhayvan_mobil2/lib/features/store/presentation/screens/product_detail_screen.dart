import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/store/providers/cart_providers.dart';
import 'package:evcilhayvan_mobil2/features/store/providers/store_providers.dart';
import 'package:evcilhayvan_mobil2/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:evcilhayvan_mobil2/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

const List<Color> _detailGradientA = [
  Color(0xFF7C7BFF),
  Color(0xFF5FD9C1),
];

const List<Color> _detailGradientB = [
  Color(0xFFFFB86C),
  Color(0xFFFF8FA2),
];

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late final PageController _pageController;
  int _page = 0;
  bool _adding = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isOwnProduct(ProductModel product) {
    final currentUser = ref.read(authProvider);
    if (currentUser == null || product.sellerId == null) return false;
    return currentUser.id == product.sellerId;
  }

  Future<void> _addToCart(ProductModel product) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isOwnProduct(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productDetailOwnProductErr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productDetailOutOfStock),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_quantity > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productDetailMaxStock(product.stock)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      final repo = ref.read(cartRepoProvider);
      for (int i = 0; i < _quantity; i++) {
        await repo.add(product.id);
      }
      ref.invalidate(cartItemsProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productDetailAddedToCart(_quantity)),
            backgroundColor: AppPalette.tertiary,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.productDetailGoToCart,
              textColor: Colors.white,
              onPressed: () => context.pushNamed('store-new-cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productDetailAddErr(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _shareProduct(ProductModel product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.productDetailShareSoon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.id));

    return Scaffold(
      body: ModernBackground(
        colors: AppPalette.storeBackground,
        child: SafeArea(
          child: detail.when(
            data: (product) {
              final l10n = AppLocalizations.of(context)!;
              final title = product.title.trim();
              final displayTitle = title.isNotEmpty ? title : l10n.productDetailNoTitle;
              final description = (product.description ?? '').trim();
              final displayDescription = description.isNotEmpty ? description : l10n.productDetailNoDesc;
              final isOwnProduct = _isOwnProduct(product);
              return Column(
              children: [
                _ImageCarousel(
                  controller: _pageController,
                  page: _page,
                  onPageChanged: (i) => setState(() => _page = i),
                  product: product,
                  isOwnProduct: isOwnProduct,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.storePrimary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -6),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppPalette.onBackground,
                                      ),
                                ),
                              ),
                              if (!isOwnProduct)
                                FavoriteButton(
                                  itemType: 'product',
                                  itemId: product.id,
                                  color: AppPalette.storePrimary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₺${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppPalette.storePrimary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _Chip(
                                label: l10n.productDetailStock(product.stock),
                                icon: Icons.inventory_2_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayDescription,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.4,
                                  color: AppPalette.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (product.store != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppPalette.storeSoftBlue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.store_mall_directory, color: AppPalette.storePrimary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.store!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if ((product.store!.description ?? '').isNotEmpty)
                                          Text(
                                            product.store!.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          const Divider(height: 32),
                          ReviewsSection(
                            productId: product.id,
                            productName: displayTitle,
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isOwnProduct)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.store_outlined, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.productDetailOwnProduct,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppPalette.storeSoftBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                  icon: const Icon(Icons.remove, size: 20),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 32),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_quantity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _quantity < product.stock
                                      ? () => setState(() => _quantity++)
                                      : null,
                                  icon: const Icon(Icons.add, size: 20),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _adding || product.stock <= 0
                                  ? null
                                  : () => _addToCart(product),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: Text(_adding ? AppLocalizations.of(context)!.productDetailAddingToCart : AppLocalizations.of(context)!.productDetailAddToCartBtn),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              );
            },
            loading: () => const _DetailSkeleton(),
            error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.productDetailNotFound)),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.storeSoftPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppPalette.storePrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({
    required this.controller,
    required this.page,
    required this.onPageChanged,
    required this.product,
    this.isOwnProduct = false,
  });

  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;
  final ProductModel product;
  final bool isOwnProduct;

  @override
  Widget build(BuildContext context) {
    final images = product.photos;
    final title = product.title.trim();
    final displayTitle = title.isNotEmpty ? title : AppLocalizations.of(context)!.productDetailNoTitle;
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final image = images.isNotEmpty ? images[index] : null;
              final imageUrl = image != null ? _resolveImageUrl(image) : null;
              final hasImage = imageUrl != null && imageUrl.isNotEmpty;
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _PlaceholderImage(title: displayTitle),
                      )
                    : _PlaceholderImage(title: displayTitle),
              );
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (!isOwnProduct)
            Positioned(
              top: 12,
              right: 12,
              child: FavoriteButton(
                itemType: 'product',
                itemId: product.id,
                showBackground: true,
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: page == i ? 22 : 8,
                    decoration: BoxDecoration(
                      color: page == i ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(20),
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

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppPalette.storeCardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 30,
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            gradient: LinearGradient(
              colors: [
                AppPalette.storePrimary.withOpacity(0.18),
                AppPalette.storeAccent.withOpacity(0.18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _resolveImageUrl(String path) {
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}
