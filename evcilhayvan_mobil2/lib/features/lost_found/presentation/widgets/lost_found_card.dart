import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import '../../domain/models/lost_found_model.dart';

class LostFoundCard extends StatelessWidget {
  final LostFoundPet report;
  final VoidCallback? onTap;

  const LostFoundCard({super.key, required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final dateStr = DateFormat('dd MMM yyyy').format(report.lastSeenDate);
    final isLost = report.isLost;
    final accentColor = isLost ? const Color(0xFFEB5757) : const Color(0xFF2D6A4F);

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDark ? 0.15 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo ──
              Stack(
                children: [
                  SizedBox(
                    height: 185,
                    width: double.infinity,
                    child: report.firstPhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolveImageUrl(report.firstPhoto),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ShimmerBox(height: 185),
                            errorWidget: (_, __, ___) => _noPhotoPlaceholder(isLost, accentColor),
                          )
                        : _noPhotoPlaceholder(isLost, accentColor),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isLost ? Icons.search_rounded : Icons.pets_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            isLost ? 'KAYIP' : 'BULUNAN',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Reward badge
                  if (report.hasReward)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${report.reward.toInt()} TL',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Reunited overlay
                  if (report.isReunited)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF2D6A4F).withOpacity(0.75),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'KAVUŞTURULDU',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Pet name on image
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      report.petName?.isNotEmpty == true
                          ? report.petName!
                          : '${report.speciesLabel} (${report.color})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Info ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    // Species + gender
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withOpacity(0.15), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets_rounded, size: 12, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            '${report.speciesLabel} · ${report.genderLabel}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Address + distance row (if available)
              if (report.lastSeenAddress?.isNotEmpty == true || report.distanceKm != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      if (report.lastSeenAddress?.isNotEmpty == true) ...[
                        Icon(Icons.location_on_rounded, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.lastSeenAddress!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (report.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8F3DC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${report.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noPhotoPlaceholder(bool isLost, Color color) {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isLost ? Icons.search_rounded : Icons.pets_rounded,
          size: 60,
          color: Colors.white.withOpacity(0.35),
        ),
      ),
    );
  }
}
