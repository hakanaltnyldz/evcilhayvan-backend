// lib/features/pets/presentation/screens/create_pet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/data/pet_breeds.dart';

import '../../data/repositories/pets_repository.dart';
import '../../domain/models/pet_model.dart';
import 'location_picker_screen.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  final Pet? petToEdit;
  final String? initialAdvertType;
  final String? initialSpecies;
  const CreatePetScreen({
    super.key,
    this.petToEdit,
    this.initialAdvertType,
    this.initialSpecies,
  });

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _bioController;
  LocationPickerResult? _selectedLocation;

  String _selectedSpecies = 'cat';
  String? _selectedBreed;
  String _selectedGender = 'unknown';
  bool _isVaccinated = false;
  String _advertType = 'adoption';

  List<String> _imageUrls = [];
  List<String> _videoUrls = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditMode => widget.petToEdit != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.petToEdit;
    if (pet != null) {
      _nameController = TextEditingController(text: pet.name);
      _ageController = TextEditingController(text: pet.ageMonths.toString());
      _bioController = TextEditingController(text: pet.bio);
      _selectedSpecies = pet.species;
      _selectedBreed = pet.breed.isNotEmpty ? pet.breed : null;
      _selectedGender = pet.gender;
      _isVaccinated = pet.vaccinated;
      _advertType = pet.advertType.isNotEmpty ? pet.advertType : 'adoption';
      _imageUrls = [...pet.images];
      _videoUrls = [...pet.videos];
      if (pet.latitude != null && pet.longitude != null) {
        _selectedLocation = LocationPickerResult(
          latLng: LatLng(pet.latitude!, pet.longitude!),
        );
      }
    } else {
      _nameController = TextEditingController();
      _ageController = TextEditingController();
      _bioController = TextEditingController();
      _selectedLocation = null;
      _advertType = widget.initialAdvertType ?? 'adoption';
      if (widget.initialSpecies != null && widget.initialSpecies!.isNotEmpty) {
        _selectedSpecies = widget.initialSpecies!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;
      setState(() => _isLoading = true);
      final repo = ref.read(petsRepositoryProvider);
      for (final file in files) {
        final url = await repo.uploadImageFile(file);
        _imageUrls.add(url);
      }
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (file == null) return;
      setState(() => _isLoading = true);
      final repo = ref.read(petsRepositoryProvider);
      final url = await repo.uploadVideoFile(file);
      _videoUrls.add(url);
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(petsRepositoryProvider);

      final age = int.parse(_ageController.text);
      final breed = _selectedBreed ?? '';
      final bio = _bioController.text.isNotEmpty ? _bioController.text : null;

      Map<String, dynamic>? locationData;
      if (_selectedLocation != null) {
        final lat = _selectedLocation!.latLng.latitude;
        final lon = _selectedLocation!.latLng.longitude;
        locationData = {
          'type': 'Point',
          'coordinates': [lon, lat],
          if (_selectedLocation!.address != null) 'address': _selectedLocation!.address,
          if (_selectedLocation!.note != null) 'note': _selectedLocation!.note,
        };
      }

      final savedPet = _isEditMode
          ? await repo.updatePet(
              widget.petToEdit!.id,
              name: _nameController.text,
              species: _selectedSpecies,
              breed: breed,
              gender: _selectedGender,
              ageMonths: age,
              bio: bio,
              vaccinated: _isVaccinated,
              location: locationData,
              advertType: _advertType,
              images: _imageUrls,
              videos: _videoUrls,
            )
          : await repo.createPet(
              name: _nameController.text,
              species: _selectedSpecies,
              breed: breed,
              gender: _selectedGender,
              ageMonths: age,
              bio: bio,
              vaccinated: _isVaccinated,
              location: locationData,
              advertType: _advertType,
              images: _imageUrls,
              videos: _videoUrls,
            );

      if (mounted) context.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(myPetsProvider);
        ref.invalidate(myAdvertsProvider('adoption'));
        ref.invalidate(myAdvertsProvider('mating'));
        // Ana sayfadaki ilan listelerini de güncelle
        ref.invalidate(adoptionAdvertsProvider);
        ref.invalidate(matingAdvertsProvider);
        ref.invalidate(allPetsProvider);
        ref.read(petFeedProvider.notifier).optimisticAdd(savedPet);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: _selectedLocation?.latLng,
          initialAddress: _selectedLocation?.address,
          initialNote: _selectedLocation?.note,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        if (_errorMessage != null && _errorMessage!.toLowerCase().contains('konum')) {
          _errorMessage = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final speciesOptions = <Map<String, String>>[
      {'label': l10n.speciesCat, 'value': 'cat'},
      {'label': l10n.speciesDog, 'value': 'dog'},
      {'label': l10n.speciesBird, 'value': 'bird'},
      {'label': l10n.speciesFish, 'value': 'fish'},
      {'label': l10n.vetSpeciesRodent, 'value': 'rodent'},
      {'label': l10n.speciesOther, 'value': 'other'},
    ];
    final genderOptions = <Map<String, String>>[
      {'label': l10n.genderMale, 'value': 'male'},
      {'label': l10n.genderFemale, 'value': 'female'},
      {'label': l10n.genderUnknown, 'value': 'unknown'},
    ];

    InputDecoration inputDecoration({
      required String label,
      IconData? icon,
      String? hint,
      int lines = 1,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: lines > 1 ? 18 : 0,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.createPetEditTitle : l10n.createPetNewTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ModernBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: AppPalette.heroGradient.map((c) => c.withOpacity(0.9)).toList(),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? l10n.createPetUpdateDesc : l10n.createPetNewDesc,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createPetHeroDesc,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.createPetAdoptionChip),
                              selected: _advertType == 'adoption',
                              onSelected: (v) => setState(() => _advertType = 'adoption'),
                              selectedColor: Colors.green.shade200,
                            ),
                            ChoiceChip(
                              label: Text(l10n.createPetMatingChip),
                              selected: _advertType == 'mating',
                              onSelected: (v) => setState(() => _advertType = 'mating'),
                              selectedColor: Colors.purple.shade200,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.createPetBasicInfo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: inputDecoration(
                            label: l10n.createPetNameLabel,
                            icon: Icons.pets_outlined,
                          ),
                          validator: (value) => (value?.isEmpty ?? true) ? l10n.createPetNameError : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.createPetSpeciesLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: speciesOptions.map((option) {
                            return ChoiceChip(
                              label: Text(option['label']!),
                              selected: _selectedSpecies == option['value'],
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSpecies = option['value']!;
                                    _selectedBreed = null; // reset breed on species change
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.createPetGenderLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: genderOptions.map((option) {
                            return ChoiceChip(
                              label: Text(option['label']!),
                              selected: _selectedGender == option['value'],
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedGender = option['value']!);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          value: _isVaccinated,
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.vaccines),
                          title: Text(l10n.createPetVaccinatedTitle),
                          subtitle: Text(l10n.createPetVaccinatedSubtitle),
                          onChanged: (value) {
                            setState(() => _isVaccinated = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.createPetDetailsSection,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          decoration: inputDecoration(
                            label: l10n.createPetAgeLabel,
                            icon: Icons.cake_outlined,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.createPetAgeError;
                            final parsed = int.tryParse(value);
                            if (parsed == null || parsed < 0) return l10n.createPetAgeInvalidError;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Cins seçici
                        GestureDetector(
                          onTap: () async {
                            final breeds = breedsFor(_selectedSpecies);
                            final picked = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (_) => _BreedPickerSheet(
                                breeds: breeds,
                                selected: _selectedBreed,
                              ),
                            );
                            if (picked != null) setState(() => _selectedBreed = picked);
                          },
                          child: InputDecorator(
                            decoration: inputDecoration(
                              label: l10n.createPetBreedLabel,
                              icon: Icons.pets_rounded,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedBreed ?? l10n.createPetBreedSelect,
                                  style: TextStyle(
                                    color: _selectedBreed != null
                                        ? theme.textTheme.bodyLarge?.color
                                        : theme.hintColor,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: theme.hintColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: inputDecoration(
                            label: l10n.createPetDescLabel,
                            hint: l10n.createPetDescHint,
                            icon: Icons.notes_outlined,
                            lines: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickLocation,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedLocation != null
                                    ? AppPalette.primary
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedLocation != null
                                  ? AppPalette.primary.withOpacity(0.06)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedLocation != null
                                      ? Icons.location_on
                                      : Icons.add_location_alt_outlined,
                                  color: _selectedLocation != null
                                      ? AppPalette.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedLocation != null ? l10n.createPetLocationSelected : l10n.createPetLocationAdd,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _selectedLocation != null
                                              ? AppPalette.primary
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      if (_selectedLocation?.address != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            _selectedLocation!.address!,
                                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      else
                                        Text(
                                          l10n.createPetLocationHint,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      if (_selectedLocation?.note != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '📝 ${_selectedLocation!.note!}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.createPetMedia,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _pickImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(l10n.createPetAddPhotoBtn),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _pickVideo,
                              icon: const Icon(Icons.videocam_outlined),
                              label: Text(l10n.createPetAddVideoBtn),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ..._imageUrls.map((url) => _MediaChip(
                                  url: url,
                                  type: 'image',
                                  onRemove: () {
                                    setState(() => _imageUrls.remove(url));
                                  },
                                )),
                            ..._videoUrls.map((url) => _MediaChip(
                                  url: url,
                                  type: 'video',
                                  onRemove: () {
                                    setState(() => _videoUrls.remove(url));
                                  },
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isEditMode ? l10n.createPetSave : l10n.createPetPublish),
                      onPressed: _isLoading ? null : _savePet,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Breed Picker Bottom Sheet ────────────────────────────────────────────────

class _BreedPickerSheet extends StatefulWidget {
  final List<String> breeds;
  final String? selected;

  const _BreedPickerSheet({required this.breeds, this.selected});

  @override
  State<_BreedPickerSheet> createState() => _BreedPickerSheetState();
}

class _BreedPickerSheetState extends State<_BreedPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.breeds;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.breeds
          : widget.breeds.where((b) => b.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.createPetBreedSearch,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final breed = _filtered[i];
                  final isSelected = breed == widget.selected;
                  return ListTile(
                    title: Text(breed),
                    trailing: isSelected ? const Icon(Icons.check, color: AppPalette.primary) : null,
                    selected: isSelected,
                    onTap: () => Navigator.of(context).pop(breed),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MediaChip extends StatelessWidget {
  final String url;
  final String type;
  final VoidCallback onRemove;

  const _MediaChip({
    required this.url,
    required this.type,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = type == 'image';
    return Chip(
      avatar: Icon(isImage ? Icons.image : Icons.videocam, size: 18),
      label: SizedBox(
        width: 140,
        child: Text(
          url.split('/').last,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      deleteIcon: const Icon(Icons.close),
      onDeleted: onRemove,
      backgroundColor: isImage ? Colors.green.shade50 : Colors.purple.shade50,
    );
  }
}
