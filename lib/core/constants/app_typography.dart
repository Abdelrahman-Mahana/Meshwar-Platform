import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Enterprise typography scale for MASHWAR (Cairo font family).
/// Tuned for calm visual rhythm, scannability, and native Arabic/Latin legibility.
class AppTypography {
  AppTypography._();

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

  /// Display / Hero heading — 25px / w800
  static TextStyle largeTitle({Color color = AppColors.navy}) => _cairo(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
      );

  /// Section / Screen title — 18px / w700
  static TextStyle title({Color color = AppColors.navy}) => _cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.32,
      );

  /// Primary body copy — 15px / w500
  static TextStyle body({Color color = AppColors.textPrimary}) => _cairo(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.48,
      );

  /// Secondary / supporting body copy — 13.5px / w500
  static TextStyle bodySecondary({Color color = AppColors.textSecondary}) =>
      _cairo(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.45,
      );

  /// Caption / compact metadata — 12px / w500
  static TextStyle bodySmall({Color color = AppColors.textSecondary}) => _cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  /// Structured field / badge / metadata label — 12px / w600
  static TextStyle label({Color color = AppColors.textSecondary}) => _cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.32,
      );

  /// Primary CTA button text — 15px / w700
  static TextStyle button({Color color = Colors.white}) => _cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  /// Brand wordmark — Cairo w800
  static TextStyle brandLogo({
    double size = 32,
    Color color = AppColors.navy,
  }) =>
      _cairo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );
}
