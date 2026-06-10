import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

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

  static const _speciesOptions = [
    'dog',
    'cat',
    'bird',
    'fish',
    'rodent',
    'other',
  ];

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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.vetRegisterLocationDenied),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
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
            content: Text(l10n.vetRegisterLocationError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(veterinaryRepositoryProvider);
      final vet = await repo.registerVet(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        lat: _lat,
        lng: _lng,
        speciesServed: _selectedSpecies.isEmpty
            ? null
            : _selectedSpecies.toList(),
      );

      final user = ref.read(authProvider);
      await repo.claimVetProfile(
        vet.id,
        claimData: {
          'fullName': user?.name ?? _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? '-'
              : _phoneController.text.trim(),
          'role': l10n.vetRegisterClaimOwnerRole,
          'note': l10n.vetRegisterAutoClaimNote,
        },
      );

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.vetRegisterSubmittedTitle),
            content: Text(l10n.vetRegisterSubmittedContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.ok),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pushNamed('vet-claim-status');
                },
                child: Text(l10n.vetHomeClaimStatus),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vetRegisterError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.vetRegisterTitle),
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
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco(l10n.vetRegisterClinicName),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.vetRegisterClinicNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _inputDeco(l10n.vetRegisterAddress),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.vetRegisterAddressRequired
                    : null,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDeco(l10n.vetRegisterPhone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: _inputDeco(l10n.vetRegisterEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: _inputDeco(l10n.vetRegisterDesc),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _lat != null
                          ? l10n.vetRegisterLocationLabel(
                              _lat!.toStringAsFixed(4),
                              _lng!.toStringAsFixed(4),
                            )
                          : l10n.vetRegisterLocationNone,
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
                    label: Text(
                      _locationLoading
                          ? l10n.vetRegisterGettingLocation
                          : l10n.vetRegisterGetLocation,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.vetRegisterSpecies,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _speciesOptions.map((species) {
                  final selected = _selectedSpecies.contains(species);
                  return FilterChip(
                    label: Text(_speciesLabel(l10n, species)),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedSpecies.add(species);
                        } else {
                          _selectedSpecies.remove(species);
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
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                    : Text(l10n.vetRegisterSaveBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _speciesLabel(AppLocalizations l10n, String species) =>
      switch (species) {
        'dog' => l10n.aiSpeciesDog,
        'cat' => l10n.aiSpeciesCat,
        'bird' => l10n.aiSpeciesBird,
        'fish' => l10n.clinicPanelSpeciesFish,
        'rodent' => l10n.clinicPanelSpeciesRodent,
        _ => l10n.aiSpeciesOther,
      };

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
