import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';

class BecomeSitterScreen extends ConsumerStatefulWidget {
  final PetSitterModel? existing; // null = yeni profil, dolu = duzenle
  const BecomeSitterScreen({super.key, this.existing});

  @override
  ConsumerState<BecomeSitterScreen> createState() => _BecomeSitterScreenState();
}

class _BecomeSitterScreenState extends ConsumerState<BecomeSitterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Hizmetler
  final List<_ServiceEntry> _services = [];
  static const _serviceTypes = [
    {'value': 'walking', 'label': 'Gezdirme'},
    {'value': 'home_sitting', 'label': 'Ev Bakimi'},
    {'value': 'boarding', 'label': 'Pansiyonda Bakim'},
    {'value': 'daycare', 'label': 'Gunduz Bakimi'},
    {'value': 'grooming', 'label': 'Timar/Bakim'},
  ];

  // Bakilan turler
  final Set<String> _speciesServed = {'dog'};
  static const _speciesOptions = [
    {'value': 'dog', 'label': 'Kopek'},
    {'value': 'cat', 'label': 'Kedi'},
    {'value': 'bird', 'label': 'Kus'},
    {'value': 'rabbit', 'label': 'Tavsan'},
    {'value': 'other', 'label': 'Diger'},
  ];

  double? _lat;
  double? _lng;
  bool _locationLoading = false;
  bool _loading = false;
  XFile? _avatarFile;
  String? _existingAvatar;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.displayName;
      _bioCtrl.text = e.bio ?? '';
      _expCtrl.text = e.experience ?? '';
      _addressCtrl.text = e.address ?? '';
      _lat = e.latitude;
      _lng = e.longitude;
      _existingAvatar = e.avatar;
      _speciesServed.clear();
      _speciesServed.addAll(e.speciesServed);
      for (final s in e.services) {
        _services.add(_ServiceEntry(
          type: s.type,
          hourCtrl: TextEditingController(text: s.pricePerHour > 0 ? s.pricePerHour.toInt().toString() : ''),
          dayCtrl: TextEditingController(text: s.pricePerDay > 0 ? s.pricePerDay.toInt().toString() : ''),
        ));
      }
    }
    if (_services.isEmpty) {
      _services.add(_ServiceEntry(type: 'walking'));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    _addressCtrl.dispose();
    for (final s in _services) {
      s.hourCtrl.dispose();
      s.dayCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni gerekli')));
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _locationLoading = false; });
    } catch (e) {
      setState(() => _locationLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Konum alinamadi: $e')));
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (file != null) setState(() => _avatarFile = file);
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarFile == null) return _existingAvatar;
    try {
      final client = ApiClient();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_avatarFile!.path, filename: _avatarFile!.name),
      });
      final response = await client.dio.post('/api/uploads/image', data: formData);
      return response.data['url']?.toString();
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      return _existingAvatar;
    }
  }

  bool get _hasServices => _services.any((s) =>
      double.tryParse(s.hourCtrl.text.trim()) != null ||
      double.tryParse(s.dayCtrl.text.trim()) != null);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_speciesServed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az bir hayvan turu secin')));
      return;
    }

    setState(() => _loading = true);
    try {
      final avatarUrl = await _uploadAvatar();

      final servicesData = _services.where((s) {
        final h = double.tryParse(s.hourCtrl.text.trim()) ?? 0;
        final d = double.tryParse(s.dayCtrl.text.trim()) ?? 0;
        return h > 0 || d > 0;
      }).map((s) => {
        'type': s.type,
        'pricePerHour': double.tryParse(s.hourCtrl.text.trim()) ?? 0,
        'pricePerDay': double.tryParse(s.dayCtrl.text.trim()) ?? 0,
      }).toList();

      final data = <String, dynamic>{
        'displayName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'experience': _expCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'speciesServed': _speciesServed.toList(),
        'services': servicesData,
        if (avatarUrl != null) 'avatar': avatarUrl,
        if (_lat != null && _lng != null)
          'location': {'type': 'Point', 'coordinates': [_lng, _lat]},
      };

      final repo = ref.read(petSitterRepositoryProvider);
      if (widget.existing != null) {
        await repo.updateSitter(widget.existing!.id, data);
      } else {
        await repo.createSitter(data);
      }

      ref.invalidate(mySitterProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Profil guncellendi!' : 'Bakici profili olusturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Profili Duzenle' : 'Bakici Ol'),
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
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppPalette.primary.withOpacity(0.1),
                        backgroundImage: _avatarFile != null
                            ? FileImage(File(_avatarFile!.path)) as ImageProvider
                            : (_existingAvatar != null && _existingAvatar!.isNotEmpty)
                                ? NetworkImage('$apiBaseUrl$_existingAvatar')
                                : null,
                        child: (_avatarFile == null && (_existingAvatar == null || _existingAvatar!.isEmpty))
                            ? const Icon(Icons.person, size: 50, color: AppPalette.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppPalette.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Isim
              Text('Temel Bilgiler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: _deco('Goruntulenen Isim *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Isim gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                decoration: _deco('Hakkinda / Tanitim'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expCtrl,
                decoration: _deco('Deneyim'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Konum
              Text('Konum', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _locationLoading ? null : _getLocation,
                icon: _locationLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(_lat != null ? 'Konum Alindi ✓' : 'Konumumu Kullan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lat != null ? Colors.green : null,
                  foregroundColor: _lat != null ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: _deco('Adres / Semt'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Bakilan hayvanlar
              Text('Hangi Hayvanlarla Calisiyorsunuz?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _speciesOptions.map((opt) {
                  final selected = _speciesServed.contains(opt['value']);
                  return FilterChip(
                    label: Text(opt['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      if (selected) _speciesServed.remove(opt['value']);
                      else _speciesServed.add(opt['value']!);
                    }),
                    selectedColor: AppPalette.primary.withOpacity(0.2),
                    checkmarkColor: AppPalette.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Hizmetler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sundugunuz Hizmetler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      final usedTypes = _services.map((s) => s.type).toSet();
                      final available = _serviceTypes.where((t) => !usedTypes.contains(t['value'])).toList();
                      if (available.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tum hizmetler eklendi')));
                        return;
                      }
                      setState(() => _services.add(_ServiceEntry(type: available.first['value']!)));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._services.asMap().entries.map((entry) => _buildServiceRow(entry.key, entry.value, theme)),
              const SizedBox(height: 32),

              // Submit
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Profili Guncelle' : 'Bakici Profili Olustur',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceRow(int index, _ServiceEntry entry, ThemeData theme) {
    final usedTypes = _services.asMap().entries
        .where((e) => e.key != index)
        .map((e) => e.value.type)
        .toSet();
    final availableTypes = _serviceTypes.where((t) => !usedTypes.contains(t['value']) || t['value'] == entry.type).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.type,
                    decoration: _deco('Hizmet Turu').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: availableTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                    onChanged: (v) => setState(() => entry.type = v ?? entry.type),
                  ),
                ),
                const SizedBox(width: 8),
                if (_services.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => _services.removeAt(index)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.hourCtrl,
                    decoration: _deco('Saat Fiyati (TL)').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.dayCtrl,
                    decoration: _deco('Gun Fiyati (TL)').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}

class _ServiceEntry {
  String type;
  final TextEditingController hourCtrl;
  final TextEditingController dayCtrl;

  _ServiceEntry({required this.type, TextEditingController? hourCtrl, TextEditingController? dayCtrl})
      : hourCtrl = hourCtrl ?? TextEditingController(),
        dayCtrl = dayCtrl ?? TextEditingController();
}
