import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';

/// Konum seçiminin sonucunu taşır.
class LocationPickerResult {
  final LatLng latLng;
  final String? address;
  final String? note;

  const LocationPickerResult({
    required this.latLng,
    this.address,
    this.note,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;
  final String? initialNote;

  const LocationPickerScreen({
    super.key,
    this.initialPosition,
    this.initialAddress,
    this.initialNote,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(41.0082, 28.9784); // İstanbul

  GoogleMapController? _mapController;
  LatLng _selectedPosition = _defaultCenter;
  String? _address;
  bool _loadingAddress = false;
  bool _loadingLocation = false;

  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'User-Agent': 'EvcilHayvanApp/1.0 (contact@patiarkadasi.com)'},
  ));

  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
      _address = widget.initialAddress;
      _noteController.text = widget.initialNote ?? '';
      if (_address == null) {
        _reverseGeocode(_selectedPosition);
      }
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _noteController.dispose();
    _dio.close();
    super.dispose();
  }

  // ─── Konum al ───────────────────────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum servisi kapalı. Lütfen açın.')),
          );
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni reddedildi.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        final latlng = LatLng(pos.latitude, pos.longitude);
        setState(() => _selectedPosition = latlng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 15));
        await _reverseGeocode(latlng);
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı, haritadan manuel seçin.')),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ─── Ters geocoding (koordinat → adres) ─────────────────────────────────────

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _loadingAddress = true);
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': pos.latitude,
          'lon': pos.longitude,
          'format': 'json',
          'accept-language': 'tr',
          'addressdetails': 1,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() => _address = _formatAddress(data));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  String _formatAddress(Map<String, dynamic> data) {
    final addr = data['address'] as Map<String, dynamic>?;
    if (addr == null) return data['display_name'] as String? ?? '';

    final parts = <String>[];
    final road = addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? addr['street'];
    final neighbourhood = addr['neighbourhood'] ?? addr['suburb'] ?? addr['quarter'];
    final district = addr['district'] ?? addr['city_district'] ?? addr['county'];
    final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['state'];

    if (road != null) parts.add(road as String);
    if (neighbourhood != null) parts.add(neighbourhood as String);
    if (district != null) parts.add(district as String);
    if (city != null) parts.add(city as String);

    return parts.isNotEmpty ? parts.join(', ') : (data['display_name'] as String? ?? '');
  }

  // ─── Adres arama (Nominatim forward) ─────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() => _showSearchResults = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'countrycodes': 'tr',
          'accept-language': 'tr',
        },
      );
      final results = (response.data as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'] as String? ?? '') ?? 0;
    final lon = double.tryParse(result['lon'] as String? ?? '') ?? 0;
    final latlng = LatLng(lat, lon);
    final name = result['display_name'] as String? ?? '';

    setState(() {
      _selectedPosition = latlng;
      _address = name;
      _showSearchResults = false;
      _searchController.clear();
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 15));
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(LatLng latlng) {
    setState(() {
      _selectedPosition = latlng;
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
    _reverseGeocode(latlng);
  }

  void _onMarkerDragEnd(LatLng latlng) {
    setState(() => _selectedPosition = latlng);
    _reverseGeocode(latlng);
  }

  void _confirm() {
    Navigator.of(context).pop(LocationPickerResult(
      latLng: _selectedPosition,
      address: _address,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    ));
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Harita
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selectedPosition, zoom: 14),
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition,
                draggable: true,
                onDragEnd: _onMarkerDragEnd,
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(bottom: 260),
          ),

          // Üst: geri + arama
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _circleBtn(Icons.arrow_back, () => Navigator.of(context).pop()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Adres veya mahalle ara...',
                              prefixIcon: Icon(Icons.search, color: AppPalette.primary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arama sonuçları
                if (_showSearchResults)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 4, 12, 0),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: _searchResults.map((r) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, color: AppPalette.primary, size: 20),
                            title: Text(
                              r['display_name'] as String? ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () => _selectSearchResult(r),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Konumumu kullan FAB
          Positioned(
            right: 16,
            bottom: 280,
            child: _circleBtn(
              Icons.my_location,
              _getCurrentLocation,
              loading: _loadingLocation,
            ),
          ),

          // Alt panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(
              address: _address,
              loadingAddress: _loadingAddress,
              noteController: _noteController,
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool loading = false}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppPalette.primary),
      ),
    );
  }
}

// ─── Alt Panel ────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final String? address;
  final bool loadingAddress;
  final TextEditingController noteController;
  final VoidCallback onConfirm;

  const _BottomPanel({
    required this.address,
    required this.loadingAddress,
    required this.noteController,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Adres satırı
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_pin, color: AppPalette.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: loadingAddress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        address ?? 'Konum seçmek için haritaya dokunun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: address != null ? Colors.black87 : Colors.grey,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Adres notu
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: 'Adres notu (isteğe bağlı)',
              hintText: 'Daire no, kat, kapı rengi...',
              prefixIcon: const Icon(Icons.edit_location_alt_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 14),

          // Onayla
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Bu Konumu Kullan', style: TextStyle(fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
