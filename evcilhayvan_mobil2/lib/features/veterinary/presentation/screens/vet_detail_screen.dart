import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/vet_review_model.dart';

final vetReviewsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, vetId) {
  return ref.read(veterinaryRepositoryProvider).getVetReviews(vetId);
});

class VetDetailScreen extends ConsumerStatefulWidget {
  final String vetId;
  const VetDetailScreen({super.key, required this.vetId});

  @override
  ConsumerState<VetDetailScreen> createState() => _VetDetailScreenState();
}

class _VetDetailScreenState extends ConsumerState<VetDetailScreen> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vetAsync = ref.watch(vetDetailProvider(widget.vetId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: vetAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (vet) {
          final photos = vet.photos.map((p) => p.startsWith('http') ? p : '$apiBaseUrl$p').toList();

          return CustomScrollView(
            slivers: [
              // ── Hero Photo Section ──
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    vet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                    ),
                  ),
                  background: photos.isEmpty
                      ? _heroPlaceholder()
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              itemCount: photos.length,
                              onPageChanged: (i) => setState(() => _photoIndex = i),
                              itemBuilder: (_, i) => Image.network(
                                photos[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _heroPlaceholder(),
                              ),
                            ),
                            // Gradient overlay for text readability
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Photo indicators
                            if (photos.length > 1)
                              Positioned(
                                bottom: 52,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(photos.length, (i) {
                                    final isActive = _photoIndex == i;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                      width: isActive ? 24 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.white : Colors.white54,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: isActive
                                            ? [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 4)]
                                            : null,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                  collapseMode: CollapseMode.parallax,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Badges ──
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (vet.isVerified)
                            _buildBadge(Icons.verified, l10n.vetVerified, const Color(0xFF2D6A4F)),
                          if (vet.source == 'google_places')
                            _buildBadge(Icons.map, 'Google Places', Colors.orange),
                          if (vet.acceptsOnlineAppointments)
                            _buildBadge(Icons.calendar_today, l10n.vetOnlineAppointment, const Color(0xFF52B788)),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                      const SizedBox(height: 16),

                      // ── Animated Rating ──
                      if (vet.googleRating != null)
                        _AnimatedRating(rating: vet.googleRating!, reviewCount: vet.googleReviewCount, l10n: l10n)
                            .animate(delay: 100.ms).fadeIn(duration: 400.ms),

                      // ── Contact Info ──
                      PremiumCard(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          children: [
                            if (vet.address != null) _infoRow(Icons.location_on, vet.address!, theme,
                              onTap: (vet.latitude != null && vet.longitude != null)
                                ? () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${vet.latitude},${vet.longitude}')
                                : () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(vet.address!)}'),
                            ),
                            if (vet.phone != null) _infoRow(Icons.phone, vet.phone!, theme, onTap: () => _launchUrl('tel:${vet.phone}')),
                            if (vet.email != null) _infoRow(Icons.email, vet.email!, theme, onTap: () => _launchUrl('mailto:${vet.email}')),
                            if (vet.website != null) _infoRow(Icons.language, vet.website!, theme, onTap: () => _launchUrl(vet.website!)),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05),
                      const SizedBox(height: 16),

                      // ── Description ──
                      if (vet.description != null) ...[
                        _sectionTitle(l10n.vetAbout, Icons.info_outline),
                        const SizedBox(height: 8),
                        Text(vet.description!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                        const SizedBox(height: 16),
                      ],

                      // ── Services ──
                      if (vet.services.isNotEmpty) ...[
                        _sectionTitle(l10n.vetServices, Icons.medical_services_outlined),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vet.services.map((s) => _serviceChip(s)).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Species ──
                      if (vet.speciesServed.isNotEmpty) ...[
                        _sectionTitle(l10n.vetSpeciesServed, Icons.pets),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vet.speciesServed.map((s) => Chip(
                            avatar: Icon(_speciesIcon(s), size: 18),
                            label: Text(_speciesLabel(s, l10n)),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Working Hours ──
                      if (vet.workingHours.isNotEmpty) ...[
                        _sectionTitle(l10n.vetWorkingHours, Icons.access_time),
                        const SizedBox(height: 10),
                        PremiumCard(
                          enableScale: false,
                          child: Column(
                            children: vet.workingHours.map((wh) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  SizedBox(width: 100, child: Text(wh.dayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                                  Expanded(
                                    child: Text(
                                      wh.isClosed ? l10n.vetClosed : '${wh.open ?? '-'} - ${wh.close ?? '-'}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: wh.isClosed ? Colors.red.shade400 : const Color(0xFF2D6A4F),
                                        fontWeight: wh.isClosed ? FontWeight.w500 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Reviews ──
              SliverToBoxAdapter(
                child: _VetReviewsSection(vetId: widget.vetId),
              ),
            ],
          );
        },
      ),
      // ── Bottom Action Buttons (Simplified: 2 prominent) ──
      bottomNavigationBar: vetAsync.whenOrNull(
        data: (vet) {
          final currentUser = ref.watch(authProvider);
          final isMyVet = vet.userId != null && currentUser != null && vet.userId == currentUser.id;

          return Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(top: BorderSide(color: const Color(0xFFD8F3DC), width: 1)),
              boxShadow: [BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PRIMARY: Randevu Al
                    if (vet.acceptsOnlineAppointments)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed('appointment-create', extra: {'vetId': vet.id, 'vetName': vet.name}),
                          icon: const Icon(Icons.calendar_today, size: 20),
                          label: Text(l10n.vetAppointment, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                    if (vet.acceptsOnlineAppointments) const SizedBox(height: 10),

                    // SECONDARY: Row of Mesaj + Harita
                    Row(
                      children: [
                        if (vet.address != null || vet.latitude != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final url = (vet.latitude != null && vet.longitude != null)
                                    ? 'https://www.google.com/maps/search/?api=1&query=${vet.latitude},${vet.longitude}'
                                    : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(vet.address!)}';
                                _launchUrl(url);
                              },
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: Text(l10n.vetOpenInMaps),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2D6A4F),
                                side: const BorderSide(color: Color(0xFF2D6A4F)),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        if ((vet.address != null || vet.latitude != null) && vet.userId != null && !isMyVet)
                          const SizedBox(width: 10),
                        if (vet.userId != null && !isMyVet)
                          Expanded(child: _MessageVetButton(vet: vet)),
                      ],
                    ),

                    // Claim (tertiary — subtle)
                    if (vet.userId == null && currentUser != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _ClaimVetButton(vet: vet),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD8F3DC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
        ),
        const SizedBox(width: 10),
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _serviceChip(String service) {
    final icon = _serviceIcon(service);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFD8F3DC), const Color(0xFFD8F3DC).withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 6),
          Text(service, style: const TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  IconData _serviceIcon(String service) {
    final s = service.toLowerCase();
    if (s.contains('aşı') || s.contains('vaccin')) return Icons.vaccines;
    if (s.contains('ameliyat') || s.contains('surg')) return Icons.medical_services;
    if (s.contains('diş') || s.contains('dent')) return Icons.mood;
    if (s.contains('acil') || s.contains('emerg')) return Icons.emergency;
    if (s.contains('muayene') || s.contains('exam')) return Icons.health_and_safety;
    return Icons.local_hospital;
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme, {VoidCallback? onTap}) {
    return InteractiveScale(
      onTap: onTap,
      enabled: onTap != null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3DC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(
                color: onTap != null ? const Color(0xFF2D6A4F) : null,
                fontWeight: onTap != null ? FontWeight.w500 : null,
              )),
            ),
            if (onTap != null) Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(child: Icon(Icons.local_hospital, size: 80, color: Colors.white24)),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _speciesIcon(String species) {
    switch (species) {
      case 'dog': return Icons.pets;
      case 'cat': return Icons.pets;
      case 'bird': return Icons.flutter_dash;
      default: return Icons.pets;
    }
  }

  String _speciesLabel(String species, AppLocalizations l10n) {
    switch (species) {
      case 'dog': return l10n.vetSpeciesDog;
      case 'cat': return l10n.vetSpeciesCat;
      case 'bird': return l10n.vetSpeciesBird;
      case 'fish': return l10n.vetSpeciesFish;
      case 'rodent': return l10n.vetSpeciesRodent;
      default: return l10n.vetSpeciesOther;
    }
  }
}

// ── Animated Rating Widget ──
class _AnimatedRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final AppLocalizations l10n;

  const _AnimatedRating({required this.rating, required this.reviewCount, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: rating),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutQuart,
        builder: (_, value, __) {
          return Row(
            children: [
              ...List.generate(5, (i) {
                final fill = (value - i).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Stack(
                    children: [
                      Icon(Icons.star_border, color: Colors.amber.shade200, size: 24),
                      ClipRect(
                        clipper: _StarClipper(fill),
                        child: Icon(Icons.star, color: Colors.amber.shade700, size: 24),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 10),
              Text(
                value.toStringAsFixed(1),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.amber.shade700),
              ),
              const SizedBox(width: 6),
              Text(
                '($reviewCount ${l10n.vetReviews})',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fraction;
  _StarClipper(this.fraction);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_StarClipper old) => old.fraction != fraction;
}

// ── Reviews Section ──
class _VetReviewsSection extends ConsumerStatefulWidget {
  final String vetId;
  const _VetReviewsSection({required this.vetId});

  @override
  ConsumerState<_VetReviewsSection> createState() => _VetReviewsSectionState();
}

class _VetReviewsSectionState extends ConsumerState<_VetReviewsSection> {
  Future<void> _showAddReview() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddReviewDialog(),
    );
    if (result == null) return;
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      await repo.addVetReview(widget.vetId, result['rating'] as int,
          comment: result['comment'] as String?);
      ref.invalidate(vetReviewsProvider(widget.vetId));
      ref.invalidate(vetDetailProvider(widget.vetId));
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vetReviewAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await ref.read(veterinaryRepositoryProvider).deleteVetReview(reviewId);
      ref.invalidate(vetReviewsProvider(widget.vetId));
      ref.invalidate(vetDetailProvider(widget.vetId));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.vetReviewDeleteError(e.toString())), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(vetReviewsProvider(widget.vetId));
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rate_review, size: 18, color: Color(0xFF2D6A4F)),
              ),
              const SizedBox(width: 10),
              Text(l10n.vetReviews, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (currentUser != null)
                TextButton.icon(
                  onPressed: _showAddReview,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.vetReviewsRate),
                ),
            ],
          ),
          const SizedBox(height: 8),
          reviewsAsync.when(
            loading: () => const Center(child: PawLoading()),
            error: (_, __) => Text(l10n.vetReviewsLoadError),
            data: (data) {
              final reviews = data['reviews'] as List<VetReview>;
              final avg = data['averageRating'] as double;
              final count = data['ratingCount'] as int;

              if (count == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(l10n.vetReviewsEmpty, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Average summary card
                  PremiumCard(
                    enableScale: false,
                    child: Row(
                      children: [
                        Text(avg.toStringAsFixed(1),
                            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber[700])),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) => Icon(
                                i < avg.round() ? Icons.star : Icons.star_border,
                                color: Colors.amber[700], size: 20,
                              )),
                            ),
                            const SizedBox(height: 2),
                            Text(l10n.vetReviewCount(count), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Review cards
                  ...reviews.asMap().entries.map((entry) {
                    final index = entry.key;
                    final r = entry.value;
                    final isOwn = currentUser != null && r.userId == currentUser.id;
                    final avatarUrl = r.userAvatarUrl != null
                        ? (r.userAvatarUrl!.startsWith('http') ? r.userAvatarUrl! : '$apiBaseUrl${r.userAvatarUrl}')
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PremiumCard(
                        enableScale: false,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFD8F3DC),
                                  foregroundColor: const Color(0xFF2D6A4F),
                                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl == null
                                      ? Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.userName, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                                      Row(
                                        children: List.generate(5, (i) => Icon(
                                          i < r.rating ? Icons.star : Icons.star_border,
                                          color: Colors.amber[700], size: 14,
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwn)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    color: Colors.red.shade300,
                                    onPressed: () => _deleteReview(r.id),
                                  ),
                              ],
                            ),
                            if (r.comment != null && r.comment!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(r.comment!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn(duration: 280.ms).slideY(begin: 0.04);
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Add Review Dialog ──
class _AddReviewDialog extends StatefulWidget {
  const _AddReviewDialog();

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.vetReviewDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber[700],
                    size: 36,
                  ).animate(delay: Duration(milliseconds: i * 60))
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 300.ms, curve: Curves.elasticOut),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.vetReviewCommentHint,
              alignLabelWithHint: true,
              filled: true,
              fillColor: const Color(0xFFF4FAF6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'rating': _rating,
            'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          }),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: Text(l10n.send),
        ),
      ],
    );
  }
}

// ── Message Vet Button ──
class _MessageVetButton extends ConsumerStatefulWidget {
  final dynamic vet;
  const _MessageVetButton({required this.vet});

  @override
  ConsumerState<_MessageVetButton> createState() => _MessageVetButtonState();
}

class _MessageVetButtonState extends ConsumerState<_MessageVetButton> {
  bool _loading = false;

  Future<void> _startConversation() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      final conversationId = await repo.startConversationWithVet(widget.vet.id);
      if (mounted) {
        context.pushNamed('chat', pathParameters: {'conversationId': conversationId});
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _loading ? null : _startConversation,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.message_outlined, size: 18),
      label: Text(l10n.vetSendMessage),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A4F),
        side: const BorderSide(color: Color(0xFF2D6A4F)),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Claim Vet Button ──
class _ClaimVetButton extends ConsumerStatefulWidget {
  final dynamic vet;
  const _ClaimVetButton({required this.vet});

  @override
  ConsumerState<_ClaimVetButton> createState() => _ClaimVetButtonState();
}

class _ClaimVetButtonState extends ConsumerState<_ClaimVetButton> {
  bool _loading = false;

  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.vetClaimDialogTitle),
        content: Text(l10n.vetClaimDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
            child: Text(l10n.vetClaimAction),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      await repo.claimVetProfile(widget.vet.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vetClaimSuccess), backgroundColor: const Color(0xFF2D6A4F)),
        );
        ref.invalidate(vetDetailProvider(widget.vet.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _loading ? null : _claim,
        icon: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.verified_outlined, size: 16),
        label: Text(l10n.vetClaimProfile, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF40916C)),
      ),
    );
  }
}
