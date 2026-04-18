import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/core/socket_service.dart';

import '../../domain/models/sitter_booking_model.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final SitterBookingModel booking;
  final bool isSitter;

  const LiveTrackingScreen({
    super.key,
    required this.booking,
    this.isSitter = false,
  });

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  static const _defaultLatLng = LatLng(41.0082, 28.9784);
  static const _initialZoom = 15.0;

  GoogleMapController? _mapController;
  final List<LatLng> _path = [];
  final List<Map<String, dynamic>> _updates = [];

  LatLng? _currentPosition;
  LatLng? _lastKnownPosition;
  DateTime? _lastLocationTime;

  bool _serviceActive = false;
  bool _serviceCompleted = false;
  DateTime? _serviceStartTime;
  bool _locationOffline = false;
  bool _payoutPaused = false;
  bool _trackingInterruptedLocally = false;
  bool _isUploading = false;
  bool _isBusy = false;

  StreamSubscription<SitterLocationEvent>? _locationSub;
  StreamSubscription<SitterWalkEvent>? _walkSub;
  StreamSubscription<SitterLocationOfflineEvent>? _offlineSub;
  StreamSubscription<Position>? _gpsSub;
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    _serviceActive = widget.booking.isActive;
    _serviceCompleted = widget.booking.isCompleted;
    _payoutPaused = widget.booking.earningsPaused;
    if (widget.booking.lastLat != null && widget.booking.lastLng != null) {
      _currentPosition = LatLng(widget.booking.lastLat!, widget.booking.lastLng!);
      _lastKnownPosition = _currentPosition;
    }
    _lastLocationTime = widget.booking.lastLocationAt;
    _subscribeToSocket();
    _loadUpdates();
    if (widget.isSitter && _serviceActive && !_serviceCompleted) {
      unawaited(_ensureTrackingStreamRunning());
    }
  }

  Future<void> _loadUpdates() async {
    try {
      final res = await ApiClient().dio.get(
        '/api/sitter-bookings/${widget.booking.id}/updates',
      );
      final list = (res.data['updates'] as List?) ?? const [];
      if (!mounted) return;

      final nextUpdates = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final nextPath = <LatLng>[];
      DateTime? startedAt;
      bool active = _serviceActive;
      bool completed = _serviceCompleted;

      for (final update in nextUpdates) {
        final type = update['type']?.toString();
        if (type == 'location') {
          final coords = update['coordinates'] as List?;
          if (coords != null && coords.length == 2) {
            final point = LatLng(
              (coords[1] as num).toDouble(),
              (coords[0] as num).toDouble(),
            );
            nextPath.add(point);
          }
        }
        if (type == 'walk_started') {
          active = true;
          completed = false;
          startedAt = DateTime.tryParse(update['timestamp']?.toString() ?? '');
        }
        if (type == 'walk_ended') {
          active = false;
          completed = true;
        }
      }

      setState(() {
        _updates
          ..clear()
          ..addAll(nextUpdates);
        _path
          ..clear()
          ..addAll(nextPath);
        if (nextPath.isNotEmpty) {
          _currentPosition = nextPath.last;
          _lastKnownPosition = nextPath.last;
        }
        _serviceActive = active;
        _serviceCompleted = completed;
        _serviceStartTime = startedAt ?? _serviceStartTime;
      });
    } catch (_) {}
  }

  void _subscribeToSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.joinBookingRoom(widget.booking.id);

    _locationSub = socketService.onSitterLocation.listen((event) {
      if (event.bookingId != widget.booking.id || !mounted) return;
      final pos = LatLng(event.lat, event.lng);
      setState(() {
        _currentPosition = pos;
        _lastKnownPosition = pos;
        _lastLocationTime = DateTime.now();
        _locationOffline = false;
        _payoutPaused = false;
        _trackingInterruptedLocally = false;
        _path.add(pos);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    });

    _walkSub = socketService.onSitterWalk.listen((event) {
      if (event.bookingId != widget.booking.id || !mounted) return;
      setState(() {
        _serviceActive = event.started;
        _serviceCompleted = !event.started;
        if (event.started) {
          _serviceStartTime ??= DateTime.now();
        }
      });
    });

    _offlineSub = socketService.onSitterLocationOffline.listen((event) {
      if (event.bookingId != widget.booking.id || !mounted) return;
      setState(() {
        _locationOffline = true;
        _payoutPaused = event.payoutPaused;
        if (event.lastLat != null && event.lastLng != null) {
          _lastKnownPosition = LatLng(event.lastLat!, event.lastLng!);
        }
        _lastLocationTime = event.lastUpdated ?? _lastLocationTime;
      });
      if (!widget.isSitter) {
        _showOfflineDialog(event);
      }
    });
  }

  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Konum servisi kapali');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnack('Konum izni gerekli');
      return false;
    }

    return true;
  }

  Future<void> _ensureTrackingStreamRunning() async {
    if (_gpsSub != null) return;
    await _startGpsStream();
  }

  Future<void> _startGpsStream() async {
    final ready = await _ensureLocationReady();
    if (!ready) {
      await _pauseTracking('location_not_available');
      return;
    }

    await _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen(
      (position) => unawaited(_handlePosition(position)),
      onError: (_) => unawaited(_pauseTracking('location_stream_error')),
    );

    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_checkTrackingHealth()),
    );

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      await _handlePosition(current);
    } catch (_) {}
  }

  Future<void> _checkTrackingHealth() async {
    if (!widget.isSitter || !_serviceActive || _serviceCompleted) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final unavailable = !enabled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever;

    if (unavailable) {
      await _pauseTracking(
        enabled ? 'location_permission_denied' : 'location_service_disabled',
      );
      return;
    }

    if (_gpsSub == null) {
      await _startGpsStream();
    }
  }

  Future<void> _pauseTracking(String reason) async {
    if (!_serviceActive || _serviceCompleted || _trackingInterruptedLocally) {
      return;
    }
    _trackingInterruptedLocally = true;
    await _gpsSub?.cancel();
    _gpsSub = null;

    try {
      await ApiClient().dio.patch(
        '/api/sitter-bookings/${widget.booking.id}/tracking',
        data: {
          'active': false,
          'reason': reason,
        },
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _locationOffline = true;
      _payoutPaused = true;
    });
    _showSnack('Konum kesildi. Odeme durduruldu.');
  }

  Future<void> _resumeTrackingIfNeeded() async {
    if (!_trackingInterruptedLocally) return;
    _trackingInterruptedLocally = false;
    try {
      await ApiClient().dio.patch(
        '/api/sitter-bookings/${widget.booking.id}/tracking',
        data: {'active': true},
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _locationOffline = false;
      _payoutPaused = false;
    });
  }

  Future<void> _handlePosition(Position position) async {
    final latLng = LatLng(position.latitude, position.longitude);
    await _resumeTrackingIfNeeded();

    if (!mounted) return;
    setState(() {
      _currentPosition = latLng;
      _lastKnownPosition = latLng;
      _lastLocationTime = DateTime.now();
      _locationOffline = false;
      _path.add(latLng);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

    await _postUpdate({
      'type': 'location',
      'coordinates': [position.longitude, position.latitude],
    });

    ref
        .read(socketServiceProvider)
        .emitSitterLocation(widget.booking.id, position.latitude, position.longitude);
  }

  Future<void> _activateService() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final ready = await _ensureLocationReady();
      if (!ready) {
        await _pauseTracking('location_not_available');
        return;
      }

      await ApiClient().dio.patch(
        '/api/sitter-bookings/${widget.booking.id}/status',
        data: {'status': 'active'},
      );
      await ApiClient().dio.patch(
        '/api/sitter-bookings/${widget.booking.id}/tracking',
        data: {'active': true},
      );
      await _postUpdate({
        'type': 'walk_started',
        'message': 'Kopek teslim alindi',
      });
      await _startGpsStream();

      if (!mounted) return;
      setState(() {
        _serviceActive = true;
        _serviceCompleted = false;
        _locationOffline = false;
        _payoutPaused = false;
        _serviceStartTime ??= DateTime.now();
      });
    } catch (e) {
      _showSnack('Bakim baslatilamadi: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _completeService() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await _gpsSub?.cancel();
      _gpsSub = null;
      _watchdogTimer?.cancel();
      _watchdogTimer = null;

      await _postUpdate({
        'type': 'walk_ended',
        'message': 'Bakim tamamlandi',
      });
      await ApiClient().dio.patch(
        '/api/sitter-bookings/${widget.booking.id}/status',
        data: {'status': 'completed'},
      );

      if (!mounted) return;
      setState(() {
        _serviceActive = false;
        _serviceCompleted = true;
        _locationOffline = false;
        _payoutPaused = false;
      });
    } catch (e) {
      _showSnack('Bakim tamamlanamadi: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickAndSendPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          file.path,
          filename: 'walk_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final res = await ApiClient().dio.post(
        '/api/sitter-bookings/${widget.booking.id}/upload-photo',
        data: formData,
      );
      final photoUrl = res.data['photoUrl']?.toString();
      if (photoUrl != null) {
        await _postUpdate({
          'type': 'photo',
          'photoUrl': photoUrl,
        });
      }
    } catch (e) {
      _showSnack('Fotograf gonderilemedi: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _postUpdate(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient().dio.post(
        '/api/sitter-bookings/${widget.booking.id}/updates',
        data: data,
      );
      final update = res.data['update'];
      if (update is Map && mounted) {
        setState(() {
          _updates.add(Map<String, dynamic>.from(update));
        });
      }
    } catch (_) {}
  }

  void _showOfflineDialog(SitterLocationOfflineEvent event) {
    if (!mounted) return;
    final timeStr = event.lastUpdated != null
        ? '${event.lastUpdated!.hour.toString().padLeft(2, '0')}:${event.lastUpdated!.minute.toString().padLeft(2, '0')}'
        : 'bilinmiyor';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konum Kesildi'),
        content: Text(
          event.payoutPaused
              ? 'Bakicinin konumu 1 dakikadir alinamiyor.\nSon gorulen saat: $timeStr\nOdeme durduruldu ve son konum gosteriliyor.'
              : 'Bakicinin konumu gecici olarak alinamiyor.\nSon gorulen saat: $timeStr',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _walkSub?.cancel();
    _offlineSub?.cancel();
    _gpsSub?.cancel();
    _watchdogTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackedPosition = _currentPosition ?? _lastKnownPosition;
    final initialPos = trackedPosition ?? _defaultLatLng;
    final photoUpdates = _updates
        .where((u) => u['type'] == 'photo' && u['photoUrl'] != null)
        .toList();

    final markers = <Marker>{};
    if (trackedPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('sitter'),
          position: trackedPosition,
          infoWindow: InfoWindow(
            title: widget.booking.sitterName ?? 'Bakici',
            snippet: _locationOffline ? 'Son gorulen konum' : 'Canli konum',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _locationOffline
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    final polylines = _path.length > 1
        ? {
            Polyline(
              polylineId: const PolylineId('tracking_path'),
              points: _path,
              color: const Color(0xFF2D6A4F),
              width: 4,
            ),
          }
        : <Polyline>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSitter
              ? 'Bakim Takibi'
              : '${widget.booking.sitterName ?? 'Bakici'} - Canli Konum',
        ),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPos,
              zoom: _initialZoom,
            ),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: widget.isSitter,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _StatusBanner(
              isActive: _serviceActive,
              isCompleted: _serviceCompleted,
              isOffline: _locationOffline,
              isSitter: widget.isSitter,
              payoutPaused: _payoutPaused,
              startTime: _serviceStartTime,
            ),
          ),
          if (_locationOffline)
            Positioned(
              top: 92,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _lastLocationTime != null
                      ? 'Son konum: ${_lastLocationTime!.hour.toString().padLeft(2, '0')}:${_lastLocationTime!.minute.toString().padLeft(2, '0')}'
                      : 'Son konum bilgisi bekleniyor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (photoUpdates.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.isSitter ? 132 : 20,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: photoUpdates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final rawUrl = photoUpdates[index]['photoUrl']?.toString() ?? '';
                    final url = rawUrl.startsWith('http')
                        ? rawUrl
                        : '$apiBaseUrl$rawUrl';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (!widget.isSitter &&
              trackedPosition == null &&
              !_serviceCompleted &&
              !_locationOffline)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Bakicinin konumu bekleniyor...'),
                  ],
                ),
              ),
            ),
          if (widget.isSitter)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildSitterControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildSitterControls() {
    if (_serviceCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text(
              'Bakim tamamlandi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (!_serviceActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isBusy ? null : _activateService,
          icon: _isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.pets),
          label: const Text(
            'Kopegi Teslim Aldim',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_payoutPaused)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: const Text(
              'Konum kapandi. Odeme durdu. Konum geri gelince sistem devam eder.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndSendPhoto,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt),
                label: const Text('Fotograf'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52B788),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isBusy
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Bakimi Bitir'),
                            content: const Text(
                              'Bakim tamamlandiginda canli konum kapanacak ve rezervasyon tamamlanacak. Devam edilsin mi?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Iptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Bitir'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _completeService();
                        }
                      },
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.stop_circle_outlined),
                label: const Text('Bakimi Bitir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final bool isOffline;
  final bool isSitter;
  final bool payoutPaused;
  final DateTime? startTime;

  const _StatusBanner({
    required this.isActive,
    required this.isCompleted,
    required this.isOffline,
    required this.isSitter,
    required this.payoutPaused,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCompleted
        ? Colors.grey.shade800
        : isActive
            ? const Color(0xFF2D6A4F)
            : Colors.orange.shade800;

    final title = isCompleted
        ? 'Bakim tamamlandi'
        : isActive
            ? (isSitter ? 'Bakim aktif, canli konum acik' : 'Bakici kopegi teslim aldi')
            : 'Teslim alma bekleniyor';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : isActive
                    ? Icons.location_on
                    : Icons.hourglass_empty,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isOffline || payoutPaused)
                  const Text(
                    'Konum kesildi, odeme durdu',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (startTime != null && isActive) _ElapsedTimer(startTime: startTime!),
        ],
      ),
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  final DateTime startTime;

  const _ElapsedTimer({required this.startTime});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$hours:$minutes:$seconds',
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
    );
  }
}
