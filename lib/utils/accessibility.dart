import 'package:flutter/material.dart';

class Accessibility {
  Accessibility._();

  static const double MIN_TOUCH_TARGET = 48.0;
  static const double NORMAL_FONT_SCALE = 1.0;
  static const double ACCESSIBLE_FONT_SCALE = 1.375;

  static double fontScale(bool isAccessible) {
    return isAccessible ? ACCESSIBLE_FONT_SCALE : NORMAL_FONT_SCALE;
  }

  static double scaledFontSize(double base, bool isAccessible) {
    return base * fontScale(isAccessible);
  }

  static Widget ensureMinTouchTarget({required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: MIN_TOUCH_TARGET,
        minHeight: MIN_TOUCH_TARGET,
      ),
      child: child,
    );
  }
}
