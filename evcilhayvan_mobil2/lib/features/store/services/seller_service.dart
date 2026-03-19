import 'package:dio/dio.dart';

import '../domain/models/seller_application_model.dart';

class SellerService {
  SellerService(this._dio);
  final Dio _dio;

  Future<SellerApplicationModel> apply(SellerApplicationModel model) async {
    final res = await _dio.post("/api/seller/apply", data: model.toJson());
    return SellerApplicationModel.fromJson(res.data['application'] ?? res.data);
  }

  Future<List<SellerApplicationModel>> adminList() async {
    final res = await _dio.get("/api/admin/seller/applications");
    final data = (res.data['applications'] ?? res.data) as List<dynamic>;
    return data.map((e) => SellerApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> adminApprove(String id) {
    return _dio.patch("/api/admin/seller/applications/$id/approve");
  }

  Future<void> adminReject(String id, {String? reason}) {
    return _dio.patch(
      "/api/admin/seller/applications/$id/reject",
      data: {"rejectionReason": reason},
    );
  }
}
