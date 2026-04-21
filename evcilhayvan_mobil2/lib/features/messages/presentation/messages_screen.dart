// lib/features/messages/presentation/screens/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/utils/url_resolver.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/widgets/animated_empty_state.dart';
import 'package:evcilhayvan_mobil2/core/widgets/interactive_scale.dart';
import 'package:evcilhayvan_mobil2/core/widgets/paw_loading.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/adoption/data/repositories/adoption_repository.dart';
import 'package:evcilhayvan_mobil2/features/adoption/domain/models/adoption_application.dart';
import 'package:evcilhayvan_mobil2/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/conservation_model.dart';
import 'package:evcilhayvan_mobil2/features/mating/data/repositories/mating_repository.dart';
import 'package:evcilhayvan_mobil2/features/mating/domain/models/match_request.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';

final _conversationPetProvider = FutureProvider.autoDispose
    .family<Pet?, String>((ref, petId) async {
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
    final l10n = AppLocalizations.of(context)!;
    final safeIndex = initialTabIndex.clamp(0, 1);
    return DefaultTabController(
      length: 2,
      initialIndex: safeIndex,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppPalette.appBarDark,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(l10n.messagesTitle),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            tabs: [
              Tab(text: l10n.messagesTitle),
              Tab(text: l10n.matchRequestsTitle),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [const _ConversationsTab(), const _RequestsTab()],
          ),
        ),
      ),
    );
  }
}

class _ConversationsTab extends ConsumerStatefulWidget {
  const _ConversationsTab();

  @override
  ConsumerState<_ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends ConsumerState<_ConversationsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesConversation(Conversation conversation, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final petName = conversation.relatedPet?.name.toLowerCase() ?? '';
    final relatedPetId = conversation.relatedPetId?.toLowerCase() ?? '';
    return conversation.otherParticipant.name.toLowerCase().contains(
          normalized,
        ) ||
        conversation.lastMessage.toLowerCase().contains(normalized) ||
        petName.contains(normalized) ||
        relatedPetId.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const _Header(),
          const SizedBox(height: 12),
          _ConversationSearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          Expanded(
            child: conversationsAsync.when(
              skipLoadingOnReload: true,
              data: (conversations) {
                final sorted = [...conversations]
                  ..sort((a, b) {
                    final unreadCompare = (b.unreadCount > 0 ? 1 : 0).compareTo(
                      a.unreadCount > 0 ? 1 : 0,
                    );
                    if (unreadCompare != 0) return unreadCompare;
                    return b.updatedAt.compareTo(a.updatedAt);
                  });
                final filtered = sorted
                    .where((conv) => _matchesConversation(conv, _query))
                    .toList(growable: false);

                if (conversations.isEmpty) {
                  return const _EmptyConversations();
                }

                if (filtered.isEmpty) {
                  return _EmptyConversations(
                    hasQuery: true,
                    onReset: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  );
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
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (itemContext, i) {
                      final conv = filtered[i];
                      return Dismissible(
                            key: ValueKey(conv.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              final dl10n = AppLocalizations.of(context)!;
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) {
                                      final ddl10n = AppLocalizations.of(
                                        dialogContext,
                                      )!;
                                      return AlertDialog(
                                        title: Text(ddl10n.chatDeleteTitle),
                                        content: Text(ddl10n.chatDeleteContent),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(false),
                                            child: Text(ddl10n.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(true),
                                            child: Text(ddl10n.delete),
                                          ),
                                        ],
                                      );
                                    },
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) async {
                              try {
                                await ref
                                    .read(messageRepositoryProvider)
                                    .deleteConversation(conv.id);
                                ref.invalidate(conversationsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.msgConvDeleted,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.msgConvDeleteErr(e.toString()),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
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
                              subtitle: conv.lastMessage.isNotEmpty
                                  ? conv.lastMessage
                                  : AppLocalizations.of(context)!.msgConvStart,
                              relatedPet: conv.relatedPet,
                              relatedPetId: conv.relatedPetId,
                              updatedAt: conv.updatedAt,
                              unreadCount: conv.unreadCount,
                              avatarUrl: resolveImageUrl(
                                conv.otherParticipant.avatarUrl,
                              ),
                              onTap: () async {
                                final result = await context.pushNamed(
                                  'chat',
                                  pathParameters: {'conversationId': conv.id},
                                  extra: {
                                    'name': conv.otherParticipant.name,
                                    'avatar': resolveImageUrl(
                                      conv.otherParticipant.avatarUrl,
                                    ),
                                  },
                                );

                                if (result == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.msgConvDeleted,
                                      ),
                                    ),
                                  );
                                  ref.invalidate(conversationsProvider);
                                }
                              },
                            ),
                          )
                          .animate(delay: Duration(milliseconds: i * 60))
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.05);
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

class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab();

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab> {
  bool _showArchived = false;

  static bool _isArchived(String status) {
    final s = status.toUpperCase();
    return s == 'CANCELLED' || s == 'REJECTED';
  }

  @override
  Widget build(BuildContext context) {
    final matchingAsync = ref.watch(inboxMatchRequestsProvider);
    final adoptionAsync = ref.watch(inboxAdoptionApplicationsProvider);

    final matchingCount = matchingAsync.maybeWhen(
      data: (items) =>
          items.where((e) => e.status.toUpperCase() == 'PENDING').length,
      orElse: () => 0,
    );
    final adoptionCount = adoptionAsync.maybeWhen(
      data: (items) =>
          items.where((e) => e.status.toUpperCase() == 'PENDING').length,
      orElse: () => 0,
    );

    // Count archived items for toggle button label
    final archivedMatchCount = matchingAsync.maybeWhen(
      data: (items) => items.where((e) => _isArchived(e.status)).length,
      orElse: () => 0,
    );
    final archivedAdoptCount = adoptionAsync.maybeWhen(
      data: (items) => items.where((e) => _isArchived(e.status)).length,
      orElse: () => 0,
    );
    final totalArchived = archivedMatchCount + archivedAdoptCount;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inboxMatchRequestsProvider);
        ref.invalidate(inboxAdoptionApplicationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(
            title: AppLocalizations.of(context)!.msgMatingRequestsTitle,
            count: matchingCount,
          ),
          const SizedBox(height: 12),
          matchingAsync.when(
            data: (items) {
              final visible = _showArchived
                  ? items
                  : items.where((e) => !_isArchived(e.status)).toList();
              if (visible.isEmpty) {
                return _EmptySection(
                  message: AppLocalizations.of(context)!.msgNoMatingRequests,
                );
              }
              return Column(
                children: visible
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
          _SectionHeader(
            title: AppLocalizations.of(context)!.msgAdoptionRequestsTitle,
            count: adoptionCount,
          ),
          const SizedBox(height: 12),
          adoptionAsync.when(
            data: (items) {
              final visible = _showArchived
                  ? items
                  : items.where((e) => !_isArchived(e.status)).toList();
              if (visible.isEmpty) {
                return _EmptySection(
                  message: AppLocalizations.of(context)!.msgNoAdoptionRequests,
                );
              }
              return Column(
                children: visible
                    .map(
                      (application) =>
                          _AdoptionApplicationCard(application: application),
                    )
                    .toList(),
              );
            },
            loading: () => const _SectionLoading(),
            error: (e, _) => _SectionError(
              message: e.toString(),
              onRetry: () => ref.invalidate(inboxAdoptionApplicationsProvider),
            ),
          ),
          // Archive toggle
          if (totalArchived > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showArchived = !_showArchived),
                icon: Icon(
                  _showArchived ? Icons.visibility_off_outlined : Icons.history,
                  size: 16,
                ),
                label: Text(
                  _showArchived
                      ? 'Geçmişi Gizle'
                      : 'Geçmiş İstekleri Göster ($totalArchived)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
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
      child: const Center(child: PawLoading()),
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
          child: Text(AppLocalizations.of(context)!.retry),
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
        final result = await ref
            .read(matingRepositoryProvider)
            .updateRequestStatus(request.id, action);
        ref.invalidate(inboxMatchRequestsProvider);
        ref.invalidate(conversationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.msgActionDone),
            ),
          );
        }
        if (action == 'accept' &&
            result.conversationId != null &&
            context.mounted) {
          await _openChatForRequest(
            context: context,
            ref: ref,
            participantId: request.fromUser?.id ?? '',
            participantName:
                request.fromUser?.name ??
                AppLocalizations.of(context)!.chatTypeGeneral,
            participantAvatar: request.fromUser?.avatarUrl,
            conversationId: result.conversationId,
            listingId: request.listingId,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                    request.listing?.name ??
                        AppLocalizations.of(context)!.petDetailTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusLabel(status, AppLocalizations.of(context)!),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Deleted advert indicator
            if (status == 'CANCELLED' && request.listing == null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      'İlan artık aktif değil',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            Text(
              AppLocalizations.of(
                context,
              )!.msgSenderLabel(request.fromUser?.name ?? '-'),
            ),
            if ((request.fromPet?.name ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(
                  context,
                )!.msgSelectedPet(request.fromPet!.name),
              ),
            ],
            if (request.fromPetId.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  'pet-detail',
                  pathParameters: {'id': request.fromPetId},
                ),
                icon: const Icon(Icons.pets_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.msgViewSenderListing),
              ),
            ],
            const SizedBox(height: 10),
            if (status == 'PENDING')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respond('accept'),
                      child: Text(
                        AppLocalizations.of(context)!.matchRequestAccept,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond('reject'),
                      child: Text(
                        AppLocalizations.of(context)!.matchRequestReject,
                      ),
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
                    participantName:
                        request.fromUser?.name ??
                        AppLocalizations.of(context)!.chatTypeGeneral,
                    participantAvatar: request.fromUser?.avatarUrl,
                    conversationId: request.conversationId,
                    listingId: request.listingId,
                  ),
                  icon: const Icon(Icons.chat_bubble),
                  label: Text(AppLocalizations.of(context)!.msgGoToChat),
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
        final result = await ref
            .read(adoptionRepositoryProvider)
            .respondToApplication(application.id, action);
        ref.invalidate(inboxAdoptionApplicationsProvider);
        ref.invalidate(conversationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.msgActionDone),
            ),
          );
        }
        if (action == 'accept' &&
            result.conversationId != null &&
            context.mounted) {
          await _openChatForRequest(
            context: context,
            ref: ref,
            participantId: application.applicantUser?.id ?? '',
            participantName:
                application.applicantUser?.name ??
                AppLocalizations.of(context)!.chatTypeGeneral,
            participantAvatar: application.applicantUser?.avatarUrl,
            conversationId: result.conversationId,
            listingId: application.adoptionListingId,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                    application.listing?.name ??
                        AppLocalizations.of(context)!.petDetailTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusLabel(status, AppLocalizations.of(context)!),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(
                context,
              )!.msgApplicantLabel(application.applicantUser?.name ?? '-'),
            ),
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
                      child: Text(
                        AppLocalizations.of(context)!.matchRequestAccept,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond('reject'),
                      child: Text(
                        AppLocalizations.of(context)!.matchRequestReject,
                      ),
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
                    participantName:
                        application.applicantUser?.name ??
                        AppLocalizations.of(context)!.chatTypeGeneral,
                    participantAvatar: application.applicantUser?.avatarUrl,
                    conversationId: application.conversationId,
                    listingId: application.adoptionListingId,
                  ),
                  icon: const Icon(Icons.chat_bubble),
                  label: Text(AppLocalizations.of(context)!.msgGoToChat),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.msgNoRecipient)),
    );
    return;
  }
  final currentUser = ref.read(authProvider);
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.msgLoginRequired)),
    );
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
      final sameListing =
          listingId == null ||
          conversation.contextId == listingId ||
          conversation.relatedPetId == listingId;
      if (sameUser && sameListing) {
        context.pushNamed(
          'chat',
          pathParameters: {'conversationId': conversation.id},
          extra: {
            'name': conversation.otherParticipant.name,
            'avatar':
                conversation.otherParticipant.avatarUrl ?? participantAvatar,
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

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.msgOpenFailed)),
  );
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

String _statusLabel(String status, AppLocalizations l10n) {
  switch (status.toUpperCase()) {
    case 'ACCEPTED':
      return l10n.msgStatusAccepted;
    case 'REJECTED':
      return l10n.msgStatusRejected;
    case 'CANCELLED':
      return l10n.msgStatusCancelled;
    default:
      return l10n.msgStatusPending;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.primary.withOpacity(context.isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2D6A4F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.msgHeaderTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.msgHeaderSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF52B788),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSearchBar extends StatelessWidget {
  const _ConversationSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8F3DC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded),
          hintText: 'Konusma veya ilan ara',
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
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
  final int unreadCount;

  const _ConversationCard({
    required this.title,
    required this.subtitle,
    this.relatedPet,
    this.relatedPetId,
    required this.updatedAt,
    required this.avatarUrl,
    required this.onTap,
    this.unreadCount = 0,
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

    final l10n = AppLocalizations.of(context)!;
    final petChipLabel = petAsync.when(
      data: (pet) => pet?.name ?? l10n.msgListingNotFound,
      loading: () => l10n.msgListingLoading,
      error: (_, __) => l10n.msgListingLoadErr,
    );

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFD8F3DC),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          title.isNotEmpty ? title[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child:
                      Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF52B788),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 1.0,
                            end: 1.25,
                            duration: 1200.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF40916C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        _formatUpdatedAt(updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (relatedPetId != null && relatedPetId!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F3DC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pets,
                            size: 12,
                            color: Color(0xFF2D6A4F),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            petChipLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1B4332),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
  const _EmptyConversations({this.hasQuery = false, this.onReset});

  final bool hasQuery;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      icon: hasQuery ? Icons.search_off_rounded : Icons.chat_bubble_outline,
      title: hasQuery
          ? 'Aramana uyan bir konusma bulunamadi'
          : AppLocalizations.of(context)!.messagesEmpty,
      subtitle: hasQuery
          ? 'Farkli bir isim, ilan veya mesaj parcasi ile tekrar dene.'
          : AppLocalizations.of(context)!.messagesEmptyDesc,
      action: hasQuery
          ? OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Aramayi temizle'),
            )
          : FilledButton.icon(
              onPressed: () => context.goNamed('home'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Ilanlari kesfet'),
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
        final highlightColor = Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.12);
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
            AppLocalizations.of(context)!.msgConvLoadErr,
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
