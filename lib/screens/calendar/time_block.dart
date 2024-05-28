import 'package:flutter/material.dart';

class TimeBlock extends StatelessWidget {
  final String title;
  final double hourCount;

  const TimeBlock({
    Key? key,
    required this.title,
    required this.hourCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double blockHeight = hourCount * 50.0; // Adjust height based on hours

    return Container(
      height: blockHeight,
      decoration: BoxDecoration(
        color: Color.fromARGB(245, 244, 67, 54), // Adjust color as needed
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
