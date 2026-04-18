import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post_model.dart';
import 'hashtag_discover_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _likedLocally = {};
  final Map<String, int> _likesLocal = {};
  final Map<String, bool> _savedLocally = {};
  final Map<String, int> _savesLocal = {};
  final ValueNotifier<String?> _hashtagNotifier = ValueNotifier(null);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final isFollowing = _tabController.index == 1;
        _hashtagNotifier.value = null;
        ref.read(feedPaginatedProvider.notifier).setFollowingMode(isFollowing);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hashtagNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedPaginatedProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sosyal Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tag_rounded),
            tooltip: 'Hashtag Keşfet',
            onPressed: () => context.pushNamed('hashtag-discover'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Gonderi Paylas',
            onPressed: () async {
              final result = await context.pushNamed<bool>('create-post');
              if (result == true)
                ref.read(feedPaginatedProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.pushNamed<bool>('create-post');
          if (result == true)
            ref.read(feedPaginatedProvider.notifier).refresh();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Paylas'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Aktif hashtag filtre banner'ı
          ValueListenableBuilder<String?>(
            valueListenable: _hashtagNotifier,
            builder: (ctx, activeTag, _) {
              if (activeTag == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF2D6A4F)),
                    const SizedBox(width: 4),
                    Text(
                      '#$activeTag',
                      style: const TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _hashtagNotifier.value = null;
                        ref.read(feedPaginatedProvider.notifier).filterByHashtag(null);
                      },
                      child: const Row(
                        children: [
                          Text('Temizle', style: TextStyle(color: Color(0xFF2D6A4F), fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.close_rounded, size: 16, color: Color(0xFF2D6A4F)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: feedAsync.when(
              data: (state) {
                final posts = state.posts;
                final isFollowingTab = _tabController.index == 1;
                if (posts.isEmpty) {
                  if (isFollowingTab) {
                    return _FollowingEmptyState(
                      onDiscover: () => context.pushNamed('home'),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD8F3DC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_album_outlined,
                            size: 48,
                            color: Color(0xFF2D6A4F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henuz gonderi yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ilk gonderiyi sen paylas!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(feedPaginatedProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posts.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == posts.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: state.loadingMore
                                ? const PawLoading()
                                : OutlinedButton.icon(
                                    onPressed: () => ref
                                        .read(feedPaginatedProvider.notifier)
                                        .loadMore(),
                                    icon: const Icon(Icons.expand_more),
                                    label: const Text('Daha Fazla Göster'),
                                  ),
                          ),
                        );
                      }
                      return PostCard(
                            post: posts[i],
                            currentUserId: currentUser?.id ?? '',
                            likedLocally: _likedLocally[posts[i].id],
                            likesLocal: _likesLocal[posts[i].id],
                            savedLocally: _savedLocally[posts[i].id],
                            savesLocal: _savesLocal[posts[i].id],
                            onLike: () => _handleLike(posts[i]),
                            onSave: () => _handleSave(posts[i]),
                            onComment: () => _showComments(context, posts[i]),
                            onDelete: currentUser?.id == posts[i].userId
                                ? () => _handleDelete(posts[i].id)
                                : null,
                            onHashtagTap: (tag) {
                              _hashtagNotifier.value = tag;
                              ref.read(feedPaginatedProvider.notifier).filterByHashtag(tag);
                            },
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
                      onPressed: () =>
                          ref.read(feedPaginatedProvider.notifier).refresh(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLike(Post post) async {
    final currentLiked = _likedLocally[post.id] ?? post.isLiked;
    setState(() {
      _likedLocally[post.id] = !currentLiked;
      _likesLocal[post.id] = post.likeCount + (currentLiked ? -1 : 1);
    });
    try {
      await ref.read(postRepositoryProvider).toggleLike(post.id);
    } catch (e) {
      setState(() {
        _likedLocally[post.id] = currentLiked;
        _likesLocal.remove(post.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Begeni islemi basarisiz: $e')));
      }
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
    } catch (e) {
      setState(() {
        _savedLocally[post.id] = currentSaved;
        _savesLocal.remove(post.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kaydetme islemi basarisiz: $e')));
      }
    }
  }

  Future<void> _handleDelete(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gonderiyi Sil'),
        content: const Text('Bu gonderiyi silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(postRepositoryProvider).deletePost(postId);
        ref.read(feedPaginatedProvider.notifier).refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
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
}

class PostCard extends StatelessWidget {
  final Post post;
  final String currentUserId;
  final bool? likedLocally;
  final int? likesLocal;
  final bool? savedLocally;
  final int? savesLocal;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback? onDelete;
  final void Function(String tag)? onHashtagTap;

  const PostCard({
    required this.post,
    required this.currentUserId,
    this.likedLocally,
    this.likesLocal,
    this.savedLocally,
    this.savesLocal,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    this.onDelete,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = likedLocally ?? post.isLiked;
    final likeCount = likesLocal ?? post.likeCount;
    final isSaved = savedLocally ?? post.isSaved;
    final saveCount = savesLocal ?? post.saveCount;
    final avatarLetter = post.userName.isNotEmpty
        ? post.userName[0].toUpperCase()
        : '?';
    final timeStr = post.createdAt != null
        ? DateFormat('d MMM, HH:mm', 'tr').format(post.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF2D6A4F),
                  backgroundImage:
                      post.userAvatar != null && post.userAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider(
                          '$apiBaseUrl${post.userAvatar}',
                        )
                      : null,
                  child: post.userAvatar == null || post.userAvatar!.isEmpty
                      ? Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (post.petName != null)
                        Row(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.petName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onDelete,
                    iconSize: 20,
                  ),
              ],
            ),
          ),

          // Content
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                post.content!,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

          // Photos
          if (post.photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: post.photos.length == 1
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(0),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: '$apiBaseUrl${post.photos[0]}',
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: post.photos.length,
                        itemBuilder: (ctx, i) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: '$apiBaseUrl${post.photos[i]}',
                              width: 180,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

          // Hashtags
          if (post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                children: post.hashtags.map((tag) => GestureDetector(
                  onTap: onHashtagTap != null ? () => onHashtagTap!(tag) : null,
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                _AnimatedLikeBtn(
                  isLiked: isLiked,
                  count: likeCount,
                  onTap: onLike,
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments.length}',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onTap: onComment,
                ),
                const Spacer(),
                _BookmarkBtn(
                  isSaved: isSaved,
                  count: saveCount,
                  onTap: onSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLikeBtn extends StatefulWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _AnimatedLikeBtn({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  State<_AnimatedLikeBtn> createState() => _AnimatedLikeBtnState();
}

class _AnimatedLikeBtnState extends State<_AnimatedLikeBtn> {
  bool _burst = false;

  void _handleTap() {
    setState(() => _burst = true);
    Future.delayed(250.ms, () {
      if (mounted) setState(() => _burst = false);
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLiked
        ? Colors.red
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            // Heart icon with scale burst animation
            AnimatedSwitcher(
                  duration: 160.ms,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(widget.isLiked),
                    color: color,
                    size: 22,
                  ),
                )
                .animate(target: _burst ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.35, 1.35),
                  duration: 120.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .scale(
                  end: const Offset(1, 1),
                  duration: 100.ms,
                  curve: Curves.easeIn,
                ),
            const SizedBox(width: 5),
            // Count with vertical slide animation
            AnimatedSwitcher(
              duration: 200.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                '${widget.count}',
                key: ValueKey(widget.count),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkBtn extends StatefulWidget {
  final bool isSaved;
  final int count;
  final VoidCallback onTap;

  const _BookmarkBtn({
    required this.isSaved,
    required this.count,
    required this.onTap,
  });

  @override
  State<_BookmarkBtn> createState() => _BookmarkBtnState();
}

class _BookmarkBtnState extends State<_BookmarkBtn> {
  bool _burst = false;

  void _handleTap() {
    setState(() => _burst = true);
    Future.delayed(250.ms, () {
      if (mounted) setState(() => _burst = false);
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSaved
        ? const Color(0xFF2D6A4F)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            AnimatedSwitcher(
                  duration: 160.ms,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(widget.isSaved),
                    color: color,
                    size: 22,
                  ),
                )
                .animate(target: _burst ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.3, 1.3),
                  duration: 120.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .scale(
                  end: const Offset(1, 1),
                  duration: 100.ms,
                  curve: Curves.easeIn,
                ),
            const SizedBox(width: 5),
            AnimatedSwitcher(
              duration: 200.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                '${widget.count}',
                key: ValueKey(widget.count),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowingEmptyState extends StatelessWidget {
  const _FollowingEmptyState({required this.onDiscover});
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFD8F3DC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF2D6A4F)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz takip ettiğin kullanıcı yok',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Kullanıcıları takip ederek onların gönderilerini buradan görebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onDiscover,
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Kullanıcı Keşfet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final Post post;
  final WidgetRef ref;

  const CommentsSheet({required this.post, required this.ref});

  @override
  State<CommentsSheet> createState() => CommentsSheetState();
}

class CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  final List<PostComment> _comments = [];
  bool _sending = false;

  // Reply state
  PostComment? _replyTo;
  final Map<String, bool> _expandedReplies = {};

  @override
  void initState() {
    super.initState();
    _comments.addAll(widget.post.comments);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startReply(PostComment comment) {
    setState(() => _replyTo = comment);
    _ctrl.text = '@${comment.userName} ';
    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
  }

  void _cancelReply() {
    setState(() => _replyTo = null);
    _ctrl.clear();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final repo = widget.ref.read(postRepositoryProvider);
      if (_replyTo != null) {
        final reply = await repo.addReply(widget.post.id, _replyTo!.id, text);
        setState(() {
          final idx = _comments.indexWhere((c) => c.id == _replyTo!.id);
          if (idx >= 0) {
            final updated = PostComment(
              id: _comments[idx].id,
              userId: _comments[idx].userId,
              userName: _comments[idx].userName,
              userAvatar: _comments[idx].userAvatar,
              text: _comments[idx].text,
              createdAt: _comments[idx].createdAt,
              replies: [..._comments[idx].replies, reply],
            );
            _comments[idx] = updated;
            _expandedReplies[_replyTo!.id] = true;
          }
          _replyTo = null;
        });
      } else {
        final comment = await repo.addComment(widget.post.id, text);
        setState(() => _comments.add(comment));
      }
      _ctrl.clear();
      widget.ref.read(feedPaginatedProvider.notifier).refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Yorumlar (${_comments.length})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _comments.isEmpty
                  ? Center(
                      child: Text(
                        'Henüz yorum yok. İlk yorumu sen yaz!',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.all(12),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        final expanded = _expandedReplies[c.id] ?? false;
                        final visibleReplies = expanded ? c.replies : c.replies.take(2).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Comment
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2D6A4F),
                                child: Text(
                                  c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                              title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.text),
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () => _startReply(c),
                                    child: const Text(
                                      'Yanıtla',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Replies
                            if (c.replies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...visibleReplies.map((r) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: const Color(0xFF52B788),
                                            child: Text(
                                              r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                                              style: const TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                Text(r.text, style: const TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                    if (c.replies.length > 2)
                                      GestureDetector(
                                        onTap: () => setState(() => _expandedReplies[c.id] = !expanded),
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            expanded
                                                ? 'Yanıtları gizle'
                                                : '${c.replies.length - 2} yanıt daha gör',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF4895EF), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            // Reply banner
            if (_replyTo != null)
              Container(
                color: const Color(0xFF2D6A4F).withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF2D6A4F)),
                    const SizedBox(width: 4),
                    Text(
                      '@${_replyTo!.userName} yanıtlanıyor',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF2D6A4F)),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: _replyTo != null ? '@${_replyTo!.userName} yanıtla...' : 'Bir yorum yaz...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const CircularProgressIndicator()
                      : IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF2D6A4F)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
