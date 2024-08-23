import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeSelectorWidget extends StatefulWidget {
  final List<DateTime> startDates;
  final List<DateTime> endDates;
  final Function(DateTime, DateTime) onDateSelected;

  const DateTimeSelectorWidget({
    Key? key,
    required this.startDates,
    required this.endDates,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _DateTimeSelectorWidgetState createState() => _DateTimeSelectorWidgetState();
}

class _DateTimeSelectorWidgetState extends State<DateTimeSelectorWidget> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.startDates.length,
      itemBuilder: (context, index) {
        final startDate = widget.startDates[index];
        final endDate = widget.endDates[index];
        final isSelected = _selectedIndex == index;

        return ListTile(
          title: Text(
            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${_formatTime(startDate)} - ${_formatTime(endDate)}',
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          tileColor: isSelected ? Theme.of(context).cardColor : null,
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            widget.onDateSelected(startDate, endDate);
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}