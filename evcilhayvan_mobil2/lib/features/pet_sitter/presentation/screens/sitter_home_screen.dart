import 'dart:async';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
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
  String? _selectedSpecies;
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

  List<Map<String, String?>> _getSpecies(AppLocalizations l10n) => [
    {'value': null, 'label': l10n.filterAll},
    {'value': 'dog', 'label': l10n.sitterSpeciesDog},
    {'value': 'cat', 'label': l10n.sitterSpeciesCat},
    {'value': 'bird', 'label': l10n.sitterSpeciesBird},
    {'value': 'rabbit', 'label': l10n.sitterSpeciesRabbit},
    {'value': 'other', 'label': l10n.sitterSpeciesOther},
  ];

  IconData _getServiceIcon(String? value) {
    switch (value) {
      case 'walking':
        return Icons.directions_walk;
      case 'home_sitting':
        return Icons.home;
      case 'boarding':
        return Icons.hotel;
      case 'daycare':
        return Icons.wb_sunny;
      case 'grooming':
        return Icons.content_cut;
      default:
        return Icons.apps;
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      final data = await repo.listSitters(
        lat: _lat,
        lng: _lng,
        service: _selectedService,
        species: _selectedSpecies,
      );
      setState(() {
        _sitters = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _buildFab(BuildContext context, AppLocalizations l10n) {
    final myProfile = ref.watch(mySitterProfileProvider);
    final existing = myProfile.valueOrNull;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF52B788).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('become-sitter', extra: existing),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: Icon(existing != null ? Icons.edit : Icons.add),
        label: Text(
          existing != null
              ? l10n.sitterEditProfile
              : l10n.sitterBecomeSitterBtn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);
    final services = _getServices(l10n);
    final species = _getSpecies(l10n);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.sitterFindTitle),
        backgroundColor: AppPalette.appBarDark,
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Service filters
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, i) {
                    final s = services[i];
                    final value = s['value'] as String?;
                    final selected = _selectedService == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InteractiveScale(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedService = value);
                            _load();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF2D6A4F)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF2D6A4F)
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2D6A4F,
                                        ).withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getServiceIcon(value),
                                  size: 18,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF2D6A4F),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s['label']! as String,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF2D6A4F),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: species.length,
                  itemBuilder: (context, i) {
                    final s = species[i];
                    final value = s['value'];
                    final selected = _selectedSpecies == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s['label'] ?? ''),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedSpecies = value);
                          _load();
                        },
                        selectedColor: const Color(
                          0xFF2D6A4F,
                        ).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF2D6A4F),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF2D6A4F) : null,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),
              ),
              // List
              Expanded(
                child: _loading
                    ? const Center(child: PawLoading())
                    : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _sitters == null || _sitters!.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            AnimatedEmptyState(
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
                          itemBuilder: (context, i) =>
                              SitterCard(
                                    sitter: _sitters![i],
                                    onTap: () => context.pushNamed(
                                      'sitter-detail',
                                      pathParameters: {'id': _sitters![i].id},
                                    ),
                                  )
                                  .animate(
                                    delay: Duration(milliseconds: i * 60),
                                  )
                                  .fadeIn(duration: 280.ms)
                                  .slideY(begin: 0.05),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: user != null ? _buildFab(context, l10n) : null,
    );
  }
}
