import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import '../../data/repositories/pets_repository.dart';

final petTimelineProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, petId) async {
      return ref.read(petsRepositoryProvider).getPetTimeline(petId);
    });

class PetTimelineScreen extends ConsumerWidget {
  final String petId;
  final String petName;

  const PetTimelineScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(petTimelineProvider(petId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '$petName — Geçmiş',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: timelineAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD8F3DC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 44,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz kayıt yok',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veteriner randevuları, sağlık kayıtları\nve bakıcı rezervasyonları burada görünür',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(petTimelineProvider(petId)),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: events.length,
              itemBuilder: (ctx, i) {
                final event = events[i];
                final isLast = i == events.length - 1;
                return _TimelineItem(event: event, isLast: isLast)
                    .animate(delay: Duration(milliseconds: i * 60))
                    .fadeIn(duration: 280.ms)
                    .slideX(begin: 0.05);
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
                onPressed: () => ref.invalidate(petTimelineProvider(petId)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final type = event['type'] as String? ?? 'health';
    final title = event['title'] as String? ?? 'Aktivite';
    final notes = event['notes'] as String?;
    final dateStr = event['date'] as String?;
    DateTime? date;
    if (dateStr != null) date = DateTime.tryParse(dateStr)?.toLocal();

    final config = _typeConfig(type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, color: config.color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: config.color.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: config.color.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(
                              color: config.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (date != null)
                          Text(
                            DateFormat(
                              'd MMM yyyy',
                              Localizations.localeOf(context).toString(),
                            ).format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TypeConfig _typeConfig(String type) {
    switch (type) {
      case 'appointment':
        return _TypeConfig(
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF4895EF),
          label: 'Veteriner',
        );
      case 'booking':
        return _TypeConfig(
          icon: Icons.pets_rounded,
          color: const Color(0xFFF4A261),
          label: 'Bakıcı',
        );
      case 'health':
      default:
        return _TypeConfig(
          icon: Icons.favorite_rounded,
          color: const Color(0xFF52B788),
          label: 'Sağlık',
        );
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
