// lib/features/pets/presentation/screens/create_pet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';

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
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _bioController;
  LatLng? _selectedLocation;

  String _selectedSpecies = 'cat';
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
      _breedController = TextEditingController(text: pet.breed);
      _ageController = TextEditingController(text: pet.ageMonths.toString());
      _bioController = TextEditingController(text: pet.bio);
      _selectedSpecies = pet.species;
      _selectedGender = pet.gender;
      _isVaccinated = pet.vaccinated;
      _advertType = pet.advertType.isNotEmpty ? pet.advertType : 'adoption';
      _imageUrls = [...pet.images];
      _videoUrls = [...pet.videos];
      if (pet.latitude != null && pet.longitude != null) {
        _selectedLocation = LatLng(pet.latitude!, pet.longitude!);
      }
    } else {
      _nameController = TextEditingController();
      _breedController = TextEditingController();
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
    _breedController.dispose();
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
      final breed = _breedController.text;
      final bio = _bioController.text.isNotEmpty ? _bioController.text : null;

      Map<String, dynamic>? locationData;
      if (_selectedLocation != null) {
        final lat = _selectedLocation!.latitude;
        final lon = _selectedLocation!.longitude;
        locationData = {
          'type': 'Point',
          'coordinates': [lon, lat],
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
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: _selectedLocation,
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
    const speciesOptions = <Map<String, String>>[
      {'label': 'Kedi', 'value': 'cat'},
      {'label': 'Köpek', 'value': 'dog'},
      {'label': 'Kuş', 'value': 'bird'},
      {'label': 'Diğer', 'value': 'other'},
    ];
    const genderOptions = <Map<String, String>>[
      {'label': 'Erkek', 'value': 'male'},
      {'label': 'Dişi', 'value': 'female'},
      {'label': 'Bilinmiyor', 'value': 'unknown'},
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
        title: Text(_isEditMode ? 'İlanı Düzenle' : 'Yeni İlan'),
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
                          _isEditMode ? 'İlan bilgilerini güncelle' : 'Yeni ilan oluştur',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlan tipini seç, fotoğraf/video ekle ve patili dostuna uygun evi bul.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Sahiplendirme ilanı'),
                              selected: _advertType == 'adoption',
                              onSelected: (v) => setState(() => _advertType = 'adoption'),
                              selectedColor: Colors.green.shade200,
                            ),
                            ChoiceChip(
                              label: const Text('Eşleştirme ilanı'),
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
                          'Temel Bilgiler',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: inputDecoration(
                            label: 'İsim',
                            icon: Icons.pets_outlined,
                          ),
                          validator: (value) => (value?.isEmpty ?? true) ? 'İsim zorunludur' : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tür',
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
                                  setState(() => _selectedSpecies = option['value']!);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cinsiyet',
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
                          title: const Text('Aşıları tam'),
                          subtitle: const Text('Aşı bilgileri ilanda rozet olarak gösterilir.'),
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
                          'Detaylar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          decoration: inputDecoration(
                            label: 'Yaş (Ay)',
                            icon: Icons.cake_outlined,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Yaş zorunlu';
                            final parsed = int.tryParse(value);
                            if (parsed == null || parsed < 0) return 'Geçerli bir sayı girin';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _breedController,
                          decoration: inputDecoration(
                            label: 'Cins',
                            icon: Icons.pets_rounded,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: inputDecoration(
                            label: 'Açıklama',
                            hint: 'Karakteri, sağlık durumu ve ihtiyaçları',
                            icon: Icons.notes_outlined,
                            lines: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.map_outlined),
                          title: Text(_selectedLocation != null
                              ? 'Konum seçildi'
                              : 'Konum ekle'),
                          subtitle: const Text('İl/ilçe seçimi için haritayı aç'),
                          trailing: FilledButton(
                            onPressed: _pickLocation,
                            child: const Text('Haritayı aç'),
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
                          'Fotoğraf & Video',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _pickImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Fotoğraf ekle'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _pickVideo,
                              icon: const Icon(Icons.videocam_outlined),
                              label: const Text('Video ekle'),
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
                      label: Text(_isEditMode ? 'Kaydet' : 'Yayınla'),
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
