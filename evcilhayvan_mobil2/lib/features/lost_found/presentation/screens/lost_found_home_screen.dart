import 'dart:async';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';


import 'package:flutter_animate/flutter_animate.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_refresh_indicator.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/lost_found_repository.dart';
import '../../domain/models/lost_found_model.dart';
import '../widgets/lost_found_card.dart';
import '../widgets/lost_found_map_view.dart';

class LostFoundHomeScreen extends ConsumerStatefulWidget {
  const LostFoundHomeScreen({super.key});

  @override
  ConsumerState<LostFoundHomeScreen> createState() => _LostFoundHomeScreenState();
}

class _LostFoundHomeScreenState extends ConsumerState<LostFoundHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showMap = false;
  double? _lat;
  double? _lng;
  bool _locationLoading = false;
  List<LostFoundPet>? _lostReports;
  List<LostFoundPet>? _foundReports;
  bool _loading = false;
  String? _error;
  bool _loadingMoreLost = false;
  bool _loadingMoreFound = false;
  bool _hasMoreLost = true;
  bool _hasMoreFound = true;
  int _lostPage = 1;
  int _foundPage = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _locationLoading = false);
        _loadReports();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _lat = pos.latitude;
      _lng = pos.longitude;
      setState(() => _locationLoading = false);
      _loadReports();
    } catch (e) {
      setState(() => _locationLoading = false);
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
      _lostPage = 1;
      _foundPage = 1;
      _hasMoreLost = true;
      _hasMoreFound = true;
    });
    try {
      final repo = ref.read(lostFoundRepositoryProvider);
      final results = await Future.wait([
        repo.listReports(type: 'lost', lat: _lat, lng: _lng, page: 1),
        repo.listReports(type: 'found', lat: _lat, lng: _lng, page: 1),
      ]);
      setState(() {
        _lostReports = results[0];
        _foundReports = results[1];
        _hasMoreLost = results[0].length >= _pageSize;
        _hasMoreFound = results[1].length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreLost() async {
    if (_loadingMoreLost || !_hasMoreLost) return;
    setState(() => _loadingMoreLost = true);
    try {
      final nextPage = _lostPage + 1;
      final more = await ref.read(lostFoundRepositoryProvider).listReports(type: 'lost', lat: _lat, lng: _lng, page: nextPage);
      setState(() {
        _lostReports = [...?_lostReports, ...more];
        _lostPage = nextPage;
        _hasMoreLost = more.length >= _pageSize;
        _loadingMoreLost = false;
      });
    } catch (_) {
      setState(() => _loadingMoreLost = false);
    }
  }

  Future<void> _loadMoreFound() async {
    if (_loadingMoreFound || !_hasMoreFound) return;
    setState(() => _loadingMoreFound = true);
    try {
      final nextPage = _foundPage + 1;
      final more = await ref.read(lostFoundRepositoryProvider).listReports(type: 'found', lat: _lat, lng: _lng, page: nextPage);
      setState(() {
        _foundReports = [...?_foundReports, ...more];
        _foundPage = nextPage;
        _hasMoreFound = more.length >= _pageSize;
        _loadingMoreFound = false;
      });
    } catch (_) {
      setState(() => _loadingMoreFound = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lostFoundTitle2),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? AppLocalizations.of(context)!.lostFoundListView : AppLocalizations.of(context)!.lostFoundMapView,
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.search, size: 18),
              text: AppLocalizations.of(context)!.lostFoundLostTab,
            ),
            Tab(
              icon: const Icon(Icons.pets, size: 18),
              text: AppLocalizations.of(context)!.lostFoundFoundTab,
            ),
          ],
        ),
      ),
      body: SafeArea(
          child: _locationLoading || _loading
              ? const Center(child: PawLoading())
              : _error != null
                  ? Center(
                      child: ErrorView(
                        message: _error!,
                        onRetry: _loadReports,
                      ),
                    )
                  : _showMap
                      ? _buildMapView()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(_lostReports ?? [], isLost: true),
                            _buildList(_foundReports ?? [], isLost: false),
                          ],
                        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('report-lost-found'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.lostFoundCreateBtn),
      ),
    );
  }

  Widget _buildList(List<LostFoundPet> reports, {required bool isLost}) {
    final hasMore = isLost ? _hasMoreLost : _hasMoreFound;
    final loadingMore = isLost ? _loadingMoreLost : _loadingMoreFound;
    final onLoadMore = isLost ? _loadMoreLost : _loadMoreFound;

    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            AnimatedEmptyState(
              icon: Icons.search_off_outlined,
              title: AppLocalizations.of(context)!.lostFoundEmptyTitle,
              subtitle: AppLocalizations.of(context)!.lostFoundEmptySubtitle,
            ),
          ],
        ),
      );
    }

    return PawRefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: reports.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == reports.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: loadingMore
                    ? const PawLoading()
                    : OutlinedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Daha Fazla Göster'),
                      ),
              ),
            );
          }
          final report = reports[index];
          return LostFoundCard(
            report: report,
            onTap: () => context.pushNamed(
              'lost-found-detail',
              pathParameters: {'id': report.id},
            ),
          )
              .animate(delay: Duration(milliseconds: (index * 55).clamp(0, 440)))
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(begin: 0.06, duration: 280.ms, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _buildMapView() {
    final allReports = <LostFoundPet>[
      ...(_lostReports ?? []),
      ...(_foundReports ?? []),
    ];

    return LostFoundMapView(
      reports: allReports,
      userLat: _lat,
      userLng: _lng,
      onMarkerTap: (report) {
        context.pushNamed('lost-found-detail', pathParameters: {'id': report.id});
      },
    );
  }
}
