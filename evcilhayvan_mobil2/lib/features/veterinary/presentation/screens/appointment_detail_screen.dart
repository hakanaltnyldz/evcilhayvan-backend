import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/status_timeline.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/appointment_model.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final aptAsync = ref.watch(appointmentDetailProvider(appointmentId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.apptDetailTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: aptAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (e, _) => Center(child: Text(l10n.apptDetailError(e.toString()))),
        data: (apt) {
          final date = apt.date;
          final dateStr =
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
          final timeStr =
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

          // Build info cards list for staggered animation indexing
          final List<Widget> infoCards = [];
          int cardIndex = 0;

          // Date & time card
          infoCards.add(
            _buildInfoCard(
              context,
              theme,
              icon: Icons.calendar_today,
              title: 'Tarih ve Saat',
              content: '$dateStr - $timeStr',
              index: cardIndex++,
            ),
          );

          // Vet card
          if (apt.vet != null) {
            infoCards.add(
              _buildInfoCard(
                context,
                theme,
                icon: Icons.local_hospital,
                title: 'Veteriner',
                content: apt.vet!.name,
                subtitle: apt.vet!.address,
                onTap: () => context.pushNamed('vet-detail',
                    pathParameters: {'id': apt.veterinaryId}),
                index: cardIndex++,
              ),
            );
          }

          // Pet card
          if (apt.pet != null) {
            infoCards.add(
              _buildInfoCard(
                context,
                theme,
                icon: Icons.pets,
                title: 'Evcil Hayvan',
                content: apt.pet!.name,
                subtitle: apt.pet!.species,
                index: cardIndex++,
              ),
            );
          }

          // Reason card
          if (apt.reason != null) {
            infoCards.add(
              _buildInfoCard(
                context,
                theme,
                icon: Icons.notes,
                title: 'Randevu Nedeni',
                content: apt.reason!,
                index: cardIndex++,
              ),
            );
          }

          // Notes card
          if (apt.notes != null) {
            infoCards.add(
              _buildInfoCard(
                context,
                theme,
                icon: Icons.note_alt,
                title: 'Notlar',
                content: apt.notes!,
                index: cardIndex++,
              ),
            );
          }

          // Online randevu — video linki kartı
          if (apt.type == 'online' && apt.meetingUrl != null) {
            infoCards.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final uri = Uri.parse(apt.meetingUrl!);
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.videocam_rounded, color: Colors.blue.shade700, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Online Randevu — Video Bağlantısı',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(apt.meetingUrl!,
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Icon(Icons.open_in_new, size: 18, color: Colors.blue.shade600),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Vet notes card
          if (apt.vetNotes != null) {
            infoCards.add(
              _buildInfoCard(
                context,
                theme,
                icon: Icons.medical_information,
                title: 'Veteriner Notlari',
                content: apt.vetNotes!,
                index: cardIndex++,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status timeline card
                PremiumCard(
                  accentColor: _statusColor(apt),
                  child: StatusTimeline(steps: [
                    StatusStep(
                      title: 'Oluşturuldu',
                      subtitle: dateStr,
                      isCompleted: true,
                    ),
                    StatusStep(
                      title: apt.status == 'confirmed'
                          ? 'Onaylandı'
                          : apt.status == 'cancelled'
                              ? 'İptal Edildi'
                              : 'Onay Bekleniyor',
                      subtitle: apt.status == 'confirmed'
                          ? 'Veteriner onayladı'
                          : null,
                      isCompleted: apt.status == 'confirmed' ||
                          apt.status == 'completed',
                      isActive: apt.status == 'pending',
                    ),
                    StatusStep(
                      title: 'Tamamlandı',
                      isCompleted: apt.status == 'completed',
                      isActive: apt.status == 'confirmed',
                    ),
                  ]),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.05),

                const SizedBox(height: 20),

                // Info cards with spacing
                ...infoCards
                    .expand((card) => [card, const SizedBox(height: 12)])
                    .toList()
                  ..removeLast(),

                const SizedBox(height: 24),

                // Cancel button
                if (apt.canCancel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelAppointment(context, ref, apt),
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red),
                      label: const Text('Randevuyu İptal Et'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )
                      .animate(
                          delay: Duration(milliseconds: 100 * cardIndex))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    VoidCallback? onTap,
    required int index,
  }) {
    return PremiumCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D6A4F), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(content,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05);
  }

  Color _statusColor(AppointmentModel apt) {
    switch (apt.status) {
      case 'confirmed':
        return const Color(0xFF52B788);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return const Color(0xFF2D6A4F);
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(AppointmentModel apt) {
    switch (apt.status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.task_alt;
      case 'no_show':
        return Icons.person_off;
      default:
        return Icons.schedule;
    }
  }

  Future<void> _cancelAppointment(
      BuildContext context, WidgetRef ref, AppointmentModel apt) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Randevuyu İptal Et',
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz. Randevuyu iptal etmek istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal Et'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(appointmentRepositoryProvider);
      await repo.updateStatus(apt.id, 'cancelled');
      ref.invalidate(appointmentDetailProvider(apt.id));
      ref.invalidate(myAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Randevu iptal edildi')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}
