import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/seller_application_model.dart';
import '../repositories/seller_repository.dart';
import '../services/seller_service.dart';
import 'dio_provider.dart';

final sellerServiceProvider = Provider((ref) => SellerService(ref.watch(storeDioProvider)));
final sellerRepoProvider = Provider((ref) => SellerRepository(ref.watch(sellerServiceProvider)));

final sellerApplyProvider = FutureProvider.autoDispose.family<SellerApplicationModel, SellerApplicationModel>(
  (ref, model) => ref.watch(sellerRepoProvider).apply(model),
);

final adminApplicationsProvider = FutureProvider<List<SellerApplicationModel>>(
  (ref) => ref.watch(sellerRepoProvider).adminList(),
);
