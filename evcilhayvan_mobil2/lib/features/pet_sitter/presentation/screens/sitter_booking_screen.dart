import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';

class SitterBookingScreen extends ConsumerStatefulWidget {
  final PetSitterModel sitter;
  const SitterBookingScreen({super.key, required this.sitter});

  @override
  ConsumerState<SitterBookingScreen> createState() => _SitterBookingScreenState();
}

class _SitterBookingScreenState extends ConsumerState<SitterBookingScreen> {
  String? _selectedServiceType;
  String? _selectedPetId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _calcPrice() {
    if (_selectedServiceType == null) return 0;
    final service = widget.sitter.services.firstWhere((s) => s.type == _selectedServiceType, orElse: () => SitterService(type: ''));
    if (service.type.isEmpty) return 0;
    final hours = _endDate.difference(_startDate).inHours.abs();
    final days = (_endDate.difference(_startDate).inHours / 24).ceil();
    if (service.pricePerDay > 0 && days >= 1) return service.pricePerDay * days;
    return service.pricePerHour * hours;
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(context: context, initialDate: _startDate,
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _startDate = DateTime(d.year, d.month, d.day, _startDate.hour, _startDate.minute));
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(context: context, initialDate: _endDate,
        firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _endDate = DateTime(d.year, d.month, d.day, _endDate.hour, _endDate.minute));
  }

  Future<void> _submit() async {
    if (_selectedServiceType == null) { _snack('Hizmet secin'); return; }
    if (_selectedPetId == null) { _snack('Pet secin'); return; }
    if (_endDate.isBefore(_startDate)) { _snack('Bitis tarihi baslangictan once olamaz'); return; }

    setState(() => _loading = true);
    try {
      await ref.read(petSitterRepositoryProvider).createBooking({
        'sitterId': widget.sitter.id,
        'petId': _selectedPetId,
        'serviceType': _selectedServiceType,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rezervasyon Gonderildi!'),
            content: const Text('Bakiciniz rezervasyon talebinizi inceleyecek ve size bildirim gonderecek.'),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(ctx); context.pop(); },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(myPetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.sitter.displayName} - Rezervasyon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hizmet sec
            Text('Hizmet', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.sitter.services.map((s) {
                final selected = _selectedServiceType == s.type;
                return ChoiceChip(
                  label: Column(
                    children: [
                      Text(s.label),
                      if (s.pricePerHour > 0) Text('${s.pricePerHour.toInt()}TL/saat', style: const TextStyle(fontSize: 10)),
                      if (s.pricePerDay > 0) Text('${s.pricePerDay.toInt()}TL/gun', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedServiceType = s.type),
                  selectedColor: AppPalette.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Pet sec
            Text('Hayvaniniz', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            petsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Petler yuklenemedi: $e'),
              data: (pets) => pets.isEmpty
                  ? const Text('Henuz petiniz yok. Once pet ekleyin.')
                  : DropdownButtonFormField<String>(
                      value: _selectedPetId,
                      hint: const Text('Pet secin'),
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: pets.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (v) => setState(() => _selectedPetId = v),
                    ),
            ),
            const SizedBox(height: 16),

            // Tarihler
            Text('Tarihler', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.subtleBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Baslangic', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(_fmt(_startDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.subtleBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bitis', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(_fmt(_endDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notlar
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notlar (opsiyonel)',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Fiyat ozeti
            if (_selectedServiceType != null)
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.payments, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Tahmini Toplam:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${_calcPrice().toInt()} TL',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Rezervasyon Gonder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
