import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;

  static const Duration page = Duration(milliseconds: 260);
  static const Duration pageReverse = Duration(milliseconds: 190);
  static const Duration nowPlayingPage = Duration(milliseconds: 240);
  static const Duration nowPlayingPageReverse = Duration(milliseconds: 180);
  static const Duration popup = Duration(milliseconds: 190);
  static const Duration switcher = Duration(milliseconds: 220);
  static const Duration quick = Duration(milliseconds: 160);

  static Widget pageTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    Offset begin = const Offset(0, 0.055),
  }) {
    final enterAnimation = CurvedAnimation(
      parent: animation,
      curve: enter,
      reverseCurve: exit,
    );
    final outgoingAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: enter,
      reverseCurve: exit,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(enterAnimation),
      child: SlideTransition(
        position:
            Tween<Offset>(begin: begin, end: Offset.zero).animate(enterAnimation),
        child: FadeTransition(
          opacity:
              Tween<double>(begin: 1, end: 0.92).animate(outgoingAnimation),
          child: child,
        ),
      ),
    );
  }

  static Widget popupTransition({
    required Animation<double> animation,
    required Widget child,
    Alignment alignment = Alignment.center,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: enter,
      reverseCurve: exit,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.965, end: 1).animate(curved),
          alignment: alignment,
          child: child,
        ),
      ),
    );
  }

  static Widget nowPlayingPageTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final enterAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoingAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final enterOffset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(enterAnimation);
    final exitOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.018),
    ).animate(outgoingAnimation);
    final opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(enterAnimation);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: exitOffset,
        child: SlideTransition(
          position: enterOffset,
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }

  static Widget menuEntryTransition({
    required Widget child,
    int index = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 120 + index * 14),
      curve: enter,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 6),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget switcherTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: enter,
      reverseCurve: exit,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
