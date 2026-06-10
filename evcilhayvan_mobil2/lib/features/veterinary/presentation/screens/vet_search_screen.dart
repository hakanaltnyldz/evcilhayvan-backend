import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/veterinary_model.dart';
import '../widgets/vet_card.dart';

class VetSearchScreen extends ConsumerStatefulWidget {
  final bool nearMe;
  final bool googleSearch;

  const VetSearchScreen({
    super.key,
    this.nearMe = false,
    this.googleSearch = false,
  });

  @override
  ConsumerState<VetSearchScreen> createState() => _VetSearchScreenState();
}

enum _SortMode { distance, rating }

class _VetSearchScreenState extends ConsumerState<VetSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  double? _lat;
  double? _lng;
  double _radiusKm = kDefaultVetRadiusKm;
  bool _locationLoading = false;
  List<VeterinaryModel>? _results;
  bool _loading = false;
  String? _error;
  _SortMode _sortMode = _SortMode.distance;
  String? _selectedSpecies;
  String? _selectedService;

  static const _speciesOptions = [
    ('dog', 'Kopek'),
    ('cat', 'Kedi'),
    ('bird', 'Kus'),
    ('fish', 'Balik'),
    ('rodent', 'Kemirgen'),
    ('other', 'Diger'),
  ];

  static const _serviceOptions = [
    ('exam', 'Muayene'),
    ('vaccination', 'Asi'),
    ('surgery', 'Cerrahi'),
    ('emergency_care', 'Acil'),
    ('laboratory', 'Laboratuvar'),
    ('dental_care', 'Dis'),
    ('checkup', 'Check-up'),
    ('online_consultation', 'Online'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.nearMe || widget.googleSearch) {
      _fetchLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context)!.vetSearchErrPermission;
            _locationLoading = false;
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      setState(() => _locationLoading = false);
      _doSearch();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(
            context,
          )!.vetSearchErrLocation(e.toString());
          _locationLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (text.trim() != _query) {
        _query = text.trim();
        _doSearch();
      }
    });
  }

  Future<void> _doSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(veterinaryRepositoryProvider);

      List<VeterinaryModel> results;
      // Konum varsa ve text query yoksa → Google Places (gerçek klinikler)
      // Text query varsa → DB text search
      final hasFilters = _selectedSpecies != null || _selectedService != null;
      if ((widget.googleSearch || widget.nearMe) &&
          _lat != null &&
          _lng != null &&
          _query.isEmpty &&
          !hasFilters) {
        results = await repo.googleSearch(lat: _lat!, lng: _lng!);
        // Google API anahtarı yoksa veya sonuç boşsa → DB aramasına düş
        if (results.isEmpty) {
          results = await repo.searchVets(lat: _lat, lng: _lng);
        }
      } else {
        results = await repo.searchVets(
          lat: _lat,
          lng: _lng,
          radiusKm: _radiusKm,
          query: _query.isEmpty ? null : _query,
          species: _selectedSpecies,
          service: _selectedService,
        );
      }
      _applySort(results);
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applySort(List<VeterinaryModel> list) {
    if (_sortMode == _SortMode.rating) {
      list.sort((a, b) => (b.googleRating ?? 0).compareTo(a.googleRating ?? 0));
    } else {
      if (_lat != null && _lng != null) {
        list.sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
      }
    }
  }

  void _changeSort(_SortMode mode) {
    setState(() {
      _sortMode = mode;
      if (_results != null) _applySort(_results!);
    });
  }

  double _distanceKm(VeterinaryModel vet) {
    if (_lat == null ||
        _lng == null ||
        vet.latitude == null ||
        vet.longitude == null)
      return double.infinity;
    const r = 6371.0;
    final dLat = (vet.latitude! - _lat!) * pi / 180;
    final dLng = (vet.longitude! - _lng!) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_lat! * pi / 180) *
            cos(vet.latitude! * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.googleSearch ? l10n.vetSearchGoogleTitle : l10n.vetSearchTitle,
        ),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.vetSearchSortTooltip,
            initialValue: _sortMode,
            onSelected: _changeSort,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SortMode.distance,
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 18,
                      color: _sortMode == _SortMode.distance
                          ? const Color(0xFF2D6A4F)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.vetSearchSortByDistance,
                      style: TextStyle(
                        fontWeight: _sortMode == _SortMode.distance
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortMode.rating,
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: _sortMode == _SortMode.rating
                          ? Colors.amber
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.vetSearchSortByRating,
                      style: TextStyle(
                        fontWeight: _sortMode == _SortMode.rating
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (!widget.googleSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.vetSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _query = '';
                            _doSearch();
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          if (!widget.googleSearch) _buildFilterChips(),

          // Konum butonu
          if (_lat == null && !_locationLoading && !widget.googleSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _fetchLocation,
                icon: const Icon(Icons.my_location),
                label: Text(l10n.vetSearchUseLocation),
              ),
            ),

          // Radius chips (konum aktifse göster)
          if (_lat != null && !widget.googleSearch)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [5.0, 10.0, 25.0, 50.0].map((km) {
                  final selected = _radiusKm == km;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${km.toInt()} km'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _radiusKm = km);
                        _doSearch();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          if (_locationLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: PawLoading(size: 36)),
            ),

          // Sonuclar
          Expanded(child: _buildResults(theme)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[
      ChoiceChip(
        label: const Text('Tum turler'),
        selected: _selectedSpecies == null,
        onSelected: (_) {
          setState(() => _selectedSpecies = null);
          _doSearch();
        },
      ),
      ..._speciesOptions.map((item) {
        return ChoiceChip(
          label: Text(item.$2),
          selected: _selectedSpecies == item.$1,
          onSelected: (_) {
            setState(() => _selectedSpecies = item.$1);
            _doSearch();
          },
        );
      }),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text('Tum hizmetler'),
        selected: _selectedService == null,
        onSelected: (_) {
          setState(() => _selectedService = null);
          _doSearch();
        },
      ),
      ..._serviceOptions.map((item) {
        return ChoiceChip(
          label: Text(item.$2),
          selected: _selectedService == item.$1,
          onSelected: (_) {
            setState(() => _selectedService = item.$1);
            _doSearch();
          },
        );
      }),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return PawLoading.fullScreen();
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_results == null) {
      return Center(
        child: Text(
          l10n.vetSearchPrompt,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    if (_results!.isEmpty) {
      return Center(
        child: Text(l10n.vetSearchNoResults, style: theme.textTheme.bodyLarge),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final vet = _results![index];
        final dist = _distanceKm(vet);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child:
              VetCard(
                    vet: vet,
                    distanceKm: dist.isFinite ? dist : null,
                    onTap: () => context.pushNamed(
                      'vet-detail',
                      pathParameters: {'id': vet.id},
                    ),
                  )
                  .animate(delay: (index * 55).ms)
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.06),
        );
      },
    );
  }
}
