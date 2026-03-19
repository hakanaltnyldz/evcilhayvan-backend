import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/data/pet_breeds.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'widgets/pet_card.dart';

class NearbyAdsScreen extends ConsumerStatefulWidget {
  const NearbyAdsScreen({super.key});

  @override
  ConsumerState<NearbyAdsScreen> createState() => _NearbyAdsScreenState();
}

class _NearbyAdsScreenState extends ConsumerState<NearbyAdsScreen> {
  final _scrollController = ScrollController();

  static const _radii = [5.0, 10.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLocation());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(nearbyAdsProvider.notifier).loadMore();
    }
  }

  Future<void> _fetchLocation() async {
    final notifier = ref.read(nearbyAdsProvider.notifier);
    notifier.setLocationLoading(true);
    try {
      // Konum servisi açık mı?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        notifier.setError('Konum servisi kapalı. Lütfen ayarlardan açın.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        notifier.setError('Konum izni kalıcı olarak reddedildi. Uygulama ayarlarından izin verin.');
        return;
      }
      if (perm == LocationPermission.denied) {
        notifier.setError('Konum izni gerekli. Lütfen tekrar deneyin.');
        return;
      }

      // Önce son bilinen konum — hızlı
      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        // Son bilinmiyorsa gerçek konum al (timeout 20s)
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 20));
      }

      notifier.setLocation(pos.latitude, pos.longitude);
    } on TimeoutException {
      notifier.setError('Konum alınamadı: zaman aşımı. Lütfen tekrar deneyin.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('denied') || msg.contains('permission')) {
        notifier.setError('Konum izni gerekli. Lütfen ayarlardan izin verin.');
      } else {
        notifier.setError('Konum alınamadı. Lütfen tekrar deneyin.');
      }
    }
  }

  void _showFilterSheet() {
    final current = ref.read(nearbyAdsProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        initial: current,
        onApply: (f) => ref.read(nearbyAdsProvider.notifier).applyFilter(f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyAdsProvider);
    final filter = state.filter;
    final activeFilters = filter.activeCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınımdaki İlanlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              child: const Icon(Icons.tune),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Yarıçap seçici
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _radii.map((r) {
                final selected = filter.radiusKm == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${r.toInt()} km'),
                    selected: selected,
                    onSelected: (_) {
                      ref.read(nearbyAdsProvider.notifier)
                          .applyFilter(filter.copyWith(radiusKm: r));
                    },
                    selectedColor: AppPalette.primary.withOpacity(0.15),
                    checkmarkColor: AppPalette.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppPalette.primary : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Aktif filtre özeti
          if (activeFilters > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Text('$activeFilters filtre aktif',
                      style: TextStyle(color: AppPalette.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(nearbyAdsProvider.notifier)
                        .applyFilter(NearbyAdsFilter(radiusKm: filter.radiusKm)), // clears all optional filters
                    child: const Text('Temizle', style: TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(NearbyAdsState state) {
    if (state.locationLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Konum alınıyor...'),
          ],
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Tekrar Dene'),
              ),
              if (state.error!.contains('servis') || state.error!.contains('ayar'))
                TextButton.icon(
                  onPressed: () => Geolocator.openLocationSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Konum Ayarlarını Aç'),
                ),
              if (state.error!.contains('kalıcı') || state.error!.contains('uygulama'))
                TextButton.icon(
                  onPressed: () => Geolocator.openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Uygulama Ayarlarını Aç'),
                ),
            ],
          ),
        ),
      );
    }

    if (state.lat == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Bu bölgede ilan bulunamadı', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(nearbyAdsProvider.notifier)
                  .applyFilter(NearbyAdsFilter(radiusKm: 50)),
              child: const Text('Alanı genişlet (50 km)'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(nearbyAdsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!state.hasMore) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text('${state.items.length} ilan gösterildi', style: const TextStyle(color: Colors.grey))),
              );
            }
            return const SizedBox.shrink();
          }
          final pet = state.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PetCard(
              pet: pet,
              onTap: () => context.pushNamed('pet-detail', pathParameters: {'id': pet.id}),
            ),
          );
        },
      ),
    );
  }
}

// ─── Filtre Bottom Sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final NearbyAdsFilter initial;
  final void Function(NearbyAdsFilter) onApply;

  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _advertType;
  late String? _species;
  late bool? _vaccinated;
  late String? _breed;

  static const _speciesList = [
    ('Köpek',   'dog'),
    ('Kedi',    'cat'),
    ('Kuş',     'bird'),
    ('Hamster', 'rodent'),
    ('Balık',   'fish'),
    ('Diğer',   'other'),
  ];

  List<String> get _currentBreeds {
    if (_species == null) return [];
    return breedsFor(_species!);
  }

  @override
  void initState() {
    super.initState();
    _advertType = widget.initial.advertType;
    _species = widget.initial.species;
    _vaccinated = widget.initial.vaccinated;
    _breed = widget.initial.breed;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtrele', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() { _advertType = null; _species = null; _vaccinated = null; _breed = null; }),
                child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const Divider(),

          // İlan Türü
          const Text('İlan Türü', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('Tümü', null, _advertType, (v) => setState(() => _advertType = v)),
              _chip('Sahiplendirme', 'adoption', _advertType, (v) => setState(() => _advertType = v)),
              _chip('Eşleştirme', 'mating', _advertType, (v) => setState(() => _advertType = v)),
            ],
          ),
          const SizedBox(height: 16),

          // Tür
          const Text('Hayvan Türü', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip('Tümü', null, _species, (v) => setState(() { _species = v; _breed = null; })),
              ..._speciesList.map((s) => _chip(s.$1, s.$2, _species, (v) => setState(() { _species = v; _breed = null; }))),
            ],
          ),
          const SizedBox(height: 16),

          // Cins (sadece tür seçiliyse)
          if (_species != null && _currentBreeds.isNotEmpty) ...[
            const Text('Cins', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip('Tümü', null, _breed, (v) => setState(() => _breed = v)),
                ..._currentBreeds.map((b) => _chip(b, b, _breed, (v) => setState(() => _breed = v))),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Aşılı
          const Text('Aşı Durumu', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _boolChip('Fark Etmez', null),
              _boolChip('Aşılı', true),
              _boolChip('Aşısız', false),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(widget.initial.copyWith(
                  advertType: _advertType,
                  species: _species,
                  vaccinated: _vaccinated,
                  breed: _breed,
                ));
                Navigator.of(context).pop();
              },
              child: const Text('Uygula'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip<T>(String label, T value, T current, void Function(T) onTap) {
    final selected = current == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(value),
      selectedColor: AppPalette.primary.withOpacity(0.15),
      checkmarkColor: AppPalette.primary,
      labelStyle: TextStyle(
        color: selected ? AppPalette.primary : null,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _boolChip(String label, bool? value) {
    final selected = _vaccinated == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _vaccinated = value),
      selectedColor: AppPalette.primary.withOpacity(0.15),
      checkmarkColor: AppPalette.primary,
      labelStyle: TextStyle(
        color: selected ? AppPalette.primary : null,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }
}
