import 'package:flutter/material.dart';

class TabStyleToggleButtons extends StatelessWidget {
  final List<ToggleOption> options;
  final List<bool> isSelected;
  final Function(int) onPressed;
  final Color? primaryColor;
  final Color? textColor;

  const TabStyleToggleButtons({
    Key? key,
    required this.options,
    required this.isSelected,
    required this.onPressed,
    this.primaryColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualPrimaryColor = primaryColor ?? theme.primaryColor;
    final actualTextColor = textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          return _buildToggleChild(options[index], isSelected[index], actualPrimaryColor, actualTextColor, theme, index);
        }),
      ),
    );
  }

  Widget _buildToggleChild(ToggleOption option, bool isItemSelected, Color primaryColor, Color textColor, ThemeData theme, int index) {
    return InkWell(
      onTap: () => onPressed(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isItemSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 18,
              color: isItemSelected ? primaryColor : textColor,
            ),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isItemSelected ? FontWeight.w600 : FontWeight.normal,
                color: isItemSelected ? primaryColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToggleOption {
  final String label;
  final IconData icon;

  const ToggleOption({required this.label, required this.icon});
}

// Usage example:
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<bool> _selections = [true, false];

  @override
  Widget build(BuildContext context) {
    return TabStyleToggleButtons(
      options: const [
        ToggleOption(label: 'Friends', icon: Icons.people),
        ToggleOption(label: 'Requests', icon: Icons.person_add),
      ],
      isSelected: _selections,
      onPressed: (index) {
        setState(() {
          for (int i = 0; i < _selections.length; i++) {
            _selections[i] = i == index;
          }
        });
      },
    );
  }
}