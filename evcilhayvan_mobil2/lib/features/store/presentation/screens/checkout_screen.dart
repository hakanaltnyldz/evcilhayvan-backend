// lib/features/store/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

import 'package:dio/dio.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../../store/domain/models/address_model.dart';
import '../../../store/providers/address_providers.dart';
import '../../../store/providers/cart_providers.dart';
import '../../../store/providers/checkout_coupon_provider.dart';
import '../../../store/providers/guest_cart_provider.dart';
import 'add_address_screen.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';

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

  // Misafir formu
  final _guestNameCtrl = TextEditingController();
  final _guestPhoneCtrl = TextEditingController();
  final _guestEmailCtrl = TextEditingController();
  final _guestNationalIdCtrl = TextEditingController();
  final _guestCityCtrl = TextEditingController();
  final _guestDistrictCtrl = TextEditingController();
  final _guestStreetCtrl = TextEditingController();

  // ── Kart Validasyonu ─────────────────────────────────────────────────────

  /// Tüm kart alanlarını validate eder. Hata varsa mesajı döner, geçerliyse null.
  String? _validateCard(AppLocalizations l10n) {
    final raw = _cardNumberController.text.replaceAll(' ', '');
    if (raw.length != 16 || !RegExp(r'^\d{16}$').hasMatch(raw)) {
      return l10n.checkoutErrCardNumber;
    }
    if (!_luhn(raw)) {
      return l10n.checkoutErrCardNumberInvalid;
    }
    final holder = _cardHolderController.text.trim();
    if (holder.isEmpty ||
        !RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(holder)) {
      return l10n.checkoutErrCardHolder;
    }
    final expiry = _expiryController.text;
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      return l10n.checkoutErrExpiry;
    }
    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]) + 2000;
    if (month < 1 || month > 12) return l10n.checkoutErrExpiry;
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return l10n.checkoutErrExpiryPast;
    }
    final cvv = _cvvController.text;
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      return l10n.checkoutErrCvv;
    }
    return null;
  }

  /// Luhn algoritması — kart numarası checksum kontrolü.
  bool _luhn(String number) {
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  @override
  void initState() {
    super.initState();
    // Checkout açılınca sepeti backend'den taze yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cartProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _guestNameCtrl.dispose();
    _guestPhoneCtrl.dispose();
    _guestEmailCtrl.dispose();
    _guestNationalIdCtrl.dispose();
    _guestCityCtrl.dispose();
    _guestDistrictCtrl.dispose();
    _guestStreetCtrl.dispose();
    super.dispose();
  }

  double _guestSubtotal(List<GuestCartItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.total);
  }

  double _currentSubtotal(bool isGuest) {
    if (isGuest) {
      return _guestSubtotal(ref.read(guestCartProvider));
    }
    return ref.read(cartProvider).valueOrNull?.total ?? 0;
  }

  Future<void> _applyCoupon({
    String? overrideCode,
    bool silent = false,
    bool clearInput = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final code = (overrideCode ?? _couponController.text).trim().toUpperCase();
    if (code.isEmpty) {
      ref
          .read(checkoutCouponProvider.notifier)
          .setError(l10n.checkoutErrCouponEmpty);
      return;
    }

    ref.read(checkoutCouponProvider.notifier)
      ..setApplying(true)
      ..setError(null);

    try {
      final isGuest = ref.read(authProvider) == null;
      if (isGuest) {
        ref.read(checkoutCouponProvider.notifier)
          ..setApplying(false)
          ..setError(l10n.checkoutErrCouponLoginRequired);
        return;
      }
      final total = _currentSubtotal(isGuest);
      if (total == 0) {
        ref.read(checkoutCouponProvider.notifier)
          ..setApplying(false)
          ..setError(l10n.checkoutErrCartTotalUnavailable);
        return;
      }

      final response = await ApiClient().dio.post(
        '/api/coupons/validate',
        data: {'code': code, 'cartTotal': total},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final discountAmount = (data['discountAmount'] as num).toDouble();
        ref
            .read(checkoutCouponProvider.notifier)
            .apply(
              code: code,
              discountAmount: discountAmount,
              validatedSubtotal: total,
            );
        if (clearInput) {
          _couponController.clear();
        }
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.checkoutCouponApplied(discountAmount.toStringAsFixed(2)),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on DioException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      final statusCode = e.response?.statusCode;
      final apiCode = ApiError.fromDio(e).code;
      String errorMessage = l10n.checkoutErrCouponFailed;
      if (apiCode == 'coupon_expired' || statusCode == 410) {
        errorMessage = l10n.checkoutErrCouponExpired;
      } else if (apiCode == 'usage_limit_exceeded' || statusCode == 409) {
        errorMessage = l10n.checkoutErrCouponUsageLimit;
      } else if (statusCode == 404 || apiCode == 'not_found') {
        errorMessage = l10n.checkoutErrCouponInvalid;
      } else if (statusCode == 400) {
        errorMessage = l10n.checkoutErrCouponNotApplicable;
      }
      final notifier = ref.read(checkoutCouponProvider.notifier);
      notifier
        ..setApplying(false)
        ..setError(errorMessage);
      if (silent) {
        notifier.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkoutCouponRemovedCartChanged),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      final notifier = ref.read(checkoutCouponProvider.notifier);
      notifier
        ..setApplying(false)
        ..setError(l10n.checkoutErrCouponFailed);
      if (silent) {
        notifier.clear();
      }
    } finally {
      ref.read(checkoutCouponProvider.notifier).setApplying(false);
    }
  }

  void _removeCoupon() {
    ref.read(checkoutCouponProvider.notifier).clear();
  }

  void _syncCouponWithCartIfNeeded({
    required CheckoutCouponState couponState,
    required double subtotal,
  }) {
    if (ref.read(authProvider) == null) {
      if (couponState.hasCoupon) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(checkoutCouponProvider.notifier).clear();
        });
      }
      return;
    }

    if (!couponState.hasCoupon || couponState.isApplying) return;

    if (subtotal <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(checkoutCouponProvider.notifier).clear();
      });
      return;
    }

    if ((couponState.validatedSubtotal - subtotal).abs() < 0.01) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyCoupon(
        overrideCode: couponState.code,
        silent: true,
        clearInput: false,
      );
    });
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final isGuest = ref.read(authProvider) == null;
    final couponState = ref.read(checkoutCouponProvider);

    // Misafir validasyon
    if (isGuest) {
      final name = _guestNameCtrl.text.trim();
      final phone = _guestPhoneCtrl.text.trim();
      final email = _guestEmailCtrl.text.trim();
      final tc = _guestNationalIdCtrl.text.trim();
      if (name.isEmpty || phone.isEmpty || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkoutErrGuestRequired),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (tc.isNotEmpty &&
          (tc.length != 11 || !RegExp(r'^\d{11}$').hasMatch(tc))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkoutErrGuestNationalId),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkoutErrNoAddress),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_paymentMethod == 'credit_card') {
      final cardError = _validateCard(l10n);
      if (cardError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cardError), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> orderItems;
      if (isGuest) {
        final guestItems = ref.read(guestCartProvider);
        if (guestItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkoutErrEmptyCart),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        orderItems = guestItems
            .map(
              (item) => {
                'productId': item.productId,
                'quantity': item.quantity,
                if (item.selectedVariants.isNotEmpty)
                  'selectedVariants': item.selectedVariants
                      .map((variant) => variant.toJson())
                      .toList(),
              },
            )
            .toList();
      } else {
        final cartState = ref.read(cartProvider);
        final items = cartState.valueOrNull?.items ?? [];
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkoutErrEmptyCart),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        orderItems = items
            .map(
              (item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                if (item.selectedVariants.isNotEmpty)
                  'selectedVariants': item.selectedVariants
                      .map((variant) => variant.toJson())
                      .toList(),
              },
            )
            .toList();
      }

      final Map<String, dynamic> body = {
        'items': orderItems,
        'paymentMethod': _paymentMethod,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        if (couponState.hasCoupon && !isGuest) 'couponCode': couponState.code,
      };

      if (isGuest) {
        body['guestInfo'] = {
          'name': _guestNameCtrl.text.trim(),
          'phone': _guestPhoneCtrl.text.trim(),
          'email': _guestEmailCtrl.text.trim(),
          if (_guestNationalIdCtrl.text.trim().isNotEmpty)
            'nationalId': _guestNationalIdCtrl.text.trim(),
          'address': {
            'city': _guestCityCtrl.text.trim(),
            'district': _guestDistrictCtrl.text.trim(),
            'street': _guestStreetCtrl.text.trim(),
          },
        };
      } else {
        body['shippingAddress'] = {
          'street': _selectedAddress!.street,
          'city': _selectedAddress!.city,
          'state': _selectedAddress!.district,
          'zipCode': _selectedAddress!.postalCode ?? '',
          'country': 'Türkiye',
        };
      }

      final response = await ApiClient().dio.post('/api/orders', data: body);

      if (response.statusCode == 201) {
        final order = response.data['order'] as Map<String, dynamic>;
        final trackingNumber = order['trackingNumber'] as String?;

        if (isGuest) {
          ref.read(guestCartProvider.notifier).clear();
        } else {
          await ref.read(cartProvider.notifier).clearCart();
        }
        ref.read(checkoutCouponProvider.notifier).clear();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.checkoutOrderSuccess,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.checkoutOrderSuccessDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (trackingNumber != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F3DC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.checkoutTrackingNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2D6A4F),
                            ),
                          ),
                          Text(
                            trackingNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1B4332),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGuest)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.checkoutTrackingEmailSent(
                            _guestEmailCtrl.text.trim(),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ],
              ),
              actions: [
                if (trackingNumber != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.pushNamed(
                          'order-tracking',
                          queryParameters: {'t': trackingNumber},
                        );
                      },
                      child: Text(l10n.checkoutTrackOrder),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (isGuest) {
                        context.go('/store');
                      } else {
                        context.goNamed('my-orders');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.storePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isGuest
                          ? l10n.checkoutContinueShopping
                          : l10n.checkoutGoToOrders,
                    ),
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
          SnackBar(
            content: Text(l10n.checkoutOrderError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGuestForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: l10n.checkoutGuestPersonalInfo,
          icon: Icons.person,
          child: Column(
            children: [
              TextField(
                controller: _guestNameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.checkoutGuestName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.checkoutGuestPhone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.checkoutGuestEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestNationalIdCtrl,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: l10n.checkoutGuestNationalId,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  helperText: l10n.checkoutGuestNationalIdHelper,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionCard(
          title: l10n.checkoutDeliveryAddress,
          icon: Icons.location_on,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _guestCityCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.checkoutGuestCity,
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _guestDistrictCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.checkoutGuestDistrict,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestStreetCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.checkoutGuestStreet,
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestOrderSummary(
    AppLocalizations l10n,
    List<GuestCartItem> guestItems, {
    String? couponCode,
    double discountAmount = 0,
  }) {
    final guestTotal = guestItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    final shippingAmount = guestTotal >= 200 ? 0.0 : 29.99;
    final finalTotal = (guestTotal + shippingAmount - discountAmount).clamp(
      0,
      double.infinity,
    );

    return Column(
      children: [
        ...guestItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.title} x${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.selectedVariants.isNotEmpty)
                        Text(
                          item.selectedVariantsLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\u20BA${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.checkoutSubtotal,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text('\u20BA${guestTotal.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.checkoutShipping,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              guestTotal >= 200 ? l10n.checkoutFreeShipping : '\u20BA29.99',
              style: TextStyle(color: guestTotal >= 200 ? Colors.green : null),
            ),
          ],
        ),
        if (discountAmount > 0 && couponCode != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    l10n.checkoutDiscount,
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      couponCode,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '-\u20BA${discountAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
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
              '\u20BA${finalTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.storePrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGuest = ref.watch(authProvider) == null;
    final cartState = ref.watch(cartProvider);
    final couponState = ref.watch(checkoutCouponProvider);
    final guestItems = ref.watch(guestCartProvider);
    final addressesAsync = ref.watch(addressNotifierProvider);
    final currentSubtotal = isGuest
        ? _guestSubtotal(guestItems)
        : cartState.valueOrNull?.total ?? 0;

    _syncCouponWithCartIfNeeded(
      couponState: couponState,
      subtotal: currentSubtotal,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.checkoutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Misafir formu veya adres seçimi
            if (isGuest)
              _buildGuestForm()
            else
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
                        ...addresses.map(
                          (address) => _buildAddressOption(address),
                        ),
                        const SizedBox(height: 8),
                        _buildAddAddressButton(),
                      ],
                    );
                  },
                  loading: () => const Center(child: PawLoading()),
                  error: (e, _) =>
                      Text(l10n.checkoutAddressLoadError(e.toString())),
                ),
              ),
            const SizedBox(height: 16),

            // Ödeme Yöntemi
            _buildSectionCard(
              title: l10n.checkoutPaymentMethod,
              icon: Icons.payment,
              child: Column(
                children: [
                  _buildPaymentOption(
                    'credit_card',
                    l10n.checkoutCreditCard,
                    Icons.credit_card,
                  ),
                  _buildPaymentOption(
                    'cash',
                    l10n.checkoutCashOnDelivery,
                    Icons.money,
                  ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uygulanan kupon göstergesi
                  if (couponState.hasCoupon) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  couponState.code!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.checkoutCouponDiscount(
                                    couponState.discountAmount.toStringAsFixed(
                                      2,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeCoupon,
                            icon: const Icon(Icons.close, size: 20),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Kupon giriş alanı
                  if (!couponState.hasCoupon) ...[
                    TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: l10n.checkoutCouponHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppPalette.storePrimary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        errorText: couponState.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: couponState.isApplying
                            ? null
                            : () => _applyCoupon(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52B788),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: couponState.isApplying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.checkoutApply,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
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
              child: isGuest
                  ? _buildGuestOrderSummary(
                      l10n,
                      guestItems,
                      couponCode: couponState.code,
                      discountAmount: couponState.discountAmount,
                    )
                  : cartState.when(
                      data: (cart) {
                        return Column(
                          children: [
                            ...cart.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item.product.title} x${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.selectedVariants.isNotEmpty)
                                            Text(
                                              item.selectedVariantsLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\u20BA${item.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.checkoutSubtotal,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text('\u20BA${cart.total.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.checkoutShipping,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  cart.total >= 200
                                      ? l10n.checkoutFreeShipping
                                      : '\u20BA29.99',
                                  style: TextStyle(
                                    color: cart.total >= 200
                                        ? Colors.green
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            if (couponState.discountAmount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        l10n.checkoutDiscount,
                                        style: const TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          couponState.code!,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '-\u20BA${couponState.discountAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\u20BA${(cart.total + (cart.total >= 200 ? 0 : 29.99) - couponState.discountAmount).toStringAsFixed(2)}',
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
                      loading: () => const Center(child: PawLoading()),
                      error: (e, _) =>
                          Text(l10n.checkoutCartLoadError(e.toString())),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
          color: isSelected
              ? AppPalette.storePrimary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppPalette.storePrimary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? AppPalette.storePrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.storePrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.checkoutDefaultAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.fullName} • ${address.phone}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
          color: isSelected
              ? AppPalette.storePrimary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppPalette.storePrimary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? AppPalette.storePrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected
                  ? AppPalette.storePrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
