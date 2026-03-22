import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
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
      body: vetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (vet) {
          final photos = vet.photos.map((p) => p.startsWith('http') ? p : '$apiBaseUrl$p').toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(vet.name, style: const TextStyle(shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
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
                            if (photos.length > 1)
                              Positioned(
                                bottom: 44,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(photos.length, (i) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: _photoIndex == i ? 22 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: _photoIndex == i ? Colors.white : Colors.white54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    );
                                  }),
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
                      // Badges
                      Wrap(
                        spacing: 8,
                        children: [
                          if (vet.isVerified)
                            Chip(
                              avatar: const Icon(Icons.verified, size: 16, color: Colors.blue),
                              label: Text(l10n.vetVerified),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          if (vet.source == 'google_places')
                            const Chip(
                              avatar: Icon(Icons.map, size: 16, color: Colors.orange),
                              label: Text('Google Places'),
                              backgroundColor: Colors.orange,
                            ),
                          if (vet.acceptsOnlineAppointments)
                            Chip(
                              avatar: const Icon(Icons.calendar_today, size: 16, color: AppPalette.tertiary),
                              label: Text(l10n.vetOnlineAppointment),
                              backgroundColor: AppPalette.tertiary.withOpacity(0.1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rating
                      if (vet.googleRating != null) ...[
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < vet.googleRating!.round() ? Icons.star : Icons.star_border,
                              color: Colors.amber[700],
                              size: 22,
                            )),
                            const SizedBox(width: 8),
                            Text('${vet.googleRating!.toStringAsFixed(1)} (${vet.googleReviewCount} ${l10n.vetReviews})',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info
                      if (vet.address != null) _infoRow(Icons.location_on, vet.address!, theme,
                        onTap: (vet.latitude != null && vet.longitude != null)
                          ? () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${vet.latitude},${vet.longitude}')
                          : () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(vet.address!)}'),
                      ),
                      if (vet.phone != null) _infoRow(Icons.phone, vet.phone!, theme, onTap: () => _launchUrl('tel:${vet.phone}')),
                      if (vet.email != null) _infoRow(Icons.email, vet.email!, theme, onTap: () => _launchUrl('mailto:${vet.email}')),
                      if (vet.website != null) _infoRow(Icons.language, vet.website!, theme, onTap: () => _launchUrl(vet.website!)),
                      const SizedBox(height: 16),

                      // Description
                      if (vet.description != null) ...[
                        Text(l10n.vetAbout, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(vet.description!, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],

                      // Services
                      if (vet.services.isNotEmpty) ...[
                        Text(l10n.vetServices, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vet.services.map((s) => Chip(label: Text(s))).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Species
                      if (vet.speciesServed.isNotEmpty) ...[
                        Text(l10n.vetSpeciesServed, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
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

                      // Working hours
                      if (vet.workingHours.isNotEmpty) ...[
                        Text(l10n.vetWorkingHours, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...vet.workingHours.map((wh) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 100, child: Text(wh.dayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                              Text(
                                wh.isClosed ? l10n.vetClosed : '${wh.open ?? '-'} - ${wh.close ?? '-'}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: wh.isClosed ? Colors.red : null),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Değerlendirmeler ──
              SliverToBoxAdapter(
                child: _VetReviewsSection(vetId: widget.vetId),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: vetAsync.whenOrNull(
        data: (vet) {
          final currentUser = ref.watch(authProvider);
          final isMyVet = vet.userId != null && currentUser != null && vet.userId == currentUser.id;
          final canClaim = vet.userId == null && currentUser != null;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Haritada Aç butonu
                  if (vet.address != null || vet.latitude != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final url = (vet.latitude != null && vet.longitude != null)
                                ? 'https://www.google.com/maps/search/?api=1&query=${vet.latitude},${vet.longitude}'
                                : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(vet.address!)}';
                            _launchUrl(url);
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: Text(l10n.vetOpenInMaps),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),

                  // Mesaj Gönder butonu (vet sisteme kayıtlıysa)
                  if (vet.userId != null && !isMyVet)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: _MessageVetButton(vet: vet),
                      ),
                    ),

                  // Randevu Al butonu
                  if (vet.acceptsOnlineAppointments)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.pushNamed('appointment-create', extra: {'vetId': vet.id, 'vetName': vet.name}),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(l10n.vetAppointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                  // Profili Sahiplen butonu (vet kayıtsız ve giriş yapılmışsa)
                  if (canClaim)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: _ClaimVetButton(vet: vet),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppPalette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: onTap != null ? AppPalette.primary : null)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: AppPalette.background,
      child: const Center(child: Icon(Icons.local_hospital, size: 80, color: AppPalette.onSurfaceVariant)),
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

// ── Değerlendirmeler Bölümü ──────────────────────────────────────────────────
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
      builder: (_) => _AddReviewDialog(),
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
              Text(l10n.vetReviews,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (currentUser != null)
                TextButton.icon(
                  onPressed: _showAddReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: Text(l10n.vetReviewsRate),
                ),
            ],
          ),
          reviewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.vetReviewsLoadError),
            data: (data) {
              final reviews = data['reviews'] as List<VetReview>;
              final avg = data['averageRating'] as double;
              final count = data['ratingCount'] as int;

              if (count == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l10n.vetReviewsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ortalama puan özeti
                  Row(
                    children: [
                      Text(avg.toStringAsFixed(1),
                          style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold, color: Colors.amber[700])),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                                5,
                                (i) => Icon(
                                      i < avg.round() ? Icons.star : Icons.star_border,
                                      color: Colors.amber[700],
                                      size: 20,
                                    )),
                          ),
                          Text(l10n.vetReviewCount(count),
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Yorum kartları
                  ...reviews.map((r) {
                    final isOwn = currentUser != null && r.userId == currentUser.id;
                    final avatarUrl = r.userAvatarUrl != null
                        ? (r.userAvatarUrl!.startsWith('http')
                            ? r.userAvatarUrl!
                            : '$apiBaseUrl${r.userAvatarUrl}')
                        : null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?')
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.userName,
                                          style: theme.textTheme.labelLarge),
                                      Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(
                                                  i < r.rating ? Icons.star : Icons.star_border,
                                                  color: Colors.amber[700],
                                                  size: 14,
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
                              const SizedBox(height: 8),
                              Text(r.comment!, style: theme.textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                    );
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
      title: Text(l10n.vetReviewDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                  size: 36,
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
              border: const OutlineInputBorder(),
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
          child: Text(l10n.send),
        ),
      ],
    );
  }
}

// ── Mesaj Gönder butonu ──────────────────────────────────────────────────────
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
          : const Icon(Icons.message_outlined),
      label: Text(l10n.vetSendMessage),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primary,
        side: const BorderSide(color: AppPalette.primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Profili Sahiplen butonu ──────────────────────────────────────────────────
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
        title: Text(l10n.vetClaimDialogTitle),
        content: Text(l10n.vetClaimDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.vetClaimAction)),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      await repo.claimVetProfile(widget.vet.id);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vetClaimSuccess), backgroundColor: Colors.green),
        );
        ref.invalidate(vetDetailProvider(widget.vet.id));
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
      onPressed: _loading ? null : _claim,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.verified_outlined),
      label: Text(l10n.vetClaimProfile),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.teal,
        side: const BorderSide(color: Colors.teal),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
