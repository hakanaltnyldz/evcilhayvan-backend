import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(nearbyAdsProvider.notifier);
    notifier.setLocationLoading(true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        notifier.setError(l10n.nearbyErrLocationService);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        notifier.setError(l10n.nearbyErrPermDeniedForever);
        return;
      }
      if (perm == LocationPermission.denied) {
        notifier.setError(l10n.nearbyErrPermDenied);
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 20));
      }

      notifier.setLocation(pos.latitude, pos.longitude);
    } on TimeoutException {
      notifier.setError(l10n.nearbyErrTimeout);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('denied') || msg.contains('permission')) {
        notifier.setError(l10n.nearbyErrPermRequired);
      } else {
        notifier.setError(l10n.nearbyErrGeneric);
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
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(nearbyAdsProvider);
    final filter = state.filter;
    final activeFilters = filter.activeCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B4332),
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B4332)),
        actionsIconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B4332)),
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
          // Radius selector
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

          // Active filter summary
          if (activeFilters > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Text(l10n.nearbyActiveFilters(activeFilters),
                      style: TextStyle(color: AppPalette.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(nearbyAdsProvider.notifier)
                        .applyFilter(NearbyAdsFilter(radiusKm: filter.radiusKm)),
                    child: Text(l10n.nearbyClearFilters, style: const TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          Expanded(child: _buildBody(state, l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(NearbyAdsState state, AppLocalizations l10n) {
    if (state.locationLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.nearbyLocating),
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
              Icon(Icons.location_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchLocation,
                icon: const Icon(Icons.my_location),
                label: Text(l10n.retry),
              ),
              if (state.error!.contains('servis') || state.error!.contains('ayar') ||
                  state.error!.contains('service') || state.error!.contains('setting'))
                TextButton.icon(
                  onPressed: () => Geolocator.openLocationSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.nearbyOpenLocationSettings),
                ),
              if (state.error!.contains('kalıcı') || state.error!.contains('uygulama') ||
                  state.error!.contains('forever') || state.error!.contains('app'))
                TextButton.icon(
                  onPressed: () => Geolocator.openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.nearbyOpenAppSettings),
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
            Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(l10n.nearbyNoResults, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(nearbyAdsProvider.notifier)
                  .applyFilter(NearbyAdsFilter(radiusKm: 50)),
              child: Text(l10n.nearbyExpandArea),
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
                child: Center(child: Text(l10n.nearbyShown(state.items.length), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
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

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

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
    final l10n = AppLocalizations.of(context)!;

    final speciesList = [
      (l10n.speciesDog, 'dog'),
      (l10n.speciesCat, 'cat'),
      (l10n.speciesBird, 'bird'),
      (l10n.speciesHamster, 'rodent'),
      (l10n.speciesFish, 'fish'),
      (l10n.speciesOther, 'other'),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filterTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() { _advertType = null; _species = null; _vaccinated = null; _breed = null; }),
                child: Text(l10n.filterReset, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const Divider(),

          // Advert type
          Text(l10n.filterAdvertType, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip(l10n.filterAll, null, _advertType, (v) => setState(() => _advertType = v)),
              _chip(l10n.advertTypeAdoption, 'adoption', _advertType, (v) => setState(() => _advertType = v)),
              _chip(l10n.advertTypeMating, 'mating', _advertType, (v) => setState(() => _advertType = v)),
            ],
          ),
          const SizedBox(height: 16),

          // Species
          Text(l10n.filterAnimalType, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip(l10n.filterAll, null, _species, (v) => setState(() { _species = v; _breed = null; })),
              ...speciesList.map((s) => _chip(s.$1, s.$2, _species, (v) => setState(() { _species = v; _breed = null; }))),
            ],
          ),
          const SizedBox(height: 16),

          // Breed (only if species selected)
          if (_species != null && _currentBreeds.isNotEmpty) ...[
            Text(l10n.filterBreed, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(l10n.filterAll, null, _breed, (v) => setState(() => _breed = v)),
                ..._currentBreeds.map((b) => _chip(b, b, _breed, (v) => setState(() => _breed = v))),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Vaccination
          Text(l10n.filterVaccine, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _boolChip(l10n.filterVaccineAny, null),
              _boolChip(l10n.filterVaccinated, true),
              _boolChip(l10n.filterUnvaccinated, false),
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
              child: Text(l10n.filterApply),
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
