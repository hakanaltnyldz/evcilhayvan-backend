// lib/features/pets/presentation/widgets/pet_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/shimmer_box.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

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

String _formatAge(int months, AppLocalizations l10n) {
  if (months < 1) return '< 1 ay';
  if (months < 12) return '$months ay';
  final years = months ~/ 12;
  final rem = months % 12;
  if (rem == 0) return '$years yıl';
  return '$years yıl $rem ay';
}

String _resolveSpecies(String species, AppLocalizations l10n) {
  switch (species) {
    case 'dog':    return l10n.speciesDog;
    case 'cat':    return l10n.speciesCat;
    case 'bird':   return l10n.speciesBird;
    case 'fish':   return l10n.speciesFish;
    case 'rodent': return l10n.speciesHamster;
    case 'other':  return l10n.speciesOther;
    default:       return species;
  }
}

class _PetCardState extends State<PetCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(20));
    final badgeColor = pet.advertType == 'mating' ? Colors.pink.shade200 : const Color(0xFFD8F3DC);
    final badgeText = pet.advertType == 'mating' ? l10n.petCardMating : l10n.petCardAdoption;
    final badgeIcon = pet.advertType == 'mating' ? Icons.favorite : Icons.home;

    return Stack(
      children: [
        Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: pet.photos.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: '${AppConfig.current.apiBaseUrl}${pet.photos[0]}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerBox(height: 170),
                      errorWidget: (context, url, error) => _fallback(context),
                    )
                  : _fallback(context),
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
                label: _resolveSpecies(pet.species, l10n),
              ),
              const SizedBox(width: 8),
              _Badge(
                icon: badgeIcon,
                label: badgeText,
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
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
              label: AppLocalizations.of(context)!.petCardVaccinated,
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

  Widget _fallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2E28), const Color(0xFF2D4A3E)]
              : [const Color(0xFFD8F3DC), const Color(0xFFEDF7F0)],
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFD8F3DC),
                foregroundColor: const Color(0xFF2D6A4F),
                child: Text(
                  avatarLetter,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ownerName.isNotEmpty ? ownerName : l10n.petCardOwnerUnknown,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                icon: Icons.cake_outlined,
                label: _formatAge(pet.ageMonths, l10n),
                bgColor: const Color(0xFFD8F3DC),
                iconColor: const Color(0xFF2D6A4F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  icon: Icons.pets,
                  label: pet.breed,
                  bgColor: Colors.grey.shade100,
                  iconColor: Colors.grey.shade600,
                ),
              ),
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
        color: backgroundColor ?? Theme.of(context).colorScheme.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: foregroundColor ?? Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
