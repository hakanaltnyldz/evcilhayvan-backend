import 'package:flutter_riverpod/flutter_riverpod.dart';

const _unset = Object();

class CheckoutCouponState {
  final String? code;
  final double discountAmount;
  final double validatedSubtotal;
  final bool isApplying;
  final String? error;

  const CheckoutCouponState({
    this.code,
    this.discountAmount = 0,
    this.validatedSubtotal = 0,
    this.isApplying = false,
    this.error,
  });

  bool get hasCoupon => code != null && code!.trim().isNotEmpty;

  CheckoutCouponState copyWith({
    Object? code = _unset,
    double? discountAmount,
    double? validatedSubtotal,
    bool? isApplying,
    Object? error = _unset,
  }) {
    return CheckoutCouponState(
      code: identical(code, _unset) ? this.code : code as String?,
      discountAmount: discountAmount ?? this.discountAmount,
      validatedSubtotal: validatedSubtotal ?? this.validatedSubtotal,
      isApplying: isApplying ?? this.isApplying,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class CheckoutCouponNotifier extends StateNotifier<CheckoutCouponState> {
  CheckoutCouponNotifier() : super(const CheckoutCouponState());

  void setApplying(bool isApplying) {
    state = state.copyWith(isApplying: isApplying);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void apply({
    required String code,
    required double discountAmount,
    required double validatedSubtotal,
  }) {
    state = CheckoutCouponState(
      code: code,
      discountAmount: discountAmount,
      validatedSubtotal: validatedSubtotal,
      isApplying: false,
      error: null,
    );
  }

  void clear() {
    state = const CheckoutCouponState();
  }
}

final checkoutCouponProvider =
    StateNotifierProvider.autoDispose<CheckoutCouponNotifier, CheckoutCouponState>(
      (_) => CheckoutCouponNotifier(),
    );
