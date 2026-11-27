import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme().copyWith(
      headlineLarge: AppTypography.largeTitle(),
      headlineMedium: AppTypography.largeTitle(),
      titleLarge: AppTypography.title(),
      titleMedium: AppTypography.body(color: AppColors.navy)
          .copyWith(fontWeight: FontWeight.w700),
      titleSmall: AppTypography.bodySecondary(color: AppColors.navy)
          .copyWith(fontWeight: FontWeight.w600),
      bodyLarge: AppTypography.body(),
      bodyMedium: AppTypography.bodySecondary(color: AppColors.textPrimary),
      bodySmall: AppTypography.bodySmall(),
      labelLarge: AppTypography.button(color: AppColors.navy),
      labelMedium: AppTypography.label(),
      labelSmall: AppTypography.bodySmall(),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.slateBg,
      primaryColor: AppColors.navy,
      canvasColor: Colors.white,
      dividerColor: AppColors.slateBorder,
      splashColor: AppColors.navy.withValues(alpha: 0.05),
      highlightColor: AppColors.navy.withValues(alpha: 0.03),
      hoverColor: AppColors.navy.withValues(alpha: 0.03),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        surface: AppColors.cardBg,
        onSurface: AppColors.textPrimary,
        surfaceTint: Colors.transparent,
        outline: AppColors.slateBorder,
        outlineVariant: AppColors.slateBorder,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.navy, size: 22),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17.5,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
          height: 1.28,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slateBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
        ),
        titleTextStyle: AppTypography.title(),
        contentTextStyle:
            AppTypography.bodySecondary(color: AppColors.textPrimary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: AppColors.navy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          side: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
        ),
        textStyle: AppTypography.bodySecondary(color: AppColors.textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusAlert),
        ),
        backgroundColor: AppColors.navy,
        contentTextStyle: AppTypography.bodySecondary(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.navy,
        disabledColor: AppColors.slateBg,
        surfaceTintColor: Colors.transparent,
        side: const BorderSide(
          color: AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        ),
        labelStyle: AppTypography.label(color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: AppTypography.bodySecondary(
          color: AppColors.textSecondary.withValues(alpha: 0.72),
        ),
        labelStyle: AppTypography.bodySecondary(color: AppColors.textSecondary),
        floatingLabelStyle: AppTypography.label(color: AppColors.navy),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: BorderSide(
            color: AppColors.slateBorder.withValues(alpha: 0.7),
            width: AppDimens.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(
            color: AppColors.navy,
            width: AppDimens.borderWidthFocused,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppDimens.borderWidthError,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppDimens.borderWidthFocused,
          ),
        ),
        errorStyle: AppTypography.label(color: AppColors.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slateBorder,
          disabledForegroundColor: AppColors.textSecondary,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(0, AppDimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slateBorder,
          disabledForegroundColor: AppColors.textSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(0, AppDimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.slateBg,
          disabledForegroundColor:
              AppColors.textSecondary.withValues(alpha: 0.65),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(0, AppDimens.secondaryButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          side: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.cobaltSurface,
        selectedIconTheme: const IconThemeData(color: AppColors.navy, size: 22),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.textSecondary, size: 22),
        selectedLabelTextStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        unselectedLabelTextStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
