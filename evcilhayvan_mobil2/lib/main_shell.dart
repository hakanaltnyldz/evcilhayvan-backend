import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/services/fcm_service.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_colors.dart';

import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'package:evcilhayvan_mobil2/core/socket_service.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/auth/domain/user_model.dart';
import 'package:evcilhayvan_mobil2/features/notifications/domain/models/app_notification.dart';
import 'package:evcilhayvan_mobil2/features/notifications/providers/notification_provider.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/store/data/order_repository.dart';
import 'package:evcilhayvan_mobil2/features/pet_sitter/data/repositories/pet_sitter_repository.dart';
import 'package:evcilhayvan_mobil2/core/widgets/birthday_celebration.dart';
import 'package:evcilhayvan_mobil2/features/store/providers/cart_providers.dart';
import 'package:evcilhayvan_mobil2/features/store/providers/guest_cart_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  final List<StreamSubscription> _socketSubscriptions = [];
  StreamSubscription<String>? _fcmRouteSub;

  // ─── Çevrimdışı banner ────────────────────────────────────────────────────
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const List<String?> _routeNames = [
    'messages', // 0: Sohbetler
    'home', // 1: Sahiplen
    'veterinary', // 2: Veteriner
    'store', // 3: Magaza
    'profile', // 4: Profil
  ];

  @override
  void initState() {
    super.initState();
    _initSocketConnection();
    _initConnectivity();
    _initFcmDeepLinks();
  }

  void _initFcmDeepLinks() {
    // Arka planda bildirime tıklanınca navigate et
    _fcmRouteSub = FcmService.routeStream.listen((route) {
      if (mounted) context.go(route);
    });
    // Uygulama tamamen kapalıyken açılan bildirim
    FcmService.checkInitialMessage();
  }

  void _initConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        setState(() => _isOffline = offline);
        if (!offline && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.shellReconnected),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _fcmRouteSub?.cancel();
    for (final sub in _socketSubscriptions) {
      sub.cancel();
    }
    // Clean up custom socket event listeners
    try {
      final socketService = ref.read(socketServiceProvider);
      socketService.offEvent('vaccination:reminder');
      socketService.offEvent('adoption:new_application');
      socketService.offEvent('adoption:accepted');
      socketService.offEvent('lostfound:new');
      socketService.offEvent('order:status_update');
      socketService.offEvent('advert:expiry_warning');
      socketService.offEvent('sitter:new_booking');
      socketService.offEvent('sitter:booking_update');
      socketService.offEvent('sitter:location_offline');
      socketService.offEvent('pet:birthday');
      socketService.offEvent('appointment:reminder');
      socketService.offEvent('appointment:updated');
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initSocketConnection() async {
    // Wait for next frame to ensure ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authProvider);
      if (user == null) return;

      final socketService = ref.read(socketServiceProvider);
      await socketService.connect(userId: user.id);

      _setupSocketListeners(socketService);
      _checkBirthdays();
      // Init FCM after auth confirmed
      FcmService.init().catchError((_) {});
    });
  }

  Future<void> _checkBirthdays() async {
    try {
      await Future.delayed(const Duration(seconds: 2)); // Let the app settle
      if (!mounted) return;
      final repo = ref.read(petsRepositoryProvider);
      final myPets = await repo.getMyAdverts();
      if (!mounted) return;
      final birthdayPets = getBirthdayPets(myPets);
      if (birthdayPets.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => BirthdayCelebrationDialog(birthdayPets: birthdayPets),
        );
      }
    } catch (_) {}
  }

  void _setupSocketListeners(SocketService socketService) {
    final notifier = ref.read(notificationProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    // Match request listener
    _socketSubscriptions.add(
      socketService.onMatchRequest.listen((event) {
        if (!mounted) return;
        notifier.addNotification(
          AppNotification(
            id: 'match_req_${event.requestId}',
            type: NotificationType.matchRequest,
            title: l10n.shellMatchRequestTitle,
            body: l10n.shellMatchRequestBody(
              event.senderName,
              event.senderPetName,
            ),
            data: {'requestId': event.requestId},
            createdAt: DateTime.now(),
          ),
        );
        showMatchRequestSnackBar(context, event);
      }),
    );

    // Match accepted listener
    _socketSubscriptions.add(
      socketService.onMatchAccepted.listen((event) {
        if (!mounted) return;
        notifier.addNotification(
          AppNotification(
            id: 'match_acc_${event.matchRequestId}',
            type: NotificationType.matchAccepted,
            title: l10n.shellMatchAcceptedTitle,
            body: l10n.shellMatchAcceptedBody(event.partnerName),
            data: {'conversationId': event.conversationId},
            createdAt: DateTime.now(),
          ),
        );
        showMatchAcceptedSnackBar(
          context,
          event,
          onGoToChat: () {
            context.goNamed(
              'chat',
              pathParameters: {'conversationId': event.conversationId},
            );
          },
        );
      }),
    );

    // Match rejected listener
    _socketSubscriptions.add(
      socketService.onMatchRejected.listen((event) {
        if (!mounted) return;
        notifier.addNotification(
          AppNotification(
            id: 'match_rej_${event.matchRequestId}',
            type: NotificationType.matchRejected,
            title: l10n.shellMatchRejectedTitle,
            body: l10n.shellMatchRejectedBody(event.rejectorName),
            data: {'requestId': event.matchRequestId},
            createdAt: DateTime.now(),
          ),
        );
        showMatchRejectedSnackBar(context, event);
      }),
    );

    // New message listener
    _socketSubscriptions.add(
      socketService.onNewMessage.listen((event) {
        if (!mounted) return;
        final currentChat = ref.read(currentChatConversationProvider);
        if (currentChat != event.conversationId) {
          notifier.addNotification(
            AppNotification(
              id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
              type: NotificationType.newMessage,
              title: l10n.shellNewMessageTitle,
              body: '${event.senderName}: ${event.message}',
              data: {'conversationId': event.conversationId},
              createdAt: DateTime.now(),
            ),
          );
          showNewMessageSnackBar(
            context,
            event,
            onGoToChat: () {
              context.goNamed(
                'chat',
                pathParameters: {'conversationId': event.conversationId},
              );
            },
          );
        }
      }),
    );

    // Vaccination reminder listener
    socketService.onEvent('vaccination:reminder', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'vac_${d['recordId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.vaccinationReminder,
            title: l10n.shellVaccinationReminderTitle,
            body: l10n.shellVaccinationReminderBody(
              d['petName']?.toString() ?? l10n.shellUnknownPet,
              d['vaccineName']?.toString() ?? l10n.shellUnknownVaccine,
              d['daysUntilDue']?.toString() ?? '?',
            ),
            data: {'petId': d['petId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    });

    // Adoption application listener
    socketService.onEvent('adoption:new_application', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'adopt_new_${d['applicationId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.adoptionNew,
            title: l10n.shellAdoptionNewTitle,
            body: l10n.shellAdoptionNewBody(
              d['applicantName']?.toString() ?? l10n.shellSomeone,
            ),
            data: d,
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    });

    // Adoption accepted listener
    socketService.onEvent('adoption:accepted', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'adopt_acc_${d['applicationId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.adoptionAccepted,
            title: l10n.shellAdoptionAcceptedTitle,
            body: l10n.shellAdoptionAcceptedBody,
            data: d,
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    });

    // Sitter new booking listener (bakici olarak)
    socketService.onEvent('sitter:new_booking', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'sitter_bk_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.sitterBooking,
            title: l10n.shellSitterNewBookingTitle,
            body: l10n.shellSitterNewBookingBody(
              d['ownerName']?.toString() ?? l10n.shellSomeone,
              d['serviceType']?.toString() ?? '',
            ),
            data: {'bookingId': d['bookingId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    });

    // Sitter booking update listener (sahip olarak)
    socketService.onEvent('sitter:booking_update', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final status = d['status']?.toString() ?? '';
        final title = status == 'accepted'
            ? l10n.shellSitterAcceptedTitle
            : status == 'active'
            ? l10n.shellSitterActiveTitle
            : status == 'rejected'
            ? l10n.shellSitterRejectedTitle
            : l10n.shellSitterUpdatedTitle;
        final sitterName =
            d['sitterName']?.toString() ?? l10n.shellSitterNameDefault;
        final body = status == 'accepted'
            ? l10n.shellSitterAcceptedBody(sitterName)
            : status == 'active'
            ? l10n.shellSitterActiveBody(sitterName)
            : status == 'rejected'
            ? l10n.shellSitterRejectedBody(sitterName)
            : l10n.shellSitterUpdatedBody(status);
        notifier.addNotification(
          AppNotification(
            id: 'sitter_upd_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.sitterBooking,
            title: title,
            body: body,
            data: {'bookingId': d['bookingId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    });

    // Pet birthday listener
    socketService.onEvent('pet:birthday', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'bday_${d['petId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.vaccinationReminder,
            title: l10n.shellBirthdayTitle,
            body: d['message']?.toString() ?? l10n.shellBirthdayDefault,
            data: {'petId': d['petId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              d['message']?.toString() ??
                  AppLocalizations.of(context)!.shellBirthdayDefault,
            ),
            backgroundColor: Colors.pink.shade400,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (_) {}
    });

    // Randevu hatırlatıcısı
    socketService.onEvent('appointment:reminder', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final petName =
            d['petName']?.toString() ?? l10n.shellApptReminderDefault;
        final vetName = d['vetName']?.toString() ?? l10n.shellVetDefault;
        final dateStr = d['dateStr']?.toString() ?? '';
        notifier.addNotification(
          AppNotification(
            id: 'appt_${d['appointmentId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.vaccinationReminder,
            title: l10n.shellAppointmentReminderTitle,
            body: l10n.shellAppointmentReminderBody(petName, vetName, dateStr),
            data: {'appointmentId': d['appointmentId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.shellAppointmentReminderSnack(petName, vetName),
              ),
              backgroundColor: const Color(0xFF2D6A4F),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.shellApptSnackView,
                textColor: Colors.white,
                onPressed: () {
                  final appointmentId = d['appointmentId']?.toString();
                  if (appointmentId != null && appointmentId.isNotEmpty) {
                    context.pushNamed(
                      'appointment-detail',
                      pathParameters: {'id': appointmentId},
                    );
                  } else {
                    context.pushNamed('veterinary');
                  }
                },
              ),
            ),
          );
        }
      } catch (_) {}
    });

    socketService.onEvent('sitter:location_offline', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'sitter_location_offline_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.general,
            title: l10n.shellSitterLocationOfflineTitle,
            body: l10n.shellSitterLocationOfflineBody,
            data: {'bookingId': d['bookingId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.shellSitterLocationOfflineSnack),
              action: SnackBarAction(
                label: l10n.shellView,
                onPressed: () => context.push('/sitters/bookings'),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (_) {}
    });

    // Randevu durumu güncellendi (onaylandı/iptal edildi)
    socketService.onEvent('appointment:updated', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final status = d['status']?.toString() ?? '';
        final statusLabel =
            {
              'confirmed': l10n.shellStatusConfirmed,
              'cancelled': l10n.shellStatusCancelled,
              'completed': l10n.shellStatusCompleted,
              'no_show': l10n.shellStatusNoShow,
            }[status] ??
            status;
        final vetName = d['vetName']?.toString() ?? l10n.shellVetDefault;
        notifier.addNotification(
          AppNotification(
            id: 'appt_upd_${d['appointmentId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.vaccinationReminder,
            title: l10n.shellAppointmentUpdatedTitle,
            body: l10n.shellAppointmentUpdatedBody(vetName, statusLabel),
            data: {'appointmentId': d['appointmentId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.shellAppointmentUpdatedBody(vetName, statusLabel),
              ),
              backgroundColor: status == 'confirmed'
                  ? const Color(0xFF2D6A4F)
                  : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (_) {}
    });

    // Lost & Found nearby listener
    socketService.onEvent('lostfound:new', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final isLost = d['type'] == 'lost';
        notifier.addNotification(
          AppNotification(
            id: 'lf_${d['id'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.lostFoundNearby,
            title: isLost ? l10n.shellLostPetTitle : l10n.shellFoundPetTitle,
            body: isLost
                ? l10n.shellLostPetBody(
                    (d['petName'] ?? d['species'] ?? l10n.shellAnimalDefault)
                        .toString(),
                    d['lastSeenAddress']?.toString() ?? '',
                  )
                : l10n.shellFoundPetBody(
                    (d['species'] ?? l10n.shellAnimalDefault).toString(),
                    d['lastSeenAddress']?.toString() ?? '',
                  ),
            data: {'reportId': d['id']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {}
    });

    // Sipariş durumu güncellendiğinde
    socketService.onEvent('order:status_update', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final status = d['status']?.toString() ?? '';
        final statusLabel =
            {
              'processing': l10n.shellOrderProcessing,
              'shipped': l10n.shellOrderShipped,
              'delivered': l10n.shellOrderDelivered,
              'cancelled': l10n.shellOrderCancelled,
            }[status] ??
            status;
        notifier.addNotification(
          AppNotification(
            id: 'order_${d['orderId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.general,
            title: l10n.shellOrderUpdatedTitle,
            body: l10n.shellOrderUpdatedBody(statusLabel),
            data: {'orderId': d['orderId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.shellOrderUpdatedSnack(statusLabel)),
              action: SnackBarAction(
                label: l10n.shellView,
                onPressed: () => context.push('/store/orders'),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          ref.invalidate(myOrdersProvider);
        }
      } catch (_) {}
    });

    // Bakıcı: yeni rezervasyon geldi
    socketService.onEvent('sitter:new_booking', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final sitterName =
            d['petName'] as String? ?? l10n.shellNewBookingDefault;
        notifier.addNotification(
          AppNotification(
            id: 'sitter_booking_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.general,
            title: l10n.shellSitterNewBookingTitle,
            body: l10n.shellPetBookingBody(sitterName),
            data: {'bookingId': d['bookingId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        ref.invalidate(incomingBookingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.shellNewBookingSnack),
              action: SnackBarAction(
                label: l10n.shellView,
                onPressed: () => context.push('/sitters/bookings'),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (_) {}
    });

    // Bakıcı rezervasyon durumu güncellendi
    socketService.onEvent('sitter:booking_update', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final status = d['status']?.toString() ?? '';
        final statusLabel =
            {
              'accepted': l10n.shellBookingAccepted,
              'active': l10n.shellBookingActive,
              'rejected': l10n.shellBookingRejected,
              'completed': l10n.shellBookingCompleted,
              'cancelled': l10n.shellBookingCancelled,
            }[status] ??
            status;
        notifier.addNotification(
          AppNotification(
            id: 'sitter_update_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.general,
            title: l10n.shellSitterUpdatedTitle,
            body: l10n.shellBookingUpdatedBody(statusLabel),
            data: {'bookingId': d['bookingId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        ref.invalidate(myBookingsProvider);
        ref.invalidate(incomingBookingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.shellBookingUpdatedSnack(statusLabel)),
              action: SnackBarAction(
                label: l10n.shellView,
                onPressed: () => context.push('/sitters/bookings'),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (_) {}
    });

    socketService.onEvent('advert:expiry_warning', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(
          AppNotification(
            id: 'expiry_${d['petId'] ?? DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.general,
            title: l10n.shellAdvertExpiryTitle,
            body:
                d['message'] as String? ??
                l10n.shellAdvertExpiryBody(
                  (d['petName'] ?? l10n.shellAnimalDefault).toString(),
                ),
            data: {'petId': d['petId']?.toString()},
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                d['message'] as String? ??
                    l10n.shellAdvertExpiryBody(
                      (d['petName'] ?? l10n.shellAnimalDefault).toString(),
                    ),
              ),
              action: SnackBarAction(
                label: l10n.shellAdvertsNav,
                onPressed: () => context.goNamed('profile'),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } catch (_) {}
    });
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    final currentUser = ref.read(authProvider);
    final l10n = AppLocalizations.of(context)!;

    // Misafir için sadece mesajlar (0) ve profil (4) giriş gerektirir
    if (currentUser == null && (index == 0 || index == 4)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF2D6A4F),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.shellLoginRequiredTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            index == 0
                ? l10n.shellMessagesLoginRequired
                : l10n.shellProfileLoginRequired,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.goNamed('login');
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(l10n.login),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.goNamed('register');
              },
              child: Text(
                l10n.register,
                style: const TextStyle(
                  color: Color(0xFF40916C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final routeName = _routeNames[index];
    if (routeName != null) {
      context.goNamed(routeName);
    }
  }

  void _updateCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/messages')) {
      _selectedIndex = 0;
    } else if (location == '/' || location.startsWith('/home')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/veterinary')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/store')) {
      _selectedIndex = 3;
    } else if (location.startsWith('/profile')) {
      _selectedIndex = 4;
    } else {
      _selectedIndex = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateCurrentIndex(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.read(authProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Sepet uyarısı (hem kayıtlı hem misafir için)
        int cartCount = 0;
        try {
          final cartAsync = ref.read(cartItemsProvider);
          cartAsync.whenData((c) => cartCount += c.items.length);
        } catch (_) {}
        try {
          final guestItems = ref.read(guestCartProvider);
          cartCount += guestItems.length;
        } catch (_) {}
        final msg = cartCount > 0
            ? l10n.shellCartExitMessage(cartCount)
            : l10n.shellExitMessage;
        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              cartCount > 0 ? l10n.shellCartExitTitle : l10n.shellExitTitle,
            ),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.no,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                ),
                child: Text(l10n.yes),
              ),
            ],
          ),
        );
        if (exit == true) SystemNavigator.pop();
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          // Rehber Pati — uygulama içi AI navigasyon asistanı
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 76),
            child:
                Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF52B788).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: FloatingActionButton.small(
                        onPressed: () => context.pushNamed('guide'),
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        tooltip: l10n.shellGuideFab,
                        child: const Icon(Icons.assistant_rounded, size: 20),
                      ),
                    )
                    .animate(
                      onPlay: (ctrl) => ctrl.repeat(
                        reverse: true,
                        period: const Duration(seconds: 3),
                      ),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              // ─── Çevrimdışı banner ────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _isOffline
                    ? Container(
                        width: double.infinity,
                        color: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.shellOfflineBanner,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  clipBehavior: Clip.none,
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF1E1E1E).withOpacity(0.88)
                        : Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: context.isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade200,
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryGreen.withOpacity(0.12),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _PillNavBar(
                    selectedIndex: _selectedIndex,
                    onTap: (index) => _onItemTapped(index, context),
                    items: [
                      _PillNavItem(
                        icon: Icons.chat_bubble_outline,
                        activeIcon: Icons.chat_bubble,
                        label: l10n.navMessages,
                        customIcon: const _MessagesNavIcon(isActive: false),
                        customActiveIcon: const _MessagesNavIcon(
                          isActive: true,
                        ),
                      ),
                      _PillNavItem(
                        icon: Icons.pets_outlined,
                        activeIcon: Icons.pets,
                        label: l10n.navAdopt,
                      ),
                      _PillNavItem(
                        icon: Icons.local_hospital_outlined,
                        activeIcon: Icons.local_hospital,
                        label: l10n.navVet,
                      ),
                      _PillNavItem(
                        icon: Icons.store_mall_directory_outlined,
                        activeIcon: Icons.store,
                        label: l10n.navStore,
                      ),
                      _PillNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: l10n.navProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ), // SafeArea
    ); // PopScope
  }
}

class _MessagesNavIcon extends ConsumerWidget {
  final bool isActive;

  const _MessagesNavIcon({required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final User? user = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final avatarUrl = _resolveAvatarUrl(user?.avatarUrl);
    final hasInitial = (user?.name ?? '').isNotEmpty;
    final initial = hasInitial ? user!.name[0].toUpperCase() : null;

    final borderColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            color: theme.colorScheme.surface,
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _NavIconFallback(isActive: isActive, initial: initial),
                  )
                : _NavIconFallback(isActive: isActive, initial: initial),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _NavIconFallback extends StatelessWidget {
  final bool isActive;
  final String? initial;

  const _NavIconFallback({required this.isActive, this.initial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (initial != null) {
      return Center(
        child: Text(
          initial!,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Icon(
      isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
      color: isActive
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      size: 20,
    );
  }
}

String? _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}

// ─── Floating Pill Nav Bar ───────────────────────────────────────────────────

class _PillNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget? customIcon;
  final Widget? customActiveIcon;

  const _PillNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.customIcon,
    this.customActiveIcon,
  });
}

class _PillNavBar extends StatelessWidget {
  const _PillNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_PillNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _PillNavItemWidget(
                item: items[i],
                isSelected: selectedIndex == i,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillNavItemWidget extends StatelessWidget {
  const _PillNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _PillNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final mutedColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                transform: Matrix4.translationValues(
                  0,
                  isSelected ? -10.0 : 0.0,
                  0,
                ),
                transformAlignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryPale : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimaryGreen.withOpacity(0.20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: item.customIcon != null
                          ? (isSelected
                                ? KeyedSubtree(
                                    key: const ValueKey('active'),
                                    child:
                                        item.customActiveIcon ??
                                        item.customIcon!,
                                  )
                                : KeyedSubtree(
                                    key: const ValueKey('inactive'),
                                    child: item.customIcon!,
                                  ))
                          : Icon(
                              isSelected ? item.activeIcon : item.icon,
                              key: ValueKey(isSelected),
                              color: isSelected ? primaryColor : mutedColor,
                              size: 22,
                            ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOut,
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                item.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              )
              .animate(key: ValueKey(isSelected))
              .scale(
                begin: isSelected
                    ? const Offset(0.88, 0.88)
                    : const Offset(1.0, 1.0),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              ),
    );
  }
}
