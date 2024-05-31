import 'package:flutter/material.dart';

class TimeBlock extends StatelessWidget {
  final String title;
  final double hourCount;
  bool? isEvent;

  TimeBlock({
    Key? key,
    required this.title,
    required this.hourCount,
    this.isEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double blockHeight = hourCount * 50.0; // Adjust height based on hours

    return Container(
      height: blockHeight,
      decoration: BoxDecoration(
        color: isEvent != null
            ? Theme.of(context).primaryColor.withOpacity(0.6)
            : Color.fromARGB(245, 244, 67, 54), // Adjust color as needed
        borderRadius: BorderRadius.circular(5.0), // Rounded corners
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white, // Adjust color as needed
            fontSize: 16.0, // Adjust size as needed
          ),
        ),
      ),
    );
  }
}
