import 'package:flutter/material.dart';

// Used to display Notifications and their details in the Notification Screen (Not Popup)
//
// Parameters:
// - 'title': title of notification item
// - 'details'(optional): details of the notification item
class NotificationItem extends StatelessWidget {
  final String title;
  final String? details;
  final IconData icon;

  const NotificationItem({
    Key? key,
    required this.title,
    this.details,
    required this.icon,
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
              color: Theme.of(context).primaryColorLight.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: MediaQuery.of(context).size.width / 16,
                  ),
                ),
                const VerticalDivider(
                  color: Colors.white54,
                  thickness: 1,
                  width: 1,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width / 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        if (details != null) ...[
                          const SizedBox(height: 5.0),
                          Text(
                            details!,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width / 28,
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              ]),
            ),
          ),
        ));
  }
}
