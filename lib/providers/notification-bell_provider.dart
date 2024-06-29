import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBellNotifier extends StateNotifier<bool> {
  NotificationBellNotifier(bool initialState) : super(initialState);

  Future<void> setBellState(bool hasUnreadNotifications) async {
    state = hasUnreadNotifications;
    await _saveBellState();
  }

  Future<void> _saveBellState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasUnreadNotifications', state);
  }

  Future<void> loadBellState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('hasUnreadNotifications') ?? false;
  }
}

final notificationBellProvider =
    StateNotifierProvider<NotificationBellNotifier, bool>((ref) {
  // Initialize state with the current unread notification status
  return NotificationBellNotifier(false)..loadBellState();
});
