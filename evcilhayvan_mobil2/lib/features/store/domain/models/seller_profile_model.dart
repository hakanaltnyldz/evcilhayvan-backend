import 'product_model.dart';

class SellerProfileModel {
  final String id;
  final String storeName;
  final String? storeDescription;
  final String? storeLogo;
  final String userId;

  SellerProfileModel({
    required this.id,
    required this.storeName,
    required this.userId,
    this.storeDescription,
    this.storeLogo,
  });

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    return SellerProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      storeName: json['storeName'] ?? '',
      storeDescription: json['storeDescription'] as String?,
      storeLogo: json['storeLogo'] as String?,
      userId: (json['user'] is Map<String, dynamic>)
          ? (json['user'] as Map<String, dynamic>)['_id'] ?? ''
          : json['user']?.toString() ?? '',
    );
  }
}

class SellerStoreView {
  final SellerProfileModel profile;
  final List<ProductModel> products;

  SellerStoreView({required this.profile, required this.products});
}
