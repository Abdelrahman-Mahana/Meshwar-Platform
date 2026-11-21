import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFCFCFD),
      primaryColor: AppColors.navy,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: AppColors.navy,
        contentTextStyle: AppTypography.bodySecondary(color: Colors.white),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        surface: AppColors.cardBg,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: const BorderSide(color: AppColors.borderDisabled, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodySecondary(
          color: AppColors.textSecondary.withValues(alpha: 0.72),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(color: AppColors.borderDisabled, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(color: AppColors.borderDisabled, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        errorStyle: AppTypography.label(color: AppColors.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppDimens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          textStyle: AppTypography.button(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(0, AppDimens.minTouchTarget),
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          textStyle: AppTypography.button(color: AppColors.navy),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: AppTypography.bodySecondary(color: AppColors.navy),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

