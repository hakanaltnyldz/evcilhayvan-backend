// lib/features/auth/presentation/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String petId, String advertType) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text('Bu ilanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
              onPressed: () async {
                try {
                  await ref.read(petsRepositoryProvider).deletePet(petId);
                  ref.invalidate(myAdvertsProvider(advertType));
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İlan başarıyla silindi.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap'),
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
                    'Profili görmek için giriş yapmalısınız.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.goNamed('login'),
                    child: const Text('Giriş Yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // İstatistikler için ilanları izle
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
              tooltip: 'Sahiplendirme Başvuruları',
              onPressed: () => context.pushNamed('adoption-applications'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.pushNamed('settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sahiplendirme İlanlarım'),
              Tab(text: 'Eşleştirme İlanlarım'),
            ],
          ),
        ),
        body: ModernBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Profil başlığı
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _ProfileHeader(
                    user: currentUser,
                    onLogout: () => _logout(context, ref),
                    onEdit: () => context.pushNamed('edit-profile'),
                  ),
                ),

                // İstatistikler
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _StatsRow(
                    adoptionCount: adoptionCount,
                    matingCount: matingCount,
                    totalViews: totalViews,
                  ),
                ),

                // Hızlı erişim
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _QuickLinksCard(user: currentUser),
                ),

                // Yeni ilan butonları
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.pushNamed('create-pet', extra: {'advertType': 'adoption'}),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Sahiplendirme'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.pushNamed('create-pet', extra: {'advertType': 'mating'}),
                          icon: const Icon(Icons.favorite, size: 18),
                          label: const Text('Eşleştirme'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: TabBarView(
                    children: [
                      _AdvertsTab(
                        advertType: 'adoption',
                        onEdit: (pet) => context.pushNamed('create-pet', extra: {'pet': pet}),
                        onDelete: (pet) => _showDeleteDialog(context, ref, pet.id, 'adoption'),
                      ),
                      _AdvertsTab(
                        advertType: 'mating',
                        onEdit: (pet) => context.pushNamed('create-pet', extra: {'pet': pet}),
                        onDelete: (pet) => _showDeleteDialog(context, ref, pet.id, 'mating'),
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

// ─── Profil Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.user, required this.onLogout, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = _resolveAvatarUrl(user.avatarUrl);
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2F5EA), Color(0xFFE9D8FD)],
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
      child: Row(
        children: [
          // Avatar (tıklanınca profil düzenle)
          GestureDetector(
            onTap: onEdit,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(initial, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppPalette.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // İsim ve e-posta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.role != null && user.role != 'user') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor(user.role).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roleLabel(user.role),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _roleColor(user.role)),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Çıkış butonu (token'ları temizler)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Çıkış Yap',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'seller': return Colors.blue;
      case 'sitter': return Colors.teal;
      case 'admin':  return Colors.red;
      default:       return Colors.grey;
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'seller': return 'Satıcı';
      case 'sitter': return 'Sitter';
      case 'admin':  return 'Admin';
      default:       return role ?? '';
    }
  }
}

// ─── İstatistik Satırı ────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int adoptionCount;
  final int matingCount;
  final int totalViews;

  const _StatsRow({required this.adoptionCount, required this.matingCount, required this.totalViews});

  @override
  Widget build(BuildContext context) {
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
          _StatItem(icon: Icons.pets, color: Colors.green, value: adoptionCount.toString(), label: 'Sahiplendirme'),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _StatItem(icon: Icons.favorite, color: Colors.purple, value: matingCount.toString(), label: 'Eşleştirme'),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _StatItem(
            icon: Icons.remove_red_eye_outlined,
            color: Colors.blue,
            value: totalViews > 999 ? '${(totalViews / 1000).toStringAsFixed(1)}K' : totalViews.toString(),
            label: 'Görüntülenme',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Hızlı Erişim Kartı ──────────────────────────────────────────────────────
class _QuickLinksCard extends StatelessWidget {
  final User user;
  const _QuickLinksCard({required this.user});

  @override
  Widget build(BuildContext context) {
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
          _QuickLinkBtn(icon: Icons.favorite_outline,      label: 'Favoriler',  color: Colors.red,    onTap: () => context.pushNamed('favorites')),
          _QuickLinkBtn(icon: Icons.shopping_bag_outlined, label: 'Siparişler', color: Colors.orange,  onTap: () => context.push('/store/orders')),
          _QuickLinkBtn(icon: Icons.pets_outlined,         label: 'Sitter',     color: Colors.teal,   onTap: () => context.pushNamed('sitter-bookings')),
          _QuickLinkBtn(icon: Icons.notifications_outlined,label: 'Bildirimler',color: Colors.indigo, onTap: () => context.pushNamed('notifications')),
          if (isSeller)
            _QuickLinkBtn(icon: Icons.store_outlined, label: 'Mağazam', color: Colors.blue, onTap: () => context.pushNamed('seller-dashboard')),
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

// ─── İlanlar Tab'ı ────────────────────────────────────────────────────────────
class _AdvertsTab extends ConsumerWidget {
  final String advertType;
  final void Function(Pet) onEdit;
  final void Function(Pet) onDelete;

  const _AdvertsTab({required this.advertType, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advertsAsync = ref.watch(myAdvertsProvider(advertType));

    Future<void> refresh() async {
      ref.invalidate(myAdvertsProvider(advertType));
      try { await ref.read(myAdvertsProvider(advertType).future); } catch (_) {}
    }

    String mapError(Object error) {
      if (error is ApiError && error.message.isNotEmpty) return error.message;
      final lower = error.toString().toLowerCase();
      if (lower.contains('auth') || lower.contains('token')) return 'Oturum doğrulanamadı. Tekrar deneyin.';
      return 'İlanlar yüklenemedi: $error';
    }

    return advertsAsync.when(
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

// ─── Boş ilan kartı ──────────────────────────────────────────────────────────
class _NoPetsCard extends StatelessWidget {
  const _NoPetsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Henüz ilan yok', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'İlk ilanınızı oluşturarak topluluğa yeni bir dost kazandırabilirsiniz.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bildirim zili ───────────────────────────────────────────────────────────
class _NotificationBellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(fontSize: 10)),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Bildirimler',
      onPressed: () => context.pushNamed('notifications'),
    );
  }
}

String? _resolveAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return '$apiBaseUrl$url';
}
