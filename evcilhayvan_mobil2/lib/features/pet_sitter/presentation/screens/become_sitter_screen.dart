import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
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

  // Services
  final List<_ServiceEntry> _services = [];

  List<Map<String, String>> _getServiceTypes(AppLocalizations l10n) => [
    {'value': 'walking', 'label': l10n.sitterServiceWalkingLabel},
    {'value': 'home_sitting', 'label': l10n.sitterServiceHomeSittingLabel},
    {'value': 'boarding', 'label': l10n.sitterServiceBoardingLabel},
    {'value': 'daycare', 'label': l10n.sitterServiceDaycareLabel},
    {'value': 'grooming', 'label': l10n.sitterServiceGroomingLabel},
  ];

  List<Map<String, String>> _getSpeciesOptions(AppLocalizations l10n) => [
    {'value': 'dog', 'label': l10n.sitterSpeciesDog},
    {'value': 'cat', 'label': l10n.sitterSpeciesCat},
    {'value': 'bird', 'label': l10n.sitterSpeciesBird},
    {'value': 'rabbit', 'label': l10n.sitterSpeciesRabbit},
    {'value': 'other', 'label': l10n.sitterSpeciesOther},
  ];

  // Species served
  final Set<String> _speciesServed = {'dog'};

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
        _services.add(
          _ServiceEntry(
            type: s.type,
            hourCtrl: TextEditingController(
              text: s.pricePerHour > 0 ? s.pricePerHour.toInt().toString() : '',
            ),
            dayCtrl: TextEditingController(
              text: s.pricePerDay > 0 ? s.pricePerDay.toInt().toString() : '',
            ),
          ),
        );
      }
    }
    if (_services.isEmpty) {
      _services.add(_ServiceEntry(type: 'walking'));
    }
    if (_lat == null) _getLocation();
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
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sitterLocationPermRequired)),
          );
        }
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() => _locationLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sitterLocationErr(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file != null) setState(() => _avatarFile = file);
  }

  bool get _hasServices => _services.any(
    (s) =>
        double.tryParse(s.hourCtrl.text.trim()) != null ||
        double.tryParse(s.dayCtrl.text.trim()) != null,
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_speciesServed.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sitterSpeciesRequired)));
      return;
    }

    setState(() => _loading = true);
    try {
      final servicesData = _services
          .where((s) {
            final h = double.tryParse(s.hourCtrl.text.trim()) ?? 0;
            final d = double.tryParse(s.dayCtrl.text.trim()) ?? 0;
            return h > 0 || d > 0;
          })
          .map(
            (s) => {
              'type': s.type,
              'pricePerHour': double.tryParse(s.hourCtrl.text.trim()) ?? 0,
              'pricePerDay': double.tryParse(s.dayCtrl.text.trim()) ?? 0,
            },
          )
          .toList();

      final data = <String, dynamic>{
        'displayName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'experience': _expCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'speciesServed': _speciesServed.toList(),
        'services': servicesData,
        if (_lat != null && _lng != null)
          'location': {
            'type': 'Point',
            'coordinates': [_lng, _lat],
          },
      };

      final repo = ref.read(petSitterRepositoryProvider);
      PetSitterModel saved;
      if (widget.existing != null) {
        saved = await repo.updateSitter(widget.existing!.id, data);
      } else {
        saved = await repo.createSitter(data);
      }

      if (_avatarFile != null) {
        saved = await repo.uploadSitterAvatar(
          saved.id,
          File(_avatarFile!.path),
        );
        _existingAvatar = saved.avatar;
      }

      ref.invalidate(mySitterProfileProvider);
      ref.invalidate(sitterListProvider);
      if (widget.existing != null) {
        ref.invalidate(sitterDetailProvider(widget.existing!.id));
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing != null
                  ? l10n.sitterProfileUpdated
                  : l10n.sitterProfileCreated,
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sitterSubmitErr(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final serviceTypes = _getServiceTypes(l10n);
    final speciesOptions = _getSpeciesOptions(l10n);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.sitterEditProfile : l10n.sitterBecomeSitterBtn,
        ),
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
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFD8F3DC),
                        backgroundImage: _avatarFile != null
                            ? FileImage(File(_avatarFile!.path))
                                  as ImageProvider
                            : (_existingAvatar != null &&
                                  _existingAvatar!.isNotEmpty)
                            ? NetworkImage('$apiBaseUrl$_existingAvatar')
                            : null,
                        child:
                            (_avatarFile == null &&
                                (_existingAvatar == null ||
                                    _existingAvatar!.isEmpty))
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF2D6A4F),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D6A4F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              Text(
                l10n.sitterBasicInfo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: _deco(l10n.sitterDisplayName),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.sitterDisplayNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                decoration: _deco(l10n.sitterBio),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expCtrl,
                decoration: _deco(l10n.sitterExperience),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Location
              Text(
                l10n.sitterLocation,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _locationLoading ? null : _getLocation,
                icon: _locationLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _lat != null
                      ? l10n.sitterLocationObtained
                      : l10n.sitterUseLocation,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lat != null
                      ? const Color(0xFF2D6A4F)
                      : null,
                  foregroundColor: _lat != null
                      ? Colors.white
                      : const Color(0xFF2D6A4F),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: _deco(l10n.sitterAddress),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Species
              Text(
                l10n.sitterSpeciesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: speciesOptions.map((opt) {
                  final selected = _speciesServed.contains(opt['value']);
                  return FilterChip(
                    label: Text(opt['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      if (selected)
                        _speciesServed.remove(opt['value']);
                      else
                        _speciesServed.add(opt['value']!);
                    }),
                    selectedColor: const Color(0xFF2D6A4F),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Services
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sitterServicesTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final usedTypes = _services.map((s) => s.type).toSet();
                      final available = serviceTypes
                          .where((t) => !usedTypes.contains(t['value']))
                          .toList();
                      if (available.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.sitterServicesAllAdded)),
                        );
                        return;
                      }
                      setState(
                        () => _services.add(
                          _ServiceEntry(type: available.first['value']!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.sitterServicesAdd),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._services.asMap().entries.map(
                (entry) => _buildServiceRow(
                  entry.key,
                  entry.value,
                  theme,
                  l10n,
                  serviceTypes,
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? l10n.sitterUpdateBtn : l10n.sitterCreateBtn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceRow(
    int index,
    _ServiceEntry entry,
    ThemeData theme,
    AppLocalizations l10n,
    List<Map<String, String>> serviceTypes,
  ) {
    final usedTypes = _services
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value.type)
        .toSet();
    final availableTypes = serviceTypes
        .where(
          (t) => !usedTypes.contains(t['value']) || t['value'] == entry.type,
        )
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                    decoration: _deco(l10n.sitterServiceType).copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: availableTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => entry.type = v ?? entry.type),
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
                    decoration: _deco(l10n.sitterHourlyPrice).copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.dayCtrl,
                    decoration: _deco(l10n.sitterDailyPrice).copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
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
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

class _ServiceEntry {
  String type;
  final TextEditingController hourCtrl;
  final TextEditingController dayCtrl;

  _ServiceEntry({
    required this.type,
    TextEditingController? hourCtrl,
    TextEditingController? dayCtrl,
  }) : hourCtrl = hourCtrl ?? TextEditingController(),
       dayCtrl = dayCtrl ?? TextEditingController();
}
