import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';
import 'package:border_player/window_geometry.dart';

class WindowsWindowPlacement {
  const WindowsWindowPlacement({
    required this.bounds,
    required this.workArea,
    required this.monitorName,
    this.usesVisibleBounds = false,
  });

  final Rect bounds;
  final Rect workArea;
  final String monitorName;
  final bool usesVisibleBounds;
}

final List<int> _enumeratedMonitors = [];

int _collectMonitor(int monitor, int dc, Pointer rect, int data) {
  _enumeratedMonitors.add(monitor);
  return 1;
}

final Pointer<NativeFunction<MONITORENUMPROC>> _monitorEnumCallback =
    Pointer.fromFunction<MONITORENUMPROC>(_collectMonitor, 0);

Rect _rectFromNative(RECT rect) => Rect.fromLTRB(
      rect.left.toDouble(),
      rect.top.toDouble(),
      rect.right.toDouble(),
      rect.bottom.toDouble(),
    );

WindowsWindowPlacement? _placementForMonitor(int monitor, Rect bounds) {
  if (monitor == 0) return null;
  final info = calloc<MONITORINFOEX>();
  try {
    info.ref.monitorInfo.cbSize = sizeOf<MONITORINFOEX>();
    if (GetMonitorInfo(monitor, info.cast<MONITORINFO>()) == 0) return null;
    return WindowsWindowPlacement(
      bounds: bounds,
      workArea: _rectFromNative(info.ref.monitorInfo.rcWork),
      monitorName: info.ref.szDevice,
    );
  } finally {
    calloc.free(info);
  }
}

List<WindowsWindowPlacement> _allMonitorPlacements() {
  _enumeratedMonitors.clear();
  EnumDisplayMonitors(0, nullptr, _monitorEnumCallback, 0);
  return [
    for (final monitor in _enumeratedMonitors)
      if (_placementForMonitor(monitor, Rect.zero) case final placement?)
        placement,
  ];
}

Future<WindowsWindowPlacement?> captureWindowsWindowPlacement() async {
  if (!Platform.isWindows) return null;
  final window = await windowManager.getId();
  final nativeRect = calloc<RECT>();
  final visibleRect = calloc<RECT>();
  try {
    if (GetWindowRect(window, nativeRect) == 0) return null;
    var bounds = _rectFromNative(nativeRect.ref);
    var usesVisibleBounds = false;
    if (DwmGetWindowAttribute(
          window,
          DWMWA_EXTENDED_FRAME_BOUNDS,
          visibleRect,
          sizeOf<RECT>(),
        ) ==
        0) {
      bounds = _rectFromNative(visibleRect.ref);
      usesVisibleBounds = true;
    }
    final monitor = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
    final placement = _placementForMonitor(monitor, bounds);
    if (placement == null) return null;
    return WindowsWindowPlacement(
      bounds: placement.bounds,
      workArea: placement.workArea,
      monitorName: placement.monitorName,
      usesVisibleBounds: usesVisibleBounds,
    );
  } finally {
    calloc.free(nativeRect);
    calloc.free(visibleRect);
  }
}

Future<bool> restoreWindowsWindowPlacement({
  required Rect savedBounds,
  required Rect savedWorkArea,
  required String savedMonitorName,
  bool savedBoundsAreVisible = false,
}) async {
  if (!Platform.isWindows) return false;
  final monitors = _allMonitorPlacements();
  if (monitors.isEmpty) return false;

  WindowsWindowPlacement? target;
  for (final monitor in monitors) {
    if (monitor.monitorName.toLowerCase() == savedMonitorName.toLowerCase()) {
      target = monitor;
      break;
    }
  }

  final monitorStillExists = target != null;
  target ??= monitors.firstWhere(
    (monitor) => monitor.workArea.contains(Offset.zero),
    orElse: () => monitors.first,
  );
  final workArea = target.workArea;
  final workAreaUnchanged = _rectNearlyEquals(savedWorkArea, workArea);
  final savedBoundsAreOnScreen = hasMeaningfulVisibleArea(
    savedBounds,
    monitors.map((monitor) => monitor.workArea),
  );
  late final int width;
  late final int height;
  late double left;
  late double top;

  if (!savedBoundsAreOnScreen) {
    width = savedBounds.width.clamp(320.0, workArea.width).round();
    height = savedBounds.height.clamp(240.0, workArea.height).round();
    left = workArea.left + (workArea.width - width) / 2;
    top = workArea.top + (workArea.height - height) / 2;
  } else if (monitorStillExists && workAreaUnchanged) {
    // Preserve the user's exact placement, including a deliberately oversized
    // window or one that crosses the edge between two monitors.
    width = savedBounds.width.round();
    height = savedBounds.height.round();
    left = savedBounds.left;
    top = savedBounds.top;
  } else {
    width = savedBounds.width.clamp(320.0, workArea.width).round();
    height = savedBounds.height.clamp(240.0, workArea.height).round();

    if (!monitorStillExists) {
      left = workArea.left + (workArea.width - width) / 2;
      top = workArea.top + (workArea.height - height) / 2;
    } else {
      left = _remapAxis(
        savedValue: savedBounds.left,
        savedOrigin: savedWorkArea.left,
        savedExtent: savedWorkArea.width,
        savedWindowExtent: savedBounds.width,
        newOrigin: workArea.left,
        newExtent: workArea.width,
        newWindowExtent: width.toDouble(),
      );
      top = _remapAxis(
        savedValue: savedBounds.top,
        savedOrigin: savedWorkArea.top,
        savedExtent: savedWorkArea.height,
        savedWindowExtent: savedBounds.height,
        newOrigin: workArea.top,
        newExtent: workArea.height,
        newWindowExtent: height.toDouble(),
      );
    }

    left = left.clamp(workArea.left, workArea.right - width).toDouble();
    top = top.clamp(workArea.top, workArea.bottom - height).toDouble();
  }
  final window = await windowManager.getId();
  var outerLeft = left.round();
  var outerTop = top.round();
  var outerWidth = width;
  var outerHeight = height;

  // Users position the visible red window edge, while GetWindowRect includes
  // Windows' invisible resize border. Reapply the current frame insets so the
  // visible edge returns to the exact saved coordinate.
  if (savedBoundsAreVisible) {
    final outerRect = calloc<RECT>();
    final visibleRect = calloc<RECT>();
    try {
      if (GetWindowRect(window, outerRect) != 0 &&
          DwmGetWindowAttribute(
                window,
                DWMWA_EXTENDED_FRAME_BOUNDS,
                visibleRect,
                sizeOf<RECT>(),
              ) ==
              0) {
        final leftInset = visibleRect.ref.left - outerRect.ref.left;
        final topInset = visibleRect.ref.top - outerRect.ref.top;
        final rightInset = outerRect.ref.right - visibleRect.ref.right;
        final bottomInset = outerRect.ref.bottom - visibleRect.ref.bottom;
        outerLeft -= leftInset;
        outerTop -= topInset;
        outerWidth += leftInset + rightInset;
        outerHeight += topInset + bottomInset;
      }
    } finally {
      calloc.free(outerRect);
      calloc.free(visibleRect);
    }
  }

  return SetWindowPos(
        window,
        0,
        outerLeft,
        outerTop,
        outerWidth,
        outerHeight,
        SWP_NOZORDER | SWP_NOACTIVATE,
      ) !=
      0;
}

bool _rectNearlyEquals(Rect a, Rect b) {
  const tolerance = 1.0;
  return (a.left - b.left).abs() <= tolerance &&
      (a.top - b.top).abs() <= tolerance &&
      (a.width - b.width).abs() <= tolerance &&
      (a.height - b.height).abs() <= tolerance;
}

double _remapAxis({
  required double savedValue,
  required double savedOrigin,
  required double savedExtent,
  required double savedWindowExtent,
  required double newOrigin,
  required double newExtent,
  required double newWindowExtent,
}) {
  final oldTravel = math.max(savedExtent - savedWindowExtent, 0.0);
  final newTravel = math.max(newExtent - newWindowExtent, 0.0);
  if (oldTravel == 0) return newOrigin;
  final ratio = ((savedValue - savedOrigin) / oldTravel).clamp(0.0, 1.0);
  return newOrigin + newTravel * ratio;
}
