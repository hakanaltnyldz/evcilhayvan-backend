import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/features/notifications/providers/notification_provider.dart';
import 'widgets/pet_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _nearbyActive = false;
  bool _locLoading = false;

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
            const SnackBar(content: Text('Konum izni gerekli')),
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
          SnackBar(content: Text('Konum alınamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final firstName = (user?.name ?? '').split(' ').first;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('İlanları Keşfet'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Ara',
              onPressed: () => context.pushNamed('search'),
            ),
            IconButton(
              icon: const Icon(Icons.location_searching),
              tooltip: 'Kayip & Bulunan',
              onPressed: () => context.pushNamed('lost-found'),
            ),
            _NotificationBell(),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFc7d2fe), Color(0xFFeef2ff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sahiplendirme'),
              Tab(text: 'Eşleştirme'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFeef2ff), Color(0xFFF8F9FB)],
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
                  // Yakınımdakiler filter chip
                  Row(
                    children: [
                      _locLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : FilterChip(
                              label: const Text('Yakınımdakiler'),
                              avatar: Icon(
                                Icons.near_me_rounded,
                                size: 16,
                                color: _nearbyActive ? Colors.white : null,
                              ),
                              selected: _nearbyActive,
                              onSelected: (_) => _toggleNearby(),
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(
                                color: _nearbyActive ? Colors.white : null,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
    final greeting = _getGreeting();
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
                    firstName != null ? '$greeting, $firstName!' : 'Hoş geldin!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sana en uygun pati dostunu keşfet.',
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

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Günaydın';
    if (hour >= 12 && hour < 18) return 'İyi günler';
    if (hour >= 18 && hour < 22) return 'İyi akşamlar';
    return 'İyi geceler';
  }
}

class _QuickShortcutsRow extends StatelessWidget {
  const _QuickShortcutsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _ShortcutCard(
            label: 'Eşleştir',
            icon: Icons.favorite_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
            ),
            onTap: () => context.pushNamed('mating'),
          ),
          _ShortcutCard(
            label: 'Bakıcı\nBul',
            icon: Icons.pets_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
            ),
            onTap: () => context.pushNamed('sitters'),
          ),
          _ShortcutCard(
            label: 'Etkinlik',
            icon: Icons.event_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF6FCF97), Color(0xFF27AE60)],
            ),
            onTap: () => context.pushNamed('events'),
          ),
          _ShortcutCard(
            label: 'Kayıp &\nBulunan',
            icon: Icons.location_searching_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF2994A), Color(0xFFEB5757)],
            ),
            onTap: () => context.pushNamed('lost-found'),
          ),
          _ShortcutCard(
            label: 'Harita',
            icon: Icons.map_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            ),
            onTap: () => context.pushNamed('map'),
          ),
          _ShortcutCard(
            label: 'Feed',
            icon: Icons.dynamic_feed_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
            ),
            onTap: () => context.pushNamed('feed'),
          ),
          _ShortcutCard(
            label: 'Pati\nAsistan',
            icon: Icons.smart_toy_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A59), Color(0xFFFF9F7F)],
            ),
            onTap: () => context.pushNamed('ai-assistant'),
          ),
        ],
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
      return const EmptyState(
        title: 'Henüz ilan yok',
        subtitle: 'İlan eklendiğinde burada göreceksin.',
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
          return TweenAnimationBuilder<double>(
            key: ValueKey(pet.id),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: (400 + (index * 60)).clamp(400, 800)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 24 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: PetCard(
              pet: pet,
              onTap: () => context.pushNamed(
                'pet-detail',
                pathParameters: {'id': pet.id},
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Bildirimler',
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
