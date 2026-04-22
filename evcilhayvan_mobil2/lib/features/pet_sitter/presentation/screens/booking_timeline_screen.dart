import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/care_report_model.dart';
import '../../domain/models/sitter_booking_model.dart';
import 'care_report_detail_screen.dart';

final _careReportsProvider = FutureProvider.autoDispose
    .family<List<CareReportModel>, String>((ref, bookingId) async {
      return ref.read(petSitterRepositoryProvider).getCareReports(bookingId);
    });

class BookingTimelineScreen extends ConsumerWidget {
  const BookingTimelineScreen({super.key, required this.booking});

  final SitterBookingModel booking;

  static const Map<String, String> _moodEmoji = {
    'great': '😊',
    'good': '🙂',
    'okay': '😐',
    'tired': '😴',
  };

  static const Map<String, String> _activityLabels = {
    'walk': 'Yuruyus',
    'play': 'Oyun',
    'grooming': 'Bakim',
    'bath': 'Banyo',
    'training': 'Egitim',
    'vet_visit': 'Veteriner',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_careReportsProvider(booking.id));
    final isSitter = ref.watch(authProvider)?.id == booking.sitterUserId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bakim Gunlugu'),
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
                final nextDay = reports.isEmpty ? 1 : reports.last.day + 1;
                final result = await context.pushNamed<bool>(
                  'care-report',
                  extra: {'booking': booking, 'dayNumber': nextDay},
                );
                if (result == true) {
                  ref.invalidate(_careReportsProvider(booking.id));
                }
              },
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Bugunun Raporunu Ekle'),
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
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSitter
                        ? 'Henuz rapor eklenmedi.\nIlk gunluk raporunuzu ekleyin.'
                        : 'Henuz rapor yok.',
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
              final report = reports[i];

              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CareReportDetailScreen(
                      booking: booking,
                      report: report,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2E28) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.primary.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppPalette.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${report.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${report.day}. Gun',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'd MMM, HH:mm',
                                    'tr_TR',
                                  ).format(report.timestamp.toLocal()),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (report.sharedWithOwner)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD8F3DC),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Gonderildi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                              ),
                            Text(
                              _moodEmoji[report.mood] ?? '🙂',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _InfoBadge(
                                  icon: report.foodEaten
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  label: report.foodEaten
                                      ? 'Yemek yedi'
                                      : 'Yemek yemedi',
                                  color: report.foodEaten
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                ...report.activities.map(
                                  (activity) => _InfoBadge(
                                    icon: Icons.check,
                                    label:
                                        _activityLabels[activity] ?? activity,
                                    color: AppPalette.primary,
                                  ),
                                ),
                              ],
                            ),
                            if ((report.notes ?? '').isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                report.notes!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (report.photos.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 90,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: report.photos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, index) {
                                    final rawUrl = report.photos[index];
                                    final url = rawUrl.startsWith('http')
                                        ? rawUrl
                                        : '${AppConfig.current.apiBaseUrl}$rawUrl';
                                    return GestureDetector(
                                      onTap: () => _showFullPhoto(context, url),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Detayi ac',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url))),
            Positioned(
              top: 40,
              right: 16,
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
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
