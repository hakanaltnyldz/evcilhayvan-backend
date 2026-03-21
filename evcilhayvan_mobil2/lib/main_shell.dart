import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/services/fcm_service.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
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
      socketService.offEvent('advert:expiry_warning');
      socketService.offEvent('sitter:new_booking');
      socketService.offEvent('sitter:booking_update');
      socketService.offEvent('pet:birthday');
      socketService.offEvent('appointment:reminder');
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

    // Pet birthday listener
    socketService.onEvent('pet:birthday', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(AppNotification(
          id: 'bday_${d['petId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.vaccinationReminder,
          title: 'Doğum Günü! 🎂',
          body: d['message']?.toString() ?? 'Dostunuzun doğum günü bugün!',
          data: {'petId': d['petId']?.toString()},
          createdAt: DateTime.now(),
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(d['message']?.toString() ?? AppLocalizations.of(context)!.shellBirthdayDefault),
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
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        final petName = d['petName']?.toString() ?? AppLocalizations.of(context)!.shellApptReminderDefault;
        final vetName = d['vetName']?.toString() ?? 'Veteriner';
        final dateStr = d['dateStr']?.toString() ?? '';
        notifier.addNotification(AppNotification(
          id: 'appt_${d['appointmentId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.vaccinationReminder,
          title: '🗓️ Randevu Hatırlatıcısı',
          body: '$petName için yarın $vetName randevunuz var. $dateStr',
          data: {'appointmentId': d['appointmentId']?.toString()},
          createdAt: DateTime.now(),
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🗓️ $petName için yarın $vetName randevunuz var!'),
              backgroundColor: Colors.teal.shade600,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.shellApptSnackView,
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
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

    socketService.onEvent('advert:expiry_warning', (data) {
      if (!mounted) return;
      try {
        final d = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
        notifier.addNotification(AppNotification(
          id: 'expiry_${d['petId'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.general,
          title: 'İlan Süresi Dolmak Üzere',
          body: d['message'] as String? ?? '"${d['petName']}" ilanınızın süresi doluyor.',
          data: {'petId': d['petId']?.toString()},
          createdAt: DateTime.now(),
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(d['message'] as String? ?? '"${d['petName']}" ilanınızın süresi doluyor.'),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.shellAdvertsNav,
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
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        // Rehber Pati — uygulama içi AI navigasyon asistanı
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 76),
          child: FloatingActionButton.small(
            onPressed: () => context.pushNamed('guide'),
            backgroundColor: AppPalette.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip: l10n.shellGuideFab,
            child: const Icon(Icons.assistant_rounded, size: 20),
          )
              .animate(
                onPlay: (ctrl) => ctrl.repeat(reverse: true, period: const Duration(seconds: 3)),
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
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            l10n.shellOfflineBanner,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
          child: Container(
            clipBehavior: Clip.none,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.scaffoldBg.withOpacity(0.97),
                  theme.colorScheme.surfaceVariant.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.subtleBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
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
                  label: AppLocalizations.of(context)?.navMessages ?? 'Sohbetler',
                  customIcon: const _MessagesNavIcon(isActive: false),
                  customActiveIcon: const _MessagesNavIcon(isActive: true),
                ),
                _PillNavItem(
                  icon: Icons.pets_outlined,
                  activeIcon: Icons.pets,
                  label: AppLocalizations.of(context)?.navAdopt ?? 'Sahiplen',
                ),
                _PillNavItem(
                  icon: Icons.local_hospital_outlined,
                  activeIcon: Icons.local_hospital,
                  label: AppLocalizations.of(context)?.navVet ?? 'Veteriner',
                ),
                _PillNavItem(
                  icon: Icons.store_mall_directory_outlined,
                  activeIcon: Icons.store,
                  label: AppLocalizations.of(context)?.navStore ?? 'Mağaza',
                ),
                _PillNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: AppLocalizations.of(context)?.navProfile ?? 'Profil',
                ),
              ],
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
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, isSelected ? -10.0 : 0.0, 0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.22),
                    blurRadius: 12,
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
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: item.customIcon != null
                  ? (isSelected
                      ? KeyedSubtree(key: const ValueKey('active'), child: item.customActiveIcon ?? item.customIcon!)
                      : KeyedSubtree(key: const ValueKey('inactive'), child: item.customIcon!))
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
            begin: isSelected ? const Offset(0.88, 0.88) : const Offset(1.0, 1.0),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
    );
  }
}
