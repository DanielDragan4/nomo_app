import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateNotifier to manage the active chat ID
class ActiveChatIdNotifier extends StateNotifier<String?> {
  ActiveChatIdNotifier() : super(null);

  void setActiveChatId(String? chatId) {
    state = chatId;
  }
}

// StateNotifierProvider to expose the ActiveChatIdNotifier
final activeChatIdProvider =
    StateNotifierProvider<ActiveChatIdNotifier, String?>((ref) {
  return ActiveChatIdNotifier();
});
