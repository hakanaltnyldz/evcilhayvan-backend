import 'dart:io';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/post_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();
  final List<File> _selectedImages = [];
  final List<String> _hashtags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(_extractHashtagsFromContent);
  }

  void _extractHashtagsFromContent() {
    final text = _contentCtrl.text;
    final matches = RegExp(r'#(\w+)').allMatches(text);
    final extracted = matches.map((m) => m.group(1)!.toLowerCase()).toSet();
    // Only add tags not already in _hashtags
    for (final tag in extracted) {
      if (!_hashtags.contains(tag)) {
        setState(() => _hashtags.add(tag));
      }
    }
  }

  void _addHashtagFromInput() {
    final raw = _hashtagCtrl.text.trim().replaceAll('#', '').toLowerCase();
    if (raw.isEmpty || _hashtags.contains(raw)) {
      _hashtagCtrl.clear();
      return;
    }
    setState(() => _hashtags.add(raw));
    _hashtagCtrl.clear();
  }

  @override
  void dispose() {
    _contentCtrl.removeListener(_extractHashtagsFromContent);
    _contentCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createPostMaxImages)),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;
    final allowed = picked.take(4 - _selectedImages.length).toList();
    setState(() => _selectedImages.addAll(allowed.map((x) => File(x.path))));
  }

  Future<List<String>> _uploadImages() async {
    final dioInstance = ApiClient().dio;
    final uploaded = <String>[];
    for (final file in _selectedImages) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final resp = await dioInstance.post('/api/uploads/single', data: formData);
      final url = resp.data['url'] ?? resp.data['path'];
      if (url != null) uploaded.add(url.toString());
    }
    return uploaded;
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createPostValidation)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        photoUrls = await _uploadImages();
      }

      await ref.read(postRepositoryProvider).createPost(
        content: content.isEmpty ? null : content,
        photos: photoUrls.isEmpty ? null : photoUrls,
        hashtags: _hashtags.isEmpty ? null : _hashtags,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.createPostErr(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createPostTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: Text(AppLocalizations.of(context)!.createPostShareBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              minLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.createPostHint,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2D6A4F)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Image picker
            Row(
              children: [
                Text(AppLocalizations.of(context)!.createPostPhotosLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Text('(${_selectedImages.length}/4)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectedImages.length < 4 ? _pickImages : null,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(AppLocalizations.of(context)!.createPostAddBtn),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D6A4F)),
                ),
              ],
            ),

            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (_, i) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10, top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImages[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.createPostEmptyHint, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Hashtag section
            const Text(
              'Hashtagler',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'İçeriğe yazdığın #kelimeler otomatik eklenir',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hashtagCtrl,
                    decoration: InputDecoration(
                      hintText: 'örn: kedi',
                      prefixText: '#',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _addHashtagFromInput(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addHashtagFromInput,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
                ),
              ],
            ),
            if (_hashtags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _hashtags.map((tag) => Chip(
                    label: Text('#$tag'),
                    labelStyle: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.w500),
                    backgroundColor: const Color(0xFFD8F3DC),
                    deleteIconColor: const Color(0xFF2D6A4F),
                    onDeleted: () => setState(() => _hashtags.remove(tag)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
