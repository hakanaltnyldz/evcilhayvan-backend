import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import '../../data/repositories/veterinary_repository.dart';

class VetRegisterScreen extends ConsumerStatefulWidget {
  const VetRegisterScreen({super.key});

  @override
  ConsumerState<VetRegisterScreen> createState() => _VetRegisterScreenState();
}

class _VetRegisterScreenState extends ConsumerState<VetRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _loading = false;
  bool _locationLoading = false;
  final Set<String> _selectedSpecies = {};

  static const _speciesOptions = {
    'dog': 'Kopek',
    'cat': 'Kedi',
    'bird': 'Kus',
    'fish': 'Balik',
    'rodent': 'Kemirgen',
    'other': 'Diger',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni reddedildi. Ayarlardan izin verin.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alinamadi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      final vet = await repo.registerVet(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        lat: _lat,
        lng: _lng,
        speciesServed: _selectedSpecies.isEmpty ? null : _selectedSpecies.toList(),
      );
      // Klinigi olusturan kisi otomatik olarak sahipleniyor
      await repo.claimVetProfile(vet.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klinik kaydedildi ve hesabınıza bağlandı!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Klinik Kaydet'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco('Klinik Adi *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Klinik adi gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _inputDeco('Adres *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Adres gerekli' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneController, decoration: _inputDeco('Telefon'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: _emailController, decoration: _inputDeco('E-posta'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: _descController, decoration: _inputDeco('Aciklama'), maxLines: 3),
              const SizedBox(height: 16),

              // Location
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _lat != null ? 'Konum: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}' : 'Konum eklenmedi',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _locationLoading ? null : _getLocation,
                    icon: _locationLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_locationLoading ? 'Aliniyor...' : 'Konum Al'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Species
              Text('Hizmet Verilen Turler', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _speciesOptions.entries.map((e) {
                  final selected = _selectedSpecies.contains(e.key);
                  return FilterChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedSpecies.add(e.key);
                        } else {
                          _selectedSpecies.remove(e.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
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

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
