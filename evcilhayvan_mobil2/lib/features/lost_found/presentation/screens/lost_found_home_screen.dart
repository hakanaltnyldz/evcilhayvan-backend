import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';


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
    });
    try {
      final repo = ref.read(lostFoundRepositoryProvider);
      final results = await Future.wait([
        repo.listReports(type: 'lost', lat: _lat, lng: _lng),
        repo.listReports(type: 'found', lat: _lat, lng: _lng),
      ]);
      setState(() {
        _lostReports = results[0];
        _foundReports = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lostFoundTitle2),
        backgroundColor: const Color(0xFF1B4332),
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
              ? const Center(child: CircularProgressIndicator())
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
                            _buildList(_lostReports ?? []),
                            _buildList(_foundReports ?? []),
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

  Widget _buildList(List<LostFoundPet> reports) {
    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            EmptyState(
              icon: Icons.search_off_outlined,
              title: AppLocalizations.of(context)!.lostFoundEmptyTitle,
              subtitle: AppLocalizations.of(context)!.lostFoundEmptySubtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return LostFoundCard(
            report: report,
            onTap: () => context.pushNamed(
              'lost-found-detail',
              pathParameters: {'id': report.id},
            ),
          );
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
