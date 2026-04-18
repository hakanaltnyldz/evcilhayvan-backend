import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import '../../data/repositories/vaccination_repository.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/veterinary_model.dart';

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

  // Veteriner seçimi
  List<VeterinaryModel> _vets = [];
  VeterinaryModel? _selectedVet;
  bool _vetsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    setState(() => _vetsLoading = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      final vets = await repo.searchVets();
      if (mounted) setState(() => _vets = vets);
    } catch (_) {
      // Sessizce devam et, veteriner seçimi opsiyonel
    } finally {
      if (mounted) setState(() => _vetsLoading = false);
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uygulama tarihi seçin')));
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
        veterinaryId: _selectedVet?.id,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        ref.invalidate(petVaccinationCalendarProvider(widget.petId));
        ref.invalidate(petVaccinationsProvider(widget.petId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aşı kaydı eklendi!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Aşı Kaydı Ekle'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aşı Adı
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco('Aşı Adı *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Aşı adı gerekli' : null,
              ),
              const SizedBox(height: 12),

              // Aşı Kodu
              TextFormField(controller: _codeController, decoration: _inputDeco('Aşı Kodu')),
              const SizedBox(height: 12),

              // Seri No
              TextFormField(controller: _batchController, decoration: _inputDeco('Seri Numarası')),
              const SizedBox(height: 16),

              // Veteriner Seçimi
              Text('Veteriner (Opsiyonel)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _vetsLoading
                  ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                  : _vets.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.subtleBorder),
                          ),
                          child: Text('Sistemde kayıtlı veteriner bulunamadı', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.subtleBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<VeterinaryModel>(
                              value: _selectedVet,
                              isExpanded: true,
                              hint: Row(
                                children: [
                                  const Icon(Icons.local_hospital_outlined, color: Color(0xFF2D6A4F), size: 20),
                                  const SizedBox(width: 8),
                                  Text('Veteriner seçin', style: theme.textTheme.bodyLarge),
                                ],
                              ),
                              items: [
                                DropdownMenuItem<VeterinaryModel>(
                                  value: null,
                                  child: Text('Seçim yok', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                                ),
                                ..._vets.map((vet) => DropdownMenuItem<VeterinaryModel>(
                                      value: vet,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.local_hospital, color: Color(0xFF2D6A4F), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(vet.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                                if (vet.address != null)
                                                  Text(vet.address!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                              onChanged: (vet) => setState(() => _selectedVet = vet),
                            ),
                          ),
                        ),
              const SizedBox(height: 16),

              // Seçili veteriner göstergesi
              if (_selectedVet != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_selectedVet!.name, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF2D6A4F), fontWeight: FontWeight.w600))),
                      GestureDetector(
                        onTap: () => setState(() => _selectedVet = null),
                        child: const Icon(Icons.close, color: Colors.grey, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Uygulama Tarihi
              Text('Uygulama Tarihi *', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dateButton(
                date: _dateAdministered,
                hint: 'Tarih seçin',
                onTap: () => _pickDate(isNextDue: false),
              ),
              const SizedBox(height: 16),

              // Sonraki Doz Tarihi
              Text('Sonraki Doz Tarihi', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dateButton(
                date: _nextDueDate,
                hint: 'Opsiyonel',
                onTap: () => _pickDate(isNextDue: true),
              ),
              const SizedBox(height: 16),

              // Notlar
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
                    : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6A4F))),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      );
}
