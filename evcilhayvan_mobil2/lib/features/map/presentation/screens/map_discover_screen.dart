import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
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
      final repo = ref.read(petsRepositoryProvider);
      final pets = await repo.getPets(
        advertType: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      final markers = <Marker>{};

      // My location marker
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Buradasin'),
      ));

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
            snippet: isMating ? 'Eslestirme Ilani → Detay icin dokun' : 'Sahiplendirme Ilani → Detay icin dokun',
            onTap: () => context.pushNamed('pet-detail', pathParameters: {'id': petId}),
          ),
        ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritada Kesfe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
                              color: isSelected ? Colors.white : Colors.black87),
                          const SizedBox(width: 4),
                          Text(f['label'] as String,
                              style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF6C63FF),
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
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
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
                  _LegendItem(color: Colors.blue, label: 'Konumun'),
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
