import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

enum options { itemOne, itemTwo, itemThree, itemFour }

class EventInfo extends StatefulWidget {
  const EventInfo(
      {super.key, required this.eventsData, required this.attendOrHost});
  final Event eventsData;
  final bool attendOrHost;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${widget.eventsData.attendies} Attending"),
              Text("${widget.eventsData.friends.length} Friends Attending"),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).primaryColor),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).primaryColorLight),
                  ),
                  child: const Text('Join'),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.square_sharp)),
              ],
            ),
          ),
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
              const PopupMenuItem(
                value: options.itemFour,
                child: Text("View Details"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
