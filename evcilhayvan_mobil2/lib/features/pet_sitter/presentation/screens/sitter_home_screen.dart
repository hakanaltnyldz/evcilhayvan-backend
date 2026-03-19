import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';
import '../widgets/sitter_card.dart';

class SitterHomeScreen extends ConsumerStatefulWidget {
  const SitterHomeScreen({super.key});
  @override
  ConsumerState<SitterHomeScreen> createState() => _SitterHomeScreenState();
}

class _SitterHomeScreenState extends ConsumerState<SitterHomeScreen> {
  double? _lat, _lng;
  String? _selectedService;
  List<PetSitterModel>? _sitters;
  bool _loading = true;
  String? _error;

  final _services = [
    {'value': null, 'label': 'Tumu'},
    {'value': 'walking', 'label': 'Gezdirme'},
    {'value': 'home_sitting', 'label': 'Ev Bakimi'},
    {'value': 'boarding', 'label': 'Pansiyon'},
    {'value': 'daycare', 'label': 'Gunduz Bakimi'},
    {'value': 'grooming', 'label': 'Timar'},
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      final data = await repo.listSitters(lat: _lat, lng: _lng, service: _selectedService);
      setState(() { _sitters = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bakici Bul'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: 'Rezervasyonlarim',
              onPressed: () => context.pushNamed('my-bookings'),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe8f5e9), Color(0xFFF8F9FB)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hizmet filtreleri
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _services.length,
                  itemBuilder: (context, i) {
                    final s = _services[i];
                    final selected = _selectedService == s['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s['label']!),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedService = s['value']);
                          _load();
                        },
                        selectedColor: AppPalette.primary.withOpacity(0.2),
                      ),
                    );
                  },
                ),
              ),
              // Liste
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ErrorView(message: _error!, onRetry: _load)
                        : _sitters == null || _sitters!.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _load,
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 80),
                                    EmptyState(
                                      icon: Icons.home_work_outlined,
                                      title: 'Yakında bakıcı bulunamadı',
                                      subtitle: 'İlk bakıcı profilini oluştur ve diğer kullanıcılara hizmet ver!',
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 4, bottom: 100),
                                  itemCount: _sitters!.length,
                                  itemBuilder: (context, i) => SitterCard(
                                    sitter: _sitters![i],
                                    onTap: () => context.pushNamed('sitter-detail',
                                        pathParameters: {'id': _sitters![i].id}),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed('become-sitter'),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Bakici Ol'),
            )
          : null,
    );
  }
}
