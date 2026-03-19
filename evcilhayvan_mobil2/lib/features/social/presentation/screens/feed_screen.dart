import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post_model.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final Map<String, bool> _likedLocally = {};
  final Map<String, int> _likesLocal = {};

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Sosyal Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Gonderi Paylas',
            onPressed: () async {
              final result = await context.pushNamed<bool>('create-post');
              if (result == true) ref.invalidate(feedProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.pushNamed<bool>('create-post');
          if (result == true) ref.invalidate(feedProvider);
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Paylas'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_album_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Henuz gonderi yok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Ilk gonderiyi sen paylas!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(feedProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (ctx, i) => _PostCard(
                post: posts[i],
                currentUserId: currentUser?.id ?? '',
                likedLocally: _likedLocally[posts[i].id],
                likesLocal: _likesLocal[posts[i].id],
                onLike: () => _handleLike(posts[i]),
                onComment: () => _showComments(context, posts[i]),
                onDelete: currentUser?.id == posts[i].userId
                    ? () => _handleDelete(posts[i].id)
                    : null,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(feedProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLike(Post post) async {
    final currentLiked = _likedLocally[post.id] ?? post.likes.contains(ref.read(authProvider)?.id);
    setState(() {
      _likedLocally[post.id] = !currentLiked;
      _likesLocal[post.id] = (post.likes.length) + (currentLiked ? -1 : 1);
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

  Future<void> _handleDelete(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gonderiyi Sil'),
        content: const Text('Bu gonderiyi silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Iptal')),
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
        ref.invalidate(feedProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post, ref: ref),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final String currentUserId;
  final bool? likedLocally;
  final int? likesLocal;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onDelete;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    this.likedLocally,
    this.likesLocal,
    required this.onLike,
    required this.onComment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = likedLocally ?? post.likes.contains(currentUserId);
    final likeCount = likesLocal ?? post.likes.length;
    final avatarLetter = post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?';
    final timeStr = post.createdAt != null
        ? DateFormat('d MMM, HH:mm', 'tr').format(post.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
                  backgroundColor: const Color(0xFF6C63FF),
                  backgroundImage: post.userAvatar != null && post.userAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider('$apiBaseUrl${post.userAvatar}')
                      : null,
                  child: post.userAvatar == null || post.userAvatar!.isEmpty
                      ? Text(avatarLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (post.petName != null)
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(post.petName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      if (timeStr.isNotEmpty)
                        Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
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
              child: Text(post.content!, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),

          // Photos
          if (post.photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: post.photos.length == 1
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                      child: CachedNetworkImage(
                        imageUrl: '$apiBaseUrl${post.photos[0]}',
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
                  color: Colors.grey,
                  onTap: onComment,
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

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

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
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
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

  const _AnimatedLikeBtn({required this.isLiked, required this.count, required this.onTap});

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
    final color = widget.isLiked ? Colors.red : Colors.grey;

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
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(widget.isLiked),
                color: color,
                size: 22,
              ),
            )
                .animate(target: _burst ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.35, 1.35), duration: 120.ms, curve: Curves.easeOut)
                .then()
                .scale(end: const Offset(1, 1), duration: 100.ms, curve: Curves.easeIn),
            const SizedBox(width: 5),
            // Count with vertical slide animation
            AnimatedSwitcher(
              duration: 200.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
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

class _CommentsSheet extends StatefulWidget {
  final Post post;
  final WidgetRef ref;

  const _CommentsSheet({required this.post, required this.ref});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final List<PostComment> _comments = [];
  bool _sending = false;

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

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await widget.ref.read(postRepositoryProvider).addComment(widget.post.id, text);
      setState(() => _comments.add(comment));
      _ctrl.clear();
      widget.ref.invalidate(feedProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: ctx.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Yorumlar (${_comments.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: _comments.isEmpty
                  ? const Center(child: Text('Henuz yorum yok. Ilk yorumu sen yaz!', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.all(12),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        final letter = c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF6C63FF),
                            child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(c.text),
                        );
                      },
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
                        hintText: 'Bir yorum yaz...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
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
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF6C63FF)),
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
