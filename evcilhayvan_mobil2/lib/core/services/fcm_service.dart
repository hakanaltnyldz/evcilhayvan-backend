import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
        return '/veterinary';
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
      );
    });

    // Uygulama arka plandayken bildirime tıklanınca navigate et
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeController.add(routeFromMessage(message));
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

  /// Kullanıcı giriş yaptıktan sonra token'ı backend'e kaydet
  static Future<void> registerToken(String authToken, String baseUrl) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('$baseUrl/api/notifications/register-token'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $authToken');
      request.write('{"token":"$token","platform":"android"}');
      await request.close();
      client.close();
    } catch (_) {
      // Token kaydedilemese de uygulama çalışmaya devam eder
    }
  }

  /// Kullanıcı çıkış yaptığında token'ı sil
  static Future<void> unregisterToken(String authToken, String baseUrl) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final client = HttpClient();
      final request = await client.deleteUrl(
        Uri.parse('$baseUrl/api/notifications/unregister-token'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $authToken');
      request.write('{"token":"$token"}');
      await request.close();
      client.close();
    } catch (_) {}
  }
}
