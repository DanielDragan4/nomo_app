import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/notification-provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBellNotifier extends StateNotifier<bool> {
  NotificationBellNotifier() : super(false) {
    _loadBellState();
  }

  void setBellState(bool hasUnreadNotifications) {
    state = hasUnreadNotifications;
    _saveBellState();
  }

  void _saveBellState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasUnreadNotifications', state);
  }

  void _loadBellState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('hasUnreadNotifications') ?? false;
  }
}

final notificationBellProvider =
    StateNotifierProvider<NotificationBellNotifier, bool>((ref) {
  final hasUnreadNotifications =
      ref.watch(unreadNotificationsProvider).isNotEmpty;

  // Initialize state with the current unread notification status
  return NotificationBellNotifier()..setBellState(hasUnreadNotifications);
});
