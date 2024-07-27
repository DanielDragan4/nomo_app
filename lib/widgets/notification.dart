import 'package:flutter/material.dart';

// Used to display Notifications and their details in the Notification Screen (Not Popup)
//
// Parameters:
// - 'title': title of notification item
// - 'details'(optional): details of the notification item
class NotificationItem extends StatelessWidget {
  final String title;
  final String? details;

  const NotificationItem({
    Key? key,
    required this.title,
    this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 5.0),
              // Text(
              //   details,
              //   style: TextStyle(
              //     fontSize: 14.0,
              //     color: Colors.grey[600],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
