import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import '../../domain/models/veterinary_model.dart';

class VetCard extends StatelessWidget {
  final VeterinaryModel vet;
  final VoidCallback? onTap;
  final double? distanceKm;

  const VetCard({super.key, required this.vet, this.onTap, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = vet.photos.isNotEmpty ? _resolveUrl(vet.photos.first) : null;

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : const ShimmerBox(height: 140),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(vet.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (vet.isVerified)
                        const Icon(Icons.verified, color: Colors.blue, size: 18),
                    ],
                  ),
                  if (vet.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppPalette.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(vet.address!, style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (vet.googleRating != null) ...[
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 2),
                        Text('${vet.googleRating!.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(${vet.googleReviewCount})', style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.onSurfaceVariant)),
                        const SizedBox(width: 12),
                      ],
                      if (distanceKm != null) ...[
                        const Icon(Icons.directions_walk, size: 14, color: AppPalette.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          distanceKm! < 1 ? '${(distanceKm! * 1000).round()} m' : '${distanceKm!.toStringAsFixed(1)} km',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (vet.acceptsOnlineAppointments)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Online Randevu', style: theme.textTheme.labelSmall?.copyWith(color: AppPalette.tertiary, fontWeight: FontWeight.w600)),
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
      color: AppPalette.background,
      child: const Center(child: Icon(Icons.local_hospital, size: 48, color: AppPalette.onSurfaceVariant)),
    );
  }

  String? _resolveUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$apiBaseUrl$path';
  }
}
