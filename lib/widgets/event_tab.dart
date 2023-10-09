import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

class EventTab extends StatelessWidget {
  const EventTab({super.key, required this.eventsData});

  final Event eventsData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Color.fromARGB(255, 26, 34, 38),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(eventsData.title),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15))),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.asset(
                  eventsData.image,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Container(
              height: 100,

            )
          ],
        ),
      ),
    );
  }
}
