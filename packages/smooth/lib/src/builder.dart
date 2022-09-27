import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:smooth/src/adapter.dart';
import 'package:smooth/src/auxiliary_tree.dart';

class SmoothBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, Widget child) builder;
  final Widget child;

  const SmoothBuilder({
    super.key,
    required this.builder,
    required this.child,
  });

  @override
  State<SmoothBuilder> createState() => _SmoothBuilderState();
}

class _SmoothBuilderState extends State<SmoothBuilder> {
  late final AuxiliaryTreePack pack;

  @override
  void initState() {
    super.initState();
    // print('${describeIdentity(this)} initState');

    pack = AuxiliaryTreePack(
      (pack) => Builder(
        builder: (context) => widget.builder(
          context,
          // hack, since AdapterInAuxiliaryTreeWidget not deal with offset yet
          RepaintBoundary(
            child: AdapterInAuxiliaryTreeWidget(
              pack: pack,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // print('${describeIdentity(this)} dispose');
    pack.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // https://github.com/fzyzcjy/yplusplus/issues/5815#issuecomment-1256952866
    // // hack, just for prototype
    // // print('$runtimeType call pack.runPipeline');
    // pack.runPipeline(debugReason: '$runtimeType.build');

    // hack: [AdapterInMainTreeWidget] does not respect "offset" in paint
    // now, so we add a RepaintBoundary to let offset==0
    return RepaintBoundary(
      child: AdapterInMainTreeWidget(
        pack: pack,
        child: widget.child,
      ),
    );
  }
}
