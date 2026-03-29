import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/pet_sitter_model.dart';

class SitterCard extends StatelessWidget {
  final PetSitterModel sitter;
  final VoidCallback? onTap;

  const SitterCard({super.key, required this.sitter, this.onTap});

  String _resolveUrl(String url) => url.startsWith('http') ? url : '$apiBaseUrl$url';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = sitter.avatar?.isNotEmpty == true ? sitter.avatar! : (sitter.photos.isNotEmpty ? sitter.photos.first : '');

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: SizedBox(
                width: 110,
                height: 120,
                child: photo.isNotEmpty
                    ? CachedNetworkImage(imageUrl: _resolveUrl(photo), fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(sitter.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (sitter.isVerified)
                          const Icon(Icons.verified, color: Color(0xFF2D6A4F), size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text('${sitter.rating.toStringAsFixed(1)} (${sitter.reviewCount})',
                            style: theme.textTheme.bodySmall),
                        if (sitter.distanceKm != null) ...[
                          const SizedBox(width: 8),
                          Text('${sitter.distanceKm!.toStringAsFixed(1)} km',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Services chips
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: sitter.services.take(3).map((s) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer)),
                        ),
                      ).toList(),
                    ),
                    const SizedBox(height: 6),
                    // Price + availability
                    Row(
                      children: [
                        if (sitter.minPrice > 0)
                          Text('${sitter.minPrice.toInt()} TL\'den',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sitter.availability ? Colors.green.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            sitter.availability ? 'Musait' : 'Dolu',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: sitter.availability ? Colors.green.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFD8F3DC),
    child: const Center(child: Icon(Icons.person, color: Color(0xFF2D6A4F), size: 40)),
  );
}
