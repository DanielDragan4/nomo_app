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

void handleMessage(
    RemoteMessage message, BuildContext context, WidgetRef ref) async {
  print("Received message: ${message.notification?.title}");
  print("Message data: ${message.data}");

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  bool eventDeletedSwitch = prefs.getBool('eventDeleted') ?? true;
  bool joinedEventSwitch = prefs.getBool('joinedEvent') ?? true;
  bool joinedEventFriendsOnlySwitch =
      prefs.getBool('joinedEventFriendsOnly') ?? false;
  bool newEventSwitch = prefs.getBool('newEvent') ?? true;
  // bool newEventFriendsOnlySwitch =
  //     prefs.getBool('newEventFriendsOnly') ?? false;
  bool messageSwitch = prefs.getBool('message') ?? true;
  bool messageFriendsOnlySwitch = prefs.getBool('messageFriendsOnly') ?? false;

  String? type = message.data['type'];

  // if (eventTitle != null &&
  //     hostUsername != null &&
  //     eventDescription != null) {
  if (type == 'DELETE' && eventDeletedSwitch) {
    print('DELETE notification handling');
    String eventTitle = message.data['eventTitle'];
    String hostUsername = message.data['hostUsername'];
    //String eventDescription = message.data['eventDescription'];
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
  if (type == 'JOIN' && joinedEventSwitch) {
    print('JOIN notification handling');
    String attendeeName = message.data['attendeeName'];
    String attendeeId = message.data['attendeeId'];
    String eventTitle = message.data['eventTitle'];
    if (joinedEventFriendsOnlySwitch) {
      bool isFriend =
          await ref.read(profileProvider.notifier).isFriend(attendeeId);
      if (isFriend) {
        ref.read(unreadNotificationsProvider.notifier).addNotification(
            "$attendeeName has joined your event, '$eventTitle'");
        ref.read(notificationBellProvider.notifier).setBellState(true);
        showSimpleNotification(
          context,
          message.notification?.body ?? 'New Message',
          message.notification?.title ?? 'Notification',
        );
      }
    } else {
      ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$attendeeName has joined your event, '$eventTitle'");
      ref.read(notificationBellProvider.notifier).setBellState(true);
      showSimpleNotification(
        context,
        message.notification?.body ?? 'New Message',
        message.notification?.title ?? 'Notification',
      );
    }
  }
  if (type == 'CREATE' && newEventSwitch) {
    print('CREATE notification handling');
    String hostUsername = message.data['hostUsername'];
    String eventTitle = message.data['eventTitle'];
    //String eventDescription = message.data['eventDescription'];
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
  if (type == 'REQUEST') {
    print('REQUEST notification handling');
    String senderName = message.data['senderName'];
    ref
        .read(unreadNotificationsProvider.notifier)
        .addNotification("$senderName has sent you a Friend Request");
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
    );
  }
  if (type == 'DM') {
    print('DM notification handling');
    String? senderId = message.data['sender_id'];
    String? chatId = message.data['chat_id'];
    String? activeChatId = ref.read(activeChatIdProvider);

    print('active: $activeChatId');
    print('current: $chatId');

    if ((activeChatId != chatId || activeChatId == null) && messageSwitch) {
      if (messageFriendsOnlySwitch) {
        bool isFriend =
            await ref.read(profileProvider.notifier).isFriend(senderId);
        if (isFriend) {
          showSimpleNotification(
            context,
            message.notification?.body ?? 'New Message',
            message.notification?.title ?? 'Notification',
          );
        }
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

void showSimpleNotification(BuildContext context, String message, String sender,
    {Color background = const Color.fromARGB(255, 109, 51, 146)}) {
  showOverlayNotification(
    (context) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 4),
        color: background,
        child: SafeArea(
          child: ListTile(
            leading: Icon(Icons.message, color: Colors.white),
            title: Text(
              sender,
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              message,
              style: TextStyle(color: Colors.white),
            ),
            trailing: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                OverlaySupportEntry.of(context)?.dismiss();
              },
            ),
          ),
        ),
      );
    },
    duration: Duration(seconds: 5),
  );
}
