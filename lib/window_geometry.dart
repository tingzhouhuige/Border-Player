import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';

const Size minimumAppWindowSize = Size(507, 507);
const Size defaultAppWindowSize = Size(1280, 756);

Size constrainWindowSizeToWorkArea(Size requested, Rect workArea) {
  if (!workArea.width.isFinite ||
      !workArea.height.isFinite ||
      workArea.width <= 0 ||
      workArea.height <= 0) {
    return defaultAppWindowSize;
  }
  final requestedWidth = requested.width.isFinite && requested.width > 0
      ? requested.width
      : defaultAppWindowSize.width;
  final requestedHeight = requested.height.isFinite && requested.height > 0
      ? requested.height
      : defaultAppWindowSize.height;
  return Size(
    requestedWidth.clamp(
      math.min(minimumAppWindowSize.width, workArea.width),
      workArea.width,
    ),
    requestedHeight.clamp(
      math.min(minimumAppWindowSize.height, workArea.height),
      workArea.height,
    ),
  );
}

Rect displayWorkArea(Display display) => Rect.fromLTWH(
      display.visiblePosition?.dx ?? 0,
      display.visiblePosition?.dy ?? 0,
      display.visibleSize?.width ?? display.size.width,
      display.visibleSize?.height ?? display.size.height,
    );

bool hasMeaningfulVisibleArea(
  Rect bounds,
  Iterable<Rect> workAreas, {
  double minimumVisibleExtent = 32.0,
}) {
  if (!bounds.left.isFinite ||
      !bounds.top.isFinite ||
      !bounds.width.isFinite ||
      !bounds.height.isFinite ||
      bounds.width <= 0 ||
      bounds.height <= 0) {
    return false;
  }

  for (final workArea in workAreas) {
    final intersection = bounds.intersect(workArea);
    if (!intersection.isEmpty &&
        intersection.width >= minimumVisibleExtent &&
        intersection.height >= minimumVisibleExtent) {
      return true;
    }
  }
  return false;
}

Display? displayForWindow(Rect windowBounds, List<Display> displays) {
  Display? best;
  var largestIntersection = 0.0;
  for (final display in displays) {
    final intersection = windowBounds.intersect(displayWorkArea(display));
    final area =
        intersection.isEmpty ? 0.0 : intersection.width * intersection.height;
    if (area > largestIntersection) {
      largestIntersection = area;
      best = display;
    }
  }
  return best;
}

Rect safeRestoredWindowBounds({
  required Rect savedBounds,
  required List<Display> displays,
  required Display primaryDisplay,
  String? savedDisplayId,
  String? savedDisplayName,
  Rect? savedDisplayWorkArea,
}) {
  Display? target;
  // The Windows plugin historically returned the same ID for every display.
  // Prefer the stable device name, then use an ID only when it is unique.
  for (final display in displays) {
    if (savedDisplayName != null && display.name == savedDisplayName) {
      target = display;
      break;
    }
  }
  if (target == null && savedDisplayId != null) {
    final matching = displays
        .where((display) => display.id.toString() == savedDisplayId)
        .toList();
    if (matching.length == 1) target = matching.single;
  }

  // Older settings do not contain display identity. Absolute coordinates are
  // still useful when they overlap a currently connected display.
  if (savedDisplayId == null && savedDisplayName == null) {
    target ??= displayForWindow(savedBounds, displays);
  }

  final displayStillExists = target != null;
  target ??= primaryDisplay;
  final workArea = displayWorkArea(target);
  final width = savedBounds.width
      .clamp(
        math.min(minimumAppWindowSize.width, workArea.width),
        workArea.width,
      )
      .toDouble();
  final height = savedBounds.height
      .clamp(
        math.min(minimumAppWindowSize.height, workArea.height),
        workArea.height,
      )
      .toDouble();

  double left;
  double top;
  if (!displayStillExists) {
    left = workArea.left + (workArea.width - width) / 2;
    top = workArea.top + (workArea.height - height) / 2;
  } else if (savedDisplayWorkArea != null) {
    left = _remapAxis(
      savedValue: savedBounds.left,
      savedOrigin: savedDisplayWorkArea.left,
      savedExtent: savedDisplayWorkArea.width,
      savedWindowExtent: savedBounds.width,
      newOrigin: workArea.left,
      newExtent: workArea.width,
      newWindowExtent: width,
    );
    top = _remapAxis(
      savedValue: savedBounds.top,
      savedOrigin: savedDisplayWorkArea.top,
      savedExtent: savedDisplayWorkArea.height,
      savedWindowExtent: savedBounds.height,
      newOrigin: workArea.top,
      newExtent: workArea.height,
      newWindowExtent: height,
    );
  } else {
    left = savedBounds.left;
    top = savedBounds.top;
  }

  left = left.clamp(workArea.left, workArea.right - width).toDouble();
  top = top.clamp(workArea.top, workArea.bottom - height).toDouble();
  return Rect.fromLTWH(left, top, width, height);
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
