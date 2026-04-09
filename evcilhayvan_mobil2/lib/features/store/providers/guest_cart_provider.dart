import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestCartItem {
  final String productId;
  final String title;
  final double price;
  int quantity;
  final String? imageUrl;
  final String? variantName;
  final String? variantLabel;

  GuestCartItem({
    required this.productId,
    required this.title,
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.variantName,
    this.variantLabel,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'variantName': variantName,
        'variantLabel': variantLabel,
      };

  factory GuestCartItem.fromJson(Map<String, dynamic> json) => GuestCartItem(
        productId: json['productId'] as String,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
        imageUrl: json['imageUrl'] as String?,
        variantName: json['variantName'] as String?,
        variantLabel: json['variantLabel'] as String?,
      );

  double get total => price * quantity;
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
        state = list.map((e) => GuestCartItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void add(GuestCartItem item) {
    final idx = state.indexWhere((e) =>
        e.productId == item.productId &&
        e.variantName == item.variantName &&
        e.variantLabel == item.variantLabel);
    if (idx >= 0) {
      final updated = List<GuestCartItem>.from(state);
      updated[idx].quantity += item.quantity;
      state = updated;
    } else {
      state = [...state, item];
    }
    _save();
  }

  void remove(String productId, {String? variantName, String? variantLabel}) {
    state = state.where((e) =>
        !(e.productId == productId &&
          e.variantName == variantName &&
          e.variantLabel == variantLabel)).toList();
    _save();
  }

  void updateQuantity(String productId, int quantity, {String? variantName, String? variantLabel}) {
    final updated = List<GuestCartItem>.from(state);
    final idx = updated.indexWhere((e) =>
        e.productId == productId &&
        e.variantName == variantName &&
        e.variantLabel == variantLabel);
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

final guestCartProvider = StateNotifierProvider<GuestCartNotifier, List<GuestCartItem>>(
  (_) => GuestCartNotifier(),
);
