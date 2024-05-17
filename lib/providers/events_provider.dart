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
    var events = await supabaseClient.from('Event').select('*, Attendees(user_id)');
    return events.toList();
  }
  Future<List> getEventImgs() async {
    final supabaseClient = (await supabase).client;
    var eventImgs = await supabaseClient.from('Images').select('*');
    return eventImgs.toList();
  }
  
  Future<void> deCodeData() async {
    final codedList = await readEvents();
    final eventImgs = await getEventImgs();

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      String url='';             
      for(var imgData in eventImgs) {
            if(eventData['image_id'] == imgData['images_id']) {
              url = supabaseClient.storage
                .from('Images')
                .getPublicUrl(imgData['image_url']);
            }
          }

      final Event deCodedEvent = Event(
          description: eventData['description'],
          sdate: eventData['time_start'],
          eventId: eventData['event_id'],
          eventType: eventData['invitationType'],
          host: eventData['host'],
          imageId: eventData['image_id'],
          imageUrl: url,
          location: eventData['location'],
          title: eventData['title'],
          edate: eventData['time_end'],
          attendees: eventData['Attendees'] 
          );

      bool attending = false;
      for(var i = 0; i < deCodedEvent.attendees.length; i++) {
        if(deCodedEvent.attendees[i]['user_id'] == supabaseClient.auth.currentUser!.id) {
          attending = true;
          break;
        }
      }
      
      if((attending == false) && (deCodedEvent.host != supabaseClient.auth.currentUser!.id)) {
        deCodedList.add(deCodedEvent);
      }
    }
    state = deCodedList;
  }
  Future<void> joinEvent(currentUser, eventToJoin) async{
    final supabaseClient = (await supabase).client;
    final newAttendeeMap = {
      'event_id' : eventToJoin,
      'user_id' : currentUser
    };
    await supabaseClient.from('Attendees').insert(newAttendeeMap);
    await deCodeData();
  }
}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});
