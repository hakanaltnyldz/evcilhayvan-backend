// lib/features/store/presentation/screens/my_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/order_model.dart';
import '../../data/order_repository.dart';
import '../../../reviews/presentation/screens/add_review_screen.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../auth/domain/user_model.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderMyOrdersTitle),
        elevation: 0,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    l10n.orderNoOrders,
                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.orderNoOrdersDesc,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _OrderCard(order: orders[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.orderLoadErr(e.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myOrdersProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _expanded = false;
  bool _cancelling = false;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatus.pending:
        return l10n.orderStatusPending;
      case OrderStatus.processing:
        return l10n.orderStatusProcessing;
      case OrderStatus.shipped:
        return l10n.orderStatusShipped;
      case OrderStatus.delivered:
        return l10n.orderStatusDelivered;
      case OrderStatus.cancelled:
        return l10n.orderStatusCancelled;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.processing:
        return Icons.inventory;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Future<void> _cancelOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.orderCancelTitle),
        content: Text(l10n.orderCancelContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.orderCancelAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);

    try {
      await ApiClient().dio.patch('/api/orders/${widget.order.id}/cancel');
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.orderCancelSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.orderCancelError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'tr').format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  String _getShortOrderId(String id) {
    if (id.length >= 8) {
      return id.substring(id.length - 8).toUpperCase();
    }
    return id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.orderNumber(_getShortOrderId(order.id)),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(order.status),
                              size: 14,
                              color: _getStatusColor(order.status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusText(order.status, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      Text(
                        '₺${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.storePrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.orderItemCount(order.items.length),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products
                  Text(
                    l10n.orderProducts,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.subtleBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.image!.startsWith('http')
                                            ? item.image!
                                            : '$apiBaseUrl${item.image}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
                                      ),
                                    )
                                  : Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    l10n.orderItemQty(
                                      item.quantity,
                                      item.price.toStringAsFixed(2),
                                    ),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        // Review button - only for delivered orders
                        if (order.status == OrderStatus.delivered) ...[
                          const SizedBox(height: 10),
                          if (item.myReview != null) ...[
                            Row(
                              children: [
                                ...List.generate(5, (index) => Icon(
                                  index < item.myReview!.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber[700],
                                  size: 20,
                                )),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.orderMyRating(item.myReview!.rating),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final existingReview = ReviewModel(
                                    id: item.myReview!.id,
                                    productId: item.productId,
                                    user: User.fromJson({'_id': ''}),
                                    rating: item.myReview!.rating,
                                    comment: item.myReview!.comment,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddReviewScreen(
                                        productId: item.productId,
                                        productName: item.name,
                                        existingReview: existingReview,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    ref.invalidate(myOrdersProvider);
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 18),
                                label: Text(l10n.edit),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppPalette.storePrimary,
                                  side: BorderSide(color: AppPalette.storePrimary),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddReviewScreen(
                                        productId: item.productId,
                                        productName: item.name,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    ref.invalidate(myOrdersProvider);
                                  }
                                },
                                icon: const Icon(Icons.star_outline, size: 18),
                                label: Text(l10n.orderReview),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber[700],
                                  side: BorderSide(color: Colors.amber[700]!),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  )),

                  // Shipping tracking info
                  if ((order.status == OrderStatus.shipped || order.status == OrderStatus.delivered) &&
                      order.trackingNumber != null &&
                      order.trackingNumber!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_shipping, color: Colors.purple[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.orderTrackingInfo,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (order.trackingCompany != null) ...[
                                      Text(
                                        order.trackingCompany!,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      order.trackingNumber!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.purple[700],
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: order.trackingNumber!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.orderTrackingCopied(order.trackingNumber!)),
                                      backgroundColor: Colors.purple,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.copy, color: Colors.purple[700], size: 20),
                                tooltip: l10n.copyTooltip,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Shipping address
                  if (order.shippingAddress != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      l10n.orderDeliveryAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.shippingAddress!.fullAddress,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],

                  // Cancel button
                  if (order.status == OrderStatus.pending || order.status == OrderStatus.processing) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelling ? null : _cancelOrder,
                        icon: _cancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cancel, size: 18),
                        label: Text(l10n.orderCancelTitle),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
