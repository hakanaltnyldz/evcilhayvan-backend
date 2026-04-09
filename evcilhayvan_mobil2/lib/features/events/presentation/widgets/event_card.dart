import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import '../../domain/models/pet_event_model.dart';

class EventCard extends StatelessWidget {
  final PetEventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  Color _categoryColor() {
    switch (event.category) {
      case 'park_meetup':  return const Color(0xFF2D6A4F);
      case 'adoption_day': return const Color(0xFFF2994A);
      case 'training':     return const Color(0xFF1B4332);
      case 'competition':  return const Color(0xFF52B788);
      case 'grooming':     return const Color(0xFF40916C);
      case 'health':       return const Color(0xFFEB5757);
      default:             return const Color(0xFF74C69D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final fmt = DateFormat('dd MMM, HH:mm');
    final catColor = _categoryColor();
    final photo = event.firstPhoto;
    final photoUrl = photo.isNotEmpty ? resolveImageUrl(photo) : null;

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: catColor.withOpacity(isDark ? 0.12 : 0.10),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover image ──
              Stack(
                children: [
                  SizedBox(
                    height: 165,
                    width: double.infinity,
                    child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ShimmerBox(height: 165),
                            errorWidget: (_, __, ___) => _NoPhotoPlaceholder(color: catColor),
                          )
                        : _NoPhotoPlaceholder(color: catColor),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Cancelled overlay
                  if (event.isCancelled)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'İPTAL EDİLDİ',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ),
                  // Category badge top-left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _CategoryBadge(label: event.categoryLabel, color: catColor),
                  ),
                  // Going badge top-right
                  if (event.isGoing)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Katılıyorum', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  // Title on image (bottom)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      event.title,
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

              // ── Info section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + Distance
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: catColor),
                              const SizedBox(width: 4),
                              Text(
                                fmt.format(event.startDate),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: catColor),
                              ),
                            ],
                          ),
                        ),
                        if (event.distanceKm != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_rounded, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 3),
                                Text(
                                  '${event.distanceKm!.toStringAsFixed(1)} km',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Venue
                    if (event.venueName != null || event.address != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.venueName ?? event.address ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Attendees + Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group_rounded, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                event.maxAttendees != null
                                    ? '${event.attendeeCount}/${event.maxAttendees}'
                                    : '${event.attendeeCount} katılımcı',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: event.isFree ? Colors.green.withOpacity(0.1) : catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: event.isFree ? Colors.green.withOpacity(0.3) : catColor.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            event.isFree ? 'Ücretsiz' : '${event.price.toInt()} TL',
                            style: TextStyle(
                              color: event.isFree ? Colors.green.shade700 : catColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
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
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  final Color color;
  const _NoPhotoPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.event_rounded, color: Colors.white.withOpacity(0.4), size: 56),
    );
  }
}
