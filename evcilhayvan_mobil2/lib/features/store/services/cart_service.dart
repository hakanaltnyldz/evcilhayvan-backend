import 'package:dio/dio.dart';

import '../domain/models/cart_item_model.dart';
import '../domain/models/cart_state.dart';

class CartService {
  CartService(this._dio);
  final Dio _dio;

  Future<CartState> getCart() async {
    final res = await _dio.get("/api/cart");
    final data = (res.data is Map<String, dynamic>)
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{"items": res.data};
    return CartState.fromJson(data);
  }

  Future<void> add(String productId, {int quantity = 1}) async {
    await _dio.post("/api/cart/items", data: {"productId": productId, "quantity": quantity});
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    await _dio.patch("/api/cart/items/$itemId", data: {"qty": quantity});
  }

  Future<void> clear() async {
    await _dio.post("/api/cart/clear");
  }

  Future<void> remove(String itemId) async {
    await _dio.delete("/api/cart/items/$itemId");
  }
}
