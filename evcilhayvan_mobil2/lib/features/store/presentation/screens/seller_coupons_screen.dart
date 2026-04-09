// lib/features/store/presentation/screens/seller_coupons_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'dart:math';

// ── Providers ──────────────────────────────────────────────────────────────

final sellerCouponsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ApiClient().dio;
  final res = await dio.get('/api/seller/coupons');
  return List<Map<String, dynamic>>.from(res.data['coupons'] ?? []);
});

// ── Screen ─────────────────────────────────────────────────────────────────

class SellerCouponsScreen extends ConsumerStatefulWidget {
  const SellerCouponsScreen({super.key});

  @override
  ConsumerState<SellerCouponsScreen> createState() => _SellerCouponsScreenState();
}

class _SellerCouponsScreenState extends ConsumerState<SellerCouponsScreen> {
  final _dateFmt = DateFormat('dd.MM.yyyy', 'tr');
  bool _showExpired = false;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final prefix = ['PATI', 'PET', 'EVCIL', 'STORE'][rng.nextInt(4)];
    final suffix = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    return '$prefix$suffix';
  }

  void _showCreateDialog() {
    final l10n = AppLocalizations.of(context)!;
    final codeCtrl = TextEditingController(text: _generateCode());
    final descCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minPurchaseCtrl = TextEditingController(text: '0');
    final maxDiscountCtrl = TextEditingController();
    final perUserCtrl = TextEditingController(text: '1');
    final totalLimitCtrl = TextEditingController();
    String discountType = 'percentage';
    DateTime? validFrom = DateTime.now();
    DateTime? validUntil = DateTime.now().add(const Duration(days: 30));
    bool firstOrderOnly = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final dl10n = AppLocalizations.of(ctx)!;
          Future<void> pickDate({required bool isFrom}) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isFrom ? (validFrom ?? DateTime.now()) : (validUntil ?? DateTime.now()),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) {
              setS(() {
                if (isFrom) {
                  validFrom = picked;
                } else {
                  validUntil = picked;
                }
              });
            }
          }

          return AlertDialog(
            title: Text(dl10n.sellerCouponCreateDialogTitle),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code field
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: dl10n.sellerCouponCodeLabel,
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setS(() => codeCtrl.text = _generateCode()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        child: Text(dl10n.sellerCouponRandom, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: dl10n.sellerCouponDescLabel,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Discount type
                  Text(dl10n.sellerCouponTypeLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'percentage', label: Text(dl10n.sellerCouponPercent)),
                      ButtonSegment(value: 'fixed', label: Text(dl10n.sellerCouponFixed)),
                    ],
                    selected: {discountType},
                    onSelectionChanged: (v) => setS(() => discountType = v.first),
                  ),
                  const SizedBox(height: 12),
                  // Value
                  TextFormField(
                    controller: valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: discountType == 'percentage'
                          ? dl10n.sellerCouponRateLabel
                          : dl10n.sellerCouponAmountLabel,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Min purchase
                  TextFormField(
                    controller: minPurchaseCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: dl10n.sellerCouponMinPurchase,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Max discount (only for percentage)
                  if (discountType == 'percentage') ...[
                    TextFormField(
                      controller: maxDiscountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: dl10n.sellerCouponMaxDiscount,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Per user limit
                  TextFormField(
                    controller: perUserCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: dl10n.sellerCouponPerUserLimit,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Total limit
                  TextFormField(
                    controller: totalLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: dl10n.sellerCouponTotalLimit,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => pickDate(isFrom: true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: dl10n.sellerCouponStartDate,
                              isDense: true,
                            ),
                            child: Text(
                              validFrom != null ? _dateFmt.format(validFrom!) : '—',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => pickDate(isFrom: false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: dl10n.sellerCouponEndDate,
                              isDense: true,
                            ),
                            child: Text(
                              validUntil != null ? _dateFmt.format(validUntil!) : '—',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // First order only
                  CheckboxListTile(
                    value: firstOrderOnly,
                    onChanged: (v) => setS(() => firstOrderOnly = v ?? false),
                    title: Text(dl10n.sellerCouponFirstOrderOnly, style: const TextStyle(fontSize: 13)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(dl10n.cancel),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim().toUpperCase();
                        final value = double.tryParse(valueCtrl.text.trim());
                        if (code.isEmpty || value == null || value <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.sellerCouponValidationError)),
                          );
                          return;
                        }
                        setS(() => isSubmitting = true);
                        try {
                          final dio = ApiClient().dio;
                          final body = {
                            'code': code,
                            'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            'discountType': discountType,
                            'discountValue': value,
                            'minPurchaseAmount': double.tryParse(minPurchaseCtrl.text) ?? 0,
                            if (maxDiscountCtrl.text.trim().isNotEmpty)
                              'maxDiscountAmount': double.tryParse(maxDiscountCtrl.text.trim()),
                            'perUserLimit': int.tryParse(perUserCtrl.text) ?? 1,
                            if (totalLimitCtrl.text.trim().isNotEmpty)
                              'totalUsageLimit': int.tryParse(totalLimitCtrl.text.trim()),
                            'validFrom': validFrom?.toIso8601String(),
                            'validUntil': validUntil?.toIso8601String(),
                            'firstOrderOnly': firstOrderOnly,
                          };
                          await dio.post('/api/seller/coupons', data: body);
                          if (ctx.mounted) Navigator.pop(ctx);
                          ref.invalidate(sellerCouponsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.sellerCouponCreated(code))),
                            );
                          }
                        } catch (e) {
                          setS(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.sellerCouponCreateFailed)),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.sellerCouponCreate),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(String couponId, bool current) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dio = ApiClient().dio;
      await dio.patch('/api/seller/coupons/$couponId/toggle');
      ref.invalidate(sellerCouponsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sellerCouponToggleFailed)),
        );
      }
    }
  }

  Future<void> _deleteCoupon(String couponId, String code) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dl10n.sellerCouponDeleteTitle),
          content: Text(dl10n.sellerCouponDeleteConfirm(code)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(dl10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl10n.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      final dio = ApiClient().dio;
      await dio.delete('/api/seller/coupons/$couponId');
      ref.invalidate(sellerCouponsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sellerCouponDeleted(code))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sellerCouponDeleteFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final couponsAsync = ref.watch(sellerCouponsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sellerCouponManagementTitle),
        actions: [
          IconButton(
            icon: Icon(_showExpired ? Icons.visibility : Icons.visibility_off_outlined),
            tooltip: _showExpired ? l10n.sellerCouponHideExpired : l10n.sellerCouponShowExpired,
            onPressed: () => setState(() => _showExpired = !_showExpired),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.sellerCouponNew),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(l10n.sellerCouponLoadError),
              TextButton(
                onPressed: () => ref.invalidate(sellerCouponsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (coupons) {
          final filtered = coupons.where((c) {
            final until = c['validUntil'] != null ? DateTime.tryParse(c['validUntil']) : null;
            final expired = until != null && until.isBefore(now);
            return _showExpired || !expired;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.discount_outlined, size: 64, color: AppPalette.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(l10n.sellerCouponEmptyTitle),
                  const SizedBox(height: 8),
                  Text(l10n.sellerCouponEmptySubtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerCouponsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final couponId = c['_id'] as String? ?? '';
                final code = c['code'] as String? ?? '';
                final isActive = c['isActive'] == true;
                final isPercent = c['discountType'] == 'percentage';
                final value = c['discountValue'];
                final label = isPercent ? '%$value' : '₺$value';
                final until = c['validUntil'] != null
                    ? _dateFmt.format(DateTime.tryParse(c['validUntil']) ?? now)
                    : '—';
                final expired = c['validUntil'] != null &&
                    (DateTime.tryParse(c['validUntil'])?.isBefore(now) ?? false);
                final usageCount = c['usageCount'] ?? 0;
                final totalLimit = c['totalUsageLimit'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: expired
                                    ? Colors.grey.withOpacity(0.15)
                                    : (isActive
                                        ? AppPalette.primary.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                  color: expired
                                      ? Colors.grey
                                      : (isActive ? AppPalette.primary : Colors.orange),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPercent
                                    ? const Color(0xFF2D6A4F).withOpacity(0.1)
                                    : const Color(0xFFFF7A59).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPercent ? const Color(0xFF2D6A4F) : const Color(0xFFFF7A59),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Toggle switch
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isActive && !expired,
                                onChanged: expired ? null : (v) => _toggleActive(couponId, isActive),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _Chip(icon: Icons.calendar_today_outlined, label: l10n.sellerCouponValidUntil(until)),
                            _Chip(
                              icon: Icons.bar_chart,
                              label: totalLimit != null
                                  ? l10n.sellerCouponUsageLimited(usageCount.toString(), totalLimit.toString())
                                  : l10n.sellerCouponUsage(usageCount.toString()),
                            ),
                            if (c['firstOrderOnly'] == true)
                              _Chip(icon: Icons.star_outline, label: l10n.sellerCouponFirstOrderLabel),
                            if (expired)
                              _Chip(
                                icon: Icons.timer_off_outlined,
                                label: l10n.sellerCouponExpiredLabel,
                                color: Colors.red,
                              ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _deleteCoupon(couponId, code),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              label: Text(l10n.delete, style: const TextStyle(color: Colors.red, fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }
}
