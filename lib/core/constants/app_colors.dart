import 'package:flutter/material.dart';

/// Design tokens for MASHWAR (مشوار) based on the official brand guidelines
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color navy = Color(0xFF0F2A43); // كحلي ليلي (أساسي)
  static const Color gold = Color(0xFFF5A524); // ذهبي (تمييز)
  static const Color teal = Color(0xFF1B7F79); // فيروزي (نجاح)
  static const Color sand = Color(0xFFFAF7F0); // رملي (براند)
  static const Color surfaceLight = Color(0xFFF8F9FA); // سطح محايد ناعم وعصري مثل أوبر

  // Neutral & Functional Colors
  static const Color textPrimary = Color(0xFF0F2A43); // Always Navy for maximum contrast
  static const Color textSecondary = Color(0xFF5B6470); // رمادي للنص الثانوي
  static const Color borderDisabled = Color(0xFFE5E5EA); // حدود ناعمة عصرية
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFFFFFFF); // خلفية بيضاء نقية

  // Status & Feedback Colors
  static const Color success = Color(0xFF1B7F79); // نجاح
  static const Color warning = Color(0xFFB26A00); // تحذير
  static const Color danger = Color(0xFFB3402A); // خطر
  static const Color coral = Color(0xFFB3402A); // مرجاني
  static const Color info = Color(0xFF1F5F9E); // معلومة

  // Surface Tints
  static const Color tealSurface = Color(0xFFE8F5F3);
  static const Color goldSurface = Color(0xFFFCF3E6);

  // Alert Light Tint Backgrounds (Rule: Alert text is Navy, semantic color for border/icon)
  static const Color successBg = Color(0xFFE8F5F3);
  static const Color warningBg = Color(0xFFFCF3E6);
  static const Color dangerBg = Color(0xFFFBECE9);
  static const Color infoBg = Color(0xFFEAF1F8);
  static const Color offlineBg = Color(0xFFF3F3F4);

  // Chip & Badge Backgrounds
  static const Color chipInactiveBg = Color(0xFFF3F3F4);
  static const Color chipInactiveBorder = Color(0xFFE5E5EA);
  static const Color badgeVerifiedBg = Color(0xFFE8F5F3);
  static const Color badgeReviewBg = Color(0xFFFCF3E6);
  static const Color badgeRejectedBg = Color(0xFFFBECE9);
  static const Color badgeNewBg = Color(0xFFEAF1F8);
  static const Color badgeSuspendedBg = Color(0xFFE2E0D8);
}

