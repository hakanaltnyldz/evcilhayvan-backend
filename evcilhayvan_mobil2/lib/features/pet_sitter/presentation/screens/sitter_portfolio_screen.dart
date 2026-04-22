import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';

class SitterPortfolioScreen extends ConsumerStatefulWidget {
  const SitterPortfolioScreen({super.key});

  @override
  ConsumerState<SitterPortfolioScreen> createState() =>
      _SitterPortfolioScreenState();
}

class _SitterPortfolioScreenState extends ConsumerState<SitterPortfolioScreen> {
  bool _uploading = false;
  String? _coverUpdatingUrl;
  final Set<String> _deleting = <String>{};

  String _resolve(String url) =>
      url.startsWith('http') ? url : '$apiBaseUrl$url';

  Future<void> _pickAndUpload(PetSitterModel sitter) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 82, maxWidth: 1400);
    if (files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      await ref
          .read(petSitterRepositoryProvider)
          .uploadPortfolioPhotos(
            sitter.id,
            files.map((item) => File(item.path)).toList(),
          );
      ref.invalidate(mySitterProfileProvider);
      ref.invalidate(sitterDetailProvider(sitter.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Portfolio guncellendi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Foto yuklenemedi: $error')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(PetSitterModel sitter, String photoUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fotografi sil'),
        content: const Text(
          'Bu fotograf portfolio alanindan kaldirilacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgec'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting.add(photoUrl));
    try {
      await ref
          .read(petSitterRepositoryProvider)
          .deletePortfolioPhoto(sitter.id, photoUrl);
      ref.invalidate(mySitterProfileProvider);
      ref.invalidate(sitterDetailProvider(sitter.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fotograf kaldirildi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fotograf silinemedi: $error')));
    } finally {
      if (mounted) setState(() => _deleting.remove(photoUrl));
    }
  }

  Future<void> _makeCover(PetSitterModel sitter, String photoUrl) async {
    final reordered = [
      photoUrl,
      ...sitter.photos.where((item) => item != photoUrl),
    ];
    setState(() => _coverUpdatingUrl = photoUrl);
    try {
      await ref
          .read(petSitterRepositoryProvider)
          .reorderPortfolioPhotos(sitter.id, reordered);
      ref.invalidate(mySitterProfileProvider);
      ref.invalidate(sitterDetailProvider(sitter.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak fotografi guncellendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kapak fotografi guncellenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _coverUpdatingUrl = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(mySitterProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Portfolio Yonetimi'),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(mySitterProfileProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: PawLoading()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Portfolio yuklenemedi:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (sitter) {
          if (sitter == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.collections_bookmark_outlined, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Portfolio yonetmek icin once bakici profili olusturmalisin.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.pushNamed('become-sitter'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Bakici Profili Olustur'),
                    ),
                  ],
                ),
              ),
            );
          }

          final completion = (sitter.photos.length / 6).clamp(0.0, 1.0);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(mySitterProfileProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _heroChip('${sitter.photos.length} fotograf'),
                          _heroChip('${sitter.reviewCount} yorum'),
                          _heroChip(sitter.availability ? 'Musait' : 'Mesgul'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        sitter.displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: completion,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.16),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFD8F3DC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Portfolio doluluk: %${(completion * 100).round()}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portfolyonu guclendir',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bakim anlari, oyun zamani ve temiz ortam fotograflari daha cok rezervasyon donusumu saglar.',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploading
                              ? null
                              : () => _pickAndUpload(sitter),
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _uploading
                                ? 'Yukleniyor...'
                                : 'Portfolioya Fotograf Ekle',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (sitter.photos.isEmpty)
                  const AnimatedEmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'Henuz portfolio fotografi yok',
                    subtitle:
                        'Ilk birkac fotografin bakici profilini daha guvenilir gosterir.',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sitter.photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    itemBuilder: (context, index) {
                      final photoUrl = sitter.photos[index];
                      final deleting = _deleting.contains(photoUrl);
                      final coverUpdating = _coverUpdatingUrl == photoUrl;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _resolve(photoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: context.subtleBackground,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.62),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? const Color(0xFFD8F3DC)
                                      : Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  index == 0
                                      ? 'Kapak'
                                      : 'Fotograf ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: index == 0
                                        ? const Color(0xFF2D6A4F)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton.filled(
                                onPressed: deleting
                                    ? null
                                    : () => _deletePhoto(sitter, photoUrl),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withOpacity(
                                    0.45,
                                  ),
                                ),
                                icon: deleting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.delete_outline),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.38),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        index == 0
                                            ? 'Profilde one cikar'
                                            : 'Kapak yaparak one cikar',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index != 0) ...[
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed: coverUpdating
                                          ? null
                                          : () => _makeCover(sitter, photoUrl),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2D6A4F,
                                        ),
                                      ),
                                      icon: coverUpdating
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.star_outline),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
