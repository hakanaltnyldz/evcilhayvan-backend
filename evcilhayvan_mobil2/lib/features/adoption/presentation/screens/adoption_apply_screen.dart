import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adoptionApplyErrGeneric(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(dynamic app) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF2D6A4F)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.adoptionApplySuccessTitle)),
          ],
        ),
        content: Text(l10n.adoptionApplySuccessContent),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.adoptionApplySuccessOk),
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
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.adoptionApplyTitle), backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3DC),
                borderRadius: BorderRadius.circular(16),
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
                        Text('${pet.species} - ${pet.breed}', style: theme.textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(pet.gender.toLowerCase().contains('erkek') ? Icons.male : Icons.female, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
                color: const Color(0xFF2D6A4F).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2D6A4F), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.adoptionApplyInfoText,
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF1B4332)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Note field
            Text(AppLocalizations.of(context)!.adoptionApplyNoteLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.adoptionApplyNoteHint,
                filled: true,
                fillColor: Colors.white,
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
              label: Text(_loading ? AppLocalizations.of(context)!.adoptionApplySending : AppLocalizations.of(context)!.adoptionApplySendBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      color: const Color(0xFFD8F3DC),
      child: const Center(child: Icon(Icons.pets, size: 40, color: Color(0xFF2D6A4F))),
    );
  }
}
