import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

final _orderTrackingProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, trackingNumber) async {
    final res = await ApiClient().dio.get('/orders/track/$trackingNumber');
    return res.data['order'] as Map<String, dynamic>;
  },
);

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String? initialTrackingNumber;
  const OrderTrackingScreen({super.key, this.initialTrackingNumber});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  late final TextEditingController _ctrl;
  String? _trackingNumber;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTrackingNumber ?? '');
    if (widget.initialTrackingNumber?.isNotEmpty == true) {
      _trackingNumber = widget.initialTrackingNumber;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _statusSteps = ['pending', 'processing', 'shipped', 'delivered'];
  static const _statusLabels = {
    'pending': 'Sipariş Alındı',
    'processing': 'Hazırlanıyor',
    'shipped': 'Kargoda',
    'delivered': 'Teslim Edildi',
    'cancelled': 'İptal Edildi',
  };
  static const _statusIcons = {
    'pending': Icons.receipt_long,
    'processing': Icons.inventory_2,
    'shipped': Icons.local_shipping,
    'delivered': Icons.check_circle,
    'cancelled': Icons.cancel,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Takip'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1B4332),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Takip numaranızı girin (örn. PAT1K2M3X)',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    ),
                    onSubmitted: (v) => setState(() => _trackingNumber = v.trim().toUpperCase()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final v = _ctrl.text.trim().toUpperCase();
                    if (v.isNotEmpty) setState(() => _trackingNumber = v);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sorgula'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _trackingNumber == null
                ? _emptyState()
                : _TrackingResult(trackingNumber: _trackingNumber!),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Takip numaranızı girin', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
}

class _TrackingResult extends ConsumerWidget {
  final String trackingNumber;
  const _TrackingResult({required this.trackingNumber});

  static const _steps = ['pending', 'processing', 'shipped', 'delivered'];
  static const _stepLabels = ['Alındı', 'Hazırlanıyor', 'Kargoda', 'Teslim Edildi'];
  static const _stepIcons = [
    Icons.receipt_long,
    Icons.inventory_2,
    Icons.local_shipping,
    Icons.check_circle,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_orderTrackingProvider(trackingNumber));

    return async.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) {
        String msg = 'Sipariş bulunamadı';
        if (e is DioException) {
          msg = e.response?.data?['message'] ?? msg;
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(msg, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
      data: (order) {
        final status = order['status'] as String? ?? 'pending';
        final tracking = order['trackingNumber'] as String? ?? trackingNumber;
        final carrier = order['carrier'] as String?;
        final isCancelled = status == 'cancelled';
        final currentStep = _steps.indexOf(status);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tracking number card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF52B788)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Takip Numarası', style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F))),
                    const SizedBox(height: 4),
                    Text(tracking,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4332),
                            letterSpacing: 1.5)),
                    if (carrier != null) ...[
                      const SizedBox(height: 4),
                      Text('Kargo: $carrier', style: const TextStyle(color: Color(0xFF2D6A4F))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isCancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text('Sipariş İptal Edildi', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else ...[
                const Text('Sipariş Durumu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                // Step indicator
                ...List.generate(_steps.length, (i) {
                  final isDone = i <= currentStep;
                  final isCurrent = i == currentStep;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? const Color(0xFF2D6A4F) : Colors.grey.shade300,
                            ),
                            child: Icon(_stepIcons[i], color: Colors.white, size: 18),
                          ),
                          if (i < _steps.length - 1)
                            Container(
                              width: 2,
                              height: 32,
                              color: i < currentStep ? const Color(0xFF52B788) : Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _stepLabels[i],
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isDone ? const Color(0xFF1B4332) : Colors.grey,
                            fontSize: isCurrent ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
