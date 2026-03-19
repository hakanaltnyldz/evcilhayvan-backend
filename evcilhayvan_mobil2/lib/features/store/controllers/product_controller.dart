import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/product_model.dart';
import '../providers/product_providers.dart';
import '../repositories/product_repository.dart';

class ProductController extends StateNotifier<AsyncValue<void>> {
  ProductController(this._repository) : super(const AsyncData(null));

  final ProductRepository _repository;

  Future<void> create(ProductModel model) async {
    state = const AsyncLoading();
    try {
      await _repository.create(model);
      state = const AsyncData(null);
    } catch (err, st) {
      state = AsyncError(err, st);
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await _repository.update(id, data);
      state = const AsyncData(null);
    } catch (err, st) {
      state = AsyncError(err, st);
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.delete(id);
      state = const AsyncData(null);
    } catch (err, st) {
      state = AsyncError(err, st);
    }
  }
}

final productControllerProvider =
    StateNotifierProvider.autoDispose<ProductController, AsyncValue<void>>((ref) {
  return ProductController(ref.watch(productRepoProvider));
});
