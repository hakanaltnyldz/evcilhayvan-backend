import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ApplySellerScreen extends ConsumerStatefulWidget {
  const ApplySellerScreen({super.key});

  @override
  ConsumerState<ApplySellerScreen> createState() => _ApplySellerScreenState();
}

class _ApplySellerScreenState extends ConsumerState<ApplySellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _loading = false;
  bool _acceptedTerms = false;
  XFile? _selectedLogo;
  final ImagePicker _picker = ImagePicker();
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
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
                'Mağaza Logosu Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (picked != null) {
                    setState(() => _selectedLogo = picked);
                  }
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
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (picked != null) {
                    setState(() => _selectedLogo = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadLogo() async {
    if (_selectedLogo == null) return null;

    try {
      final dio = ApiClient().dio;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedLogo!.path,
          filename: _selectedLogo!.name,
        ),
      });

      debugPrint('[ApplySeller] Uploading logo...');
      final response = await dio.post('/api/uploads/images', data: formData);
      debugPrint('[ApplySeller] Upload response: ${response.data}');
      return response.data['url'] as String?;
    } catch (e) {
      debugPrint('[ApplySeller] Logo upload error: $e');
      if (e is DioException) {
        debugPrint('[ApplySeller] Upload response: ${e.response?.data}');
      }
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // Önce logoyu yükle
      String? logoUrl;
      if (_selectedLogo != null) {
        logoUrl = await _uploadLogo();
      }

      final repo = ref.read(storeRepositoryProvider);
      final result = await repo.applySeller(
        storeName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        logoUrl: logoUrl,
      );

      ref.read(authProvider.notifier).loginSuccess(result.user);
      if (mounted) {
        _showSuccessDialog(result.store.name);
      }
    } catch (e) {
      debugPrint('[ApplySeller] Error: $e');
      if (e is DioException) {
        debugPrint('[ApplySeller] Response: ${e.response?.data}');
        debugPrint('[ApplySeller] Status: ${e.response?.statusCode}');
      }
      if (mounted) {
        final message = _formatErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String storeName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tebrikler!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '"$storeName" mağazanız başarıyla oluşturuldu!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mağazama Git'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatErrorMessage(Object error) {
    if (error is DioException) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message'] as String?)
          : error.response?.data?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return 'Bir hata oluştu, lütfen tekrar deneyin.';
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPalette.storePrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: AppPalette.storePrimary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Satıcı Sözleşmesi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermSection(
                      '1. Genel Kurallar',
                      'Satıcı olarak platformumuza katılarak aşağıdaki kurallara uymayı kabul etmiş sayılırsınız.',
                    ),
                    _buildTermSection(
                      '2. Ürün Kalitesi',
                      'Satışa sunduğunuz tüm ürünlerin kaliteli, orijinal ve açıklamalarla uyumlu olması gerekmektedir. Sahte veya yanıltıcı ürün satışı yasaktır.',
                    ),
                    _buildTermSection(
                      '3. Fiyatlandırma',
                      'Ürün fiyatları adil ve piyasa koşullarına uygun olmalıdır. Aşırı fiyatlandırma veya yanıltıcı indirimler yasaktır.',
                    ),
                    _buildTermSection(
                      '4. Teslimat',
                      'Siparişler en geç 3 iş günü içinde kargoya verilmelidir. Gecikme durumunda müşteriyi bilgilendirmelisiniz.',
                    ),
                    _buildTermSection(
                      '5. İade ve İptal',
                      'Müşterilerin 14 gün içinde iade hakkı bulunmaktadır. İade talepleri en geç 48 saat içinde yanıtlanmalıdır.',
                    ),
                    _buildTermSection(
                      '6. Müşteri İletişimi',
                      'Müşteri sorularına en geç 24 saat içinde yanıt verilmelidir. Kibar ve profesyonel iletişim esastır.',
                    ),
                    _buildTermSection(
                      '7. Yasaklı Ürünler',
                      'Yasadışı, tehlikeli, sağlığa zararlı veya hayvan refahına aykırı ürünlerin satışı kesinlikle yasaktır.',
                    ),
                    _buildTermSection(
                      '8. Komisyon',
                      'Platform, her satıştan %10 komisyon alır. Komisyon tutarı ödeme sırasında otomatik olarak düşülür.',
                    ),
                    _buildTermSection(
                      '9. Hesap Askıya Alma',
                      'Kurallara uymayan satıcıların hesapları uyarı yapılmadan askıya alınabilir.',
                    ),
                    _buildTermSection(
                      '10. Kabul',
                      'Bu sözleşmeyi kabul ederek tüm maddelere uymayı taahhüt etmiş olursunuz.',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _acceptedTerms = true);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.storePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Okudum ve Kabul Ediyorum',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppPalette.storePrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza Aç'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Steps
                  _buildProgressSteps(),
                  const SizedBox(height: 24),

                  // Logo Section
                  _buildLogoSection(),
                  const SizedBox(height: 20),

                  // Store Info Section
                  _buildStoreInfoSection(),
                  const SizedBox(height: 20),

                  // Terms Section
                  _buildTermsSection(),
                  const SizedBox(height: 24),

                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 16),

                  // Info Text
                  Center(
                    child: Text(
                      'Mağazanız onaylandıktan sonra ürün eklemeye başlayabilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
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

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStep(1, 'Logo', _selectedLogo != null),
          _buildStepLine(_selectedLogo != null),
          _buildStep(2, 'Bilgiler', _nameController.text.isNotEmpty),
          _buildStepLine(_nameController.text.isNotEmpty && _acceptedTerms),
          _buildStep(3, 'Sözleşme', _acceptedTerms),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label, bool completed) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: completed ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: completed ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: completed ? Colors.green : Colors.grey[600],
              fontWeight: completed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool completed) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: completed ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppPalette.storeWarmGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mağaza Logosu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppPalette.storePrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppPalette.storePrimary.withOpacity(0.3),
                    width: 2,
                  ),
                  image: _selectedLogo != null
                      ? DecorationImage(
                          image: FileImage(File(_selectedLogo!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedLogo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: AppPalette.storePrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Logo Ekle',
                            style: TextStyle(
                              color: AppPalette.storePrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            right: 8,
                            top: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedLogo = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Kare formatta, minimum 200x200 piksel önerilir',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppPalette.storeCoolGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mağaza Bilgileri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mağaza Adı *',
              hintText: 'Örn: Happy Pets Store',
              prefixIcon: const Icon(Icons.storefront),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mağaza adı gerekli';
              }
              if (value.trim().length < 3) {
                return 'En az 3 karakter olmalı';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Mağaza Açıklaması',
              hintText: 'Mağazanızı tanıtın...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _acceptedTerms
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _acceptedTerms ? Icons.verified : Icons.description,
                  color: _acceptedTerms ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Satıcı Sözleşmesi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_acceptedTerms)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Kabul Edildi',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showTermsDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _acceptedTerms
                    ? Colors.green.withOpacity(0.05)
                    : Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptedTerms
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      if (value == true) {
                        _showTermsDialog();
                      } else {
                        setState(() => _acceptedTerms = false);
                      }
                    },
                    activeColor: Colors.green,
                  ),
                  const Expanded(
                    child: Text(
                      'Satıcı sözleşmesini okudum ve kabul ediyorum',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isReady = _nameController.text.trim().isNotEmpty && _acceptedTerms;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isReady
            ? const LinearGradient(colors: AppPalette.storeWarmGradient)
            : null,
        color: isReady ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: AppPalette.storePrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _loading || !isReady ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: isReady ? Colors.white : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mağazamı Aç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isReady ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}