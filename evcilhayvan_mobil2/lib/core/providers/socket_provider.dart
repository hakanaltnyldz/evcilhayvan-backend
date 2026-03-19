// lib/core/providers/socket_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../socket_service.dart';

// Socket service provider (singleton)
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

// Connection status provider
final socketConnectionProvider = StreamProvider<bool>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onConnectionStatus;
});

// Match request count provider (for badge)
final matchRequestCountProvider = StateProvider<int>((ref) => 0);

// Unread message count provider (for badge)
final unreadMessageCountProvider = StateProvider<int>((ref) => 0);

// Current chat conversation ID (to know if user is in chat)
final currentChatConversationProvider = StateProvider<String?>((ref) => null);

// Socket notification state
class SocketNotificationState {
  final List<MatchRequestEvent> pendingMatchRequests;
  final List<MatchAcceptedEvent> pendingMatchAccepted;
  final List<MatchRejectedEvent> pendingMatchRejected;
  final List<NewMessageEvent> pendingMessages;

  const SocketNotificationState({
    this.pendingMatchRequests = const [],
    this.pendingMatchAccepted = const [],
    this.pendingMatchRejected = const [],
    this.pendingMessages = const [],
  });

  SocketNotificationState copyWith({
    List<MatchRequestEvent>? pendingMatchRequests,
    List<MatchAcceptedEvent>? pendingMatchAccepted,
    List<MatchRejectedEvent>? pendingMatchRejected,
    List<NewMessageEvent>? pendingMessages,
  }) {
    return SocketNotificationState(
      pendingMatchRequests: pendingMatchRequests ?? this.pendingMatchRequests,
      pendingMatchAccepted: pendingMatchAccepted ?? this.pendingMatchAccepted,
      pendingMatchRejected: pendingMatchRejected ?? this.pendingMatchRejected,
      pendingMessages: pendingMessages ?? this.pendingMessages,
    );
  }
}

// Socket notification notifier
class SocketNotificationNotifier extends StateNotifier<SocketNotificationState> {
  final Ref ref;
  final List<StreamSubscription> _subscriptions = [];

  SocketNotificationNotifier(this.ref) : super(const SocketNotificationState()) {
    _initListeners();
  }

  void _initListeners() {
    final socketService = ref.read(socketServiceProvider);

    // Match request listener
    _subscriptions.add(
      socketService.onMatchRequest.listen((event) {
        state = state.copyWith(
          pendingMatchRequests: [...state.pendingMatchRequests, event],
        );
        // Increment badge count
        ref.read(matchRequestCountProvider.notifier).state++;
      }),
    );

    // Match accepted listener
    _subscriptions.add(
      socketService.onMatchAccepted.listen((event) {
        state = state.copyWith(
          pendingMatchAccepted: [...state.pendingMatchAccepted, event],
        );
      }),
    );

    // Match rejected listener
    _subscriptions.add(
      socketService.onMatchRejected.listen((event) {
        state = state.copyWith(
          pendingMatchRejected: [...state.pendingMatchRejected, event],
        );
      }),
    );

    // New message listener
    _subscriptions.add(
      socketService.onNewMessage.listen((event) {
        final currentChatId = ref.read(currentChatConversationProvider);

        // Only show notification if not in the same chat
        if (currentChatId != event.conversationId) {
          state = state.copyWith(
            pendingMessages: [...state.pendingMessages, event],
          );
          // Increment unread count
          ref.read(unreadMessageCountProvider.notifier).state++;
        }
      }),
    );
  }

  void clearMatchRequest(String requestId) {
    state = state.copyWith(
      pendingMatchRequests: state.pendingMatchRequests
          .where((e) => e.requestId != requestId)
          .toList(),
    );
  }

  void clearAllMatchRequests() {
    state = state.copyWith(pendingMatchRequests: []);
    ref.read(matchRequestCountProvider.notifier).state = 0;
  }

  void clearMatchAccepted(String matchRequestId) {
    state = state.copyWith(
      pendingMatchAccepted: state.pendingMatchAccepted
          .where((e) => e.matchRequestId != matchRequestId)
          .toList(),
    );
  }

  void clearMatchRejected(String matchRequestId) {
    state = state.copyWith(
      pendingMatchRejected: state.pendingMatchRejected
          .where((e) => e.matchRequestId != matchRequestId)
          .toList(),
    );
  }

  void clearMessage(String conversationId) {
    state = state.copyWith(
      pendingMessages: state.pendingMessages
          .where((e) => e.conversationId != conversationId)
          .toList(),
    );
  }

  void clearAllMessages() {
    state = state.copyWith(pendingMessages: []);
    ref.read(unreadMessageCountProvider.notifier).state = 0;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

final socketNotificationProvider =
    StateNotifierProvider<SocketNotificationNotifier, SocketNotificationState>(
  (ref) => SocketNotificationNotifier(ref),
);

// Helper widget to show socket notifications
class SocketNotificationListener extends ConsumerStatefulWidget {
  final Widget child;
  final void Function(BuildContext context, MatchRequestEvent event)? onMatchRequest;
  final void Function(BuildContext context, MatchAcceptedEvent event)? onMatchAccepted;
  final void Function(BuildContext context, MatchRejectedEvent event)? onMatchRejected;
  final void Function(BuildContext context, NewMessageEvent event)? onNewMessage;

  const SocketNotificationListener({
    super.key,
    required this.child,
    this.onMatchRequest,
    this.onMatchAccepted,
    this.onMatchRejected,
    this.onNewMessage,
  });

  @override
  ConsumerState<SocketNotificationListener> createState() =>
      _SocketNotificationListenerState();
}

class _SocketNotificationListenerState
    extends ConsumerState<SocketNotificationListener> {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    final socketService = ref.read(socketServiceProvider);

    if (widget.onMatchRequest != null) {
      _subscriptions.add(
        socketService.onMatchRequest.listen((event) {
          if (mounted) {
            widget.onMatchRequest!(context, event);
          }
        }),
      );
    }

    if (widget.onMatchAccepted != null) {
      _subscriptions.add(
        socketService.onMatchAccepted.listen((event) {
          if (mounted) {
            widget.onMatchAccepted!(context, event);
          }
        }),
      );
    }

    if (widget.onMatchRejected != null) {
      _subscriptions.add(
        socketService.onMatchRejected.listen((event) {
          if (mounted) {
            widget.onMatchRejected!(context, event);
          }
        }),
      );
    }

    if (widget.onNewMessage != null) {
      _subscriptions.add(
        socketService.onNewMessage.listen((event) {
          if (mounted) {
            widget.onNewMessage!(context, event);
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Utility functions for showing notifications
void showMatchRequestSnackBar(BuildContext context, MatchRequestEvent event) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${event.senderName} size ${event.senderPetName} ile eslesme istegi gonderdi!',
      ),
      action: SnackBarAction(
        label: 'Gor',
        onPressed: () {
          // Navigate to match requests
        },
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

void showMatchAcceptedSnackBar(
  BuildContext context,
  MatchAcceptedEvent event, {
  VoidCallback? onGoToChat,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${event.partnerName} eslesme isteginizi kabul etti! ${event.partnerPetName} ile eslestiniz.',
      ),
      action: SnackBarAction(
        label: 'Sohbete Git',
        onPressed: onGoToChat ?? () {},
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.green,
    ),
  );
}

void showMatchRejectedSnackBar(BuildContext context, MatchRejectedEvent event) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${event.rejectorName} eslesme isteginizi reddetti.',
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.orange,
    ),
  );
}

void showNewMessageSnackBar(
  BuildContext context,
  NewMessageEvent event, {
  VoidCallback? onGoToChat,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${event.senderName}: ${event.message.length > 30 ? '${event.message.substring(0, 30)}...' : event.message}',
      ),
      action: SnackBarAction(
        label: 'Gor',
        onPressed: onGoToChat ?? () {},
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
