import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import '../../data/repositories/vaccination_repository.dart';

class VaccinationAddScreen extends ConsumerStatefulWidget {
  final String petId;
  const VaccinationAddScreen({super.key, required this.petId});

  @override
  ConsumerState<VaccinationAddScreen> createState() => _VaccinationAddScreenState();
}

class _VaccinationAddScreenState extends ConsumerState<VaccinationAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dateAdministered;
  DateTime? _nextDueDate;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNextDue}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // dateAdministered → geçmiş veya bugün; nextDueDate → gelecek
    final firstDate = isNextDue ? today.add(const Duration(days: 1)) : DateTime(2020);
    final lastDate  = isNextDue ? today.add(const Duration(days: 730)) : today;
    final defaultInitial = isNextDue ? today.add(const Duration(days: 1)) : today;
    final initial = isNextDue
        ? (_nextDueDate?.isAfter(today) == true ? _nextDueDate! : defaultInitial)
        : (_dateAdministered != null && !_dateAdministered!.isAfter(today) ? _dateAdministered! : defaultInitial);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        if (isNextDue) {
          _nextDueDate = picked;
        } else {
          _dateAdministered = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateAdministered == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uygulama tarihi secin')));
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(vaccinationRepositoryProvider);
      await repo.addRecord(
        petId: widget.petId,
        vaccineName: _nameController.text.trim(),
        dateAdministered: _dateAdministered!,
        vaccineCode: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
        nextDueDate: _nextDueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        ref.invalidate(petVaccinationCalendarProvider(widget.petId));
        ref.invalidate(petVaccinationsProvider(widget.petId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asi kaydi eklendi!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(title: const Text('Asi Kaydi Ekle'), backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco('Asi Adi *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Asi adi gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _codeController, decoration: _inputDeco('Asi Kodu')),
              const SizedBox(height: 12),
              TextFormField(controller: _batchController, decoration: _inputDeco('Seri Numarasi')),
              const SizedBox(height: 16),

              // Uygulama tarihi
              Text('Uygulama Tarihi *', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dateButton(
                date: _dateAdministered,
                hint: 'Tarih secin',
                onTap: () => _pickDate(isNextDue: false),
              ),
              const SizedBox(height: 16),

              // Sonraki doz tarihi
              Text('Sonraki Doz Tarihi', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dateButton(
                date: _nextDueDate,
                hint: 'Opsiyonel',
                onTap: () => _pickDate(isNextDue: true),
              ),
              const SizedBox(height: 16),

              TextFormField(controller: _notesController, decoration: _inputDeco('Notlar'), maxLines: 3),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateButton({DateTime? date, required String hint, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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
            const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F), size: 20),
            const SizedBox(width: 12),
            Text(date != null ? _formatDate(date) : hint, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
