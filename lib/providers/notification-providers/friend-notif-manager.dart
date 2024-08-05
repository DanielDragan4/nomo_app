import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FriendNotificationManager {
  static Future<void> handleAddFriend(WidgetRef ref, String friendId) async {
    ref.read(friendNotificationProvider.notifier).setNotification(friendId, false);
  }

  static Future<void> handleRemoveFriend(WidgetRef ref, String friendId) async {
    ref.read(friendNotificationProvider.notifier).removeFriend(friendId);
  }
}

class FriendNotificationState extends StateNotifier<Map<String, bool>> {
  FriendNotificationState() : super({});

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final friendNotifications = prefs.getString('friendNotifications');
    if (friendNotifications != null) {
      state = Map<String, bool>.from(json.decode(friendNotifications));
    }
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('friendNotifications', json.encode(state));
  }

  void setNotification(String friendId, bool hasNewMessage) {
    state = {...state, friendId: hasNewMessage};
    saveState();
  }

  void removeFriend(String friendId) {
    state = Map<String, bool>.from(state)..remove(friendId);
    saveState();
  }

  void resetNotification(String friendId) {
    if (state.containsKey(friendId)) {
      state = {...state, friendId: false};
      saveState();
    }
  }
}

final friendNotificationProvider = StateNotifierProvider<FriendNotificationState, Map<String, bool>>((ref) {
  return FriendNotificationState();
});
