// lib/features/pet_sitter/presentation/screens/live_tracking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/core/socket_service.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/config/app_config.dart';
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
  GoogleMapController? _mapController;
  LatLng? _sitterPosition;
  final List<LatLng> _path = [];
  StreamSubscription<SitterLocationEvent>? _locationSub;
  StreamSubscription<SitterWalkEvent>? _walkSub;
  StreamSubscription<SitterLocationOfflineEvent>? _offlineSub;
  bool _walkActive = false;
  bool _walkEnded = false;
  DateTime? _walkStartTime;

  // Offline / grace period (pet owner tarafı)
  bool _locationOffline = false;
  LatLng? _lastKnownPosition;
  DateTime? _lastLocationTime;
  Timer? _graceTimer;       // 60s countdown
  int _graceSecondsLeft = 60;
  DateTime? _lastLocationReceived;

  // Sitter mode — GPS
  StreamSubscription<Position>? _gpsSub;
  Timer? _gpsTimer;
  bool _isUploading = false;

  // Walk updates (photos from API)
  final List<Map<String, dynamic>> _updates = [];

  static const _initialZoom = 15.0;
  static const _defaultLatLng = LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    _loadUpdates();
    if (widget.isSitter) {
      _initSitterMode();
    } else {
      _subscribeToSocket();
    }
  }

  Future<void> _loadUpdates() async {
    try {
      final res = await ApiClient().dio.get('/api/sitter-bookings/${widget.booking.id}/updates');
      final list = (res.data['updates'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _updates.clear();
          _updates.addAll(list.cast<Map<String, dynamic>>());
          // Harita üzerinde path oluştur
          for (final u in _updates) {
            if (u['type'] == 'location') {
              final coords = u['coordinates'] as List?;
              if (coords != null && coords.length == 2) {
                _path.add(LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()));
              }
            }
            if (u['type'] == 'walk_started') {
              _walkActive = true;
              _walkStartTime = DateTime.tryParse(u['timestamp']?.toString() ?? '');
            }
            if (u['type'] == 'walk_ended') {
              _walkActive = false;
              _walkEnded = true;
            }
          }
          if (_path.isNotEmpty) _sitterPosition = _path.last;
        });
      }
    } catch (_) {}
  }

  void _initSitterMode() {
    // Sitter modu: GPS stream başlatmayı kullanıcı "Geziye Başla"'ya basınca yaparız
  }

  void _subscribeToSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.joinBookingRoom(widget.booking.id);

    _locationSub = socketService.onSitterLocation.listen((event) {
      if (event.bookingId != widget.booking.id) return;
      final pos = LatLng(event.lat, event.lng);
      if (mounted) {
        setState(() {
          _sitterPosition = pos;
          _lastKnownPosition = pos;
          _lastLocationReceived = DateTime.now();
          _lastLocationTime = DateTime.now();
          _path.add(pos);
          // Konum geldi — offline durumu sıfırla
          if (_locationOffline) {
            _locationOffline = false;
            _graceTimer?.cancel();
            _graceTimer = null;
          }
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
        // Grace period varsa iptal et
        _graceTimer?.cancel();
        _graceTimer = null;
      }
    });

    _walkSub = socketService.onSitterWalk.listen((event) {
      if (event.bookingId != widget.booking.id) return;
      if (mounted) setState(() {
        _walkActive = event.started;
        if (event.started) _walkStartTime = DateTime.now();
        if (!event.started) _walkEnded = true;
      });
    });

    // Backend'den 60s grace period tamamlanınca gelen event
    _offlineSub = socketService.onSitterLocationOffline.listen((event) {
      if (event.bookingId != widget.booking.id) return;
      if (mounted) {
        setState(() {
          _locationOffline = true;
          _graceTimer?.cancel();
          _graceTimer = null;
          if (event.lastLat != null && event.lastLng != null) {
            _lastKnownPosition = LatLng(event.lastLat!, event.lastLng!);
          }
          _lastLocationTime = event.lastUpdated;
        });
        _showOfflineDialog(event);
      }
    });
  }

  void _showOfflineDialog(SitterLocationOfflineEvent event) {
    if (!mounted) return;
    final timeStr = event.lastUpdated != null
        ? '${event.lastUpdated!.hour.toString().padLeft(2,'0')}:${event.lastUpdated!.minute.toString().padLeft(2,'0')}'
        : 'bilinmiyor';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Konum Kesildi', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          'Bakıcının konum paylaşımı durdu.\n\n'
          'Son konum alınma saati: $timeStr\n'
          'Haritada son bilinen konumu göstermeye devam ediyoruz.',
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

  Future<void> _startWalk() async {
    try {
      // GPS izni
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _showSnack('Konum izni gerekli');
        return;
      }

      await _postUpdate({'type': 'walk_started'});

      // GPS stream başlat
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) {
        _onGpsUpdate(pos);
      });

      if (mounted) setState(() {
        _walkActive = true;
        _walkStartTime = DateTime.now();
      });
    } catch (e) {
      _showSnack('Gezi başlatılamadı: $e');
    }
  }

  void _onGpsUpdate(Position pos) {
    final latlng = LatLng(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _sitterPosition = latlng;
        _path.add(latlng);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(latlng));
    }
    // API'ye konum gönder
    _postUpdate({
      'type': 'location',
      'coordinates': [pos.longitude, pos.latitude],
    });
    // Socket.io ile de ilet
    final socket = ref.read(socketServiceProvider);
    socket.emitSitterLocation(widget.booking.id, pos.latitude, pos.longitude);
  }

  Future<void> _endWalk() async {
    _gpsSub?.cancel();
    _gpsTimer?.cancel();
    await _postUpdate({'type': 'walk_ended'});
    // Status güncelle
    try {
      await ApiClient().dio.patch('/api/sitter-bookings/${widget.booking.id}/status', data: {'status': 'completed'});
    } catch (_) {}
    if (mounted) setState(() {
      _walkActive = false;
      _walkEnded = true;
    });
  }

  Future<void> _pickAndSendPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(file.path, filename: 'walk_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      });
      final res = await ApiClient().dio.post(
        '/api/sitter-bookings/${widget.booking.id}/upload-photo',
        data: formData,
      );
      final photoUrl = res.data['photoUrl']?.toString();
      if (photoUrl != null) {
        await _postUpdate({'type': 'photo', 'photoUrl': photoUrl});
      }
    } catch (e) {
      _showSnack('Fotoğraf gönderilemedi: $e');
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
      final update = res.data['update'] as Map<String, dynamic>?;
      if (update != null && mounted) {
        setState(() => _updates.add(update));
      }
    } catch (_) {}
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _walkSub?.cancel();
    _offlineSub?.cancel();
    _gpsSub?.cancel();
    _gpsTimer?.cancel();
    _graceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Offline durumda son bilinen konumu göster
    final displayPos = _sitterPosition ?? _lastKnownPosition;
    final initialPos = displayPos ?? _defaultLatLng;
    final markers = <Marker>{};
    if (displayPos != null) {
      // Canlıysa yeşil, offline ise turuncu marker
      final markerHue = _locationOffline
          ? BitmapDescriptor.hueOrange
          : BitmapDescriptor.hueGreen;
      final snippetText = _locationOffline
          ? 'Son bilinen konum'
          : 'Bakıcı konumu';
      markers.add(Marker(
        markerId: const MarkerId('sitter'),
        position: displayPos,
        infoWindow: InfoWindow(title: widget.booking.sitterName ?? 'Bakıcı', snippet: snippetText),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
      ));
    }

    final polylines = _path.length > 1
        ? {Polyline(
            polylineId: const PolylineId('path'),
            points: _path,
            color: const Color(0xFF52B788),
            width: 4,
          )}
        : <Polyline>{};

    // Fotoğraflar — sadece photo type updates
    final photos = _updates.where((u) => u['type'] == 'photo' && u['photoUrl'] != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSitter ? 'Gezi Kontrolü' : '${widget.booking.sitterName ?? 'Bakıcı'} — Canlı Konum'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: _initialZoom),
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Status banner
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _walkEnded
                    ? Colors.grey.shade800
                    : _walkActive ? const Color(0xFF2D6A4F) : Colors.orange.shade800,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Icon(
                    _walkEnded ? Icons.check_circle : _walkActive ? Icons.directions_walk : Icons.hourglass_empty,
                    color: Colors.white, size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _walkEnded ? 'Gezi tamamlandı'
                          : _walkActive ? 'Gezi devam ediyor'
                          : 'Gezi henüz başlamadı',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_walkStartTime != null && _walkActive)
                    _ElapsedTimer(startTime: _walkStartTime!),
                ],
              ),
            ),
          ),

          // Offline uyarı banner (pet owner tarafı)
          if (!widget.isSitter && _locationOffline)
            Positioned(
              top: 90, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konum paylaşımı durdu',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          if (_lastLocationTime != null)
                            Text(
                              'Son konum: ${_lastLocationTime!.hour.toString().padLeft(2, '0')}:${_lastLocationTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Fotoğraf listesi (altta)
          if (photos.isNotEmpty)
            Positioned(
              bottom: widget.isSitter ? 120 : 20,
              left: 0, right: 0,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final url = '${AppConfig.current.apiBaseUrl}${photos[i]['photoUrl']}';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            ),

          // Sitter kontrolleri (altta)
          if (widget.isSitter)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: _buildSitterControls(),
            ),

          // Owner: konum bekleniyor (ilk kez konum alınmadıysa)
          if (!widget.isSitter && displayPos == null && !_walkEnded && !_locationOffline)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Bakıcının konumu bekleniyor...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSitterControls() {
    if (_walkEnded) {
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
            Text('Gezi tamamlandı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (!_walkActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startWalk,
          icon: const Icon(Icons.directions_walk),
          label: const Text('Geziye Başla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickAndSendPhoto,
            icon: _isUploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt),
            label: const Text('Fotoğraf'),
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
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Geziyi Bitir'),
                  content: const Text('Geziyi bitirmek istediğinize emin misiniz? Rezervasyon tamamlandı olarak işaretlenecek.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Bitir')),
                  ],
                ),
              );
              if (confirm == true) await _endWalk();
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Bitir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
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
      setState(() => _elapsed = DateTime.now().difference(widget.startTime));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$m:$s', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold));
  }
}
