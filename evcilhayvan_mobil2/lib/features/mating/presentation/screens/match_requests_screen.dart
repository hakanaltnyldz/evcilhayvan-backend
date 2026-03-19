import 'dart:async';

import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/socket_service.dart';
import '../../../../core/widgets/modern_background.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../messages/data/repositories/message_repository.dart';
import '../../data/repositories/mating_repository.dart';
import '../../domain/models/match_request.dart';

class MatchRequestsScreen extends ConsumerWidget {
  const MatchRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.matchRequestsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.matchRequestsInbox),
              Tab(text: AppLocalizations.of(context)!.matchRequestsOutbox),
            ],
          ),
        ),
        body: const ModernBackground(
          child: SafeArea(
            child: TabBarView(
              children: [
                _RequestTab(tabType: _RequestTabType.inbox),
                _RequestTab(tabType: _RequestTabType.outbox),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _RequestTabType { inbox, outbox }

class _RequestTab extends ConsumerWidget {
  const _RequestTab({required this.tabType});
  final _RequestTabType tabType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = tabType == _RequestTabType.inbox
        ? ref.watch(inboxMatchRequestsProvider)
        : ref.watch(outboxMatchRequestsProvider);
    return asyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.matchReqNoRequests));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final request = items[index];
            return _RequestCard(request: request, tabType: tabType);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                if (tabType == _RequestTabType.inbox) {
                  ref.invalidate(inboxMatchRequestsProvider);
                } else {
                  ref.invalidate(outboxMatchRequestsProvider);
                }
              },
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request, required this.tabType});
  final MatchRequest request;
  final _RequestTabType tabType;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  StreamSubscription<ConversationCreatedEvent>? _conversationCreatedSub;
  StreamSubscription<MatchAcceptedEvent>? _matchAcceptedSub;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _conversationCreatedSub?.cancel();
    _matchAcceptedSub?.cancel();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socketService = SocketService();

    // Listen for conversation created events
    _conversationCreatedSub = socketService.onConversationCreated.listen((event) {
      if (!mounted) return;

      // Only handle if this is relevant to our request
      // We'll navigate to chat automatically when conversation is created
      _handleConversationCreated(event);
    });

    // Listen for match accepted events (for the requester side)
    _matchAcceptedSub = socketService.onMatchAccepted.listen((event) {
      if (!mounted) return;

      // Refresh the requests list to show updated status
      ref.invalidate(inboxMatchRequestsProvider);
      ref.invalidate(outboxMatchRequestsProvider);
    });
  }

  void _handleConversationCreated(ConversationCreatedEvent event) {
    if (!mounted || event.conversationId.isEmpty) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    // Only navigate if we're on the inbox tab and we received the request
    // OR if we're on the outbox tab and we sent the request
    final shouldAutoNavigate = (widget.tabType == _RequestTabType.inbox &&
            widget.request.toUser?.id == currentUser.id) ||
        (widget.tabType == _RequestTabType.outbox &&
            widget.request.fromUser?.id == currentUser.id);

    if (!shouldAutoNavigate) return;

    // Get partner info from conversation data or request
    final conversation = event.conversation;
    final l10n = AppLocalizations.of(context)!;
    String partnerName = l10n.chatTypeGeneral;
    String? partnerAvatar;

    if (conversation != null && conversation['participants'] is List) {
      final participants = conversation['participants'] as List;
      for (final p in participants) {
        if (p is Map<String, dynamic> && p['_id'] != currentUser.id) {
          partnerName = p['name']?.toString() ?? l10n.chatTypeGeneral;
          partnerAvatar = p['avatarUrl']?.toString();
          break;
        }
      }
    } else {
      // Fallback to request data
      final other = widget.tabType == _RequestTabType.inbox
          ? widget.request.fromUser
          : widget.request.toUser;
      partnerName = other?.name ?? l10n.chatTypeGeneral;
      partnerAvatar = other?.avatarUrl;
    }

    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.matchReqMatchSuccess(partnerName)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: l10n.matchReqGoNow,
          onPressed: () {
            _navigateToChat(event.conversationId, partnerName, partnerAvatar);
          },
        ),
      ),
    );

    // Auto-navigate after a short delay to let user see the snackbar
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToChat(event.conversationId, partnerName, partnerAvatar);
      }
    });
  }

  void _navigateToChat(String conversationId, String name, String? avatar) {
    if (!mounted) return;
    context.pushNamed(
      'chat',
      pathParameters: {'conversationId': conversationId},
      extra: {'name': name, 'avatar': avatar},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(theme, widget.request.status);
    final statusLabel = _statusLabel(widget.request.status, l10n);
    final currentUser = ref.watch(authProvider);

    Future<void> _act(String action) async {
      final repo = ref.read(matingRepositoryProvider);
      try {
        final result = await repo.updateRequestStatus(widget.request.id, action);
        ref.invalidate(inboxMatchRequestsProvider);
        ref.invalidate(outboxMatchRequestsProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.matchReqActDone(action))));

        // For accept action, navigation will be handled by socket event listener
        // But as a fallback, if conversationId is immediately available, navigate
        if (action == 'accept' && result.conversationId != null && context.mounted) {
          final other = (widget.tabType == _RequestTabType.inbox ? result.request.fromUser : result.request.toUser) ??
              (widget.tabType == _RequestTabType.inbox ? widget.request.fromUser : widget.request.toUser);
          final targetName = other?.name ?? AppLocalizations.of(context)!.chatTypeGeneral;

          // Navigate immediately for the user who accepted
          _navigateToChat(result.conversationId!, targetName, other?.avatarUrl);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    Future<void> _goToChat() async {
      final otherUserId = widget.tabType == _RequestTabType.inbox
          ? widget.request.fromUser?.id
          : widget.request.toUser?.id;
      final otherUser = widget.tabType == _RequestTabType.inbox
          ? widget.request.fromUser
          : widget.request.toUser;
      if (otherUserId == null || currentUser == null) return;

      if (widget.request.conversationId != null && context.mounted) {
        _navigateToChat(
          widget.request.conversationId!,
          otherUser?.name ?? AppLocalizations.of(context)!.chatTypeGeneral,
          otherUser?.avatarUrl,
        );
        return;
      }

      final messageRepo = ref.read(messageRepositoryProvider);
      try {
        final convo = await messageRepo.createOrGetConversation(
          participantId: otherUserId,
          relatedPetId: widget.request.listingId,
          currentUserId: currentUser.id,
        );
        if (context.mounted) {
          _navigateToChat(
            convo.id,
            convo.otherParticipant.name,
            convo.otherParticipant.avatarUrl,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.matchReqChatError(e.toString()))));
        }
      }
    }

    final listingName = widget.request.listing?.name ?? l10n.petDetailTitle;
    final fromPetName = widget.request.fromPet?.name ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listingName,
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
                    statusLabel,
                    style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.tabType == _RequestTabType.inbox
                  ? l10n.matchReqSenderLabel(widget.request.fromUser?.name ?? '-')
                  : l10n.matchReqReceiverLabel(widget.request.toUser?.name ?? '-'),
              style: theme.textTheme.bodyMedium,
            ),
            if (fromPetName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.tabType == _RequestTabType.inbox
                    ? l10n.matchReqSenderPet(fromPetName)
                    : l10n.matchReqSelectedPet(fromPetName),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (widget.tabType == _RequestTabType.inbox && widget.request.fromPetId.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  'pet-detail',
                  pathParameters: {'id': widget.request.fromPetId},
                ),
                icon: const Icon(Icons.pets_outlined, size: 18),
                label: Text(l10n.matchReqViewListing),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (widget.tabType == _RequestTabType.inbox && widget.request.status == 'PENDING') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _act('accept'),
                      child: Text(l10n.matchReqAccept),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _act('reject'),
                      child: Text(l10n.matchReqReject),
                    ),
                  ),
                ] else if (widget.request.status == 'ACCEPTED') ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _goToChat,
                      icon: const Icon(Icons.chat_bubble),
                      label: Text(l10n.matchReqGoToChat),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
}
