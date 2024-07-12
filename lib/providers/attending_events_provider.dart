import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendEventProvider extends StateNotifier<List<Event>> {
  AttendEventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<List> readEvents() async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient
        .from('recommended_events')
        .select('*, Attendees(user_id), Bookmarked(user_id)');
    return events.toList();
  }

  Future<void> deCodeData() async {
    final codedList = await readEvents();

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      String profileUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(eventData['profile_path']);
      String eventUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(eventData['event_path']);

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
          isVirtual: eventData['is_virtual']);

      bool attending = false;
      for (var i = 0; i < deCodedEvent.attendees.length; i++) {
        if (deCodedEvent.attendees[i]['user_id'] ==
            supabaseClient.auth.currentUser!.id) {
          attending = true;
          deCodedEvent.attending = true;
          break;
        }
      }
      print(deCodedEvent.title);
      if ((attending) ||
          ((deCodedEvent.host == supabaseClient.auth.currentUser!.id) ||
              (bookmarked))) {
        if (deCodedEvent.host == supabaseClient.auth.currentUser!.id) {
          deCodedEvent.isHost = true;
        }
        deCodedList.add(deCodedEvent);
      }
    }
    state = deCodedList;
  }

  Future<List> readEventsWithId(String userID) async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient
        .rpc('get_other_profile_events', params: {'other_user_id': userID});
    return events.toList();
  }

  Future<void> deCodeDataWithId(String userId) async {
    final codedList = await readEventsWithId(userId);

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      String profileUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(eventData['profile_path']);
      String eventUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(eventData['event_path']);

      bool bookmarked = false;
      for (var bookmark in eventData['Bookmarked']) {
        if (bookmark == userId) {
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
          isVirtual: eventData['is_virtual']);

      bool attending = false;
      for (var i = 0; i < deCodedEvent.attendees.length; i++) {
        if (deCodedEvent.attendees[i] == userId) {
          attending = true;
          deCodedEvent.attending = true;
          break;
        }
      }

      if ((attending) || (deCodedEvent.host == userId || (bookmarked))) {
        if (deCodedEvent.host == userId) {
          deCodedEvent.isHost = true;
        }
        deCodedList.add(deCodedEvent);
      }
    }
    state = deCodedList;
  }

  List<Event> eventsAttendingByMonth(int year, int month) {
    List<Event> eventsPerMonth = [];
    final List<Event> allAttend = state;

    for (var event in allAttend) {
      DateTime startDate = DateTime.parse(event.sdate);
      DateTime endDate = DateTime.parse(event.edate);

      // Iterate over each day between startDate and endDate
      for (DateTime day = startDate;
          day.isBefore(endDate.add(Duration(days: 1)));
          day = day.add(Duration(days: 1))) {
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
    final supabaseClient = (await supabase).client;

    await supabaseClient
        .from('Attendees')
        .delete()
        .eq('user_id', currentUser)
        .eq('event_id', eventToLeave);
    deCodeData();
  }

  void clearEvents() {
    state = [];
  }
}

final attendEventsProvider =
    StateNotifierProvider<AttendEventProvider, List<Event>>((ref) {
  final supabase = ref.read(supabaseInstance);
  return AttendEventProvider(
    supabase: supabase,
  );
});
