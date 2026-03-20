import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/vaccination_repository.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/veterinary_model.dart';
import '../widgets/appointment_card.dart';
import '../widgets/vet_card.dart';

const List<Color> _vetBackgroundLight = [
  Color(0xFFF0FFF4),
  Color(0xFFE8F5FF),
  Color(0xFFFFF8F0),
];
const List<Color> _vetBackgroundDark = [
  Color(0xFF0E1F16),
  Color(0xFF0D1A26),
  Color(0xFF1F1610),
];

class VetHomeScreen extends ConsumerStatefulWidget {
  const VetHomeScreen({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  ConsumerState<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends ConsumerState<VetHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? _vetBackgroundDark : _vetBackgroundLight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(AppLocalizations.of(context)!.vetTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppPalette.primary,
            unselectedLabelColor: AppPalette.onSurfaceVariant,
            indicatorColor: AppPalette.primary,
            tabs: [
              Tab(icon: const Icon(Icons.search), text: AppLocalizations.of(context)!.vetHomeTabSearch),
              Tab(icon: const Icon(Icons.calendar_today), text: AppLocalizations.of(context)!.vetHomeTabAppointments),
              Tab(icon: const Icon(Icons.vaccines), text: AppLocalizations.of(context)!.vetHomeTabVaccine),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _SearchTab(),
            _AppointmentsTab(),
            _VaccinationTab(),
          ],
        ),
      ),
    );
  }
}

class _SearchTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  List<VeterinaryModel>? _nearbyVets;
  bool _loadingVets = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyVets();
  }

  Future<void> _loadNearbyVets() async {
    setState(() => _loadingVets = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _locationDenied = true; _loadingVets = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final repo = ref.read(veterinaryRepositoryProvider);
      // Google Places ile yakın vets ara → DB'ye upsert et ve döndür
      final vets = await repo.googleSearch(lat: pos.latitude, lng: pos.longitude, radiusKm: 10);
      if (mounted) setState(() { _nearbyVets = vets; _loadingVets = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingVets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama butonu
          InkWell(
            onTap: () => context.pushNamed('vet-search'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppPalette.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l10n.vetHomeSearchHint, style: theme.textTheme.bodyLarge?.copyWith(color: AppPalette.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hizli erisim kartlari
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.location_on,
                  label: l10n.vetHomeNearMe,
                  color: const Color(0xFF4CAF50),
                  onTap: () => context.pushNamed('vet-search', extra: {'nearMe': true}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_business,
                  label: l10n.vetHomeSaveClinic,
                  color: const Color(0xFF2196F3),
                  onTap: () => context.pushNamed('vet-register'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map,
                  label: l10n.vetHomeGoogleSearch,
                  color: const Color(0xFFFF9800),
                  onTap: () => context.pushNamed('vet-search', extra: {'googleSearch': true}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.notifications_active,
                  label: l10n.vetHomeReminders,
                  color: const Color(0xFFE91E63),
                  onTap: () => context.pushNamed('vaccination-reminders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Yakin veterinerler
          Text(l10n.vetHomeNearbyTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loadingVets)
            const Center(child: CircularProgressIndicator())
          else if (_locationDenied)
            Center(
              child: Text(l10n.vetHomeNearbyPermRequired,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
            )
          else if (_nearbyVets == null || _nearbyVets!.isEmpty)
            Center(
              child: Text(l10n.vetHomeNearbyEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nearbyVets!.length,
              itemBuilder: (context, index) {
                final vet = _nearbyVets![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VetCard(
                    vet: vet,
                    onTap: () => context.pushNamed('vet-detail', pathParameters: {'id': vet.id}),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return appointmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.vetHomeLoadError(e.toString()))),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: AppPalette.onSurfaceVariant.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.vetHomeApptsEmpty, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.vetHomeApptsEmptyDesc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myAppointmentsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final apt = appointments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppointmentCard(
                  appointment: apt,
                  onTap: () => context.pushNamed('appointment-detail', pathParameters: {'id': apt.id}),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _VaccinationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(vaccinationRemindersProvider);

    final l10n = AppLocalizations.of(context)!;
    return remindersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.vetHomeLoadError(e.toString()))),
      data: (reminders) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.vetHomeVaccineTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (reminders.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vaccines, size: 64, color: AppPalette.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(l10n.vetHomeVaccineEmpty, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(l10n.vetHomeVaccineEmptyDesc,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppPalette.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final r = reminders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            r.isOverdue ? Icons.warning : Icons.vaccines,
                            color: r.isOverdue ? Colors.red : Colors.orange,
                          ),
                          title: Text(r.vaccineName),
                          subtitle: Text(
                            r.nextDueDate != null
                                ? '${r.nextDueDate!.day}.${r.nextDueDate!.month}.${r.nextDueDate!.year}'
                                : '',
                          ),
                          trailing: r.isOverdue
                              ? Chip(label: Text(l10n.vetHomeVaccineOverdue, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.red)
                              : Chip(label: Text(l10n.vetHomeVaccineUpcoming, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.orange),
                          onTap: () => context.pushNamed('vaccination-calendar', pathParameters: {'petId': r.petId}),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
