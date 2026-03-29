// lib/features/auth/presentation/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/core/widgets/state_views.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/auth/domain/user_model.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/features/notifications/providers/notification_provider.dart';

import '../../../pets/presentation/screens/widgets/pet_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String petId,
    String advertType,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.profileDeleteTitle),
          content: Text(l10n.profileDeleteContent),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
              onPressed: () async {
                try {
                  await ref.read(petsRepositoryProvider).deletePet(petId);
                  ref.invalidate(myAdvertsProvider(advertType));
                  ref.invalidate(myAdvertsProvider('adoption'));
                  ref.invalidate(myAdvertsProvider('mating'));
                  ref.invalidate(adoptionPaginatedProvider);
                  ref.invalidate(matingPaginatedProvider);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.profileDeleteSuccess), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileLogoutTitle),
        content: Text(l10n.profileLogoutContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profileLogout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.goNamed('login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authProvider);

    if (currentUser == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: ModernBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    l10n.profileLoginRequired,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.goNamed('login'),
                    child: Text(l10n.profileLoginBtn),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final adoptionAsync = ref.watch(myAdvertsProvider('adoption'));
    final matingAsync   = ref.watch(myAdvertsProvider('mating'));
    final adoptionCount = adoptionAsync.valueOrNull?.length ?? 0;
    final matingCount   = matingAsync.valueOrNull?.length ?? 0;
    final totalViews    = [
      ...adoptionAsync.valueOrNull ?? [],
      ...matingAsync.valueOrNull   ?? [],
    ].fold<int>(0, (s, pet) => s + (pet.viewCount as int));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            _NotificationBellButton(),
            IconButton(
              icon: const Icon(Icons.volunteer_activism),
              tooltip: l10n.profileAdoptionApplications,
              onPressed: () => context.pushNamed('adoption-applications'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.pushNamed('settings'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.profileTabMyAds),
              Tab(text: l10n.profileTabMatingAds),
            ],
          ),
        ),
        body: ModernBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _ProfileHeader(
                    user: currentUser,
                    onLogout: () => _logout(context, ref, l10n),
                    onEdit: () => context.pushNamed('edit-profile'),
                    adoptionCount: adoptionCount,
                    matingCount: matingCount,
                    totalViews: totalViews,
                  ),
                ),

                _ProfileCompletionCard(user: currentUser, onEdit: () => context.pushNamed('edit-profile')),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.pushNamed('create-pet', extra: {'advertType': 'adoption'}),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Sahiplendir', overflow: TextOverflow.ellipsis),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.pushNamed('create-pet', extra: {'advertType': 'mating'}),
                          icon: const Icon(Icons.favorite, size: 16),
                          label: const Text('Eşleştir', overflow: TextOverflow.ellipsis),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF52B788),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                Expanded(
                  child: TabBarView(
                    children: [
                      _AdvertsTab(
                        advertType: 'adoption',
                        onEdit: (pet) => context.pushNamed('create-pet', extra: {'pet': pet}),
                        onDelete: (pet) => _showDeleteDialog(context, ref, pet.id, 'adoption', l10n),
                      ),
                      _AdvertsTab(
                        advertType: 'mating',
                        onEdit: (pet) => context.pushNamed('create-pet', extra: {'pet': pet}),
                        onDelete: (pet) => _showDeleteDialog(context, ref, pet.id, 'mating', l10n),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;
  final VoidCallback onEdit;
  final int adoptionCount;
  final int matingCount;
  final int totalViews;

  const _ProfileHeader({
    required this.user,
    required this.onLogout,
    required this.onEdit,
    required this.adoptionCount,
    required this.matingCount,
    required this.totalViews,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final avatarUrl = _resolveAvatarUrl(user.avatarUrl);
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D2B1E), const Color(0xFF1B4332)]
              : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.15),
                      backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(initial, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
                          : null,
                    )
                        .animate(
                          onPlay: (ctrl) => ctrl.repeat(reverse: true, period: const Duration(seconds: 3)),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.06, 1.06),
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Color(0xFF2D6A4F), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.role != null && user.role != 'user') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _roleColor(user.role).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _roleLabel(user.role, l10n),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _roleColor(user.role)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: l10n.profileLogoutTitle,
                onPressed: onLogout,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: theme.colorScheme.outline.withOpacity(0.25)),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatItem(icon: Icons.pets, color: const Color(0xFF2D6A4F), intValue: adoptionCount, label: l10n.profileAdoptionCount),
              Container(width: 1, height: 36, color: theme.colorScheme.outline.withOpacity(0.25)),
              _StatItem(icon: Icons.favorite, color: const Color(0xFF52B788), intValue: matingCount, label: l10n.profileMatingCount),
              Container(width: 1, height: 36, color: theme.colorScheme.outline.withOpacity(0.25)),
              _StatItem(icon: Icons.remove_red_eye_outlined, color: const Color(0xFF40916C), intValue: totalViews, label: l10n.profileViewCount),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'seller': return const Color(0xFF2D6A4F);
      case 'sitter': return const Color(0xFF40916C);
      case 'admin':  return Colors.red;
      default:       return Colors.grey;
    }
  }

  String _roleLabel(String? role, AppLocalizations l10n) {
    switch (role) {
      case 'seller': return l10n.profileRoleSeller;
      case 'sitter': return l10n.profileRoleSitter;
      case 'admin':  return l10n.profileRoleAdmin;
      default:       return role ?? '';
    }
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int adoptionCount;
  final int matingCount;
  final int totalViews;

  const _StatsRow({required this.adoptionCount, required this.matingCount, required this.totalViews});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _StatItem(icon: Icons.pets, color: const Color(0xFF2D6A4F), intValue: adoptionCount, label: l10n.profileAdoptionCount),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          _StatItem(icon: Icons.favorite, color: const Color(0xFF52B788), intValue: matingCount, label: l10n.profileMatingCount),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          _StatItem(
            icon: Icons.remove_red_eye_outlined,
            color: const Color(0xFF40916C),
            intValue: totalViews,
            label: l10n.profileViewCount,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int intValue;
  final String label;

  const _StatItem({required this.icon, required this.color, required this.intValue, required this.label});

  String _formatValue(int v) => v > 999 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: intValue),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text(
              _formatValue(v),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Links Card ──────────────────────────────────────────────────────────
class _QuickLinksCard extends StatelessWidget {
  final User user;
  const _QuickLinksCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSeller = user.role == 'seller';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickLinkBtn(icon: Icons.favorite_outline,      label: l10n.profileFavorites,     color: Colors.red,                   onTap: () => context.pushNamed('favorites')),
          _QuickLinkBtn(icon: Icons.shopping_bag_outlined, label: l10n.profileOrders,         color: Colors.orange,                onTap: () => context.push('/store/orders')),
          _QuickLinkBtn(icon: Icons.pets_outlined,         label: l10n.profileSitterBtn,      color: const Color(0xFF40916C),      onTap: () => context.pushNamed('sitter-bookings')),
          _QuickLinkBtn(icon: Icons.notifications_outlined,label: l10n.profileNotifications,  color: const Color(0xFF2D6A4F),      onTap: () => context.pushNamed('notifications')),
          if (isSeller)
            _QuickLinkBtn(icon: Icons.store_outlined, label: l10n.profileMyStore, color: const Color(0xFF52B788), onTap: () => context.pushNamed('seller-dashboard')),
        ],
      ),
    );
  }
}

class _QuickLinkBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLinkBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Adverts Tab ────────────────────────────────────────────────────────────────
class _AdvertsTab extends ConsumerWidget {
  final String advertType;
  final void Function(Pet) onEdit;
  final void Function(Pet) onDelete;

  const _AdvertsTab({required this.advertType, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final advertsAsync = ref.watch(myAdvertsProvider(advertType));

    Future<void> refresh() async {
      ref.invalidate(myAdvertsProvider(advertType));
      try { await ref.read(myAdvertsProvider(advertType).future); } catch (_) {}
    }

    String mapError(Object error) {
      if (error is ApiError && error.message.isNotEmpty) return error.message;
      final lower = error.toString().toLowerCase();
      if (lower.contains('auth') || lower.contains('token')) return l10n.profileAuthErr;
      return l10n.profileAdsLoadErr(error.toString());
    }

    return advertsAsync.when(
      skipLoadingOnReload: false,
      data: (pets) {
        if (pets.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 24), _NoPetsCard()],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Stack(
                  children: [
                    PetCard(
                      pet: pet,
                      onTap: () => context.pushNamed('pet-detail', pathParameters: {'id': pet.id}),
                    ),
                    Positioned(
                      top: 16,
                      right: 24,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5)),
                            onPressed: () => onEdit(pet),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5)),
                            onPressed: () => onDelete(pet),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [const SizedBox(height: 48), ErrorView(message: mapError(e), onRetry: refresh)],
        ),
      ),
    );
  }
}

// ─── No Pets Card ──────────────────────────────────────────────────────────────
class _NoPetsCard extends StatelessWidget {
  const _NoPetsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(l10n.profileNoPetsTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.profileNoPetsDesc,
              style: theme.textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Bell ───────────────────────────────────────────────────────
class _NotificationBellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = ref.watch(unreadCountProvider);
    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(fontSize: 10)),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: l10n.profileNotifications,
      onPressed: () => context.pushNamed('notifications'),
    );
  }
}

String? _resolveAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return '$apiBaseUrl$url';
}

// ─── Profile Completion Card ──────────────────────────────────────────────────

class _ProfileCompletionCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;

  const _ProfileCompletionCard({required this.user, required this.onEdit});

  int get _completedCount {
    int count = 0;
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) count++;
    if (user.city != null && user.city!.isNotEmpty) count++;
    if (user.about != null && user.about!.isNotEmpty) count++;
    return count;
  }

  static const int _totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completed = _completedCount;
    if (completed == _totalSteps) return const SizedBox.shrink();

    final percent = completed / _totalSteps;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_pin_outlined, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.profileCompletePercent((percent * 100).round()),
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingChip extends StatelessWidget {
  final String label;
  const _MissingChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_circle_outline, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
