import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/core/widgets/modern_background.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
import '../../domain/models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)!.notificationsTitle}${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tumunu okundu isaretle',
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tumunu temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Bildirimleri Temizle'),
                    content: const Text('Tum bildirimler silinecek. Emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Iptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(notificationProvider.notifier).clearAll();
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F3DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.notificationsEmpty,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni bildirimler burada görünecek.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, ref, notification),
                    onDismiss: () {
                      ref.read(notificationProvider.notifier).removeNotification(notification.id);
                    },
                  )
                      .animate(delay: Duration(milliseconds: index * 60))
                      .fadeIn(duration: 280.ms)
                      .slideY(begin: 0.05);
                },
              ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification notification) {
    // Okundu isaretle
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.matchRequest:
        context.pushNamed('mating-requests');
        break;
      case NotificationType.matchAccepted:
        final conversationId = data['conversationId']?.toString();
        if (conversationId != null) {
          context.pushNamed('chat', pathParameters: {'conversationId': conversationId});
        }
        break;
      case NotificationType.matchRejected:
        context.pushNamed('mating-requests');
        break;
      case NotificationType.newMessage:
        final conversationId = data['conversationId']?.toString();
        if (conversationId != null) {
          context.pushNamed('chat', pathParameters: {'conversationId': conversationId});
        }
        break;
      case NotificationType.adoptionNew:
        context.pushNamed('adoption-applications');
        break;
      case NotificationType.adoptionAccepted:
        final conversationId = data['conversationId']?.toString();
        if (conversationId != null) {
          context.pushNamed('chat', pathParameters: {'conversationId': conversationId});
        } else {
          context.pushNamed('adoption-applications');
        }
        break;
      case NotificationType.adoptionRejected:
        context.pushNamed('adoption-applications');
        break;
      case NotificationType.vaccinationReminder:
        final petId = data['petId']?.toString();
        if (petId != null) {
          context.pushNamed('vaccination-calendar', pathParameters: {'petId': petId});
        }
        break;
      case NotificationType.orderUpdate:
        context.pushNamed('my-orders');
        break;
      case NotificationType.lostFoundNearby:
        final reportId = data['reportId']?.toString();
        if (reportId != null) {
          context.pushNamed('lost-found-detail', pathParameters: {'id': reportId});
        } else {
          context.pushNamed('lost-found');
        }
        break;
      case NotificationType.sitterBooking:
        context.pushNamed('sitter-bookings');
        break;
      case NotificationType.general:
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.matchRequest:
        return Icons.favorite;
      case NotificationType.matchAccepted:
        return Icons.check_circle;
      case NotificationType.matchRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.chat;
      case NotificationType.adoptionNew:
        return Icons.pets;
      case NotificationType.adoptionAccepted:
        return Icons.volunteer_activism;
      case NotificationType.adoptionRejected:
        return Icons.block;
      case NotificationType.vaccinationReminder:
        return Icons.vaccines;
      case NotificationType.orderUpdate:
        return Icons.local_shipping;
      case NotificationType.lostFoundNearby:
        return Icons.location_searching;
      case NotificationType.sitterBooking:
        return Icons.pets;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.matchRequest:
        return Colors.pink;
      case NotificationType.matchAccepted:
        return Colors.green;
      case NotificationType.matchRejected:
        return Colors.red;
      case NotificationType.newMessage:
        return const Color(0xFF2D6A4F);
      case NotificationType.adoptionNew:
        return Colors.orange;
      case NotificationType.adoptionAccepted:
        return Colors.green;
      case NotificationType.adoptionRejected:
        return Colors.red;
      case NotificationType.lostFoundNearby:
        return Colors.deepOrange;
      case NotificationType.sitterBooking:
        return const Color(0xFF1B4332);
      case NotificationType.vaccinationReminder:
        return const Color(0xFF40916C);
      case NotificationType.orderUpdate:
        return const Color(0xFF52B788);
      case NotificationType.general:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(notification.createdAt);
    final iconColor = _getIconColor();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.surface
              : (theme.brightness == Brightness.dark ? const Color(0xFF1E2E28) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? Colors.grey.shade200 : const Color(0xFFD8F3DC),
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!notification.isRead)
                    Container(width: 4, color: const Color(0xFF2D6A4F)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getIcon(), color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: notification.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2D6A4F),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF52B788),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Az once';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk once';
  if (diff.inHours < 24) return '${diff.inHours} saat once';
  if (diff.inDays < 7) return '${diff.inDays} gun once';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta once';
  return '${(diff.inDays / 30).floor()} ay once';
}
