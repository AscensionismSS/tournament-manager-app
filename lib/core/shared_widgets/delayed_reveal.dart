import 'dart:async';
import 'package:flutter/material.dart';

/// Revela o [child] com fade + leve subida após um [delay].
/// O espaço do child é mantido durante a espera (zero layout shift).
class DelayedReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const DelayedReveal({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 900),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<DelayedReveal> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
