// lib/features/pets/presentation/widgets/pet_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';

class PetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final String ownerName = pet.owner?.name ?? '';
    final String avatarLetter = ownerName.isNotEmpty ? ownerName.substring(0, 1).toUpperCase() : '?';
    final heroTag = 'pet-image-${pet.id}';

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: _isPressed ? 0.97 : 1,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        elevation: 10,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            setState(() => _isPressed = value);
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PetImage(heroTag: heroTag, pet: pet),
              _PetInfoSection(
                pet: pet,
                ownerName: ownerName,
                avatarLetter: avatarLetter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetImage extends StatelessWidget {
  final String heroTag;
  final Pet pet;

  const _PetImage({required this.heroTag, required this.pet});

  @override
  Widget build(BuildContext context) {
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(20));
    final badgeColor = pet.advertType == 'mating' ? Colors.purple.shade200 : Colors.green.shade200;
    final badgeText = pet.advertType == 'mating' ? 'Eşleştirme' : 'Sahiplendirme';
    final badgeIcon = pet.advertType == 'mating' ? Icons.favorite : Icons.home;

    return Stack(
      children: [
        Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: pet.photos.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: '${AppConfig.current.apiBaseUrl}${pet.photos[0]}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFE5E3FF),
                              Color(0xFFFDE4DF),
                            ],
                          ),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Row(
            children: [
              _Badge(
                icon: Icons.category,
                label: pet.species,
              ),
              const SizedBox(width: 8),
              _Badge(
                icon: badgeIcon,
                label: badgeText,
                backgroundColor: badgeColor,
                foregroundColor: Colors.black87,
              ),
            ],
          ),
        ),
        if (pet.vaccinated)
          Positioned(
            top: 16,
            right: 16,
            child: _Badge(
              icon: Icons.verified,
              label: 'Aşılı',
              backgroundColor: Colors.greenAccent.shade200,
              foregroundColor: Colors.green.shade900,
            ),
          ),
        Positioned(
          bottom: 18,
          left: 20,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Text(
              pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        color: Colors.black38,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE5E3FF),
            Color(0xFFFDE4DF),
          ],
        ),
      ),
      child: Icon(
        Icons.pets,
        size: 76,
        color: AppPalette.primary.withOpacity(0.5),
      ),
    );
  }
}

class _PetInfoSection extends StatelessWidget {
  final Pet pet;
  final String ownerName;
  final String avatarLetter;

  const _PetInfoSection({
    required this.pet,
    required this.ownerName,
    required this.avatarLetter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.secondary.withOpacity(0.15),
                foregroundColor: AppPalette.secondary,
                child: Text(
                  avatarLetter,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ownerName.isNotEmpty ? ownerName : 'Bilinmiyor',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.cake_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('${pet.ageMonths} ay'),
              const SizedBox(width: 12),
              Icon(Icons.pets, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(pet.breed),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _Badge({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: foregroundColor ?? Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: foregroundColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
