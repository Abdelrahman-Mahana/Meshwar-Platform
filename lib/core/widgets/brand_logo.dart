import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class MashwarPinIcon extends StatelessWidget {
  const MashwarPinIcon({
    super.key,
    this.size = 48,
    this.isLight = false,
  });

  final double size;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PinPainter(isLight: isLight),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.isLight});
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Top loop circle
    final Paint loopPaint = Paint()
      ..color = isLight ? Colors.white : AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(w * 0.5, h * 0.38);
    final double radius = w * 0.24;
    canvas.drawCircle(center, radius, loopPaint);

    // Golden Pin stem / drop tail
    final Paint goldPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(w * 0.44, h * 0.55);
    path.quadraticBezierTo(w * 0.48, h * 0.88, w * 0.36, h * 0.98);
    path.quadraticBezierTo(w * 0.60, h * 0.90, w * 0.58, h * 0.55);
    path.close();

    canvas.drawPath(path, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => oldDelegate.isLight != isLight;
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.fontSize = 32,
    this.showEnglish = true,
    this.isLight = false,
  });

  final double fontSize;
  final bool showEnglish;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isLight ? Colors.white : AppColors.navy;
    final double iconSize = fontSize * 1.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'مشوار',
              style: AppTypography.brandLogo(
                size: fontSize,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            MashwarPinIcon(size: iconSize, isLight: isLight),
          ],
        ),
        if (showEnglish) ...[
          const SizedBox(height: 2),
          Text(
            'M A S H W A R',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize * 0.32,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
              color: isLight ? Colors.white.withValues(alpha: 0.8) : AppColors.teal,
            ),
          ),
        ],
      ],
    );
  }
}

