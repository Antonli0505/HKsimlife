import 'package:flutter/material.dart';

/// 迷你走勢折線（唔依賴 fl_chart）
class PriceSparkline extends StatelessWidget {
  final List<double> prices;
  final double height;
  final double width;
  final Color? color;

  const PriceSparkline({
    super.key,
    required this.prices,
    this.height = 28,
    this.width = 72,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.length < 2) {
      return SizedBox(width: width, height: height);
    }
    final up = prices.last >= prices.first;
    final c = color ??
        (up ? const Color(0xFF3DDC97) : const Color(0xFFFF6B6B));
    return CustomPaint(
      size: Size(width, height),
      painter: _SparkPainter(prices, c),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _SparkPainter(this.prices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final minV = prices.reduce((a, b) => a < b ? a : b);
    final maxV = prices.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = size.width * i / (prices.length - 1);
      final y = size.height * (1 - (prices[i] - minV) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.prices != prices || oldDelegate.color != color;
}
