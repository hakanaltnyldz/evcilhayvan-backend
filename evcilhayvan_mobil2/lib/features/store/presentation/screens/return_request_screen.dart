// lib/features/store/presentation/screens/return_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';

const _returnReasons = [
  'Yanlış ürün gönderildi',
  'Hasarlı / kırık geldi',
  'Ürün açıklamayla uyuşmuyor',
  'Beklentimi karşılamadı',
  'Diğer',
];

class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({super.key, required this.order});

  final OrderModel order;

  @override
  ConsumerState<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiClient().dio.post(
        '/api/orders/${widget.order.id}/return-request',
        data: {
          'reason': _selectedReason,
          if (_descriptionCtrl.text.trim().isNotEmpty)
            'description': _descriptionCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İade talebiniz alındı. Ekibimiz en kısa sürede dönüş yapacak.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İade talebi gönderilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('İade Talebi', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sipariş özet kartı
              _OrderSummaryCard(order: widget.order),
              const SizedBox(height: 20),

              // İade nedeni
              Text(
                'İade Nedeni',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedReason == null
                        ? Colors.grey.shade300
                        : AppPalette.storePrimary.withOpacity(0.5),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedReason,
                  hint: const Text('Bir neden seçin'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  items: _returnReasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReason = v),
                  validator: (v) => v == null ? 'Lütfen bir neden seçin' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Açıklama
              Text(
                'Açıklama (opsiyonel)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Daha fazla detay ekleyin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: context.cardColor,
                ),
              ),
              const SizedBox(height: 8),

              // Bilgi notu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'İade talebi oluşturduktan sonra ekibimiz 1-3 iş günü içinde size dönüş yapacak. Onay durumunda ürünü orijinal ambalajında kargolayabilirsiniz.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gönder butonu
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.storePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.assignment_return_outlined),
                  label: Text(
                    _isSubmitting ? 'Gönderiliyor...' : 'İade Talebi Gönder',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.storePrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_outlined, color: AppPalette.storePrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş #${order.id.length >= 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₺${order.totalAmount.toStringAsFixed(2)} · ${order.items.length} ürün',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Teslim Edildi',
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...order.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: AppPalette.storePrimary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )),
            if (order.items.length > 3)
              Text(
                '+${order.items.length - 3} ürün daha',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
          ],
        ],
      ),
    );
  }
}
