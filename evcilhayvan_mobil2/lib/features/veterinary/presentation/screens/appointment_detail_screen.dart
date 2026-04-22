import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/appointment_model.dart';
import '../../domain/models/appointment_prescription_model.dart';

final _appointmentPrescriptionsProvider = FutureProvider.autoDispose
    .family<List<AppointmentPrescriptionModel>, String>((ref, appointmentId) {
      return ref
          .watch(appointmentRepositoryProvider)
          .getAppointmentPrescriptions(appointmentId);
    });

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _HeaderCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _HeaderCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'tr_TR',
    ).format(appointment.date.toLocal());
    final badgeColor = _statusColor(appointment.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              _Badge(
                label: appointment.type == 'online' ? 'Online' : 'Klinik',
                color: Colors.white.withOpacity(0.16),
                textColor: Colors.white,
              ),
              _Badge(
                label: _statusText(appointment.status),
                color: badgeColor.withOpacity(0.22),
                textColor: Colors.white,
              ),
              if (appointment.feeAmount > 0)
                _Badge(
                  label: NumberFormat.currency(
                    locale: 'tr_TR',
                    symbol: 'TL',
                    decimalDigits: appointment.feeAmount % 1 == 0 ? 0 : 2,
                  ).format(appointment.feeAmount),
                  color: Colors.white.withOpacity(0.16),
                  textColor: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            appointment.pet?.name ?? appointment.vet?.name ?? 'Randevu',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(date, style: const TextStyle(color: Colors.white70)),
          if (appointment.completedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tamamlanma: ${DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(appointment.completedAt!.toLocal())}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _VetActionPanel extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onEditClinicalRecord;
  final VoidCallback onCreatePrescription;
  final ValueChanged<String> onStatusTap;

  const _VetActionPanel({
    required this.appointment,
    required this.onEditClinicalRecord,
    required this.onCreatePrescription,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _ActionButton(
        icon: Icons.note_alt_outlined,
        label: 'Klinik Kaydi',
        onTap: onEditClinicalRecord,
      ),
      _ActionButton(
        icon: Icons.medication_outlined,
        label: 'Recete Ekle',
        onTap: onCreatePrescription,
      ),
    ];

    if (appointment.status == 'pending') {
      actions.addAll([
        _ActionButton(
          icon: Icons.check_circle_outline,
          label: 'Onayla',
          onTap: () => onStatusTap('confirmed'),
        ),
        _ActionButton(
          icon: Icons.cancel_outlined,
          label: 'Reddet',
          isDanger: true,
          onTap: () => onStatusTap('cancelled'),
        ),
      ]);
    } else if (appointment.status == 'confirmed') {
      actions.addAll([
        _ActionButton(
          icon: Icons.task_alt_outlined,
          label: 'Tamamla',
          onTap: () => onStatusTap('completed'),
        ),
        _ActionButton(
          icon: Icons.person_off_outlined,
          label: 'Gelmedi',
          isDanger: true,
          onTap: () => onStatusTap('no_show'),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Veteriner Islemleri',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: actions),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red : const Color(0xFF2D6A4F);

    return SizedBox(
      width: 154,
      child: PremiumCard(
        onTap: onTap,
        accentColor: color,
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? secondary;
  final VoidCallback? onTap;

  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.secondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.subtleBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((secondary ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      secondary!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(Icons.chevron_right),
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: content,
    );
  }
}

class _ClinicalBlock extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isLast;

  const _ClinicalBlock({
    required this.title,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.subtleBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D6A4F), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final AppointmentPrescriptionModel prescription;
  final String? dateLabel;

  const _PrescriptionCard({
    required this.prescription,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: const Color(0xFF2D6A4F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recete',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              _Badge(
                label: _prescriptionStatusText(prescription.status),
                color: const Color(0xFF2D6A4F).withOpacity(0.12),
                textColor: const Color(0xFF2D6A4F),
              ),
            ],
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              dateLabel!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Tani',
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            prescription.diagnosis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if ((prescription.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Notlar',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(prescription.notes!),
          ],
          if (prescription.followUpDate != null) ...[
            const SizedBox(height: 14),
            Text(
              'Kontrol Tarihi',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'dd MMMM yyyy',
                'tr_TR',
              ).format(prescription.followUpDate!.toLocal()),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Ilac Listesi',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...prescription.medications.map((medication) {
            final details = [
              if ((medication.dosage ?? '').isNotEmpty) medication.dosage!,
              if ((medication.frequency ?? '').isNotEmpty)
                medication.frequency!,
              if (medication.durationDays != null)
                '${medication.durationDays} gun',
            ].join(' • ');

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.subtleBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                  if ((medication.instructions ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      medication.instructions!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  const _SheetField({
    required this.controller,
    required this.label,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: context.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _CenteredErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CenteredErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MedicationDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController durationDaysController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

  Map<String, dynamic>? toPayload() {
    final name = nameController.text.trim();
    if (name.isEmpty) return null;

    return {
      'name': name,
      if (dosageController.text.trim().isNotEmpty)
        'dosage': dosageController.text.trim(),
      if (frequencyController.text.trim().isNotEmpty)
        'frequency': frequencyController.text.trim(),
      if (int.tryParse(durationDaysController.text.trim()) != null)
        'durationDays': int.parse(durationDaysController.text.trim()),
      if (instructionsController.text.trim().isNotEmpty)
        'instructions': instructionsController.text.trim(),
    };
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationDaysController.dispose();
    instructionsController.dispose();
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return const Color(0xFF52B788);
    case 'completed':
      return const Color(0xFF95D5B2);
    case 'cancelled':
      return Colors.red;
    case 'no_show':
      return Colors.grey;
    default:
      return Colors.orange;
  }
}

String _statusText(String status) {
  switch (status) {
    case 'pending':
      return 'Beklemede';
    case 'confirmed':
      return 'Onaylandi';
    case 'cancelled':
      return 'Iptal';
    case 'completed':
      return 'Tamamlandi';
    case 'no_show':
      return 'Gelmedi';
    default:
      return status;
  }
}

String _prescriptionStatusText(String status) {
  switch (status) {
    case 'active':
      return 'Aktif';
    case 'completed':
      return 'Tamamlandi';
    case 'cancelled':
      return 'Iptal';
    default:
      return status;
  }
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final isVetOrAdmin =
        currentUser?.role == 'vet' || currentUser?.role == 'admin';
    final appointmentAsync = ref.watch(
      appointmentDetailProvider(widget.appointmentId),
    );
    final prescriptionsAsync = ref.watch(
      _appointmentPrescriptionsProvider(widget.appointmentId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Randevu Detayi'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _refreshAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: appointmentAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (error, _) => _CenteredErrorState(
          message: 'Randevu detayi yuklenemedi:\n$error',
          onRetry: _refreshAll,
        ),
        data: (appointment) {
          return RefreshIndicator(
            onRefresh: () async => _refreshAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(appointment: appointment),
                const SizedBox(height: 16),
                if (isVetOrAdmin) ...[
                  _VetActionPanel(
                    appointment: appointment,
                    onEditClinicalRecord: () =>
                        _showClinicalRecordSheet(appointment),
                    onCreatePrescription: () =>
                        _showPrescriptionSheet(appointment),
                    onStatusTap: (status) =>
                        _handleStatusChange(appointment, status),
                  ),
                  const SizedBox(height: 16),
                ],
                if (appointment.owner != null && isVetOrAdmin) ...[
                  _buildSectionTitle('Musteri Bilgisi'),
                  const SizedBox(height: 10),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailLine(
                          icon: Icons.person_outline,
                          label: 'Musteri',
                          value: appointment.owner!.name,
                        ),
                        if ((appointment.owner!.phone ?? '').isNotEmpty)
                          _DetailLine(
                            icon: Icons.call_outlined,
                            label: 'Telefon',
                            value: appointment.owner!.phone!,
                          ),
                        if ((appointment.owner!.email ?? '').isNotEmpty)
                          _DetailLine(
                            icon: Icons.mail_outline,
                            label: 'E-posta',
                            value: appointment.owner!.email!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildSectionTitle('Randevu Bilgileri'),
                const SizedBox(height: 10),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailLine(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tarih',
                        value: _formatDateTime(appointment.date),
                      ),
                      _DetailLine(
                        icon: appointment.type == 'online'
                            ? Icons.videocam_outlined
                            : Icons.local_hospital_outlined,
                        label: 'Gorusme Tipi',
                        value: appointment.type == 'online'
                            ? 'Online gorusme'
                            : 'Klinik muayene',
                      ),
                      if (appointment.vet != null)
                        _DetailLine(
                          icon: Icons.local_hospital,
                          label: 'Veteriner',
                          value: appointment.vet!.name,
                          secondary: appointment.vet!.address,
                          onTap: () => context.pushNamed(
                            'vet-detail',
                            pathParameters: {'id': appointment.veterinaryId},
                          ),
                        ),
                      if (appointment.pet != null)
                        _DetailLine(
                          icon: Icons.pets_outlined,
                          label: 'Evcil Hayvan',
                          value: appointment.pet!.name,
                          secondary: appointment.pet!.species,
                        ),
                      if ((appointment.reason ?? '').isNotEmpty)
                        _DetailLine(
                          icon: Icons.assignment_outlined,
                          label: 'Randevu Nedeni',
                          value: appointment.reason!,
                        ),
                      if ((appointment.notes ?? '').isNotEmpty)
                        _DetailLine(
                          icon: Icons.sticky_note_2_outlined,
                          label: 'Sahip Notu',
                          value: appointment.notes!,
                        ),
                      if (appointment.type == 'online' &&
                          (appointment.meetingUrl ?? '').isNotEmpty)
                        _DetailLine(
                          icon: Icons.open_in_new_outlined,
                          label: 'Toplanti Baglantisi',
                          value: appointment.meetingUrl!,
                          onTap: () => _launchExternal(
                            appointment.meetingUrl!,
                            fallbackMessage: 'Toplanti baglantisi acilamadi.',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasClinicalSummary(appointment)) ...[
                  _buildSectionTitle('Klinik Kaydi'),
                  const SizedBox(height: 10),
                  PremiumCard(
                    accentColor: const Color(0xFF2D6A4F),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((appointment.diagnosis ?? '').isNotEmpty)
                          _ClinicalBlock(
                            title: 'Tani',
                            value: appointment.diagnosis!,
                            icon: Icons.biotech_outlined,
                          ),
                        if ((appointment.vetNotes ?? '').isNotEmpty)
                          _ClinicalBlock(
                            title: 'Veteriner Notlari',
                            value: appointment.vetNotes!,
                            icon: Icons.note_alt_outlined,
                          ),
                        if ((appointment.treatmentSummary ?? '').isNotEmpty)
                          _ClinicalBlock(
                            title: 'Tedavi Ozeti',
                            value: appointment.treatmentSummary!,
                            icon: Icons.healing_outlined,
                          ),
                        if (appointment.followUpDate != null)
                          _ClinicalBlock(
                            title: 'Takip Tarihi',
                            value: _formatDate(appointment.followUpDate!),
                            icon: Icons.event_repeat_outlined,
                          ),
                        if (appointment.feeAmount > 0)
                          _ClinicalBlock(
                            title: 'Muayene Ucreti',
                            value: _formatCurrency(appointment.feeAmount),
                            icon: Icons.payments_outlined,
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildSectionTitle('Receteler'),
                const SizedBox(height: 10),
                prescriptionsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: PawLoading(size: 36)),
                  ),
                  error: (error, _) => PremiumCard(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Receteler yuklenemedi: $error',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  data: (prescriptions) {
                    if (prescriptions.isEmpty) {
                      return PremiumCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              size: 40,
                              color: Color(0xFF2D6A4F),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Bu randevu icin henuz recete olusturulmadi.',
                              textAlign: TextAlign.center,
                            ),
                            if (isVetOrAdmin) ...[
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showPrescriptionSheet(appointment),
                                icon: const Icon(Icons.add),
                                label: const Text('Ilk Receteyi Hazirla'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: prescriptions
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PrescriptionCard(
                                prescription: item,
                                dateLabel: item.issuedAt != null
                                    ? _formatDateTime(item.issuedAt!)
                                    : null,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (appointment.canCancel && !isVetOrAdmin)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _handleStatusChange(appointment, 'cancelled'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Randevuyu Iptal Et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleStatusChange(
    AppointmentModel appointment,
    String nextStatus,
  ) async {
    final confirmed = await _confirmStatusChange(nextStatus);
    if (confirmed != true) return;

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateStatus(appointment.id, nextStatus);
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_statusLabel(nextStatus)} olarak guncellendi'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Islem basarisiz: $error')));
    }
  }

  Future<bool?> _confirmStatusChange(String nextStatus) {
    final isDanger = nextStatus == 'cancelled' || nextStatus == 'no_show';
    final title = _confirmTitle(nextStatus);
    final description = _confirmDescription(nextStatus);

    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDanger
                        ? Colors.red.withOpacity(0.08)
                        : const Color(0xFF2D6A4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _statusIcon(nextStatus),
                    color: isDanger ? Colors.red : const Color(0xFF2D6A4F),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(sheetContext).hintColor),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Vazgec'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDanger
                              ? Colors.red
                              : const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Devam Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showClinicalRecordSheet(AppointmentModel appointment) async {
    final notesController = TextEditingController(text: appointment.vetNotes);
    final diagnosisController = TextEditingController(
      text: appointment.diagnosis,
    );
    final treatmentController = TextEditingController(
      text: appointment.treatmentSummary,
    );
    final feeController = TextEditingController(
      text: appointment.feeAmount > 0 ? appointment.feeAmount.toString() : '',
    );
    DateTime? followUpDate = appointment.followUpDate;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Klinik Kaydi Duzenle',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veteriner notlari, tani ve takip planini bu randevuya bagli olarak kaydet.',
                        style: TextStyle(
                          color: Theme.of(sheetContext).hintColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SheetField(
                        controller: diagnosisController,
                        label: 'Tani',
                        hintText: 'Orn. Gastrit supheci',
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: notesController,
                        label: 'Veteriner Notlari',
                        hintText: 'Muayene sirasinda dikkat cekenler',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: treatmentController,
                        label: 'Tedavi Ozeti',
                        hintText: 'Uygulanan tedavi, oneriler, kontrol plani',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: feeController,
                        label: 'Muayene Ucreti (TL)',
                        hintText: '350',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      PremiumCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_repeat_outlined,
                              color: Color(0xFF2D6A4F),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Takip Tarihi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    followUpDate == null
                                        ? 'Henuz secilmedi'
                                        : _formatDate(followUpDate!),
                                    style: TextStyle(
                                      color: Theme.of(sheetContext).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: sheetContext,
                                  initialDate: followUpDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  locale: const Locale('tr', 'TR'),
                                );
                                if (picked == null) return;
                                setModalState(() => followUpDate = picked);
                              },
                              child: const Text('Sec'),
                            ),
                            if (followUpDate != null)
                              IconButton(
                                onPressed: () =>
                                    setModalState(() => followUpDate = null),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final parsedFee =
                                      feeController.text.trim().isEmpty
                                      ? null
                                      : double.tryParse(
                                          feeController.text.trim().replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        );
                                  if (feeController.text.trim().isNotEmpty &&
                                      parsedFee == null) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ucret alani sayisal olmalidir.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);
                                  try {
                                    await ref
                                        .read(appointmentRepositoryProvider)
                                        .updateClinicalRecord(
                                          appointment.id,
                                          vetNotes: notesController.text.trim(),
                                          diagnosis: diagnosisController.text
                                              .trim(),
                                          treatmentSummary: treatmentController
                                              .text
                                              .trim(),
                                          followUpDate: followUpDate,
                                          clearFollowUpDate:
                                              followUpDate == null,
                                          feeAmount: parsedFee,
                                        );
                                    _refreshAll();
                                    if (!mounted) return;
                                    Navigator.of(sheetContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Klinik kaydi guncellendi.',
                                        ),
                                      ),
                                    );
                                  } catch (error) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Kayit guncellenemedi: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isSubmitting ? 'Kaydediliyor...' : 'Kaydet',
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    notesController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    feeController.dispose();
  }

  Future<void> _showPrescriptionSheet(AppointmentModel appointment) async {
    final diagnosisController = TextEditingController(
      text: appointment.diagnosis,
    );
    final noteController = TextEditingController();
    final drafts = <_MedicationDraft>[_MedicationDraft()];
    DateTime? followUpDate = appointment.followUpDate;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Recete Olustur',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ilaclari ve kullanim planini randevu kaydina ekle.',
                        style: TextStyle(
                          color: Theme.of(sheetContext).hintColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SheetField(
                        controller: diagnosisController,
                        label: 'Tani',
                        hintText: 'Kesinlestirilmis tani',
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: noteController,
                        label: 'Ek Notlar',
                        hintText: 'Kullanim uyarisi veya kontrol notu',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Ilaclar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setModalState(
                              () => drafts.add(_MedicationDraft()),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Ilac Ekle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(drafts.length, (index) {
                        final draft = drafts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PremiumCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ilac ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (drafts.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setModalState(() {
                                            final removed = drafts.removeAt(
                                              index,
                                            );
                                            removed.dispose();
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                _SheetField(
                                  controller: draft.nameController,
                                  label: 'Ilac Adi',
                                  hintText: 'Orn. Amoksisilin',
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SheetField(
                                        controller: draft.dosageController,
                                        label: 'Doz',
                                        hintText: '250 mg',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SheetField(
                                        controller: draft.frequencyController,
                                        label: 'Siklik',
                                        hintText: 'Gunde 2 kez',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SheetField(
                                        controller:
                                            draft.durationDaysController,
                                        label: 'Gun',
                                        hintText: '7',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SheetField(
                                        controller:
                                            draft.instructionsController,
                                        label: 'Kullanim',
                                        hintText: 'Tok karinla',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      PremiumCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_repeat_outlined,
                              color: Color(0xFF2D6A4F),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kontrol Tarihi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    followUpDate == null
                                        ? 'Istege bagli'
                                        : _formatDate(followUpDate!),
                                    style: TextStyle(
                                      color: Theme.of(sheetContext).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: sheetContext,
                                  initialDate: followUpDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  locale: const Locale('tr', 'TR'),
                                );
                                if (picked == null) return;
                                setModalState(() => followUpDate = picked);
                              },
                              child: const Text('Sec'),
                            ),
                            if (followUpDate != null)
                              IconButton(
                                onPressed: () =>
                                    setModalState(() => followUpDate = null),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final diagnosis = diagnosisController.text
                                      .trim();
                                  if (diagnosis.isEmpty) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tani alani zorunlu.'),
                                      ),
                                    );
                                    return;
                                  }

                                  final medications = drafts
                                      .map((draft) => draft.toPayload())
                                      .whereType<Map<String, dynamic>>()
                                      .toList();
                                  if (medications.isEmpty) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'En az bir ilac girmelisin.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);
                                  try {
                                    await ref
                                        .read(appointmentRepositoryProvider)
                                        .createAppointmentPrescription(
                                          appointment.id,
                                          diagnosis: diagnosis,
                                          medications: medications,
                                          notes:
                                              noteController.text.trim().isEmpty
                                              ? null
                                              : noteController.text.trim(),
                                          followUpDate: followUpDate,
                                        );
                                    _refreshAll();
                                    if (!mounted) return;
                                    Navigator.of(sheetContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Recete olusturuldu.'),
                                      ),
                                    );
                                  } catch (error) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Recete olusturulamadi: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.medication_outlined),
                          label: Text(
                            isSubmitting
                                ? 'Kaydediliyor...'
                                : 'Receteyi Kaydet',
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    diagnosisController.dispose();
    noteController.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
  }

  void _refreshAll() {
    ref.invalidate(appointmentDetailProvider(widget.appointmentId));
    ref.invalidate(_appointmentPrescriptionsProvider(widget.appointmentId));
    ref.invalidate(myAppointmentsProvider);
  }

  Future<void> _launchExternal(
    String url, {
    required String fallbackMessage,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fallbackMessage)));
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(fallbackMessage)));
  }

  bool _hasClinicalSummary(AppointmentModel appointment) {
    return (appointment.vetNotes ?? '').isNotEmpty ||
        (appointment.diagnosis ?? '').isNotEmpty ||
        (appointment.treatmentSummary ?? '').isNotEmpty ||
        appointment.followUpDate != null ||
        appointment.feeAmount > 0;
  }

  Widget _buildSectionTitle(String label) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(value.toLocal());
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd MMMM yyyy', 'tr_TR').format(value.toLocal());
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: 'TL',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    );
    return formatter.format(value);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'confirmed':
        return 'Onaylandi';
      case 'cancelled':
        return 'Iptal edildi';
      case 'completed':
        return 'Tamamlandi';
      case 'no_show':
        return 'Gelmedi';
      default:
        return status;
    }
  }

  String _confirmTitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Randevuyu onayla';
      case 'completed':
        return 'Randevuyu tamamla';
      case 'no_show':
        return 'Gelmedi olarak isle';
      case 'cancelled':
        return 'Randevuyu iptal et';
      default:
        return 'Durumu guncelle';
    }
  }

  String _confirmDescription(String status) {
    switch (status) {
      case 'confirmed':
        return 'Bu randevu onaylanacak ve kullaniciya bildirim gidecek.';
      case 'completed':
        return 'Bu randevu tamamlandi olarak isaretlenecek.';
      case 'no_show':
        return 'Hasta gelmedi olarak kaydedilecek.';
      case 'cancelled':
        return 'Bu islem geri alinmaz. Randevu iptal edilecek.';
      default:
        return 'Devam etmek istiyor musun?';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.task_alt_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'no_show':
        return Icons.person_off_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }
}
