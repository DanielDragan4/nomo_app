import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

enum options { itemOne, itemTwo, itemThree }

class EventInfo extends StatefulWidget {
  const EventInfo({super.key, required this.eventsData});
  final Event eventsData;
  @override
  State<StatefulWidget> createState() {
    return _EventInfoState();
  }
}

class _EventInfoState extends State<EventInfo> {
  @override
  Widget build(BuildContext context) {
    options? selectedOption;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${widget.eventsData.attendies} Attending"),
          PopupMenuButton<options>(
            onSelected: (options item) {
              setState(
                () {
                  selectedOption = item;
                },
              );
            },
            itemBuilder: (context) => <PopupMenuEntry<options>>[
              const PopupMenuItem(
                value: options.itemOne,
                child: Text("Edit Event"),
              ),
              const PopupMenuItem(
                value: options.itemTwo,
                child: Text("Send Invites"),
              ),
              const PopupMenuItem(
                value: options.itemThree,
                child: Text("Share Link"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
