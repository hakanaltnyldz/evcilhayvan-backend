import 'product_model.dart';
import 'selected_variant_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final double unitPrice;
  final List<SelectedVariantModel> selectedVariants;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.selectedVariants = const [],
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson =
        (json['product'] ?? json['productId']) as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final product = ProductModel.fromJson(productJson);
    final selectedVariants = SelectedVariantModel.fromJsonList(
      json['selectedVariants'],
    );
    final normalizedVariants = selectedVariants.isNotEmpty
        ? selectedVariants
        : SelectedVariantModel.fromLegacy(
            variantName: json['variantName'] as String?,
            variantLabel: json['variantLabel'] as String?,
          );

    return CartItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      product: product,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice:
          (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          product.price,
      selectedVariants: normalizedVariants,
    );
  }

  String get productId => product.id;
  double get total => unitPrice * quantity;
  String? get variantName =>
      selectedVariants.isNotEmpty ? selectedVariants.first.name : null;
  String? get variantLabel =>
      selectedVariants.isNotEmpty ? selectedVariants.first.label : null;
  String get selectedVariantsLabel =>
      selectedVariants.map((variant) => variant.displayText).join(', ');
}
