// lib/features/pet_sitter/presentation/screens/care_report_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/config/app_config.dart';
import '../../domain/models/sitter_booking_model.dart';
import '../../data/repositories/pet_sitter_repository.dart';

class CareReportScreen extends ConsumerStatefulWidget {
  final SitterBookingModel booking;
  final int dayNumber;

  const CareReportScreen({
    super.key,
    required this.booking,
    required this.dayNumber,
  });

  @override
  ConsumerState<CareReportScreen> createState() => _CareReportScreenState();
}

class _CareReportScreenState extends ConsumerState<CareReportScreen> {
  String _mood = 'good';
  final _notesCtrl = TextEditingController();
  final Set<String> _activities = {};
  bool _foodEaten = true;
  final List<String> _uploadedPhotos = [];
  bool _isSending = false;

  static const _moods = [
    ('great', '😊', 'Harika'),
    ('good', '🙂', 'İyi'),
    ('okay', '😐', 'Normal'),
    ('tired', '😴', 'Yorgun'),
  ];

  static const _activityOptions = [
    ('walk', Icons.directions_walk, 'Yürüyüş'),
    ('play', Icons.sports_esports, 'Oyun'),
    ('grooming', Icons.auto_fix_high, 'Bakım'),
    ('bath', Icons.water_drop, 'Banyo'),
    ('training', Icons.school, 'Eğitim'),
    ('vet_visit', Icons.local_hospital, 'Veteriner'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 70);
    if (files.isEmpty || !mounted) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      for (final file in files) {
        final url = await repo.uploadCarePhoto(
          widget.booking.id,
          File(file.path),
        );
        if (url.isNotEmpty && mounted) setState(() => _uploadedPhotos.add(url));
      }
    } catch (e) {
      if (mounted) _showSnack('Fotoğraf yüklenemedi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _submit() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      await repo.createCareReport(widget.booking.id, {
        'day': widget.dayNumber,
        'mood': _mood,
        'photos': _uploadedPhotos,
        'notes': _notesCtrl.text.trim(),
        'activities': _activities.toList(),
        'foodEaten': _foodEaten,
      });
      if (mounted) {
        _showSnack('Gunluk rapor olusturuldu ve musteriye gonderildi!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showSnack('Rapor gönderilemedi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.dayNumber}. Gün Raporu'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Nasıl hissediyor?',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moods.map((m) {
                  final isSelected = _mood == m.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _mood = m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.primary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppPalette.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(m.$2, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            m.$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppPalette.primary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Yemek Yedi mi?',
              child: Row(
                children: [
                  const Text('Bugün yemeğini yedi'),
                  const Spacer(),
                  Switch(
                    value: _foodEaten,
                    onChanged: (v) => setState(() => _foodEaten = v),
                    activeColor: AppPalette.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Aktiviteler',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activityOptions.map((a) {
                  final isSelected = _activities.contains(a.$1);
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (v) => setState(() {
                      if (v)
                        _activities.add(a.$1);
                      else
                        _activities.remove(a.$1);
                    }),
                    avatar: Icon(a.$2, size: 16),
                    label: Text(a.$3),
                    selectedColor: AppPalette.primary.withOpacity(0.2),
                    checkmarkColor: AppPalette.primary,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Fotoğraflar',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_uploadedPhotos.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _uploadedPhotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final url =
                              '${AppConfig.current.apiBaseUrl}${_uploadedPhotos[i]}';
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  if (_uploadedPhotos.isNotEmpty) const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSending ? null : _pickAndUploadPhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Fotoğraf Ekle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.primary,
                      side: BorderSide(color: AppPalette.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Notlar',
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Bugün ne yaptınız? Özel bir şey oldu mu?',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppPalette.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Raporu Olustur ve Gonder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2E28) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
