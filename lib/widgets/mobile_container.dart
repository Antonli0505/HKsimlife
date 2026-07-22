import 'package:flutter/material.dart';

/// Mobile-first centered container for web preview.
class MobileContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MobileContainer({
    super.key,
    required this.child,
    this.maxWidth = 430,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            border: Border.symmetric(
              vertical: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
