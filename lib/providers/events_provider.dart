import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventProvider extends StateNotifier<List?> {
  EventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<List> readEvents() async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.from('Event').select().neq('host', supabaseClient.auth.currentUser!.id);
    return events.toList();
  }

  Future<void> deCodeData() async {
    final codedList = await readEvents();

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      final Event deCodedEvent = Event(
          description: eventData['description'],
          sdate: eventData['time_start'],
          eventId: eventData['event_id'],
          eventType: eventData['invitationType'],
          host: eventData['host'],
          imageId: eventData['image_id'],
          location: eventData['location'],
          title: eventData['title'],
          edate: eventData['time_end']);

        final attendee = await supabaseClient.from('Attendees').select()
        .eq('event_id', eventData['event_id']).eq('user_id', supabaseClient.auth.currentUser!.id);
      
      if(attendee.isEmpty) {
        deCodedList.add(deCodedEvent);
      }
      else if(attendee[0]['user_id'] == supabaseClient.auth.currentUser!.id) {
        attendingEvents.add(deCodedEvent);
      }
    }
    state = deCodedList;
  }

  List<Event> eventsAttendingByMonth(int year, int month) {

    List<Event> eventsPerMonth = [];
    final List<Event> allAttend = attendingEvents;

    for(int i =0; i < allAttend.length; i++) {
      int eventYear = DateTime.parse(allAttend[i].sdate).year;
      int eventMonth = DateTime.parse(allAttend[i].sdate).month;
      bool inList = false;

      for(Event checkEvent in eventsPerMonth) {
        if(checkEvent.eventId == allAttend[i].eventId) {
          inList = true;
        }
      }

      if((inList == false) && (eventYear == year) && (eventMonth == month)) {
        eventsPerMonth.add(attendingEvents[i]);
      }
    }
    return eventsPerMonth;
  }

  Future<String> ImageURL(imgId) async {
    final supabaseClient = (await supabase).client;
    final imgPath = await supabaseClient
        .from('Images')
        .select('image_url')
        .eq('images_id', imgId);
    final imgURL = supabaseClient.storage
        .from('Images')
        .getPublicUrl(imgPath[0]['image_url']);

    return imgURL;
  }

  Future<void> joinEvent(currentUser, eventToJoin) async{
    final supabaseClient = (await supabase).client;
    final newAttendeeMap = {
      'event_id' : eventToJoin,
      'user_id' : currentUser
    };
    await supabaseClient.from('Attendees').insert(newAttendeeMap);
  }
}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});
