import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  bool? isStartTime;

  CustomTimePicker({Key? key, required this.initialTime, required this.onTimeSelected, this.isStartTime})
      : super(key: key);

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int hour;
  late int minute;
  late String timeFormat;

  @override
  void initState() {
    super.initState();
    hour = widget.initialTime.hourOfPeriod;
    minute = widget.initialTime.minute;
    timeFormat = widget.initialTime.period == DayPeriod.am ? "AM" : "PM";
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isStartTime == null)
              Text(
                "Pick Your Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorScheme.onSurface,
                ),
              ),
            if (widget.isStartTime == true)
              Text(
                "Pick Your Start Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorScheme.onSurface,
                ),
              ),
            if (widget.isStartTime == false)
              Text(
                "Pick Your End Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorScheme.onSurface,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, "0")} $timeFormat",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Color.fromARGB(255, 27, 27, 27) : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNumberPicker(true),
                  _buildNumberPicker(false),
                  _buildAmPmPicker(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final selectedTime = TimeOfDay(
                      hour: timeFormat == "PM" ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour),
                      minute: minute,
                    );
                    Navigator.of(context).pop(selectedTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker(bool isHour) {
    return NumberPicker(
      minValue: isHour ? 1 : 0,
      maxValue: isHour ? 12 : 59,
      value: isHour ? hour : minute,
      zeroPad: true,
      infiniteLoop: true,
      itemWidth: 60,
      itemHeight: 40,
      onChanged: (value) {
        setState(() {
          if (isHour) {
            hour = value;
          } else {
            minute = value;
          }
        });
      },
      textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
      selectedTextStyle:
          TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
          bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildAmPmPicker() {
    return Column(
      children: [
        _buildAmPmButton("AM"),
        const SizedBox(height: 8),
        _buildAmPmButton("PM"),
      ],
    );
  }

  Widget _buildAmPmButton(String format) {
    final bool isSelected = timeFormat == format;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() {
          timeFormat = format;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: Text(
          format,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
