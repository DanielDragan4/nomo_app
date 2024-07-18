import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/availability_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/models/interests_enum.dart';

class ProfileProvider extends StateNotifier<Profile?> {
  ProfileProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;

  // Returns the ID of the currently logged in user

  Future<String> getCurrentUserId() async {
    final supabaseClient = (await supabase).client;
    String profileId = (await supabaseClient
        .from('profile_view')
        .select('profile_id')
        .eq('profile_id', supabaseClient.auth.currentUser!.id)
        .single())['profile_id'];
    return profileId;
  }

  // Returns all relevant data for the current user to be decoded

  Future<Map> readProfile() async {
    final supabaseClient = (await supabase).client;
    if (supabaseClient.auth.currentUser == null) return {};
    Map profile = {};
    profile = (await supabaseClient
        .from('profile_view')
        .select('*, Interests(interests),  Availability(*)')
        .eq('profile_id', supabaseClient.auth.currentUser!.id)
        .single());
    return profile;
  }

  // Returns decoded (useable) data for the current user, passed in through the use of readProfile

  Future<void> decodeData() async {
    final userProfile = await readProfile();
    if (userProfile == null) return;
    Profile profile;
    final supabaseClient = (await supabase).client;
    List<Availability> availability = [];

    String profileUrl = supabaseClient.storage.from('Images').getPublicUrl(userProfile['profile_path']);

    for (var avail in userProfile['Availability']) {
      DateTime startDate = DateTime.parse(avail['start_time']);
      DateTime endDate = DateTime.parse(avail['end_time']);

      // Calculate the start and end dates
      DateTime startDateTime = DateTime(startDate.year, startDate.month, startDate.day);
      DateTime endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

      if (startDate.day == endDate.day) {
        // If the entire block is in a single day, use original start and end times
        Availability decodedTime = Availability(
          availId: avail['availability_id'],
          userId: avail['user_id'],
          sTime: startDate,
          eTime: endDate,
          blockTitle: avail['block_title'],
          eventId: avail['event_id'],
        );
        availability.add(decodedTime);
      } else {
        // Iterate through each day within the range
        for (var dt = startDateTime;
            dt.isBefore(endDateTime) || dt.isAtSameMomentAs(endDateTime);
            dt = dt.add(Duration(days: 1))) {
          DateTime blockStart;
          DateTime blockEnd;

          // Determine the block start and end times for each day
          if (dt.isAtSameMomentAs(startDateTime)) {
            blockStart = startDate;
            blockEnd = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59, 999);
          } else if (dt.isAtSameMomentAs(endDateTime)) {
            blockStart = DateTime(endDate.year, endDate.month, endDate.day, 0, 0, 0, 0);
            blockEnd = endDate;
          } else {
            blockStart = DateTime(dt.year, dt.month, dt.day, 0, 0, 0, 0);
            blockEnd = DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
          }

          // Create the Availability object for the block of time
          Availability decodedTime = Availability(
            availId: avail['availability_id'],
            userId: avail['user_id'],
            sTime: blockStart,
            eTime: blockEnd,
            blockTitle: avail['block_title'],
            eventId: avail['event_id'],
          );

          availability.add(decodedTime);
        }
      }

      profile = Profile(
        profile_id: userProfile['profile_id'],
        avatar: profileUrl,
        username: userProfile['username'],
        profile_name: userProfile['profile_name'],
        interests: userProfile['Interests'],
        availability: availability,
        private: userProfile['private'],
      );

      state = profile;
    }
  }

  // Returns all relevant data for a user with a specified ID to be decoded\
  //
  // Parameters:
  // - 'userID': The profile_id of the user you wish to retrieve data for, passed in by fetchProfileById

  Future<Map> readProfileById(String userId) async {
    final supabaseClient = (await supabase).client;
    Map profile = {};
    profile =
        (await supabaseClient.from('profile_view').select('*, Interests(interests)').eq('profile_id', userId).single());
    return profile;
  }

  // Returns decoded (useable) data for the user with specified ID, passed in through the use of readProfileById
  //
  // Parameters:
  // - 'userID': The profile_id of the user you wish to retrieve data for, passed to readProfileById

  Future<Profile> fetchProfileById(String userId) async {
    final userProfile = await readProfileById(userId);
    final supabaseClient = (await supabase).client;
    List availability = [];

    // Ensure profile_path is not null
    String profilePath = userProfile['profile_path'] ?? '';
    String profileUrl = '';
    if (profilePath.isNotEmpty) {
      profileUrl = supabaseClient.storage.from('Images').getPublicUrl(profilePath);
    } else {
      profileUrl = 'default_avatar_url'; // Use a default avatar URL if profile_path is null
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

  // Returns a list of interests selected by the current user

  Future<List> fetchExistingInterests() async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;
    final response = await supabaseClient.from('Interests').select('interests').eq('user_id', userId);
    final List<dynamic> rows = response;
    final List<String> existingInterests = rows.map((row) => row['interests'].toString()).toList();
    return existingInterests;
  }

  // Updates the list of current user's interests in the database

  Future<void> updateInterests(Map<Interests, bool> selectedInterests) async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;

    // Clear existing interests if editing
    if (state?.interests != null) {
      await supabaseClient.from('Interests').delete().eq('user_id', userId);
    }

    // Get selected interests
    final newInterestsRows = selectedInterests.entries.where((entry) => entry.value).map((entry) {
      final interestString = enumToString(entry.key);
      return {
        'user_id': userId,
        'interests': interestString,
      };
    }).toList();

    // Insert new interests
    await supabaseClient.from('Interests').insert(newInterestsRows);
  }

  // If user chooses to skip interest selection when creating account,
  // sets user interests to empty list in database, and clears any potentially selected options

  void skipInterests() async {
    final supabaseClient = (await supabase).client;

    final userId = supabaseClient.auth.currentUser!.id;

    // Clear existing interests if skipping
    await supabaseClient.from('Interests').delete().eq('user_id', userId);
  }

  // Cleans up and formats each enum selection for interets
  // Removes any possible punctuation marks and capitalizes start of each word
  //
  // Parameters:
  // - 'interest': current interest selection to be formatted

  String enumToString(interest) {
    final str = interest.toString().split('.').last;
    return str.replaceAllMapped(RegExp(r"((?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z]))"), (match) => ' ${match.group(1)}');
  }

  // Returns list of friends data for current user to be decoded

  Future<List> readFriends() async {
    final supabaseClient = (await supabase).client;

    var friends =
        (await supabaseClient.from('friends_view').select('*').eq('current', supabaseClient.auth.currentUser!.id));
    return friends.toList();
  }

  // Returns decoded (useable) data for the current user's friends, passed in through the use of readFriends

  Future<List<Friend>> decodeFriends() async {
    final List userFriendsCoded = await readFriends();
    List<Friend> userFriends = [];
    final supabaseClient = (await supabase).client;

    for (var f in userFriendsCoded) {
      String profileUrl = supabaseClient.storage.from('Images').getPublicUrl(f['profile_path']);

      final Friend friend = Friend(
          friendProfileId: f['friend'],
          avatar: profileUrl,
          friendUsername: f['username'],
          friendProfileName: f['profile_name']);

      userFriends.add(friend);
    }
    return userFriends;
  }

  // Returns a list of incoming friend requests data for current user

  Future<List> readRequests() async {
    final supabaseClient = (await supabase).client;

    var friends =
        (await supabaseClient.from('new_friends_view').select().eq('reciever_id', supabaseClient.auth.currentUser!.id));
    return friends.toList();
  }

  // Returns a list of incoming and outgoing friend requests data for current user

  Future<List> readOutgoingRequests() async {
    final supabaseClient = (await supabase).client;
    final currentUserId = supabaseClient.auth.currentUser!.id;

    var incomingRequests = await supabaseClient.from('new_friends_view').select().eq('reciever_id', currentUserId);

    var outgoingRequests = await supabaseClient.from('new_friends_view').select().eq('sender_id', currentUserId);

    return [...incomingRequests, ...outgoingRequests];
  }

  // Returns decoded (useable) data for the current user's incoming friend requests, passed in through the use of readRequests

  Future<List<Friend>> decodeRequests() async {
    final List userFriendsCoded = await readRequests();
    List<Friend> userFriends = [];
    final supabaseClient = (await supabase).client;

    for (var f in userFriendsCoded) {
      String profileUrl = supabaseClient.storage.from('Images').getPublicUrl(f['profile_path']);

      final Friend friend = Friend(
          friendProfileId: f['sender_id'],
          avatar: profileUrl,
          friendUsername: f['username'],
          friendProfileName: f['profile_name']);

      userFriends.add(friend);
    }
    print(userFriends);
    return userFriends;
  }

  // Updates Friends and New_Friend tables based on whether a user has an incoming request from the specified user
  //
  // Parameters:
  // - 'friendId': profile_id of user being viewed
  // - 'acceping': determines whether there was a previously incoming request, and accepts if there was one
  //    - If incoming request (accepting == true), add friend instantly
  //    - If no incoming request (accepting == false), send a friend request and set to pending

  Future<void> addFriend(friendId, accepting) async {
    final supabaseClient = (await supabase).client;
    final currentUserId = supabaseClient.auth.currentUser!.id;
    final newFriendMapCurrent = {'current': currentUserId, 'friend': friendId};
    final newFriendMapFriend = {'current': friendId, 'friend': currentUserId};
    final response =
        await supabaseClient.from('New_Friend').select('*').or('reciever_id.eq.$friendId,sender_id.eq.$friendId');

    if (response.isEmpty && !accepting) {
      final newFriendRequest = {'reciever_id': friendId, 'sender_id': currentUserId};
      await supabaseClient.from('New_Friend').insert(newFriendRequest);
    } else if (response.isNotEmpty) {
      await supabaseClient.from('Friends').insert(newFriendMapCurrent);
      await supabaseClient.from('Friends').insert(newFriendMapFriend);
      await supabaseClient.from('New_Friend').delete().eq('id', response[0]['id']);
    }
  }

  // Removes friend of specified user
  //
  // Parameters:
  // - 'currentUserId': profile_id of the current user removing their friend
  // - 'friendId': profile_id of user who is being removed

  Future<void> removeFriend(currentUserId, friendId) async {
    final supabaseClient = (await supabase).client;
    await supabaseClient.from('Friends').delete().eq('current', currentUserId).eq('friend', friendId);
  }

  // Removes incoming friend request sent by a specified user
  // Parameters:
  // - 'friendId': profile_id of user who sent the friend request

  Future<void> removeRequest(friendId) async {
    final supabaseClient = (await supabase).client;
    final currentUserId = supabaseClient.auth.currentUser!.id;
    await supabaseClient.from('New_Friend').delete().eq('reciever_id', currentUserId).eq('sender_id', friendId);
  }

  // Returns if current user is friends with a specified user
  //
  // Parameters:
  // - 'friendProfileId': profile_id of user to check

  Future<bool> isFriend(friendProfileId) async {
    final supabaseClient = (await supabase).client;

    var friends = (await supabaseClient
        .from('Friends')
        .select('*')
        .eq('current', supabaseClient.auth.currentUser!.id)
        .eq('friend', friendProfileId));
    return friends.isNotEmpty;
  }

  // Creates a new time-block for a specified user, requested in DayScreen
  //
  // Parameters:
  // - 'profileId': profile_id of user to create time-block for
  // - 'sTime': start time of time-block
  // - 'eTime': end time of time-block
  // - 'title': title of time-block
  // - 'eventId' (optional): event_id of event being represented by time-block

  Future<void> createBlockedTime(profileId, sTime, eTime, title, String? eventId) async {
    final supabaseClient = (await supabase).client;
    Map blockedTimeMap;

    if (eventId == null) {
      blockedTimeMap = {'user_id': profileId, 'start_time': sTime, 'end_time': eTime, 'block_title': title};
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

  // Updates an existing time-block for a specified user, updated in DayScreen
  //
  // Parameters:
  // - 'profileId': profile_id of user to create time-block for
  // - 'sTime': start time of time-block
  // - 'eTime': end time of time-block
  // - 'title': title of time-block
  // - 'availId': id of time-block being edited

  Future<void> updateBlockedTime(profileId, sTime, eTime, title, availId) async {
    final supabaseClient = (await supabase).client;
    Map blockedTimeMap = {'user_id': profileId, 'start_time': sTime, 'end_time': eTime, 'block_title': title};
    await supabaseClient.from('Availability').update(blockedTimeMap).eq('availability_id', availId);
  }

  // Deletes an existing time-block
  //
  // Parameters:
  // - 'availId' (optional): id of time-block being deleted
  // - 'eventId' (optional): event_id of event being represented by time-block

  Future<void> deleteBlockedTime(String? availId, String? eventId) async {
    final supabaseClient = (await supabase).client;
    if (eventId == null) {
      await supabaseClient.from('Availability').delete().eq('availability_id', availId!);
    } else {
      await supabaseClient.from('Availability').delete().eq('event_id', eventId);
    }
  }

  // Returns list of time-blocks for the current user for a specified month
  //
  // Parameters:
  // - 'year': year of specified month
  // - 'month': month of the year for which to retrieve time-blocks

  List<Availability> availabilityByMonth(int year, int month) {
    List<Availability> availByMonth = [];
    final List allAttend = state!.availability;

    // Print the original availability data
    for (var item in allAttend) {
      print('Original Start Time: ${item.sTime}');
      print('Original End Time: ${item.eTime}');
    }

    for (int i = 0; i < allAttend.length; i++) {
      int eventYear = allAttend[i].sTime.year;
      int eventMonth = allAttend[i].sTime.month;

      if (eventYear == year && eventMonth == month) {
        availByMonth.add(allAttend[i]);
      }
    }

    // Print filtered availability data by month
    for (Availability availability in availByMonth) {
      DateTime startDate = availability.sTime;
      DateTime endDate = availability.eTime;
      print('Filtered Start Time: ${startDate.toString()}');
      print('Filtered End Time: ${endDate.toString()}');
    }

    return availByMonth;
  }

  // Returns list of times within a specified time period when all users are available (no time-blocks)
  //
  // Parameters:
  // - 'userIds': profile_id's of users to check availability for
  // - 'startDate': start date of time period to check mutual availability
  // - 'endDate': end date of time period to check mutual availability
  // - 'duration': minimum duration to consider all parties available

  Future<List> mutualAvailability(List<String> userIds, DateTime startDate, DateTime endDate, int duration) async {
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

    if (blockedTimes.isEmpty) {
      availableTimes.add({'start_time': startDate, 'end_time': endDate});
    }
    for (var blocked in blockedTimes) {
      DateTime blockedStart = DateTime.parse(blocked['start_time']);
      DateTime blockedEnd = DateTime.parse(blocked['end_time']);
      print(currentEndTime);

      if (currentEndTime.isBefore(blockedStart) && (blockedStart.difference(currentEndTime).inHours >= duration)) {
        availableTimes.add({'start_time': currentEndTime, 'end_time': blockedStart});
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
    print('$availableTimes------------------------');
    return availableTimes;
  }

  // Updates whether the current account is private
  //
  // Parameters:
  // - 'isPrivate': value to set privacy to

  Future<void> updatePrivacy(bool isPrivate) async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;

    // Update the private value in Supabase
    await supabaseClient.from('Profiles').update({'private': isPrivate}).eq('profile_id', userId);
  }

  // Updates profile information locally (in provider) if changed
  //
  // Parameters:
  // - 'newUsername': updated username of current user
  // - 'newProfileName': updated profile name of current user
  // - 'newAvatarId' (optional): ID of user's updated avatar (if updated)

  Future updateProfileLocally(
    String newUsername,
    String newProfileName,
    String? newAvatarId,
  ) async {
    if (state != null) {
      final supabaseClient = (await supabase).client;
      String? newAvatarUrl;
      if (newAvatarId != null) {
        newAvatarUrl = supabaseClient.storage.from('Images').getPublicUrl(newAvatarId);
      }
      state = state!.copyWith(
        username: newUsername,
        profile_name: newProfileName,
        avatar: newAvatarUrl ?? state!.avatar,
      );
      print(state);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileProvider, Profile?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ProfileProvider(supabase: supabase);
});
