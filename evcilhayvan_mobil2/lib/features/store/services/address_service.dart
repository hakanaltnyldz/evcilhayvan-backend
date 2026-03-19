// lib/features/store/services/address_service.dart

import 'package:dio/dio.dart';
import '../domain/models/address_model.dart';

class AddressService {
  final Dio _dio;

  AddressService(this._dio);

  Future<List<AddressModel>> getAddresses() async {
    final response = await _dio.get('/api/addresses');
    final List<dynamic> addressesJson = response.data['addresses'] ?? [];
    return addressesJson.map((json) => AddressModel.fromJson(json)).toList();
  }

  Future<AddressModel?> getDefaultAddress() async {
    final response = await _dio.get('/api/addresses/default');
    final addressJson = response.data['address'];
    if (addressJson == null) return null;
    return AddressModel.fromJson(addressJson);
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final response = await _dio.post('/api/addresses', data: address.toJson());
    return AddressModel.fromJson(response.data['address']);
  }

  Future<AddressModel> updateAddress(String id, AddressModel address) async {
    final response = await _dio.patch('/api/addresses/$id', data: address.toJson());
    return AddressModel.fromJson(response.data['address']);
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('/api/addresses/$id');
  }

  Future<AddressModel> setDefaultAddress(String id) async {
    final response = await _dio.patch('/api/addresses/$id/default');
    return AddressModel.fromJson(response.data['address']);
  }
}