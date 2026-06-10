import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/pet_sitter_repository.dart';

class SitterRequestFormScreen extends ConsumerStatefulWidget {
  const SitterRequestFormScreen({super.key});

  @override
  ConsumerState<SitterRequestFormScreen> createState() =>
      _SitterRequestFormScreenState();
}

class _SitterRequestFormScreenState
    extends ConsumerState<SitterRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _serviceType = 'walking';
  final Set<String> _petTypes = {'dog'};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  List<Map<String, Object>> _services(AppLocalizations l10n) => [
    {
      'value': 'walking',
      'label': l10n.sitterServiceWalkingLabel,
      'icon': Icons.directions_walk,
    },
    {
      'value': 'home_sitting',
      'label': l10n.sitterServiceHomeSittingLabel,
      'icon': Icons.home,
    },
    {
      'value': 'boarding',
      'label': l10n.sitterServiceBoardingLabel,
      'icon': Icons.hotel,
    },
    {
      'value': 'daycare',
      'label': l10n.sitterServiceDaycareLabel,
      'icon': Icons.wb_sunny,
    },
    {
      'value': 'grooming',
      'label': l10n.sitterServiceGroomingLabel,
      'icon': Icons.content_cut,
    },
  ];

  List<Map<String, String>> _petTypeOptions(AppLocalizations l10n) => [
    {'value': 'dog', 'label': '🐶 ${l10n.sitterSpeciesDog}'},
    {'value': 'cat', 'label': '🐱 ${l10n.sitterSpeciesCat}'},
    {'value': 'bird', 'label': '🐦 ${l10n.sitterSpeciesBird}'},
    {'value': 'rabbit', 'label': '🐰 ${l10n.sitterSpeciesRabbit}'},
    {'value': 'other', 'label': '🐾 ${l10n.sitterSpeciesOther}'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final first = isStart ? now : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? d, AppLocalizations l10n) {
    if (d == null) return l10n.sitterRequestSelectDate;
    return '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sitterRequestDateRequired)));
      return;
    }
    if (_petTypes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sitterSpeciesRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      await repo.createSitterRequest({
        'serviceType': _serviceType,
        'petTypes': _petTypes.toList(),
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'description': _descriptionController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sitterRequestPublished)));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sitterSubmitErr(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final services = _services(l10n);
    final petTypeOptions = _petTypeOptions(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sitterRequestFormTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hizmet tipi
            Text(
              l10n.sitterServiceType,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((s) {
                final selected = _serviceType == s['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _serviceType = s['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2D6A4F)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2D6A4F)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          s['icon'] as IconData,
                          size: 18,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s['label'] as String,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade800,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Hayvan türleri
            Text(
              l10n.sitterRequestPetTypeMulti,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: petTypeOptions.map((opt) {
                final selected = _petTypes.contains(opt['value']);
                return FilterChip(
                  label: Text(opt['label'] as String),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _petTypes.add(opt['value'] as String);
                      else
                        _petTypes.remove(opt['value']);
                    });
                  },
                  selectedColor: const Color(0xFF2D6A4F).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF2D6A4F),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF2D6A4F) : null,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Tarih aralığı
            Text(
              l10n.sitterRequestServiceDates,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sitterRequestStartDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_startDate, l10n),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '—',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sitterRequestEndDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_endDate, l10n),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Açıklama
            Text(
              l10n.sitterRequestExtraInfo,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.sitterRequestDescHint,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Yayınla butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.sitterRequestPublish,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
