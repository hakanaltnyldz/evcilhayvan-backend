// lib/features/store/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../../store/domain/models/address_model.dart';
import '../../../store/providers/address_providers.dart';
import '../../../store/providers/cart_providers.dart';
import 'add_address_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  String _paymentMethod = 'credit_card';
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  bool _isLoading = false;
  bool _isApplyingCoupon = false;
  String? _appliedCouponCode;
  double _discountAmount = 0;
  String? _couponError;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _couponError = l10n.checkoutErrCouponEmpty);
      return;
    }

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      final cartState = ref.read(cartProvider);
      final total = cartState.valueOrNull?.total ?? 0;

      final response = await ApiClient().dio.post('/api/coupons/validate', data: {
        'code': code,
        'cartTotal': total,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _appliedCouponCode = code;
          _discountAmount = (data['discountAmount'] as num).toDouble();
          _couponController.clear();
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkoutCouponApplied(_discountAmount.toStringAsFixed(2))),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String errorMessage = l10n.checkoutErrCouponFailed;
      if (e.toString().contains('404')) {
        errorMessage = l10n.checkoutErrCouponInvalid;
      } else if (e.toString().contains('400')) {
        errorMessage = l10n.checkoutErrCouponNotApplicable;
      }
      setState(() => _couponError = errorMessage);
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _discountAmount = 0;
      _couponError = null;
    });
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutErrNoAddress), backgroundColor: Colors.red),
      );
      return;
    }

    if (_paymentMethod == 'credit_card') {
      if (_cardNumberController.text.replaceAll(' ', '').length < 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkoutErrCardNumber), backgroundColor: Colors.red),
        );
        return;
      }
      if (_cardHolderController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkoutErrCardHolder), backgroundColor: Colors.red),
        );
        return;
      }
      if (_expiryController.text.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkoutErrExpiry), backgroundColor: Colors.red),
        );
        return;
      }
      if (_cvvController.text.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkoutErrCvv), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final cartState = ref.read(cartProvider);
      final items = cartState.valueOrNull?.items ?? [];

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkoutErrEmptyCart), backgroundColor: Colors.red),
        );
        return;
      }

      final orderItems = items.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
      }).toList();

      final response = await ApiClient().dio.post('/api/orders', data: {
        'items': orderItems,
        'shippingAddress': {
          'street': _selectedAddress!.street,
          'city': _selectedAddress!.city,
          'state': _selectedAddress!.district,
          'zipCode': _selectedAddress!.postalCode ?? '',
          'country': 'Türkiye',
        },
        'paymentMethod': _paymentMethod,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        if (_appliedCouponCode != null) 'couponCode': _appliedCouponCode,
      });

      if (response.statusCode == 201) {
        // Sepeti temizle
        await ref.read(cartProvider.notifier).clearCart();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.checkoutOrderSuccess,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.checkoutOrderSuccessDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go('/store/orders');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.storePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.checkoutGoToOrders),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkoutOrderError(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartState = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.checkoutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teslimat Adresi
            _buildSectionCard(
              title: l10n.checkoutDeliveryAddress,
              icon: Icons.location_on,
              child: addressesAsync.when(
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return _buildAddAddressButton();
                  }

                  // Varsayılan adresi seç
                  if (_selectedAddress == null) {
                    _selectedAddress = addresses.firstWhere(
                      (a) => a.isDefault,
                      orElse: () => addresses.first,
                    );
                  }

                  return Column(
                    children: [
                      ...addresses.map((address) => _buildAddressOption(address)),
                      const SizedBox(height: 8),
                      _buildAddAddressButton(),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(l10n.checkoutAddressLoadError(e.toString())),
              ),
            ),
            const SizedBox(height: 16),

            // Ödeme Yöntemi
            _buildSectionCard(
              title: l10n.checkoutPaymentMethod,
              icon: Icons.payment,
              child: Column(
                children: [
                  _buildPaymentOption('credit_card', l10n.checkoutCreditCard, Icons.credit_card),
                  _buildPaymentOption('cash', l10n.checkoutCashOnDelivery, Icons.money),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kart Bilgileri
            if (_paymentMethod == 'credit_card') ...[
              _buildSectionCard(
                title: l10n.checkoutCardInfo,
                icon: Icons.credit_card,
                child: Column(
                  children: [
                    TextField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        labelText: l10n.checkoutCardNumber,
                        hintText: '1234 5678 9012 3456',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberFormatter(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cardHolderController,
                      decoration: InputDecoration(
                        labelText: l10n.checkoutCardHolder,
                        hintText: l10n.checkoutCardHolderHint,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expiryController,
                            decoration: InputDecoration(
                              labelText: l10n.checkoutExpiry,
                              hintText: l10n.checkoutExpiryHint,
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryDateFormatter(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cvvController,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Kupon Kodu
            _buildSectionCard(
              title: l10n.checkoutCoupon,
              icon: Icons.local_offer,
              child: _appliedCouponCode != null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _appliedCouponCode!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  l10n.checkoutCouponDiscount(_discountAmount.toStringAsFixed(2)),
                                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeCoupon,
                            icon: const Icon(Icons.close, size: 20),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                decoration: InputDecoration(
                                  hintText: l10n.checkoutCouponHint,
                                  border: const OutlineInputBorder(),
                                  errorText: _couponError,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isApplyingCoupon ? null : _applyCoupon,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.storePrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isApplyingCoupon
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Text(l10n.checkoutApply),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Sipariş Notu
            _buildSectionCard(
              title: l10n.checkoutOrderNote,
              icon: Icons.note,
              child: TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: l10n.checkoutOrderNoteHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Sipariş Özeti
            _buildSectionCard(
              title: l10n.checkoutOrderSummary,
              icon: Icons.receipt_long,
              child: cartState.when(
                data: (cart) {
                  return Column(
                    children: [
                      ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.title} x${item.quantity}',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₺${(item.product.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.checkoutSubtotal, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text('₺${cart.total.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.checkoutShipping, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text(
                            cart.total >= 200 ? l10n.checkoutFreeShipping : '₺29.99',
                            style: TextStyle(
                              color: cart.total >= 200 ? Colors.green : null,
                            ),
                          ),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(l10n.checkoutDiscount, style: const TextStyle(color: Colors.green)),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _appliedCouponCode!,
                                    style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '-₺${_discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.checkoutTotal,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₺${(cart.total + (cart.total >= 200 ? 0 : 29.99) - _discountAmount).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.storePrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(l10n.checkoutCartLoadError(e.toString())),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.storePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.checkoutCompleteOrder,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppPalette.storePrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAddressOption(AddressModel address) {
    final isSelected = _selectedAddress?.id == address.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddress = address),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.storePrimary.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppPalette.storePrimary : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppPalette.storePrimary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.storePrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.checkoutDefaultAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.fullName} • ${address.phone}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAddressScreen()),
        );
        if (result == true) {
          ref.read(addressNotifierProvider.notifier).loadAddresses();
        }
      },
      icon: const Icon(Icons.add),
      label: Text(AppLocalizations.of(context)!.checkoutAddNewAddress),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.storePrimary,
        side: BorderSide(color: AppPalette.storePrimary.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.storePrimary.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppPalette.storePrimary : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppPalette.storePrimary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: isSelected ? AppPalette.storePrimary : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kart numarası formatı: 1234 5678 9012 3456
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Son kullanma tarihi formatı: AA/YY
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}