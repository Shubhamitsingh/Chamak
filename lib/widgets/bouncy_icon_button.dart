import 'package:flutter/material.dart';

/// Small reusable widget that gives a smooth "bounce" tap animation.
class BouncyIconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyIconButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BouncyIconButton> createState() => _BouncyIconButtonState();
}

class _BouncyIconButtonState extends State<BouncyIconButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _setPressed(bool down) {
    setState(() {
      _scale = down ? 0.9 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}

/// Idle "breathing" animation wrapper so icons are always softly moving.
class BreathingWrapper extends StatefulWidget {
  final Widget child;

  const BreathingWrapper({super.key, required this.child});

  @override
  State<BreathingWrapper> createState() => _BreathingWrapperState();
}

class _BreathingWrapperState extends State<BreathingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

/// Special wrapper for call icon to create a "ringing" effect
/// (slight left-right wobble + subtle scale pulse).
class RingingWrapper extends StatefulWidget {
  final Widget child;

  const RingingWrapper({super.key, required this.child});

  @override
  State<RingingWrapper> createState() => _RingingWrapperState();
}

class _RingingWrapperState extends State<RingingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(); // continuous loop

    // First 1 second: stronger left-right wiggle (ringing)
    // Next 1 second: stay at center (no movement) → pause
    _rotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.14, end: 0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.14, end: -0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0), // no rotation → pause
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Only rotate left/right (no scale) so icon does a "ringing" wiggle
        return Transform.rotate(
          angle: _rotation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}



