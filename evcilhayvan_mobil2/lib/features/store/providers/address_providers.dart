// lib/features/store/providers/address_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/address_model.dart';
import '../services/address_service.dart';
import 'dio_provider.dart';

final addressServiceProvider = Provider((ref) => AddressService(ref.watch(storeDioProvider)));

final addressesProvider = FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final service = ref.watch(addressServiceProvider);
  return service.getAddresses();
});

final defaultAddressProvider = FutureProvider.autoDispose<AddressModel?>((ref) async {
  final service = ref.watch(addressServiceProvider);
  return service.getDefaultAddress();
});

final addressNotifierProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>((ref) {
  return AddressNotifier(ref);
});

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final Ref ref;

  AddressNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    state = const AsyncValue.loading();
    try {
      final addresses = await ref.read(addressServiceProvider).getAddresses();
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAddress(AddressModel address) async {
    try {
      await ref.read(addressServiceProvider).addAddress(address);
      await loadAddresses();
      ref.invalidate(defaultAddressProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress(String id, AddressModel address) async {
    try {
      await ref.read(addressServiceProvider).updateAddress(id, address);
      await loadAddresses();
      ref.invalidate(defaultAddressProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await ref.read(addressServiceProvider).deleteAddress(id);
      await loadAddresses();
      ref.invalidate(defaultAddressProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      await ref.read(addressServiceProvider).setDefaultAddress(id);
      await loadAddresses();
      ref.invalidate(defaultAddressProvider);
    } catch (e) {
      rethrow;
    }
  }
}