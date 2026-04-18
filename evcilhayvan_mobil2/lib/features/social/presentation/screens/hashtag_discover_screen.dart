import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import '../../data/repositories/post_repository.dart';

class HashtagDiscoverScreen extends ConsumerWidget {
  const HashtagDiscoverScreen({super.key});

  static const List<Color> _chipColors = [
    Color(0xFF2D6A4F),
    Color(0xFF4895EF),
    Color(0xFFF4A261),
    Color(0xFFE63946),
    Color(0xFF7B2FBE),
    Color(0xFF52B788),
    Color(0xFFFFB300),
    Color(0xFF00B4D8),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hashtagsAsync = ref.watch(trendingHashtagsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Hashtag Keşfet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: hashtagsAsync.when(
        data: (hashtags) {
          if (hashtags.isEmpty) {
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
                    child: const Icon(Icons.tag_rounded, size: 44, color: Color(0xFF2D6A4F)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz hashtag yok',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gönderi paylaşırken #etiket ekle',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(trendingHashtagsProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Trend Etiketler',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(hashtags.length, (i) {
                        final item = hashtags[i];
                        final tag = item['tag'] as String? ?? '';
                        final count = item['count'] as int? ?? 0;
                        final color = _chipColors[i % _chipColors.length];
                        return _HashtagChip(
                          tag: tag,
                          count: count,
                          color: color,
                          onTap: () {
                            ref.read(feedPaginatedProvider.notifier).filterByHashtag(tag);
                            context.pop();
                          },
                        )
                            .animate(delay: Duration(milliseconds: i * 40))
                            .fadeIn(duration: 250.ms)
                            .scale(begin: const Offset(0.85, 0.85));
                      }),
                    ),
                  ),
                ),
              ],
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
                onPressed: () => ref.invalidate(trendingHashtagsProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String tag;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _HashtagChip({
    required this.tag,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag_rounded, color: color, size: 15),
            const SizedBox(width: 3),
            Text(
              tag,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
