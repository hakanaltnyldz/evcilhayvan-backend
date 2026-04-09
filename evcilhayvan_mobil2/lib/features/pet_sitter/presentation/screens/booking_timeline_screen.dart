// lib/features/pet_sitter/presentation/screens/booking_timeline_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/config/app_config.dart';
import '../../domain/models/sitter_booking_model.dart';
import 'care_report_screen.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';

final _careReportsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, bookingId) async {
  final res = await ApiClient().dio.get('/api/sitter-bookings/$bookingId/care-reports');
  final list = res.data['reports'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

class BookingTimelineScreen extends ConsumerWidget {
  final SitterBookingModel booking;

  const BookingTimelineScreen({super.key, required this.booking});

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'great': return '😊';
      case 'good': return '🙂';
      case 'okay': return '😐';
      case 'tired': return '😴';
      default: return '🙂';
    }
  }

  String _activityLabel(String a) {
    switch (a) {
      case 'walk': return 'Yürüyüş';
      case 'play': return 'Oyun';
      case 'grooming': return 'Bakım';
      case 'bath': return 'Banyo';
      case 'training': return 'Eğitim';
      case 'vet_visit': return 'Veteriner';
      default: return a;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_careReportsProvider(booking.id));
    final isSitter = ref.watch(authProvider)?.id == booking.sitterUserId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bakım Günlüğü'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isSitter)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(_careReportsProvider(booking.id)),
            ),
        ],
      ),
      floatingActionButton: isSitter && booking.isAccepted
          ? FloatingActionButton.extended(
              onPressed: () async {
                final reports = reportsAsync.valueOrNull ?? [];
                final nextDay = reports.isEmpty ? 1 : (reports.last['day'] as int? ?? 0) + 1;
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => CareReportScreen(booking: booking, dayNumber: nextDay)),
                );
                if (result == true) ref.invalidate(_careReportsProvider(booking.id));
              },
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Bugünün Raporunu Ekle'),
            )
          : null,
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    isSitter ? 'Henüz rapor eklenmedi.\nİlk günlük raporunuzu ekleyin!' : 'Henüz rapor yok.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final r = reports[i];
              final day = r['day'] as int? ?? i + 1;
              final mood = r['mood']?.toString() ?? 'good';
              final notes = r['notes']?.toString();
              final foodEaten = r['foodEaten'] as bool? ?? true;
              final activities = (r['activities'] as List?)?.cast<String>() ?? [];
              final photos = (r['photos'] as List?)?.cast<String>() ?? [];
              final timestamp = r['timestamp'] != null
                  ? DateTime.tryParse(r['timestamp'].toString())
                  : null;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2E28) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppPalette.primary.withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppPalette.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text('$day', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$day. Gün', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (timestamp != null)
                                Text(
                                  DateFormat('d MMM, HH:mm', 'tr').format(timestamp.toLocal()),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(_moodEmoji(mood), style: const TextStyle(fontSize: 28)),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Yemek + mood
                          Row(
                            children: [
                              _InfoBadge(
                                icon: foodEaten ? Icons.check_circle : Icons.cancel,
                                label: foodEaten ? 'Yemek yedi' : 'Yemek yemedi',
                                color: foodEaten ? Colors.green : Colors.red,
                              ),
                            ],
                          ),

                          // Aktiviteler
                          if (activities.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: activities.map((a) => _InfoBadge(
                                icon: Icons.check,
                                label: _activityLabel(a),
                                color: AppPalette.primary,
                              )).toList(),
                            ),
                          ],

                          // Notlar
                          if (notes != null && notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(notes, style: const TextStyle(fontSize: 14, height: 1.4)),
                          ],

                          // Fotoğraflar
                          if (photos.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: photos.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, pi) {
                                  final url = '${AppConfig.current.apiBaseUrl}${photos[pi]}';
                                  return GestureDetector(
                                    onTap: () => _showFullPhoto(context, url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(url, width: 90, height: 90, fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url))),
            Positioned(
              top: 40, right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
