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

class FeedPaginatedState {
  final List<Post> posts;
  final int currentPage;
  final bool hasMore;
  final bool loadingMore;
  const FeedPaginatedState({
    required this.posts,
    required this.currentPage,
    required this.hasMore,
    required this.loadingMore,
  });
  FeedPaginatedState copyWith({List<Post>? posts, int? currentPage, bool? hasMore, bool? loadingMore}) {
    return FeedPaginatedState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class FeedPaginatedNotifier extends AsyncNotifier<FeedPaginatedState> {
  static const _pageSize = 20;
  String? _activeHashtag;
  bool _followingMode = false;

  String? get activeHashtag => _activeHashtag;
  bool get followingMode => _followingMode;

  @override
  Future<FeedPaginatedState> build() async {
    final posts = await ref.read(postRepositoryProvider).getFeed(page: 1);
    return FeedPaginatedState(
      posts: posts,
      currentPage: 1,
      hasMore: posts.length >= _pageSize,
      loadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final repo = ref.read(postRepositoryProvider);
      final more = _activeHashtag != null
          ? await repo.getFeedByHashtag(_activeHashtag!, page: nextPage)
          : await repo.getFeed(page: nextPage, mode: _followingMode ? 'following' : null);
      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...more],
        currentPage: nextPage,
        hasMore: more.length >= _pageSize,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(postRepositoryProvider);
      final posts = _activeHashtag != null
          ? await repo.getFeedByHashtag(_activeHashtag!)
          : await repo.getFeed(page: 1, mode: _followingMode ? 'following' : null);
      return FeedPaginatedState(
        posts: posts,
        currentPage: 1,
        hasMore: posts.length >= _pageSize,
        loadingMore: false,
      );
    });
  }

  Future<void> filterByHashtag(String? hashtag) async {
    _activeHashtag = hashtag;
    await refresh();
  }

  Future<void> setFollowingMode(bool following) async {
    _followingMode = following;
    _activeHashtag = null; // clear hashtag filter when switching tabs
    await refresh();
  }
}

final feedPaginatedProvider = AsyncNotifierProvider<FeedPaginatedNotifier, FeedPaginatedState>(
  FeedPaginatedNotifier.new,
);

final trendingHashtagsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(postRepositoryProvider).getTrendingHashtags();
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

  Future<List<Post>> getFeed({int page = 1, String? mode}) async {
    final params = <String, dynamic>{'page': page, 'limit': 20};
    if (mode != null) params['mode'] = mode;
    final resp = await _guard(() => _dio.get('/api/posts', queryParameters: params));
    final list = resp.data['posts'] as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost({
    String? content,
    List<String>? photos,
    String? petId,
    String? petName,
    List<String>? hashtags,
  }) async {
    final resp = await _guard(() => _dio.post('/api/posts', data: {
      if (content != null) 'content': content,
      if (photos != null) 'photos': photos,
      if (petId != null) 'petId': petId,
      if (petName != null) 'petName': petName,
      if (hashtags != null && hashtags.isNotEmpty) 'hashtags': hashtags,
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

  Future<PostReply> addReply(String postId, String commentId, String text) async {
    final resp = await _guard(() => _dio.post(
      '/api/posts/$postId/comments/$commentId/reply',
      data: {'text': text},
    ));
    return PostReply.fromJson(resp.data['reply'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _guard(() => _dio.delete('/api/posts/$postId'));
  }

  Future<Map<String, dynamic>> savePost(String postId) async {
    final resp = await _guard(() => _dio.post('/api/posts/$postId/save'));
    return {'saved': resp.data['saved'] as bool, 'saveCount': resp.data['saveCount'] as int};
  }

  Future<List<Post>> getSavedPosts() async {
    final resp = await _guard(() => _dio.get('/api/posts/saved'));
    final list = resp.data['posts'] as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    final resp = await _guard(() => _dio.get('/api/posts/hashtags/trending'));
    final list = resp.data['hashtags'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Post>> getFeedByHashtag(String hashtag, {int page = 1}) async {
    final resp = await _guard(() => _dio.get('/api/posts', queryParameters: {
      'hashtag': hashtag,
      'page': page,
      'limit': 20,
    }));
    final list = resp.data['posts'] as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> reactToMessage(String convId, String msgId, String emoji) async {
    final resp = await _guard(() => _dio.post(
      '/api/conversations/$convId/messages/$msgId/react',
      data: {'emoji': emoji},
    ));
    return Map<String, dynamic>.from(resp.data['reactions'] ?? {});
  }
}
