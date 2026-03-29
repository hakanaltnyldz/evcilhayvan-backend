import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/pet_event_model.dart';

class EventCard extends StatelessWidget {
  final PetEventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  Color _categoryColor() {
    switch (event.category) {
      case 'park_meetup': return Colors.green;
      case 'adoption_day': return Colors.orange;
      case 'training': return const Color(0xFF2D6A4F);
      case 'competition': return const Color(0xFF52B788);
      case 'grooming': return const Color(0xFF40916C);
      case 'health': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    final catColor = _categoryColor();
    final photo = event.firstPhoto;
    final photoUrl = photo.isNotEmpty
        ? (photo.startsWith('http') ? photo : '$apiBaseUrl$photo')
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            if (photoUrl != null)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: photoUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 160, color: Theme.of(context).colorScheme.surfaceVariant),
                    errorWidget: (_, __, ___) => _NoPhotoPlaceholder(color: catColor),
                  ),
                  if (event.isCancelled)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const Text('IPTAL EDILDI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _CategoryBadge(label: event.categoryLabel, color: catColor),
                  ),
                  if (event.isGoing)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Katiliyorum', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              )
            else
              Stack(
                children: [
                  _NoPhotoPlaceholder(color: catColor),
                  Positioned(
                    top: 10, left: 10,
                    child: _CategoryBadge(label: event.categoryLabel, color: catColor),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(fmt.format(event.startDate), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      if (event.distanceKm != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text('${event.distanceKm!.toStringAsFixed(1)} km', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ],
                  ),
                  if (event.address != null || event.venueName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venueName ?? event.address ?? '',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AttendeeChip(count: event.attendeeCount, max: event.maxAttendees),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: event.isFree ? Colors.green.withOpacity(0.1) : const Color(0xFF2D6A4F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.isFree ? 'Ucretsiz' : '${event.price.toInt()} TL',
                          style: TextStyle(
                            color: event.isFree ? const Color(0xFF52B788) : const Color(0xFF2D6A4F),
                            fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _AttendeeChip extends StatelessWidget {
  final int count;
  final int? max;
  const _AttendeeChip({required this.count, this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.group, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          max != null ? '$count/$max katilimci' : '$count katilimci',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  final Color color;
  const _NoPhotoPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: color.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(Icons.event, color: color.withOpacity(0.5), size: 40),
    );
  }
}
