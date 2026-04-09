import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/gradient_button.dart';
import 'package:evcilhayvan_mobil2/core/widgets/section_header.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';
import 'availability_screen.dart';

class SitterDetailScreen extends ConsumerWidget {
  final String sitterId;
  const SitterDetailScreen({super.key, required this.sitterId});

  String _r(String url) => url.startsWith('http') ? url : '$apiBaseUrl$url';

  IconData _serviceIcon(String type) {
    switch (type) {
      case 'walking':
        return Icons.directions_walk;
      case 'home_sitting':
        return Icons.home;
      case 'boarding':
        return Icons.hotel;
      case 'daycare':
        return Icons.wb_sunny;
      case 'grooming':
        return Icons.content_cut;
      default:
        return Icons.pets;
    }
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SectionHeader(title: title),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sitterDetailProvider(sitterId));
    final user = ref.watch(authProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: PawLoading())),
      error: (e, _) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(appBar: AppBar(), body: Center(child: Text('${l10n.sitterErrorPrefix}$e')));
      },
      data: (data) {
        final l10n = AppLocalizations.of(context)!;
        final sitter = data['sitter'] as PetSitterModel;
        final reviews = data['reviews'] as List<SitterReview>;
        final photo = sitter.avatar?.isNotEmpty == true
            ? sitter.avatar!
            : (sitter.photos.isNotEmpty ? sitter.photos.first : '');

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppPalette.appBarDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _r(photo), fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1B4332),
                                    Color(0xFF2D6A4F)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                  child: Icon(Icons.person,
                                      size: 80, color: Color(0xFFD8F3DC))),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(sitter.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (sitter.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF52B788)),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified,
                                        size: 14,
                                        color: Color(0xFF2D6A4F)),
                                    const SizedBox(width: 4),
                                    Text(l10n.sitterVerifiedLabel,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2D6A4F))),
                                  ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating + Distance
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                              '${sitter.rating.toStringAsFixed(1)} (${sitter.reviewCount} yorum)',
                              style: Theme.of(context).textTheme.bodyMedium),
                          if (sitter.distanceKm != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.location_on,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            Text(
                                '${sitter.distanceKm!.toStringAsFixed(1)} km',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Availability badge with pulse animation
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sitter.availability
                              ? const Color(0xFFD8F3DC)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: sitter.availability
                                ? const Color(0xFF52B788)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sitter.availability
                                    ? const Color(0xFF2D6A4F)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sitter.availability
                                  ? l10n.sitterAvailableNow
                                  : l10n.sitterCurrentlyBusy,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sitter.availability
                                    ? const Color(0xFF2D6A4F)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(
                            onPlay: (controller) => sitter.availability
                                ? controller.repeat(reverse: true)
                                : null,
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.03, 1.03),
                            duration: 1200.ms,
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(height: 16),

                      // Bio
                      if (sitter.bio?.isNotEmpty == true) ...[
                        _sectionTitle(l10n.sitterAboutSection, Icons.info_outline),
                        Text(sitter.bio!,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                      ],

                      // Services + Prices
                      _sectionTitle(l10n.sitterServicesAndPrices, Icons.handyman),
                      ...sitter.services.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PremiumCard(
                            accentColor: const Color(0xFF52B788),
                            enableScale: false,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD8F3DC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_serviceIcon(s.type),
                                      color: const Color(0xFF2D6A4F),
                                      size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(s.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (s.pricePerHour > 0)
                                      Text(l10n.sitterHourlyRate(s.pricePerHour.toInt()),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF2D6A4F))),
                                    if (s.pricePerDay > 0)
                                      Text(l10n.sitterDailyRate(s.pricePerDay.toInt()),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          )
                              .animate(
                                  delay:
                                      Duration(milliseconds: 100 * i))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Species
                      _sectionTitle('Bakilan Turler', Icons.pets),
                      Text(sitter.speciesLabel,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),

                      // Portfolio Fotoğrafları
                      if (sitter.photos.isNotEmpty) ...[
                        _sectionTitle('Fotoğraflar (${sitter.photos.length})', Icons.photo_library),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: sitter.photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final url = _r(sitter.photos[i]);
                              return GestureDetector(
                                onTap: () => showDialog(
                                  context: ctx,
                                  builder: (_) => Dialog.fullscreen(
                                    child: Stack(
                                      children: [
                                        Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url))),
                                        Positioned(
                                          top: 40, right: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.of(ctx).pop(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(imageUrl: url, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Address
                      if (sitter.address?.isNotEmpty == true) ...[
                        _sectionTitle('Konum', Icons.location_on),
                        Row(children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF2D6A4F)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sitter.address!)),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Reviews
                      if (reviews.isNotEmpty) ...[
                        _sectionTitle(
                            'Yorumlar (${reviews.length})', Icons.reviews),
                        ...reviews.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PremiumCard(
                              enableScale: false,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            const Color(0xFFD8F3DC),
                                        child: Text(
                                            (r.ownerName ?? '?')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Color(0xFF2D6A4F),
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(r.ownerName ?? 'Kullanici',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      ...List.generate(
                                          5,
                                          (j) => Icon(
                                                j < r.rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 14,
                                              )),
                                    ],
                                  ),
                                  if (r.comment?.isNotEmpty == true) ...[
                                    const SizedBox(height: 8),
                                    Text(r.comment!),
                                  ],
                                ],
                              ),
                            )
                                .animate(
                                    delay:
                                        Duration(milliseconds: 80 * i))
                                .fadeIn(duration: 280.ms)
                                .slideY(begin: 0.05),
                          );
                        }),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
              ),
            ],
          ),
          bottomNavigationBar: user != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // Kendi profili ise — müsaitlik takvimi butonu
                        if (sitter.userId != null && sitter.userId == user.id) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AvailabilityScreen(sitterId: sitter.id)),
                              ),
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Müsaitlik'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2D6A4F),
                                side: const BorderSide(color: Color(0xFF2D6A4F)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                        if (sitter.userId != null && sitter.userId != user.id) ...[
                          Expanded(
                            child: _MessageSitterButton(
                                sitter: sitter, userId: user.id),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (sitter.availability && sitter.userId != user.id)
                          Expanded(
                            child: GradientButton(
                              label: l10n.sitterBook,
                              icon: Icons.calendar_month_rounded,
                              onPressed: () => context.pushNamed(
                                'sitter-booking',
                                pathParameters: {'sitterId': sitter.id},
                                extra: sitter,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _MessageSitterButton extends ConsumerStatefulWidget {
  final PetSitterModel sitter;
  final String userId;
  const _MessageSitterButton({required this.sitter, required this.userId});

  @override
  ConsumerState<_MessageSitterButton> createState() => _MessageSitterButtonState();
}

class _MessageSitterButtonState extends ConsumerState<_MessageSitterButton> {
  bool _loading = false;

  Future<void> _openChat() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(messageRepositoryProvider);
      final conv = await repo.createOrGetConversation(
        participantId: widget.sitter.userId!,
        currentUserId: widget.userId,
      );
      if (mounted) {
        context.pushNamed('chat',
            pathParameters: {'conversationId': conv.id},
            extra: {'name': widget.sitter.displayName, 'avatar': widget.sitter.avatar});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _openChat,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.message_outlined),
      label: const Text('Mesajla', style: TextStyle(fontSize: 16)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A4F),
        side: const BorderSide(color: Color(0xFF2D6A4F)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
