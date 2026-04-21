import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/appointment_model.dart';
import '../../domain/models/vet_review_model.dart';
import '../../domain/models/veterinary_model.dart';

final _vetClinicPanelProvider =
    FutureProvider.autoDispose<_VetClinicPanelData?>((ref) async {
      final vetRepo = ref.watch(veterinaryRepositoryProvider);
      final appointmentRepo = ref.watch(appointmentRepositoryProvider);

      VeterinaryModel? vet;
      List<Map<String, dynamic>> claims = const [];

      try {
        vet = await vetRepo.getMyClinic();
      } catch (_) {
        vet = null;
      }

      try {
        claims = await vetRepo.getMyClaimStatus();
      } catch (_) {
        claims = const [];
      }

      final activeClaim = _pickPreferredClaim(claims);
      if (vet == null && activeClaim != null) {
        final claimVetId = _extractClaimVetId(activeClaim);
        if (claimVetId != null && claimVetId.isNotEmpty) {
          try {
            vet = await vetRepo.getVetDetail(claimVetId);
          } catch (_) {
            vet = null;
          }
        }
      }

      if (vet == null) {
        return null;
      }

      List<VetReview> reviews = const [];
      double averageRating = 0;
      int ratingCount = 0;
      List<AppointmentModel> appointments = const [];

      try {
        final reviewData = await vetRepo.getVetReviews(vet.id);
        reviews = (reviewData['reviews'] as List<VetReview>?) ?? const [];
        averageRating = (reviewData['averageRating'] as num?)?.toDouble() ?? 0;
        ratingCount = (reviewData['ratingCount'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      try {
        final schedule = await appointmentRepo.getVetSchedule();
        appointments =
            (schedule['appointments'] as List<AppointmentModel>?) ?? const [];
      } catch (_) {}

      return _VetClinicPanelData(
        vet: vet,
        claim: activeClaim,
        reviews: reviews,
        averageRating: averageRating,
        ratingCount: ratingCount,
        appointments: appointments,
      );
    });

class VetClinicPanelScreen extends ConsumerStatefulWidget {
  const VetClinicPanelScreen({super.key});

  @override
  ConsumerState<VetClinicPanelScreen> createState() =>
      _VetClinicPanelScreenState();
}

class _VetClinicPanelScreenState extends ConsumerState<VetClinicPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _slotMinutesController = TextEditingController();

  bool _acceptsOnlineAppointments = false;
  bool _saving = false;
  String? _seededVetId;
  final Set<String> _selectedSpecies = <String>{};
  final Set<String> _selectedServices = <String>{};
  List<_WorkingHoursDraft> _workingHours = _buildDefaultWorkingHours();

  static const Map<String, String> _speciesOptions = {
    'dog': 'Kopek',
    'cat': 'Kedi',
    'bird': 'Kus',
    'fish': 'Balik',
    'rodent': 'Kemirgen',
    'other': 'Diger',
  };

  static const List<String> _defaultServiceOptions = <String>[
    'Muayene',
    'Asi',
    'Cerrahi',
    'Acil Bakim',
    'Laboratuvar',
    'Dis Bakimi',
    'Check-up',
    'Online Danisma',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _slotMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelAsync = ref.watch(_vetClinicPanelProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Klinik Panelim'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_vetClinicPanelProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: panelAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (error, _) => _PanelError(
          message: error.toString(),
          onRetry: () => ref.invalidate(_vetClinicPanelProvider),
        ),
        data: (data) {
          if (data == null) {
            return _NoClinicPanel(
              onRegister: () => context.pushNamed('vet-register'),
            );
          }

          if (_seededVetId != data.vet.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _seedForm(data);
            });
            return const Center(child: PawLoading());
          }

          final pendingCount = data.appointments
              .where((item) => item.status == 'pending')
              .length;
          final confirmedCount = data.appointments
              .where((item) => item.status == 'confirmed')
              .length;
          final completedCount = data.appointments
              .where((item) => item.status == 'completed')
              .length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_vetClinicPanelProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ClinicHeroCard(data: data),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      title: 'App Puani',
                      value: data.averageRating.toStringAsFixed(1),
                      subtitle: '${data.ratingCount} yorum',
                      icon: Icons.star_rounded,
                      accent: Colors.amber.shade700,
                    ),
                    _MetricCard(
                      title: 'Bekleyen',
                      value: pendingCount.toString(),
                      subtitle: 'Onay bekleyen randevu',
                      icon: Icons.schedule_rounded,
                      accent: Colors.orange.shade700,
                    ),
                    _MetricCard(
                      title: 'Onayli',
                      value: confirmedCount.toString(),
                      subtitle: 'Takvimde aktif randevu',
                      icon: Icons.event_available_rounded,
                      accent: const Color(0xFF2D6A4F),
                    ),
                    _MetricCard(
                      title: 'Tamamlanan',
                      value: completedCount.toString(),
                      subtitle: 'Kapanan randevu',
                      icon: Icons.task_alt_rounded,
                      accent: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Profil Bilgileri',
                  subtitle:
                      'Klinik vitrini, iletisim bilgileri ve randevu tercihlerini bu alandan yonetin.',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Klinik Adi',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Klinik adi gerekli'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Adres',
                          maxLines: 2,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Adres gerekli'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Telefon',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          label: 'E-posta',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website',
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Aciklama',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _acceptsOnlineAppointments,
                          activeColor: const Color(0xFF2D6A4F),
                          onChanged: (value) => setState(
                            () => _acceptsOnlineAppointments = value,
                          ),
                          title: const Text(
                            'Online randevu kabul et',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Aciksa kullanicilar video gorusme tipi randevu olusturabilir.',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _slotMinutesController,
                          label: 'Randevu Slot Dakikasi',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Hizmetler',
                  subtitle:
                      'One cikan hizmetleri secin. Profil kartlarinda chip olarak gosterilir.',
                  child: _ChipSelector(
                    options: <String>{
                      ..._defaultServiceOptions,
                      ..._selectedServices,
                    }.toList()..sort(),
                    selected: _selectedServices,
                    onToggle: (value) => setState(() {
                      if (_selectedServices.contains(value)) {
                        _selectedServices.remove(value);
                      } else {
                        _selectedServices.add(value);
                      }
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Hizmet Verilen Turler',
                  subtitle:
                      'Arama ve filtrelerde eslesme icin hizmet verilen hayvan turlerini secin.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _speciesOptions.entries.map((entry) {
                      final selected = _selectedSpecies.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: selected,
                        selectedColor: const Color(0xFFD8F3DC),
                        checkmarkColor: const Color(0xFF2D6A4F),
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedSpecies.remove(entry.key);
                          } else {
                            _selectedSpecies.add(entry.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Calisma Saatleri',
                  subtitle:
                      'Takvim yonetiminin temelini olusturur. Kapali gunleri ve saat araliklarini duzenleyin.',
                  child: Column(
                    children: _workingHours
                        .map(
                          (item) => _WorkingHoursRow(
                            item: item,
                            onClosedChanged: (value) =>
                                setState(() => item.isClosed = value),
                            onPickOpen: () => _pickTime(item, true),
                            onPickClose: () => _pickTime(item, false),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Son Yorumlar',
                  subtitle:
                      'Klinik kalitesini takip etmek icin son gelen geri bildirimler.',
                  child: data.reviews.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Henuz uygulama ici yorum yok.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Column(
                          children: data.reviews.take(3).map((review) {
                            return _ReviewTile(review: review);
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(data.vet.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _saving
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
                    _saving ? 'Kaydediliyor...' : 'Degisiklikleri Kaydet',
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

  void _seedForm(_VetClinicPanelData data) {
    _seededVetId = data.vet.id;
    _nameController.text = data.vet.name;
    _addressController.text = data.vet.address ?? '';
    _phoneController.text = data.vet.phone ?? '';
    _emailController.text = data.vet.email ?? '';
    _websiteController.text = data.vet.website ?? '';
    _descriptionController.text = data.vet.description ?? '';
    _slotMinutesController.text = data.vet.appointmentSlotMinutes.toString();
    _acceptsOnlineAppointments = data.vet.acceptsOnlineAppointments;
    _selectedSpecies
      ..clear()
      ..addAll(data.vet.speciesServed);
    _selectedServices
      ..clear()
      ..addAll(data.vet.services);
    _workingHours = _seedWorkingHours(data.vet.workingHours);
    setState(() {});
  }

  Future<void> _pickTime(_WorkingHoursDraft item, bool isOpen) async {
    if (item.isClosed) return;

    final currentValue = isOpen ? item.open : item.close;
    final initial =
        _parseTime(currentValue) ?? const TimeOfDay(hour: 9, minute: 0);
    final result = await showTimePicker(context: context, initialTime: initial);

    if (result == null || !mounted) return;

    setState(() {
      final formatted = _formatTime(result);
      if (isOpen) {
        item.open = formatted;
      } else {
        item.close = formatted;
      }
    });
  }

  Future<void> _save(String vetId) async {
    if (!_formKey.currentState!.validate()) return;

    final slotMinutes = int.tryParse(_slotMinutesController.text.trim()) ?? 30;
    if (slotMinutes < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot suresi en az 10 dakika olmali.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      await repo.updateVetProfile(vetId, {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _nullable(_phoneController.text),
        'email': _nullable(_emailController.text),
        'website': _nullable(_websiteController.text),
        'description': _nullable(_descriptionController.text),
        'services': _selectedServices.toList(),
        'speciesServed': _selectedSpecies.toList(),
        'acceptsOnlineAppointments': _acceptsOnlineAppointments,
        'appointmentSlotMinutes': slotMinutes,
        'workingHours': _workingHours.map((item) => item.toJson()).toList(),
      });

      ref.invalidate(_vetClinicPanelProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klinik bilgileri guncellendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayit basarisiz: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _VetClinicPanelData {
  const _VetClinicPanelData({
    required this.vet,
    required this.claim,
    required this.reviews,
    required this.averageRating,
    required this.ratingCount,
    required this.appointments,
  });

  final VeterinaryModel vet;
  final Map<String, dynamic>? claim;
  final List<VetReview> reviews;
  final double averageRating;
  final int ratingCount;
  final List<AppointmentModel> appointments;
}

class _ClinicHeroCard extends StatelessWidget {
  const _ClinicHeroCard({required this.data});

  final _VetClinicPanelData data;

  @override
  Widget build(BuildContext context) {
    final claimStatus = data.claim?['status']?.toString();
    final claimLabel = switch (claimStatus) {
      'approved' => 'Sahiplik onayli',
      'rejected' => 'Talep reddedildi',
      'pending' => 'Onay bekliyor',
      _ => null,
    };

    final claimColor = switch (claimStatus) {
      'approved' => const Color(0xFFD8F3DC),
      'rejected' => const Color(0xFFFFE5E5),
      'pending' => const Color(0xFFFFF4D6),
      _ => Colors.white24,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (data.vet.isVerified)
                const _HeroBadge(
                  label: 'Dogrulanmis Klinik',
                  color: Color(0xFFD8F3DC),
                  textColor: Color(0xFF1B4332),
                ),
              if (claimLabel != null)
                _HeroBadge(
                  label: claimLabel,
                  color: claimColor,
                  textColor: const Color(0xFF1B4332),
                ),
              if (data.vet.acceptsOnlineAppointments)
                const _HeroBadge(
                  label: 'Online Randevu Acik',
                  color: Color(0xFFE0FBFC),
                  textColor: Color(0xFF0B5563),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.vet.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          if ((data.vet.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.vet.address!,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _MiniFact(
                icon: Icons.phone_outlined,
                label: data.vet.phone ?? 'Telefon eklenmedi',
              ),
              _MiniFact(
                icon: Icons.email_outlined,
                label: data.vet.email ?? 'E-posta eklenmedi',
              ),
              _MiniFact(
                icon: Icons.public_outlined,
                label: data.vet.website ?? 'Website eklenmedi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: const Color(0xFFD8F3DC),
          checkmarkColor: const Color(0xFF2D6A4F),
          onSelected: (_) => onToggle(option),
        );
      }).toList(),
    );
  }
}

class _WorkingHoursRow extends StatelessWidget {
  const _WorkingHoursRow({
    required this.item,
    required this.onClosedChanged,
    required this.onPickOpen,
    required this.onPickClose,
  });

  final _WorkingHoursDraft item;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  item.isClosed ? 'Kapali' : 'Acik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.isClosed
                        ? Colors.red.shade600
                        : const Color(0xFF2D6A4F),
                  ),
                ),
                Switch.adaptive(
                  value: item.isClosed,
                  activeColor: Colors.red.shade600,
                  onChanged: onClosedChanged,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Acilis',
                    value: item.open ?? '--:--',
                    enabled: !item.isClosed,
                    onTap: onPickOpen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: 'Kapanis',
                    value: item.close ?? '--:--',
                    enabled: !item.isClosed,
                    onTap: onPickClose,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? const Color(0xFF52B788).withOpacity(0.35)
                : Colors.grey.shade300,
          ),
          color: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: enabled ? const Color(0xFF2D6A4F) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final VetReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD8F3DC),
                backgroundImage: review.userAvatarUrl != null
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: review.userAvatarUrl == null
                    ? Text(
                        review.userName.isEmpty
                            ? '?'
                            : review.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF1B4332),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DateFormat(
                        'dd MMM yyyy',
                        'tr_TR',
                      ).format(review.createdAt.toLocal()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelError extends StatelessWidget {
  const _PanelError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Klinik paneli yuklenemedi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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

class _NoClinicPanel extends StatelessWidget {
  const _NoClinicPanel({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedEmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'Yonetilecek klinik bulunamadi',
              subtitle:
                  'Once bir klinik kaydi yapin veya mevcut klinik talebinizin onaylanmasini bekleyin.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Klinik Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkingHoursDraft {
  _WorkingHoursDraft({
    required this.day,
    required this.label,
    this.open,
    this.close,
    this.isClosed = false,
  });

  final int day;
  final String label;
  String? open;
  String? close;
  bool isClosed;

  Map<String, dynamic> toJson() => {
    'day': day,
    'open': isClosed ? null : open,
    'close': isClosed ? null : close,
    'isClosed': isClosed,
  };
}

Map<String, dynamic>? _pickPreferredClaim(List<Map<String, dynamic>> claims) {
  if (claims.isEmpty) return null;
  for (final claim in claims) {
    if (claim['status']?.toString() == 'approved') return claim;
  }
  for (final claim in claims) {
    if (claim['status']?.toString() == 'pending') return claim;
  }
  return claims.first;
}

String? _extractClaimVetId(Map<String, dynamic>? claim) {
  if (claim == null) return null;
  final vet = claim['vetId'];
  if (vet is Map<String, dynamic>) {
    return vet['_id']?.toString() ?? vet['id']?.toString();
  }
  return vet?.toString();
}

List<_WorkingHoursDraft> _buildDefaultWorkingHours() {
  const labels = <String>[
    'Pazartesi',
    'Sali',
    'Carsamba',
    'Persembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  return List<_WorkingHoursDraft>.generate(
    labels.length,
    (index) => _WorkingHoursDraft(
      day: index,
      label: labels[index],
      open: index < 5 ? '09:00' : '10:00',
      close: index < 5 ? '18:00' : '16:00',
      isClosed: false,
    ),
  );
}

List<_WorkingHoursDraft> _seedWorkingHours(List<WorkingHours> source) {
  final drafts = _buildDefaultWorkingHours();
  for (final item in source) {
    final match = drafts.where((draft) => draft.day == item.day);
    if (match.isEmpty) continue;
    final draft = match.first;
    draft.open = item.open ?? draft.open;
    draft.close = item.close ?? draft.close;
    draft.isClosed = item.isClosed;
  }
  return drafts;
}
