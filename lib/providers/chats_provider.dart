import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsProvider extends StateNotifier<List?> {
  ChatsProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  late var chatID;

  Future<String> readChatId(user1Id, user2Id) async {
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
    return chat[0]['chat_id'];
  }

  Future<void> getChatStream (user1Id, user2Id) async{
    final supabaseClient = (await supabase).client;
    chatID = await readChatId(user1Id, user2Id);
    var stream = await supabaseClient.from('Messages').select()
      .eq('chat_id', chatID).order('created_at', ascending: true);
    
    state = stream;
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
  Future<void> sendMessage(String user1Id, String user2Id, String message) async{
    final supabaseClient = (await supabase).client;
    var newMessage = {
        'sender_id': user1Id,
        'chat_id' : chatID,
        'message' : message
      };
    await supabaseClient.from('Messages').insert(newMessage);
    await getChatStream(user1Id, user2Id);
  }
}

final chatsProvider = StateNotifierProvider<ChatsProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ChatsProvider(supabase: supabase);
});
