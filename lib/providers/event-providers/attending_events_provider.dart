import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AttendEventProvider extends StateNotifier<List<Event>> {
  AttendEventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<List> readEvents() async {
    /*
      gets All of the current users Attending, Hosted, and Bookmarked Events data
      and returns it as a list

      Params: none
      
      Returns: List of supabase friend data
    */
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.from('recommended_events').select('*, Attendees(user_id), Bookmarked(user_id)');
    return events.toList();
  }

  Future<void> deCodeData() async {
    /*
      takes in a list of friend data and converts it to a list of Friends with
      attached images for the hosts avatar and event image and sets the state
      of the provider to the list

      Params: none
      
      Returns: sets state of attending events
    */
    final codedList = await readEvents();

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;
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
      for (var bookmark in eventData['Bookmarked']) {
        if (bookmark['user_id'] == supabaseClient.auth.currentUser!.id) {
          bookmarked = true;
          break;
        }
      }

      final Event deCodedEvent = Event(
          description: eventData['description'],
          sdate: eventData['time_start'],
          eventId: eventData['event_id'],
          eventType: eventData['invitationType'],
          host: eventData['host'],
          imageId: eventData['image_id'],
          imageUrl: eventUrl,
          location: eventData['location'],
          title: eventData['title'],
          edate: eventData['time_end'],
          attendees: eventData['Attendees'],
          hostProfileUrl: profileUrl,
          hostUsername: eventData['username'],
          profileName: eventData['profile_name'],
          bookmarked: bookmarked,
          attending: false,
          isHost: false,
          friends: eventData['friends_attending'],
          numOfComments: eventData['comments_num'].length,
          isVirtual: eventData['is_virtual'],
          isRecurring: eventData['recurring'],
          categories: eventData['event_interests'],
          distanceAway: distance);

      bool attending = false;
      for (var i = 0; i < deCodedEvent.attendees.length; i++) {
        if (deCodedEvent.attendees[i]['user_id'] == supabaseClient.auth.currentUser!.id) {
          attending = true;
          deCodedEvent.attending = true;
          break;
        }
      }
      if ((attending) || ((deCodedEvent.host == supabaseClient.auth.currentUser!.id) || (bookmarked))) {
        if (deCodedEvent.host == supabaseClient.auth.currentUser!.id) {
          deCodedEvent.isHost = true;
        }

        deCodedList.add(deCodedEvent);
      }
    }
    state = deCodedList;
  }

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
          eventType: eventData['invitationType'],
          host: eventData['host'],
          imageId: eventData['image_id'],
          imageUrl: eventUrl,
          location: eventData['location'],
          title: eventData['title'],
          edate: eventData['time_end'],
          attendees: eventData['Attendees'],
          hostProfileUrl: profileUrl,
          hostUsername: eventData['username'],
          profileName: eventData['profile_name'],
          bookmarked: bookmarked,
          attending: false,
          isHost: false,
          friends: eventData['friends_attending'],
          numOfComments: eventData['comments_num'].length,
          isVirtual: eventData['is_virtual'],
          isRecurring: eventData['recurring'],
          categories: eventData['event_interests'],
          otherBookmark: otherBookmark,
          otherAttend: false,
          otherHost: false,
          distanceAway: distance);

      bool attending = false;
      for (var i = 0; i < deCodedEvent.attendees.length; i++) {
        if (deCodedEvent.attendees[i] == currentUser) {
          attending = true;
          deCodedEvent.attending = true;
        }
        if (deCodedEvent.attendees[i] == userId) {
          deCodedEvent.otherAttend = true;
        }
      }
      if ((attending) || (deCodedEvent.host == userId || (bookmarked))) {
        if (deCodedEvent.host == currentUser) {
          deCodedEvent.isHost = true;
        }
      }
      if (deCodedEvent.host == userId) {
        deCodedEvent.otherHost = true;
      }
      print(deCodedEvent);
      deCodedList.add(deCodedEvent);
    }
    state = deCodedList;
  }

  List<Event> eventsAttendingByMonth(int year, int month) {
    /*
      Based on the year and month entered a List of events that are occuring in the month and year entered

      Params: int year, int month
      
      Returns: List of Friends
    */
    List<Event> eventsPerMonth = [];
    final List<Event> allAttend = state;

    for (var event in allAttend) {
      DateTime startDate = DateTime.parse(event.sdate);
      DateTime endDate = DateTime.parse(event.edate);

      // Iterate over each day between startDate and endDate
      for (DateTime day = startDate; day.isBefore(endDate.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
        // Check if the day falls within the specified month and year
        if (day.year == year && day.month == month) {
          eventsPerMonth.add(event);
          break; // Break once we've added the event for this day
        }
      }
    }

    return eventsPerMonth;
  }

  Future<void> leaveEvent(eventToLeave, currentUser) async {
    /*
      Deletes the attending record for the event and user entered. 

      Params: eventToLeave: uuid, currentUser: uuid
      
      Returns: none
    */
    final supabaseClient = (await supabase).client;

    await supabaseClient.from('Attendees').delete().eq('user_id', currentUser).eq('event_id', eventToLeave);
  }

  void clearEvents() {
    state = [];
  }
}

final attendEventsProvider = StateNotifierProvider<AttendEventProvider, List<Event>>((ref) {
  final supabase = ref.read(supabaseInstance);
  return AttendEventProvider(
    supabase: supabase,
  );
});
