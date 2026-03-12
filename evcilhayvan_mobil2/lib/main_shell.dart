import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/services/fcm_service.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/socket_service.dart';
import 'package:evcilhayvan_mobil2/core/providers/socket_provider.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvan_mobil2/features/auth/domain/user_model.dart';
import 'package:evcilhayvan_mobil2/features/notifications/domain/models/app_notification.dart';
import 'package:evcilhayvan_mobil2/features/notifications/providers/notification_provider.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/core/widgets/birthday_celebration.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  final List<StreamSubscription> _socketSubscriptions = [];

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
  }

  @override
  void dispose() {
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
      socketService.offEvent('sitter:new_booking');
      socketService.offEvent('sitter:booking_update');
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

    // Match request listener
    _socketSubscriptions.add(
      socketService.onMatchRequest.listen((event) {
        if (!mounted) return;
        notifier.addNotification(AppNotification(
          id: 'match_req_${event.requestId}',
          type: NotificationType.matchRequest,
          title: 'Eslestirme Istegi',
          body: '${event.senderName} sana ${event.senderPetName} icin eslestirme istegi gonderdi.',
          data: {'requestId': event.requestId},
          createdAt: DateTime.now(),
        ));
        showMatchRequestSnackBar(context, event);
      }),
    );

    // Match accepted listener
    _socketSubscriptions.add(
      socketService.onMatchAccepted.listen((event) {
        if (!mounted) return;
        notifier.addNotification(AppNotification(
          id: 'match_acc_${event.matchRequestId}',
          type: NotificationType.matchAccepted,
          title: 'Eslestirme Kabul Edildi',
          body: '${event.partnerName} eslestirme istegini kabul etti! Artik mesajlasabilirsiniz.',
          data: {'conversationId': event.conversationId},
          createdAt: DateTime.now(),
        ));
        showMatchAcceptedSnackBar(
          context,
          event,
          onGoToChat: () {
            context.goNamed('chat', pathParameters: {
              'conversationId': event.conversationId,
            });
          },
        );
      }),
    );

    // Match rejected listener
    _socketSubscriptions.add(
      socketService.onMatchRejected.listen((event) {
        if (!mounted) return;
        notifier.addNotification(AppNotification(
          id: 'match_rej_${event.matchRequestId}',
          type: NotificationType.matchRejected,
          title: 'Eslestirme Reddedildi',
          body: '${event.rejectorName} eslestirme istegini reddetti.',
          data: {'requestId': event.matchRequestId},
          createdAt: DateTime.now(),
        ));
        showMatchRejectedSnackBar(context, event);
      }),
    );

    // New message listener
    _socketSubscriptions.add(
      socketService.onNewMessage.listen((event) {
        if (!mounted) return;
        final currentChat = ref.read(currentChatConversationProvider);
        if (currentChat != event.conversationId) {
          notifier.addNotification(AppNotification(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.newMessage,
            title: 'Yeni Mesaj',
            body: '${event.senderName}: ${event.message}',
            data: {'conversationId': event.conversationId},
            createdAt: DateTime.now(),
          ));
          showNewMessageSnackBar(
            context,
            event,
            onGoToChat: () {
              context.goNamed('chat', pathParameters: {
                'conversationId': event.conversationId,
              });
            },
          );
        }
      }),
    );

    // Vaccination reminder listener
    socketService.onEvent('vaccination:reminder', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(AppNotification(
          id: 'vac_${d['recordId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.vaccinationReminder,
          title: 'Asi Hatirlatmasi',
          body: '${d['petName']} icin ${d['vaccineName']} asisi ${d['daysUntilDue']} gun icinde yapilmali.',
          data: {'petId': d['petId']?.toString()},
          createdAt: DateTime.now(),
        ));
      } catch (_) {}
    });

    // Adoption application listener
    socketService.onEvent('adoption:new_application', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(AppNotification(
          id: 'adopt_new_${d['applicationId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.adoptionNew,
          title: 'Yeni Sahiplendirme Basvurusu',
          body: '${d['applicantName'] ?? 'Birisi'} ilaniniza basvuru yapti.',
          data: d,
          createdAt: DateTime.now(),
        ));
      } catch (_) {}
    });

    // Adoption accepted listener
    socketService.onEvent('adoption:accepted', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(AppNotification(
          id: 'adopt_acc_${d['applicationId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.adoptionAccepted,
          title: 'Basvuru Kabul Edildi',
          body: 'Sahiplendirme basvurunuz kabul edildi!',
          data: d,
          createdAt: DateTime.now(),
        ));
      } catch (_) {}
    });

    // Sitter new booking listener (bakici olarak)
    socketService.onEvent('sitter:new_booking', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(AppNotification(
          id: 'sitter_bk_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.sitterBooking,
          title: 'Yeni Rezervasyon Talebi',
          body: '${d['ownerName'] ?? 'Birisi'} ${d['serviceType'] ?? ''} icin rezervasyon istedi.',
          data: {'bookingId': d['bookingId']?.toString()},
          createdAt: DateTime.now(),
        ));
      } catch (_) {}
    });

    // Sitter booking update listener (sahip olarak)
    socketService.onEvent('sitter:booking_update', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        final status = d['status']?.toString() ?? '';
        final title = status == 'accepted'
            ? 'Rezervasyon Kabul Edildi'
            : status == 'rejected'
                ? 'Rezervasyon Reddedildi'
                : 'Rezervasyon Guncellendi';
        final body = status == 'accepted'
            ? '${d['sitterName'] ?? 'Bakici'} rezervasyonunuzu kabul etti!'
            : status == 'rejected'
                ? '${d['sitterName'] ?? 'Bakici'} rezervasyonunuzu reddetti.'
                : 'Rezervasyonunuz $status durumuna guncellendi.';
        notifier.addNotification(AppNotification(
          id: 'sitter_upd_${d['bookingId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.sitterBooking,
          title: title,
          body: body,
          data: {'bookingId': d['bookingId']?.toString()},
          createdAt: DateTime.now(),
        ));
      } catch (_) {}
    });

    // Lost & Found nearby listener
    socketService.onEvent('lostfound:new', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        final isLost = d['type'] == 'lost';
        notifier.addNotification(AppNotification(
          id: 'lf_${d['id'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.lostFoundNearby,
          title: isLost ? 'Kayip Hayvan Ilani' : 'Bulunan Hayvan Ilani',
          body: isLost
              ? '${d['petName'] ?? d['species'] ?? 'Bir hayvan'} kayip! ${d['lastSeenAddress'] ?? ''}'
              : '${d['species'] ?? 'Bir hayvan'} bulundu! ${d['lastSeenAddress'] ?? ''}',
          data: {'reportId': d['id']?.toString()},
          createdAt: DateTime.now(),
        ));
      } catch (_) {}
    });
  }

  void _onItemTapped(int index, BuildContext context) {
    final currentUser = ref.read(authProvider);

    if (currentUser == null && (index == 0 || index == 2 || index == 4)) {
      context.goNamed('login');
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

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: widget.child,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.background.withOpacity(0.94),
                  theme.colorScheme.surfaceVariant.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: (index) => _onItemTapped(index, context),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.onSurfaceVariant,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: _MessagesNavIcon(isActive: false),
                    activeIcon: _MessagesNavIcon(isActive: true),
                    label: 'Sohbetler',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.pets_outlined),
                    activeIcon: Icon(Icons.pets),
                    label: 'Sahiplen',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_hospital_outlined),
                    activeIcon: Icon(Icons.local_hospital),
                    label: 'Veteriner',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.store_mall_directory_outlined),
                    activeIcon: Icon(Icons.store),
                    label: 'Magaza',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

    final borderColor = isActive ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.2);

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
                    errorBuilder: (_, __, ___) => _NavIconFallback(
                      isActive: isActive,
                      initial: initial,
                    ),
                  )
                : _NavIconFallback(
                    isActive: isActive,
                    initial: initial,
                  ),
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
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Icon(
      isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
      color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      size: 20,
    );
  }
}

String? _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$apiBaseUrl$path';
}
