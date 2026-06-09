import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ScrollAwareFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() future;
  final AsyncWidgetBuilder<T> builder;
  final Object? cacheKey;

  const ScrollAwareFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.cacheKey,
  });

  @override
  State<ScrollAwareFutureBuilder<T>> createState() =>
      _ScrollAwareFutureBuilderState<T>();
}

class _ScrollAwareFutureBuilderState<T>
    extends State<ScrollAwareFutureBuilder<T>> {
  Future<T>? _future;
  bool _scheduled = false;

  void _createDeferredFuture() {
    if (Scrollable.recommendDeferredLoadingForContext(context)) {
      _scheduleDeferredFuture();
      return;
    }

    setState(() {
      _future = widget.future();
    });
  }

  void _scheduleDeferredFuture() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      _scheduled = false;
      scheduleMicrotask(_createDeferredFuture);
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleDeferredFuture();
  }

  @override
  void didUpdateWidget(covariant ScrollAwareFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cacheKey == oldWidget.cacheKey) return;
    _future = null;
    _scheduleDeferredFuture();
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<T>(
      future: _future,
      builder: widget.builder,
    );
  }
}
