import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/appointment_model.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aptAsync = ref.watch(appointmentDetailProvider(appointmentId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Randevu Detay'), backgroundColor: Colors.transparent, elevation: 0),
      body: aptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (apt) {
          final date = apt.date;
          final dateStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
          final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_statusColor(apt).withOpacity(0.15), _statusColor(apt).withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(_statusIcon(apt), size: 48, color: _statusColor(apt)),
                      const SizedBox(height: 8),
                      Text(apt.statusText, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _statusColor(apt))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Date & time
                _card(
                  context, theme,
                  icon: Icons.calendar_today,
                  title: 'Tarih ve Saat',
                  content: '$dateStr - $timeStr',
                ),
                const SizedBox(height: 12),

                // Vet
                if (apt.vet != null)
                  _card(
                    context, theme,
                    icon: Icons.local_hospital,
                    title: 'Veteriner',
                    content: apt.vet!.name,
                    subtitle: apt.vet!.address,
                    onTap: () => context.pushNamed('vet-detail', pathParameters: {'id': apt.veterinaryId}),
                  ),
                const SizedBox(height: 12),

                // Pet
                if (apt.pet != null)
                  _card(
                    context, theme,
                    icon: Icons.pets,
                    title: 'Evcil Hayvan',
                    content: apt.pet!.name,
                    subtitle: apt.pet!.species,
                  ),
                const SizedBox(height: 12),

                // Reason
                if (apt.reason != null)
                  _card(context, theme, icon: Icons.notes, title: 'Randevu Nedeni', content: apt.reason!),
                if (apt.notes != null) ...[
                  const SizedBox(height: 12),
                  _card(context, theme, icon: Icons.note_alt, title: 'Notlar', content: apt.notes!),
                ],
                if (apt.vetNotes != null) ...[
                  const SizedBox(height: 12),
                  _card(context, theme, icon: Icons.medical_information, title: 'Veteriner Notlari', content: apt.vetNotes!),
                ],
                const SizedBox(height: 24),

                // Actions
                if (apt.canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _cancelAppointment(context, ref, apt),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Randevuyu Iptal Et', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, ThemeData theme, {required IconData icon, required String title, required String content, String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppPalette.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(content, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null) Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.onSurfaceVariant)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppPalette.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AppointmentModel apt) {
    switch (apt.status) {
      case 'confirmed': return AppPalette.tertiary;
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blue;
      case 'no_show': return Colors.grey;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(AppointmentModel apt) {
    switch (apt.status) {
      case 'confirmed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'completed': return Icons.task_alt;
      case 'no_show': return Icons.person_off;
      default: return Icons.schedule;
    }
  }

  Future<void> _cancelAppointment(BuildContext context, WidgetRef ref, AppointmentModel apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevuyu Iptal Et'),
        content: const Text('Randevuyu iptal etmek istediginize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Iptal Et', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(appointmentRepositoryProvider);
      await repo.updateStatus(apt.id, 'cancelled');
      ref.invalidate(appointmentDetailProvider(apt.id));
      ref.invalidate(myAppointmentsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu iptal edildi')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
}
