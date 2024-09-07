import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/events_model.dart';

class SearchProvider extends StateNotifier<List<dynamic>> {
  SearchProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;

  // Calls SQL 'Function to search profiles' in Supabase
  //
  // Parameters:
  // - 'query': what the user is trying to search for
  Future<List> searchProfiles(String query) async {
    final supabaseClient = (await supabase).client;

    final profilesRpc = await supabaseClient.rpc('search_profiles', params: {'query': query});

    final profiles = profilesRpc as List;

    return profiles;
  }

  // Returns decoded (useable) data for the list of queried user profiles,
  // passed in through the use of searchProfiles
  Future<List<Friend>> decodeProfileSearch(String query) async {
    final List userSearchCoded = await searchProfiles(query);
    List<Friend> userSearches = [];
    final supabaseClient = (await supabase).client;

    for (var s in userSearchCoded) {
      String profileUrl = supabaseClient.storage.from('Images').getPublicUrl(s['profile_path']);

      final Friend user = Friend(
          friendProfileId: s['profile_id'],
          avatar: profileUrl,
          friendUsername: s['username'],
          friendProfileName: s['profile_name']);

      userSearches.add(user);
    }
    return userSearches;
  }

  // Calls SQL 'Function to search events' in Supabase
  //
  // Parameters:
  // - 'query': what the user is trying to search for
  Future<List> searchEvents(String query) async {
    final supabaseClient = (await supabase).client;

    final eventsRpc = await supabaseClient.rpc('search_events', params: {'query': query});

    final events = eventsRpc as List;

    return events;
  }

  // Returns decoded (useable) data for the list of queried events,
  // passed in through the use of searchEvents
  Future<List<Event>> decodeEventSearch(String query) async {
    final codedList = await searchEvents(query);

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      String profilePictureUrl = supabaseClient.storage.from('Images').getPublicUrl(eventData['profile_path']);
      String eventUrl = supabaseClient.storage.from('Images').getPublicUrl(eventData['event_path']);
      bool bookmarked = eventData['bookmarked'].contains(supabaseClient.auth.currentUser!.id);

      final Event deCodedEvent = Event(
        description: eventData['description'],
        sdate: eventData['time_start'],
        eventId: eventData['event_id'],
        eventType: eventData['invitationtype'],
        host: eventData['host'],
        imageId: eventData['image_id'],
        imageUrl: eventUrl,
        location: eventData['location'],
        title: eventData['title'],
        edate: eventData['time_end'],
        attendees: eventData['attendees'],
        hostProfileUrl: profilePictureUrl,
        hostUsername: eventData['username'],
        profileName: eventData['profile_name'],
        bookmarked: bookmarked,
        attending: false,
        isHost: false,
        friends: eventData['friends_attending'] ?? [],
        numOfComments: eventData['comments_num'].length,
        isVirtual: eventData['is_virtual'],
        isRecurring: eventData['recurring'],
        isTicketed: eventData['ticketed'],
        categories: eventData['event_interests'],
        distanceAway: eventData['distance_away'],
      );

      // Set attending flag
      deCodedEvent.attending = deCodedEvent.attendees.contains(supabaseClient.auth.currentUser!.id);

      // Set isHost flag
      deCodedEvent.isHost = deCodedEvent.host == supabaseClient.auth.currentUser!.id;

      // Set attendeeDates
      if (deCodedEvent.attending && (eventData['attendee_start'] != null)) {
        deCodedEvent.attendeeDates = {'time_start': eventData['attendee_start'], 'time_end': eventData['attendee_end']};
      } else {
        deCodedEvent.attendeeDates = {'time_start': deCodedEvent.sdate.first, 'time_end': deCodedEvent.edate.first};
      }

      deCodedList.add(deCodedEvent);
    }
    return deCodedList;
  }

  // Calls SQL 'Function to search event_interests' in Supabase
  //
  // Parameters:
  // - 'query': what the user is trying to search for
  Future<List> searchInterests(String query) async {
    final supabaseClient = (await supabase).client;

    final eventsRpc = await supabaseClient.rpc('search_interests', params: {'query': query});

    final events = eventsRpc as List;

    return events;
  }

  // Returns decoded (useable) data for the list of events based on queried interests,
  // passed in through the use of searchInterests
  Future<List<Event>> decodeInterestSearch(String query) async {
    final codedList = await searchInterests(query);

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      String profilePictureUrl = supabaseClient.storage.from('Images').getPublicUrl(eventData['profile_path']);
      String eventUrl = supabaseClient.storage.from('Images').getPublicUrl(eventData['event_path']);
      bool bookmarked = eventData['bookmarked']?.contains(supabaseClient.auth.currentUser!.id) ?? false;

      // Convert timestamps to strings
      List<String> startDates =
          (eventData['time_start'] as List?)?.map((timestamp) => timestamp.toString()).toList() ?? [];
      List<String> endDates = (eventData['time_end'] as List?)?.map((timestamp) => timestamp.toString()).toList() ?? [];

      final Event deCodedEvent = Event(
        description: eventData['description'],
        sdate: startDates,
        eventId: eventData['event_id'],
        eventType: eventData['invitationtype'],
        host: eventData['host'],
        imageId: null, // Assuming this is not provided in the search results
        imageUrl: eventUrl,
        location: eventData['location'],
        title: eventData['title'],
        edate: endDates,
        attendees: eventData['attendees'] ?? [],
        hostProfileUrl: profilePictureUrl,
        hostUsername: eventData['username'],
        profileName: eventData['profile_name'],
        bookmarked: bookmarked,
        attending: false,
        isHost: false,
        friends: eventData['friends_attending'] ?? [],
        numOfComments: eventData['comments_num']?.length ?? 0,
        isVirtual: eventData['is_virtual'] ?? false,
        isRecurring: eventData['recurring'] ?? false,
        isTicketed: eventData['ticketed'] ?? false,
        categories: eventData['event_interests'] ?? [],
        distanceAway: eventData['distance_away'],
      );

      // Set attending flag
      deCodedEvent.attending = deCodedEvent.attendees.contains(supabaseClient.auth.currentUser!.id);

      // Set isHost flag
      deCodedEvent.isHost = deCodedEvent.host == supabaseClient.auth.currentUser!.id;

      // Set attendeeDates
      if (startDates.isNotEmpty && endDates.isNotEmpty) {
        deCodedEvent.attendeeDates = {'time_start': startDates.first, 'time_end': endDates.first};
      } else {
        deCodedEvent.attendeeDates = {'time_start': null, 'time_end': null};
      }

      deCodedList.add(deCodedEvent);
    }
    return deCodedList;
  }
}

final searchProvider = StateNotifierProvider<SearchProvider, List<dynamic>>((ref) {
  final supabase = ref.read(supabaseInstance);
  return SearchProvider(supabase: supabase);
});
