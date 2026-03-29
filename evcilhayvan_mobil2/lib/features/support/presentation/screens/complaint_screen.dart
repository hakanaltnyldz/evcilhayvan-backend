// lib/features/support/presentation/screens/complaint_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';

class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key});

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  static const _categories = [
    ('app_bug', 'Uygulama Hatası'),
    ('content_complaint', 'İçerik Şikayeti'),
    ('user_complaint', 'Kullanıcı Şikayeti'),
    ('payment_issue', 'Ödeme Sorunu'),
    ('account_issue', 'Hesap Sorunu'),
    ('other', 'Diğer'),
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ApiClient().dio;
      await dio.post('/api/support/ticket', data: {
        'category': _selectedCategory,
        'message': _messageCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayetiniz iletildi. En kısa sürede inceleyeceğiz.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayet gönderilemedi. Lütfen tekrar deneyin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('Şikayet Bildir'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3DC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2D6A4F), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Şikayetiniz gizli tutulur ve ekibimiz tarafından incelenir.',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6A4F))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 2)),
                prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF2D6A4F)),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat.$1,
                  child: Text(cat.$2),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Lütfen bir kategori seçin' : null,
            ),
            const SizedBox(height: 16),
            // Message field
            TextFormField(
              controller: _messageCtrl,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: 'Mesajınız',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Yaşadığınız sorunu detaylı açıklayın...',
              ),
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Mesaj en az 10 karakter olmalıdır';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Submit button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Gönderiliyor...' : 'Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
