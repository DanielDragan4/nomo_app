import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/notification-provider.dart';
import 'package:nomo/widgets/fade_out_dismissable.dart';
import 'package:nomo/widgets/notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            )),
        centerTitle: false,
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
          return FadeOutDismissible(
            key: Key(notifications[index].title),
            onDismissed: (direction) {
              ref.read(unreadNotificationsProvider.notifier).removeNotification(index);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification dismissed')),
              );
            },
            child: NotificationItem(
              title: notifications[index].title,
              details: notifications[index].description,
            ),
          );
        },
      ),
    );
  }
}
