import '../domain/models/product_model.dart';
import '../services/product_service.dart';

class ProductRepository {
  ProductRepository(this._service);
  final ProductService _service;

  Future<List<ProductModel>> all() => _service.sellerProducts();
  Future<ProductModel> create(ProductModel model) => _service.create(model);
  Future<ProductModel> update(String id, Map<String, dynamic> data) => _service.update(id, data);
  Future<void> delete(String id) => _service.delete(id);
}
