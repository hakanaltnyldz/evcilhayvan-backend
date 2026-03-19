import '../domain/models/category_model.dart';
import '../domain/models/product_model.dart';
import '../domain/models/seller_profile_model.dart';
import '../services/store_service.dart';

class StoreRepository {
  StoreRepository(this._service);
  final StoreService _service;

  Future<List<CategoryModel>> categories() => _service.categories();
  Future<List<ProductModel>> products({String? category, String? q, String sort = 'newest'}) =>
      _service.products(category: category, q: q, sort: sort);
  Future<ProductModel> product(String id) => _service.product(id);
  Future<SellerStoreView> sellerProfile(String userId) => _service.sellerProfile(userId);
}
