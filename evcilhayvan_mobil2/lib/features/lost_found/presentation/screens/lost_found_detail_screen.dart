import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/lost_found_repository.dart';
import '../../domain/models/lost_found_model.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';

class LostFoundDetailScreen extends ConsumerWidget {
  final String reportId;
  const LostFoundDetailScreen({super.key, required this.reportId});

  String _resolvePhoto(String url) {
    if (url.startsWith('http')) return url;
    return '$apiBaseUrl$url';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(lostFoundDetailProvider(reportId));
    final currentUser = ref.watch(authProvider);

    return reportAsync.when(
      loading: () => const Scaffold(body: Center(child: PawLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Hata: $e')),
      ),
      data: (report) {
        final isOwner = currentUser != null && currentUser.id == report.userId;

        return Scaffold(
          backgroundColor: const Color(0xFFF4FAF6),
          body: CustomScrollView(
            slivers: [
              // Photo gallery
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF1B4332),
                flexibleSpace: FlexibleSpaceBar(
                  background: report.photos.isNotEmpty
                      ? PageView.builder(
                          itemCount: report.photos.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: _resolvePhoto(report.photos[index]),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
                              errorWidget: (_, __, ___) => Container(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFD8F3DC),
                          child: Center(
                            child: Icon(
                              report.isLost ? Icons.search : Icons.pets,
                              size: 80,
                              color: const Color(0xFF52B788),
                            ),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status + type badge
                      Row(
                        children: [
                          _StatusBadge(report: report),
                          if (report.hasReward) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.shade400),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Odul: ${report.reward.toInt()} TL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pet name
                      Text(
                        report.petName?.isNotEmpty == true
                            ? report.petName!
                            : '${report.speciesLabel} (${report.color})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Info card
                      _InfoCard(report: report),
                      const SizedBox(height: 16),

                      // Description
                      Text('Aciklama', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1B4332))),
                      const SizedBox(height: 8),
                      Text(report.description, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),

                      // Location
                      if (report.lastSeenAddress != null && report.lastSeenAddress!.isNotEmpty) ...[
                        Text(
                          report.isLost ? 'Son Gorulme Yeri' : 'Bulundugu Yer',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on, color: Color(0xFF2D6A4F)),
                            title: Text(report.lastSeenAddress!),
                            subtitle: report.distanceKm != null
                                ? Text('${report.distanceKm!.toStringAsFixed(1)} km uzakta')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reporter info
                      if (report.userName != null) ...[
                        Text('Ilan Sahibi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFD8F3DC),
                              foregroundColor: const Color(0xFF2D6A4F),
                              child: Text(
                                report.userName!.isNotEmpty ? report.userName![0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(report.userName!),
                            subtitle: report.contactNote != null ? Text(report.contactNote!) : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Contact buttons (not owner)
                      if (!isOwner && report.isActive) ...[
                        Row(
                          children: [
                            if (report.contactPhone != null && report.contactPhone!.isNotEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _callPhone(report.contactPhone!),
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Ara'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D6A4F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            if (report.contactPhone != null && report.contactPhone!.isNotEmpty)
                              const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: create conversation and navigate to chat
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Mesaj gonderme yakinda aktif olacak')),
                                  );
                                },
                                icon: const Icon(Icons.chat),
                                label: const Text('Mesaj Gonder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D6A4F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Owner actions
                      if (isOwner && report.isActive) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _markReunited(context, ref, report),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Kavusturuldu'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D6A4F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _cancelReport(context, ref, report),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Iptal Et'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _markReunited(BuildContext context, WidgetRef ref, LostFoundPet report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kavusturuldu'),
        content: const Text('Hayvaniniz bulundu mu? Bu ilan "Kavusturuldu" olarak isaretlenecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(lostFoundRepositoryProvider).updateStatus(report.id, 'reunited');
                ref.invalidate(lostFoundDetailProvider(report.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tebrikler! Ilan kavusturuldu olarak isaretlendi.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Evet, Kavusturuldu'),
          ),
        ],
      ),
    );
  }

  void _cancelReport(BuildContext context, WidgetRef ref, LostFoundPet report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ilani Iptal Et'),
        content: const Text('Bu ilani iptal etmek istediginize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgec')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(lostFoundRepositoryProvider).updateStatus(report.id, 'cancelled');
                ref.invalidate(lostFoundDetailProvider(report.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ilan iptal edildi.')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Iptal Et'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LostFoundPet report;
  const _StatusBadge({required this.report});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (report.isReunited) {
      bg = const Color(0xFFD8F3DC);
      fg = const Color(0xFF1B4332);
      label = 'Kavusturuldu';
      icon = Icons.check_circle;
    } else if (report.status == 'cancelled') {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
      label = 'Iptal';
      icon = Icons.cancel;
    } else if (report.isLost) {
      bg = Colors.red.shade100;
      fg = Colors.red.shade800;
      label = 'Kayip';
      icon = Icons.search;
    } else {
      bg = const Color(0xFFD8F3DC);
      fg = const Color(0xFF1B4332);
      label = 'Bulunan';
      icon = Icons.pets;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final LostFoundPet report;
  const _InfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd.MM.yyyy').format(report.lastSeenDate);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(context, Icons.pets, 'Tur', report.speciesLabel),
            if (report.breed != null) _infoRow(context, Icons.category, 'Cins', report.breed!),
            _infoRow(context, Icons.palette, 'Renk', report.color),
            _infoRow(context, Icons.wc, 'Cinsiyet', report.genderLabel),
            if (report.ageApprox != null) _infoRow(context, Icons.cake, 'Tahmini Yas', report.ageApprox!),
            _infoRow(
              context,
              Icons.calendar_today,
              report.isLost ? 'Son Gorulme' : 'Bulunma Tarihi',
              dateStr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
