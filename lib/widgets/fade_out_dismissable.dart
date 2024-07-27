import 'package:flutter/material.dart';

class FadeOutDismissible extends StatefulWidget {
  final Widget child;
  final Key key;
  final Function(DismissDirection) onDismissed;

  const FadeOutDismissible({
    required this.key,
    required this.child,
    required this.onDismissed,
  }) : super(key: key);

  @override
  _FadeOutDismissibleState createState() => _FadeOutDismissibleState();
}

class _FadeOutDismissibleState extends State<FadeOutDismissible> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key,
      onDismissed: widget.onDismissed,
      onUpdate: (details) {
        setState(() {
          _opacity = 1.0 - details.progress;
        });
      },
      background: Container(color: Colors.transparent),
      child: Opacity(
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}
