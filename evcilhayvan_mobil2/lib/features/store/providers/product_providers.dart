import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/product_model.dart';
import '../repositories/product_repository.dart';
import '../services/product_service.dart';
import 'dio_provider.dart';

final productServiceProvider = Provider((ref) => ProductService(ref.watch(storeDioProvider)));
final productRepoProvider = Provider((ref) => ProductRepository(ref.watch(productServiceProvider)));

final sellerProductsProvider = FutureProvider<List<ProductModel>>(
  (ref) => ref.watch(productRepoProvider).all(),
);

final productCreateProvider = FutureProvider.autoDispose.family<ProductModel, ProductModel>(
  (ref, model) => ref.watch(productRepoProvider).create(model),
);

final productUpdateProvider = FutureProvider.autoDispose.family<ProductModel, Map<String, dynamic>>(
  (ref, params) {
    final id = params['id'] as String;
    final data = params['data'] as Map<String, dynamic>;
    return ref.watch(productRepoProvider).update(id, data);
  },
);
