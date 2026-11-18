import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography specification for MASHWAR (Cairo font family)
class AppTypography {
  AppTypography._();

  // Helper using GoogleFonts.cairo with fallback
  static TextStyle _cairo({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // عنوان كبير 28 / 800
  static TextStyle largeTitle({Color color = AppColors.navy}) => _cairo(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
      );

  // عنوان 20 / 800
  static TextStyle title({Color color = AppColors.navy}) => _cairo(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.3,
      );

  // نص أساسي 16 / 500
  static TextStyle body({Color color = AppColors.textPrimary}) => _cairo(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  // نص ثانوي 14 / 500
  static TextStyle bodySecondary({Color color = AppColors.textSecondary}) => _cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  // نص صغير 12 / 500
  static TextStyle bodySmall({Color color = AppColors.textSecondary}) => _cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.35,
      );

  // تسمية 12 / 600
  static TextStyle label({Color color = AppColors.textSecondary}) => _cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  // أزرار
  static TextStyle button({Color color = Colors.white}) => _cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  // Logo text: Cairo 800
  static TextStyle brandLogo({double size = 32, Color color = AppColors.navy}) => _cairo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );
}

