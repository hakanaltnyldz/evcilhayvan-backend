import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/appointment_model.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ApiClient());
});

final myAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getMyAppointments();
});

final appointmentDetailProvider = FutureProvider.autoDispose.family<AppointmentModel, String>((ref, id) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getAppointmentDetail(id);
});

final availableSlotsProvider =
    FutureProvider.autoDispose.family<List<String>, AvailableSlotsParams>((ref, params) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getAvailableSlots(vetId: params.vetId, date: params.date);
});

class AvailableSlotsParams {
  final String vetId;
  final String date; // YYYY-MM-DD

  const AvailableSlotsParams({required this.vetId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableSlotsParams && vetId == other.vetId && date == other.date;

  @override
  int get hashCode => Object.hash(vetId, date);
}

class AppointmentRepository {
  final ApiClient _client;
  AppointmentRepository(this._client);
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  Future<List<AppointmentModel>> getMyAppointments() {
    return _guard(() async {
      final response = await _dio.get('/api/appointments/me');
      final List<dynamic> list = (response.data['appointments'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(AppointmentModel.fromJson).toList();
    });
  }

  Future<AppointmentModel> getAppointmentDetail(String id) {
    return _guard(() async {
      final response = await _dio.get('/api/appointments/$id');
      return AppointmentModel.fromJson(response.data['appointment']);
    });
  }

  Future<AppointmentModel> createAppointment({
    required String petId,
    required String veterinaryId,
    required DateTime date,
    String? reason,
    String? notes,
    String type = 'clinic',
  }) {
    return _guard(() async {
      final response = await _dio.post('/api/appointments', data: {
        'petId': petId,
        'veterinaryId': veterinaryId,
        'date': date.toIso8601String(),
        if (reason != null) 'reason': reason,
        if (notes != null) 'notes': notes,
        'type': type,
      });
      return AppointmentModel.fromJson(response.data['appointment']);
    });
  }

  Future<AppointmentModel> updateStatus(String id, String status) {
    return _guard(() async {
      final response = await _dio.patch('/api/appointments/$id/status', data: {'status': status});
      return AppointmentModel.fromJson(response.data['appointment']);
    });
  }

  Future<Map<String, dynamic>> getVetSchedule({String? status, String? date, int page = 1}) {
    return _guard(() async {
      final response = await _dio.get('/api/appointments/vet-schedule', queryParameters: {
        if (status != null) 'status': status,
        if (date != null) 'date': date,
        'page': page,
        'limit': 50,
      });
      final List<dynamic> list = (response.data['appointments'] as List?) ?? [];
      return {
        'appointments': list.whereType<Map<String, dynamic>>().map(AppointmentModel.fromJson).toList(),
        'vetName': response.data['vetName'] ?? '',
        'total': response.data['total'] ?? 0,
      };
    });
  }

  Future<List<String>> getAvailableSlots({required String vetId, required String date}) {
    return _guard(() async {
      final response = await _dio.get('/api/appointments/vet/$vetId/slots', queryParameters: {'date': date});
      final List<dynamic> slots = (response.data['slots'] as List?) ?? [];
      return slots.whereType<String>().toList();
    });
  }
}
