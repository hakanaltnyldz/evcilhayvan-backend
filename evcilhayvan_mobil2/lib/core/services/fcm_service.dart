import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';

/// Arka planda gelen FCM mesajlarını işler (top-level fonksiyon olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda bildirim zaten sistem tarafından gösterilir
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  // Deep-link stream: dinleyiciler rotayı alıp navigate eder
  static final _routeController = StreamController<String>.broadcast();
  static Stream<String> get routeStream => _routeController.stream;

  /// FCM mesaj verisinden uygulama route'u üretir.
  /// Backend bildirimlerinde `data.type` ve ilgili ID'ler gelmelidir.
  static String routeFromMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    switch (type) {
      case 'message':
      case 'new_message':
        final convId = data['conversationId'] as String?;
        if (convId != null && convId.isNotEmpty) return '/chat/$convId';
        return '/messages';
      case 'match':
      case 'match_request':
      case 'mating_request':
        return '/mating/requests';
      case 'adoption':
      case 'adoption_application':
      case 'adoption_response':
        return '/messages?tab=requests';
      case 'birthday':
        final petId = data['petId'] as String?;
        if (petId != null && petId.isNotEmpty) return '/pet/$petId';
        return '/';
      case 'appointment':
      case 'appointment_reminder':
        final apptId = data['appointmentId'] as String?;
        if (apptId != null && apptId.isNotEmpty) return '/veterinary/appointment/$apptId';
        return '/veterinary';
      case 'vaccination':
      case 'vaccination_reminder':
        final vacPetId = data['petId'] as String?;
        if (vacPetId != null && vacPetId.isNotEmpty) return '/veterinary/vaccination/$vacPetId';
        return '/veterinary';
      case 'order':
      case 'order_update':
      case 'order_status':
        return '/store/orders';
      case 'sitter_booking':
      case 'booking_update':
        return '/sitters/bookings';
      case 'lost_found':
        final lfId = data['reportId'] as String?;
        if (lfId != null && lfId.isNotEmpty) return '/lost-found/$lfId';
        return '/lost-found';
      case 'notification':
      default:
        return '/notifications';
    }
  }

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Önemli Bildirimler',
    description: 'Uygulama bildirimleri için kanal',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Arka plan handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // İzin iste
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android için bildirim kanalı oluştur
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // Ön plandayken gelen mesajları göster
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      // Route'u payload olarak geç → kullanıcı bildirimi tıklayınca navigate et
      final route = routeFromMessage(message);

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: route,
      );
    });

    // Uygulama arka plandayken bildirime tıklanınca navigate et
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeController.add(routeFromMessage(message));
    });

    // FCM token yenilendiğinde backend'i güncelle
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registerToken(newToken);
    });

    // Local notification tıklanınca da deep link
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _routeController.add(payload);
        }
      },
    );
  }

  /// Uygulama tamamen kapalıyken açılan bildirim rotasını kontrol eder.
  /// MainShell.initState() içinde çağrılmalıdır.
  static Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      // Kısa gecikme: router hazır olana kadar bekle
      await Future.delayed(const Duration(milliseconds: 500));
      _routeController.add(routeFromMessage(message));
    }
  }

  /// Kullanıcı giriş yaptıktan sonra (veya token yenilenince) backend'e kaydet.
  /// [fcmToken] verilmezse Firebase'den anlık token alınır.
  static Future<void> registerToken([String? fcmToken]) async {
    try {
      final token = fcmToken ?? await _messaging.getToken();
      if (token == null) return;
      await ApiClient().dio.post(
        '/api/auth/fcm-token',
        data: {'token': token, 'platform': Platform.isAndroid ? 'android' : 'ios'},
      );
    } catch (_) {
      // Token kaydedilemese de uygulama çalışmaya devam eder
    }
  }

  /// Kullanıcı çıkış yaptığında token'ı sil
  static Future<void> unregisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await ApiClient().dio.delete(
        '/api/auth/fcm-token',
        data: {'token': token},
      );
    } catch (_) {}
  }
}
