import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/availability_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/search_provider.dart';

class ProfileProvider extends StateNotifier<Profile?> {
  ProfileProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;

  Future<String> getCurrentUserId() async {
    final supabaseClient = (await supabase).client;
    String profileId = (await supabaseClient
        .from('profile_view')
        .select('profile_id')
        .eq('profile_id', supabaseClient.auth.currentUser!.id)
        .single())['profile_id'];
    return profileId;
  }

  Future<Map> readProfile() async {
    final supabaseClient = (await supabase).client;
    Map profile = {};
    profile = (await supabaseClient
        .from('profile_view')
        .select('*, Interests(interests),  Availability(*)')
        .eq('profile_id', supabaseClient.auth.currentUser!.id)
        .single());
    return profile;
  }

  Future<void> decodeData() async {
    final userProfile = await readProfile();
    Profile profile;
    final supabaseClient = (await supabase).client;
    List<Availability> availability = [];

    String profileUrl = supabaseClient.storage
        .from('Images')
        .getPublicUrl(userProfile['profile_path']);
    for (var avail in userProfile['Availability']) {
      Availability decodedTime = Availability(
        availId: avail['availability_id'],
        userId: avail['user_id'],
        sTime: DateTime.parse(avail['start_time']),
        eTime: DateTime.parse(avail['end_time']),
        blockTitle: avail['block_title'],
        eventId: avail['event_id'],
      );
      availability.add(decodedTime);
    }
    profile = (Profile(
        profile_id: userProfile['profile_id'],
        avatar: profileUrl,
        username: userProfile['username'],
        profile_name: userProfile['profile_name'],
        interests: userProfile['Interests'],
        availability: availability,
        private: userProfile['private']));
    state = profile;
  }

  Future<Map> readProfileById(String userId) async {
    final supabaseClient = (await supabase).client;
    Map profile = {};
    profile = (await supabaseClient
        .from('profile_view')
        .select('*, Interests(interests)')
        .eq('profile_id', userId)
        .single());
    return profile;
  }

  Future<Profile> fetchProfileById(String userId) async {
    final userProfile = await readProfileById(userId);
    final supabaseClient = (await supabase).client;
    List availability = [];

    // Ensure profile_path is not null
    String profilePath = userProfile['profile_path'] ?? '';
    String profileUrl = '';
    if (profilePath.isNotEmpty) {
      profileUrl =
          supabaseClient.storage.from('Images').getPublicUrl(profilePath);
    } else {
      profileUrl =
          'default_avatar_url'; // Use a default avatar URL if profile_path is null
    }

    // Ensure Availability is not null before iterating
    if (userProfile['Availability'] != null) {
      for (var avail in userProfile['Availability']) {
        Availability decodedTime = Availability(
          availId: avail['availability_id'],
          userId: avail['user_id'],
          sTime: DateTime.parse(avail['start_time']),
          eTime: DateTime.parse(avail['end_time']),
          blockTitle: avail['block_title'],
          eventId: avail['event_id'],
        );
        availability.add(decodedTime);
      }
    }

    Profile profile = Profile(
        profile_id: userProfile['profile_id'] ?? '',
        avatar: profileUrl,
        username: userProfile['username'] ?? 'Unknown',
        profile_name: userProfile['profile_name'] ?? 'No Name',
        interests: userProfile['Interests'] ?? [],
        availability: availability,
        private: userProfile['private']);

    return profile;
  }

  Future<List> fetchExistingInterests() async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;
    final response = await supabaseClient
        .from('Interests')
        .select('interests')
        .eq('user_id', userId);
    final List<dynamic> rows = response;
    final List<String> existingInterests =
        rows.map((row) => row['interests'].toString()).toList();
    return existingInterests;
  }

  Future<void> updateInterests(Map<Interests, bool> selectedInterests) async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;

    // Clear existing interests if editing
    if (state?.interests != null) {
      await supabaseClient.from('Interests').delete().eq('user_id', userId);
    }

    // Get selected interests
    final newInterestsRows =
        selectedInterests.entries.where((entry) => entry.value).map((entry) {
      final interestString = enumToString(entry.key);
      return {
        'user_id': userId,
        'interests': interestString,
      };
    }).toList();

    // Insert new interests
    await supabaseClient.from('Interests').insert(newInterestsRows);
  }

  void skipInterests() async {
    final supabaseClient = (await supabase).client;

    final userId = supabaseClient.auth.currentUser!.id;

    // Clear existing interests if skipping
    await supabaseClient.from('Interests').delete().eq('user_id', userId);
  }

  String enumToString(interest) {
    final str = interest.toString().split('.').last;
    return str.replaceAllMapped(RegExp(r"((?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z]))"),
        (match) => ' ${match.group(1)}');
  }

  Future<List> readFriends() async {
    final supabaseClient = (await supabase).client;

    var friends = (await supabaseClient
        .from('friends_view')
        .select('*')
        .eq('current', supabaseClient.auth.currentUser!.id));
    return friends.toList();
  }

  Future<List<Friend>> decodeFriends() async {
    final List userFriendsCoded = await readFriends();
    List<Friend> userFriends = [];
    final supabaseClient = (await supabase).client;

    for (var f in userFriendsCoded) {
      String profileUrl =
          supabaseClient.storage.from('Images').getPublicUrl(f['profile_path']);

      final Friend friend = Friend(
          friendProfileId: f['friend'],
          avatar: profileUrl,
          friendUsername: f['username'],
          friendProfileName: f['profile_name']);

      userFriends.add(friend);
    }
    return userFriends;
  }
  Future<List> readRequests() async {
    final supabaseClient = (await supabase).client;

    var friends = (await supabaseClient
        .from('new_friends_view')
        .select('*')
        .eq('reciver_id', supabaseClient.auth.currentUser!.id));
    return friends.toList();
  }

  Future<List<Friend>> decodeRequests() async {
    final List userFriendsCoded = await readRequests();
    List<Friend> userFriends = [];
    final supabaseClient = (await supabase).client;

    for (var f in userFriendsCoded) {
      String profileUrl =
          supabaseClient.storage.from('Images').getPublicUrl(f['profile_path']);

      final Friend friend = Friend(
          friendProfileId: f['sender_id'],
          avatar: profileUrl,
          friendUsername: f['username'],
          friendProfileName: f['profile_name']);

      userFriends.add(friend);
    }
    return userFriends;
  }

  Future<void> addFriend(currentUserId, friendId) async {
    final supabaseClient = (await supabase).client;
    final newFriendMap = {'current': currentUserId, 'friend': friendId};
    final response = await supabaseClient.from('Friends')
    .select()
    .eq('current', friendId)
    .eq('friend', friendId);

    await supabaseClient.from('Friends').insert(newFriendMap);
    if(response != null) {
      final newFriendRequest = {'reciver_id' : friendId, 'sender_id' : currentUserId};
      await supabaseClient.from('New_Friend').insert(newFriendRequest);
    } else {
      await supabaseClient.from('New_Friend').delete().eq('id', response[0]['id']);
    }
  }

  Future<void> removeFriend(currentUserId, friendId) async {
    final supabaseClient = (await supabase).client;
    await supabaseClient
        .from('Friends')
        .delete()
        .eq('current', currentUserId)
        .eq('friend', friendId);
  }

  Future<bool> isFriend(friendProfileId) async {
    final supabaseClient = (await supabase).client;

    var friends = (await supabaseClient
        .from('Friends')
        .select('*')
        .eq('current', supabaseClient.auth.currentUser!.id)
        .eq('friend', friendProfileId));
    return friends.isNotEmpty;
  }

  Future<void> createBlockedTime(
      profileId, sTime, eTime, title, String? eventId) async {
    final supabaseClient = (await supabase).client;
    Map blockedTimeMap;

    if (eventId == null) {
      blockedTimeMap = {
        'user_id': profileId,
        'start_time': sTime,
        'end_time': eTime,
        'block_title': title
      };
    } else {
      blockedTimeMap = {
        'user_id': profileId,
        'start_time': sTime,
        'end_time': eTime,
        'block_title': title,
        'event_id': eventId
      };
    }

    await supabaseClient.from('Availability').insert(blockedTimeMap);
  }

  Future<void> updateBlockedTime(
      profileId, sTime, eTime, title, availId) async {
    final supabaseClient = (await supabase).client;
    Map blockedTimeMap = {
      'user_id': profileId,
      'start_time': sTime,
      'end_time': eTime,
      'block_title': title
    };
    await supabaseClient
        .from('Availability')
        .update(blockedTimeMap)
        .eq('availability_id', availId);
  }

  Future<void> deleteBlockedTime(String? availId, String? eventId) async {
    final supabaseClient = (await supabase).client;
    if (eventId == null) {
      await supabaseClient
          .from('Availability')
          .delete()
          .eq('availability_id', availId!);
    } else {
      await supabaseClient
          .from('Availability')
          .delete()
          .eq('event_id', eventId);
    }
  }

  List<Availability> availavilityByMonth(int year, int month) {
    List<Availability> availByMonth = [];
    final List allAttend = state!.availability;

    for (int i = 0; i < allAttend.length; i++) {
      int eventYear = allAttend[i].sTime.year;
      int eventMonth = allAttend[i].sTime.month;

      if ((eventYear == year) && (eventMonth == month)) {
        availByMonth.add(allAttend[i]);
      }
    }
    return availByMonth;
  }

  Future<List> mutualAvailability(List<String> userIds, DateTime startDate,
      DateTime endDate, int duration) async {
    final supabaseClient = (await supabase).client;
    List availableTimes = [];
    DateTime currentEndTime = startDate;

    final List blockedTimes = await supabaseClient
        .from('Availability')
        .select('start_time, end_time')
        .inFilter('user_id', userIds)
        .gte('start_time', startDate)
        .lte('end_time', endDate)
        .order('start_time', ascending: true);

    print(duration);
    for (var blocked in blockedTimes) {
      DateTime blockedStart = DateTime.parse(blocked['start_time']);
      DateTime blockedEnd = DateTime.parse(blocked['end_time']);
      print(currentEndTime);

      if (currentEndTime.isBefore(blockedStart) &&
          (blockedStart.difference(currentEndTime).inHours >= duration)) {
        availableTimes
            .add({'start_time': currentEndTime, 'end_time': blockedStart});
        currentEndTime = blockedEnd;
      }
      if (currentEndTime.isBefore(blockedEnd)) {
        currentEndTime = blockedEnd;
      }
      if ((blocked == blockedTimes.last) &&
          currentEndTime.isBefore(endDate) &&
          (endDate.difference(currentEndTime).inHours >= duration)) {
        availableTimes.add({'start_time': currentEndTime, 'end_time': endDate});
      }
    }
    print('${availableTimes}------------------------');
    return availableTimes;
  }

  Future<void> updatePrivacy(bool isPrivate) async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;

    // Update the private value in Supabase
    await supabaseClient
        .from('Profiles')
        .update({'private': isPrivate}).eq('profile_id', userId);
  }
}

final profileProvider = StateNotifierProvider<ProfileProvider, Profile?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ProfileProvider(supabase: supabase);
});
