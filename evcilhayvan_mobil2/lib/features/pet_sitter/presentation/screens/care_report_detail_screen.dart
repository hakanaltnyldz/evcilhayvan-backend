import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../domain/models/care_report_model.dart';
import '../../domain/models/sitter_booking_model.dart';

class CareReportDetailScreen extends StatelessWidget {
  const CareReportDetailScreen({
    super.key,
    required this.booking,
    required this.report,
  });

  final SitterBookingModel booking;
  final CareReportModel report;

  static const Map<String, String> _moodEmoji = {
    'great': '😊',
    'good': '🙂',
    'okay': '😐',
    'tired': '😴',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final sentAt = report.sharedWithOwnerAt;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.careReportDetailTitle(report.day)),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(
                      icon: Icons.pets_outlined,
                      label: booking.petName ?? l10n.bookingsPetFallback,
                    ),
                    _pill(
                      icon: Icons.room_service_outlined,
                      label: _serviceLabel(l10n, booking.serviceType),
                    ),
                    _pill(
                      icon: Icons.send_outlined,
                      label: sentAt != null
                          ? l10n.careReportDetailShared
                          : l10n.careReportDetailNotShared,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      _moodEmoji[report.mood] ?? '🙂',
                      style: const TextStyle(fontSize: 42),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.careReportDetailSummary(report.day),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                              locale,
                            ).format(report.timestamp.toLocal()),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sentAt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.careReportDetailSharedAt(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                        locale,
                      ).format(sentAt.toLocal()),
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            l10n.careReportDetailStatus,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  report.foodEaten
                      ? l10n.careReportDetailFoodEaten
                      : l10n.careReportDetailFoodNotEaten,
                  report.foodEaten ? Colors.green : Colors.red,
                  report.foodEaten
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                ),
                ...report.activities.map(
                  (activity) => _statusChip(
                    _activityLabel(l10n, activity),
                    const Color(0xFF2D6A4F),
                    Icons.check,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            l10n.careReportDetailSitterNote,
            Text(
              (report.notes ?? '').trim().isEmpty
                  ? l10n.careReportDetailNoNote
                  : report.notes!,
              style: TextStyle(
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            l10n.careReportDetailPhotos,
            report.photos.isEmpty
                ? Text(
                    l10n.careReportDetailNoPhotos,
                    style: const TextStyle(color: Colors.grey),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: report.photos.length,
                    itemBuilder: (context, index) {
                      final rawUrl = report.photos[index];
                      final url = rawUrl.startsWith('http')
                          ? rawUrl
                          : '${AppConfig.current.apiBaseUrl}$rawUrl';
                      return GestureDetector(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => Dialog.fullscreen(
                            child: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    child: Image.network(url),
                                  ),
                                ),
                                Positioned(
                                  top: 36,
                                  right: 16,
                                  child: IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _serviceLabel(AppLocalizations l10n, String serviceType) {
  switch (serviceType) {
    case 'walking':
      return l10n.sitterServiceWalkingLabel;
    case 'home_sitting':
      return l10n.sitterServiceHomeSittingLabel;
    case 'boarding':
      return l10n.sitterServiceBoardingLabel;
    case 'daycare':
      return l10n.sitterServiceDaycareLabel;
    case 'grooming':
      return l10n.sitterServiceGroomingLabel;
    default:
      return serviceType;
  }
}

String _activityLabel(AppLocalizations l10n, String activity) {
  switch (activity) {
    case 'walk':
      return l10n.careReportActivityWalk;
    case 'play':
      return l10n.careReportActivityPlay;
    case 'grooming':
      return l10n.careReportActivityGrooming;
    case 'vet_visit':
      return l10n.careReportActivityVetVisit;
    case 'bath':
      return l10n.careReportActivityBath;
    case 'training':
      return l10n.careReportActivityTraining;
    default:
      return activity;
  }
}
