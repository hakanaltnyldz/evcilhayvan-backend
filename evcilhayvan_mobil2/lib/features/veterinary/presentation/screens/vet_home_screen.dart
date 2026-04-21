import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';

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
import '../../domain/models/appointment_model.dart';
import '../widgets/appointment_card.dart';
import '../widgets/vet_card.dart';

class VetHomeScreen extends ConsumerStatefulWidget {
  const VetHomeScreen({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  ConsumerState<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends ConsumerState<VetHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
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
        title: Text(
          AppLocalizations.of(context)!.vetTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.search),
              text: AppLocalizations.of(context)!.vetHomeTabSearch,
            ),
            Tab(
              icon: const Icon(Icons.calendar_today),
              text: AppLocalizations.of(context)!.vetHomeTabAppointments,
            ),
            Tab(
              icon: const Icon(Icons.vaccines),
              text: AppLocalizations.of(context)!.vetHomeTabVaccine,
            ),
            const Tab(icon: Icon(Icons.local_hospital_rounded), text: 'Klinik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SearchTab(),
          isGuest ? const _GuestLockedTab() : _AppointmentsTab(),
          isGuest ? const _GuestLockedTab() : _VaccinationTab(),
          isGuest ? const _GuestLockedTab() : _VetScheduleTab(),
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
  bool _errorVets = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyVets();
  }

  Future<void> _loadNearbyVets() async {
    setState(() {
      _loadingVets = true;
      _errorVets = false;
    });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _locationDenied = true;
          _loadingVets = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final repo = ref.read(veterinaryRepositoryProvider);
      final isGuest = ref.read(authProvider) == null;
      // Guest modda public endpoint kullan; giriş yapılmışsa Google Places ile upsert et
      final vets = isGuest
          ? await repo.searchVets(
              lat: pos.latitude,
              lng: pos.longitude,
              radiusKm: kDefaultVetRadiusKm,
            )
          : await repo.googleSearch(
              lat: pos.latitude,
              lng: pos.longitude,
              radiusKm: kDefaultVetRadiusKm,
            );
      if (mounted)
        setState(() {
          _nearbyVets = vets;
          _loadingVets = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loadingVets = false;
          _errorVets = true;
        });
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
        icon: Icons.assignment_ind_outlined,
        label: 'Talep Durumum',
        onTap: () => context.pushNamed('vet-claim-status'),
      ),
      _QuickActionData(
        icon: Icons.map,
        label: l10n.vetHomeGoogleSearch,
        onTap: () =>
            context.pushNamed('vet-search', extra: {'googleSearch': true}),
      ),
      _QuickActionData(
        icon: Icons.dashboard_customize_outlined,
        label: 'Klinik Panelim',
        onTap: () => context.pushNamed('vet-clinic-panel'),
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(
                    l10n.vetHomeSearchHint,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hizli erisim kartlari
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(data: quickActions[0], index: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(data: quickActions[1], index: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(data: quickActions[2], index: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(data: quickActions[3], index: 3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(data: quickActions[4], index: 4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(data: quickActions[5], index: 5),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Yakin veterinerler
          Text(
            l10n.vetHomeNearbyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingVets)
            const Center(child: PawLoading())
          else if (_errorVets)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(l10n.vetHomeNearbyEmpty),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadNearbyVets,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            )
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
                        onTap: () => context.pushNamed(
                          'vet-detail',
                          pathParameters: {'id': vet.id},
                        ),
                      ),
                    )
                    .animate(delay: Duration(milliseconds: index * 60))
                    .fadeIn(duration: 280.ms)
                    .slideY(
                      begin: 0.05,
                      duration: 280.ms,
                      curve: Curves.easeOut,
                    );
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

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
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
                  child: Icon(
                    data.icon,
                    color: const Color(0xFF2D6A4F),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

class _AppointmentsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends ConsumerState<_AppointmentsTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);
    final l10n = AppLocalizations.of(context)!;

    return appointmentsAsync.when(
      loading: () => const Center(child: PawLoading()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(l10n.vetHomeLoadError(e.toString())),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(myAppointmentsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (appointments) {
        // Günlere göre grupla
        final Map<DateTime, List<dynamic>> eventMap = {};
        for (final apt in appointments) {
          final day = _normalizeDay(apt.date);
          eventMap.putIfAbsent(day, () => []).add(apt);
        }

        List<dynamic> Function(DateTime) getEventsForDay = (day) =>
            eventMap[_normalizeDay(day)] ?? [];

        final selectedDay = _selectedDay ?? _normalizeDay(DateTime.now());
        final visibleAppointments = _selectedDay != null
            ? getEventsForDay(_selectedDay!)
            : appointments;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myAppointmentsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null &&
                      _normalizeDay(day) == _normalizeDay(_selectedDay!),
                  eventLoader: getEventsForDay,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
                  locale: 'tr_TR',
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay =
                          _normalizeDay(selected) ==
                              _normalizeDay(_selectedDay ?? DateTime(0))
                          ? null // ikinci tıklayınca seçimi kaldır
                          : selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) {
                    setState(() => _focusedDay = focused);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF52B788).withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF2D6A4F),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF52B788),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (_selectedDay != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Color(0xFF2D6A4F),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year} — ${visibleAppointments.length} randevu',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDay = null),
                          child: const Text(
                            'Tümünü Göster',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (visibleAppointments.isEmpty)
                SliverFillRemaining(
                  child: AnimatedEmptyState(
                    icon: Icons.calendar_today,
                    title: _selectedDay != null
                        ? 'Bu günde randevu yok'
                        : l10n.vetHomeApptsEmpty,
                    subtitle: _selectedDay == null
                        ? l10n.vetHomeApptsEmptyDesc
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final apt = visibleAppointments[index];
                      return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumCard(
                              accentColor: _accentForStatus(apt.status),
                              onTap: () => context.pushNamed(
                                'appointment-detail',
                                pathParameters: {'id': apt.id},
                              ),
                              padding: EdgeInsets.zero,
                              child: AppointmentCard(
                                appointment: apt,
                                onTap: null,
                              ),
                            ),
                          )
                          .animate(delay: Duration(milliseconds: index * 60))
                          .fadeIn(duration: 280.ms)
                          .slideY(
                            begin: 0.05,
                            duration: 280.ms,
                            curve: Curves.easeOut,
                          );
                    }, childCount: visibleAppointments.length),
                  ),
                ),
            ],
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
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(l10n.vetHomeLoadError(e.toString())),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(vaccinationRemindersProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (reminders) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.vetHomeVaccineTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
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
                      final accentColor = isOverdue
                          ? Colors.red
                          : Colors.orange;
                      final iconColor = isOverdue ? Colors.red : Colors.orange;

                      return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PremiumCard(
                              accentColor: accentColor,
                              onTap: () => context.pushNamed(
                                'vaccination-calendar',
                                pathParameters: {'petId': r.petId},
                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.vaccineName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (r.nextDueDate != null)
                                          Text(
                                            '${r.nextDueDate!.day}.${r.nextDueDate!.month}.${r.nextDueDate!.year}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      isOverdue
                                          ? l10n.vetHomeVaccineOverdue
                                          : l10n.vetHomeVaccineUpcoming,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor: accentColor,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(delay: Duration(milliseconds: index * 60))
                          .fadeIn(duration: 280.ms)
                          .slideY(
                            begin: 0.05,
                            duration: 280.ms,
                            curve: Curves.easeOut,
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
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

// ─── Vet Schedule Tab (Klinik sahibi için) ───────────────────────

class _VetScheduleTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VetScheduleTab> createState() => _VetScheduleTabState();
}

class _VetScheduleTabState extends ConsumerState<_VetScheduleTab> {
  List<AppointmentModel> _appointments = [];
  bool _loading = false;
  String? _error;
  String? _vetName;
  String? _statusFilter; // null = hepsi
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final result = await repo.getVetSchedule(status: _statusFilter);
      if (mounted) {
        setState(() {
          _appointments = (result['appointments'] as List)
              .cast<AppointmentModel>();
          _vetName = result['vetName'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _updateStatus(
    AppointmentModel apt,
    String newStatus, {
    String? vetNotes,
  }) async {
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      await repo.updateStatus(apt.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusLabel(newStatus) + ' olarak güncellendi'),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Güncelleme hatası: $e')));
      }
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'Onaylandı';
      case 'cancelled':
        return 'İptal edildi';
      case 'completed':
        return 'Tamamlandı';
      case 'no_show':
        return 'Gelmedi';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return const Color(0xFF2D6A4F);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: PawLoading());

    if (_error != null) {
      // Klinik bulunamadı durumu
      final noClinic =
          _error!.contains('404') ||
          _error!.toLowerCase().contains('bulunamadi');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                noClinic ? Icons.local_hospital_outlined : Icons.error_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                noClinic ? 'Kayıtlı kliniğiniz yok' : 'Randevular yüklenemedi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                noClinic
                    ? 'Veteriner olarak klinik kaydı yapın veya\nbir kliniği sahiplenin.'
                    : _error!,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (noClinic)
                ElevatedButton.icon(
                  onPressed: () => context.pushNamed('vet-register'),
                  icon: const Icon(Icons.add_business, size: 18),
                  label: const Text('Klinik Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
            ],
          ),
        ),
      );
    }

    // Takvim için event map
    final Map<DateTime, List<AppointmentModel>> eventMap = {};
    for (final apt in _appointments) {
      final day = _normalizeDay(apt.date);
      eventMap.putIfAbsent(day, () => []).add(apt);
    }
    List<AppointmentModel> getEvents(DateTime d) =>
        eventMap[_normalizeDay(d)] ?? [];

    final selectedDay = _selectedDay ?? _normalizeDay(DateTime.now());
    final visible = _selectedDay != null
        ? getEvents(_selectedDay!)
        : List<AppointmentModel>.from(_appointments);

    // Durum bazlı filtre
    final filtered = _statusFilter == null
        ? visible
        : visible.where((a) => a.status == _statusFilter).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Klinik başlığı + filtreler
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_vetName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_hospital_rounded,
                          color: Color(0xFF2D6A4F),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _vetName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                        ),
                        Text(
                          '${_appointments.length} randevu',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Durum filtreleri
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      _filterChip(null, 'Tümü'),
                      const SizedBox(width: 8),
                      _filterChip('pending', 'Bekleyen'),
                      const SizedBox(width: 8),
                      _filterChip('confirmed', 'Onaylı'),
                      const SizedBox(width: 8),
                      _filterChip('completed', 'Tamamlandı'),
                      const SizedBox(width: 8),
                      _filterChip('cancelled', 'İptal'),
                    ],
                  ),
                ),
                // Takvim
                TableCalendar<AppointmentModel>(
                  firstDay: DateTime.now().subtract(const Duration(days: 180)),
                  lastDay: DateTime.now().add(const Duration(days: 180)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null &&
                      _normalizeDay(day) == _normalizeDay(_selectedDay!),
                  eventLoader: getEvents,
                  calendarFormat: CalendarFormat.twoWeeks,
                  availableCalendarFormats: const {
                    CalendarFormat.twoWeeks: '2 Hafta',
                    CalendarFormat.month: 'Ay',
                  },
                  locale: 'tr_TR',
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay =
                          _normalizeDay(selected) ==
                              _normalizeDay(_selectedDay ?? DateTime(0))
                          ? null
                          : selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) =>
                      setState(() => _focusedDay = focused),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF52B788).withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF2D6A4F),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF52B788),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (_selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 14,
                          color: Color(0xFF2D6A4F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year} — ${getEvents(_selectedDay!).length} randevu',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDay = null),
                          child: Text(
                            'Tümü',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Randevu listesi
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: AnimatedEmptyState(
                icon: Icons.event_available,
                title: _statusFilter != null
                    ? 'Bu durumda randevu yok'
                    : _selectedDay != null
                    ? 'Bu günde randevu yok'
                    : 'Henüz randevu alınmamış',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildAppointmentCard(filtered[i], i),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2D6A4F)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel apt, int index) {
    final statusColor = _statusColor(apt.status);
    final isPending = apt.status == 'pending';
    final isConfirmed = apt.status == 'confirmed';

    return PremiumCard(
          accentColor: statusColor,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: saat + durum badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF2D6A4F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${apt.date.hour.toString().padLeft(2, '0')}:${apt.date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${apt.date.day}.${apt.date.month}.${apt.date.year}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(apt.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Hayvan sahibi bilgisi
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Color(0xFF52B788),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      apt.pet?.name != null
                          ? '${apt.pet!.name} (${apt.pet!.species})'
                          : 'Hayvan bilgisi yok',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Randevu türü
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        apt.type == 'online'
                            ? Icons.videocam_rounded
                            : Icons.local_hospital_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        apt.type == 'online' ? 'Online' : 'Klinikte',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (apt.reason != null && apt.reason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        apt.reason!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Aksiyon butonları
              if (isPending || isConfirmed) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isPending) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(apt, 'cancelled'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text(
                            'Reddet',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(apt, 'confirmed'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text(
                            'Onayla',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ] else if (isConfirmed) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(apt, 'no_show'),
                          icon: const Icon(Icons.person_off_outlined, size: 16),
                          label: const Text(
                            'Gelmedi',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(apt, 'completed'),
                          icon: const Icon(Icons.task_alt, size: 16),
                          label: const Text(
                            'Tamamlandı',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.04, duration: 280.ms, curve: Curves.easeOut);
  }
}
