import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/store/data/order_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _reviewsPageProvider = StateProvider.autoDispose<int>((ref) => 1);
final _ratingFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

final _sellerReviewsProvider = FutureProvider.autoDispose.family<SellerReviewsResponse, (int, int?)>(
  (ref, args) {
    final repo = ref.watch(orderRepositoryProvider);
    return repo.getSellerReviews(page: args.$1, rating: args.$2);
  },
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class SellerReviewsScreen extends ConsumerStatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  ConsumerState<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends ConsumerState<SellerReviewsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final page = ref.read(_reviewsPageProvider);
      final filter = ref.read(_ratingFilterProvider);
      final asyncVal = ref.read(_sellerReviewsProvider((page, filter)));
      asyncVal.whenData((data) {
        if (page < data.totalPages) {
          ref.read(_reviewsPageProvider.notifier).state = page + 1;
        }
      });
    }
  }

  void _applyFilter(int? rating) {
    ref.read(_ratingFilterProvider.notifier).state = rating;
    ref.read(_reviewsPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(_reviewsPageProvider);
    final filter = ref.watch(_ratingFilterProvider);
    final reviewsAsync = ref.watch(_sellerReviewsProvider((page, filter)));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Müşteri Yorumları',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.read(_reviewsPageProvider.notifier).state = 1;
              ref.invalidate(_sellerReviewsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary + filter row ──────────────────────────────────
          reviewsAsync.when(
            data: (data) => _SummaryBar(data: data, currentFilter: filter, onFilter: _applyFilter),
            loading: () => const _SummaryBarSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Review list ───────────────────────────────────────────
          Expanded(
            child: reviewsAsync.when(
              data: (data) {
                if (data.reviews.isEmpty) {
                  return _EmptyReviews(hasFilter: filter != null);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(_reviewsPageProvider.notifier).state = 1;
                    ref.invalidate(_sellerReviewsProvider);
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: data.reviews.length + (page < data.totalPages ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == data.reviews.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: PawLoading()),
                        );
                      }
                      return _ReviewCard(review: data.reviews[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: PawLoading()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Yorumlar yüklenemedi', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.read(_reviewsPageProvider.notifier).state = 1;
                        ref.invalidate(_sellerReviewsProvider);
                      },
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
}

// ─── Summary Bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final SellerReviewsResponse data;
  final int? currentFilter;
  final void Function(int?) onFilter;
  const _SummaryBar({required this.data, required this.currentFilter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avg rating + star breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big rating
              Column(
                children: [
                  Text(
                    data.avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.primary,
                      height: 1,
                    ),
                  ),
                  _StarRow(rating: data.avgRating.round(), size: 14),
                  const SizedBox(height: 2),
                  Text(
                    '${data.total} yorum',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Breakdown bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = data.ratingBreakdown[star] ?? 0;
                    final pct = data.total > 0 ? count / data.total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const Icon(Icons.star, size: 10, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                                minHeight: 7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Tümü', selected: currentFilter == null, onTap: () => onFilter(null)),
                const SizedBox(width: 6),
                for (final star in [5, 4, 3, 2, 1]) ...[
                  _FilterChip(
                    label: '$star★',
                    selected: currentFilter == star,
                    onTap: () => onFilter(star == currentFilter ? null : star),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SummaryBarSkeleton extends StatelessWidget {
  const _SummaryBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Theme.of(context).cardColor,
      child: const Center(child: PawLoading()),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppPalette.primary : AppPalette.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppPalette.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Review Card ─────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final SellerReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + date
          Row(
            children: [
              Expanded(
                child: Text(
                  review.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppPalette.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // User + rating row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppPalette.primary.withOpacity(0.15),
                backgroundImage: review.userAvatar != null && review.userAvatar!.isNotEmpty
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null || review.userAvatar!.isEmpty
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'K',
                        style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w700, fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              _StarRow(rating: review.rating, size: 14),
              const SizedBox(width: 4),
              Text(
                '${review.rating}.0',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, height: 1.4),
            ),
          ],
          if (review.verifiedPurchase) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified_outlined, size: 13, color: Colors.green[600]),
                const SizedBox(width: 3),
                Text(
                  'Doğrulanmış Satın Alma',
                  style: TextStyle(color: Colors.green[600], fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// ─── Star Row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFC107),
          size: size,
        );
      }),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyReviews extends StatelessWidget {
  final bool hasFilter;
  const _EmptyReviews({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Bu filtreye ait yorum yok' : 'Henüz yorum almadınız',
              style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
