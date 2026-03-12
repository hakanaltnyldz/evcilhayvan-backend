// lib/core/socket_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'http.dart';

// Event data models
class MatchRequestEvent {
  final String requestId;
  final String senderName;
  final String senderPetName;
  final String? senderPetImage;
  final String? fromAdvertId;

  MatchRequestEvent({
    required this.requestId,
    required this.senderName,
    required this.senderPetName,
    this.senderPetImage,
    this.fromAdvertId,
  });

  factory MatchRequestEvent.fromJson(Map<String, dynamic> json) {
    return MatchRequestEvent(
      requestId: json['requestId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Bilinmeyen',
      senderPetName: json['senderPetName']?.toString() ?? 'Bilinmeyen',
      senderPetImage: json['senderPetImage']?.toString(),
      fromAdvertId: json['fromAdvertId']?.toString(),
    );
  }
}

class MatchAcceptedEvent {
  final String conversationId;
  final String matchRequestId;
  final String partnerName;
  final String partnerPetName;

  MatchAcceptedEvent({
    required this.conversationId,
    required this.matchRequestId,
    required this.partnerName,
    required this.partnerPetName,
  });

  factory MatchAcceptedEvent.fromJson(Map<String, dynamic> json) {
    return MatchAcceptedEvent(
      conversationId: json['conversationId']?.toString() ?? '',
      matchRequestId: json['matchRequestId']?.toString() ?? '',
      partnerName: json['partnerName']?.toString() ?? 'Bilinmeyen',
      partnerPetName: json['partnerPetName']?.toString() ?? 'Bilinmeyen',
    );
  }
}

class MatchRejectedEvent {
  final String matchRequestId;
  final String rejectorName;

  MatchRejectedEvent({
    required this.matchRequestId,
    required this.rejectorName,
  });

  factory MatchRejectedEvent.fromJson(Map<String, dynamic> json) {
    return MatchRejectedEvent(
      matchRequestId: json['matchRequestId']?.toString() ?? '',
      rejectorName: json['rejectorName']?.toString() ?? 'Bilinmeyen',
    );
  }
}

class NewMessageEvent {
  final String conversationId;
  final String message;
  final String senderName;
  final DateTime timestamp;

  NewMessageEvent({
    required this.conversationId,
    required this.message,
    required this.senderName,
    required this.timestamp,
  });

  factory NewMessageEvent.fromJson(Map<String, dynamic> json) {
    return NewMessageEvent(
      conversationId: json['conversationId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Bilinmeyen',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ConversationCreatedEvent {
  final String conversationId;
  final Map<String, dynamic>? conversation;

  ConversationCreatedEvent({
    required this.conversationId,
    this.conversation,
  });

  factory ConversationCreatedEvent.fromJson(Map<String, dynamic> json) {
    return ConversationCreatedEvent(
      conversationId: json['conversationId']?.toString() ?? '',
      conversation: json['conversation'] is Map<String, dynamic>
          ? json['conversation'] as Map<String, dynamic>
          : null,
    );
  }
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  String? _currentUserId;
  bool _isConnecting = false;

  factory SocketService() => _instance;
  SocketService._internal();

  // Stream controllers for events
  final _matchRequestController = StreamController<MatchRequestEvent>.broadcast();
  final _matchAcceptedController = StreamController<MatchAcceptedEvent>.broadcast();
  final _matchRejectedController = StreamController<MatchRejectedEvent>.broadcast();
  final _newMessageController = StreamController<NewMessageEvent>.broadcast();
  final _conversationCreatedController = StreamController<ConversationCreatedEvent>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Public streams
  Stream<MatchRequestEvent> get onMatchRequest => _matchRequestController.stream;
  Stream<MatchAcceptedEvent> get onMatchAccepted => _matchAcceptedController.stream;
  Stream<MatchRejectedEvent> get onMatchRejected => _matchRejectedController.stream;
  Stream<NewMessageEvent> get onNewMessage => _newMessageController.stream;
  Stream<ConversationCreatedEvent> get onConversationCreated => _conversationCreatedController.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get currentUserId => _currentUserId;

  Future<void> connect({String? userId}) async {
    if (_isConnecting) return;
    if (_socket != null && _socket!.connected) {
      // Already connected, just join user room if userId provided
      if (userId != null && userId != _currentUserId) {
        _currentUserId = userId;
        _socket!.emit('join:user', userId);
      }
      return;
    }

    _isConnecting = true;

    try {
      _socket?.dispose();

      final backendUri = Uri.parse(apiBaseUrl);
      final authority = backendUri.hasPort
          ? '${backendUri.scheme}://${backendUri.host}:${backendUri.port}'
          : '${backendUri.scheme}://${backendUri.host}';

      final prefs = await SharedPreferences.getInstance();
      // accessToken veya token key'lerinden birini dene
      final token = prefs.getString('accessToken') ?? prefs.getString('token');

      final builder = IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000);

      if (token != null && token.isNotEmpty) {
        builder.setExtraHeaders({'Authorization': 'Bearer $token'});
        builder.setAuth({'token': token});
      }

      final socket = IO.io(authority, builder.build());
      _socket = socket;

      // Connection events
      socket.onConnect((_) {
        print('Socket connected: ${socket.id}');
        _connectionStatusController.add(true);

        // Auto-join user room on connect
        if (userId != null) {
          _currentUserId = userId;
          socket.emit('join:user', userId);
          print('Joined user room: user:$userId');
        }
      });

      socket.onDisconnect((_) {
        print('Socket disconnected');
        _connectionStatusController.add(false);
      });

      socket.onReconnect((_) {
        print('Socket reconnected');
        _connectionStatusController.add(true);
        // Rejoin user room on reconnect
        if (_currentUserId != null) {
          socket.emit('join:user', _currentUserId);
        }
      });

      socket.onConnectError((e) => print('Socket connect_error: $e'));
      socket.onError((e) => print('Socket error: $e'));

      // Setup event listeners
      _setupEventListeners(socket);

      socket.connect();

      // Store userId for later
      if (userId != null) {
        _currentUserId = userId;
      }
    } finally {
      _isConnecting = false;
    }
  }

  void _setupEventListeners(IO.Socket socket) {
    // Match request listener
    socket.on('match_request', (data) {
      print('Received match_request: $data');
      try {
        final event = MatchRequestEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _matchRequestController.add(event);
      } catch (e) {
        print('Error parsing match_request: $e');
      }
    });

    // Match accepted listener
    socket.on('match_accepted', (data) {
      print('Received match_accepted: $data');
      try {
        final event = MatchAcceptedEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _matchAcceptedController.add(event);
      } catch (e) {
        print('Error parsing match_accepted: $e');
      }
    });

    // Match rejected listener
    socket.on('match_rejected', (data) {
      print('Received match_rejected: $data');
      try {
        final event = MatchRejectedEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _matchRejectedController.add(event);
      } catch (e) {
        print('Error parsing match_rejected: $e');
      }
    });

    // New message listener (for notifications when not in chat)
    socket.on('new_message', (data) {
      print('Received new_message: $data');
      try {
        final event = NewMessageEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _newMessageController.add(event);
      } catch (e) {
        print('Error parsing new_message: $e');
      }
    });

    // Message:new listener (for chat screen updates)
    socket.on('message:new', (data) {
      print('Received message:new: $data');
      // This is handled by the existing onMessage callback
    });

    // Conversation created listener
    socket.on('conversation:created', (data) {
      print('Received conversation:created: $data');
      try {
        final event = ConversationCreatedEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _conversationCreatedController.add(event);
      } catch (e) {
        print('Error parsing conversation:created: $e');
      }
    });
  }

  void joinUserRoom(String userId) {
    _currentUserId = userId;
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('join:user', userId);
      print('Joined user room: user:$userId');
    } else {
      socket.onConnect((_) {
        socket.emit('join:user', userId);
        print('Joined user room on connect: user:$userId');
      });
    }
  }

  void joinRoom(String conversationId) {
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('join:conversation', conversationId);
      print('Joined conversation room: conv:$conversationId');
    } else {
      socket.onConnect((_) {
        socket.emit('join:conversation', conversationId);
        print('Joined conversation room on connect: conv:$conversationId');
      });
    }
  }

  void leaveRoom(String conversationId) {
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('leave:conversation', conversationId);
      print('Left conversation room: conv:$conversationId');
    }
  }

  void onMessage(void Function(dynamic) callback) {
    final socket = _socket;
    if (socket == null) return;
    socket.off('message:new');
    socket.on('message:new', callback);
  }

  void onEvent(String event, void Function(dynamic) callback) {
    final socket = _socket;
    if (socket == null) return;
    socket.off(event);
    socket.on(event, callback);
  }

  void offEvent(String event) {
    final socket = _socket;
    if (socket == null) return;
    socket.off(event);
  }

  void sendMessage({
    required String conversationId,
    required Map<String, dynamic> message,
  }) {
    final socket = _socket;
    if (socket == null) return;
    socket.emit('sendMessage', {
      'conversationId': conversationId,
      'message': message,
    });
  }

  void disconnect() {
    final socket = _socket;
    if (socket == null) return;
    socket.disconnect();
    socket.dispose();
    _socket = null;
    _currentUserId = null;
    _connectionStatusController.add(false);
  }

  void dispose() {
    _matchRequestController.close();
    _matchAcceptedController.close();
    _matchRejectedController.close();
    _newMessageController.close();
    _conversationCreatedController.close();
    _connectionStatusController.close();
    disconnect();
  }
}
