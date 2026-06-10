import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/step_progress.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import '../../data/repositories/appointment_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class AppointmentCreateScreen extends ConsumerStatefulWidget {
  final String vetId;
  final String vetName;
  final bool acceptsOnlineAppointments;

  const AppointmentCreateScreen({
    super.key,
    required this.vetId,
    required this.vetName,
    this.acceptsOnlineAppointments = true,
  });

  @override
  ConsumerState<AppointmentCreateScreen> createState() =>
      _AppointmentCreateScreenState();
}

class _AppointmentCreateScreenState
    extends ConsumerState<AppointmentCreateScreen> {
  // Steps: 0=Pet, 1=Tarih+Saat (MHRS), 2=Onay
  int _step = 0;
  Pet? _selectedPet;
  DateTime _focusedDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _selectedDate;
  String? _selectedSlot;
  String _appointmentType = 'clinic';
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  // Slot cache: dateStr → slots
  final Map<String, List<String>> _slotCache = {};
  final Map<String, bool> _slotLoading = {};
  List<String> get _currentSlots =>
      _selectedDate != null ? (_slotCache[_dateKey(_selectedDate!)] ?? []) : [];
  bool get _currentSlotsLoading =>
      _selectedDate != null &&
      (_slotLoading[_dateKey(_selectedDate!)] ?? false);

  // Horizontal day list scroll
  final ScrollController _dayScrollController = ScrollController();

  // 60 günlük pencere
  late final List<DateTime> _days = List.generate(
    60,
    (i) => DateTime.now().add(Duration(days: i + 1)),
  );

  @override
  void initState() {
    super.initState();
    // İlk günü seç ve slotları yükle
    _selectDay(_days.first);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _selectDay(DateTime day) async {
    setState(() {
      _selectedDate = day;
      _selectedSlot = null;
    });
    final key = _dateKey(day);
    if (_slotCache.containsKey(key)) return; // zaten yüklü
    setState(() => _slotLoading[key] = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final slots = await repo.getAvailableSlots(
        vetId: widget.vetId,
        date: key,
      );
      if (mounted) {
        setState(() {
          _slotCache[key] = slots;
          _slotLoading[key] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _slotCache[key] = [];
          _slotLoading[key] = false;
        });
      }
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _selectedPet != null;
      case 1:
        return _selectedDate != null && _selectedSlot != null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() => setState(() => _step++);

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedPet == null ||
        _selectedDate == null ||
        _selectedSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.apptCreateValidation)));
      return;
    }
    if (_appointmentType == 'online' && !widget.acceptsOnlineAppointments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu klinik online randevu kabul etmiyor.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final parts = _selectedSlot!.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );
      await repo.createAppointment(
        petId: _selectedPet!.id,
        veterinaryId: widget.vetId,
        date: dateTime,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        type: _appointmentType,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.apptCreateSuccess)));
        ref.invalidate(myAppointmentsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.apptCreateError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.apptCreateTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          StepProgress(
            totalSteps: 3,
            currentStep: _step,
            stepLabels: [
              l10n.apptCreateStepPet,
              l10n.apptCreateStepDateTime,
              l10n.apptCreateStepConfirm,
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(_step),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavButtons(),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildPetStep();
      case 1:
        return _buildCalendarSlotStep();
      case 2:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Pet Selection ───────────────────────────────────────

  Widget _buildPetStep() {
    final l10n = AppLocalizations.of(context)!;
    final myPetsAsync = ref.watch(myPetsProvider);

    return myPetsAsync.when(
      loading: () => Center(child: PawLoading()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.apptCreatePetsError(e.toString()),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (pets) {
        if (pets.isEmpty) {
          return Center(
            child: AnimatedEmptyState(
              icon: Icons.pets,
              title: l10n.apptCreateNoPets,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            final selected = _selectedPet?.id == pet.id;
            return InteractiveScale(
                  onTap: () => setState(() => _selectedPet = pet),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFD8F3DC)
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2D6A4F)
                            : context.subtleBorder,
                        width: selected ? 2 : 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2D6A4F,
                          ).withOpacity(selected ? 0.15 : 0.06),
                          blurRadius: selected ? 12 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildPetAvatar(pet),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: selected
                                            ? const Color(0xFF1B4332)
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pet.species,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D6A4F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms, delay: (index * 60).ms)
                .slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }

  Widget _buildPetAvatar(Pet pet) {
    if (pet.photos.isNotEmpty) {
      final url = '${AppConfig.current.apiBaseUrl}${pet.photos[0]}';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 40,
            height: 40,
            color: const Color(0xFFD8F3DC),
            child: const Icon(Icons.pets, size: 20, color: Color(0xFF2D6A4F)),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD8F3DC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, size: 20, color: Color(0xFF2D6A4F)),
          ),
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFD8F3DC),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pets, size: 20, color: Color(0xFF2D6A4F)),
    );
  }

  // ─── Step 1: MHRS Takvim + Slot Seçimi ─────────────────────────

  Widget _buildCalendarSlotStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthLabel(),
        _buildDayStrip(),
        const Divider(height: 1),
        Expanded(child: _buildSlotPanel()),
      ],
    );
  }

  Widget _buildMonthLabel() {
    final d = _selectedDate ?? _days.first;
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFF2D6A4F),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy', locale).format(d),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip() {
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 76,
      child: ListView.builder(
        controller: _dayScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected =
              _selectedDate != null &&
              _dateKey(day) == _dateKey(_selectedDate!);
          final isToday =
              _dateKey(day) ==
              _dateKey(DateTime.now().add(const Duration(days: 1)));
          final hasSlots = _slotCache[_dateKey(day)]?.isNotEmpty ?? true;

          return GestureDetector(
            onTap: () => _selectDay(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2D6A4F) : context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2D6A4F)
                      : isToday
                      ? const Color(0xFF52B788)
                      : context.subtleBorder,
                  width: isSelected ? 0 : (isToday ? 1.5 : 0.5),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2D6A4F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', locale).format(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : hasSlots
                          ? const Color(0xFF1B4332)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Slot göstergesi (dolu/boş nokta)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white54
                          : _slotCache.containsKey(_dateKey(day))
                          ? (_slotCache[_dateKey(day)]!.isNotEmpty
                                ? const Color(0xFF52B788)
                                : Colors.grey.shade300)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotPanel() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentSlotsLoading) {
      return Center(child: PawLoading());
    }

    final slots = _currentSlots;

    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.apptCreateNoSlotsDay,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.apptCreateChooseAnotherDay,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Sabah / Öğleden sonra / Akşam grupla
    final morning = <String>[];
    final afternoon = <String>[];
    final evening = <String>[];
    for (final s in slots) {
      final h = int.tryParse(s.split(':').first) ?? 0;
      if (h < 12) {
        morning.add(s);
      } else if (h < 17) {
        afternoon.add(s);
      } else {
        evening.add(s);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seçili tarih başlığı
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8F3DC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatFullDate(_selectedDate!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4332),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.apptCreateAvailableSlots(slots.length),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (morning.isNotEmpty) ...[
            _buildSlotGroupHeader(
              Icons.wb_sunny_rounded,
              l10n.apptCreateMorning,
              const Color(0xFFF9A825),
            ),
            const SizedBox(height: 10),
            _buildSlotGrid(morning),
            const SizedBox(height: 20),
          ],
          if (afternoon.isNotEmpty) ...[
            _buildSlotGroupHeader(
              Icons.wb_cloudy_rounded,
              l10n.apptCreateAfternoon,
              const Color(0xFFFF8F00),
            ),
            const SizedBox(height: 10),
            _buildSlotGrid(afternoon),
            const SizedBox(height: 20),
          ],
          if (evening.isNotEmpty) ...[
            _buildSlotGroupHeader(
              Icons.nights_stay_rounded,
              l10n.apptCreateEvening,
              const Color(0xFF5C6BC0),
            ),
            const SizedBox(height: 10),
            _buildSlotGrid(evening),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotGroupHeader(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotGrid(List<String> slots) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final selected = _selectedSlot == slot;
        return InteractiveScale(
          onTap: () => setState(() => _selectedSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2D6A4F) : context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2D6A4F)
                    : context.subtleBorder,
                width: selected ? 1.5 : 0.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? Colors.white : const Color(0xFF1B4332),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatFullDate(DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, d MMMM', locale).format(d);
  }

  // ─── Step 2: Onay ────────────────────────────────────────────────

  Widget _buildConfirmStep() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Randevu Türü
          Text(
            l10n.apptCreateType,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AppointmentTypeCard(
                  icon: Icons.local_hospital_rounded,
                  label: l10n.apptCreateClinicType,
                  selected: _appointmentType == 'clinic',
                  onTap: () => setState(() => _appointmentType = 'clinic'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AppointmentTypeCard(
                  icon: Icons.videocam_rounded,
                  label: l10n.apptCreateOnlineType,
                  selected: _appointmentType == 'online',
                  onTap: () {
                    if (!widget.acceptsOnlineAppointments) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bu klinik online randevu kabul etmiyor.',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() => _appointmentType = 'online');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Neden
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.apptCreateReason,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notlar
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.apptCreateNotes,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Özet kart
          PremiumCard(
            accentColor: const Color(0xFF52B788),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.local_hospital_rounded,
                  widget.vetName,
                  theme,
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.pets_rounded,
                  _selectedPet?.name ?? '-',
                  theme,
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.calendar_today_rounded,
                  _selectedDate != null ? _formatFullDate(_selectedDate!) : '-',
                  theme,
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.access_time_rounded,
                  _selectedSlot ?? '-',
                  theme,
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  _appointmentType == 'online'
                      ? Icons.videocam_rounded
                      : Icons.local_hospital_rounded,
                  _appointmentType == 'online'
                      ? l10n.apptCreateOnlineSummary
                      : l10n.apptCreateClinicSummary,
                  theme,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD8F3DC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Navigation ───────────────────────────────────────────

  Widget _buildNavButtons() {
    final l10n = AppLocalizations.of(context)!;
    final isBusy = _currentSlotsLoading || _loading;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    side: const BorderSide(color: Color(0xFF2D6A4F)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.back),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_canProceed && !isBusy)
                    ? (_step < 2 ? _nextStep : _submit)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF2D6A4F,
                  ).withOpacity(0.4),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _step < 2
                    ? Text(
                        l10n.apptCreateContinue,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      )
                    : _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.apptCreateBtn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppointmentTypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD8F3DC)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade500,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected
                    ? const Color(0xFF1B4332)
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
