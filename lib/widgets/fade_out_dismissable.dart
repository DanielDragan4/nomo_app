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

class _FadeOutDismissibleState extends State<FadeOutDismissible> with TickerProviderStateMixin {
  double _opacity = 1.0;
  bool _isDismissing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss(DismissDirection direction) {
    if (!_isDismissing) {
      setState(() {
        _isDismissing = true;
      });
      _animationController.forward().then((_) {
        if (mounted) {
          widget.onDismissed(direction);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key,
      confirmDismiss: (direction) async {
        _handleDismiss(direction);
        await _animationController.forward();
        return true;
      },
      onUpdate: (details) {
        if (!_isDismissing) {
          setState(() {
            _opacity = 1.0 - details.progress;
          });
        }
      },
      background: Container(color: Colors.transparent),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final dismissOpacity = 1.0 - _animationController.value;
          return Opacity(
            opacity: _isDismissing ? dismissOpacity : _opacity,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
