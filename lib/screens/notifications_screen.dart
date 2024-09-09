import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/notification-providers/notification-provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';
import 'package:nomo/screens/friends/chat_screen.dart';
import 'package:nomo/screens/friends/friends_screen.dart';
import 'package:nomo/widgets/fade_out_dismissable.dart';
import 'package:nomo/widgets/notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  void _handleNotificationTap(NotificationData notification) {
    switch (notification.type) {
      case 'UPDATE':
      case 'JOIN':
      case 'CREATE':
      case 'EventComment':
        String? eventId = notification.additionalData?['eventId'];
        if (eventId != null) {
          ref.read(eventsProvider.notifier).deCodeLinkEvent(eventId).then((event) {
            if (event != null) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedEventScreen(eventData: event),
                ),
              );
            }
          });
        }
        break;
      case 'REQUEST':
      case 'ACCEPT':
      case 'GROUP':
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (context) => const NavBar(
                    initialIndex: 3,
                  )),
        );
        break;
    }
  }

  IconData _notificationIcon(NotificationData notification) {
    switch (notification.type) {
      case 'UPDATE':
      case 'JOIN':
      case 'CREATE':
      case 'DELETE':
        return Icons.calendar_today;
      case 'REQUEST':
      case 'ACCEPT':
        return Icons.person_add_alt_1;
      case 'GROUP':
        return Icons.group_add_sharp;
      case 'EventComment':
        return Icons.message_rounded;
    }
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        // flexibleSpace: PreferredSize(
        //   preferredSize: const Size.fromHeight(kToolbarHeight),

        // ),
        title: Text('Notifications',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            )),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 69, 69, 69),
            height: 1.0,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[notifications.length - 1 - index];
          return FadeOutDismissible(
            key: Key(notification.title),
            onDismissed: (direction) {
              ref.read(unreadNotificationsProvider.notifier).removeNotification(index);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification dismissed')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GestureDetector(
                onTap: () => _handleNotificationTap(notification),
                child: NotificationItem(
                    title: notification.title,
                    details: notification.description,
                    icon: _notificationIcon(
                      notification,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }
}
