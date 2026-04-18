enum NotificationType {
  matchRequest,
  matchAccepted,
  matchRejected,
  newMessage,
  adoptionNew,
  adoptionAccepted,
  adoptionRejected,
  vaccinationReminder,
  orderUpdate,
  lostFoundNearby,
  sitterBooking,
  appointment,
  general,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseType(json['type']?.toString() ?? 'general'),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'matchRequest': return NotificationType.matchRequest;
      case 'matchAccepted': return NotificationType.matchAccepted;
      case 'matchRejected': return NotificationType.matchRejected;
      case 'newMessage': return NotificationType.newMessage;
      case 'adoptionNew': return NotificationType.adoptionNew;
      case 'adoptionAccepted': return NotificationType.adoptionAccepted;
      case 'adoptionRejected': return NotificationType.adoptionRejected;
      case 'vaccinationReminder': return NotificationType.vaccinationReminder;
      case 'orderUpdate': return NotificationType.orderUpdate;
      case 'lostFoundNearby': return NotificationType.lostFoundNearby;
      case 'sitterBooking': return NotificationType.sitterBooking;
      case 'appointment': return NotificationType.appointment;
      default: return NotificationType.general;
    }
  }

  String get icon {
    switch (type) {
      case NotificationType.matchRequest: return 'favorite';
      case NotificationType.matchAccepted: return 'check_circle';
      case NotificationType.matchRejected: return 'cancel';
      case NotificationType.newMessage: return 'chat';
      case NotificationType.adoptionNew: return 'pets';
      case NotificationType.adoptionAccepted: return 'volunteer_activism';
      case NotificationType.adoptionRejected: return 'block';
      case NotificationType.vaccinationReminder: return 'vaccines';
      case NotificationType.orderUpdate: return 'local_shipping';
      case NotificationType.lostFoundNearby: return 'location_searching';
      case NotificationType.sitterBooking: return 'pets';
      case NotificationType.appointment: return 'calendar_month';
      case NotificationType.general: return 'notifications';
    }
  }
}
