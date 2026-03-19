import 'package:dio/dio.dart';

import '../domain/models/product_model.dart';

class ProductService {
  ProductService(this._dio);
  final Dio _dio;

  Future<List<ProductModel>> sellerProducts() async {
    final res = await _dio.get("/api/seller/products");
    final data = (res.data['products'] ?? res.data) as List<dynamic>;
    return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> create(ProductModel model) async {
    final res = await _dio.post("/api/seller/products", data: model.toJson());
    return ProductModel.fromJson(res.data['product'] ?? res.data);
  }

  Future<ProductModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch("/api/seller/products/$id", data: data);
    return ProductModel.fromJson(res.data['product'] ?? res.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete("/api/seller/products/$id");
  }
}
