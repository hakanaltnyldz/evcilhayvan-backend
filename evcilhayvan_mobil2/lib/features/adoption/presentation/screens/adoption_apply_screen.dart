import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import '../../data/repositories/adoption_repository.dart';

class AdoptionApplyScreen extends ConsumerStatefulWidget {
  final Pet pet;
  const AdoptionApplyScreen({super.key, required this.pet});

  @override
  ConsumerState<AdoptionApplyScreen> createState() => _AdoptionApplyScreenState();
}

class _AdoptionApplyScreenState extends ConsumerState<AdoptionApplyScreen> {
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(adoptionRepositoryProvider);
      final app = await repo.createApplication(
        widget.pet.id,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        ref.invalidate(sentAdoptionApplicationsProvider);
        _showSuccessDialog(app);
      }
    } on AdoptionApplicationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(dynamic app) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Basvuru Gonderildi!')),
          ],
        ),
        content: const Text('Sahiplendirme basvurunuz ilan sahibine iletildi. Sonucu basvurularim sayfasindan takip edebilirsiniz.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pet = widget.pet;
    final photoUrl = pet.photos.isNotEmpty ? '$apiBaseUrl${pet.photos[0]}' : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sahiplendirme Basvurusu'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: photoUrl != null
                          ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _petPlaceholder())
                          : _petPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${pet.species} - ${pet.breed}', style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(pet.gender.toLowerCase().contains('erkek') ? Icons.male : Icons.female, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${pet.gender} - ${pet.ageMonths} ay', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bilgilendirme
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Basvurunuz ilan sahibine iletilecektir. Ilan sahibi basvurunuzu kabul ederse mesajlasma baslatilacaktir.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Not alani
            Text('Basvuru Notu (opsiyonel)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Kendinizi tanıtın, neden bu hayvani sahiplenmek istediğinizi açıklayın...',
                filled: true,
                fillColor: context.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Gonder butonu
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_loading ? 'Gonderiliyor...' : 'Basvuru Gonder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _petPlaceholder() {
    return Container(
      color: AppPalette.background,
      child: const Center(child: Icon(Icons.pets, size: 40, color: AppPalette.onSurfaceVariant)),
    );
  }
}
