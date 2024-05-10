import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendEventProvider extends StateNotifier<List<Event>> {
  AttendEventProvider({required this.supabase, required this.readEvents}) : super([]);

  Future<Supabase> supabase;
  final Future<List> readEvents;
  List<Event> attendingEvents = [];

  Future<void> deCodeData() async {
    final codedList = await readEvents;

    List<Event> deCodedList = [];
    bool attending = false; 
    final supabaseClient = (await supabase).client;

  if(supabaseClient.auth.currentUser != null) {
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
          edate: eventData['time_end'],
          attendees: eventData['Attendees']);


        for( var i in deCodedEvent.attendees) {
          if(i == supabaseClient.auth.currentUser!.id) {
            attending = true;
        }
      }
      
      if((attending) || (deCodedEvent.host == supabaseClient.auth.currentUser!.id)) {
        deCodedList.add(deCodedEvent);
      }
    }
  }
    state = deCodedList;
  }

  List<Event> eventsAttendingByMonth(int year, int month) {

    List<Event> eventsPerMonth = [];
    final List<Event> allAttend = state;

    for(int i =0; i < allAttend.length; i++) {
      int eventYear = DateTime.parse(allAttend[i].sdate).year;
      int eventMonth = DateTime.parse(allAttend[i].sdate).month;

      if((eventYear == year) && (eventMonth == month)) {
        eventsPerMonth.add(allAttend[i]);
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

  // Future<void> joinEvent(currentUser, eventToJoin) async{
  //   final supabaseClient = (await supabase).client;
  //   final newAttendeeMap = {
  //     'event_id' : eventToJoin,
  //     'user_id' : currentUser
  //   };
  //   await supabaseClient.from('Attendees').insert(newAttendeeMap);
  // }
}

final attendEventsProvider = StateNotifierProvider<AttendEventProvider, List<Event>>((ref) {
  final supabase = ref.read(supabaseInstance);
  final readEvents = ref.watch(eventsProvider.notifier).readEvents();
  return AttendEventProvider(supabase: supabase, readEvents: readEvents);
});
