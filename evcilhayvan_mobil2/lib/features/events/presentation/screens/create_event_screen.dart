import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/event_repository.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _maxAttendeesCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  String _category = 'park_meetup';
  bool _isFree = true;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7, hours: 2));

  final Set<String> _speciesAllowed = {'all'};
  final List<XFile> _photos = [];
  double? _lat;
  double? _lng;
  bool _locationLoading = false;
  bool _loading = false;

  List<Map<String, String>> _getCategories(AppLocalizations l10n) => [
    {'value': 'park_meetup', 'label': l10n.eventCatParkMeetup},
    {'value': 'adoption_day', 'label': l10n.eventCatAdoptionDay},
    {'value': 'training', 'label': l10n.eventCatTraining},
    {'value': 'competition', 'label': l10n.eventCatCompetition},
    {'value': 'grooming', 'label': l10n.eventCatGrooming},
    {'value': 'health', 'label': l10n.eventCatHealth},
    {'value': 'other', 'label': l10n.eventCatOther},
  ];

  List<Map<String, String>> _getSpeciesOptions(AppLocalizations l10n) => [
    {'value': 'all', 'label': l10n.eventSpeciesAll},
    {'value': 'dog', 'label': l10n.eventSpeciesDog},
    {'value': 'cat', 'label': l10n.eventSpeciesCat},
    {'value': 'bird', 'label': l10n.eventSpeciesBird},
    {'value': 'rabbit', 'label': l10n.eventSpeciesRabbit},
    {'value': 'other', 'label': l10n.eventSpeciesOther},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _maxAttendeesCtrl.dispose();
    _linkCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;

    final dt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = dt;
        if (_endDate.isBefore(_startDate.add(const Duration(minutes: 30)))) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      } else {
        _endDate = dt;
      }
    });
  }

  Future<void> _getLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.eventErrLocationPerm)));
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _locationLoading = false; });
    } catch (e) {
      setState(() => _locationLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.eventErrLocationFail(e.toString()))));
    }
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.eventErrMaxPhotos)));
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
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.eventErrEndBeforeStart)));
      return;
    }

    setState(() => _loading = true);
    try {
      final photoUrls = await _uploadPhotos();

      final species = _speciesAllowed.contains('all') ? ['all'] : _speciesAllowed.toList();
      final tags = _tagsCtrl.text.trim().isEmpty
          ? <String>[]
          : _tagsCtrl.text.trim().split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'isFree': _isFree,
        'speciesAllowed': species,
        'tags': tags,
        'photos': photoUrls,
      };

      if (!_isFree) {
        data['price'] = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      }
      if (_venueCtrl.text.trim().isNotEmpty) data['venueName'] = _venueCtrl.text.trim();
      if (_addressCtrl.text.trim().isNotEmpty) data['address'] = _addressCtrl.text.trim();
      if (_maxAttendeesCtrl.text.trim().isNotEmpty) {
        data['maxAttendees'] = int.tryParse(_maxAttendeesCtrl.text.trim());
      }
      if (_linkCtrl.text.trim().isNotEmpty) data['externalLink'] = _linkCtrl.text.trim();
      if (_lat != null && _lng != null) {
        data['location'] = {'type': 'Point', 'coordinates': [_lng, _lat]};
      }

      await ref.read(eventRepositoryProvider).createEvent(data);
      ref.invalidate(myOrganizedEventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.eventCreated), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.eventCreateErr(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDt(DateTime d) => DateFormat('dd.MM.yyyy HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categories = _getCategories(l10n);
    final speciesOptions = _getSpeciesOptions(l10n);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.eventCreateTitle),
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
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: _deco('Event Title *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.error : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _deco(l10n.addProductCategoryLabel),
                items: categories.map((c) => DropdownMenuItem(value: c['value']!, child: Text(c['label']!))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: _deco(l10n.addProductDescLabel),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.error : null,
              ),
              const SizedBox(height: 24),

              // Photos
              Text(l10n.eventPhotosLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                                top: 2, right: 2,
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
                          width: 100, height: 100,
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
              const SizedBox(height: 24),

              // Dates
              Text(l10n.eventDateTimeLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _DateTile(label: l10n.eventStartLabel, value: _formatDt(_startDate), onTap: () => _pickDate(true)),
              const SizedBox(height: 8),
              _DateTile(label: l10n.eventEndLabel, value: _formatDt(_endDate), onTap: () => _pickDate(false)),
              const SizedBox(height: 24),

              // Location
              Text(l10n.eventLocationLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _locationLoading ? null : _getLocation,
                icon: _locationLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(_lat != null ? l10n.eventLocationObtained : l10n.eventUseMyLocation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lat != null ? Colors.green : null,
                  foregroundColor: _lat != null ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _venueCtrl, decoration: _deco(l10n.apptDetailVet)),
              const SizedBox(height: 8),
              TextFormField(controller: _addressCtrl, decoration: _deco(l10n.sellerApplyAddress), maxLines: 2),
              const SizedBox(height: 24),

              // Capacity & Price
              Text(l10n.eventCapacityLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxAttendeesCtrl,
                decoration: _deco('Max Attendees'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(l10n.eventFreeLabel),
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
                activeColor: const Color(0xFF2D6A4F),
                contentPadding: EdgeInsets.zero,
              ),
              if (!_isFree) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: _deco('Participation Fee (₺)'),
                  keyboardType: TextInputType.number,
                  validator: _isFree ? null : (v) => (v == null || v.trim().isEmpty) ? l10n.addProductPriceRequired : null,
                ),
              ],
              const SizedBox(height: 24),

              // Species
              Text(l10n.eventAnimalsLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: speciesOptions.map((opt) {
                  final v = opt['value']!;
                  final selected = _speciesAllowed.contains(v);
                  return FilterChip(
                    label: Text(opt['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      if (v == 'all') {
                        _speciesAllowed.clear();
                        _speciesAllowed.add('all');
                      } else {
                        _speciesAllowed.remove('all');
                        if (selected) _speciesAllowed.remove(v);
                        else _speciesAllowed.add(v);
                        if (_speciesAllowed.isEmpty) _speciesAllowed.add('all');
                      }
                    }),
                    selectedColor: const Color(0xFFD8F3DC),
                    checkmarkColor: const Color(0xFF2D6A4F),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Tags + link
              TextFormField(controller: _tagsCtrl, decoration: _deco('Tags (comma separated)')),
              const SizedBox(height: 8),
              TextFormField(controller: _linkCtrl, decoration: _deco('External Link (optional)')),
              const SizedBox(height: 32),

              // Submit
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.eventCreateBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
