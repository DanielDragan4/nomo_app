import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/main.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chat-providers/chat_id_provider.dart';
import 'package:nomo/providers/chat-providers/chats_provider.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/notification-providers/friend-notif-manager.dart';
import 'package:nomo/providers/notification-providers/notification-bell-provider.dart';
import 'package:nomo/providers/notification-providers/notification-provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';
import 'package:nomo/screens/friends/chat_screen.dart';
import 'package:nomo/screens/friends/friends_screen.dart';
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

  // Function to navigate to Friends Screen
  void navigateToFriendsScreen() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => NavBar()),
      (route) => false,
    );
    navigatorKey.currentState?.push(
      MaterialPageRoute(
          builder: (context) => NavBar(
                initialIndex: 3,
              )),
    );
  }

  // Function to navigate to Chat Screen
  void navigateToChatScreen(String senderId, String chatId) {
    ref.read(friendNotificationProvider.notifier).resetNotification(senderId);
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => NavBar()),
      (route) => false,
    );
    navigatorKey.currentState?.push(
      MaterialPageRoute(
          builder: (context) => const NavBar(
                initialIndex: 3,
              )),
    );
    // Fetch friend data using senderId and navigate to ChatScreen
    ref.read(profileProvider.notifier).fetchProfileById(senderId).then((friendProfile) {
      Friend friendData = Friend(
        friendProfileId: friendProfile.profile_id,
        friendProfileName: friendProfile.username,
        friendUsername: friendProfile.username,
        avatar: friendProfile.avatar,
      );
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatterUser: friendData,
            currentUser: ref.read(profileProvider)!.profile_id,
          ),
        ),
      );
    });
  }

  // New function to navigate to Detailed Event Screen
  void navigateToDetailedEventScreen(String eventId) {
    ref.read(eventsProvider.notifier).deCodeLinkEvent(eventId).then((event) {
      if (event != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => NavBar()),
          (route) => false,
        );
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DetailedEventScreen(eventData: event),
          ),
        );
      }
    });
  }

  // Handles in-app notification for a joined event getting deleted
  if (type == 'DELETE' && eventDeletedSwitch) {
    print('DELETE notification handling');
    String eventTitle = message.data['eventTitle'];
    String hostUsername = message.data['hostUsername'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$hostUsername has deleted: '$eventTitle'",
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
    String eventId = message.data['eventId'];
    //String eventDescription = message.data['eventDescription'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
      "$hostUsername has updated: '$eventTitle'",
      type: 'UPDATE',
      additionalData: {'eventId': eventId},
    );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
      onTap: () => navigateToDetailedEventScreen(eventId),
    );
  }
  // Handles in-app notification for another user joining current user's event
  if (type == 'JOIN' && joinedEventSwitch) {
    print('JOIN notification handling');
    String attendeeName = message.data['attendeeName'];
    String attendeeId = message.data['attendeeId'];
    String eventTitle = message.data['eventTitle'];
    String eventId = message.data['eventId'];
    // If setting toggle for only notifying if a friend joins is enabled
    if (joinedEventFriendsOnlySwitch) {
      bool isFriend = await ref.read(profileProvider.notifier).isFriend(attendeeId);
      if (isFriend) {
        ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$attendeeName has joined your event: '$eventTitle'",
          type: 'JOIN',
          additionalData: {'eventId': eventId},
        );
        ref.read(notificationBellProvider.notifier).setBellState(true);
        showSimpleNotification(
          context,
          message.notification?.body ?? 'New Message',
          message.notification?.title ?? 'Notification',
          onTap: () => navigateToDetailedEventScreen(eventId),
        );
      }
      // If setting toggle for only notifying if a friend joins is disabled (notify for all)
    } else {
      ref.read(unreadNotificationsProvider.notifier).addNotification(
        "$attendeeName has joined your event: '$eventTitle'",
        type: 'JOIN',
        additionalData: {'eventId': eventId},
      );
      ref.read(notificationBellProvider.notifier).setBellState(true);
      showSimpleNotification(
        context,
        message.notification?.body ?? 'New Message',
        message.notification?.title ?? 'Notification',
        onTap: () => navigateToDetailedEventScreen(eventId),
      );
    }
  }
  // Handles in-app notification for user's friend creating an event
  if (type == 'CREATE' && newEventSwitch) {
    print('CREATE notification handling');
    String hostUsername = message.data['hostUsername'];
    String eventTitle = message.data['eventTitle'];
    String eventId = message.data['eventId'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
      "$hostUsername has created an event: '$eventTitle'",
      type: 'CREATE',
      additionalData: {'eventId': eventId},
    );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
      onTap: () => navigateToDetailedEventScreen(eventId),
    );
  }
  // Handles in-app notification for user recieving a friend request
  if (type == 'REQUEST') {
    print('REQUEST notification handling');
    String senderName = message.data['senderName'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$senderName has sent you a Friend Request",
          type: 'REQUEST',
        );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
      onTap: navigateToFriendsScreen,
    );
  }
  // Handles in-app notification for user's friend request getting accepted
  if (type == 'ACCEPT') {
    print('ACCEPT notification handling');
    String recieverName = message.data['senderName'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "$recieverName has accepted your Friend Request",
          type: 'ACCEPT',
        );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
      onTap: navigateToFriendsScreen,
    );
  }
  // Handles in-app notification for if user is added to a group
  if (type == 'GROUP') {
    print('GROUP notification handling');
    String groupName = message.data['groupName'];
    ref.read(unreadNotificationsProvider.notifier).addNotification(
          "You have been added to the group '$groupName'",
          type: 'GROUP',
        );
    ref.read(notificationBellProvider.notifier).setBellState(true);
    showSimpleNotification(
      context,
      message.notification?.body ?? 'New Message',
      message.notification?.title ?? 'Notification',
      onTap: navigateToFriendsScreen,
    );
  }
  // Handles in-app notification for user recieving a direct-message
  if (type == 'DM') {
    print('DM notification handling');
    String? senderId = message.data['senderId'];
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
            onTap: () => navigateToChatScreen(senderId!, chatId!),
          );
          ref.read(friendNotificationProvider.notifier).setNotification(senderId!, true);
        }
        // If setting toggle for only notifying if a friend sends a DM is disabled (all incoming messages)
      } else {
        showSimpleNotification(
          context,
          message.notification?.body ?? 'New Message',
          message.notification?.title ?? 'Notification',
          onTap: () => navigateToChatScreen(senderId!, chatId!),
        );
        ref.read(friendNotificationProvider.notifier).setNotification(senderId!, true);
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
    {Color background = const Color.fromARGB(255, 109, 51, 146), VoidCallback? onTap}) {
  showOverlayNotification(
    (context) {
      return GestureDetector(
        onTap: onTap,
        child: Dismissible(
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
        ),
      );
    },
    duration: Duration(seconds: 3),
  );
}
