// lib/features/store/presentation/screens/add_address_screen.dart

import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import '../../domain/models/address_model.dart';
import '../../providers/address_providers.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? address; // Düzenleme için

  const AddAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _streetController;
  late final TextEditingController _buildingNoController;
  late final TextEditingController _floorController;
  late final TextEditingController _apartmentNoController;
  late final TextEditingController _postalCodeController;
  bool _isDefault = false;
  bool _isLoading = false;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _titleController = TextEditingController(text: a?.title ?? '');
    _fullNameController = TextEditingController(text: a?.fullName ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _districtController = TextEditingController(text: a?.district ?? '');
    _neighborhoodController = TextEditingController(text: a?.neighborhood ?? '');
    _streetController = TextEditingController(text: a?.street ?? '');
    _buildingNoController = TextEditingController(text: a?.buildingNo ?? '');
    _floorController = TextEditingController(text: a?.floor ?? '');
    _apartmentNoController = TextEditingController(text: a?.apartmentNo ?? '');
    _postalCodeController = TextEditingController(text: a?.postalCode ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _neighborhoodController.dispose();
    _streetController.dispose();
    _buildingNoController.dispose();
    _floorController.dispose();
    _apartmentNoController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final address = AddressModel(
        id: widget.address?.id ?? '',
        title: _titleController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        neighborhood: _neighborhoodController.text.trim().isNotEmpty
            ? _neighborhoodController.text.trim()
            : null,
        street: _streetController.text.trim(),
        buildingNo: _buildingNoController.text.trim().isNotEmpty
            ? _buildingNoController.text.trim()
            : null,
        floor: _floorController.text.trim().isNotEmpty
            ? _floorController.text.trim()
            : null,
        apartmentNo: _apartmentNoController.text.trim().isNotEmpty
            ? _apartmentNoController.text.trim()
            : null,
        postalCode: _postalCodeController.text.trim().isNotEmpty
            ? _postalCodeController.text.trim()
            : null,
        isDefault: _isDefault,
        createdAt: DateTime.now(),
      );

      if (isEditing) {
        await ref.read(addressNotifierProvider.notifier).updateAddress(widget.address!.id, address);
      } else {
        await ref.read(addressNotifierProvider.notifier).addAddress(address);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? l10n.addressUpdated : l10n.addressAdded),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.addressSaveErr(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.addressEditTitle : l10n.addressNewTitle),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: l10n.addressInfoCard,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: l10n.addressTitleLabel,
                    hint: l10n.addressTitleHint,
                    icon: Icons.bookmark,
                    required: true,
                    l10n: l10n,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: l10n.addressRecipientCard,
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: l10n.addressFullName,
                    hint: l10n.addressFullNameHint,
                    icon: Icons.person,
                    required: true,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: l10n.addressPhone,
                    hint: '05XX XXX XX XX',
                    icon: Icons.phone,
                    required: true,
                    keyboardType: TextInputType.phone,
                    l10n: l10n,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: l10n.addressDetailsCard,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: l10n.addressCity,
                          hint: l10n.addressCityHint,
                          icon: Icons.location_city,
                          required: true,
                          l10n: l10n,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _districtController,
                          label: l10n.addressDistrict,
                          hint: l10n.addressDistrictHint,
                          icon: Icons.map,
                          required: true,
                          l10n: l10n,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _neighborhoodController,
                    label: l10n.addressNeighborhood,
                    hint: l10n.addressNeighborhoodHint,
                    icon: Icons.house,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _streetController,
                    label: l10n.addressStreet,
                    hint: l10n.addressStreetHint,
                    icon: Icons.streetview,
                    required: true,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _buildingNoController,
                          label: l10n.addressBuildingNo,
                          hint: '12',
                          icon: Icons.home,
                          l10n: l10n,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _floorController,
                          label: l10n.addressFloor,
                          hint: '3',
                          icon: Icons.stairs,
                          l10n: l10n,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _apartmentNoController,
                          label: l10n.addressApartmentNo,
                          hint: '5',
                          icon: Icons.door_front_door,
                          l10n: l10n,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _postalCodeController,
                    label: l10n.addressPostalCode,
                    hint: '34000',
                    icon: Icons.local_post_office,
                    keyboardType: TextInputType.number,
                    l10n: l10n,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: l10n.addressPreferencesCard,
                children: [
                  SwitchListTile(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    title: Text(l10n.addressSetDefault),
                    subtitle: Text(l10n.addressSetDefaultSub),
                    activeColor: AppPalette.storePrimary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.storePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? l10n.addressUpdate : l10n.save,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    TextInputType? keyboardType,
    AppLocalizations? l10n,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? (l10n?.addressRequired(label) ?? '$label zorunludur') : null
          : null,
    );
  }
}