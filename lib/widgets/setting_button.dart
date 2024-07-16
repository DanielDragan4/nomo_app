import 'package:flutter/material.dart';

//Default button styling for Settings Screen list
class SettingButton extends StatefulWidget {
  const SettingButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isSwitch,
  });

  final String title;
  final Function() onPressed;
  final bool? isSwitch;

  @override
  _SettingButtonState createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  bool _switchVal = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      style: const ButtonStyle(
        alignment: Alignment.centerLeft,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20),
            ),
            if (widget.isSwitch == true)
              Switch(
                value: _switchVal,
                onChanged: (bool newVal) {
                  setState(() {
                    _switchVal = newVal;
                  });
                  if (widget.isSwitch == true) {
                    widget.onPressed();
                  }
                },
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded),
          ],
        ),
      ),
    );
  }
}
