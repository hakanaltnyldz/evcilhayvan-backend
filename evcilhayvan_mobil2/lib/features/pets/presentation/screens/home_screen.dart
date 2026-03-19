import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/core/data/pet_breeds.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/features/notifications/providers/notification_provider.dart';
import 'package:evcilhayvan_mobil2/features/veterinary/data/repositories/appointment_repository.dart';
import 'widgets/pet_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _nearbyActive = false;
  bool _locLoading = false;
  String? _selectedSpecies;
  String? _selectedBreed;

  static const _speciesValues = ['dog', 'cat', 'bird', 'fish', 'rodent', 'other'];
  static const _speciesEmojis = ['🐶', '🐱', '🐦', '🐟', '🐹', '🐾'];

  void _applyFilter({String? species, String? breed}) {
    setState(() {
      _selectedSpecies = species;
      _selectedBreed = breed;
    });
    ref.read(adoptionPaginatedProvider.notifier).setFilter(species: species, breed: breed);
    ref.read(matingPaginatedProvider.notifier).setFilter(species: species, breed: breed);
    ref.read(adoptionPaginatedProvider.notifier).refresh();
    ref.read(matingPaginatedProvider.notifier).refresh();
  }

  void _pickBreed() {
    if (_selectedSpecies == null) return;
    final breeds = breedsFor(_selectedSpecies!);
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BreedPickerSheet(breeds: breeds, selected: _selectedBreed),
    ).then((picked) {
      if (picked != null) {
        _applyFilter(species: _selectedSpecies, breed: picked == '__clear__' ? null : picked);
      }
    });
  }

  Future<void> _toggleNearby() async {
    if (_nearbyActive) {
      setState(() => _nearbyActive = false);
      ref.read(adoptionPaginatedProvider.notifier).clearLocation();
      ref.read(matingPaginatedProvider.notifier).clearLocation();
      ref.read(adoptionPaginatedProvider.notifier).refresh();
      ref.read(matingPaginatedProvider.notifier).refresh();
      return;
    }
    setState(() => _locLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.homeLocationPermErr)),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      ref.read(adoptionPaginatedProvider.notifier).setLocation(pos.latitude, pos.longitude);
      ref.read(matingPaginatedProvider.notifier).setLocation(pos.latitude, pos.longitude);
      ref.read(adoptionPaginatedProvider.notifier).refresh();
      ref.read(matingPaginatedProvider.notifier).refresh();
      if (mounted) setState(() => _nearbyActive = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.homeLocationErr(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);
    final firstName = (user?.name ?? '').split(' ').first;
    final speciesList = [
      ('🐶 ${l10n.speciesDog}', 'dog'),
      ('🐱 ${l10n.speciesCat}', 'cat'),
      ('🐦 ${l10n.speciesBird}', 'bird'),
      ('🐟 ${l10n.speciesFish}', 'fish'),
      ('🐹 ${l10n.vetSpeciesRodent}', 'rodent'),
      ('🐾 ${l10n.speciesOther}', 'other'),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(l10n.homeDiscoverTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: l10n.homeSearchTooltip,
              onPressed: () => context.pushNamed('search'),
            ),
            IconButton(
              icon: const Icon(Icons.location_searching),
              tooltip: l10n.homeLostFoundTooltip,
              onPressed: () => context.pushNamed('lost-found'),
            ),
            _NotificationBell(),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDark
                    ? [const Color(0xFF1E1C30), const Color(0xFF12111F)]
                    : [const Color(0xFFc7d2fe), const Color(0xFFeef2ff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)?.homeAdoptionTab ?? 'Sahiplendirme'),
              Tab(text: AppLocalizations.of(context)?.homeMatingTab ?? 'Eşleştirme'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.isDark
                  ? [const Color(0xFF12111F), const Color(0xFF0D0C1A)]
                  : [const Color(0xFFeef2ff), const Color(0xFFF8F9FB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedHeader(firstName: firstName.isEmpty ? null : firstName),
                  const SizedBox(height: 12),
                  const _QuickShortcutsRow(),
                  const SizedBox(height: 8),
                  const _UpcomingRemindersWidget(),
                  // Yakınımdakiler butonu + Tür filtresi
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ActionChip(
                          label: Text(l10n.homeNearbyAds),
                          avatar: const Icon(Icons.near_me_rounded, size: 16),
                          onPressed: () => context.pushNamed('nearby-ads'),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...speciesList.map((s) {
                          final selected = _selectedSpecies == s.$2;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(s.$1),
                              selected: selected,
                              onSelected: (_) {
                                if (selected) {
                                  _applyFilter(species: null, breed: null);
                                } else {
                                  _applyFilter(species: s.$2, breed: null);
                                }
                              },
                              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(
                                color: selected ? Theme.of(context).colorScheme.primary : null,
                                fontWeight: selected ? FontWeight.bold : null,
                                fontSize: 12,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Cins filtresi (tür seçiliyse)
                  if (_selectedSpecies != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickBreed,
                          icon: const Icon(Icons.pets, size: 14),
                          label: Text(
                            _selectedBreed ?? l10n.homeBreedSelect,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                        if (_selectedBreed != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _applyFilter(species: _selectedSpecies, breed: null),
                            child: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                          ),
                        ],
                        const Spacer(),
                        TextButton(
                          onPressed: () => _applyFilter(species: null, breed: null),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.red,
                          ),
                          child: Text(l10n.homeClearFilter, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _AdvertsList(provider: adoptionPaginatedProvider),
                        _AdvertsList(provider: matingPaginatedProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  final String? firstName;
  const _AnimatedHeader({this.firstName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = l10n.homeGoodMorning;
    } else if (hour >= 12 && hour < 18) {
      greeting = l10n.homeGoodDay;
    } else if (hour >= 18 && hour < 22) {
      greeting = l10n.homeGoodEvening;
    } else {
      greeting = l10n.homeGoodNight;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.85),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                color: Colors.white.withOpacity(0.95),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstName != null ? '$greeting, $firstName!' : l10n.homeWelcome,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.homeHeaderDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _QuickShortcutsRow extends StatelessWidget {
  const _QuickShortcutsRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shortcuts = [
      (label: l10n.homeShortcutMating, icon: Icons.favorite_rounded, colors: const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)], route: 'mating'),
      (label: l10n.homeShortcutSitterFull, icon: Icons.pets_rounded, colors: const [Color(0xFF56CCF2), Color(0xFF2F80ED)], route: 'sitters'),
      (label: l10n.homeShortcutEvents, icon: Icons.event_rounded, colors: const [Color(0xFF6FCF97), Color(0xFF27AE60)], route: 'events'),
      (label: l10n.homeShortcutLostFull, icon: Icons.location_searching_rounded, colors: const [Color(0xFFF2994A), Color(0xFFEB5757)], route: 'lost-found'),
      (label: l10n.homeShortcutMap, icon: Icons.map_rounded, colors: const [Color(0xFF11998E), Color(0xFF38EF7D)], route: 'map'),
      (label: l10n.homeShortcutFeed, icon: Icons.dynamic_feed_rounded, colors: const [Color(0xFF6C63FF), Color(0xFF9B8FFF)], route: 'feed'),
      (label: l10n.homeShortcutAiFull, icon: Icons.smart_toy_rounded, colors: const [Color(0xFFFF7A59), Color(0xFFFF9F7F)], route: 'ai-assistant'),
    ];
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: shortcuts.length,
        itemBuilder: (context, i) {
          final s = shortcuts[i];
          return _ShortcutCard(
            label: s.label,
            icon: s.icon,
            gradient: LinearGradient(colors: s.colors),
            onTap: () => context.pushNamed(s.route),
          )
              .animate(delay: Duration(milliseconds: 80 + i * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.15, duration: 300.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvertsList extends ConsumerStatefulWidget {
  const _AdvertsList({required this.provider});
  final StateNotifierProvider<PaginatedAdvertsNotifier, PaginatedAdvertsState> provider;

  @override
  ConsumerState<_AdvertsList> createState() => _AdvertsListState();
}

class _AdvertsListState extends ConsumerState<_AdvertsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(widget.provider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);

    if (state.items.isEmpty && state.isLoading) {
      return const _SkeletonList();
    }

    if (state.items.isEmpty && state.error != null) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(widget.provider.notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return EmptyState(
        icon: Icons.pets,
        title: AppLocalizations.of(context)!.homeEmptyListings,
        subtitle: AppLocalizations.of(context)!.homeEmptyListingsDesc,
      );
    }

    final showBottomLoader = state.page > 0 && state.isLoading;

    return RefreshIndicator(
      onRefresh: () => ref.read(widget.provider.notifier).refresh(),
      displacement: 36,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: state.items.length + (showBottomLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final pet = state.items[index];
          return PetCard(
            pet: pet,
            onTap: () => context.pushNamed(
              'pet-detail',
              pathParameters: {'id': pet.id},
            ),
          )
              .animate(
                key: ValueKey(pet.id),
                delay: Duration(milliseconds: (index * 55).clamp(0, 440)),
              )
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(begin: 0.07, duration: 280.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final bellIcon = unreadCount > 0
        ? const Icon(Icons.notifications_outlined)
            .animate(onPlay: (ctrl) => ctrl.repeat(period: const Duration(seconds: 4)))
            .shake(hz: 4, duration: 500.ms, curve: Curves.easeInOut)
        : const Icon(Icons.notifications_outlined);
    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: bellIcon,
      ),
      tooltip: AppLocalizations.of(context)!.homeNotifTooltip,
      onPressed: () => context.pushNamed('notifications'),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, __) => const _PetCardSkeleton(),
    );
  }
}

class _PetCardSkeleton extends StatefulWidget {
  const _PetCardSkeleton();

  @override
  State<_PetCardSkeleton> createState() => _PetCardSkeletonState();
}

class _PetCardSkeletonState extends State<_PetCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final c = Theme.of(context).colorScheme.onSurface.withOpacity(_anim.value * 0.15);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 140, color: c, margin: const EdgeInsets.only(bottom: 8)),
                    Container(height: 12, width: 100, color: c, margin: const EdgeInsets.only(bottom: 6)),
                    Container(height: 12, width: 80, color: c),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Cins Seçici ─────────────────────────────────────────────────────────────

class _BreedPickerSheet extends StatefulWidget {
  final List<String> breeds;
  final String? selected;
  const _BreedPickerSheet({required this.breeds, this.selected});

  @override
  State<_BreedPickerSheet> createState() => _BreedPickerSheetState();
}

class _BreedPickerSheetState extends State<_BreedPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.breeds;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.breeds
            : widget.breeds.where((b) => b.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.homeBreedSearch,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final breed = _filtered[i];
                  final isSelected = breed == widget.selected;
                  return ListTile(
                    title: Text(breed),
                    trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                    selected: isSelected,
                    onTap: () => Navigator.of(context).pop(breed),
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

// ── Upcoming Reminders Widget ───────────────────────────────────────────────

class _UpcomingRemindersWidget extends ConsumerWidget {
  const _UpcomingRemindersWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(myAppointmentsProvider);

    return apptAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (appointments) {
        final now = DateTime.now();
        final twoDaysLater = now.add(const Duration(days: 2));
        final upcoming = appointments
            .where((a) =>
                (a.status == 'pending' || a.status == 'confirmed') &&
                a.date.isAfter(now.subtract(const Duration(hours: 1))) &&
                a.date.isBefore(twoDaysLater))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 14, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.homeUpcomingAppointments,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF6C63FF),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final a = upcoming[i];
                  final date = a.date;
                  final isToday = date.day == now.day && date.month == now.month;
                  final label = isToday ? AppLocalizations.of(context)!.today : AppLocalizations.of(context)!.tomorrow;
                  final time =
                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  return GestureDetector(
                    onTap: () => context.pushNamed('appointment-detail', pathParameters: {'id': a.id}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                a.vet?.name ?? AppLocalizations.of(context)!.homeApptFallback,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$label · $time',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
