import 'dart:html';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventProvider extends StateNotifier<List?> {
  EventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<List> readEvents() async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient.from('recommended_events').select('*, Attendees(user_id), Bookmarked(user_id)');
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
      bool bookmarked;

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
          bookmarked: false,
          attending: false,
          isHost: false,
          );
        for(var bookmark in eventData['Bookmarked']) {
        if(bookmark['user_id'] == supabaseClient.auth.currentUser!.id) {
          deCodedEvent.bookmarked = true;
          break;
        }
      }

      bool attending = false;
      for(var i = 0; i < deCodedEvent.attendees.length; i++) {
        if(deCodedEvent.attendees[i]['user_id'] == supabaseClient.auth.currentUser!.id) {
          attending = true;
          deCodedEvent.attending = true;
          break;
        }
      }
      
      if((attending == false) && (deCodedEvent.host != supabaseClient.auth.currentUser!.id)) {
        deCodedEvent.isHost = false;
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

  Future<void> bookmark(eventToMark, currentUser) async{
    final supabaseClient = (await supabase).client;
    final newABookMarkMap = {
      'user_id' : currentUser,
      'event_id' : eventToMark
    };
    await supabaseClient.from('Bookmarked').insert(newABookMarkMap);
  }

  Future<void> unBookmark(eventToMark, currentUser) async{
    final supabaseClient = (await supabase).client;
    await supabaseClient.from('Bookmarked').delete().eq('event_id', eventToMark).eq('user_id', currentUser);
  }

  Future<List> readComments(String eventId) async {
      final supabaseClient = (await supabase).client;
      var comments = await supabaseClient.from('event_comments').select('*');
      return comments.toList();
    }
  Future<List<Comment>> getComments(String eventId) async{
    final codedList = await readComments(eventId);

    List<Comment> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for(var commentData in codedList) {

      String profileUrl = supabaseClient.storage
      .from('Images')
      .getPublicUrl(commentData['profile_path']);

      final Comment decodedComment = Comment(
        comment_id: commentData['comments_id'],
        comment_text: commentData['comment_text'],
        profile_id: commentData['user_id'],
        reply_comments: commentData['reply_id'],
        timeStamp: commentData['commented_at'],
        username: commentData['username'],
        profileUrl: profileUrl
      );

      deCodedList.add(decodedComment);
    }
    return deCodedList;
  }

}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});
