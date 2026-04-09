import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/veterinary_model.dart';

class VetCard extends StatelessWidget {
  final VeterinaryModel vet;
  final VoidCallback? onTap;
  final double? distanceKm;

  const VetCard({super.key, required this.vet, this.onTap, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = vet.photos.isNotEmpty ? resolveImageUrl(vet.photos.first) : null;
    final isDark = context.isDark;

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(isDark ? 0.15 : 0.1),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo with gradient overlay ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 148,
                    width: double.infinity,
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ShimmerBox(height: 148),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  // Gradient overlay for text readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Verified badge top-right
                  if (vet.isVerified)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Onaylı', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  // Online randevu badge top-left
                  if (vet.acceptsOnlineAppointments)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 10, color: Color(0xFF2D6A4F)),
                            SizedBox(width: 4),
                            Text('Online Randevu', style: TextStyle(color: Color(0xFF1B4332), fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  // Vet name bottom-left
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      vet.name,
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
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address
                  if (vet.address != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFF52B788)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vet.address!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Rating + Distance row
                  Row(
                    children: [
                      if (vet.googleRating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                              const SizedBox(width: 3),
                              Text(
                                vet.googleRating!.toStringAsFixed(1),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.amber.shade800),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '(${vet.googleReviewCount})',
                                style: TextStyle(fontSize: 11, color: Colors.amber.shade700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8F3DC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk, size: 14, color: Color(0xFF2D6A4F)),
                              const SizedBox(width: 3),
                              Text(
                                distanceKm! < 1
                                    ? '${(distanceKm! * 1000).round()} m'
                                    : '${distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 148,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_hospital_rounded, size: 56, color: Colors.white24),
      ),
    );
  }
}
