// lib/features/store/presentation/screens/add_address_screen.dart

import 'package:flutter/material.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Adres güncellendi' : 'Adres eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isEditing ? 'Adresi Düzenle' : 'Yeni Adres'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                title: 'Adres Bilgileri',
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Adres Başlığı',
                    hint: 'Ev, İş, vb.',
                    icon: Icons.bookmark,
                    required: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Alıcı Bilgileri',
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Ad Soyad',
                    hint: 'Teslimat alacak kişi',
                    icon: Icons.person,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefon',
                    hint: '05XX XXX XX XX',
                    icon: Icons.phone,
                    required: true,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Adres Detayları',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'İl',
                          hint: 'İstanbul',
                          icon: Icons.location_city,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _districtController,
                          label: 'İlçe',
                          hint: 'Kadıköy',
                          icon: Icons.map,
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _neighborhoodController,
                    label: 'Mahalle',
                    hint: 'Mahalle adı',
                    icon: Icons.house,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _streetController,
                    label: 'Sokak/Cadde',
                    hint: 'Sokak veya cadde adı',
                    icon: Icons.streetview,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _buildingNoController,
                          label: 'Bina No',
                          hint: '12',
                          icon: Icons.home,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _floorController,
                          label: 'Kat',
                          hint: '3',
                          icon: Icons.stairs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _apartmentNoController,
                          label: 'Daire',
                          hint: '5',
                          icon: Icons.door_front_door,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _postalCodeController,
                    label: 'Posta Kodu',
                    hint: '34000',
                    icon: Icons.local_post_office,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Tercihler',
                children: [
                  SwitchListTile(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    title: const Text('Varsayılan adres olarak ayarla'),
                    subtitle: const Text('Siparişlerde bu adres otomatik seçilir'),
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
                          isEditing ? 'Güncelle' : 'Kaydet',
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
          ? (v) => (v == null || v.trim().isEmpty) ? '$label zorunludur' : null
          : null,
    );
  }
}