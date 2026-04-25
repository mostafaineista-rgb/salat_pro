import 'package:flutter/material.dart';

/// Exposes main-tab navigation to descendants (e.g. Home → Settings) without a global.
class MainNavScope extends InheritedWidget {
  const MainNavScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  /// Switches the bottom [NavigationBar] to [index] (0=Home … 5=Settings).
  final void Function(int index) selectTab;

  static MainNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavScope>();
  }

  @override
  bool updateShouldNotify(covariant MainNavScope oldWidget) {
    return oldWidget.selectTab != selectTab;
  }
}
