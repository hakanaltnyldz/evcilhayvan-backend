// lib/features/reviews/presentation/widgets/reviews_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/reviews/domain/models/review_model.dart';
import 'package:evcilhayvan_mobil2/features/reviews/presentation/screens/add_review_screen.dart';
import 'package:evcilhayvan_mobil2/features/reviews/presentation/widgets/star_rating.dart';
import 'package:evcilhayvan_mobil2/features/reviews/providers/review_providers.dart';

class ReviewsSection extends ConsumerWidget {
  final String productId;
  final String productName;

  const ReviewsSection({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(reviewStatsProvider(productId));
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final canReviewAsync = ref.watch(canReviewProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add review button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.reviewsSectionTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              canReviewAsync.when(
                data: (result) {
                  final canReview = result['canReview'] == true;
                  final existingReview =
                      result['existingReview'] as ReviewModel?;

                  if (!canReview && existingReview == null) {
                    return const SizedBox.shrink();
                  }

                  return TextButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddReviewScreen(
                            productId: productId,
                            productName: productName,
                            existingReview: existingReview,
                          ),
                        ),
                      );

                      if (updated == true) {
                        ref.invalidate(productReviewsProvider);
                        ref.invalidate(reviewStatsProvider);
                      }
                    },
                    icon: Icon(
                      existingReview != null ? Icons.edit : Icons.add,
                      size: 18,
                    ),
                    label: Text(
                      existingReview != null
                          ? AppLocalizations.of(context)!.reviewsSectionEdit
                          : AppLocalizations.of(context)!.reviewsSectionAdd,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // Stats summary
        statsAsync.when(
          data: (stats) {
            if (stats.totalReviews == 0) {
              return _EmptyReviews();
            }

            return Column(
              children: [
                _StatsSummary(stats: stats),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const _StatsSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Reviews list
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: reviews.map((review) {
                return _ReviewCard(review: review);
              }).toList(),
            );
          },
          loading: () => Column(
            children: List.generate(3, (_) => const _ReviewCardSkeleton()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.reviewsLoadErr(error.toString()),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsSummary extends StatelessWidget {
  final ReviewStats stats;

  const _StatsSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.storeSoftColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Average rating
          Column(
            children: [
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppPalette.storePrimary,
                ),
              ),
              const SizedBox(height: 4),
              StarRating(rating: stats.averageRating, size: 18),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.reviewsCount(stats.totalReviews),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Distribution
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((rating) {
                final count = stats.distribution[rating] ?? 0;
                final percentage = stats.getPercentage(rating);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: context.subtleBorder,
                            valueColor: const AlwaysStoppedAnimation(
                              AppPalette.storePrimary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: theme.textTheme.bodySmall,
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
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  String _formatDate(BuildContext context, DateTime date) {
    try {
      return DateFormat(
        'dd MMM yyyy',
        Localizations.localeOf(context).toString(),
      ).format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.subtleBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: review.user.profilePicture != null
                    ? NetworkImage('$apiBaseUrl${review.user.profilePicture}')
                    : null,
                child: review.user.profilePicture == null
                    ? Text(
                        review.user.name.isNotEmpty
                            ? review.user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.user.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.verifiedPurchase)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppPalette.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.reviewsVerifiedBuyer,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StarRating(
                          rating: review.rating.toDouble(),
                          size: 14,
                          allowHalf: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(context, review.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.storeSoftColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppPalette.storePrimary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.reviewsEmptyTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.reviewsEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 120,
      decoration: BoxDecoration(
        color: context.storeSoftColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      height: 100,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.subtleBorder, width: 1),
      ),
    );
  }
}
