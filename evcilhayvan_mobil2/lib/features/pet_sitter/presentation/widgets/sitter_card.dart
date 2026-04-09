import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import '../../domain/models/pet_sitter_model.dart';

class SitterCard extends StatelessWidget {
  final PetSitterModel sitter;
  final VoidCallback? onTap;

  const SitterCard({super.key, required this.sitter, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final rawPhoto = sitter.avatar?.isNotEmpty == true
        ? sitter.avatar!
        : (sitter.photos.isNotEmpty ? sitter.photos.first : '');

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(isDark ? 0.15 : 0.09),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar / Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    width: 112,
                    height: 130,
                    child: rawPhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolveImageUrl(rawPhoto),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ShimmerBox(height: 130),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: _AvailabilityDot(isAvailable: sitter.availability),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sitter.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sitter.isVerified) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D6A4F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          ),
                        ],
                      ],
                    ),
                    // Rating + distance
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                sitter.rating.toStringAsFixed(1),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.amber.shade800),
                              ),
                              Text(
                                ' (${sitter.reviewCount})',
                                style: TextStyle(fontSize: 10, color: Colors.amber.shade700),
                              ),
                            ],
                          ),
                        ),
                        if (sitter.distanceKm != null) ...[
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded, size: 12, color: theme.colorScheme.primary.withOpacity(0.7)),
                              const SizedBox(width: 2),
                              Text(
                                '${sitter.distanceKm!.toStringAsFixed(1)} km',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    // Services chips
                    if (sitter.services.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: sitter.services.take(3).map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.15), width: 0.8),
                          ),
                          child: Text(
                            s.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF2D6A4F),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )).toList(),
                      ),
                    // Price + availability
                    Row(
                      children: [
                        if (sitter.minPrice > 0)
                          Text(
                            '${sitter.minPrice.toInt()} TL\'den',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D6A4F),
                              fontSize: 13,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: sitter.availability
                                ? Colors.green.withOpacity(0.1)
                                : theme.colorScheme.onSurface.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sitter.availability ? Colors.green.withOpacity(0.3) : Colors.transparent,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            sitter.availability ? 'Müsait' : 'Dolu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sitter.availability
                                  ? Colors.green.shade700
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
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
    width: 112,
    height: 130,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: Icon(Icons.person_rounded, color: Colors.white30, size: 40)),
  );
}

class _AvailabilityDot extends StatefulWidget {
  final bool isAvailable;
  const _AvailabilityDot({required this.isAvailable});

  @override
  State<_AvailabilityDot> createState() => _AvailabilityDotState();
}

class _AvailabilityDotState extends State<_AvailabilityDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isAvailable) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAvailable) {
      return Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          child!,
        ],
      ),
      child: Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
