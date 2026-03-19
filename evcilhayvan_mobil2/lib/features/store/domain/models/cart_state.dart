import 'cart_item_model.dart';

class CartState {
  final List<CartItemModel> items;
  final double total;
  final int itemCount;

  const CartState({
    required this.items,
    required this.total,
    required this.itemCount,
  });

  factory CartState.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    final summary = (json['summary'] as Map<String, dynamic>?) ?? const {};
    return CartState(
      items: itemsJson.whereType<Map<String, dynamic>>().map(CartItemModel.fromJson).toList(),
      total: (summary['total'] as num?)?.toDouble() ?? 0,
      itemCount: (summary['itemCount'] as num?)?.toInt() ?? itemsJson.length,
    );
  }
}
