import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/auth/domain/user_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/category_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/store_model.dart';

class SellerApplicationResult {
  final User user;
  final StoreModel store;
  SellerApplicationResult({required this.user, required this.store});
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final client = ApiClient();
  return StoreRepository(client);
});

final storeFeedProvider = AsyncNotifierProvider.autoDispose<StoreFeedNotifier, List<ProductModel>>(
  StoreFeedNotifier.new,
);

final storeDiscoverProvider = FutureProvider.autoDispose<List<StoreModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStores();
});

final myStoreProvider = FutureProvider.autoDispose<StoreModel?>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  try {
    return await repo.getMyStore();
  } catch (_) {
    return null;
  }
});

final myProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getMyProducts();
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getCategories();
});

class StoreRepository {
  final ApiClient _client;
  StoreRepository(this._client);
  Dio get _dio => _client.dio;
  static const _feedCacheKey = 'cache_store_feed';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  Future<List<ProductModel>> _readCachedFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedCacheKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _writeCachedFeed(List<ProductModel> products) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_feedCacheKey, serialized);
  }

  Future<List<StoreModel>> getStores() {
    return _guard(() async {
      final response = await _dio.get('/api/stores/discover');
      final List<dynamic> storeJson = (response.data['stores'] as List?) ?? const <dynamic>[];
      return storeJson.whereType<Map<String, dynamic>>().map(StoreModel.fromJson).toList();
    });
  }

  Future<List<ProductModel>> getProductFeed() {
    return _guard(() async {
      final response = await _dio.get('/api/stores/feed');
      final List<dynamic> productJson = (response.data['products'] as List?) ?? const <dynamic>[];
      return productJson.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
    });
  }

  Future<List<ProductModel>> getCachedFeed() => _readCachedFeed();

  Future<void> cacheFeed(List<ProductModel> products) => _writeCachedFeed(products);

  Future<StoreModel?> getMyStore() {
    return _guard(() async {
      final response = await _dio.get('/api/stores/me');
      if (response.data['store'] == null) return null;
      return StoreModel.fromJson(response.data['store']);
    });
  }

  Future<List<ProductModel>> getMyProducts() {
    return _guard(() async {
      final response = await _dio.get('/api/stores/me/products');
      final List<dynamic> productJson = (response.data['products'] as List?) ?? const <dynamic>[];
      return productJson.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
    });
  }

  Future<StoreModel> getStore(String storeId) {
    return _guard(() async {
      final response = await _dio.get('/api/stores/$storeId');
      return StoreModel.fromJson(response.data['store']);
    });
  }

  Future<List<ProductModel>> getStoreProducts(String storeId) {
    return _guard(() async {
      final response = await _dio.get('/api/stores/$storeId/products');
      final List<dynamic> productJson = (response.data['products'] as List?) ?? const <dynamic>[];
      return productJson.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
    });
  }

  Future<SellerApplicationResult> applySeller({
    required String storeName,
    String? description,
    String? logoUrl,
  }) {
    return _guard(() async {
      final response = await _dio.post('/api/stores/create', data: {
        'storeName': storeName,
        if (description != null) 'description': description,
        if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
      });

      await _client.persistTokens(
        accessToken: response.data['token'] as String?,
        refreshToken: response.data['refreshToken'] as String?,
      );
      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      final store = StoreModel.fromJson(response.data['store']);
      return SellerApplicationResult(user: user, store: store);
    });
  }

  Future<ProductModel> addProduct({
    required String title,
    required double price,
    String? description,
    List<String>? photos,
    int? stock,
    String? categoryId,
  }) {
    return _guard(() async {
      final response = await _dio.post('/api/stores/me/products', data: {
        'title': title,
        'price': price,
        if (description != null) 'description': description,
        if (photos != null) 'photos': photos,
        if (stock != null) 'stock': stock,
        if (categoryId != null) 'category': categoryId,
      });

      final product = ProductModel.fromJson(response.data['product']);
      await _updateCachedFeed((current) => [product, ...current]);
      return product;
    });
  }

  Future<ProductModel> updateProduct(
    String productId, {
    required Map<String, dynamic> data,
  }) {
    return _guard(() async {
      final response = await _dio.patch(
        '/api/seller/products/$productId',
        data: data,
      );
      final product = ProductModel.fromJson(response.data['product'] ?? response.data);
      await _updateCachedFeed(
        (current) => current
            .map((item) => item.id == product.id ? product : item)
            .toList(),
      );
      return product;
    });
  }

  Future<void> deleteProduct(String productId) {
    return _guard(() async {
      await _dio.delete('/api/seller/products/$productId');
      await _updateCachedFeed(
        (current) => current.where((item) => item.id != productId).toList(),
      );
    });
  }

  Future<void> _updateCachedFeed(List<ProductModel> Function(List<ProductModel>) updater) async {
    final current = await getCachedFeed();
    final updated = updater(current);
    await cacheFeed(updated);
  }

  // Kategorileri getir
  Future<List<CategoryModel>> getCategories() {
    return _guard(() async {
      final response = await _dio.get('/api/store/categories');
      final List<dynamic> categoryJson = (response.data['categories'] as List?) ?? const <dynamic>[];
      return categoryJson.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
    });
  }

  // Fotoğraflı ürün ekleme (galeri/kamera)
  Future<ProductModel> addProductWithImages({
    required String name,
    required double price,
    String? description,
    List<XFile>? images,
    int? stock,
    String? categoryId,
  }) {
    return _guard(() async {
      final formData = FormData.fromMap({
        'name': name,
        'price': price,
        if (description != null) 'description': description,
        if (stock != null) 'stock': stock,
        if (categoryId != null) 'category': categoryId,
      });

      // Resimleri ekle
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final file = File(image.path);
          final fileName = image.name;
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ));
        }
      }

      final response = await _dio.post(
        '/api/seller/products/with-images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final product = ProductModel.fromJson(response.data['product']);
      await _updateCachedFeed((current) => [product, ...current]);
      return product;
    });
  }

  // Mevcut ürüne fotoğraf ekle
  Future<ProductModel> uploadProductImages(String productId, List<XFile> images) {
    return _guard(() async {
      final formData = FormData();

      for (final image in images) {
        final file = File(image.path);
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(file.path, filename: image.name),
        ));
      }

      final response = await _dio.post(
        '/api/seller/products/$productId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final product = ProductModel.fromJson(response.data['product']);
      await _updateCachedFeed(
        (current) => current.map((item) => item.id == product.id ? product : item).toList(),
      );
      return product;
    });
  }

  // Stok güncelleme (increase/decrease/set)
  Future<ProductModel> updateStock(
    String productId, {
    required int stock,
    String? action, // 'increase', 'decrease', or null for direct set
  }) {
    return _guard(() async {
      final response = await _dio.patch(
        '/api/seller/products/$productId/stock',
        data: {
          'stock': stock,
          if (action != null) 'action': action,
        },
      );

      final product = ProductModel.fromJson(response.data['product']);
      await _updateCachedFeed(
        (current) => current.map((item) => item.id == product.id ? product : item).toList(),
      );
      return product;
    });
  }

  // Ürün aktif/pasif toggle
  Future<ProductModel> toggleProductActive(String productId) {
    return _guard(() async {
      final response = await _dio.patch('/api/seller/products/$productId/toggle-active');

      final product = ProductModel.fromJson(response.data['product']);
      await _updateCachedFeed(
        (current) => current.map((item) => item.id == product.id ? product : item).toList(),
      );
      return product;
    });
  }

  // Seller istatistikleri
  Future<SellerStats> getSellerStats() {
    return _guard(() async {
      final response = await _dio.get('/api/seller/stats');
      return SellerStats.fromJson(response.data['stats']);
    });
  }

  // Demo mağaza ürünleri oluşturma
  Future<SeedDemoProductsResult> seedDemoProducts() {
    return _guard(() async {
      final response = await _dio.post('/api/seller/seed-demo-products');
      return SeedDemoProductsResult.fromJson(response.data);
    });
  }
}

class SellerStats {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int outOfStock;
  final int lowStock;
  final int totalStock;
  final double totalValue;

  SellerStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.outOfStock,
    required this.lowStock,
    required this.totalStock,
    required this.totalValue,
  });

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    return SellerStats(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      inactiveProducts: json['inactiveProducts'] ?? 0,
      outOfStock: json['outOfStock'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      totalStock: json['totalStock'] ?? 0,
      totalValue: (json['totalValue'] ?? 0).toDouble(),
    );
  }
}

class SeedDemoProductsResult {
  final String message;
  final int categoriesCreated;
  final int productsCreated;
  final String storeName;

  SeedDemoProductsResult({
    required this.message,
    required this.categoriesCreated,
    required this.productsCreated,
    required this.storeName,
  });

  factory SeedDemoProductsResult.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final store = stats['store'] as Map<String, dynamic>? ?? {};

    return SeedDemoProductsResult(
      message: json['message'] ?? 'Demo ürünler oluşturuldu',
      categoriesCreated: stats['categoriesCreated'] ?? 0,
      productsCreated: stats['productsCreated'] ?? 0,
      storeName: store['name'] ?? 'Mağazanız',
    );
  }
}

class StoreFeedNotifier extends AutoDisposeAsyncNotifier<List<ProductModel>> {
  late final StoreRepository _repository;

  @override
  Future<List<ProductModel>> build() async {
    _repository = ref.read(storeRepositoryProvider);
    final cached = await _repository.getCachedFeed();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }
    final fresh = await _repository.getProductFeed();
    await _repository.cacheFeed(fresh);
    return fresh;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await _repository.getProductFeed();
      await _repository.cacheFeed(fresh);
      return fresh;
    });
  }
}
