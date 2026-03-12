import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/veterinary_repository.dart';

class VetDetailScreen extends ConsumerWidget {
  final String vetId;
  const VetDetailScreen({super.key, required this.vetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetAsync = ref.watch(vetDetailProvider(vetId));
    final theme = Theme.of(context);

    return Scaffold(
      body: vetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (vet) {
          final photoUrl = vet.photos.isNotEmpty
              ? (vet.photos.first.startsWith('http') ? vet.photos.first : '$apiBaseUrl${vet.photos.first}')
              : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(vet.name, style: const TextStyle(shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
                  background: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _heroPlaceholder())
                      : _heroPlaceholder(),
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
                              label: const Text('Dogrulanmis'),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          if (vet.source == 'google_places')
                            Chip(
                              avatar: const Icon(Icons.map, size: 16, color: Colors.orange),
                              label: const Text('Google Places'),
                              backgroundColor: Colors.orange.withOpacity(0.1),
                            ),
                          if (vet.acceptsOnlineAppointments)
                            Chip(
                              avatar: const Icon(Icons.calendar_today, size: 16, color: AppPalette.tertiary),
                              label: const Text('Online Randevu'),
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
                            Text('${vet.googleRating!.toStringAsFixed(1)} (${vet.googleReviewCount} degerlendirme)',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info
                      if (vet.address != null) _infoRow(Icons.location_on, vet.address!, theme),
                      if (vet.phone != null) _infoRow(Icons.phone, vet.phone!, theme, onTap: () => _launchUrl('tel:${vet.phone}')),
                      if (vet.email != null) _infoRow(Icons.email, vet.email!, theme, onTap: () => _launchUrl('mailto:${vet.email}')),
                      if (vet.website != null) _infoRow(Icons.language, vet.website!, theme, onTap: () => _launchUrl(vet.website!)),
                      const SizedBox(height: 16),

                      // Description
                      if (vet.description != null) ...[
                        Text('Hakkinda', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(vet.description!, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],

                      // Services
                      if (vet.services.isNotEmpty) ...[
                        Text('Hizmetler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                        Text('Hizmet Verilen Turler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vet.speciesServed.map((s) => Chip(
                            avatar: Icon(_speciesIcon(s), size: 18),
                            label: Text(_speciesLabel(s)),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Working hours
                      if (vet.workingHours.isNotEmpty) ...[
                        Text('Calisma Saatleri', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...vet.workingHours.map((wh) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 100, child: Text(wh.dayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                              Text(
                                wh.isClosed ? 'Kapali' : '${wh.open ?? '-'} - ${wh.close ?? '-'}',
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
                        label: const Text('Randevu Al'),
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

  String _speciesLabel(String species) {
    switch (species) {
      case 'dog': return 'Kopek';
      case 'cat': return 'Kedi';
      case 'bird': return 'Kus';
      case 'fish': return 'Balik';
      case 'rodent': return 'Kemirgen';
      default: return 'Diger';
    }
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
      onPressed: _loading ? null : _startConversation,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.message_outlined),
      label: const Text('Mesaj Gönder'),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profili Sahiplen'),
        content: const Text(
          'Bu klinik profilini hesabınıza bağlamak istediğinizden emin misiniz?\n\n'
          'Sahiplendikten sonra müşteriler size doğrudan mesaj gönderebilir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sahiplen')),
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
          const SnackBar(content: Text('Profil başarıyla sahiplenildi! Artık mesaj alabilirsiniz.'), backgroundColor: Colors.green),
        );
        ref.invalidate(vetDetailProvider(widget.vet.id));
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
      onPressed: _loading ? null : _claim,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.verified_outlined),
      label: const Text('Bu Kliniği Sahiplen'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.teal,
        side: const BorderSide(color: Colors.teal),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
