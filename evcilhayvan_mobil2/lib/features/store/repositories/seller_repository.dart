import '../domain/models/seller_application_model.dart';
import '../services/seller_service.dart';

class SellerRepository {
  SellerRepository(this._service);
  final SellerService _service;

  Future<SellerApplicationModel> apply(SellerApplicationModel model) => _service.apply(model);
  Future<List<SellerApplicationModel>> adminList() => _service.adminList();
  Future<void> approve(String id) => _service.adminApprove(id);
  Future<void> reject(String id, {String? reason}) => _service.adminReject(id, reason: reason);
}
