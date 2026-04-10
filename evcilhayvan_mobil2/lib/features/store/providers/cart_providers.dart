import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/repositories/auth_repository.dart';
import '../domain/models/cart_state.dart';
import '../domain/models/product_model.dart';
import '../repositories/cart_repository.dart';
import '../services/cart_service.dart';
import 'dio_provider.dart';

const _emptyCartState = CartState(items: [], total: 0, itemCount: 0);

final cartServiceProvider = Provider(
  (ref) => CartService(ref.watch(storeDioProvider)),
);
final cartRepoProvider = Provider(
  (ref) => CartRepository(ref.watch(cartServiceProvider)),
);

final cartItemsProvider = FutureProvider<CartState>((ref) async {
  final currentUser = ref.watch(authProvider);
  if (currentUser == null) return _emptyCartState;
  return ref.watch(cartRepoProvider).items();
});

final addToCartProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  productId,
) async {
  await ref.watch(cartRepoProvider).add(productId);
  ref.invalidate(cartItemsProvider);
});

final updateCartQuantityProvider = FutureProvider.autoDispose
    .family<void, ({String itemId, int quantity})>((ref, payload) async {
      await ref
          .watch(cartRepoProvider)
          .updateQuantity(payload.itemId, payload.quantity);
      ref.invalidate(cartItemsProvider);
    });

final clearCartProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(cartRepoProvider).clear();
  ref.invalidate(cartItemsProvider);
});

final removeFromCartProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  itemId,
) async {
  await ref.watch(cartRepoProvider).remove(itemId);
  ref.invalidate(cartItemsProvider);
});

// StateNotifier for cart actions (for easy use in product cards)
final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<CartState>>(
  (ref) {
    final currentUser = ref.watch(authProvider);
    return CartNotifier(ref, currentUser?.id);
  },
);

class CartNotifier extends StateNotifier<AsyncValue<CartState>> {
  final Ref ref;
  final String? _userId;

  CartNotifier(this.ref, this._userId) : super(const AsyncValue.loading()) {
    if (_userId == null) {
      state = const AsyncValue.data(_emptyCartState);
    } else {
      _loadCart();
    }
  }

  Future<void> _loadCart() async {
    if (_userId == null) {
      state = const AsyncValue.data(_emptyCartState);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final cart = await ref.read(cartRepoProvider).items();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _ensureAuthenticated() {
    if (_userId == null) {
      throw StateError('Sepet islemleri icin giris yapmalisiniz');
    }
  }

  Future<void> addItem(ProductModel product, int quantity) async {
    _ensureAuthenticated();
    try {
      await ref.read(cartRepoProvider).add(product.id, quantity: quantity);
      await _loadCart();
      ref.invalidate(cartItemsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    _ensureAuthenticated();
    try {
      await ref.read(cartRepoProvider).remove(itemId);
      await _loadCart();
      ref.invalidate(cartItemsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    _ensureAuthenticated();
    try {
      await ref.read(cartRepoProvider).updateQuantity(itemId, quantity);
      await _loadCart();
      ref.invalidate(cartItemsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    _ensureAuthenticated();
    try {
      await ref.read(cartRepoProvider).clear();
      await _loadCart();
      ref.invalidate(cartItemsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadCart();
  }
}
