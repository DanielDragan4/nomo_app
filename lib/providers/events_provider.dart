import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventProvider extends StateNotifier<List?> {
  EventProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;

  Future<List> readEvents() async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.from('Event').select();
    return events.toList();
  }

  Future<void> deCodeData() async {
    final codedList = await readEvents();

    List<Event> deCodedList = [];

    for (int i = 0; i < codedList.length; i++) {
      Event deCodedEvent = Event(
          description: codedList[i]['description'],
          sdate: codedList[i]['time_start'],
          eventId: codedList[i]['event_id'],
          eventType: codedList[i]['invitationType'],
          host: codedList[i]['host'],
          imageId: codedList[i]['image_id'],
          location: codedList[i]['location'],
          title: codedList[i]['title'],
          edate: codedList[i]['time_end']);
      deCodedList.add(deCodedEvent);
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
}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});
