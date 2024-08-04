import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/chat_id_provider.dart';
import 'package:nomo/providers/notification-bell_provider.dart';
import 'package:nomo/providers/notification-provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Handles incoming Firebase Cloud Messaging (FCM) messages, processes various types
// of notifications based on message data, and triggers notifications
// accordingly by calling showSimpleNotification(). Additionally, triggers UI updates
// to Notification Bell Icon (Friends Screen) and Notification Screen through providers.
//
// Parameters:
// - `message`: The incoming FCM message containing notification details and data.

void handleMessage(RemoteMessage message, BuildContext context, WidgetRef ref) async {
  print("Received message: ${message.notification?.title}");
  print("Message data: ${message.data}");

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  bool eventDeletedSwitch = prefs.getBool('eventDeleted') ?? true;
  bool joinedEventSwitch = prefs.getBool('joinedEvent') ?? true;
  bool joinedEventFriendsOnlySwitch = prefs.getBool('joinedEventFriendsOnly') ?? false;
  bool newEventSwitch = prefs.getBool('newEvent') ?? true;
  bool messageSwitch = prefs.getBool('message') ?? true;
  bool messageFriendsOnlySwitch = prefs.getBool('messageFriendsOnly') ?? false;

  String? type = message.data['type'];

  // Handles in-app notification for a joined event getting deleted
  if (type == 'DELETE' && eventDeletedSwitch) {
    print('DELETE notification handling');
    String eventTitle = message.data['eventTitle'];
    String hostUsername = message.data['hostUsername'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$hostUsername has deleted '$eventTitle'",
        );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
    );
  }
  // Handles in-app notification for a joined event getting updated
  if (type == 'UPDATE' && eventDeletedSwitch) {
    print('UPDATE notification handling');
    String eventTitle = message.data['eventTitle'];
    String hostUsername = message.data['hostUsername'];
    //String eventDescription = message.data['eventDescription'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$hostUsername has updated '$eventTitle'",
        );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
    );
  }
  // Handles in-app notification for another user joining current user's event
  if (type == 'JOIN' && joinedEventSwitch) {
    print('JOIN notification handling');
    String attendeeName = message.data['attendeeName'];
    String attendeeId = message.data['attendeeId'];
    String eventTitle = message.data['eventTitle'];
    // If setting toggle for only notifying if a friend joins is enabled
    if (joinedEventFriendsOnlySwitch) {
      bool isFriend = await ref.read(profileProvider.notifier).isFriend(attendeeId);
      if (isFriend) {
        ref
            .read(unreadNotificationsProvider.notifier)
            .addNotification("$attendeeName has joined your event, '$eventTitle'");
        ref.read(notificationBellProvider.notifier).setBellState(true);
        showSimpleNotification(
          context,
          message.notification?.body ?? 'New Message',
          message.notification?.title ?? 'Notification',
        );
      }
      // If setting toggle for only notifying if a friend joins is disabled (notify for all)
    } else {
      ref
          .read(unreadNotificationsProvider.notifier)
          .addNotification("$attendeeName has joined your event, '$eventTitle'");
      ref.read(notificationBellProvider.notifier).setBellState(true);
      showSimpleNotification(
        context,
        message.notification?.body ?? 'New Message',
        message.notification?.title ?? 'Notification',
      );
    }
  }
  // Handles in-app notification for user's friend creating an event
  if (type == 'CREATE' && newEventSwitch) {
    print('CREATE notification handling');
    String hostUsername = message.data['hostUsername'];
    String eventTitle = message.data['eventTitle'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$hostUsername has created an event, '$eventTitle'",
        );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
    );
  }
  // Handles in-app notification for user recieving a friend request
  if (type == 'REQUEST') {
    print('REQUEST notification handling');
    String senderName = message.data['senderName'];
    ref.read(unreadNotificationsProvider.notifier).addNotification("$senderName has sent you a Friend Request");
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
    );
  }
  // Handles in-app notification for user's friend request getting accepted
  if (type == 'ACCEPT') {
    print('ACCEPT notification handling');
    String recieverName = message.data['senderName'];
    ref.read(unreadNotificationsProvider.notifier).addNotification("$recieverName has accepted your Friend Request");
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
    );
  }
  // Handles in-app notification for user recieving a direct-message
  if (type == 'DM') {
    print('DM notification handling');
    String? senderId = message.data['sender_id'];
    String? chatId = message.data['chat_id'];
    String? activeChatId = ref.read(activeChatIdProvider);

    print('active: $activeChatId');
    print('current: $chatId');

    //Only displays if user is not currently in the chat where the recieved message is from
    if ((activeChatId != chatId || activeChatId == null) && messageSwitch) {
      if (messageFriendsOnlySwitch) {
        bool isFriend = await ref.read(profileProvider.notifier).isFriend(senderId);
        // If setting for only notifying if a friend sends a DM is enabled
        if (isFriend) {
          showSimpleNotification(
            context,
            message.notification?.body ?? 'New Message',
            message.notification?.title ?? 'Notification',
          );
        }
        // If setting toggle for only notifying if a friend sends a DM is disabled (all incoming messages)
      } else {
        showSimpleNotification(
          context,
          message.notification?.body ?? 'New Message',
          message.notification?.title ?? 'Notification',
        );
      }
    } else {
      print("Missing data in notification");
    }
  }
}

// Displays simple notification popup at the top of the user's screen when app is open
//
// Parameters:
// - 'message': Details about the notification, such as specific event title or profile-name of the user who triggered it
// - 'messageTitle': Bold text shown at the top of the message typically showing the type of notification
// - 'background': Color of the notification, set to dark purple by default (can be overwritten)

void showSimpleNotification(BuildContext context, String message, String messageTitle,
    {Color background = const Color.fromARGB(255, 109, 51, 146)}) {
  showOverlayNotification(
    (context) {
      return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        direction: DismissDirection.up,
        onDismissed: (_) {
          OverlaySupportEntry.of(context)?.dismiss();
        },
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 4),
          color: background,
          child: SafeArea(
            child: ListTile(
              leading: Icon(Icons.message, color: Colors.white),
              title: Text(
                messageTitle,
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
              // trailing: IconButton(
              //   icon: Icon(Icons.close, color: Colors.white),
              //   onPressed: () {
              //     OverlaySupportEntry.of(context)?.dismiss();
              //   },
              // ),
            ),
          ),
        ),
      );
    },
    duration: Duration(seconds: 3),
  );
}
