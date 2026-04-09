import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:evcilhayvan_mobil2/features/store/providers/cart_providers.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class StoreProductCard extends ConsumerStatefulWidget {
  const StoreProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.badge,
    this.showStoreName = true,
    this.onAddToCart,
    this.isOwnProduct = false,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final String? badge;
  final bool showStoreName;
  final VoidCallback? onAddToCart;
  final bool isOwnProduct;

  @override
  ConsumerState<StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends ConsumerState<StoreProductCard> {
  bool _pressed = false;
  bool _addingToCart = false;

  void _handleTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _handleCancel() => setState(() => _pressed = false);
  void _handleTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  Future<void> _addToCart() async {
    if (_addingToCart) return;

    setState(() => _addingToCart = true);
    try {
      await ref.read(cartProvider.notifier).addItem(widget.product, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.productCardAddedToCart(widget.product.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppPalette.storePrimary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        widget.onAddToCart?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productCardAddErr(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final hasImage = product.photos.isNotEmpty;
    final badge = widget.badge;
    final title = product.title.trim();
    final displayTitle = title.isNotEmpty ? title : AppLocalizations.of(context)!.productCardNoTitle;
    final imageUrl = hasImage ? resolveImageUrl(product.photos.first) : null;
    final isOutOfStock = product.stock <= 0;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapCancel: _handleCancel,
        onTapUp: _handleTapUp,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppPalette.storePrimary.withOpacity(context.isDark ? 0.12 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün Fotoğrafı
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ürün resmi
                    imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderImage(title: displayTitle),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const ShimmerBox();
                            },
                          )
                        : _PlaceholderImage(title: displayTitle),

                    // Favori butonu - sağ üst köşe
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FavoriteButton(
                          itemType: 'product',
                          itemId: product.id,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                      ),
                    ),

                    // Badge (Tükendi, Son 3 adet vb.)
                    if (badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOutOfStock ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),

                    // Sepete ekle butonu - sağ alt köşe (kendi ürününde gizli)
                    if (!isOutOfStock && !widget.isOwnProduct)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _addToCart,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppPalette.storePrimary, AppPalette.storeSecondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.storePrimary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _addingToCart
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Ürün Bilgileri
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün adı
                      Text(
                        displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppPalette.onBackground,
                          height: 1.2,
                        ),
                      ),

                      const Spacer(),

                      // Mağaza adı (varsa)
                      if (widget.showStoreName && product.store != null) ...[
                        Text(
                          product.store!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Fiyat
                      Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppPalette.storePrimary,
                        ),
                      ),
                    ],
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

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 4),
          Text(
            title.isNotEmpty ? title.substring(0, title.length > 10 ? 10 : title.length) : '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

