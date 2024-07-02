import 'package:flutter/material.dart';

class TimeBlock extends StatelessWidget {
  final String title;
  final double hourCount;
  final bool? isEvent;

  const TimeBlock({
    Key? key,
    required this.title,
    required this.hourCount,
    this.isEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double blockHeight = hourCount * 50.0;

    return Container(
      height: blockHeight,
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isEvent != null
            ? Theme.of(context).primaryColor.withOpacity(0.7)
            : Colors.redAccent.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}