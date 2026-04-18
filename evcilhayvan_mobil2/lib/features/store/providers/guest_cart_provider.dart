import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/selected_variant_model.dart';

class GuestCartItem {
  final String productId;
  final String title;
  final double price;
  int quantity;
  final String? imageUrl;
  final List<SelectedVariantModel> selectedVariants;

  GuestCartItem({
    required this.productId,
    required this.title,
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.selectedVariants = const [],
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
    'selectedVariants': selectedVariants
        .map((variant) => variant.toJson())
        .toList(),
    'variantName': variantName,
    'variantLabel': variantLabel,
  };

  factory GuestCartItem.fromJson(Map<String, dynamic> json) {
    final selectedVariants = SelectedVariantModel.fromJsonList(
      json['selectedVariants'],
    );
    final normalizedVariants = selectedVariants.isNotEmpty
        ? selectedVariants
        : SelectedVariantModel.fromLegacy(
            variantName: json['variantName'] as String?,
            variantLabel: json['variantLabel'] as String?,
          );
    return GuestCartItem(
      productId: json['productId'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      selectedVariants: normalizedVariants,
    );
  }

  double get total => price * quantity;
  String get selectedVariantsSignature =>
      SelectedVariantModel.signatureOf(selectedVariants);
  String? get variantName =>
      selectedVariants.isNotEmpty ? selectedVariants.first.name : null;
  String? get variantLabel =>
      selectedVariants.isNotEmpty ? selectedVariants.first.label : null;
  String get selectedVariantsLabel =>
      selectedVariants.map((variant) => variant.displayText).join(', ');
}

class GuestCartNotifier extends StateNotifier<List<GuestCartItem>> {
  static const _key = 'guest_cart';

  GuestCartNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        state = list
            .map((e) => GuestCartItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void add(GuestCartItem item) {
    final idx = state.indexWhere(
      (e) =>
          e.productId == item.productId &&
          e.selectedVariantsSignature == item.selectedVariantsSignature,
    );
    if (idx >= 0) {
      final updated = List<GuestCartItem>.from(state);
      updated[idx].quantity += item.quantity;
      state = updated;
    } else {
      state = [...state, item];
    }
    _save();
  }

  void remove(
    String productId, {
    List<SelectedVariantModel> selectedVariants = const [],
  }) {
    final signature = SelectedVariantModel.signatureOf(selectedVariants);
    state = state
        .where(
          (e) =>
              !(e.productId == productId &&
                  e.selectedVariantsSignature == signature),
        )
        .toList();
    _save();
  }

  void updateQuantity(
    String productId,
    int quantity, {
    List<SelectedVariantModel> selectedVariants = const [],
  }) {
    final updated = List<GuestCartItem>.from(state);
    final signature = SelectedVariantModel.signatureOf(selectedVariants);
    final idx = updated.indexWhere(
      (e) =>
          e.productId == productId && e.selectedVariantsSignature == signature,
    );
    if (idx >= 0) {
      if (quantity <= 0) {
        updated.removeAt(idx);
      } else {
        updated[idx].quantity = quantity;
      }
      state = updated;
      _save();
    }
  }

  void clear() {
    state = [];
    _save();
  }

  double get total => state.fold(0, (sum, e) => sum + e.total);
  int get itemCount => state.fold(0, (sum, e) => sum + e.quantity);
}

final guestCartProvider =
    StateNotifierProvider<GuestCartNotifier, List<GuestCartItem>>(
      (_) => GuestCartNotifier(),
    );
