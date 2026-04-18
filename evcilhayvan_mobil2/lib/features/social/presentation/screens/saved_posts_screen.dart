import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post_model.dart';
import 'feed_screen.dart';

final savedPostsProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  return ref.read(postRepositoryProvider).getSavedPosts();
});

class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  final Map<String, bool> _likedLocally = {};
  final Map<String, int> _likesLocal = {};
  final Map<String, bool> _savedLocally = {};
  final Map<String, int> _savesLocal = {};

  Future<void> _handleLike(Post post) async {
    final currentLiked = _likedLocally[post.id] ?? post.isLiked;
    setState(() {
      _likedLocally[post.id] = !currentLiked;
      _likesLocal[post.id] = post.likeCount + (currentLiked ? -1 : 1);
    });
    try {
      await ref.read(postRepositoryProvider).toggleLike(post.id);
    } catch (_) {
      setState(() {
        _likedLocally[post.id] = currentLiked;
        _likesLocal.remove(post.id);
      });
    }
  }

  Future<void> _handleSave(Post post) async {
    final currentSaved = _savedLocally[post.id] ?? post.isSaved;
    setState(() {
      _savedLocally[post.id] = !currentSaved;
      _savesLocal[post.id] = post.saveCount + (currentSaved ? -1 : 1);
    });
    try {
      await ref.read(postRepositoryProvider).savePost(post.id);
      // Listeden çıkar (kayıt kaldırıldıysa)
      if (currentSaved) ref.invalidate(savedPostsProvider);
    } catch (_) {
      setState(() {
        _savedLocally[post.id] = currentSaved;
        _savesLocal.remove(post.id);
      });
    }
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(post: post, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedPostsProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Kaydedilenler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: savedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD8F3DC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      size: 44,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz kaydedilen gönderi yok',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Feed\'deki gönderileri kaydetmek için\nbookmark ikonuna dokun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(savedPostsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (ctx, i) {
                final post = posts[i];
                return PostCard(
                      post: post,
                      currentUserId: currentUser?.id ?? '',
                      likedLocally: _likedLocally[post.id],
                      likesLocal: _likesLocal[post.id],
                      savedLocally: _savedLocally[post.id],
                      savesLocal: _savesLocal[post.id],
                      onLike: () => _handleLike(post),
                      onSave: () => _handleSave(post),
                      onComment: () => _showComments(context, post),
                    )
                    .animate(delay: Duration(milliseconds: i * 60))
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.05);
              },
            ),
          );
        },
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(savedPostsProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
