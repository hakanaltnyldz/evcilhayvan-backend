import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart' show ProductVariant, VariantOption;

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/constants.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/category_model.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class _OptionDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController(text: '0');
  final TextEditingController priceDiffCtrl = TextEditingController(text: '0');

  void dispose() {
    labelCtrl.dispose();
    stockCtrl.dispose();
    priceDiffCtrl.dispose();
  }
}

class _VariantDraft {
  final TextEditingController nameCtrl = TextEditingController();
  final List<_OptionDraft> options = [_OptionDraft()];

  void dispose() {
    nameCtrl.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

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

  // Variant editor
  final List<_VariantDraft> _variants = [];

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
      for (final v in product.variants) {
        final draft = _VariantDraft();
        draft.nameCtrl.text = v.name;
        draft.options.clear();
        for (final opt in v.options) {
          final o = _OptionDraft();
          o.labelCtrl.text = opt.label;
          o.stockCtrl.text = opt.stock.toString();
          o.priceDiffCtrl.text = opt.priceDiff.toStringAsFixed(0);
          draft.options.add(o);
        }
        _variants.add(draft);
      }
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
      imageQuality: kImageQualityMedium,
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
      imageQuality: kImageQualityMedium,
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
      SnackBar(
        content: Text(AppLocalizations.of(context)!.addProductMaxWarning(_maxImages)),
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
          color: context.cardColor,
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
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.addProductPickDialogTitle,
                style: const TextStyle(
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
                title: Text(AppLocalizations.of(context)!.addProductPickGallery),
                subtitle: Text(AppLocalizations.of(context)!.addProductPickGallerySub),
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
                title: Text(AppLocalizations.of(context)!.addProductPickCamera),
                subtitle: Text(AppLocalizations.of(context)!.addProductPickCameraSub),
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
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() {
        _error = AppLocalizations.of(context)!.addProductCategoryRequired;
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

      final variantsPayload = _variants
          .where((v) => v.nameCtrl.text.trim().isNotEmpty && v.options.isNotEmpty)
          .map((v) => {
                'name': v.nameCtrl.text.trim(),
                'options': v.options
                    .where((o) => o.labelCtrl.text.trim().isNotEmpty)
                    .map((o) => {
                          'label': o.labelCtrl.text.trim(),
                          'stock': int.tryParse(o.stockCtrl.text) ?? 0,
                          'priceDiff': double.tryParse(o.priceDiffCtrl.text) ?? 0,
                        })
                    .toList(),
              })
          .toList();

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
            'variants': variantsPayload,
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
          variants: variantsPayload.isNotEmpty ? variantsPayload : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? AppLocalizations.of(context)!.addProductUpdated : AppLocalizations.of(context)!.addProductAdded),
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
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.addProductEditTitle : l10n.addProductTitle),
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
                      color: context.cardColor,
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
                            Text(
                              l10n.addProductPhotosSection,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_selectedImages.length}/$_maxImages',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                        l10n.addProductAddBtn,
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
                              l10n.addProductPhotosHint(_maxImages),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: context.cardColor,
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
                          label: l10n.addProductTitleField,
                          hint: l10n.addProductTitleHint,
                          icon: Icons.label_outline,
                          validator: (value) => value == null || value.trim().isEmpty ? l10n.addProductTitleRequired : null,
                        ),
                        const SizedBox(height: 12),
                        categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) {
                              return _ErrorChip(message: l10n.addProductCategoryNotFound);
                            }
                            return DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: l10n.addProductCategoryLabel,
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
                                  _selectedCategoryId == null ? l10n.addProductCategoryRequired : null,
                            );
                          },
                          loading: () => _FieldSkeleton(label: l10n.addProductCategoryLabel),
                          error: (e, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ErrorChip(message: l10n.addProductCategoryLoadErr),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () => ref.invalidate(categoriesProvider),
                                child: Text(l10n.addProductRetry),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LabeledField(
                          controller: _descController,
                          label: l10n.addProductDescLabel,
                          hint: l10n.addProductDescHint,
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LabeledField(
                                controller: _priceController,
                                label: l10n.addProductPriceLabel,
                                hint: '249.90',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return l10n.addProductPriceRequired;
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) return l10n.addProductPriceInvalid;
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledField(
                                controller: _stockController,
                                label: l10n.addProductStockLabel,
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
                                _isActive ? l10n.addProductActiveLabel : l10n.addProductInactiveLabel,
                                style: TextStyle(
                                  color: _isActive ? Colors.green[700] : Theme.of(context).colorScheme.onSurfaceVariant,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Varyant Editörü
                  _VariantEditorSection(
                    variants: _variants,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
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
                              label: Text(_loading ? l10n.addProductSaving : l10n.addProductSaveBtn),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.storePrimary.withOpacity(0.18)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        AppLocalizations.of(context)!.addProductCategoryLoading(label),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _VariantEditorSection extends StatelessWidget {
  const _VariantEditorSection({
    required this.variants,
    required this.onChanged,
  });

  final List<_VariantDraft> variants;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
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
                  gradient: const LinearGradient(colors: AppPalette.storeWarmGradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Varyantlar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Beden, renk, boyut gibi seçenekler',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  variants.add(_VariantDraft());
                  onChanged();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
              ),
            ],
          ),
          if (variants.isNotEmpty) const SizedBox(height: 12),
          ...variants.asMap().entries.map((vEntry) {
            final vi = vEntry.key;
            final v = vEntry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.storeSoftBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.storePrimary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: v.nameCtrl,
                          onChanged: (_) => onChanged(),
                          decoration: InputDecoration(
                            hintText: 'Varyant adı (ör: Boyut, Renk)',
                            hintStyle: const TextStyle(fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: context.cardColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          v.dispose();
                          variants.removeAt(vi);
                          onChanged();
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...v.options.asMap().entries.map((oEntry) {
                    final oi = oEntry.key;
                    final o = oEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _SmallField(
                              controller: o.labelCtrl,
                              hint: 'Etiket (ör: S, Kırmızı)',
                              onChanged: (_) => onChanged(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: _SmallField(
                              controller: o.stockCtrl,
                              hint: 'Stok',
                              keyboardType: TextInputType.number,
                              prefixText: '📦 ',
                              onChanged: (_) => onChanged(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: _SmallField(
                              controller: o.priceDiffCtrl,
                              hint: '±Fiyat',
                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                              prefixText: '₺ ',
                              onChanged: (_) => onChanged(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (v.options.length > 1)
                            GestureDetector(
                              onTap: () {
                                o.dispose();
                                v.options.removeAt(oi);
                                onChanged();
                              },
                              child: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red, size: 20),
                            )
                          else
                            const SizedBox(width: 20),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      v.options.add(_OptionDraft());
                      onChanged();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Seçenek Ekle', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? prefixText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: context.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
