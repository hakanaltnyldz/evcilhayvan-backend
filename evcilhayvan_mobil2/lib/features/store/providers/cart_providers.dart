import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/cart_state.dart';
import '../domain/models/product_model.dart';
import '../repositories/cart_repository.dart';
import '../services/cart_service.dart';
import 'dio_provider.dart';

final cartServiceProvider = Provider((ref) => CartService(ref.watch(storeDioProvider)));
final cartRepoProvider = Provider((ref) => CartRepository(ref.watch(cartServiceProvider)));

final cartItemsProvider = FutureProvider<CartState>(
  (ref) => ref.watch(cartRepoProvider).items(),
);

final addToCartProvider = FutureProvider.autoDispose.family<void, String>((ref, productId) async {
  await ref.watch(cartRepoProvider).add(productId);
  ref.invalidate(cartItemsProvider);
});

final updateCartQuantityProvider =
    FutureProvider.autoDispose.family<void, ({String itemId, int quantity})>((ref, payload) async {
  await ref.watch(cartRepoProvider).updateQuantity(payload.itemId, payload.quantity);
  ref.invalidate(cartItemsProvider);
});

final clearCartProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(cartRepoProvider).clear();
  ref.invalidate(cartItemsProvider);
});

final removeFromCartProvider = FutureProvider.autoDispose.family<void, String>((ref, itemId) async {
  await ref.watch(cartRepoProvider).remove(itemId);
  ref.invalidate(cartItemsProvider);
});

// StateNotifier for cart actions (for easy use in product cards)
final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<CartState>>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<AsyncValue<CartState>> {
  final Ref ref;

  CartNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      state = const AsyncValue.loading();
      final cart = await ref.read(cartRepoProvider).items();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(ProductModel product, int quantity) async {
    try {
      await ref.read(cartRepoProvider).add(product.id, quantity: quantity);
      ref.invalidate(cartItemsProvider);
      await _loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await ref.read(cartRepoProvider).remove(itemId);
      ref.invalidate(cartItemsProvider);
      await _loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await ref.read(cartRepoProvider).updateQuantity(itemId, quantity);
      ref.invalidate(cartItemsProvider);
      await _loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await ref.read(cartRepoProvider).clear();
      ref.invalidate(cartItemsProvider);
      await _loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadCart();
  }
}
