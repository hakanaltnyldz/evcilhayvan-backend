import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';

class MapDiscoverScreen extends ConsumerStatefulWidget {
  const MapDiscoverScreen({super.key});

  @override
  ConsumerState<MapDiscoverScreen> createState() => _MapDiscoverScreenState();
}

class _MapDiscoverScreenState extends ConsumerState<MapDiscoverScreen> {
  GoogleMapController? _mapCtrl;
  LatLng _center = const LatLng(41.0082, 28.9784); // Istanbul default
  Set<Marker> _markers = {};
  bool _loadingLocation = false;
  String _selectedFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': 'Tumu', 'icon': Icons.map_outlined},
    {'key': 'adoption', 'label': 'Sahiplendirme', 'icon': Icons.pets},
    {'key': 'mating', 'label': 'Eslestirme', 'icon': Icons.favorite_outline},
    {'key': 'vet', 'label': 'Veteriner', 'icon': Icons.local_hospital_outlined},
    {'key': 'sitter', 'label': 'Bakici', 'icon': Icons.home_outlined},
    {'key': 'lost', 'label': 'Kayip/Bulunan', 'icon': Icons.search_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationAndLoad();
  }

  Future<void> _requestLocationAndLoad() async {
    setState(() => _loadingLocation = true);
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        _center = LatLng(pos.latitude, pos.longitude);
        _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13));
      }
    } catch (_) {}
    await _loadMarkers();
    setState(() => _loadingLocation = false);
  }

  Future<void> _loadMarkers() async {
    try {
      final markers = <Marker>{};

      // My location marker
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Buradasin'),
      ));

      final showPets = _selectedFilter == 'all' ||
          _selectedFilter == 'adoption' ||
          _selectedFilter == 'mating';
      if (showPets) {
        final repo = ref.read(petsRepositoryProvider);
        final petFilter = (_selectedFilter == 'adoption' || _selectedFilter == 'mating')
            ? _selectedFilter
            : null;
        final pets = await repo.getPets(advertType: petFilter);
        for (final pet in pets) {
          if (pet.latitude == null || pet.longitude == null) continue;
          if (pet.latitude == 0 && pet.longitude == 0) continue;
          final isMating = pet.advertType == 'mating';
          final petId = pet.id;
          markers.add(Marker(
            markerId: MarkerId(petId),
            position: LatLng(pet.latitude!, pet.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isMating ? BitmapDescriptor.hueMagenta : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: '${pet.name} (${pet.species})',
              snippet: isMating ? 'Eslestirme → Detay icin dokun' : 'Sahiplendirme → Detay icin dokun',
              onTap: () => context.pushNamed('pet-detail', pathParameters: {'id': petId}),
            ),
          ));
        }
      }

      if (_selectedFilter == 'all' || _selectedFilter == 'vet') {
        await _addVetMarkers(markers);
      }
      if (_selectedFilter == 'all' || _selectedFilter == 'sitter') {
        await _addSitterMarkers(markers);
      }
      if (_selectedFilter == 'all' || _selectedFilter == 'lost') {
        await _addLostFoundMarkers(markers);
      }

      setState(() => _markers = markers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harita yukleme hatasi: $e')),
        );
      }
    }
  }

  Future<void> _addVetMarkers(Set<Marker> markers) async {
    try {
      final res = await ApiClient().dio.get('/api/veterinaries', queryParameters: {
        'lat': _center.latitude,
        'lng': _center.longitude,
        'radiusKm': 15,
      });
      final vets = (res.data['data']['vets'] as List? ?? []);
      for (final v in vets) {
        final lat = (v['location']?['coordinates'] as List?)?.elementAtOrNull(1);
        final lng = (v['location']?['coordinates'] as List?)?.elementAtOrNull(0);
        if (lat == null || lng == null) continue;
        final id = v['_id']?.toString() ?? '';
        final name = v['name']?.toString() ?? 'Veteriner';
        markers.add(Marker(
          markerId: MarkerId('vet_$id'),
          position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: name,
            snippet: 'Veteriner → Detay icin dokun',
            onTap: () => context.pushNamed('vet-detail', pathParameters: {'id': id}),
          ),
        ));
      }
    } catch (_) {}
  }

  Future<void> _addSitterMarkers(Set<Marker> markers) async {
    try {
      final res = await ApiClient().dio.get('/api/pet-sitters', queryParameters: {
        'lat': _center.latitude,
        'lng': _center.longitude,
        'radiusKm': 15,
      });
      final sitters = (res.data['data']['sitters'] as List? ?? []);
      for (final s in sitters) {
        final lat = (s['location']?['coordinates'] as List?)?.elementAtOrNull(1);
        final lng = (s['location']?['coordinates'] as List?)?.elementAtOrNull(0);
        if (lat == null || lng == null) continue;
        final id = s['_id']?.toString() ?? '';
        final name = s['displayName']?.toString() ?? 'Bakici';
        markers.add(Marker(
          markerId: MarkerId('sitter_$id'),
          position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: name,
            snippet: 'Bakici → Detay icin dokun',
            onTap: () => context.pushNamed('sitters'),
          ),
        ));
      }
    } catch (_) {}
  }

  Future<void> _addLostFoundMarkers(Set<Marker> markers) async {
    try {
      final res = await ApiClient().dio.get('/api/lost-found', queryParameters: {
        'lat': _center.latitude,
        'lng': _center.longitude,
      });
      final reports = (res.data['data']['reports'] as List? ?? []);
      for (final r in reports) {
        final lat = (r['location']?['coordinates'] as List?)?.elementAtOrNull(1);
        final lng = (r['location']?['coordinates'] as List?)?.elementAtOrNull(0);
        if (lat == null || lng == null) continue;
        final id = r['_id']?.toString() ?? '';
        final name = r['petName']?.toString() ?? 'Kayip Hayvan';
        final status = r['status']?.toString() ?? 'lost';
        markers.add(Marker(
          markerId: MarkerId('lost_$id'),
          position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: name,
            snippet: status == 'found' ? 'Bulunan → Detay icin dokun' : 'Kayip → Detay icin dokun',
            onTap: () => context.pushNamed('lost-found'),
          ),
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritada Kesfe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Konumuma Don',
            onPressed: () {
              _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _loadMarkers,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (ctrl) {
              _mapCtrl = ctrl;
              _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(_center, 12));
            },
          ),

          // Filter chips at top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f['icon'] as IconData, size: 14,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 4),
                          Text(f['label'] as String,
                              style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF2D6A4F),
                      checkmarkColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black26,
                      onSelected: (_) async {
                        setState(() => _selectedFilter = f['key'] as String);
                        await _loadMarkers();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Loading indicator
          if (_loadingLocation)
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Konum aliniyor...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Legend at bottom
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.06), blurRadius: 12),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(color: Colors.orange, label: 'Sahiplendirme'),
                  const SizedBox(height: 4),
                  _LegendItem(color: Colors.pink, label: 'Eslestirme'),
                  const SizedBox(height: 4),
                  _LegendItem(color: const Color(0xFF2D6A4F), label: 'Konumun'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
