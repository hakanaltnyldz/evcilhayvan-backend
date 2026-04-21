import 'dart:io';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/store/data/store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class ApplySellerScreen extends ConsumerStatefulWidget {
  const ApplySellerScreen({super.key});

  @override
  ConsumerState<ApplySellerScreen> createState() => _ApplySellerScreenState();
}

class _ApplySellerScreenState extends ConsumerState<ApplySellerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Store info (Adım 1)
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Legal info (Adım 2)
  final _companyTitleController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _ibanController = TextEditingController();

  bool _loading = false;
  bool _acceptedTerms = false;
  bool _kvkkAccepted = false;
  XFile? _selectedLogo;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _companyTitleController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _addressController.dispose();
    _contactInfoController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
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
                AppLocalizations.of(context)!.applySellerLogoTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                title: Text(AppLocalizations.of(context)!.applySellerPickGallery),
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
                title: Text(AppLocalizations.of(context)!.applySellerPickCamera),
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
      final response = await dio.post('/api/uploads/images', data: formData);
      return response.data['url'] as String?;
    } catch (e) {
      debugPrint('[ApplySeller] Logo upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satıcı sözleşmesini kabul etmeniz gerekiyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_kvkkAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KVKK metnini kabul etmeniz gerekiyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String? logoUrl;
      if (_selectedLogo != null) {
        logoUrl = await _uploadLogo();
      }

      final repo = ref.read(storeRepositoryProvider);
      final result = await repo.applySeller(
        companyName: _nameController.text.trim(),
        companyTitle: _companyTitleController.text.trim(),
        taxNumber: _taxNumberController.text.trim(),
        taxOffice: _taxOfficeController.text.trim(),
        address: _addressController.text.trim(),
        contactInfo: _contactInfoController.text.trim(),
        iban: _ibanController.text.trim().toUpperCase(),
        logoUrl: logoUrl,
        kvkkAccepted: true,
        contractAccepted: true,
      );

      if (mounted) {
        _showSuccessDialog(result.applicationId);
      }
    } catch (e) {
      debugPrint('[ApplySeller] Error: $e');
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

  void _showSuccessDialog(String applicationId) {
    final outerContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
              child: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(outerContext)!.applySellerSuccessTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(outerContext)!.applySellerSuccessDesc(_nameController.text.trim()),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(outerContext).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (outerContext.mounted) {
                    Navigator.of(outerContext).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(outerContext)!.applySellerGoToStore),
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
    return AppLocalizations.of(context)!.applySellerGenericError;
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
                  Text(
                    AppLocalizations.of(context)!.applySellerTermsDialogTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    ...() {
                      final isEn = Localizations.localeOf(context).languageCode == 'en';
                      return isEn ? [
                        _buildTermSection('1. General Rules', 'By joining our platform as a seller, you agree to comply with the following rules.'),
                        _buildTermSection('2. Product Quality', 'All products you list must be quality, original and consistent with descriptions. Selling counterfeit products is prohibited.'),
                        _buildTermSection('3. Pricing', 'Product prices must be fair and in line with market conditions. Excessive pricing or misleading discounts are prohibited.'),
                        _buildTermSection('4. Delivery', 'Orders must be shipped within 3 business days. You must notify the customer in case of delay.'),
                        _buildTermSection('5. Returns & Cancellations', 'Customers have the right to return within 14 days. Return requests must be responded to within 48 hours.'),
                        _buildTermSection('6. Customer Communication', 'Customer questions must be answered within 24 hours. Polite and professional communication is essential.'),
                        _buildTermSection('7. Prohibited Products', 'The sale of illegal, dangerous or animal welfare-violating products is strictly prohibited.'),
                        _buildTermSection('8. Commission', 'The platform takes a 10% commission on each sale, automatically deducted at payment.'),
                        _buildTermSection('9. Account Suspension', 'Sellers who do not comply with the rules may have their accounts suspended without warning.'),
                        _buildTermSection('10. Acceptance', 'By accepting this agreement, you commit to complying with all terms.'),
                      ] : [
                        _buildTermSection('1. Genel Kurallar', 'Satıcı olarak platformumuza katılarak aşağıdaki kurallara uymayı kabul etmiş sayılırsınız.'),
                        _buildTermSection('2. Ürün Kalitesi', 'Satışa sunduğunuz tüm ürünlerin kaliteli, orijinal ve açıklamalarla uyumlu olması gerekmektedir. Sahte veya yanıltıcı ürün satışı yasaktır.'),
                        _buildTermSection('3. Fiyatlandırma', 'Ürün fiyatları adil ve piyasa koşullarına uygun olmalıdır. Aşırı fiyatlandırma veya yanıltıcı indirimler yasaktır.'),
                        _buildTermSection('4. Teslimat', 'Siparişler en geç 3 iş günü içinde kargoya verilmelidir. Gecikme durumunda müşteriyi bilgilendirmelisiniz.'),
                        _buildTermSection('5. İade ve İptal', 'Müşterilerin 14 gün içinde iade hakkı bulunmaktadır. İade talepleri en geç 48 saat içinde yanıtlanmalıdır.'),
                        _buildTermSection('6. Müşteri İletişimi', 'Müşteri sorularına en geç 24 saat içinde yanıt verilmelidir. Kibar ve profesyonel iletişim esastır.'),
                        _buildTermSection('7. Yasaklı Ürünler', 'Yasadışı, tehlikeli, sağlığa zararlı veya hayvan refahına aykırı ürünlerin satışı kesinlikle yasaktır.'),
                        _buildTermSection('8. Komisyon', 'Platform, her satıştan %10 komisyon alır. Komisyon tutarı ödeme sırasında otomatik olarak düşülür.'),
                        _buildTermSection('9. Hesap Askıya Alma', 'Kurallara uymayan satıcıların hesapları uyarı yapılmadan askıya alınabilir.'),
                        _buildTermSection('10. Kabul', 'Bu sözleşmeyi kabul ederek tüm maddelere uymayı taahhüt etmiş olursunuz.'),
                      ];
                    }(),
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
                  child: Text(
                    AppLocalizations.of(context)!.applySellerTermsAcceptBtn,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.applySellerTitle),
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
                  _buildProgressSteps(),
                  const SizedBox(height: 24),

                  _buildLogoSection(),
                  const SizedBox(height: 20),

                  _buildStoreInfoSection(l10n),
                  const SizedBox(height: 20),

                  _buildLegalInfoSection(l10n),
                  const SizedBox(height: 20),

                  _buildTermsSection(l10n),
                  const SizedBox(height: 24),

                  _buildSubmitButton(l10n),
                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      l10n.applySellerApprovalNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context)!;
    final step1Done = _selectedLogo != null;
    final step2Done = _nameController.text.isNotEmpty &&
        _companyTitleController.text.isNotEmpty &&
        _taxNumberController.text.isNotEmpty;
    final step3Done = _acceptedTerms && _kvkkAccepted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
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
          _buildStep(1, l10n.applySellerStepLogo, step1Done),
          _buildStepLine(step1Done),
          _buildStep(2, l10n.applySellerStepInfo, step2Done),
          _buildStepLine(step2Done && step3Done),
          _buildStep(3, l10n.applySellerStepContract, step3Done),
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
              color: completed ? Colors.green : Theme.of(context).dividerColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: completed ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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
              color: completed ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
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
          color: completed ? Colors.green : Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
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
              Text(
                l10n.applySellerLogoSection,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            l10n.applySellerLogoAdd,
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
              l10n.applySellerLogoHint,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
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
              Text(
                l10n.applySellerInfoSection,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            maxLength: 120,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.applySellerNameLabel,
              hintText: l10n.applySellerNameHint,
              prefixIcon: const Icon(Icons.storefront),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerNameRequired;
              }
              if (value.trim().length < 3) {
                return l10n.applySellerNameTooShort;
              }
              if (value.trim().length > 120) {
                return l10n.applySellerNameTooLong;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: l10n.applySellerDescLabel,
              hintText: l10n.applySellerDescHint,
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfoSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
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
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.deepPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.applySellerLegalInfoSection,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Şirket Unvanı
          TextFormField(
            controller: _companyTitleController,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l10n.applySellerCompanyTitleLabel,
              hintText: l10n.applySellerCompanyTitleHint,
              prefixIcon: const Icon(Icons.apartment),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerCompanyTitleRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Vergi Numarası
          TextFormField(
            controller: _taxNumberController,
            maxLength: 11,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.applySellerTaxNumberLabel,
              hintText: l10n.applySellerTaxNumberHint,
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerTaxNumberRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Vergi Dairesi
          TextFormField(
            controller: _taxOfficeController,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: l10n.applySellerTaxOfficeLabel,
              hintText: l10n.applySellerTaxOfficeHint,
              prefixIcon: const Icon(Icons.account_balance),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerTaxOfficeRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Adres
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: l10n.applySellerAddressLabel,
              hintText: l10n.applySellerAddressHint,
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerAddressRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // İletişim Bilgisi
          TextFormField(
            controller: _contactInfoController,
            maxLength: 100,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.applySellerContactInfoLabel,
              hintText: l10n.applySellerContactInfoHint,
              prefixIcon: const Icon(Icons.contact_phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerContactInfoRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // IBAN
          TextFormField(
            controller: _ibanController,
            maxLength: 32,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.applySellerIbanLabel,
              hintText: l10n.applySellerIbanHint,
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.applySellerIbanRequired;
              }
              final iban = value.trim().toUpperCase().replaceAll(' ', '');
              if (!iban.startsWith('TR') || iban.length < 10) {
                return l10n.applySellerIbanInvalid;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
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
              Expanded(
                child: Text(
                  l10n.applySellerTermsTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_acceptedTerms)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l10n.applySellerTermsAccepted,
                        style: const TextStyle(
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
                  Expanded(
                    child: Text(
                      l10n.applySellerTermsRead,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // KVKK onayı
          InkWell(
            onTap: () => setState(() => _kvkkAccepted = !_kvkkAccepted),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kvkkAccepted
                    ? Colors.blue.withOpacity(0.05)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kvkkAccepted
                      ? Colors.blue.withOpacity(0.3)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _kvkkAccepted,
                    onChanged: (value) => setState(() => _kvkkAccepted = value ?? false),
                    activeColor: Colors.blue,
                  ),
                  const Expanded(
                    child: Text(
                      'Kişisel verilerimin işlenmesine ilişkin KVKK aydınlatma metnini okudum ve onaylıyorum.',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    final isReady = _nameController.text.trim().isNotEmpty && _acceptedTerms && _kvkkAccepted;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isReady
            ? const LinearGradient(colors: AppPalette.storeWarmGradient)
            : null,
        color: isReady ? null : Theme.of(context).dividerColor,
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
                    Icons.send,
                    color: isReady ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.applySellerOpenBtn,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isReady ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
