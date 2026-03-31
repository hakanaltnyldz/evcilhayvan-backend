import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  String _filter = 'all'; // all, active, inactive, lowstock, outofstock

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(myProductsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.productMgmtTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(myProductsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('store-add-product'),
        backgroundColor: AppPalette.storePrimary,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.productMgmtAddProduct,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: context.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.productMgmtAll,
                    isSelected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.productMgmtActive,
                    isSelected: _filter == 'active',
                    color: Colors.green,
                    onTap: () => setState(() => _filter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.productMgmtInactive,
                    isSelected: _filter == 'inactive',
                    color: Colors.grey,
                    onTap: () => setState(() => _filter = 'inactive'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.productMgmtLowStock,
                    isSelected: _filter == 'lowstock',
                    color: Colors.orange,
                    onTap: () => setState(() => _filter = 'lowstock'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.productMgmtOutOfStock,
                    isSelected: _filter == 'outofstock',
                    color: Colors.red,
                    onTap: () => setState(() => _filter = 'outofstock'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Product list
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = _filterProducts(products);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'all' ? l10n.productMgmtNoProducts : l10n.productMgmtNoCategoryProducts,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_filter == 'all') ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.pushNamed('store-add-product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.storePrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              l10n.productMgmtAddFirst,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myProductsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _ProductCard(
                        product: product,
                        onToggleActive: () => _toggleActive(product),
                        onUpdateStock: () => _showStockDialog(product),
                        onEdit: () => _editProduct(product),
                        onDelete: () => _deleteProduct(product),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: PawLoading()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      l10n.productMgmtLoadErr,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(e.toString()),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(myProductsProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
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

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    switch (_filter) {
      case 'active':
        return products.where((p) => p.isActive).toList();
      case 'inactive':
        return products.where((p) => !p.isActive).toList();
      case 'lowstock':
        return products.where((p) => p.stock > 0 && p.stock <= 5).toList();
      case 'outofstock':
        return products.where((p) => p.stock <= 0).toList();
      default:
        return products;
    }
  }

  Future<void> _toggleActive(ProductModel product) async {
    final l10n = AppLocalizations.of(context)!;
    final wasActive = product.isActive;
    try {
      final repo = ref.read(storeRepositoryProvider);
      await repo.toggleProductActive(product.id);
      ref.invalidate(myProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasActive ? l10n.productMgmtToggleDeactivated : l10n.productMgmtToggleActivated,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sellerErrGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showStockDialog(ProductModel product) async {
    final l10n = AppLocalizations.of(context)!;
    final stockController = TextEditingController(text: product.stock.toString());
    String action = 'set';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final ml10n = AppLocalizations.of(context)!;
          return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.storePrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: AppPalette.storePrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ml10n.productMgmtUpdateStockTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          product.displayName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Current stock info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ml10n.productMgmtCurrentStock,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${product.stock} ${ml10n.productMgmtStockUnit}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: product.stock <= 0
                            ? Colors.red
                            : product.stock <= 5
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action selection
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: ml10n.productMgmtStockChange,
                      icon: Icons.edit,
                      isSelected: action == 'set',
                      onTap: () => setModalState(() => action = 'set'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: ml10n.productMgmtStockIncrease,
                      icon: Icons.add_circle_outline,
                      isSelected: action == 'increase',
                      color: Colors.green,
                      onTap: () => setModalState(() => action = 'increase'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: ml10n.productMgmtStockDecrease,
                      icon: Icons.remove_circle_outline,
                      isSelected: action == 'decrease',
                      color: Colors.orange,
                      onTap: () => setModalState(() => action = 'decrease'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stock input
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: action == 'set'
                      ? ml10n.productMgmtNewStockAmt
                      : action == 'increase'
                          ? ml10n.productMgmtAddAmt
                          : ml10n.productMgmtSubtractAmt,
                  hintText: ml10n.productMgmtEnterAmt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppPalette.storePrimary,
                      width: 2,
                    ),
                  ),
                  suffixText: ml10n.productMgmtStockUnit,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(ml10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = int.tryParse(stockController.text) ?? 0;
                        Navigator.pop(context);
                        await _updateStock(
                          product,
                          amount,
                          action == 'set' ? null : action,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.storePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        ml10n.productMgmtUpdate,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Future<void> _updateStock(ProductModel product, int stock, String? action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(storeRepositoryProvider);
      await repo.updateStock(product.id, stock: stock, action: action);
      ref.invalidate(myProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productMgmtStockUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sellerErrGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editProduct(ProductModel product) {
    // TODO: Navigate to edit product screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.productMgmtEditSoon),
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(dl10n.productMgmtDeleteTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dl10n.productMgmtDeleteContent(product.displayName),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dl10n.productMgmtDeleteWarning,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dl10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(dl10n.delete),
          ),
        ],
      );
      },
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(storeRepositoryProvider);
        await repo.deleteProduct(product.id);
        ref.invalidate(myProductsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.productMgmtDeleted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.sellerErrGeneric(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppPalette.storePrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppPalette.storePrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? btnColor.withOpacity(0.1) : context.subtleBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? btnColor : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? btnColor : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? btnColor : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onToggleActive,
    required this.onUpdateStock,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductModel product;
  final VoidCallback onToggleActive;
  final VoidCallback onUpdateStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasImage = product.photos.isNotEmpty;
    final imageUrl = hasImage
        ? (product.photos.first.startsWith('http')
            ? product.photos.first
            : '${AppConfig.current.apiBaseUrl}${product.photos.first}')
        : null;

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
          // Product info row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
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
                          size: 32,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? Colors.green.shade50
                                  : context.cardColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.isActive ? AppLocalizations.of(context)!.productMgmtStatusActive : AppLocalizations.of(context)!.productMgmtStatusInactive,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: product.isActive
                                    ? Colors.green.shade700
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price
                      Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.storePrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stock info
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: _getStockColor(product.stock),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.productMgmtStock(product.stock),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getStockColor(product.stock),
                            ),
                          ),
                          if (product.stock <= 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.productMgmtStockOutBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ] else if (product.stock <= 5) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.productMgmtStockLowBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            decoration: BoxDecoration(
              color: context.subtleBackground,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _CardActionButton(
                  icon: product.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  label: product.isActive ? AppLocalizations.of(context)!.productMgmtDeactivate : AppLocalizations.of(context)!.productMgmtActivate,
                  color: product.isActive ? Colors.grey : Colors.green,
                  onTap: onToggleActive,
                ),
                _CardActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: AppLocalizations.of(context)!.productMgmtStockAction,
                  color: AppPalette.storePrimary,
                  onTap: onUpdateStock,
                ),
                _CardActionButton(
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context)!.productMgmtEditAction,
                  color: const Color(0xFF2D6A4F),
                  onTap: onEdit,
                ),
                _CardActionButton(
                  icon: Icons.delete_outline,
                  label: AppLocalizations.of(context)!.productMgmtDeleteAction,
                  color: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}