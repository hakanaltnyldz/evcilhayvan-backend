// lib/features/auth/presentation/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/config/app_config.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  String _imgUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.current.apiBaseUrl}/$path';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userPublicProfileProvider(userId));

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.userProfileLoadErr, style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => ref.invalidate(userPublicProfileProvider(userId)),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
        data: (data) {
          final l10n = AppLocalizations.of(context)!;
          final userJson = data['user'] as Map<String, dynamic>? ?? {};
          final petsJson = (data['pets'] as List<dynamic>?) ?? [];

          final name = userJson['name'] as String? ?? l10n.userProfileDefaultName;
          final city = userJson['city'] as String?;
          final avatarUrl = userJson['avatarUrl'] as String?;
          final about = userJson['about'] as String?;
          final isSeller = userJson['isSeller'] == true;
          final memberSince = userJson['memberSince'] as String?;
          final year = memberSince != null ? DateTime.tryParse(memberSince)?.year : null;

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, ref, name, avatarUrl, city, isSeller, year),
              if (about != null && about.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.userProfileAbout,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(about, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    l10n.userProfileListings(petsJson.length),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (petsJson.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(l10n.userProfileNoListings, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final pet = petsJson[i] as Map<String, dynamic>? ?? {};
                        return _PetMiniCard(pet: pet, imgUrl: _imgUrl);
                      },
                      childCount: petsJson.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String name,
    String? avatarUrl,
    String? city,
    bool isSeller,
    int? year,
  ) {
    final currentUser = ref.watch(authProvider);
    final isMe = currentUser?.id == userId;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Avatar + info
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.15),
                    backgroundImage:
                        avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(_imgUrl(avatarUrl))
                            : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Color(0xFF2D6A4F))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSeller) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.profileRoleSeller,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (city != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 13, color: Colors.white70),
                              const SizedBox(width: 2),
                              Text(city,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                        if (year != null) ...[
                          const SizedBox(height: 2),
                          Text(AppLocalizations.of(context)!.userProfileMemberSince(year!),
                              style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isMe)
          IconButton(
            icon: const Icon(Icons.message_rounded, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.userProfileMessageTooltip,
            onPressed: () => _openChat(context, ref),
          ),
      ],
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;
    try {
      final conv = await ref.read(messageRepositoryProvider).createOrGetConversation(
            participantId: userId,
            currentUserId: currentUser.id,
          );
      if (!context.mounted) return;
      context.pushNamed(
        'chat',
        pathParameters: {'conversationId': conv.id},
        extra: {'name': conv.otherParticipant.name, 'avatar': conv.otherParticipant.avatarUrl},
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userProfileChatErr(e.toString()))),
      );
    }
  }
}

class _PetMiniCard extends StatelessWidget {
  const _PetMiniCard({required this.pet, required this.imgUrl});
  final Map<String, dynamic> pet;
  final String Function(String?) imgUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = pet['name'] as String? ?? '?';
    final species = pet['species'] as String? ?? '';
    final breed = pet['breed'] as String? ?? '';
    final advertType = pet['advertType'] as String? ?? '';
    final photos = (pet['photos'] as List<dynamic>?)?.cast<String>() ?? [];
    final petId = pet['_id'] ?? pet['id'] ?? '';

    String photoUrl = photos.isNotEmpty ? imgUrl(photos.first) : '';

    Color typeColor = const Color(0xFF2D6A4F);
    String typeLabel = '';
    switch (advertType) {
      case 'adoption':
        typeColor = Colors.green;
        typeLabel = l10n.userProfileTypeAdopt;
        break;
      case 'mating':
        typeColor = Colors.pink;
        typeLabel = l10n.userProfileTypeMating;
        break;
      case 'lost':
        typeColor = Colors.orange;
        typeLabel = l10n.userProfileTypeLost;
        break;
      default:
        typeLabel = advertType;
    }

    return GestureDetector(
      onTap: () => context.pushNamed('pet-detail', pathParameters: {'id': petId.toString()}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(Icons.pets, color: Theme.of(context).colorScheme.outlineVariant, size: 40),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Icon(Icons.pets, color: Theme.of(context).colorScheme.outlineVariant, size: 40),
                          ),
                    if (typeLabel.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    breed.isNotEmpty ? '$species · $breed' : species,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
