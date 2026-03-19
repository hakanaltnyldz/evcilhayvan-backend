import 'package:evcilhayvan_mobil2/core/http.dart';

class BlockReportRepository {
  final _client = ApiClient();

  Future<void> blockUser(String userId) async {
    await _client.dio.post('/users/block/$userId');
  }

  Future<void> unblockUser(String userId) async {
    await _client.dio.delete('/users/block/$userId');
  }

  Future<bool> isBlocked(String userId) async {
    final res = await _client.dio.get('/users/is-blocked/$userId');
    return res.data['blocked'] == true;
  }

  Future<void> reportUser(String userId, String reason, {String? description}) async {
    await _client.dio.post('/users/report/$userId', data: {
      'reason': reason,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }
}
