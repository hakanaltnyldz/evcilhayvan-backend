import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  const AppointmentCreateScreen({super.key, required this.vetId, required this.vetName});

  @override
  ConsumerState<AppointmentCreateScreen> createState() => _AppointmentCreateScreenState();
}

class _AppointmentCreateScreenState extends ConsumerState<AppointmentCreateScreen> {
  int _step = 0;
  Pet? _selectedPet;
  DateTime? _selectedDate;
  String? _selectedSlot;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;
  List<String> _availableSlots = [];
  bool _slotsLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _selectedPet != null;
      case 1:
        return _selectedDate != null;
      case 2:
        return _selectedSlot != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_step == 1 && _selectedDate != null) {
      _fetchSlots(_selectedDate!);
    }
    setState(() => _step++);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() => _slotsLoading = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final slots = await repo.getAvailableSlots(vetId: widget.vetId, date: dateStr);
      setState(() {
        _availableSlots = slots;
        _slotsLoading = false;
      });
    } catch (e) {
      setState(() => _slotsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateSlotsError(e.toString()))),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedPet == null || _selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateValidation)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final parts = _selectedSlot!.split(':');
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      await repo.createAppointment(
        petId: _selectedPet!.id,
        veterinaryId: widget.vetId,
        date: dateTime,
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateSuccess)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.apptCreateTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          StepProgress(
            totalSteps: 4,
            currentStep: _step,
            stepLabels: [
              l10n.apptCreateSelectPet,
              l10n.apptCreateDate,
              l10n.apptCreateTime,
              l10n.apptCreateBtn,
            ],
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
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
        return _buildDateStep();
      case 2:
        return _buildTimeStep();
      case 3:
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
          child: Text(l10n.apptCreatePetsError(e.toString()), textAlign: TextAlign.center),
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
                  color: selected ? const Color(0xFFD8F3DC) : context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? const Color(0xFF2D6A4F) : context.subtleBorder,
                    width: selected ? 2 : 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withOpacity(selected ? 0.15 : 0.06),
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
                                    color: selected ? const Color(0xFF1B4332) : null,
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
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms, delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
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

  // ─── Step 1: Date Selection ──────────────────────────────────────

  Widget _buildDateStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PremiumCard(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF52B788), width: 2),
                ),
                child: const Icon(Icons.calendar_month_rounded, size: 48, color: Color(0xFF2D6A4F)),
              ),
              const SizedBox(height: 20),
              if (_selectedDate != null) ...[
                Text(
                  '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatWeekday(_selectedDate!),
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: Text(l10n.apptCreateSelectDateBtn),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D6A4F)),
                ),
              ] else ...[
                Text(
                  l10n.apptCreateDate,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.apptCreateSelectDateBtn,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
      ),
    );
  }

  String _formatWeekday(DateTime date) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[date.weekday - 1];
  }

  // ─── Step 2: Time Slot Selection ─────────────────────────────────

  Widget _buildTimeStep() {
    final l10n = AppLocalizations.of(context)!;

    if (_slotsLoading) {
      return Center(child: PawLoading());
    }

    if (_availableSlots.isEmpty) {
      return Center(
        child: AnimatedEmptyState(
          icon: Icons.access_time_filled,
          title: l10n.apptCreateNoSlots,
        ),
      );
    }

    // Group slots
    final morning = <String>[];
    final afternoon = <String>[];
    final evening = <String>[];

    for (final slot in _availableSlots) {
      final hour = int.tryParse(slot.split(':').first) ?? 0;
      if (hour < 12) {
        morning.add(slot);
      } else if (hour < 17) {
        afternoon.add(slot);
      } else {
        evening.add(slot);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morning.isNotEmpty) ...[
            _buildTimeGroupHeader(Icons.wb_sunny_rounded, 'Sabah', const Color(0xFFF9A825)),
            const SizedBox(height: 8),
            _buildSlotGrid(morning),
            const SizedBox(height: 20),
          ],
          if (afternoon.isNotEmpty) ...[
            _buildTimeGroupHeader(Icons.wb_cloudy_rounded, 'Öğleden Sonra', const Color(0xFFFF8F00)),
            const SizedBox(height: 8),
            _buildSlotGrid(afternoon),
            const SizedBox(height: 20),
          ],
          if (evening.isNotEmpty) ...[
            _buildTimeGroupHeader(Icons.nights_stay_rounded, 'Akşam', const Color(0xFF5C6BC0)),
            const SizedBox(height: 8),
            _buildSlotGrid(evening),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeGroupHeader(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
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
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2D6A4F) : context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFF2D6A4F) : context.subtleBorder,
                width: selected ? 1.5 : 0.5,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
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

  // ─── Step 3: Summary + Confirm ───────────────────────────────────

  Widget _buildConfirmStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reason
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: l10n.apptCreateReason,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.apptCreateNotes,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Summary card
          PremiumCard(
            accentColor: const Color(0xFF52B788),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow(Icons.local_hospital_rounded, widget.vetName, theme),
                const Divider(height: 20),
                _buildSummaryRow(Icons.pets_rounded, _selectedPet?.name ?? '-', theme),
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.calendar_today_rounded,
                  _selectedDate != null
                      ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                      : '-',
                  theme,
                ),
                const Divider(height: 20),
                _buildSummaryRow(Icons.access_time_rounded, _selectedSlot ?? '-', theme),
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
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Navigation ───────────────────────────────────────────

  Widget _buildNavButtons() {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _step--;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    side: const BorderSide(color: Color(0xFF2D6A4F)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Geri'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed
                    ? (_step < 3 ? _nextStep : (_loading ? null : _submit))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF2D6A4F).withOpacity(0.4),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _step < 3
                    ? const Text('Devam', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))
                    : _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.apptCreateBtn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
