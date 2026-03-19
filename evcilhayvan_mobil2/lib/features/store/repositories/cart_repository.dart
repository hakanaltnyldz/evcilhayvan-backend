import '../domain/models/cart_state.dart';
import '../services/cart_service.dart';

class CartRepository {
  CartRepository(this._service);
  final CartService _service;

  Future<CartState> items() => _service.getCart();
  Future<void> add(String productId, {int quantity = 1}) => _service.add(productId, quantity: quantity);
  Future<void> updateQuantity(String itemId, int quantity) => _service.updateQuantity(itemId, quantity);
  Future<void> clear() => _service.clear();
  Future<void> remove(String itemId) => _service.remove(itemId);
}
