import 'package:flutter/material.dart';
import 'theme_controller.dart';

class ThemeProvider extends InheritedNotifier<ThemeController> {
  const ThemeProvider({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'ThemeProvider not found in context');
    return provider!.notifier!;
  }
}
