import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/seller_application_model.dart';
import '../providers/seller_providers.dart';
import '../repositories/seller_repository.dart';

class SellerApplicationController extends StateNotifier<AsyncValue<void>> {
  SellerApplicationController(this._repository) : super(const AsyncData(null));

  final SellerRepository _repository;

  Future<void> submit(SellerApplicationModel model) async {
    state = const AsyncLoading();
    try {
      await _repository.apply(model);
      state = const AsyncData(null);
    } catch (err, st) {
      state = AsyncError(err, st);
    }
  }
}

final sellerApplicationControllerProvider =
    StateNotifierProvider<SellerApplicationController, AsyncValue<void>>((ref) {
  return SellerApplicationController(ref.watch(sellerRepoProvider));
});
