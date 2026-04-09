import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/widgets/premium_card.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/constants.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/vaccination_repository.dart';
import '../../data/repositories/veterinary_repository.dart';
import '../../domain/models/veterinary_model.dart';
import '../widgets/appointment_card.dart';
import '../widgets/vet_card.dart';

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
    final isGuest = ref.watch(authProvider) == null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.vetTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
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
          isGuest ? const _GuestLockedTab() : _AppointmentsTab(),
          isGuest ? const _GuestLockedTab() : _VaccinationTab(),
        ],
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
      final isGuest = ref.read(authProvider) == null;
      // Guest modda public endpoint kullan; giriş yapılmışsa Google Places ile upsert et
      final vets = isGuest
          ? await repo.searchVets(lat: pos.latitude, lng: pos.longitude, radiusKm: kDefaultVetRadiusKm)
          : await repo.googleSearch(lat: pos.latitude, lng: pos.longitude, radiusKm: kDefaultVetRadiusKm);
      if (mounted) setState(() { _nearbyVets = vets; _loadingVets = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingVets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final quickActions = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.location_on,
        label: l10n.vetHomeNearMe,
        onTap: () => context.pushNamed('vet-search', extra: {'nearMe': true}),
      ),
      _QuickActionData(
        icon: Icons.add_business,
        label: l10n.vetHomeSaveClinic,
        onTap: () => context.pushNamed('vet-register'),
      ),
      _QuickActionData(
        icon: Icons.map,
        label: l10n.vetHomeGoogleSearch,
        onTap: () => context.pushNamed('vet-search', extra: {'googleSearch': true}),
      ),
      _QuickActionData(
        icon: Icons.notifications_active,
        label: l10n.vetHomeReminders,
        onTap: () => context.pushNamed('vaccination-reminders'),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama butonu
          InteractiveScale(
            onTap: () => context.pushNamed('vet-search'),
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
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(l10n.vetHomeSearchHint, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
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
                  data: quickActions[0],
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  data: quickActions[1],
                  index: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  data: quickActions[2],
                  index: 2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  data: quickActions[3],
                  index: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Yakin veterinerler
          Text(l10n.vetHomeNearbyTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loadingVets)
            const Center(child: PawLoading())
          else if (_locationDenied)
            AnimatedEmptyState(
              icon: Icons.location_searching,
              title: l10n.vetHomeNearbyPermRequired,
            )
          else if (_nearbyVets == null || _nearbyVets!.isEmpty)
            AnimatedEmptyState(
              icon: Icons.location_searching,
              title: l10n.vetHomeNearbyEmpty,
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
                )
                    .animate(delay: Duration(milliseconds: index * 60))
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.05, duration: 280.ms, curve: Curves.easeOut);
              },
            ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionData({required this.icon, required this.label, required this.onTap});
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;
  final int index;

  const _QuickActionCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return InteractiveScale(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3DC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: const Color(0xFF2D6A4F), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
  }
}

Color _accentForStatus(String status) {
  switch (status) {
    case 'confirmed':
      return const Color(0xFF52B788);
    case 'cancelled':
      return Colors.red;
    case 'completed':
      return const Color(0xFF2D6A4F);
    case 'no_show':
      return Colors.grey;
    default:
      return Colors.orange;
  }
}

class _AppointmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return appointmentsAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.vetHomeLoadError(e.toString()))),
      data: (appointments) {
        if (appointments.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.calendar_today,
            title: AppLocalizations.of(context)!.vetHomeApptsEmpty,
            subtitle: AppLocalizations.of(context)!.vetHomeApptsEmptyDesc,
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
                child: PremiumCard(
                  accentColor: _accentForStatus(apt.status),
                  onTap: () => context.pushNamed('appointment-detail', pathParameters: {'id': apt.id}),
                  padding: EdgeInsets.zero,
                  child: AppointmentCard(appointment: apt, onTap: null),
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 60))
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.05, duration: 280.ms, curve: Curves.easeOut);
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
      loading: () => const Center(child: PawLoading()),
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
                  child: AnimatedEmptyState(
                    icon: Icons.vaccines,
                    title: l10n.vetHomeVaccineEmpty,
                    subtitle: l10n.vetHomeVaccineEmptyDesc,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final r = reminders[index];
                      final isOverdue = r.isOverdue;
                      final accentColor = isOverdue ? Colors.red : Colors.orange;
                      final iconColor = isOverdue ? Colors.red : Colors.orange;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PremiumCard(
                          accentColor: accentColor,
                          onTap: () => context.pushNamed('vaccination-calendar', pathParameters: {'petId': r.petId}),
                          child: Row(
                            children: [
                              Icon(
                                isOverdue ? Icons.warning : Icons.vaccines,
                                color: iconColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.vaccineName,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    if (r.nextDueDate != null)
                                      Text(
                                        '${r.nextDueDate!.day}.${r.nextDueDate!.month}.${r.nextDueDate!.year}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  isOverdue ? l10n.vetHomeVaccineOverdue : l10n.vetHomeVaccineUpcoming,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                                backgroundColor: accentColor,
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: index * 60))
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.05, duration: 280.ms, curve: Curves.easeOut);
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

class _GuestLockedTab extends StatelessWidget {
  const _GuestLockedTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Bu özellik için giriş yapmalısın',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.pushNamed('login'),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }
}
