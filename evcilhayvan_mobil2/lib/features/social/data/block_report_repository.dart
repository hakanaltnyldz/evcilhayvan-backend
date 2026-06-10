import 'package:evcilhayvan_mobil2/core/http.dart';

class BlockReportRepository {
  final _client = ApiClient();

  Future<void> blockUser(String userId) async {
    await _client.dio.post('/api/users/block/$userId');
  }

  Future<void> unblockUser(String userId) async {
    await _client.dio.delete('/api/users/block/$userId');
  }

  Future<bool> isBlocked(String userId) async {
    final res = await _client.dio.get('/api/users/is-blocked/$userId');
    return res.data['blocked'] == true;
  }

  Future<void> reportUser(String userId, String reason, {String? description}) async {
    await _client.dio.post('/api/users/report/$userId', data: {
      'reason': reason,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }
}
