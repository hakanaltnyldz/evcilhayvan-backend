// lib/core/socket_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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

  ConversationCreatedEvent({required this.conversationId, this.conversation});

  factory ConversationCreatedEvent.fromJson(Map<String, dynamic> json) {
    return ConversationCreatedEvent(
      conversationId: json['conversationId']?.toString() ?? '',
      conversation: json['conversation'] is Map<String, dynamic>
          ? json['conversation'] as Map<String, dynamic>
          : null,
    );
  }
}

class SitterLocationEvent {
  final String bookingId;
  final double lat;
  final double lng;
  final int updatedAt;

  SitterLocationEvent({
    required this.bookingId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory SitterLocationEvent.fromJson(Map<String, dynamic> json) =>
      SitterLocationEvent(
        bookingId: json['bookingId']?.toString() ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      );
}

class SitterWalkEvent {
  final String bookingId;
  final bool started; // true=walk_started, false=walk_ended

  SitterWalkEvent({required this.bookingId, required this.started});
}

class SitterLocationOfflineEvent {
  final String bookingId;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastUpdated;
  final String message;

  SitterLocationOfflineEvent({
    required this.bookingId,
    this.lastLat,
    this.lastLng,
    this.lastUpdated,
    this.message = 'Bakıcının konumu alınamıyor.',
  });

  factory SitterLocationOfflineEvent.fromJson(Map<String, dynamic> json) =>
      SitterLocationOfflineEvent(
        bookingId: json['bookingId']?.toString() ?? '',
        lastLat: json['lastLat'] != null ? (json['lastLat'] as num).toDouble() : null,
        lastLng: json['lastLng'] != null ? (json['lastLng'] as num).toDouble() : null,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'].toString())
            : null,
        message: json['message']?.toString() ?? 'Bakıcının konumu alınamıyor.',
      );
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  String? _currentUserId;
  bool _isConnecting = false;

  factory SocketService() => _instance;
  SocketService._internal();

  // Stream controllers for events
  final _matchRequestController =
      StreamController<MatchRequestEvent>.broadcast();
  final _matchAcceptedController =
      StreamController<MatchAcceptedEvent>.broadcast();
  final _matchRejectedController =
      StreamController<MatchRejectedEvent>.broadcast();
  final _newMessageController = StreamController<NewMessageEvent>.broadcast();
  final _conversationCreatedController =
      StreamController<ConversationCreatedEvent>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _sitterLocationController =
      StreamController<SitterLocationEvent>.broadcast();
  final _sitterWalkController = StreamController<SitterWalkEvent>.broadcast();
  final _sitterLocationOfflineController =
      StreamController<SitterLocationOfflineEvent>.broadcast();
  final _appointmentUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _careReportController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<MatchRequestEvent> get onMatchRequest =>
      _matchRequestController.stream;
  Stream<MatchAcceptedEvent> get onMatchAccepted =>
      _matchAcceptedController.stream;
  Stream<MatchRejectedEvent> get onMatchRejected =>
      _matchRejectedController.stream;
  Stream<NewMessageEvent> get onNewMessage => _newMessageController.stream;
  Stream<ConversationCreatedEvent> get onConversationCreated =>
      _conversationCreatedController.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;
  Stream<SitterLocationEvent> get onSitterLocation =>
      _sitterLocationController.stream;
  Stream<SitterWalkEvent> get onSitterWalk => _sitterWalkController.stream;
  Stream<SitterLocationOfflineEvent> get onSitterLocationOffline =>
      _sitterLocationOfflineController.stream;
  Stream<Map<String, dynamic>> get onAppointmentUpdated =>
      _appointmentUpdatedController.stream;
  Stream<Map<String, dynamic>> get onBookingUpdate =>
      _bookingUpdateController.stream;
  Stream<Map<String, dynamic>> get onCareReport => _careReportController.stream;

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

      final token = await ApiClient().tokenStorage.accessToken;

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
        _connectionStatusController.add(true);

        // Auto-join user room on connect
        if (userId != null) {
          _currentUserId = userId;
          socket.emit('join:user', userId);
        }
      });

      socket.onDisconnect((_) {
        _connectionStatusController.add(false);
      });

      socket.onReconnect((_) {
        _connectionStatusController.add(true);
        // Rejoin user room on reconnect
        if (_currentUserId != null) {
          socket.emit('join:user', _currentUserId);
        }
      });

      socket.onConnectError((_) {});
      socket.onError((_) {});

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
      try {
        final event = MatchRequestEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _matchRequestController.add(event);
      } catch (e) {}
    });

    // Match accepted listener
    socket.on('match_accepted', (data) {
      try {
        final event = MatchAcceptedEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _matchAcceptedController.add(event);
      } catch (e) {}
    });

    // Match rejected listener
    socket.on('match_rejected', (data) {
      try {
        final event = MatchRejectedEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _matchRejectedController.add(event);
      } catch (e) {}
    });

    // New message listener (for notifications when not in chat)
    socket.on('new_message', (data) {
      try {
        final event = NewMessageEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _newMessageController.add(event);
      } catch (e) {}
    });

    // Conversation created listener
    socket.on('conversation:created', (data) {
      try {
        final event = ConversationCreatedEvent.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
        );
        _conversationCreatedController.add(event);
      } catch (e) {}
    });

    // Sitter location events
    socket.on('sitter:location_update', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data);
        _sitterLocationController.add(SitterLocationEvent.fromJson(map));
      } catch (e) {}
    });

    socket.on('sitter:walk_started', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data);
        _sitterWalkController.add(
          SitterWalkEvent(
            bookingId: map['bookingId']?.toString() ?? '',
            started: true,
          ),
        );
      } catch (e) {}
    });

    socket.on('sitter:walk_ended', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data);
        _sitterWalkController.add(
          SitterWalkEvent(
            bookingId: map['bookingId']?.toString() ?? '',
            started: false,
          ),
        );
      } catch (e) {}
    });

    // Sitter location offline (grace period bitti, konum kayboldu)
    socket.on('sitter:location_offline', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data);
        _sitterLocationOfflineController
            .add(SitterLocationOfflineEvent.fromJson(map));
      } catch (e) {}
    });

    // Appointment updated (randevu durum değişimi)
    socket.on('appointment:updated', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        _appointmentUpdatedController.add(map);
      } catch (e) {}
    });

    // Sitter booking update (bakıcı rezervasyon güncelleme)
    socket.on('booking:update', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        _bookingUpdateController.add(map);
      } catch (e) {}
    });

    // Care report (bakım raporu)
    socket.on('booking:care_report', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        _careReportController.add(map);
      } catch (e) {}
    });
  }

  void joinUserRoom(String userId) {
    _currentUserId = userId;
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('join:user', userId);
    } else {
      socket.onConnect((_) {
        socket.emit('join:user', userId);
      });
    }
  }

  void joinRoom(String conversationId) {
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('join:conversation', conversationId);
    } else {
      socket.onConnect((_) {
        socket.emit('join:conversation', conversationId);
      });
    }
  }

  void leaveRoom(String conversationId) {
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('leave:conversation', conversationId);
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

  void joinBookingRoom(String bookingId) {
    _socket?.emit('join:booking', {'bookingId': bookingId});
  }

  void emitSitterLocation(String bookingId, double lat, double lng) {
    _socket?.emit('sitter:location_update', {
      'bookingId': bookingId,
      'lat': lat,
      'lng': lng,
    });
  }

  void emitWalkStarted(String bookingId) {
    _socket?.emit('sitter:walk_started', {'bookingId': bookingId});
  }

  void emitWalkEnded(String bookingId) {
    _socket?.emit('sitter:walk_ended', {'bookingId': bookingId});
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
    _sitterLocationController.close();
    _sitterWalkController.close();
    _appointmentUpdatedController.close();
    _bookingUpdateController.close();
    _careReportController.close();
    disconnect();
  }
}
