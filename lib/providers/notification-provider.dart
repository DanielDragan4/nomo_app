import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/notification-bell_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationData {
  final String title;
  final String? description;

  NotificationData({required this.title, this.description});

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };

  static NotificationData fromJson(Map<String, dynamic> json) {
    return NotificationData(
      title: json['title'],
      description: json['description'],
    );
  }
}

class UnreadNotificationsNotifier
    extends StateNotifier<List<NotificationData>> {
  UnreadNotificationsNotifier(this._ref) : super([]) {
    _loadNotifications();
  }

  final Ref _ref;

  void addNotification(String title) {
    state = [
      ...state,
      NotificationData(
        title: title,
      )
    ];
    _saveNotifications();
    _updateNotificationBellState(true);
  }

  void removeNotification(int index) {
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    _saveNotifications();
    if (state.isEmpty) {
      _updateNotificationBellState(false);
    }
  }

  void clearNotifications() {
    state = [];
    _saveNotifications();
    _updateNotificationBellState(false);
  }

  void _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationStrings =
        state.map((notif) => json.encode(notif.toJson())).toList();
    await prefs.setStringList('notifications', notificationStrings);
  }

  void _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notificationStrings =
        prefs.getStringList('notifications');
    if (notificationStrings != null) {
      state = notificationStrings
          .map((notifStr) => NotificationData.fromJson(json.decode(notifStr)))
          .toList();
    }
  }

  void _updateNotificationBellState(bool hasUnreadNotifications) {
    _ref
        .read(notificationBellProvider.notifier)
        .setBellState(hasUnreadNotifications);
  }
}

final unreadNotificationsProvider =
    StateNotifierProvider<UnreadNotificationsNotifier, List<NotificationData>>(
        (ref) {
  return UnreadNotificationsNotifier(ref);
});

final appInitializationProvider = Provider((ref) async {
  await ref.read(notificationBellProvider.notifier).loadBellState();
  ref.read(unreadNotificationsProvider.notifier)._loadNotifications();
});
