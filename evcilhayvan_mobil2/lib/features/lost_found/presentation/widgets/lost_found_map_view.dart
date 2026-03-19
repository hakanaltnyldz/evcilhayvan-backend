import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/models/lost_found_model.dart';

class LostFoundMapView extends StatefulWidget {
  final List<LostFoundPet> reports;
  final double? userLat;
  final double? userLng;
  final void Function(LostFoundPet report)? onMarkerTap;

  const LostFoundMapView({
    super.key,
    required this.reports,
    this.userLat,
    this.userLng,
    this.onMarkerTap,
  });

  @override
  State<LostFoundMapView> createState() => _LostFoundMapViewState();
}

class _LostFoundMapViewState extends State<LostFoundMapView> {
  GoogleMapController? _controller;

  LatLng get _initialPosition {
    if (widget.userLat != null && widget.userLng != null) {
      return LatLng(widget.userLat!, widget.userLng!);
    }
    // Istanbul default
    return const LatLng(41.0082, 28.9784);
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final report in widget.reports) {
      if (report.latitude == null || report.longitude == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(report.id),
          position: LatLng(report.latitude!, report.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            report.isLost ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: report.petName ?? '${report.speciesLabel} (${report.color})',
            snippet: report.isLost ? 'Kayip - ${report.lastSeenAddress ?? ""}' : 'Bulunan - ${report.lastSeenAddress ?? ""}',
            onTap: () => widget.onMarkerTap?.call(report),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 12,
      ),
      markers: _buildMarkers(),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _controller = controller;
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
