import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import '../../data/repositories/lost_found_repository.dart';

class ReportLostFoundScreen extends ConsumerStatefulWidget {
  const ReportLostFoundScreen({super.key});

  @override
  ConsumerState<ReportLostFoundScreen> createState() => _ReportLostFoundScreenState();
}

class _ReportLostFoundScreenState extends ConsumerState<ReportLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'lost';
  String _species = 'dog';
  String _gender = 'unknown';
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _ageController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _rewardController = TextEditingController();
  DateTime _lastSeenDate = DateTime.now();
  double? _lat;
  double? _lng;
  final List<XFile> _photos = [];
  bool _loading = false;
  bool _locationLoading = false;

  final _speciesOptions = [
    {'value': 'dog', 'label': 'Kopek'},
    {'value': 'cat', 'label': 'Kedi'},
    {'value': 'bird', 'label': 'Kus'},
    {'value': 'rabbit', 'label': 'Tavsan'},
    {'value': 'other', 'label': 'Diger'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _ageController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastSeenDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastSeenDate = picked);
  }

  Future<void> _getLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni gerekli')),
          );
        }
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() => _locationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Konum alinamadi: $e')));
      }
    }
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En fazla 5 foto eklenebilir')));
      return;
    }
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
    if (images.isNotEmpty) {
      setState(() {
        final remaining = 5 - _photos.length;
        _photos.addAll(images.take(remaining));
      });
    }
  }

  Future<List<String>> _uploadPhotos() async {
    if (_photos.isEmpty) return [];
    final client = ApiClient();
    final urls = <String>[];
    for (final photo in _photos) {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
        });
        final response = await client.dio.post('/api/uploads/image', data: formData);
        final url = response.data['url']?.toString();
        if (url != null) urls.add(url);
      } catch (e) {
        debugPrint('Photo upload error: $e');
      }
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_colorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renk/fiziksel tanim gerekli')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Upload photos first
      final photoUrls = await _uploadPhotos();

      final data = <String, dynamic>{
        'type': _type,
        'species': _species,
        'gender': _gender,
        'color': _colorController.text.trim(),
        'description': _descController.text.trim(),
        'lastSeenDate': _lastSeenDate.toIso8601String(),
        'photos': photoUrls,
      };

      if (_nameController.text.trim().isNotEmpty) data['petName'] = _nameController.text.trim();
      if (_breedController.text.trim().isNotEmpty) data['breed'] = _breedController.text.trim();
      if (_ageController.text.trim().isNotEmpty) data['ageApprox'] = _ageController.text.trim();
      if (_addressController.text.trim().isNotEmpty) data['lastSeenAddress'] = _addressController.text.trim();
      if (_phoneController.text.trim().isNotEmpty) data['contactPhone'] = _phoneController.text.trim();
      if (_noteController.text.trim().isNotEmpty) data['contactNote'] = _noteController.text.trim();

      if (_type == 'lost' && _rewardController.text.trim().isNotEmpty) {
        data['reward'] = double.tryParse(_rewardController.text.trim()) ?? 0;
      }

      if (_lat != null && _lng != null) {
        data['location'] = {
          'type': 'Point',
          'coordinates': [_lng, _lat],
        };
      }

      await ref.read(lostFoundRepositoryProvider).createReport(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ilan basariyla olusturuldu!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayip/Bulunan Ilani'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle
              Text('Ilan Tipi', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lost', label: Text('Kayip'), icon: Icon(Icons.search)),
                  ButtonSegment(value: 'found', label: Text('Bulunan'), icon: Icon(Icons.pets)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),

              // Pet name
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco(_type == 'lost' ? 'Hayvan Adi' : 'Hayvan Adi (opsiyonel)'),
              ),
              const SizedBox(height: 12),

              // Species
              Text('Tur', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _speciesOptions.map((opt) {
                  final selected = _species == opt['value'];
                  return ChoiceChip(
                    label: Text(opt['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() => _species = opt['value']!),
                    selectedColor: AppPalette.primary.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Breed + Color
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _breedController, decoration: _inputDeco('Cinsi'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: _inputDeco('Renk / Tanim *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Renk gerekli' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gender + Age
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: _inputDeco('Cinsiyet'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Erkek')),
                        DropdownMenuItem(value: 'female', child: Text('Disi')),
                        DropdownMenuItem(value: 'unknown', child: Text('Bilinmiyor')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'unknown'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _ageController, decoration: _inputDeco('Tahmini Yas'))),
                ],
              ),
              const SizedBox(height: 16),

              // Photos
              Text('Fotograflar (max 5)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photos.map((photo) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(photo.path), width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photos.remove(photo)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (_photos.length < 5)
                      GestureDetector(
                        onTap: _pickPhotos,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Icon(Icons.add_a_photo, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 32),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date
              Text(
                _type == 'lost' ? 'Son Gorulme Tarihi *' : 'Bulunma Tarihi *',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
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
                      const Icon(Icons.calendar_today, color: AppPalette.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(_formatDate(_lastSeenDate), style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              Text('Konum', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _locationLoading ? null : _getLocation,
                      icon: _locationLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: Text(_lat != null ? 'Konum Alindi' : 'Konumumu Kullan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lat != null ? Colors.green : null,
                        foregroundColor: _lat != null ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _inputDeco('Adres / Yer Tarifi'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: _inputDeco('Detayli Aciklama *'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Aciklama gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Contact
              Text('Iletisim', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDeco('Telefon Numarasi'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: _inputDeco('Iletisim Notu'),
              ),

              // Reward (only for lost)
              if (_type == 'lost') ...[
                const SizedBox(height: 16),
                Text('Odul (TL)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rewardController,
                  decoration: _inputDeco('Odul miktari (opsiyonel)'),
                  keyboardType: TextInputType.number,
                ),
              ],

              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'lost' ? Colors.red.shade600 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _type == 'lost' ? 'Kayip Ilani Olustur' : 'Bulunan Ilani Olustur',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
