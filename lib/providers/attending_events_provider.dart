import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendEventProvider extends StateNotifier<List<Event>> {
  AttendEventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

   Future<List> readEvents1() async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.from('Event').select('*, Attendees(user_id)');
    return events.toList();
  }

  Future<void> deCodeData() async {
    final codedList = await readEvents1();

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;
    final currentUser = supabaseClient.auth.currentUser!.id;

  if(currentUser != null) {
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

        bool attending = false; 
        for(var i = 0; i < deCodedEvent.attendees.length; i++) {
        if(deCodedEvent.attendees[i]['user_id'] == supabaseClient.auth.currentUser!.id) {
          attending = true;
          break;
        }
      }
      
      if((attending) || (deCodedEvent.host == currentUser)) {
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

  Future<void> leaveEvent(currentUser, eventToLeave) async{
    final supabaseClient = (await supabase).client;

    await supabaseClient.from('Attendees').delete().eq('user_id', currentUser).eq('event_id', eventToLeave);
  }
}

final attendEventsProvider = StateNotifierProvider<AttendEventProvider, List<Event>>((ref) {
  final supabase = ref.read(supabaseInstance);
  return AttendEventProvider(supabase: supabase,);
});
