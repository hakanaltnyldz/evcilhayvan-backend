import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
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
      List<AvailabilityOverrideModel> availabilityOverrides =
          vet.availabilityOverrides;
      List<Map<String, dynamic>> bookingLoad = const [];

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

      try {
        final availabilityData = await vetRepo.getMyClinicAvailability();
        availabilityOverrides =
            (availabilityData['availabilityOverrides']
                as List<AvailabilityOverrideModel>?) ??
            availabilityOverrides;
        bookingLoad =
            (availabilityData['bookingLoad'] as List<Map<String, dynamic>>?) ??
            const [];
      } catch (_) {}

      return _VetClinicPanelData(
        vet: vet,
        claim: activeClaim,
        reviews: reviews,
        averageRating: averageRating,
        ratingCount: ratingCount,
        appointments: appointments,
        availabilityOverrides: availabilityOverrides,
        bookingLoad: bookingLoad,
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
  final _clinicFeeController = TextEditingController();
  final _onlineFeeController = TextEditingController();

  bool _acceptsOnlineAppointments = false;
  bool _saving = false;
  String? _seededVetId;
  final Set<String> _selectedSpecies = <String>{};
  final Set<String> _selectedServices = <String>{};
  List<_WorkingHoursDraft> _workingHours = _buildDefaultWorkingHours();
  List<_AvailabilityOverrideDraft> _availabilityOverrides =
      _buildAvailabilityDrafts();

  static const List<String> _speciesOptions = [
    'dog',
    'cat',
    'bird',
    'fish',
    'rodent',
    'other',
  ];

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
    _clinicFeeController.dispose();
    _onlineFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelAsync = ref.watch(_vetClinicPanelProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.clinicPanelTitle),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _seededVetId = null);
              ref.invalidate(_vetClinicPanelProvider);
            },
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
          final bookingLoadByDate = <String, Map<String, dynamic>>{
            for (final item in data.bookingLoad)
              (item['date']?.toString() ?? ''): item,
          };

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _seededVetId = null);
              ref.invalidate(_vetClinicPanelProvider);
            },
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
                      title: l10n.clinicPanelAppScore,
                      value: data.averageRating.toStringAsFixed(1),
                      subtitle: l10n.clinicPanelReviewCount(data.ratingCount),
                      icon: Icons.star_rounded,
                      accent: Colors.amber.shade700,
                    ),
                    _MetricCard(
                      title: l10n.clinicPanelPending,
                      value: pendingCount.toString(),
                      subtitle: l10n.clinicPanelPendingSubtitle,
                      icon: Icons.schedule_rounded,
                      accent: Colors.orange.shade700,
                    ),
                    _MetricCard(
                      title: l10n.clinicPanelConfirmed,
                      value: confirmedCount.toString(),
                      subtitle: l10n.clinicPanelConfirmedSubtitle,
                      icon: Icons.event_available_rounded,
                      accent: const Color(0xFF2D6A4F),
                    ),
                    _MetricCard(
                      title: l10n.clinicPanelCompleted,
                      value: completedCount.toString(),
                      subtitle: l10n.clinicPanelCompletedSubtitle,
                      icon: Icons.task_alt_rounded,
                      accent: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: l10n.clinicPanelProfileTitle,
                  subtitle: l10n.clinicPanelProfileSubtitle,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: l10n.clinicPanelClinicName,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? l10n.clinicPanelClinicNameRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _addressController,
                          label: l10n.clinicPanelAddress,
                          maxLines: 2,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? l10n.clinicPanelAddressRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          label: l10n.clinicPanelPhone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          label: l10n.clinicPanelEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _websiteController,
                          label: l10n.clinicPanelWebsite,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _descriptionController,
                          label: l10n.clinicPanelDescription,
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
                          title: Text(
                            l10n.clinicPanelAcceptOnline,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(l10n.clinicPanelAcceptOnlineSubtitle),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _slotMinutesController,
                          label: l10n.clinicPanelSlotMinutes,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _clinicFeeController,
                                label: l10n.clinicPanelClinicFee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _onlineFeeController,
                                label: l10n.clinicPanelOnlineFee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n.clinicPanelServicesTitle,
                  subtitle: l10n.clinicPanelServicesSubtitle,
                  child: _ChipSelector(
                    options: <String>{
                      ..._defaultServiceOptions,
                      ..._selectedServices,
                    }.toList()..sort(),
                    selected: _selectedServices,
                    labelBuilder: (value) => _serviceLabel(l10n, value),
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
                  title: l10n.clinicPanelSpeciesTitle,
                  subtitle: l10n.clinicPanelSpeciesSubtitle,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _speciesOptions.map((species) {
                      final selected = _selectedSpecies.contains(species);
                      return FilterChip(
                        label: Text(_speciesLabel(l10n, species)),
                        selected: selected,
                        selectedColor: const Color(0xFFD8F3DC),
                        checkmarkColor: const Color(0xFF2D6A4F),
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedSpecies.remove(species);
                          } else {
                            _selectedSpecies.add(species);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n.clinicPanelWorkingHoursTitle,
                  subtitle: l10n.clinicPanelWorkingHoursSubtitle,
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
                  title: l10n.clinicPanelAvailabilityTitle,
                  subtitle: l10n.clinicPanelAvailabilitySubtitle,
                  child: Column(
                    children: _availabilityOverrides
                        .map(
                          (item) => _AvailabilityOverrideRow(
                            item: item,
                            bookingLoad:
                                (bookingLoadByDate[item.dateKey]?['total']
                                        as num?)
                                    ?.toInt() ??
                                0,
                            onClosedChanged: (value) => setState(() {
                              item.isClosed = value;
                              if (value) {
                                item.open = null;
                                item.close = null;
                              }
                            }),
                            onPickOpen: () => _pickAvailabilityTime(item, true),
                            onPickClose: () =>
                                _pickAvailabilityTime(item, false),
                            onReset: () => setState(() {
                              item.isClosed = false;
                              item.open = null;
                              item.close = null;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n.clinicPanelReviewsTitle,
                  subtitle: l10n.clinicPanelReviewsSubtitle,
                  child: _VetReviewPanel(
                    averageRating: data.averageRating,
                    ratingCount: data.ratingCount,
                    reviews: data.reviews,
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
                    _saving ? l10n.apptSaving : l10n.clinicPanelSaveChanges,
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
    _clinicFeeController.text = data.vet.clinicConsultationFee == 0
        ? ''
        : data.vet.clinicConsultationFee.toStringAsFixed(
            data.vet.clinicConsultationFee % 1 == 0 ? 0 : 2,
          );
    _onlineFeeController.text = data.vet.onlineConsultationFee == 0
        ? ''
        : data.vet.onlineConsultationFee.toStringAsFixed(
            data.vet.onlineConsultationFee % 1 == 0 ? 0 : 2,
          );
    _acceptsOnlineAppointments = data.vet.acceptsOnlineAppointments;
    _selectedSpecies
      ..clear()
      ..addAll(data.vet.speciesServed);
    _selectedServices
      ..clear()
      ..addAll(data.vet.services);
    _workingHours = _seedWorkingHours(data.vet.workingHours);
    _availabilityOverrides = _seedAvailabilityDrafts(
      data.availabilityOverrides,
    );
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

  Future<void> _pickAvailabilityTime(
    _AvailabilityOverrideDraft item,
    bool isOpen,
  ) async {
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

    final l10n = AppLocalizations.of(context)!;
    final slotMinutes = int.tryParse(_slotMinutesController.text.trim()) ?? 30;
    if (slotMinutes < 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.clinicPanelSlotMinError)));
      return;
    }

    for (final item in _availabilityOverrides) {
      if (item.isClosed) continue;
      final hasOpen = (item.open ?? '').isNotEmpty;
      final hasClose = (item.close ?? '').isNotEmpty;
      if (hasOpen != hasClose) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.clinicPanelAvailabilityRangeRequired(item.label(context)),
            ),
          ),
        );
        return;
      }
      if (hasOpen && hasClose && item.open!.compareTo(item.close!) >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.clinicPanelAvailabilityCloseAfterOpen(item.label(context)),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      final clinicFee =
          double.tryParse(_clinicFeeController.text.replaceAll(',', '.')) ?? 0;
      final onlineFee =
          double.tryParse(_onlineFeeController.text.replaceAll(',', '.')) ?? 0;
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
        'clinicConsultationFee': clinicFee,
        'onlineConsultationFee': onlineFee,
        'workingHours': _workingHours.map((item) => item.toJson()).toList(),
      });
      await repo.updateMyClinicAvailability(
        _availabilityOverrides.map((item) => item.toJson()).toList(),
      );

      if (mounted) {
        setState(() => _seededVetId = null);
      }
      ref.invalidate(_vetClinicPanelProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.clinicPanelSaved)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clinicPanelSaveFailed(error.toString()))),
      );
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

String _formatDateOnly(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

class _VetClinicPanelData {
  const _VetClinicPanelData({
    required this.vet,
    required this.claim,
    required this.reviews,
    required this.averageRating,
    required this.ratingCount,
    required this.appointments,
    required this.availabilityOverrides,
    required this.bookingLoad,
  });

  final VeterinaryModel vet;
  final Map<String, dynamic>? claim;
  final List<VetReview> reviews;
  final double averageRating;
  final int ratingCount;
  final List<AppointmentModel> appointments;
  final List<AvailabilityOverrideModel> availabilityOverrides;
  final List<Map<String, dynamic>> bookingLoad;
}

class _ClinicHeroCard extends StatelessWidget {
  const _ClinicHeroCard({required this.data});

  final _VetClinicPanelData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final claimStatus = data.claim?['status']?.toString();
    final claimLabel = switch (claimStatus) {
      'approved' => l10n.clinicPanelClaimApproved,
      'rejected' => l10n.clinicPanelClaimRejected,
      'pending' => l10n.clinicPanelClaimPending,
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
                _HeroBadge(
                  label: l10n.clinicPanelVerifiedClinic,
                  color: const Color(0xFFD8F3DC),
                  textColor: const Color(0xFF1B4332),
                ),
              if (claimLabel != null)
                _HeroBadge(
                  label: claimLabel,
                  color: claimColor,
                  textColor: const Color(0xFF1B4332),
                ),
              if (data.vet.acceptsOnlineAppointments)
                _HeroBadge(
                  label: l10n.clinicPanelOnlineOpen,
                  color: const Color(0xFFE0FBFC),
                  textColor: const Color(0xFF0B5563),
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
                label: data.vet.phone ?? l10n.clinicPanelPhoneMissing,
              ),
              _MiniFact(
                icon: Icons.email_outlined,
                label: data.vet.email ?? l10n.clinicPanelEmailMissing,
              ),
              _MiniFact(
                icon: Icons.public_outlined,
                label: data.vet.website ?? l10n.clinicPanelWebsiteMissing,
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
    required this.labelBuilder,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final String Function(String value) labelBuilder;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(labelBuilder(option)),
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
    final l10n = AppLocalizations.of(context)!;

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
                    _weekdayLabel(l10n, item.day),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  item.isClosed ? l10n.clinicPanelClosed : l10n.clinicPanelOpen,
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
                    label: l10n.clinicPanelOpening,
                    value: item.open ?? '--:--',
                    enabled: !item.isClosed,
                    onTap: onPickOpen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: l10n.clinicPanelClosing,
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

class _AvailabilityOverrideRow extends StatelessWidget {
  const _AvailabilityOverrideRow({
    required this.item,
    required this.bookingLoad,
    required this.onClosedChanged,
    required this.onPickOpen,
    required this.onPickClose,
    required this.onReset,
  });

  final _AvailabilityOverrideDraft item;
  final int bookingLoad;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final helperText = item.isClosed
        ? l10n.clinicPanelDateClosed
        : (item.hasCustomHours
              ? l10n.clinicPanelDateCustomHours
              : l10n.clinicPanelDateDefaultHours);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label(context),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (bookingLoad > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.clinicPanelBookingLoad(bookingLoad),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8C5E00),
                      ),
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
                    label: l10n.clinicPanelOpening,
                    value: item.open ?? l10n.clinicPanelDefault,
                    enabled: !item.isClosed,
                    onTap: onPickOpen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: l10n.clinicPanelClosing,
                    value: item.close ?? l10n.clinicPanelDefault,
                    enabled: !item.isClosed,
                    onTap: onPickClose,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.clinicPanelResetWeeklyPlan),
              ),
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

class _VetReviewPanel extends StatelessWidget {
  const _VetReviewPanel({
    required this.averageRating,
    required this.ratingCount,
    required this.reviews,
  });

  final double averageRating;
  final int ratingCount;
  final List<VetReview> reviews;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.clinicPanelReviewsEmpty,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final visibleReviews = reviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.clinicPanelReviewCount(ratingCount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReviewStatPill(
                    icon: Icons.rate_review_outlined,
                    label: l10n.clinicPanelRecentReviews,
                  ),
                  _ReviewStatPill(
                    icon: Icons.thumb_up_alt_outlined,
                    label: l10n.clinicPanelQualityTracking,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...visibleReviews.map((review) => _ReviewTile(review: review)),
        if (reviews.length > visibleReviews.length)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (context) => SafeArea(
                    child: FractionallySizedBox(
                      heightFactor: 0.88,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: [
                          Text(
                            l10n.clinicPanelAllReviews,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.clinicPanelReviewSummary(
                              ratingCount,
                              averageRating.toStringAsFixed(1),
                            ),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...reviews.map(
                            (review) => _ReviewTile(review: review),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_full_rounded),
              label: Text(l10n.clinicPanelSeeAllReviews),
            ),
          ),
      ],
    );
  }
}

class _ReviewStatPill extends StatelessWidget {
  const _ReviewStatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B4332)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4332),
            ),
          ),
        ],
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
                        Localizations.localeOf(context).toString(),
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              l10n.clinicPanelLoadFailed,
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
              label: Text(l10n.retry),
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedEmptyState(
              icon: Icons.local_hospital_outlined,
              title: l10n.clinicPanelNoClinicTitle,
              subtitle: l10n.clinicPanelNoClinicSubtitle,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l10n.vetRegisterSaveBtn),
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
    this.open,
    this.close,
    this.isClosed = false,
  });

  final int day;
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

class _AvailabilityOverrideDraft {
  _AvailabilityOverrideDraft({
    required this.date,
    this.open,
    this.close,
    this.isClosed = false,
  });

  final DateTime date;
  String? open;
  String? close;
  bool isClosed;

  bool get hasCustomHours =>
      (open ?? '').isNotEmpty || (close ?? '').isNotEmpty;

  String get dateKey => _formatDateOnly(date);

  String label(BuildContext context) {
    return DateFormat(
      'dd MMM, EEEE',
      Localizations.localeOf(context).toString(),
    ).format(date);
  }

  Map<String, dynamic> toJson() => {
    'date': dateKey,
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

String _speciesLabel(AppLocalizations l10n, String species) {
  switch (species) {
    case 'dog':
      return l10n.aiSpeciesDog;
    case 'cat':
      return l10n.aiSpeciesCat;
    case 'bird':
      return l10n.aiSpeciesBird;
    case 'fish':
      return l10n.clinicPanelSpeciesFish;
    case 'rodent':
      return l10n.clinicPanelSpeciesRodent;
    case 'other':
      return l10n.aiSpeciesOther;
    default:
      return species;
  }
}

String _serviceLabel(AppLocalizations l10n, String service) {
  switch (service.toLowerCase()) {
    case 'muayene':
      return l10n.clinicPanelServiceExam;
    case 'asi':
    case 'aşı':
      return l10n.clinicPanelServiceVaccination;
    case 'cerrahi':
      return l10n.clinicPanelServiceSurgery;
    case 'acil bakim':
    case 'acil bakım':
      return l10n.clinicPanelServiceEmergencyCare;
    case 'laboratuvar':
      return l10n.clinicPanelServiceLaboratory;
    case 'dis bakimi':
    case 'diş bakımı':
      return l10n.clinicPanelServiceDentalCare;
    case 'check-up':
    case 'checkup':
      return l10n.clinicPanelServiceCheckup;
    case 'online danisma':
    case 'online danışma':
      return l10n.clinicPanelServiceOnlineConsultation;
    default:
      return service;
  }
}

String _weekdayLabel(AppLocalizations l10n, int day) {
  switch (day) {
    case 0:
      return l10n.weekdayMonday;
    case 1:
      return l10n.weekdayTuesday;
    case 2:
      return l10n.weekdayWednesday;
    case 3:
      return l10n.weekdayThursday;
    case 4:
      return l10n.weekdayFriday;
    case 5:
      return l10n.weekdaySaturday;
    case 6:
      return l10n.weekdaySunday;
    default:
      return day.toString();
  }
}

List<_WorkingHoursDraft> _buildDefaultWorkingHours() {
  return List<_WorkingHoursDraft>.generate(
    7,
    (index) => _WorkingHoursDraft(
      day: index,
      open: index < 5 ? '09:00' : '10:00',
      close: index < 5 ? '18:00' : '16:00',
      isClosed: false,
    ),
  );
}

List<_AvailabilityOverrideDraft> _buildAvailabilityDrafts({int days = 14}) {
  final now = DateTime.now();
  return List<_AvailabilityOverrideDraft>.generate(days, (index) {
    final date = DateTime(now.year, now.month, now.day + index);
    return _AvailabilityOverrideDraft(date: date);
  });
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

List<_AvailabilityOverrideDraft> _seedAvailabilityDrafts(
  List<AvailabilityOverrideModel> source, {
  int days = 14,
}) {
  final drafts = _buildAvailabilityDrafts(days: days);
  final sourceByDate = <String, AvailabilityOverrideModel>{
    for (final item in source) _formatDateOnly(item.date): item,
  };

  for (final draft in drafts) {
    final match = sourceByDate[draft.dateKey];
    if (match == null) continue;
    draft.open = match.open;
    draft.close = match.close;
    draft.isClosed = match.isClosed;
  }

  return drafts;
}
