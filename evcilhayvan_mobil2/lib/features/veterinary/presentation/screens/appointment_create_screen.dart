import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      _fetchSlots(picked);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateSlotsError(e.toString()))));
    }
  }

  Future<void> _submit() async {
    if (_selectedPet == null || _selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateValidation)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateSuccess)));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.apptCreateError(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final myPetsAsync = ref.watch(myPetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.apptCreateTitle), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vet info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, color: AppPalette.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.vetName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pet secimi
            Text(l10n.apptCreateSelectPet, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            myPetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.apptCreatePetsError(e.toString())),
              data: (pets) {
                if (pets.isEmpty) {
                  return Text(l10n.apptCreateNoPets);
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pets.map((pet) {
                    final selected = _selectedPet?.id == pet.id;
                    return ChoiceChip(
                      label: Text(pet.name),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedPet = pet),
                      avatar: Icon(Icons.pets, size: 16, color: selected ? Colors.white : null),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Tarih secimi
            Text(l10n.apptCreateDate, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.subtleBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppPalette.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                          : l10n.apptCreateSelectDateBtn,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Saat secimi
            if (_selectedDate != null) ...[
              Text(l10n.apptCreateTime, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_slotsLoading)
                const Center(child: CircularProgressIndicator())
              else if (_availableSlots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(l10n.apptCreateNoSlots, textAlign: TextAlign.center),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((slot) {
                    final selected = _selectedSlot == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],

            // Neden
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: l10n.apptCreateReason,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Notlar
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.apptCreateNotes,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.apptCreateBtn),
            ),
          ],
        ),
      ),
    );
  }
}
