import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/services/cache_service.dart';
import '../domain/models/category_model.dart';
import '../domain/models/product_model.dart';
import '../domain/models/seller_profile_model.dart';
import '../repositories/store_repository.dart';
import '../services/store_service.dart';
import 'dio_provider.dart';

final storeServiceProvider = Provider((ref) => StoreService(ref.watch(storeDioProvider)));
final storeRepoProvider = Provider((ref) => StoreRepository(ref.watch(storeServiceProvider)));

// Categories: stale-while-revalidate (TTL 2h — rarely change)
class _CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  static const _cacheKey = 'cache_store_categories_v1';

  @override
  Future<List<CategoryModel>> build() async {
    final repo = ref.read(storeRepoProvider);
    return CacheService.staleWhileRevalidate<List<CategoryModel>>(
      key: _cacheKey,
      ttl: const Duration(hours: 2),
      fetch: () => repo.categories(),
      fromJson: (raw) =>
          (raw as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList(),
      toJson: (list) => list.map((e) => e.toJson()).toList(),
      onUpdate: (fresh) => state = AsyncData(fresh),
    );
  }
}

final categoriesProvider = AsyncNotifierProvider<_CategoriesNotifier, List<CategoryModel>>(
  _CategoriesNotifier.new,
);

typedef StoreProductQuery = ({String? category, String? q, String? sort});

final storeProductsProvider = FutureProvider.family<List<ProductModel>, StoreProductQuery>(
  (ref, params) => ref.watch(storeRepoProvider).products(
        category: params.category,
        q: params.q,
        sort: params.sort ?? 'newest',
      ),
);

final productDetailProvider = FutureProvider.family<ProductModel, String>(
  (ref, id) => ref.watch(storeRepoProvider).product(id),
);

final sellerProfileProvider = FutureProvider.family<SellerStoreView, String>(
  (ref, userId) => ref.watch(storeRepoProvider).sellerProfile(userId),
);
