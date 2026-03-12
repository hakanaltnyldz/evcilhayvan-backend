import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/veterinary_model.dart';
import '../widgets/vet_card.dart';

class VetSearchScreen extends ConsumerStatefulWidget {
  final bool nearMe;
  final bool googleSearch;

  const VetSearchScreen({super.key, this.nearMe = false, this.googleSearch = false});

  @override
  ConsumerState<VetSearchScreen> createState() => _VetSearchScreenState();
}

class _VetSearchScreenState extends ConsumerState<VetSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  double? _lat;
  double? _lng;
  bool _locationLoading = false;
  List<VeterinaryModel>? _results;
  bool _loading = false;
  String? _error;

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
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Konum izni gerekli';
          _locationLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _lat = pos.latitude;
      _lng = pos.longitude;
      setState(() => _locationLoading = false);
      _doSearch();
    } catch (e) {
      setState(() {
        _error = 'Konum alinamadi: $e';
        _locationLoading = false;
      });
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
      if ((widget.googleSearch || widget.nearMe) && _lat != null && _lng != null && _query.isEmpty) {
        results = await repo.googleSearch(lat: _lat!, lng: _lng!);
      } else {
        results = await repo.searchVets(
          lat: _lat,
          lng: _lng,
          query: _query.isEmpty ? null : _query,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.googleSearch ? 'Google ile Ara' : 'Veteriner Ara'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  hintText: 'Klinik adi veya adres...',
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
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),

          // Konum butonu
          if (_lat == null && !_locationLoading && !widget.googleSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _fetchLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Konumumu kullan'),
              ),
            ),

          if (_locationLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Sonuclar
          Expanded(
            child: _buildResults(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }
    if (_results == null) {
      return Center(
        child: Text('Aramak icin yukariya yazin veya konumunuzu paylasın',
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
      );
    }
    if (_results!.isEmpty) {
      return Center(child: Text('Sonuc bulunamadi', style: theme.textTheme.bodyLarge));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final vet = _results![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: VetCard(
            vet: vet,
            onTap: () => context.pushNamed('vet-detail', pathParameters: {'id': vet.id}),
          ),
        );
      },
    );
  }
}
