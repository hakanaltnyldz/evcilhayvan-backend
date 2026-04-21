// lib/features/store/presentation/screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../data/order_repository.dart';
import '../../domain/models/order_model.dart';
import 'return_request_screen.dart';
import 'dart:async';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderModel, String>((ref, orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderById(orderId);
});

// file-private alias for internal use
final _orderDetailProvider = orderDetailProvider;

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  StreamSubscription<dynamic>? _orderStatusSub;

  @override
  void initState() {
    super.initState();
    final socketService = ref.read(socketServiceProvider);
    _orderStatusSub = socketService.onOrderStatusUpdated.listen((event) {
      if (mounted && event.orderId == widget.orderId) {
        ref.invalidate(_orderDetailProvider(widget.orderId));
      }
    });
  }

  @override
  void dispose() {
    _orderStatusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(_orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sipariş Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_orderDetailProvider(widget.orderId)),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => _OrderDetailBody(order: order, ref: ref),
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Sipariş yüklenemedi: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_orderDetailProvider(widget.orderId)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.order, required this.ref});

  final OrderModel order;
  final WidgetRef ref;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _cancelling = false;

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return const Color(0xFF40916C);
      case OrderStatus.shipped:
        return const Color(0xFF52B788);
      case OrderStatus.delivered:
        return const Color(0xFF2D6A4F);
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.processing:
        return 'Hazırlanıyor';
      case OrderStatus.shipped:
        return 'Kargoda';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  IconData _statusIcon(OrderStatus status) {
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

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  String _shortId(String id) {
    if (id.length >= 8) return id.substring(id.length - 8).toUpperCase();
    return id.toUpperCase();
  }

  static String? _trackingUrl(String? carrier, String? number) {
    if (number == null || number.isEmpty) return null;
    final n = Uri.encodeComponent(number);
    switch (carrier) {
      case 'Yurtiçi':
        return 'https://www.yurticikargo.com/tr/online-islemler/gonderi-sorgula?code=$n';
      case 'MNG':
        return 'https://www.mngkargo.com.tr/wps/portal/mng/main/mngkanal/bireysel/gonderitakip?siparisNo=$n';
      case 'PTT':
        return 'https://gonderitakip.ptt.gov.tr/Track/Verify?q=$n';
      case 'UPS':
        return 'https://www.ups.com/track?tracknum=$n';
      case 'DHL':
        return 'https://www.dhl.com/tr-tr/home/tracking.html?tracking-id=$n';
      case 'Aras':
        return 'https://www.araskargo.com.tr/pages/kargo-takip';
      case 'Sürat':
        return 'https://www.suratkargo.com.tr/KargoSorgulama/';
      default:
        return 'https://www.google.com/search?q=$n+kargo+takip';
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi İptal Et'),
        content: const Text('Bu siparişi iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);

    try {
      await ApiClient().dio.patch('/api/orders/${widget.order.id}/cancel');
      ref.invalidate(_orderDetailProvider(widget.order.id));
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş iptal edildi.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İptal başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final color = _statusColor(order.status);
    final trackUrl = _trackingUrl(order.trackingCompany, order.trackingNumber);
    final canCancel = order.status == OrderStatus.pending || order.status == OrderStatus.processing;
    final canReturn = order.status == OrderStatus.delivered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID + Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sipariş No', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sipariş ID kopyalandı'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                '#${_shortId(order.id)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(order.status), size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            _statusText(order.status),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sipariş Tarihi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(_formatDate(order.createdAt), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Ödeme', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(order.paymentMethod!, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items
          _SectionTitle(title: 'Ürünler (${order.items.length})'),
          const SizedBox(height: 8),
          ...order.items.map((item) => _OrderItemTile(item: item)),
          const SizedBox(height: 8),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Toplam Tutar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ],
            ),
          ),

          // Shipping address
          if (order.shippingAddress != null && order.shippingAddress!.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle(title: 'Teslimat Adresi'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF40916C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      order.shippingAddress!.fullAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tracking
          if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle(title: 'Kargo Takip'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF40916C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.trackingCompany != null && order.trackingCompany!.isNotEmpty)
                          Text(order.trackingCompany!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(order.trackingNumber!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (trackUrl != null)
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(trackUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Takip Et', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4332),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Notes
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle(title: 'Not'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(order.notes!, style: const TextStyle(fontSize: 14)),
            ),
          ],

          // Cancel button
          if (canCancel) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelOrder,
                icon: _cancelling
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined),
                label: Text(_cancelling ? 'İptal ediliyor...' : 'Siparişi İptal Et'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          // Return button
          if (canReturn) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ReturnRequestScreen(order: order),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(_orderDetailProvider(order.id));
                  }
                },
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('İade Talebi Oluştur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.image != null
                ? Image.network(
                    item.image!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} adet × ₺${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '₺${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D6A4F)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
    );
  }
}
