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

class UnreadNotificationsNotifier extends StateNotifier<List<NotificationData>> {
  UnreadNotificationsNotifier(this._ref) : super([]) {
    _loadNotifications();
  }

  final Ref _ref;

  //Adds a new notification to provider state list, and triggers notification bell icon update
  //
  // Parameters:
  // - 'title': title of the added notification
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

  // Removes notification from provider state list when deleted in Notification Screen
  //
  // Parameters:
  // - 'index': index of the notification to be removed
  void removeNotification(int index) {
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    _saveNotifications();
    if (state.isEmpty) {
      _updateNotificationBellState(false);
    }
  }

  //Removes all current notifications in provider state list
  void clearNotifications() {
    state = [];
    _saveNotifications();
    _updateNotificationBellState(false);
  }

  //Saves all current notifications to Shared Preferences to save across sessions
  void _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationStrings = state.map((notif) => json.encode(notif.toJson())).toList();
    await prefs.setStringList('notifications', notificationStrings);
  }

  //Loads notifications saved in Shared Preferences and assigns all of them to provider state list
  void _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notificationStrings = prefs.getStringList('notifications');
    if (notificationStrings != null) {
      state = notificationStrings.map((notifStr) => NotificationData.fromJson(json.decode(notifStr))).toList();
    }
  }

  //Updates notification bell icon through Notification Bell Provider
  //
  // Parameters:
  // - 'hasUnreadNotifications': true if user has any unread or new notifications, passed to Notification Bell Provider
  void _updateNotificationBellState(bool hasUnreadNotifications) {
    _ref.read(notificationBellProvider.notifier).setBellState(hasUnreadNotifications);
  }
}

final unreadNotificationsProvider = StateNotifierProvider<UnreadNotificationsNotifier, List<NotificationData>>((ref) {
  return UnreadNotificationsNotifier(ref);
});

final appInitializationProvider = Provider((ref) async {
  await ref.read(notificationBellProvider.notifier).loadBellState();
  ref.read(unreadNotificationsProvider.notifier)._loadNotifications();
});
