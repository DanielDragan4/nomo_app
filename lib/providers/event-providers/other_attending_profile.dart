import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtherEventProvider extends StateNotifier<List<Event>> {
  OtherEventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<List> readEventsWithId(String userID) async {
    /*
      Runs the 'get_other_profile_events' in supabase to get the selected users profiles events
      based on the userId. Converts this data to Friends and returns the List

      Params: userID: uuid
      
      Returns: List of Friends data
    */
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.rpc('get_other_profile_events', params: {'other_user_id': userID});
    return events.toList();
  }

  Future<void> deCodeDataWithId(String userId) async {
    print('decoded data with ID');
    /*
      Converts read events data to Friends and returns the List as the state

      Params: userID: uuid
      
      Returns: List of Friends
    */
    final codedList = await readEventsWithId(userId);

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;
    final currentUser = supabaseClient.auth.currentUser!.id;
    final getLocation = await SharedPreferences.getInstance();
    final exsistingLocation = getLocation.getStringList('savedLocation');
    final currentPosition = Position.fromMap(json.decode(exsistingLocation![0]));

    for (var eventData in codedList) {
      String profileUrl = supabaseClient.storage.from('Images').getPublicUrl(eventData['profile_path']);
      String eventUrl = supabaseClient.storage.from('Images').getPublicUrl(eventData['event_path']);

      var distance;

      if (eventData['lat'] != null) {
        distance = Geolocator.distanceBetween(
                currentPosition.latitude, currentPosition.longitude, eventData['lat'], eventData['long']) *
            0.000621371;
      }

      bool bookmarked = false;
      bool otherBookmark = false;
      for (var bookmark in eventData['Bookmarked']) {
        if (bookmark == userId) {
          bookmarked = true;
        }
        if (bookmark == currentUser) {
          otherBookmark = true;
        }
      }

      final Event deCodedEvent = Event(
          description: eventData['description'],
          sdate: eventData['time_start'],
          eventId: eventData['event_id'],
          //eventType: eventData['invitationType'],
          host: eventData['host'],
          imageId: eventData['image_id'],
          imageUrl: eventUrl,
          location: eventData['location'],
          title: eventData['title'],
          edate: eventData['time_end'],
          attendees: eventData['Attendees'],
          //hostProfileUrl: profileUrl,
          //hostUsername: eventData['username'],
          //profileName: eventData['profile_name'],
          bookmarked: bookmarked,
          attending: false,
          //isHost: false,
          friends: eventData['friends_attending'],
          numOfComments: eventData['comments_num'].length,
          isVirtual: eventData['is_virtual'],
          isRecurring: eventData['recurring'],
          isTicketed: eventData['ticketed'],
          categories: eventData['event_interests'],
          otherBookmark: otherBookmark,
          otherAttend: false,
          //otherHost: false,
          distanceAway: distance);

      bool attending = false;
      for (var i = 0; i < deCodedEvent.attendees.length; i++) {
        if (deCodedEvent.attendees[i] == currentUser) {
          if (eventData['attendee_start'] != null) {
            deCodedEvent.attendeeDates = {
              'time_start': eventData['attendee_start'],
              'time_end': eventData['attendee_end']
            };
          } else {
            deCodedEvent.attendeeDates = {'time_start': deCodedEvent.sdate.first, 'time_end': deCodedEvent.edate.first};
          }
        } else {
          deCodedEvent.attendeeDates = {'time_start': deCodedEvent.sdate.first, 'time_end': deCodedEvent.edate.first};
        }
        if (deCodedEvent.attendees[i] == userId) {
          deCodedEvent.otherAttend = true;
        }
      }

      // if (deCodedEvent.host == userId) {
      //   deCodedEvent.otherHost = true;
      // }
      if((deCodedEvent.attendeeDates == null) || deCodedEvent.attendeeDates.isEmpty) {
        deCodedEvent.attendeeDates = {'time_start': deCodedEvent.sdate.first, 'time_end': deCodedEvent.edate.first};
      }

      deCodedList.add(deCodedEvent);
    }
    state = deCodedList;
  }

  void clearEvents() {
    state = [];
  }
}

final otherEventsProvider = StateNotifierProvider<OtherEventProvider, List<Event>>((ref) {
  final supabase = ref.read(supabaseInstance);
  return OtherEventProvider(
    supabase: supabase,
  );
});
