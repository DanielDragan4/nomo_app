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

  Future<void> deCodeData() async {
    final codedList = await readEvents();

    List<Event> deCodedList = [];
    bool attending = false;
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
          edate: eventData['time_end'],
          attendees: eventData['Attendees'] 
          );


      for( var i in deCodedEvent.attendees) {
        if(i == supabaseClient.auth.currentUser!.id) {
          attending = true;
        }
      }
      
      if((!attending) && (deCodedEvent.host != supabaseClient.auth.currentUser!.id)) {
        deCodedList.add(deCodedEvent);
      }
    }
    state = deCodedList;
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
  Future<bool> hasJoined(eventId) async{
    final supabaseClient = (await supabase).client;
    final attendee = await supabaseClient.from('Attendees').select()
    .eq('event_id', eventId).eq('user_id', supabaseClient.auth.currentUser!.id);

    if(attendee.isEmpty) {
      return true;
    }
    else {
      return false;
    }
  }
}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});
