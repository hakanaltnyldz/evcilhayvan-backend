import 'package:dio/dio.dart';

import '../domain/models/category_model.dart';
import '../domain/models/product_model.dart';
import '../domain/models/seller_profile_model.dart';

class StoreService {
  StoreService(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> categories() async {
    final res = await _dio.get("/api/store/categories");
    final data = (res.data['categories'] ?? res.data) as List<dynamic>;
    return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProductModel>> products({
    String? category,
    String? q,
    String sort = 'newest',
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 40,
  }) async {
    final res = await _dio.get("/api/store/products", queryParameters: {
      if (category != null) "category": category,
      if (q != null) "q": q,
      "sort": sort,
      if (minPrice != null) "minPrice": minPrice.toInt(),
      if (maxPrice != null) "maxPrice": maxPrice.toInt(),
      "page": page,
      "limit": limit,
    });
    final data = (res.data['products'] ?? res.data) as List<dynamic>;
    return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> product(String id) async {
    final res = await _dio.get("/api/store/products/$id");
    return ProductModel.fromJson(res.data['product'] ?? res.data);
  }

  Future<SellerStoreView> sellerProfile(String userId) async {
    final res = await _dio.get("/api/store/sellers/$userId");
    final profile = SellerProfileModel.fromJson(res.data['profile'] ?? res.data);
    final productsJson = (res.data['products'] as List<dynamic>? ?? const []);
    final products = productsJson
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return SellerStoreView(profile: profile, products: products);
  }
}
