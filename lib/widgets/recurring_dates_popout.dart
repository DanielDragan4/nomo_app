import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringPopout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      content: Center(
        child: Text(
          'Other event dates will be shown here',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
