import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';

import '../../domain/models/pet_sitter_model.dart';

class SitterCard extends StatelessWidget {
  final PetSitterModel sitter;
  final VoidCallback? onTap;

  const SitterCard({super.key, required this.sitter, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = sitter.avatar?.isNotEmpty == true
        ? sitter.avatar!
        : (sitter.photos.isNotEmpty ? sitter.photos.first : '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF52B788).withOpacity(0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(photo: photo, name: sitter.displayName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sitter.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF1B4332),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (sitter.isVerified)
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF2D6A4F),
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaChip(
                            icon: Icons.star_rounded,
                            label:
                                '${sitter.rating.toStringAsFixed(1)} (${sitter.reviewCount})',
                            foreground: Colors.amber.shade900,
                            background: Colors.amber.shade50,
                          ),
                          if (sitter.distanceKm != null)
                            _MetaChip(
                              icon: Icons.near_me_rounded,
                              label:
                                  '${sitter.distanceKm!.toStringAsFixed(1)} km',
                              foreground: const Color(0xFF2D6A4F),
                              background: const Color(0xFFD8F3DC),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        sitter.services.isNotEmpty
                            ? sitter.services.take(3).map((s) => s.label).join(' • ')
                            : 'Hizmet bilgisi eklenmemiş',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52796F),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sitter.speciesLabel.isNotEmpty
                            ? sitter.speciesLabel
                            : 'Tür bilgisi eklenmemiş',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            sitter.minPrice > 0
                                ? '${sitter.minPrice.toInt()} TL\'den'
                                : 'Fiyat belirtilmemiş',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF1B4332),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: sitter.availability
                                  ? const Color(0xFFD8F3DC)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              sitter.availability ? 'Müsait' : 'Dolu',
                              style: TextStyle(
                                color: sitter.availability
                                    ? const Color(0xFF2D6A4F)
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String photo;
  final String name;

  const _Avatar({required this.photo, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 84,
        height: 84,
        child: photo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: resolveImageUrl(photo),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(initial),
              )
            : _fallback(initial),
      ),
    );
  }

  Widget _fallback(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF52B788)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
