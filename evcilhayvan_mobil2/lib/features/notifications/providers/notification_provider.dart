import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/app_notification.dart';

const _storageKey = 'app_notifications';
const _maxNotifications = 100;

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> decoded = jsonDecode(raw);
      state = decoded
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limited = state.take(_maxNotifications).toList();
      await prefs.setString(_storageKey, jsonEncode(limited.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }

  void addNotification(AppNotification notification) {
    state = [notification, ...state];
    if (state.length > _maxNotifications) {
      state = state.sublist(0, _maxNotifications);
    }
    _saveToStorage();
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            createdAt: n.createdAt,
            isRead: true,
          )
        else
          n,
    ];
    _saveToStorage();
  }

  void markAllAsRead() {
    state = [
      for (final n in state)
        AppNotification(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          createdAt: n.createdAt,
          isRead: true,
        ),
    ];
    _saveToStorage();
  }

  void clearAll() {
    state = [];
    _saveToStorage();
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _saveToStorage();
  }
}
