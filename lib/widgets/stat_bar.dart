import 'package:flutter/material.dart';

/// 屬性條：中文標籤 + 進度條 + 數字（現值／上限）
class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final double labelWidth;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.labelWidth = 36,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final maxLabel = max > 0 ? '$value/$max' : '$value';
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFC9D1D9),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFF21262D),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            maxLabel,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
