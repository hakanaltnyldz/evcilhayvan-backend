import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';


import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
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

  List<Map<String, Object?>> _getServices(AppLocalizations l10n) => [
    {'value': null, 'label': l10n.sitterServiceAll},
    {'value': 'walking', 'label': l10n.sitterServiceWalking},
    {'value': 'home_sitting', 'label': l10n.sitterServiceHomeSitting},
    {'value': 'boarding', 'label': l10n.sitterServiceBoarding},
    {'value': 'daycare', 'label': l10n.sitterServiceDaycare},
    {'value': 'grooming', 'label': l10n.sitterServiceGrooming},
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
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);
    final services = _getServices(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(l10n.sitterFindTitle),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: l10n.sitterMyBookingsTooltip,
              onPressed: () => context.pushNamed('my-bookings'),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF1B4332), const Color(0xFF121212)]
                : [const Color(0xFFF4FAF6), const Color(0xFFF8F9FB)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Service filters
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: services.length,
                  itemBuilder: (context, i) {
                    final s = services[i];
                    final selected = _selectedService == s['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s['label']! as String),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedService = s['value'] as String?);
                          _load();
                        },
                        selectedColor: const Color(0xFF2D6A4F).withOpacity(0.2),
                      ),
                    );
                  },
                ),
              ),
              // List
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
                                  children: [
                                    const SizedBox(height: 80),
                                    EmptyState(
                                      icon: Icons.home_work_outlined,
                                      title: l10n.sitterEmptyTitle,
                                      subtitle: l10n.sitterEmptySubtitle,
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
              label: Text(l10n.sitterBecomeSitterBtn),
            )
          : null,
    );
  }
}
