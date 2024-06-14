import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsProvider extends StateNotifier<List?> {
  ChatsProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  var chatID;

  Future<String> readChatId(String user1Id, String user2Id) async {
    final supabaseClient = (await supabase).client;
    List chat = await supabaseClient
        .from('Chats')
        .select('*')
        .or('user1_id.eq.$user1Id,user1_id.eq.$user2Id')
        .or('user2_id.eq.$user1Id,user2_id.eq.$user2Id');
    if (chat.isEmpty) {
      await createNewChat(user1Id, user2Id);
      chat = await supabaseClient
          .from('Chats')
          .select('*')
          .or('user1_id.eq.$user1Id,user1_id.eq.$user2Id')
          .or('user2_id.eq.$user1Id,user2_id.eq.$user2Id');
    }
    return chat[0]['chat_id'];
  }

  Future<void> getChatStream(user1Id, user2Id) async {
    final supabaseClient = (await supabase).client;
    chatID = await readChatId(user1Id, user2Id);
    var stream = await supabaseClient
        .from('Messages')
        .select()
        .eq('chat_id', chatID)
        .order('created_at', ascending: true);

    state = stream;
  }

  Future<void> createNewChat(String user1Id, String user2Id) async {
    final supabaseClient = (await supabase).client;
    var newChat = {
      'user1_id': user1Id,
      'user2_id': user2Id,
    };
    await supabaseClient.from('Chats').insert(newChat);
  }

  Future<void> sendMessage(
      String user1Id, String user2Id, String message) async {
    final supabaseClient = (await supabase).client;
    chatID = await readChatId(user1Id, user2Id);
    var newMessage = {
      'sender_id': user1Id,
      'chat_id': chatID,
      'message': message
    };

    await supabaseClient.from('Messages').insert(newMessage);
  }

  Future<List> getGroupChatIds() async{
    final supabaseClient = (await supabase).client;
    List groupChatIds = [];
    final List codedGroup = await supabaseClient.from('Group_Members').select().eq('profile_id', supabaseClient.auth.currentUser!.id);
    for(var member in codedGroup) {
      groupChatIds.add(member['group_id']);
    }
    return groupChatIds;
  }

  Future<List<String>> getGroupMemberIds(groupId) async{
    final supabaseClient = (await supabase).client;
    List<String> groupMemberIds = [];
    final List codedGroup = await supabaseClient.from('Group_Members').select().eq('group_id', groupId);
    for(var member in codedGroup) {
      groupMemberIds.add(member['profile_id']);
    }
    return groupMemberIds;
  }
  Future<List<Map>> getMemberIdAndAvatar(groupId) async{
    final supabaseClient = (await supabase).client;
    List<Map> groupMemberIds = [];
    final List codedGroup = await supabaseClient.from('group_view').select().eq('group_id', groupId);
    for(var member in codedGroup) {
      var id = member['profile_id'];
      String avatarURL = supabaseClient.storage
        .from('Images')
        .getPublicUrl(member['profile_path']);
      groupMemberIds.add({'id': id, 'avatar' : avatarURL});
    }
    return groupMemberIds;
  }

  Future<List> getGroupChatInfo() async {
    final supabaseClient = (await supabase).client;
    final chatIds = await getGroupChatIds();
    List groupInfo = [];

    final List codedGroupInfo = await supabaseClient.from('Groups').select();

    for(var group in codedGroupInfo) {
      for(var chatId in chatIds) {
        if(chatId == group['group_id']) {
          groupInfo.add({'group_id' : chatId, 'title' : group['name']});
        }
      }
    }
    return groupInfo;
  } 

  Future<void> sendGroupMessage(
      String groupID, String message) async {
    final supabaseClient = (await supabase).client;
    var newMessage = {
      'sender_id': supabaseClient.auth.currentUser!.id,
      'group_id': groupID,
      'message': message
    };

    await supabaseClient.from('Group_Messages').insert(newMessage);
  }

  Future<void> createNewGroup(String title, List users) async {
    final supabaseClient = (await supabase).client;
    users.add(supabaseClient.auth.currentUser!.id);
    var newChat = {
      'name': title,
    };
    var newGroup = await supabaseClient.from('Groups').insert(newChat).select().single();

    for(var user in users) {
      var newMember = {
        'group_id' : newGroup['group_id'],
        'profile_id': user,
    };
      await supabaseClient.from('Group_Members').insert(newMember);
    }

  }
}

final chatsProvider = StateNotifierProvider<ChatsProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ChatsProvider(supabase: supabase);
});
