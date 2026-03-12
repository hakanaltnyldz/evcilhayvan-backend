import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/category_model.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.product});

  final ProductModel? product;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedCategoryId;
  bool _isActive = true;
  bool _loading = false;
  String? _error;

  // Image picker için
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  static const int _maxImages = 5;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _titleController.text = product.title;
      _descController.text = product.description ?? '';
      _priceController.text = product.price.toStringAsFixed(2);
      _stockController.text = product.stock.toString();
      _selectedCategoryId = product.categoryId;
      _isActive = product.isActive;
    }
  }

  // Galeriden resim seç
  Future<void> _pickFromGallery() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesWarning();
      return;
    }
    final remaining = _maxImages - _selectedImages.length;
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked.take(remaining));
      });
    }
  }

  // Kameradan resim çek
  Future<void> _pickFromCamera() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesWarning();
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked != null) {
      setState(() {
        _selectedImages.add(picked);
      });
    }
  }

  void _showMaxImagesWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('En fazla $_maxImages fotoğraf ekleyebilirsiniz'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fotoğraf Ekle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.storePrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppPalette.storePrimary),
                ),
                title: const Text('Galeriden Seç'),
                subtitle: const Text('Mevcut fotoğraflarınızdan seçin'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.storeSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppPalette.storeSecondary),
                ),
                title: const Text('Kamerayı Aç'),
                subtitle: const Text('Yeni fotoğraf çekin'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() {
        _error = 'Kategori seçin';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(storeRepositoryProvider);
      final stock = int.tryParse(_stockController.text.trim());

      final title = _titleController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final description = _descController.text.trim().isNotEmpty ? _descController.text.trim() : null;

      if (_isEditMode) {
        // Edit modda mevcut ürünü güncelle
        await repo.updateProduct(
          widget.product!.id,
          data: {
            'name': title,
            'title': title,
            'price': price,
            'description': description,
            'stock': stock ?? 0,
            'category': _selectedCategoryId,
            'isActive': _isActive,
          },
        );
        // Yeni resimler varsa yükle
        if (_selectedImages.isNotEmpty) {
          await repo.uploadProductImages(widget.product!.id, _selectedImages);
        }
      } else {
        // Yeni ürün ekle (resimlerle birlikte)
        await repo.addProductWithImages(
          name: title,
          price: price,
          description: description,
          images: _selectedImages.isNotEmpty ? _selectedImages : null,
          stock: stock,
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Ürün güncellendi!' : 'Ürün eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(myProductsProvider);
        await ref.read(storeFeedProvider.notifier).refresh();
        Navigator.of(context).pop(true);
      }
    } catch (err) {
      final message = _formatErrorMessage(err);
      if (mounted) {
        setState(() {
          _error = message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatErrorMessage(Object error) {
    if (error is DioException) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message'] as String?)
          : error.response?.data?.toString();
      final code = error.response?.statusCode;
      if (message != null && message.isNotEmpty) {
        return _isEditMode ? 'Urun guncellenemedi: $message' : 'Urun eklenemedi: $message';
      }
      if (code != null) {
        return _isEditMode ? 'Urun guncellenemedi (HTTP $code)' : 'Urun eklenemedi (HTTP $code)';
      }
    }
    return _isEditMode
        ? 'Urun guncellenemedi, lutfen tekrar deneyin.'
        : 'Urun eklenemedi, lutfen tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Ürün Düzenle' : 'Ürün Ekle'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppPalette.storeWarmGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ModernBackground(
        colors: AppPalette.storeBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Fotoğraf Ekleme Bölümü
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.storePrimary.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppPalette.storeWarmGradient,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Ürün Fotoğrafları',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_selectedImages.length}/$_maxImages',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Fotoğraf ekle butonu
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppPalette.storePrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppPalette.storePrimary.withOpacity(0.3),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        color: AppPalette.storePrimary,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ekle',
                                        style: TextStyle(
                                          color: AppPalette.storePrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Seçilen fotoğraflar
                              ..._selectedImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final image = entry.value;
                                return Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        image: DecorationImage(
                                          image: FileImage(File(image.path)),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        if (_selectedImages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Ürününüzün fotoğraflarını ekleyin (max $_maxImages)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ürün Bilgileri Bölümü
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.storePrimary.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _LabeledField(
                          controller: _titleController,
                          label: 'Ürün Başlığı',
                          hint: 'Örn: Renkli kedi oyuncağı',
                          icon: Icons.label_outline,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Başlık gerekli' : null,
                        ),
                        const SizedBox(height: 12),
                        categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const _ErrorChip(message: 'Kategori bulunamadı.');
                            }
                            return DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                prefixIcon: const Icon(Icons.category_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              isExpanded: true,
                              items: categories
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category.id,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: category.colorValue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              category.iconData,
                                              color: category.colorValue,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              category.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedCategoryId = value),
                              validator: (_) =>
                                  _selectedCategoryId == null ? 'Kategori seçin' : null,
                            );
                          },
                          loading: () => const _FieldSkeleton(label: 'Kategori'),
                          error: (e, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _ErrorChip(message: 'Kategoriler yüklenemedi.'),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () => ref.invalidate(categoriesProvider),
                                child: const Text('Yeniden dene'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LabeledField(
                          controller: _descController,
                          label: 'Açıklama',
                          hint: 'Ürün özellikleri, boyut, malzeme...',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LabeledField(
                                controller: _priceController,
                                label: 'Fiyat (₺)',
                                hint: '249.90',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Gerekli';
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) return 'Geçersiz';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledField(
                                controller: _stockController,
                                label: 'Stok',
                                hint: '15',
                                icon: Icons.inventory_2_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_isEditMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile.adaptive(
                              value: _isActive,
                              title: Text(
                                _isActive ? 'Ürün Aktif' : 'Ürün Pasif',
                                style: TextStyle(
                                  color: _isActive ? Colors.green[700] : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onChanged: (value) => setState(() => _isActive = value),
                              contentPadding: EdgeInsets.zero,
                              activeColor: Colors.green,
                            ),
                          ),
                        if (_isEditMode) const SizedBox(height: 12),
                        if (_error != null) _ErrorChip(message: _error!),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppPalette.storeWarmGradient,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.save_alt_outlined),
                              label: Text(_loading ? 'Kaydediliyor...' : 'Kaydet'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.storePrimary.withOpacity(0.18)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        '$label yükleniyor...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
