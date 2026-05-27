import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  static const double _maxWidth = 500;
  static const double _breakpoint = 600;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _breakpoint) return child;

        return Container(
          color: const Color(0xFF1C1C1E),
          child: Center(
            child: SizedBox(
              width: _maxWidth,
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
