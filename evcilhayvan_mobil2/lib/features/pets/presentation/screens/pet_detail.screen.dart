// lib/features/pets/presentation/screens/pet_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../mating/data/repositories/mating_repository.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../adoption/data/repositories/adoption_repository.dart';

final petDetailProvider = FutureProvider.autoDispose.family<Pet, String>((ref, petId) {
  final repository = ref.watch(petsRepositoryProvider);
  return repository.getPetById(petId);
});

class PetDetailScreen extends ConsumerWidget {
  final String petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsyncValue = ref.watch(petDetailProvider(petId));
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      body: petAsyncValue.when(
        data: (pet) {
          final bool isOwner = (currentUser?.id == pet.owner?.id);

          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPalette.heroGradient.first.withOpacity(0.1),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Hero Image with App Bar
                  _buildSliverAppBar(context, pet),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Name and Type Badge
                          _buildNameSection(context, pet),
                          const SizedBox(height: 20),

                          // Quick Info Cards
                          _buildQuickInfoCards(context, pet),
                          const SizedBox(height: 24),

                          // Bio Section
                          if (pet.bio?.isNotEmpty == true) ...[
                            _buildBioSection(context, pet),
                            const SizedBox(height: 24),
                          ],

                          // Details Grid
                          _buildDetailsSection(context, pet),
                          const SizedBox(height: 24),

                          // Health Info
                          _buildHealthSection(context, pet),
                          const SizedBox(height: 24),

                          // Location Section
                          if (pet.latitude != null && pet.longitude != null) ...[
                            _LocationSection(pet: pet),
                            const SizedBox(height: 24),
                          ],

                          // Owner Section
                          _buildOwnerSection(context, pet),
                          const SizedBox(height: 16),

                          // Owner Banner (if owner)
                          if (isOwner) ...[
                            _buildOwnerBanner(context),
                            const SizedBox(height: 12),
                            // Health Journal shortcut for owners
                            OutlinedButton.icon(
                              onPressed: () => context.pushNamed(
                                'health-journal',
                                pathParameters: {'petId': pet.id},
                                extra: {'petName': pet.name},
                              ),
                              icon: const Icon(Icons.health_and_safety_outlined),
                              label: const Text('Sağlık Günlüğü'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Bottom padding for action buttons
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Action Buttons
              if (currentUser != null && !isOwner)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ActionButtons(pet: pet),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'İlan yüklenemedi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQrCard(BuildContext context, Pet pet) {
    final ageLabel = pet.ageMonths >= 12
        ? '${pet.ageMonths ~/ 12} yas${pet.ageMonths % 12 > 0 ? ' ${pet.ageMonths % 12} ay' : ''}'
        : '${pet.ageMonths} aylik';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baslik
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppPalette.accentGradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${pet.species} • ${pet.breed}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // QR Kod
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: QrImageView(
                  data: 'evcilhayvan://pet/${pet.id}',
                  version: QrVersions.auto,
                  size: 200,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF6C63FF)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),
              // Bilgiler
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _QrInfoRow(label: 'Yas', value: ageLabel, icon: Icons.cake_outlined),
                    const SizedBox(height: 6),
                    _QrInfoRow(label: 'Cinsiyet', value: pet.gender, icon: Icons.wc_outlined),
                    const SizedBox(height: 6),
                    _QrInfoRow(
                      label: 'Asi',
                      value: pet.vaccinated ? 'Tam' : 'Eksik',
                      icon: Icons.vaccines_outlined,
                      valueColor: pet.vaccinated ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ID kopyala
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pet.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ID panoya kopyalandi'), duration: Duration(seconds: 2)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text('ID: ${pet.id.substring(0, 8)}...'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageZoom(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  shape: const CircleBorder(),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildSliverAppBar(BuildContext context, Pet pet) {
    final heroTag = 'pet-image-${pet.id}';

    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      backgroundColor: AppPalette.heroGradient.first,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        FavoriteButton(
          itemType: 'pet',
          itemId: pet.id,
          showBackground: true,
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Paylaş',
            onPressed: () {
              HapticFeedback.lightImpact();
              Share.share(
                '${pet.name} - Pati Arkadaşı uygulamasında keşfet!',
                subject: '${pet.name} ilanı',
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
            tooltip: 'QR Kimlik Karti',
            onPressed: () => _showQrCard(context, pet),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            GestureDetector(
              onTap: pet.photos.isNotEmpty
                  ? () => _showImageZoom(context, '$apiBaseUrl${pet.photos[0]}')
                  : null,
              child: Hero(
                tag: heroTag,
                child: pet.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: '$apiBaseUrl${pet.photos[0]}',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppPalette.heroGradient.first.withOpacity(0.3),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                        errorWidget: (_, __, ___) => _buildPlaceholderImage(context),
                      )
                    : _buildPlaceholderImage(context),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Status badge
            Positioned(
              top: 100,
              right: 16,
              child: _buildStatusBadge(context, pet),
            ),
            // Advert type badge
            Positioned(
              top: 100,
              left: 16,
              child: _buildAdvertTypeBadge(context, pet),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.heroGradient.first.withOpacity(0.5),
            AppPalette.heroGradient.last.withOpacity(0.5),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.pets, size: 100, color: Colors.white54),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pet.isActive ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pet.isActive ? Icons.check_circle : Icons.pause_circle,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            pet.isActive ? 'Yayında' : 'Pasif',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertTypeBadge(BuildContext context, Pet pet) {
    final isMating = pet.advertType == 'mating';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isMating ? Colors.pink : Colors.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMating ? Icons.favorite : Icons.pets,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isMating ? 'Eşleştirme' : 'Sahiplendirme',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, Pet pet) {
    final hasCoordinates = pet.latitude != null && pet.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pet.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.white.withOpacity(0.9),
              size: 18,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                hasCoordinates
                    ? 'Konum paylaşıldı'
                    : 'Konum bilgisi yok',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppPalette.accentGradient),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.pets, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet.species,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pet.breed.isNotEmpty ? pet.breed : 'Cins belirtilmemiş',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCards(BuildContext context, Pet pet) {
    final ageInYears = pet.ageMonths ~/ 12;
    final remainingMonths = pet.ageMonths % 12;
    final ageLabel = ageInYears > 0
        ? '$ageInYears yaş${remainingMonths > 0 ? ' $remainingMonths ay' : ''}'
        : '${pet.ageMonths} aylık';

    return Row(
      children: [
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.cake,
            label: 'Yaş',
            value: ageLabel,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickInfoCard(
            icon: pet.gender.toLowerCase().contains('erkek')
                ? Icons.male
                : Icons.female,
            label: 'Cinsiyet',
            value: pet.gender,
            color: pet.gender.toLowerCase().contains('erkek')
                ? Colors.blue
                : Colors.pink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.vaccines,
            label: 'Aşı',
            value: pet.vaccinated ? 'Tam' : 'Eksik',
            color: pet.vaccinated ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.heroGradient.first.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description,
                  color: AppPalette.heroGradient.first,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hakkında',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pet.bio!,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Detaylı Bilgiler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailRow(
            icon: Icons.category,
            label: 'Tür',
            value: pet.species,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.badge,
            label: 'Cins',
            value: pet.breed.isNotEmpty ? pet.breed : 'Belirtilmemiş',
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.transgender,
            label: 'Cinsiyet',
            value: pet.gender,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.calendar_month,
            label: 'Yaş',
            value: '${pet.ageMonths} ay',
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.campaign,
            label: 'İlan Türü',
            value: pet.advertType == 'mating' ? 'Eşleştirme' : 'Sahiplendirme',
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sağlık Bilgileri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HealthCard(
                  icon: Icons.vaccines,
                  title: 'Aşı Durumu',
                  value: pet.vaccinated ? 'Aşıları Tam' : 'Aşı Gerekli',
                  isPositive: pet.vaccinated,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HealthCard(
                  icon: Icons.verified,
                  title: 'İlan Durumu',
                  value: pet.isActive ? 'Aktif' : 'Pasif',
                  isPositive: pet.isActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);
    final ownerName = pet.owner?.name ?? 'Sahip Bilgisi Yok';
    final avatarLetter = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: pet.owner?.id != null && pet.owner!.id.isNotEmpty
          ? () => context.pushNamed('user-profile', pathParameters: {'userId': pet.owner!.id})
          : null,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.heroGradient.first.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppPalette.accentGradient),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ownerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İlan Sahibi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppPalette.heroGradient.first.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: AppPalette.heroGradient.first,
              size: 16,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildOwnerBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade100,
            Colors.amber.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              color: Colors.amber.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu ilan size ait!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İlanınızı güncel tutarak daha fazla ilgi çekebilirsiniz.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Info Card Widget
class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// Health Card Widget
class _HealthCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isPositive;

  const _HealthCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Location Section - Static map preview with tap to open
class _LocationSection extends StatelessWidget {
  final Pet pet;

  const _LocationSection({required this.pet});

  Future<void> _openInMaps(BuildContext context) async {
    final lat = pet.latitude!;
    final lng = pet.longitude!;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harita uygulaması açılamadı')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lat = pet.latitude!;
    final lng = pet.longitude!;

    // Static map image URL (Google Static Maps API)
    final staticMapUrl = 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=14'
        '&size=600x300'
        '&maptype=roadmap'
        '&markers=color:red%7C$lat,$lng'
        '&key=AIzaSyBxxxxxxxxxx'; // API key gerekli

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Konum',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openInMaps(context),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Haritada Aç'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tıklanabilir harita önizlemesi
          GestureDetector(
            onTap: () => _openInMaps(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade50,
                      Colors.blue.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Harita arka planı
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                        ),
                        child: CustomPaint(
                          painter: _MapGridPainter(),
                        ),
                      ),
                    ),
                    // Merkez pin
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tıklama overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 18,
                              color: Colors.indigo.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Haritada görüntülemek için dokunun',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.indigo.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Harita grid çizgisi painter
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Yatay çizgiler
    for (var i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Dikey çizgiler
    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Action Buttons - Handles both Adoption and Mating
class _ActionButtons extends ConsumerStatefulWidget {
  final Pet pet;

  const _ActionButtons({required this.pet});

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isMating = widget.pet.advertType == 'mating';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sahiplendirme için: Mesaj + Sahiplen butonları, Eşleştirme için: Match Request
          if (!isMating) ...[
            // Mesaj butonu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                      onPressed: _handleSendMessage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.heroGradient.first,
                        side: BorderSide(color: AppPalette.heroGradient.first),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.message),
                      label: const Text(
                        'Mesaj',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Sahiplen butonu
            Expanded(
              child: _isLoading
                  ? const SizedBox()
                  : ElevatedButton.icon(
                      onPressed: _handleAdoptionApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.pets),
                      label: const Text(
                        'Sahiplen',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
            ),
          ] else
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _handleMatingRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.favorite),
                      label: const Text(
                        'Eşleştirme İsteği Gönder',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  // Sahiplendirme ilanı için direkt mesaj gönderme
  Future<void> _handleSendMessage() async {
    final currentUser = ref.read(authProvider);
    final owner = widget.pet.owner;

    if (currentUser == null) {
      _showError('Mesaj göndermek için giriş yapmalısınız.');
      return;
    }

    if (owner == null) {
      _showError('İlan sahibi bilgisi bulunamadı.');
      return;
    }

    if (owner.id == currentUser.id) {
      _showError('Kendi ilanınıza mesaj gönderemezsiniz.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Debug: Log the request parameters
      print('🔵 Creating conversation with:');
      print('   participantId: ${owner.id}');
      print('   currentUserId: ${currentUser.id}');
      print('   relatedPetId: ${widget.pet.id}');

      // messageRepositoryProvider kullanıyoruz - bu endpoint mevcut conversation'ı döndürür veya yeni oluşturur
      final repo = ref.read(messageRepositoryProvider);
      final conversation = await repo.createOrGetConversation(
        participantId: owner.id,
        currentUserId: currentUser.id,
        relatedPetId: widget.pet.id,
      );

      print('✅ Conversation created: ${conversation.id}');

      if (!mounted) return;

      // Conversation başarıyla alındı veya oluşturuldu, chat ekranına yönlendir
      context.pushNamed(
        'chat',
        pathParameters: {'conversationId': conversation.id},
        extra: {
          'name': owner.name,
          'avatar': _resolveAvatarUrl(owner.avatarUrl),
        },
      );
    } catch (e, stackTrace) {
      // Tüm hataları yakala ve detaylı log
      print('❌ Error in _handleSendMessage:');
      print('   Error: $e');
      print('   Stack: $stackTrace');

      if (!mounted) return;

      // Hata mesajını parse et
      String errorMessage = e.toString();

      // ApiError'dan mesajı çıkar
      if (errorMessage.contains('ApiError:')) {
        errorMessage = errorMessage.replaceAll('Exception: ApiError: ', '');
        errorMessage = errorMessage.replaceAll('ApiError: ', '');
      }

      // Özel hata mesajları
      if (errorMessage.contains('not found') || errorMessage.contains('bulunamadi')) {
        errorMessage = 'İlan veya kullanıcı bulunamadı';
      } else if (errorMessage.contains('network') || errorMessage.contains('SocketException')) {
        errorMessage = 'İnternet bağlantınızı kontrol edin';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Sahiplendirme basvuru ekranina yonlendir
  void _handleAdoptionApply() {
    context.pushNamed('adoption-apply', extra: widget.pet);
  }

  // Eşleştirme ilanı için pet seçimi ve istek gönderme
  Future<void> _handleMatingRequest() async {
    final currentUser = ref.read(authProvider);

    if (currentUser == null) {
      _showError('Eşleştirme isteği göndermek için giriş yapmalısınız.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kullanıcının kendi eşleştirme ilanlarını getir
      final petsRepo = ref.read(petsRepositoryProvider);
      final myPets = await petsRepo.getMyAdverts(advertType: 'mating');

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Aynı türden ilanları filtrele
      final sameSpeicesPets = myPets.where((p) =>
        p.species.toLowerCase() == widget.pet.species.toLowerCase() &&
        p.id != widget.pet.id
      ).toList();

      if (myPets.isEmpty) {
        // Hiç eşleştirme ilanı yok
        _showNoPetDialog();
        return;
      }

      if (sameSpeicesPets.isEmpty) {
        // Aynı türden ilan yok
        _showNoSameSpeciesPetDialog();
        return;
      }

      // Pet seçim modalını göster
      final selectedPet = await _showPetSelectionModal(sameSpeicesPets);

      if (selectedPet == null || !mounted) return;

      // İsteği gönder
      await _sendMatchRequest(selectedPet.id);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Bir hata oluştu: $e');
    }
  }

  Future<Pet?> _showPetSelectionModal(List<Pet> pets) async {
    return showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PetSelectionModal(
        pets: pets,
        targetSpecies: widget.pet.species,
      ),
    );
  }

  void _showNoPetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('İlan Gerekli'),
          ],
        ),
        content: const Text(
          'Eşleştirme isteği göndermek için önce bir eşleştirme ilanı oluşturmalısınız.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushNamed('create-pet', extra: {'advertType': 'mating'});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('İlan Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showNoSameSpeciesPetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Aynı Tür Gerekli'),
          ],
        ),
        content: Text(
          'Bu ilan "${widget.pet.species}" türünde. Eşleştirme isteği gönderebilmek için aynı türden bir ilanınız olmalı.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushNamed('create-pet', extra: {
                'advertType': 'mating',
                'species': widget.pet.species,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('İlan Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMatchRequest(String myPetId) async {
    setState(() => _isLoading = true);

    try {
      final matingRepo = ref.read(matingRepositoryProvider);
      final result = await matingRepo.sendMatchRequest(
        widget.pet.id,
        requesterPetId: myPetId,
      );

      if (!mounted) return;

      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showError(result.message);
      }
    } on MatchRequestException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Eşleştirme isteği gönderilemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(MatchRequestResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('İstek Gönderildi!')),
          ],
        ),
        content: Text(
          result.didMatch
              ? 'Tebrikler! Karşılıklı eşleşme oluştu. Artık mesajlaşabilirsiniz.'
              : 'Eşleştirme isteğiniz gönderildi. Karşı tarafın onayını bekliyorsunuz.',
        ),
        actions: [
          if (result.didMatch && result.request?.conversationId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pushNamed(
                  'chat',
                  pathParameters: {'conversationId': result.request!.conversationId!},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mesajlaşmaya Başla'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$apiBaseUrl$path';
  }
}

// Pet Selection Modal for Mating Requests
class _PetSelectionModal extends StatelessWidget {
  final List<Pet> pets;
  final String targetSpecies;

  const _PetSelectionModal({
    required this.pets,
    required this.targetSpecies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pets, color: Colors.pink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hayvanınızı Seçin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Eşleştirme için $targetSpecies türünden seçim yapın',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Pet list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              itemBuilder: (ctx, index) {
                final pet = pets[index];
                return _PetSelectionCard(
                  pet: pet,
                  onTap: () => Navigator.pop(context, pet),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PetSelectionCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetSelectionCard({
    required this.pet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pet image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: pet.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: '$apiBaseUrl${pet.photos[0]}',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.pets, color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.pets, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Pet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species} • ${pet.breed}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        pet.gender.toLowerCase().contains('erkek')
                            ? Icons.male
                            : Icons.female,
                        size: 14,
                        color: pet.gender.toLowerCase().contains('erkek')
                            ? Colors.blue
                            : Colors.pink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pet.gender,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.cake,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pet.ageMonths} ay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.pink,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _QrInfoRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor ?? Colors.black87,
            )),
      ],
    );
  }
}