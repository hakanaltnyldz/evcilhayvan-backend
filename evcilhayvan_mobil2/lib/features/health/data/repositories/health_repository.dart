import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/health/domain/models/health_record_model.dart';

class HealthRepository {
  final _dio = ApiClient().dio;

  Future<List<HealthRecord>> getRecords(String petId, {String? type}) async {
    final res = await _dio.get('/health/$petId',
        queryParameters: {if (type != null) 'type': type});
    final raw = res.data['records'] as List;
    return raw.map((j) => HealthRecord.fromJson(Map<String, dynamic>.from(j))).toList();
  }

  Future<HealthRecord> addRecord(String petId, Map<String, dynamic> body) async {
    final res = await _dio.post('/health/$petId', data: body);
    return HealthRecord.fromJson(Map<String, dynamic>.from(res.data['record']));
  }

  Future<void> deleteRecord(String recordId) async {
    await _dio.delete('/health/record/$recordId');
  }

  Future<List<Map<String, dynamic>>> getWeightChart(String petId) async {
    final res = await _dio.get('/health/$petId/weight-chart');
    return List<Map<String, dynamic>>.from(res.data['weightData'] ?? []);
  }
}
