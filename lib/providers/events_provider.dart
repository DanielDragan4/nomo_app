import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventProvider extends StateNotifier<List?> {
  EventProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase; 

  Future<void> readEvents() async{
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.from('Event').select().count(CountOption.exact);
    print(events);
  }
  
}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});