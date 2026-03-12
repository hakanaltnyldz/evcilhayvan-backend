// lib/features/mating/presentation/screens/mating_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/mating/data/repositories/mating_repository.dart';
import 'package:evcilhayvan_mobil2/features/mating/domain/models/mating_profile.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';

class MatingScreen extends ConsumerStatefulWidget {
  const MatingScreen({super.key});

  @override
  ConsumerState<MatingScreen> createState() => _MatingScreenState();
}

class _MatingScreenState extends ConsumerState<MatingScreen> {
  final List<String> _species = const ['Tümü', 'Köpek', 'Kedi', 'Kuş'];
  String _selectedSpecies = 'Tümü';
  String _selectedGender = 'Tümü';
  double _maxDistance = 20;
  final Set<String> _requestingProfiles = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = MatingQuery(
      species: _selectedSpecies == 'Tümü' ? null : _selectedSpecies,
      gender: _selectedGender == 'Tümü' ? null : _selectedGender,
      maxDistanceKm: _maxDistance,
    );

    final profilesAsync = ref.watch(matingProfilesProvider(filters));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Eşleştirme Bul'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            tooltip: 'Eşleştirme istekleri',
            onPressed: () => context.pushNamed('mating-requests'),
          ),
        ],
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evcil dostların için uygun eşleşmeleri keşfet.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  label: 'Tür',
                  values: _species,
                  selectedValue: _selectedSpecies,
                  onSelected: (value) => setState(() => _selectedSpecies = value),
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  label: 'Cinsiyet',
                  values: const ['Tümü', 'Erkek', 'Dişi'],
                  selectedValue: _selectedGender,
                  onSelected: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Maksimum mesafe: ${_maxDistance.round()} km',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.15),
                    thumbColor: theme.colorScheme.secondary,
                    overlayColor: theme.colorScheme.secondary.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_maxDistance.round()} km',
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: profilesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => _ErrorState(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(matingProfilesProvider(filters)),
                    ),
                    data: (profiles) {
                      final filtered = profiles.where((profile) {
                        final matchesSpecies = _selectedSpecies == 'Tümü' || profile.species == _selectedSpecies;
                        final matchesGender = _selectedGender == 'Tümü' || profile.gender == _selectedGender;
                        final matchesDistance = profile.distanceKm <= _maxDistance;
                        return matchesSpecies && matchesGender && matchesDistance;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const _EmptyState();
                      }

                      return _SwipeCardDeck(
                        key: ValueKey('${_selectedSpecies}_${_selectedGender}_${_maxDistance.round()}'),
                        profiles: filtered,
                        onSwipeRight: (profile) => _swipeRightMatch(profile, filters: filters),
                        onDetails: _openDetails,
                        onRefresh: () async {
                          ref.invalidate(matingProfilesProvider(filters));
                          try {
                            await ref.read(matingProfilesProvider(filters).future);
                          } catch (_) {}
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(MatingProfile profile) async {
    if (!mounted) return;
    if (profile.petId.isEmpty) {
      _showSnackBar('İlan detayı açılamadı.', isError: true);
      return;
    }
    context.pushNamed(
      'pet-detail',
      pathParameters: {'id': profile.petId},
    );
  }

  /// Swipe mode'da eşleştirme isteği gönder (navigasyon yok)
  Future<void> _swipeRightMatch(MatingProfile profile, {required MatingQuery filters}) async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      _showSnackBar('Eşleştirme isteği için önce giriş yapmalısın.', isError: true);
      if (mounted) context.goNamed('login');
      return;
    }

    final requesterPetId = await _pickMyMatingAdvertId(profile.species);
    if (requesterPetId == null) return;

    final repository = ref.read(matingRepositoryProvider);
    try {
      final targetId = profile.id.isNotEmpty ? profile.id : profile.petId;
      final result = await repository.sendMatchRequest(
        targetId,
        requesterPetId: requesterPetId,
      );
      if (!mounted) return;
      _showSnackBar(result.message, isError: !result.success);
      if (result.success || result.didMatch) {
        ref.invalidate(matingProfilesProvider(filters));
        ref.invalidate(outboxMatchRequestsProvider);
      }
    } on MatchRequestException catch (e) {
      if (!mounted) return;
      if (e.code == 'NO_MATING_ADVERT') {
        await _showMatingAdvertSheet(targetSpecies: profile.species);
        return;
      }
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _requestMatch(
    MatingProfile profile, {
    required MatingQuery filters,
  }) async {
    if (_requestingProfiles.contains(profile.id)) {
      return;
    }

    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      _showSnackBar('Eşleştirme isteği için önce giriş yapmalısın.', isError: true);
      if (mounted) context.goNamed('login');
      return;
    }

    final requesterPetId = await _pickMyMatingAdvertId(profile.species);
    if (requesterPetId == null) return;

    setState(() {
      _requestingProfiles.add(profile.id);
    });

    final repository = ref.read(matingRepositoryProvider);
    try {
      final targetId = profile.id.isNotEmpty ? profile.id : profile.petId;
      final result = await repository.sendMatchRequest(
        targetId,
        requesterPetId: requesterPetId,
      );
      if (!mounted) return;
      _showSnackBar(result.message, isError: !result.success);
      if (result.success || result.didMatch) {
        ref.invalidate(matingProfilesProvider(filters));
        ref.invalidate(outboxMatchRequestsProvider);
        if (mounted) {
          context.goNamed('messages', queryParameters: {'tab': 'requests'});
        }
      }
    } on MatchRequestException catch (e) {
      if (!mounted) return;
      if (e.code == 'NO_MATING_ADVERT') {
        await _showMatingAdvertSheet(targetSpecies: profile.species);
        return;
      }
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _requestingProfiles.remove(profile.id);
        });
      }
    }
  }

  Future<String?> _pickMyMatingAdvertId(String? targetSpecies) async {
    final petsRepo = ref.read(petsRepositoryProvider);
    try {
      final myMating = await petsRepo.getMyAdverts(advertType: 'mating');
      final active = myMating.where((p) => p.isActive).toList();
      if (active.isEmpty) {
        await _showMatingAdvertSheet(targetSpecies: targetSpecies);
        return null;
      }

      final normalizedTarget = targetSpecies?.trim().toLowerCase() ?? '';
      final compatible = normalizedTarget.isEmpty
          ? active
          : active.where((p) => p.species.trim().toLowerCase() == normalizedTarget).toList();

      if (compatible.isEmpty) {
        await _showMatingAdvertSheet(targetSpecies: targetSpecies);
        return null;
      }

      if (compatible.length == 1) {
        return compatible.first.id;
      }

      if (!mounted) return null;

      String? selectedId = compatible.first.id;
      String? confirmedId;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final maxHeight = MediaQuery.of(ctx).size.height * 0.6;
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Eşleştirme için ilan seç',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: compatible.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final p = compatible[index];
                            final name = p.name.trim().isNotEmpty ? p.name : 'İsimsiz ilan';
                            final detailParts = <String>[
                              if (p.species.trim().isNotEmpty) p.species,
                              if (p.breed.trim().isNotEmpty) p.breed,
                            ];
                            final detail = detailParts.isNotEmpty ? detailParts.join(' - ') : 'Detay yok';
                            final isSelected = selectedId == p.id;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(name),
                              subtitle: Text(detail),
                              trailing: Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Theme.of(ctx).colorScheme.outline,
                              ),
                              onTap: () => setModalState(() => selectedId = p.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Vazgeç'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selectedId != null
                                  ? () {
                                      confirmedId = selectedId;
                                      Navigator.of(ctx).pop();
                                    }
                                  : null,
                              child: const Text('Devam et'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      return confirmedId;
    } catch (_) {
      await _showMatingAdvertSheet(targetSpecies: targetSpecies);
      return null;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _showMatingAdvertSheet({String? targetSpecies}) async {
    if (!mounted) return;
    final speciesLabel = targetSpecies != null && targetSpecies.trim().isNotEmpty
        ? targetSpecies.trim()
        : null;
    final description = speciesLabel == null
        ? 'Eşleştirme isteği göndermek için önce kendi eşleştirme ilanını oluşturmalısın.'
        : 'Eşleştirme isteği göndermek için önce aynı türden ilan oluşturmalısın: $speciesLabel.';

    final shouldCreate = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eşleştirme ilanı gerekli',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Vazgec'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Şimdi ilan oluştur'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldCreate == true && mounted) {
      final extra = <String, dynamic>{'advertType': 'mating'};
      if (speciesLabel != null) {
        extra['species'] = speciesLabel;
      }
      context.pushNamed('create-pet', extra: extra);
    }
  }
}

// ─── Filter Chips ────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _FilterChips({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values.map((value) {
            final isSelected = value == selectedValue;
            return FilterChip(
              label: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(value),
              showCheckmark: false,
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isSelected ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Swipe Card Deck ─────────────────────────────────────────────────────────

class _SwipeCardDeck extends StatefulWidget {
  final List<MatingProfile> profiles;
  final Future<void> Function(MatingProfile) onSwipeRight;
  final void Function(MatingProfile) onDetails;
  final Future<void> Function() onRefresh;

  const _SwipeCardDeck({
    super.key,
    required this.profiles,
    required this.onSwipeRight,
    required this.onDetails,
    required this.onRefresh,
  });

  @override
  State<_SwipeCardDeck> createState() => _SwipeCardDeckState();
}

class _SwipeCardDeckState extends State<_SwipeCardDeck> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;
  bool _isSwiping = false;
  Offset _animStart = Offset.zero;
  Offset _animEnd = Offset.zero;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _animController.addListener(_onAnimTick);
    _animController.addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAnimTick() {
    if (!mounted) return;
    final t = Curves.easeOut.transform(_animController.value);
    setState(() => _dragOffset = Offset.lerp(_animStart, _animEnd, t)!);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) return;
    if (_isSwiping) {
      setState(() => _currentIndex++);
    }
    setState(() {
      _dragOffset = Offset.zero;
      _isAnimating = false;
      _isSwiping = false;
    });
    _animController.reset();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    setState(() => _dragOffset += d.delta);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_isAnimating) return;
    const threshold = 80.0;
    if (_dragOffset.dx.abs() > threshold) {
      _commitSwipe(_dragOffset.dx > 0);
    } else {
      _snapBack();
    }
  }

  void _commitSwipe(bool swipeRight) {
    if (_isAnimating || _currentIndex >= widget.profiles.length) return;
    final screenWidth = MediaQuery.of(context).size.width;
    _animStart = _dragOffset;
    _animEnd = Offset(
      swipeRight ? screenWidth * 1.7 : -screenWidth * 1.7,
      _dragOffset.dy + 60,
    );
    setState(() {
      _isAnimating = true;
      _isSwiping = true;
    });
    _animController.forward(from: 0);
    if (swipeRight) {
      HapticFeedback.mediumImpact();
      widget.onSwipeRight(widget.profiles[_currentIndex]);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _snapBack() {
    _animStart = _dragOffset;
    _animEnd = Offset.zero;
    setState(() => _isAnimating = true);
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, widget.profiles.length);
    if (safeIndex >= widget.profiles.length) {
      return _EndOfCards(onRefresh: widget.onRefresh);
    }

    final profile = widget.profiles[safeIndex];
    final nextProfile = safeIndex + 1 < widget.profiles.length ? widget.profiles[safeIndex + 1] : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final swipeProgress = (_dragOffset.dx / screenWidth).clamp(-1.0, 1.0);
    final rotation = swipeProgress * 0.14;
    final likeOpacity = swipeProgress > 0 ? swipeProgress.clamp(0.0, 1.0) : 0.0;
    final nopeOpacity = swipeProgress < 0 ? (-swipeProgress).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Card stack
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background card (next profile peeking)
              if (nextProfile != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Transform.scale(
                      scale: 0.95,
                      alignment: Alignment.bottomCenter,
                      child: _SwipeCard(
                        profile: nextProfile,
                        likeOpacity: 0,
                        nopeOpacity: 0,
                      ),
                    ),
                  ),
                ),
              // Foreground card (draggable)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Transform.translate(
                      offset: _dragOffset,
                      child: Transform.rotate(
                        angle: rotation,
                        child: _SwipeCard(
                          profile: profile,
                          likeOpacity: likeOpacity,
                          nopeOpacity: nopeOpacity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Card counter
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            '${safeIndex + 1} / ${widget.profiles.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionBtn(
                icon: Icons.close_rounded,
                color: const Color(0xFFFF6B6B),
                size: 58,
                onTap: () => _commitSwipe(false),
              ),
              _ActionBtn(
                icon: Icons.info_outline_rounded,
                color: Colors.blue.shade400,
                size: 46,
                onTap: () => widget.onDetails(profile),
              ),
              _ActionBtn(
                icon: Icons.favorite_rounded,
                color: const Color(0xFF4CAF50),
                size: 58,
                onTap: () => _commitSwipe(true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Swipe Card ──────────────────────────────────────────────────────────────

class _SwipeCard extends StatelessWidget {
  final MatingProfile profile;
  final double likeOpacity;
  final double nopeOpacity;

  const _SwipeCard({
    required this.profile,
    required this.likeOpacity,
    required this.nopeOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pet photo
            profile.primaryImageUrl.isNotEmpty
                ? Image.network(
                    profile.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _CardImagePlaceholder(),
                  )
                : const _CardImagePlaceholder(),

            // Bottom gradient + pet info
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${profile.name}, ${profile.formattedAge}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile.gender,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.pets, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.breed,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.distanceKmRounded} km',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Score badge (top-right)
            if (profile.score > 0)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _scoreColor(profile.score).withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${profile.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Vaccinated badge (top-left)
            if (profile.isVaccinated)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 3),
                      Text(
                        'Aşılı',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // LIKE stamp
            if (likeOpacity > 0.05)
              Positioned(
                top: 48,
                left: 20,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF4CAF50), width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // NOPE stamp
            if (nopeOpacity > 0.05)
              Positioned(
                top: 48,
                right: 20,
                child: Opacity(
                  opacity: nopeOpacity,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF6B6B), width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NOPE',
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardImagePlaceholder extends StatelessWidget {
  const _CardImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 80,
          color: AppPalette.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Icon(icon, color: color, size: size * 0.46),
      ),
    );
  }
}

// ─── End of Cards ─────────────────────────────────────────────────────────────

class _EndOfCards extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EndOfCards({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Hepsi bu kadar!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Yakınında başka profil bulunamadı.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 60, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Filtreleri gevşetmeyi deneyin',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Yakınında henüz uygun eşleşme bulunamadı.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

Color _scoreColor(int score) {
  if (score >= 70) return const Color(0xFF4CAF50);
  if (score >= 40) return const Color(0xFFFFA726);
  return const Color(0xFF78909C);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Bir sorun oluştu',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
