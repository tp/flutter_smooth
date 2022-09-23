// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hello_package/demo/impl/preempt_builder.dart';

const _kDuration = Duration(milliseconds: 1000);

enum Mode {
  slowByAnimation,
  slowByBuilder,
  fast,
}

class EnterPageAnimation extends StatelessWidget {
  final Mode? mode;
  final Widget child;

  const EnterPageAnimation({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case null:
        return const SizedBox();
      case Mode.slowByAnimation:
        return _EnterPageAnimationSlowByAnimation(child: child);
      case Mode.slowByBuilder:
        return _EnterPageAnimationSlowByBuilder(child: child);
      case Mode.fast:
        return _EnterPageAnimationFast(child: child);
    }
  }
}

class _EnterPageAnimationSlowByAnimation extends StatefulWidget {
  final Widget child;

  const _EnterPageAnimationSlowByAnimation({required this.child});

  @override
  State<_EnterPageAnimationSlowByAnimation> createState() =>
      _EnterPageAnimationSlowByAnimationState();
}

class _EnterPageAnimationSlowByAnimationState
    extends State<_EnterPageAnimationSlowByAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(duration: _kDuration, vsync: this);
  late final _offsetAnimation =
      Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0))
          .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

class _EnterPageAnimationSlowByBuilder extends StatefulWidget {
  final Widget child;

  const _EnterPageAnimationSlowByBuilder({required this.child});

  @override
  State<_EnterPageAnimationSlowByBuilder> createState() =>
      _EnterPageAnimationSlowByBuilderState();
}

class _EnterPageAnimationSlowByBuilderState
    extends State<_EnterPageAnimationSlowByBuilder> {
  var firstFrame = true;

  // hacky, just b/c it is prototype
  // TODO use vsync, duration, etc
  DateTime? initialTime;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() => firstFrame = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      initialTime ??= DateTime.now();
      final ratio = DateTime.now().difference(initialTime!).inMicroseconds /
          _kDuration.inMicroseconds;

      if (ratio < 1) {
        SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {}));
      }

      return Stack(
        children: [
          Positioned(
            left: constraints.maxWidth * max(0, 1 - ratio),
            top: 0,
            bottom: 0,
            width: constraints.maxWidth,
            child: firstFrame ? Container() : widget.child,
          ),
        ],
      );
    });
  }
}

class _EnterPageAnimationFast extends StatefulWidget {
  final Widget child;

  const _EnterPageAnimationFast({required this.child});

  @override
  State<_EnterPageAnimationFast> createState() =>
      _EnterPageAnimationFastState();
}

class _EnterPageAnimationFastState extends State<_EnterPageAnimationFast> {
  // hacky, just b/c it is prototype
  var firstFrame = true;

  // hacky, just b/c it is prototype
  // TODO use vsync, duration, etc
  DateTime? initialTime;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() => firstFrame = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => PreemptBuilder(
        builder: (_, child) {
          initialTime ??= DateTime.now();
          final ratio = DateTime.now().difference(initialTime!).inMicroseconds /
              _kDuration.inMicroseconds;

          print('$runtimeType PreemptBuilder.builder called ratio=$ratio');

          return Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth * max(0, 1 - ratio),
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth,
                  child: child,
                ),
              ],
            ),
          );
        },
        // NOTE: this one extra frame lag is *avoidable*.
        // Since this is a prototype, I do not bother to initialize the aux tree pack
        // in a fancier way.
        child: firstFrame ? Container() : widget.child,
      ),
    );
  }
}
