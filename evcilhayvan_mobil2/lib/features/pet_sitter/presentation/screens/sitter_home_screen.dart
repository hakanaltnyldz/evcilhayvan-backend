import 'dart:async';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
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

class _SitterHomeScreenState extends ConsumerState<SitterHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    _load(); // Load immediately without waiting for location
    _initLocation(); // Get location in background, reload when available
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        if (mounted) {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _load(); // Reload with location data
        }
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      var data = await repo.listSitters(
        lat: _lat,
        lng: _lng,
        service: _selectedService,
        species: _selectedSpecies,
      );
      // Geo filtresi sonuç vermezse konumsuz tekrar dene
      if (data.isEmpty && (_lat != null || _lng != null)) {
        data = await repo.listSitters(
          service: _selectedService,
          species: _selectedSpecies,
        );
      }
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

  Future<void> _showMyRequests(BuildContext context) async {
    final repo = ref.read(petSitterRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MyRequestsSheet(repo: repo),
    );
  }

  Widget _buildFab(BuildContext context, AppLocalizations l10n) {
    final myProfile = ref.watch(mySitterProfileProvider);
    final existing = myProfile.valueOrNull;

    // Tab 1 (Bakıcı Aranıyor): herkes ilan açabilir
    if (_tabController.index == 1) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42A5F5).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.pushNamed('sitter-request-form'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text('İlan Aç'),
        ),
      );
    }

    // Tab 0 (Bakıcılar): profil düzenle/oluştur
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52B788).withOpacity(0.4),
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

  // Kendi bakıcı profil kartı — verified olsun olmasın göster
  Widget _buildMyProfileCard(BuildContext context, PetSitterModel sitter) {
    final isVerified = sitter.isVerified;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerified
              ? [const Color(0xFF2D6A4F).withOpacity(0.12), const Color(0xFF52B788).withOpacity(0.08)]
              : [const Color(0xFFF57F17).withOpacity(0.10), const Color(0xFFFFCA28).withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? const Color(0xFF52B788).withOpacity(0.4) : const Color(0xFFFFCA28).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isVerified ? const Color(0xFF52B788).withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            backgroundImage: sitter.avatar != null ? NetworkImage(sitter.avatar!) : null,
            child: sitter.avatar == null
                ? Icon(Icons.person, color: isVerified ? const Color(0xFF2D6A4F) : Colors.orange)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bakıcı Profilim',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  sitter.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? const Color(0xFF52B788).withOpacity(0.2) : const Color(0xFFFFCA28).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isVerified ? '✓ Aktif' : '⏳ Onay Bekleniyor',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isVerified ? const Color(0xFF2D6A4F) : const Color(0xFFF57F17),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _buildSittersTab(BuildContext context, AppLocalizations l10n) {
    final services = _getServices(l10n);
    final species = _getSpecies(l10n);
    final myProfile = ref.watch(mySitterProfileProvider);
    final mySitter = myProfile.valueOrNull;

    return Column(
      children: [
        // Kendi profil kartı (varsa)
        if (mySitter != null)
          GestureDetector(
            onTap: () => context.pushNamed('become-sitter', extra: mySitter),
            child: _buildMyProfileCard(context, mySitter),
          ),
        // Service filters
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        color: selected ? const Color(0xFF2D6A4F) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getServiceIcon(value), size: 18, color: selected ? Colors.white : const Color(0xFF2D6A4F)),
                          const SizedBox(width: 6),
                          Text(
                            s['label']! as String,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF2D6A4F),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  selectedColor: const Color(0xFF2D6A4F).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF2D6A4F),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF2D6A4F) : null,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                    itemBuilder: (context, i) => SitterCard(
                      sitter: _sitters![i],
                      onTap: () => context.pushNamed(
                        'sitter-detail',
                        pathParameters: {'id': _sitters![i].id},
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.sitterFindTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (user != null && _tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Kendi İlanlarım',
              onPressed: () => _showMyRequests(context),
            ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: l10n.sitterMyBookingsTooltip,
              onPressed: () => context.pushNamed('sitter-bookings'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}), // FAB güncelleme için
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Bakıcılar'),
            Tab(text: 'Bakıcı Aranıyor'),
          ],
        ),
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
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSittersTab(context, l10n),
              // İlanlar tab'ı — SitterRequestsScreen widget olarak embed et
              _SitterRequestsTabContent(lat: _lat, lng: _lng),
            ],
          ),
        ),
      ),
      floatingActionButton: user != null ? _buildFab(context, l10n) : null,
    );
  }
}

/// İlanlar tab içeriği (inline widget — ayrı route yerine tab'a embed)
class _SitterRequestsTabContent extends ConsumerStatefulWidget {
  final double? lat;
  final double? lng;

  const _SitterRequestsTabContent({this.lat, this.lng});

  @override
  ConsumerState<_SitterRequestsTabContent> createState() => _SitterRequestsTabContentState();
}

class _SitterRequestsTabContentState extends ConsumerState<_SitterRequestsTabContent> {
  List<Map<String, dynamic>>? _requests;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(petSitterRepositoryProvider);
      final data = await repo.listSitterRequests(lat: widget.lat, lng: widget.lng);
      setState(() {
        _requests = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _serviceLabel(String? type) {
    switch (type) {
      case 'walking': return 'Yürüyüş';
      case 'home_sitting': return 'Ev Bakımı';
      case 'boarding': return 'Pansiyon';
      case 'daycare': return 'Günlük Bakım';
      case 'grooming': return 'Tımar';
      default: return type ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: PawLoading());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_requests == null || _requests!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Henüz bakıcı ilanı yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Birisi bakıcı aradığında burada görünecek', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _requests!.length,
        itemBuilder: (context, i) {
          final req = _requests![i];
          final owner = req['owner'] as Map<String, dynamic>?;
          final startDate = req['startDate'] != null ? DateTime.tryParse(req['startDate'].toString()) : null;
          final endDate = req['endDate'] != null ? DateTime.tryParse(req['endDate'].toString()) : null;
          final petTypes = (req['petTypes'] as List?)?.cast<String>() ?? [];
          final serviceType = req['serviceType'] as String?;
          final description = req['description'] as String?;
          final requestId = req['id']?.toString() ?? req['_id']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: owner?['avatarUrl'] != null ? NetworkImage(owner!['avatarUrl']) : null,
                        child: owner?['avatarUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(owner?['name'] ?? 'Kullanıcı', style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (startDate != null && endDate != null)
                              Text(
                                '${startDate.day}.${startDate.month.toString().padLeft(2,'0')}.${startDate.year} — ${endDate.day}.${endDate.month.toString().padLeft(2,'0')}.${endDate.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _serviceLabel(serviceType),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2D6A4F)),
                        ),
                      ),
                    ],
                  ),
                  if (petTypes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: petTypes.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final repo = ref.read(petSitterRepositoryProvider);
                          final convId = await repo.contactSitterRequestOwner(requestId);
                          if (!context.mounted) return;
                          context.pushNamed(
                            'chat',
                            pathParameters: {'conversationId': convId},
                            extra: {
                              'name': owner?['name'] ?? 'Kullanıcı',
                              'avatar': owner?['avatarUrl'],
                            },
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.message_outlined, size: 18),
                      label: const Text('İletişime Geç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 280.ms).slideY(begin: 0.05);
        },
      ),
    );
  }
}

/// Kendi ilanlarımı gösteren bottom sheet
class _MyRequestsSheet extends StatefulWidget {
  final PetSitterRepository repo;
  const _MyRequestsSheet({required this.repo});

  @override
  State<_MyRequestsSheet> createState() => _MyRequestsSheetState();
}

class _MyRequestsSheetState extends State<_MyRequestsSheet> {
  List<Map<String, dynamic>>? _requests;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repo.mySitterRequests();
      if (mounted) setState(() { _requests = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _requests = []; _loading = false; });
    }
  }

  String _serviceLabel(String? type) {
    switch (type) {
      case 'walking': return 'Yürüyüş';
      case 'home_sitting': return 'Ev Bakımı';
      case 'boarding': return 'Pansiyon';
      case 'daycare': return 'Günlük Bakım';
      case 'grooming': return 'Tımar';
      default: return type ?? '';
    }
  }

  Future<void> _close(String id) async {
    try {
      await widget.repo.updateSitterRequestStatus(id, 'closed');
      _load();
    } catch (_) {}
  }

  Future<void> _open(String id) async {
    try {
      await widget.repo.updateSitterRequestStatus(id, 'open');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Color(0xFF2D6A4F)),
                  SizedBox(width: 8),
                  Text('Kendi İlanlarım', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests == null || _requests!.isEmpty
                  ? const Center(child: Text('Henüz ilan açmadınız', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: _requests!.length,
                      itemBuilder: (context, i) {
                        final req = _requests![i];
                        final id = req['id']?.toString() ?? req['_id']?.toString() ?? '';
                        final status = req['status'] as String? ?? 'open';
                        final isOpen = status == 'open';
                        final startDate = req['startDate'] != null ? DateTime.tryParse(req['startDate'].toString()) : null;
                        final endDate = req['endDate'] != null ? DateTime.tryParse(req['endDate'].toString()) : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_serviceLabel(req['serviceType'] as String?),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      if (startDate != null && endDate != null)
                                        Text(
                                          '${startDate.day}.${startDate.month.toString().padLeft(2,'0')}.${startDate.year} — ${endDate.day}.${endDate.month.toString().padLeft(2,'0')}.${endDate.year}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOpen ? const Color(0xFF2D6A4F).withOpacity(0.1) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isOpen ? 'Aktif' : 'Kapalı',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isOpen ? const Color(0xFF2D6A4F) : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(isOpen ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                      color: isOpen ? Colors.orange : const Color(0xFF2D6A4F)),
                                  tooltip: isOpen ? 'İlanı Kapat' : 'İlanı Aç',
                                  onPressed: () => isOpen ? _close(id) : _open(id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
