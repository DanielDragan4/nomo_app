import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationData {
  final String title;
  final String description;

  NotificationData({required this.title, required this.description});

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
  UnreadNotificationsNotifier() : super([]) {
    _loadNotifications();
  }

  void addNotification(String title, String description) {
    state = [
      ...state,
      NotificationData(title: title, description: description)
    ];
    _saveNotifications();
    // Update the notification bell state when a new notification is added
    _updateNotificationBellState();
  }

  void removeNotification(int index) {
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    _saveNotifications();
    // Check if there are any notifications left to decide the bell state
  }

  //Here if we ever want a clear all notifs button
  void clearNotifications() {
    state = [];
    _saveNotifications();
    // No notifications left, update bell state to false
    _updateNotificationBellState();
  }

  void _updateNotificationBellState() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasUnreadNotifications = state.isNotEmpty;
    await prefs.setBool('hasUnreadNotifications', hasUnreadNotifications);
    print('Bell state updated to: $hasUnreadNotifications');
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
}

final unreadNotificationsProvider =
    StateNotifierProvider<UnreadNotificationsNotifier, List<NotificationData>>(
        (ref) {
  return UnreadNotificationsNotifier();
});
