import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/vaccination_record_model.dart';
import '../../domain/models/vaccination_schedule_model.dart';

final vaccinationRepositoryProvider = Provider<VaccinationRepository>((ref) {
  return VaccinationRepository(ApiClient());
});

final vaccinationSchedulesProvider =
    FutureProvider.autoDispose.family<List<VaccinationScheduleModel>, String>((ref, species) {
  final repo = ref.watch(vaccinationRepositoryProvider);
  return repo.getSchedules(species: species);
});

final petVaccinationsProvider =
    FutureProvider.autoDispose.family<List<VaccinationRecordModel>, String>((ref, petId) {
  final repo = ref.watch(vaccinationRepositoryProvider);
  return repo.getPetVaccinations(petId);
});

final petVaccinationCalendarProvider =
    FutureProvider.autoDispose.family<List<VaccinationCalendarItem>, String>((ref, petId) {
  final repo = ref.watch(vaccinationRepositoryProvider);
  return repo.getPetCalendar(petId);
});

final vaccinationRemindersProvider = FutureProvider.autoDispose<List<VaccinationRecordModel>>((ref) {
  final repo = ref.watch(vaccinationRepositoryProvider);
  return repo.getReminders();
});

class VaccinationRepository {
  final ApiClient _client;
  VaccinationRepository(this._client);
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

  Future<List<VaccinationScheduleModel>> getSchedules({String? species}) {
    return _guard(() async {
      final response = await _dio.get('/api/vaccinations/schedules', queryParameters: {
        if (species != null) 'species': species,
      });
      final List<dynamic> list = (response.data['schedules'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(VaccinationScheduleModel.fromJson).toList();
    });
  }

  Future<List<VaccinationRecordModel>> getPetVaccinations(String petId) {
    return _guard(() async {
      final response = await _dio.get('/api/vaccinations/pet/$petId');
      final List<dynamic> list = (response.data['records'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(VaccinationRecordModel.fromJson).toList();
    });
  }

  Future<VaccinationRecordModel> addRecord({
    required String petId,
    required String vaccineName,
    required DateTime dateAdministered,
    String? vaccineCode,
    String? batchNumber,
    DateTime? nextDueDate,
    String? veterinaryId,
    String? notes,
  }) {
    return _guard(() async {
      final response = await _dio.post('/api/vaccinations/records', data: {
        'petId': petId,
        'vaccineName': vaccineName,
        'dateAdministered': dateAdministered.toIso8601String(),
        if (vaccineCode != null) 'vaccineCode': vaccineCode,
        if (batchNumber != null) 'batchNumber': batchNumber,
        if (nextDueDate != null) 'nextDueDate': nextDueDate.toIso8601String(),
        if (veterinaryId != null) 'veterinaryId': veterinaryId,
        if (notes != null) 'notes': notes,
      });
      return VaccinationRecordModel.fromJson(response.data['record']);
    });
  }

  Future<VaccinationRecordModel> updateRecord(String id, Map<String, dynamic> data) {
    return _guard(() async {
      final response = await _dio.put('/api/vaccinations/records/$id', data: data);
      return VaccinationRecordModel.fromJson(response.data['record']);
    });
  }

  Future<void> deleteRecord(String id) {
    return _guard(() async {
      await _dio.delete('/api/vaccinations/records/$id');
    });
  }

  Future<List<VaccinationCalendarItem>> getPetCalendar(String petId) {
    return _guard(() async {
      final response = await _dio.get('/api/vaccinations/pet/$petId/calendar');
      final List<dynamic> list = (response.data['calendar'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(VaccinationCalendarItem.fromJson).toList();
    });
  }

  Future<List<VaccinationRecordModel>> getReminders() {
    return _guard(() async {
      final response = await _dio.get('/api/vaccinations/reminders');
      final List<dynamic> list = (response.data['reminders'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(VaccinationRecordModel.fromJson).toList();
    });
  }
}
