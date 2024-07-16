import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBellNotifier extends StateNotifier<bool> {
  NotificationBellNotifier() : super(false) {
    loadBellState();
  }

  //Changes notification bell icon depending on whether the user has unread notifications
  //
  // Parameters:
  // - 'hasUnreadNotifications': true if user has any unread or new notifications
  Future<void> setBellState(bool hasUnreadNotifications) async {
    state = hasUnreadNotifications;
    await _saveBellState();
  }

  // Saves the state of the notification bell to Shared Preferences to remain consistent between app sessions
  Future<void> _saveBellState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasUnreadNotifications', state);
  }

  // Retrieves saved bell state in Shared Preferences and sets provider state accordingly
  Future<void> loadBellState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('hasUnreadNotifications') ?? false;
  }
}

final notificationBellProvider = StateNotifierProvider<NotificationBellNotifier, bool>((ref) {
  return NotificationBellNotifier();
});
