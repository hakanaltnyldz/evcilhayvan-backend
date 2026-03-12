// lib/features/messages/presentation/screens/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/adoption/data/repositories/adoption_repository.dart';
import 'package:evcilhayvan_mobil2/features/adoption/domain/models/adoption_application.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvan_mobil2/features/mating/data/repositories/mating_repository.dart';
import 'package:evcilhayvan_mobil2/features/mating/domain/models/match_request.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';

final _conversationPetProvider =
    FutureProvider.autoDispose.family<Pet?, String>((ref, petId) async {
  final repo = ref.watch(petsRepositoryProvider);
  try {
    return await repo.getPetById(petId);
  } catch (_) {
    return null;
  }
});

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeIndex = initialTabIndex.clamp(0, 1);
    return DefaultTabController(
      length: 2,
      initialIndex: safeIndex,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Sohbetler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sohbetler'),
              Tab(text: 'İstekler'),
            ],
          ),
        ),
        body: ModernBackground(
          child: SafeArea(
            child: TabBarView(
              children: [
                const _ConversationsTab(),
                const _RequestsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationsTab extends ConsumerWidget {
  const _ConversationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const _Header(),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const _EmptyConversations();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.refresh(conversationsProvider.future);
                  },
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 24, top: 12),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (itemContext, index) {
                      final conv = conversations[index];
                      return Dismissible(
                        key: ValueKey(conv.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Sohbeti sil'),
                                  content: const Text(
                                    'Bu sohbeti kalici olarak silmek istediginize emin misiniz?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: const Text('Vazgec'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) async {
                          try {
                            await ref.read(messageRepositoryProvider).deleteConversation(conv.id);
                            ref.invalidate(conversationsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sohbet silindi'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sohbet silinemedi: $e')),
                              );
                            }
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.error.withOpacity(0.8),
                                theme.colorScheme.error.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.delete_forever,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                        child: _ConversationCard(
                          title: conv.otherParticipant.name,
                          subtitle: conv.lastMessage.isNotEmpty ? conv.lastMessage : 'Sohbete basla',
                          relatedPet: conv.relatedPet,
                          relatedPetId: conv.relatedPetId,
                          updatedAt: conv.updatedAt,
                          avatarUrl: _resolveAvatarUrl(
                            conv.otherParticipant.avatarUrl,
                          ),
                          onTap: () async {
                            final result = await context.pushNamed(
                              'chat',
                              pathParameters: {'conversationId': conv.id},
                              extra: {
                                'name': conv.otherParticipant.name,
                                'avatar': _resolveAvatarUrl(
                                  conv.otherParticipant.avatarUrl,
                                ),
                              },
                            );

                            if (result == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sohbet silindi'),
                                ),
                              );
                              ref.invalidate(conversationsProvider);
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const _LoadingState(),
              error: (error, stack) => _ErrorState(message: error.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingAsync = ref.watch(inboxMatchRequestsProvider);
    final adoptionAsync = ref.watch(inboxAdoptionApplicationsProvider);

    final matchingCount = matchingAsync.maybeWhen(
      data: (items) => items.where((e) => e.status.toUpperCase() == 'PENDING').length,
      orElse: () => 0,
    );
    final adoptionCount = adoptionAsync.maybeWhen(
      data: (items) => items.where((e) => e.status.toUpperCase() == 'PENDING').length,
      orElse: () => 0,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inboxMatchRequestsProvider);
        ref.invalidate(inboxAdoptionApplicationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(title: 'Eşleştirme İstekleri', count: matchingCount),
          const SizedBox(height: 12),
          matchingAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EmptySection(message: 'Henüz eşleştirme isteği yok.');
              }
              return Column(
                children: items
                    .map((request) => _MatchingRequestCard(request: request))
                    .toList(),
              );
            },
            loading: () => const _SectionLoading(),
            error: (e, _) => _SectionError(
              message: e.toString(),
              onRetry: () => ref.invalidate(inboxMatchRequestsProvider),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Sahiplendirme Başvuruları', count: adoptionCount),
          const SizedBox(height: 12),
          adoptionAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EmptySection(message: 'Henüz başvuru yok.');
              }
              return Column(
                children: items
                    .map((application) => _AdoptionApplicationCard(application: application))
                    .toList(),
              );
            },
            loading: () => const _SectionLoading(),
            error: (e, _) => _SectionError(
              message: e.toString(),
              onRetry: () => ref.invalidate(inboxAdoptionApplicationsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (count > 0) _Badge(text: count.toString()),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Tekrar dene'),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}

class _MatchingRequestCard extends ConsumerWidget {
  final MatchRequest request;

  const _MatchingRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = request.status.toUpperCase();
    final statusColor = _statusColor(theme, status);

    Future<void> _respond(String action) async {
      try {
        final result = await ref.read(matingRepositoryProvider).updateRequestStatus(request.id, action);
        ref.invalidate(inboxMatchRequestsProvider);
        ref.invalidate(conversationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('İşlem tamamlandı: $action')));
        }
        if (action == 'accept' && result.conversationId != null && context.mounted) {
          await _openChatForRequest(
            context: context,
            ref: ref,
            participantId: request.fromUser?.id ?? '',
            participantName: request.fromUser?.name ?? 'Sohbet',
            participantAvatar: request.fromUser?.avatarUrl,
            conversationId: result.conversationId,
            listingId: request.listingId,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.listing?.name ?? 'Ilan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Gönderen: ${request.fromUser?.name ?? '-'}'),
            if ((request.fromPet?.name ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Seçilen pet: ${request.fromPet?.name}'),
            ],
            if (request.fromPetId.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  'pet-detail',
                  pathParameters: {'id': request.fromPetId},
                ),
                icon: const Icon(Icons.pets_outlined, size: 18),
                label: const Text('Gönderen ilanını gör'),
              ),
            ],
            const SizedBox(height: 10),
            if (status == 'PENDING')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respond('accept'),
                      child: const Text('Kabul Et'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond('reject'),
                      child: const Text('Reddet'),
                    ),
                  ),
                ],
              )
            else if (status == 'ACCEPTED')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openChatForRequest(
                    context: context,
                    ref: ref,
                    participantId: request.fromUser?.id ?? '',
                    participantName: request.fromUser?.name ?? 'Sohbet',
                    participantAvatar: request.fromUser?.avatarUrl,
                    conversationId: request.conversationId,
                    listingId: request.listingId,
                  ),
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text('Sohbete git'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdoptionApplicationCard extends ConsumerWidget {
  final AdoptionApplication application;

  const _AdoptionApplicationCard({required this.application});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = application.status.toUpperCase();
    final statusColor = _statusColor(theme, status);

    Future<void> _respond(String action) async {
      try {
        final result = await ref.read(adoptionRepositoryProvider).respondToApplication(application.id, action);
        ref.invalidate(inboxAdoptionApplicationsProvider);
        ref.invalidate(conversationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('İşlem tamamlandı: $action')));
        }
        if (action == 'accept' && result.conversationId != null && context.mounted) {
          await _openChatForRequest(
            context: context,
            ref: ref,
            participantId: application.applicantUser?.id ?? '',
            participantName: application.applicantUser?.name ?? 'Sohbet',
            participantAvatar: application.applicantUser?.avatarUrl,
            conversationId: result.conversationId,
            listingId: application.adoptionListingId,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.listing?.name ?? 'Ilan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Başvuran: ${application.applicantUser?.name ?? '-'}'),
            if ((application.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(application.note!),
            ],
            const SizedBox(height: 10),
            if (status == 'PENDING')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respond('accept'),
                      child: const Text('Kabul Et'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond('reject'),
                      child: const Text('Reddet'),
                    ),
                  ),
                ],
              )
            else if (status == 'ACCEPTED')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openChatForRequest(
                    context: context,
                    ref: ref,
                    participantId: application.applicantUser?.id ?? '',
                    participantName: application.applicantUser?.name ?? 'Sohbet',
                    participantAvatar: application.applicantUser?.avatarUrl,
                    conversationId: application.conversationId,
                    listingId: application.adoptionListingId,
                  ),
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text('Sohbete git'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openChatForRequest({
  required BuildContext context,
  required WidgetRef ref,
  required String participantId,
  required String participantName,
  String? participantAvatar,
  String? conversationId,
  String? listingId,
}) async {
  if (participantId.trim().isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Karşı taraf bilgisi bulunamadı.')));
    return;
  }
  final currentUser = ref.read(authProvider);
  if (currentUser == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sohbet için giriş yapın.')));
    return;
  }

  if (conversationId != null && conversationId.isNotEmpty) {
    context.pushNamed(
      'chat',
      pathParameters: {'conversationId': conversationId},
      extra: {'name': participantName, 'avatar': participantAvatar},
    );
    return;
  }

  final repo = ref.read(messageRepositoryProvider);
  try {
    final conversations = await repo.getMyConversations(currentUser.id);
    for (final conversation in conversations) {
      final sameUser = conversation.otherParticipant.id == participantId;
      final sameListing = listingId == null ||
          conversation.contextId == listingId ||
          conversation.relatedPetId == listingId;
      if (sameUser && sameListing) {
        context.pushNamed(
          'chat',
          pathParameters: {'conversationId': conversation.id},
          extra: {
            'name': conversation.otherParticipant.name,
            'avatar': conversation.otherParticipant.avatarUrl ?? participantAvatar,
          },
        );
        return;
      }
    }
  } catch (_) {
    // ignore
  }

  if (listingId != null) {
    try {
      final convo = await repo.createOrGetConversation(
        participantId: participantId,
        relatedPetId: listingId,
        currentUserId: currentUser.id,
      );
      context.pushNamed(
        'chat',
        pathParameters: {'conversationId': convo.id},
        extra: {
          'name': convo.otherParticipant.name,
          'avatar': convo.otherParticipant.avatarUrl ?? participantAvatar,
        },
      );
      return;
    } catch (_) {
      // ignore
    }
  }

  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Sohbet açılamadı.')));
}

Color _statusColor(ThemeData theme, String status) {
  switch (status.toUpperCase()) {
    case 'ACCEPTED':
      return Colors.green;
    case 'REJECTED':
      return theme.colorScheme.error;
    case 'CANCELLED':
      return Colors.grey;
    default:
      return theme.colorScheme.primary;
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'ACCEPTED':
      return 'Kabul edildi';
    case 'REJECTED':
      return 'Reddedildi';
    case 'CANCELLED':
      return 'İptal edildi';
    default:
      return 'Beklemede';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppPalette.heroGradient.first.withOpacity(0.26),
            AppPalette.heroGradient.last.withOpacity(0.24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sohbet kutunu renklendir',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sahiplendirme görüşmelerini, ilan sorularını ve yeni dostlukları burada yönet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=360&q=80',
              width: 90,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 100,
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.pets,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Pet? relatedPet;
  final String? relatedPetId;
  final DateTime updatedAt;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.title,
    required this.subtitle,
    this.relatedPet,
    this.relatedPetId,
    required this.updatedAt,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    AsyncValue<Pet?> petAsync;
    if (relatedPet != null) {
      petAsync = AsyncValue<Pet?>.data(relatedPet);
    } else if (relatedPetId != null && relatedPetId!.isNotEmpty) {
      petAsync = ref.watch(_conversationPetProvider(relatedPetId!));
    } else {
      petAsync = const AsyncData<Pet?>(null);
    }

    final petChipLabel = petAsync.when(
      data: (pet) => pet?.name ?? 'İlan bilgisi bulunamadı',
      loading: () => 'İlan yükleniyor...',
      error: (_, __) => 'İlan bilgisi alınamadı',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.background,
              AppPalette.heroGradient.last.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatUpdatedAt(updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppPalette.accentGradient,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          petChipLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=420&q=80',
                height: 140,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  width: 200,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 38,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Henüz bir konuşma yok',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Evcil dostlar hakkında konuşmaya başlamak için ilanlardan birine göz at.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 32),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: ShimmerTile(index: index),
        );
      },
    );
  }
}

class ShimmerTile extends StatefulWidget {
  final int index;
  const ShimmerTile({super.key, required this.index});

  @override
  State<ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final baseColor = Theme.of(context).colorScheme.surface;
        final highlightColor =
            Theme.of(context).colorScheme.primary.withOpacity(0.12);
        final t = 0.5 + (_controller.value * 0.5);
        final color = Color.lerp(baseColor, highlightColor, t)!;

        return Container(
          height: 86,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Sohbetler yüklenemedi',
            style: theme.textTheme.titleMedium,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatUpdatedAt(DateTime time) {
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String? _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}
