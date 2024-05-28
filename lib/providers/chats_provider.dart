import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/message_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsProvider extends StateNotifier<String?> {
  ChatsProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<void> readChatId(user1Id, user2Id) async {
    final supabaseClient = (await supabase).client;
    List chat = await supabaseClient
        .from('Chats')
        .select('*')
        .eq('user1_id', user1Id)
        .eq('user2_id', user2Id);
    if(chat.isEmpty) {
      await createNewChat(user1Id, user2Id);
      chat = await supabaseClient
        .from('Chats')
        .select('*')
        .eq('user1_id', user1Id)
        .eq('user2_id', user2Id);
    }
    state = chat[0]['chat_id'];
  }

  // Future<void> deCodeData(String user1Id, String user2Id) async {
  //   final codedList = await readMessages(user1Id, user2Id);

  //   List<Message> deCodedList = [];
  //   final supabaseClient = (await supabase).client;

  //   for (var messageData in codedList) {
  //     bool isMine;

  //     if(messageData[0]['sender_id'] == supabaseClient.auth.currentUser?.id) {
  //       isMine = true;
  //     } else {
  //       isMine = false;
  //     }

  //     final Message deCodedMessage = Message(
  //       isMine: isMine,
  //       message: messageData[0]['message'],
  //       senderId: messageData[0]['sender_id'],
  //       timeStamp: messageData[0]['created_at'],
  //     );
  //     deCodedList.add(deCodedMessage);
  //   }
  //   state = deCodedList;
  // }
  Future<void> createNewChat(String user1Id, String user2Id) async{
    final supabaseClient = (await supabase).client;
    var newChat = {
        'user1_id': user1Id,
        'user2_id': user2Id,
      };
      await supabaseClient.from('Chats')
      .insert(newChat);
  }
  Future<void> sendMessage(String userId, String message) async{
    final supabaseClient = (await supabase).client;
    var newMessage = {
        'sender_id': userId,
        'chat_id' : state,
        'message' : message
      };
    await supabaseClient.from('Messages').insert(newMessage);
  }
}

final chatsProvider = StateNotifierProvider<ChatsProvider, String?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ChatsProvider(supabase: supabase);
});
