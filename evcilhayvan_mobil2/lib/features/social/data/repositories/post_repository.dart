import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/post_model.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ApiClient());
});

final feedProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  return ref.read(postRepositoryProvider).getFeed();
});

class PostRepository {
  PostRepository(this._client);
  final ApiClient _client;
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

  Future<List<Post>> getFeed({int page = 1}) async {
    final resp = await _guard(() => _dio.get('/api/posts', queryParameters: {'page': page, 'limit': 20}));
    final list = resp.data['posts'] as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost({
    String? content,
    List<String>? photos,
    String? petId,
    String? petName,
  }) async {
    final resp = await _guard(() => _dio.post('/api/posts', data: {
      if (content != null) 'content': content,
      if (photos != null) 'photos': photos,
      if (petId != null) 'petId': petId,
      if (petName != null) 'petName': petName,
    }));
    return Post.fromJson(resp.data['post'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final resp = await _guard(() => _dio.post('/api/posts/$postId/like'));
    return {'liked': resp.data['liked'] as bool, 'likeCount': resp.data['likeCount'] as int};
  }

  Future<PostComment> addComment(String postId, String text) async {
    final resp = await _guard(() => _dio.post('/api/posts/$postId/comment', data: {'text': text}));
    return PostComment.fromJson(resp.data['comment'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _guard(() => _dio.delete('/api/posts/$postId'));
  }

  Future<Map<String, dynamic>> reactToMessage(String convId, String msgId, String emoji) async {
    final resp = await _guard(() => _dio.post(
      '/api/conversations/$convId/messages/$msgId/react',
      data: {'emoji': emoji},
    ));
    return Map<String, dynamic>.from(resp.data['reactions'] ?? {});
  }
}
