import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventProvider extends StateNotifier<List?> {
  EventProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;
  List<Event> attendingEvents = [];

  Future<List> readEvents() async {
    final supabaseClient = (await supabase).client;
    final getLocation = await SharedPreferences.getInstance();
    final exsistingLocation = getLocation.getStringList('savedLocation');
    final setRadius = getLocation.getStringList('savedRadius');
    final _currentPosition =
        Position.fromMap(json.decode(exsistingLocation![0]));
    final _preferredRadius = double.parse(setRadius!.first);
    var events = await supabaseClient.rpc('get_recommended_events', params: {
      'user_lon': _currentPosition.longitude,
      'user_lat': _currentPosition.latitude,
      'radius': _preferredRadius
    });
    return events.toList();
  }

  Future<void> deCodeData() async {
    final codedList = await readEvents();
    print(codedList.length);

    List<Event> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var eventData in codedList) {
      print(eventData);
      String profilePictureUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(eventData['profile_path']);
      String eventUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(eventData['event_path']);
      bool bookmarked = false;
      for (var bookmark in eventData['bookmarked']) {
        if (bookmark == supabaseClient.auth.currentUser!.id) {
          bookmarked = true;
          break;
        } else {
          bookmark = false;
        }
      }

      final Event deCodedEvent = Event(
          description: eventData['description'],
          sdate: eventData['time_start'],
          eventId: eventData['event_id'],
          eventType: eventData['invitationtype'],
          host: eventData['host'],
          imageId: eventData['image_id'],
          imageUrl: eventUrl,
          location: eventData['location'],
          title: eventData['title'],
          edate: eventData['time_end'],
          attendees: eventData['attendees'],
          hostProfileUrl: profilePictureUrl,
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
        if (deCodedEvent.attendees[i] == supabaseClient.auth.currentUser!.id) {
          attending = true;
          deCodedEvent.attending = true;
          break;
        }
      }

      if ((deCodedEvent.host != supabaseClient.auth.currentUser!.id)) {
        deCodedEvent.isHost = false;
      } else {
        deCodedEvent.isHost = true;
      }
      deCodedList.add(deCodedEvent);
    }
    state = deCodedList;
  }

  Future<void> joinEvent(currentUser, eventToJoin) async {
    final supabaseClient = (await supabase).client;
    final newAttendeeMap = {'event_id': eventToJoin, 'user_id': currentUser};
    await supabaseClient.from('Attendees').insert(newAttendeeMap);
    await deCodeData();
  }

  Future<void> deleteEvent(Event event) async {
    final supabaseClient = (await supabase).client;
    await supabaseClient.from('Event').delete().eq('event_id', event.eventId);
  }

  Future<void> bookmark(eventToMark, currentUser) async {
    final supabaseClient = (await supabase).client;
    final newABookMarkMap = {'user_id': currentUser, 'event_id': eventToMark};
    await supabaseClient.from('Bookmarked').insert(newABookMarkMap);
    await deCodeData();
  }

  Future<void> unBookmark(eventToMark, currentUser) async {
    final supabaseClient = (await supabase).client;
    await supabaseClient
        .from('Bookmarked')
        .delete()
        .eq('event_id', eventToMark)
        .eq('user_id', currentUser);
    await deCodeData();
  }

  Future<List> readComments(String eventId) async {
    final supabaseClient = (await supabase).client;
    var comments = await supabaseClient
        .from('event_comments')
        .select('*')
        .eq("event_id", eventId);
    return comments.toList();
  }

  Future<List<Comment>> getComments(String eventId) async {
    final codedList = await readComments(eventId);

    List<Comment> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var commentData in codedList) {
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
          profileUrl: profileUrl);

      deCodedList.add(decodedComment);
    }
    return deCodedList;
  }

  Future<List<Comment>> postComment(
      currentUser, eventIid, String comment, replyId) async {
    final supabaseClient = (await supabase).client;
    final newCommentMap = {
      'reply_id': replyId,
      'user_id': currentUser,
      'comment_text': comment,
      'event_id': eventIid
    };
    await supabaseClient.from('Comments').insert(newCommentMap);
    return await getComments(eventIid);
  }

  Future<Map> readLinkEvent(eventId) async {
    final supabaseClient = (await supabase).client;
    var events = await supabaseClient
        .from('recommended_events')
        .select('*, Attendees(user_id), Bookmarked(user_id)')
        .eq('event_id', eventId)
        .single();
    return events;
  }

  Future<Event> deCodeLinkEvent(eventId) async {
    final codedEvent = await readLinkEvent(eventId);
    final supabaseClient = (await supabase).client;

    String profilePictureUrl = supabaseClient.storage
        .from('Images')
        .getPublicUrl(codedEvent['profile_path']);
    String eventUrl = supabaseClient.storage
        .from('Images')
        .getPublicUrl(codedEvent['event_path']);
    bool bookmarked = false;
    for (var bookmark in codedEvent['Bookmarked']) {
      if (bookmark['user_id'] == supabaseClient.auth.currentUser!.id) {
        bookmarked = true;
        break;
      } else {
        bookmark = false;
      }
    }
    Event deCodedEvent = Event(
        description: codedEvent['description'],
        sdate: codedEvent['time_start'],
        eventId: codedEvent['event_id'],
        eventType: codedEvent['invitationType'],
        host: codedEvent['host'],
        imageId: codedEvent['image_id'],
        imageUrl: eventUrl,
        location: codedEvent['location'],
        title: codedEvent['title'],
        edate: codedEvent['time_end'],
        attendees: codedEvent['Attendees'],
        hostProfileUrl: profilePictureUrl,
        hostUsername: codedEvent['username'],
        profileName: codedEvent['profile_name'],
        bookmarked: bookmarked,
        attending: false,
        isHost: false,
        friends: codedEvent['friends_attending'],
        numOfComments: codedEvent['comments_num'].length,
        isVirtual: codedEvent['is_virtual']);

    for (var i = 0; i < deCodedEvent.attendees.length; i++) {
      if (deCodedEvent.attendees[i]['user_id'] ==
          supabaseClient.auth.currentUser!.id) {
        deCodedEvent.attending = true;
        break;
      }
    }
    return deCodedEvent;
  }

  Future<List> readEventAttendees(String eventId) async {
    final supabaseClient = (await supabase).client;
    var comments = await supabaseClient
        .rpc('attendees_by_event',params: {'current_event_id' : eventId});
    return comments.toList();
  }

  Future<List<Friend>> getEventAttendees(String eventId) async {
    final codedList = await readEventAttendees(eventId);

    List<Friend> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var attendeeData in codedList) {
      String profileUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(attendeeData['profile_path']);

      final Friend decodedAttendee = Friend(
          friendProfileId: attendeeData['user_id'],
          friendUsername: attendeeData['username'],
          avatar: profileUrl);

      deCodedList.add(decodedAttendee);
    }
    return deCodedList;
  }

  Future<List> readEventFriends(String eventId) async {
    final supabaseClient = (await supabase).client;
    var comments = await supabaseClient
        .rpc('friends_by_event',params: {'event_id_t' : eventId});
    return comments.toList();
  }

  Future<List<Friend>> getEventFriends(String eventId) async {
    final codedList = await readEventFriends(eventId);

    List<Friend> deCodedList = [];
    final supabaseClient = (await supabase).client;

    for (var attendeeData in codedList) {
      String profileUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(attendeeData['profile_path']);

      final Friend decodedAttendee = Friend(
          friendProfileId: attendeeData['user_id'],
          friendUsername: attendeeData['username'],
          avatar: profileUrl);

      deCodedList.add(decodedAttendee);
    }
    return deCodedList;
  }
}

final eventsProvider = StateNotifierProvider<EventProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return EventProvider(supabase: supabase);
});
