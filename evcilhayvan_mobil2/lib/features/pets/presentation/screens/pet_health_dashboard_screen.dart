import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import '../../data/repositories/pets_repository.dart';

class PetHealthDashboardScreen extends ConsumerWidget {
  const PetHealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(petHealthSummaryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sağlık Durumu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
                    child: const Icon(Icons.health_and_safety_rounded, size: 44, color: Color(0xFF2D6A4F)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Henüz evcil hayvan yok', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Bir evcil hayvan ekleyerek sağlık\nözetini burada görebilirsin',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(petHealthSummaryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summary.length,
              itemBuilder: (ctx, i) {
                return _PetHealthCard(data: summary[i])
                    .animate(delay: Duration(milliseconds: i * 80))
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.06);
              },
            ),
          );
        },
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(petHealthSummaryProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetHealthCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PetHealthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final petId   = data['petId'] as String? ?? '';
    final petName = data['petName'] as String? ?? 'Pet';
    final photo   = data['photo'] as String?;
    final status  = data['healthStatus'] as String? ?? 'iyi';
    final alerts  = (data['alerts'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final statusIcon  = _statusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed('health-journal', pathParameters: {'petId': petId}),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photo != null
                    ? CachedNetworkImage(
                        imageUrl: resolveImageUrl(photo),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _defaultAvatar(petName),
                      )
                    : _defaultAvatar(petName),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (alerts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: alerts.take(3).map((alert) {
                          final type     = alert['type'] as String? ?? '';
                          final label    = alert['label'] as String? ?? '';
                          final daysLeft = (alert['daysLeft'] as num?)?.toInt() ?? 0;
                          final color    = daysLeft <= 7 ? const Color(0xFFE63946) : const Color(0xFFFFB300);
                          final icon     = type == 'vaccination' ? '💉' : '📅';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Text(
                              '$icon $label — $daysLeft gün',
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        'Her şey yolunda',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFFD8F3DC),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'acil':   return const Color(0xFFE63946);
      case 'dikkat': return const Color(0xFFFFB300);
      default:       return const Color(0xFF52B788);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'acil':   return 'Acil';
      case 'dikkat': return 'Dikkat';
      default:       return 'İyi';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'acil':   return Icons.warning_rounded;
      case 'dikkat': return Icons.info_outline_rounded;
      default:       return Icons.check_circle_outline_rounded;
    }
  }
}
