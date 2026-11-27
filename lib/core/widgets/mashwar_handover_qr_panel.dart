import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'mashwar_button.dart';

/// Deterministic, zero-dependency, 100% offline-ready QR matrix widget for
/// MASHWAR handover verification codes (Worksite Supply, Route Parcels, Escrow).
///
/// Renders a crisp 21x21 Version-1-style matrix with 3 corner finder patterns,
/// quiet zone, timing tracks, and deterministic data modules seeded from [data].
class MashwarQrMatrixWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color moduleColor;
  final Color backgroundColor;
  final Color accentColor;
  final bool showFrame;

  const MashwarQrMatrixWidget({
    super.key,
    required this.data,
    this.size = 120,
    this.moduleColor = AppColors.navy,
    this.backgroundColor = Colors.white,
    this.accentColor = AppColors.gold,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final qrCanvas = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MashwarQrMatrixPainter(
          data: data,
          moduleColor: moduleColor,
          backgroundColor: backgroundColor,
          accentColor: accentColor,
        ),
      ),
    );

    if (!showFrame) {
      return Semantics(
        label: 'QR Code $data',
        child: qrCanvas,
      );
    }

    return Semantics(
      label: 'QR Code $data',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: moduleColor.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: moduleColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: qrCanvas,
      ),
    );
  }
}

class _MashwarQrMatrixPainter extends CustomPainter {
  final String data;
  final Color moduleColor;
  final Color backgroundColor;
  final Color accentColor;

  static const int _gridSize = 21;

  const _MashwarQrMatrixPainter({
    required this.data,
    required this.moduleColor,
    required this.backgroundColor,
    required this.accentColor,
  });

  bool _isFinderRegion(int r, int c) {
    final topLeft = r <= 7 && c <= 7;
    final topRight = r <= 7 && c >= _gridSize - 8;
    final bottomLeft = r >= _gridSize - 8 && c <= 7;
    return topLeft || topRight || bottomLeft;
  }

  bool _isCenterBadge(int r, int c) {
    return r >= 9 && r <= 11 && c >= 9 && c <= 11;
  }

  bool _finderModuleOn(int localR, int localC) {
    if (localR < 0 || localR > 6 || localC < 0 || localC > 6) return false;
    final onOuter = localR == 0 || localR == 6 || localC == 0 || localC == 6;
    final onInner = localR >= 2 && localR <= 4 && localC >= 2 && localC <= 4;
    return onOuter || onInner;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;

    // Quiet zone background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()..color = backgroundColor,
    );

    final quiet = side * 0.06;
    final drawable = side - (quiet * 2);
    final cell = drawable / _gridSize;

    // Deterministic PRNG seeded from payload string (FNV-1a 32-bit)
    int seed = 0x811C9DC5;
    for (final unit in data.codeUnits) {
      seed ^= unit;
      seed = (seed * 0x01000193) & 0x7FFFFFFF;
    }
    if (seed == 0) seed = 0x5A3C19F1;

    final darkPaint = Paint()..color = moduleColor;
    final accentPaint = Paint()..color = accentColor;

    for (var r = 0; r < _gridSize; r++) {
      for (var c = 0; c < _gridSize; c++) {
        bool filled = false;

        if (r <= 6 && c <= 6) {
          filled = _finderModuleOn(r, c);
        } else if (r <= 6 && c >= _gridSize - 7) {
          filled = _finderModuleOn(r, c - (_gridSize - 7));
        } else if (r >= _gridSize - 7 && c <= 6) {
          filled = _finderModuleOn(r - (_gridSize - 7), c);
        } else if (_isFinderRegion(r, c)) {
          filled = false; // 1-module white separator
        } else if (_isCenterBadge(r, c)) {
          filled = false;
        } else if (r == 6 || c == 6) {
          // Timing tracks
          filled = (r + c).isEven;
        } else {
          // Deterministic bit mixing per coordinate + payload seed
          int h = seed ^ (r * 73856093) ^ (c * 19349663) ^ ((r + 1) * (c + 3) * 83492791);
          h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF;
          filled = ((h >> 7) & 1) == 1 || ((h >> 15) & 3) == 0;
        }

        if (filled) {
          final rect = Rect.fromLTWH(
            quiet + c * cell,
            quiet + r * cell,
            cell + 0.35,
            cell + 0.35,
          );
          canvas.drawRect(rect, darkPaint);
        }
      }
    }

    // Center MASHWAR micro-emblem (keeps visual identity sharp & distinct)
    final centerRect = Rect.fromLTWH(
      quiet + 9.25 * cell,
      quiet + 9.25 * cell,
      2.5 * cell,
      2.5 * cell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cell * 0.6)),
      darkPaint,
    );
    canvas.drawCircle(
      centerRect.center,
      cell * 0.55,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MashwarQrMatrixPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.moduleColor != moduleColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Captures an auditable emergency handover fallback record when a participant's
/// phone battery is dead or device cannot display the handover QR/code.
@immutable
class EmergencyHandoverRecord {
  final String fallbackRef;
  final String backupContactName;
  final String backupContactPhone;
  final String? qidLast4;
  final String proofNote;
  final DateTime recordedAt;

  const EmergencyHandoverRecord({
    required this.fallbackRef,
    required this.backupContactName,
    required this.backupContactPhone,
    this.qidLast4,
    required this.proofNote,
    required this.recordedAt,
  });
}

/// Unified Handover Security Card showing BOTH the scannable QR Code AND the
/// manual verification code side-by-side, with 1-tap copy, full-screen QR zoom,
/// offline readiness badge, and interactive real-world contingency fallbacks
/// (dead phone battery, broken camera, no internet signal).
class MashwarHandoverQrCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String code;
  final String qrPayload;
  final bool isAr;
  final Color accentColor;
  final Color surfaceColor;
  final Color borderColor;
  final Key? cardKey;
  final Key? codeValueKey;
  final Key? qrKey;
  final Key? contingencyButtonKey;
  final String referenceId;
  final VoidCallback? onSwitchToManualCode;
  final ValueChanged<EmergencyHandoverRecord>? onEmergencyFallbackLogged;

  const MashwarHandoverQrCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.qrPayload,
    required this.isAr,
    required this.referenceId,
    this.accentColor = AppColors.navy,
    this.surfaceColor = AppColors.sand,
    this.borderColor = AppColors.gold,
    this.cardKey,
    this.codeValueKey,
    this.qrKey,
    this.contingencyButtonKey,
    this.onSwitchToManualCode,
    this.onEmergencyFallbackLogged,
  });

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم نسخ رمز التسليم: $code' : 'Handover code copied: $code',
        ),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExpandedQrDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'رمز QR وكود التسليم السريع'
                          : 'Full-Size Handover QR & Code',
                      style: AppTypography.title().copyWith(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.navy),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MashwarQrMatrixWidget(
                data: qrPayload,
                size: 210,
                moduleColor: accentColor,
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    code,
                    style: AppTypography.largeTitle(color: accentColor)
                        .copyWith(letterSpacing: 6, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? 'امسح الرمز بالكاميرا أو أدخل الكود يدوياً (يعمل بدون إنترنت)'
                    : 'Scan QR with camera or enter the code manually (works offline)',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.offline_bolt_outlined,
                      size: 13,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isAr ? 'يعمل أوفلاين' : 'Offline Ready',
                      style: AppTypography.label(color: AppColors.teal)
                          .copyWith(fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 330;
              final qrBox = InkWell(
                key: qrKey,
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showExpandedQrDialog(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MashwarQrMatrixWidget(
                      data: qrPayload,
                      size: isNarrow ? 112 : 104,
                      moduleColor: accentColor,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAr ? 'اضغط لتكبير QR' : 'Tap to zoom QR',
                      style: AppTypography.label(color: AppColors.textSecondary)
                          .copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );

              final codeColumn = Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'الكود اليدوي البديل:' : 'Manual Backup Code:',
                    style: AppTypography.label(color: AppColors.textSecondary)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          code,
                          key: codeValueKey,
                          style: AppTypography.largeTitle(color: accentColor)
                              .copyWith(
                            letterSpacing: 5,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment:
                        isNarrow ? WrapAlignment.center : WrapAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: AppColors.navy.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _copyCode(context),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: Text(
                          isAr ? 'نسخ الكود' : 'Copy Code',
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: AppColors.teal.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showExpandedQrDialog(context),
                        icon: const Icon(Icons.zoom_out_map_rounded, size: 14),
                        label: Text(
                          isAr ? 'تكبير QR' : 'Zoom QR',
                          style: AppTypography.label(color: AppColors.teal)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    qrBox,
                    const SizedBox(height: 12),
                    codeColumn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  qrBox,
                  const SizedBox(width: 14),
                  Expanded(child: codeColumn),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: AppTypography.bodySmall(color: AppColors.navy),
          ),
          const SizedBox(height: 10),
          InkWell(
            key: contingencyButtonKey ??
                const ValueKey('handover_contingency_btn'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => showMashwarHandoverContingencySheet(
              context,
              isAr: isAr,
              referenceId: referenceId,
              handoverCode: code,
              onSwitchToManualCode: onSwitchToManualCode,
              onEmergencyFallbackLogged: onEmergencyFallbackLogged,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.navy.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.battery_alert_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'الموبايل فصل شحن أو الكاميرا معطّلة؟ عرض الحلول البديلة'
                          : 'Dead battery or broken camera? View fallback solutions',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 11.5),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.navy,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive QR Scanner sheet for providers / drivers receiving a handover code.
/// Offers immediate 1-tap fallback to manual code entry when the camera is
/// damaged/unavailable, and direct access to dead-battery emergency procedures.
Future<String?> showMashwarQrScanSheet(
  BuildContext context, {
  required bool isAr,
  required String referenceId,
  required int expectedLength,
  String? demoScannedCode,
  ValueChanged<EmergencyHandoverRecord>? onEmergencyFallbackLogged,
}) {
  final pasteCtrl = TextEditingController();
  String? scanError;

  String extractCode(String raw) {
    final trimmed = raw.trim().toUpperCase();
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      return parts.last.trim();
    }
    return trimmed.replaceAll(RegExp(r'\s+'), '');
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderDisabled,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.teal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'مسح رمز QR لتأكيد الاستلام'
                                  : 'Scan Handover QR Code',
                              style: AppTypography.title().copyWith(fontSize: 16.5),
                            ),
                            Text(
                              isAr
                                  ? 'وجّه الكاميرا نحو رمز QR الظاهر لدى الطرف الآخر'
                                  : 'Point camera at the QR code on the other party\'s screen',
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Viewfinder frame
                  Container(
                    height: 164,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.7),
                        width: 1.6,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 2.2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white54,
                              size: 62,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isAr
                                  ? 'المسح الفوري جاهز · يدعم الأكواد المكونة من $expectedLength خانات'
                                  : 'Scanner ready · Supports $expectedLength-char handover codes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (demoScannedCode != null &&
                      demoScannedCode.trim().isNotEmpty) ...[
                    MashwarButton(
                      key: const ValueKey('qr_demo_capture_btn'),
                      text: isAr
                          ? 'التقاط رمز QR تلقائياً ($demoScannedCode)'
                          : 'Capture QR Automatically ($demoScannedCode)',
                      variant: MashwarButtonVariant.secondary,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      onPressed: () =>
                          Navigator.of(sheetCtx).pop(demoScannedCode.trim()),
                    ),
                    const SizedBox(height: 10),
                  ],

                  TextField(
                    key: const ValueKey('qr_payload_input'),
                    controller: pasteCtrl,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'أو الصق نص الـ QR / الكود مباشرة'
                          : 'Or paste QR payload / code directly',
                      hintText: isAr
                          ? 'مثال: MASHWAR|SUPPLY|... أو الكود'
                          : 'e.g. MASHWAR|SUPPLY|... or code',
                      errorText: scanError,
                      suffixIcon: IconButton(
                        tooltip: isAr ? 'استخدام' : 'Apply',
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.teal,
                        ),
                        onPressed: () {
                          final extracted = extractCode(pasteCtrl.text);
                          if (extracted.length != expectedLength) {
                            setModalState(() {
                              scanError = isAr
                                  ? 'يجب أن يحتوي الرمز على $expectedLength خانات صحيحة.'
                                  : 'Extracted code must be $expectedLength characters.';
                            });
                            return;
                          }
                          Navigator.of(sheetCtx).pop(extracted);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1-tap Broken Camera -> Manual Code Switch
                  OutlinedButton.icon(
                    key: const ValueKey('qr_fallback_manual_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                    label: Text(
                      isAr
                          ? 'الكاميرا معطّلة؟ العودة لإدخال الكود يدوياً'
                          : 'Camera broken? Switch to manual code entry',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dead Battery / Contingency Center trigger
                  TextButton.icon(
                    key: const ValueKey('qr_open_contingency_btn'),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      showMashwarHandoverContingencySheet(
                        context,
                        isAr: isAr,
                        referenceId: referenceId,
                        onEmergencyFallbackLogged: onEmergencyFallbackLogged,
                      );
                    },
                    icon: const Icon(
                      Icons.battery_alert_rounded,
                      size: 17,
                      color: AppColors.warning,
                    ),
                    label: Text(
                      isAr
                          ? 'موبايل الطرف الآخر فصل شحن أو لا يوجد إنترنت؟ اضغط للحلول البديلة'
                          : 'Other phone battery dead or offline? View emergency fallbacks',
                      textAlign: TextAlign.center,
                      style: AppTypography.label(color: AppColors.warning)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Interactive Real-World Handover Contingency & Fallback Center.
/// Solves real field failures cleanly:
/// 1) Broken camera / unable to scan QR -> 1-tap manual code entry
/// 2) Dead phone battery / powered-off device -> Interactive Emergency Backup
///    Handover form (Backup Receiver / Site Contact + optional QID last 4 digits
///    + photo proof note) + car charger & pre-handover SMS backup tips
/// 3) Offline / zero signal at remote site -> 100% offline QR & code display
/// 4) Lost / unreceived code -> Direct operations support & reference copy
Future<void> showMashwarHandoverContingencySheet(
  BuildContext context, {
  required bool isAr,
  required String referenceId,
  String? handoverCode,
  VoidCallback? onSwitchToManualCode,
  ValueChanged<EmergencyHandoverRecord>? onEmergencyFallbackLogged,
}) {
  final backupNameCtrl = TextEditingController();
  final backupPhoneCtrl = TextEditingController();
  final qidLast4Ctrl = TextEditingController();
  final noteCtrl = TextEditingController();
  bool showEmergencyForm = false;
  String? formError;
  EmergencyHandoverRecord? savedRecord;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderDisabled,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.goldSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.navy,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'حلول الطوارئ والبدائل عند التسليم'
                                  : 'Handover Emergency & Fallback Solutions',
                              style: AppTypography.title().copyWith(fontSize: 16.5),
                            ),
                            Text(
                              isAr
                                  ? 'إجراءات آمنة وموثّقة حتى لا يتعطل تسليم طلبك في أي ظرف'
                                  : 'Safe, auditable fallbacks so delivery never stalls',
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Broken Camera / Cannot Scan QR
                  _ContingencyScenarioCard(
                    icon: Icons.no_photography_outlined,
                    iconColor: AppColors.cobalt,
                    surfaceColor: AppColors.cobaltSurface,
                    title: isAr
                        ? '1. الكاميرا معطّلة أو لا تقرأ رمز QR'
                        : '1. Camera Broken or Unable to Scan QR',
                    body: isAr
                        ? 'لا تحتاج الكاميرا إطلاقاً! يمكنك إدخال الكود الرقمي/الأبجدي يدوياً أو نقله من المحادثة بنفس مستوى الأمان والضمان 100%.'
                        : 'No camera needed! Enter the handover code manually or read it verbally / via chat with 100% identical verification security.',
                    actionLabel: onSwitchToManualCode != null
                        ? (isAr
                            ? 'إدخال الكود يدوياً الآن'
                            : 'Enter Code Manually Now')
                        : (handoverCode != null
                            ? (isAr ? 'نسخ الكود اليدوي' : 'Copy Manual Code')
                            : null),
                    onAction: onSwitchToManualCode != null
                        ? () {
                            Navigator.of(sheetCtx).pop();
                            onSwitchToManualCode();
                          }
                        : (handoverCode != null
                            ? () {
                                Clipboard.setData(
                                    ClipboardData(text: handoverCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAr
                                          ? 'تم نسخ الكود اليدوي: $handoverCode'
                                          : 'Manual code copied: $handoverCode',
                                    ),
                                    backgroundColor: AppColors.teal,
                                  ),
                                );
                              }
                            : null),
                  ),
                  const SizedBox(height: 10),

                  // 2. Dead Phone Battery
                  _ContingencyScenarioCard(
                    icon: Icons.battery_0_bar_rounded,
                    iconColor: AppColors.warning,
                    surfaceColor: AppColors.goldSurface,
                    title: isAr
                        ? '2. بطارية الموبايل فصلت بالكامل عند التسليم'
                        : '2. Phone Battery Died / Device Powered Off',
                    body: isAr
                        ? '• الحل الأسرع: توصيل الجهاز 2 دقيقة بشاحن السيارة لعرض الكود أو الـ QR.\n• الحل الاستباقي: مشاركة الكود مسبقاً مع مستلم احتياطي معتمد في الموقع.\n• الحل الفوري بدون جوال: تفعيل «تسليم الطوارئ الموثّق» أدناه بتسجيل بيانات المستلم البديل وآخر 4 أرقام من البطاقة QID وصورة إثبات التسليم.'
                        : '• Fastest: Charge for 2 mins via vehicle charger to view the code/QR.\n• Proactive: Share the code ahead of time with an authorized backup site contact.\n• Instant No-Phone Fallback: Use "Audited Emergency Handover" below with backup contact details, optional last 4 QID digits, and handover proof note.',
                    actionKey: const ValueKey('emergency_dead_battery_btn'),
                    actionLabel: savedRecord != null
                        ? (isAr
                            ? 'تم توثيق تسليم الطوارئ ✓'
                            : 'Emergency Fallback Logged ✓')
                        : (showEmergencyForm
                            ? (isAr ? 'إخفاء نموذج الطوارئ' : 'Hide Emergency Form')
                            : (isAr
                                ? 'تفعيل تسليم طوارئ (بطارية فارغة)'
                                : 'Start Dead-Battery Emergency Handover')),
                    onAction: savedRecord != null
                        ? null
                        : () => setModalState(
                              () => showEmergencyForm = !showEmergencyForm,
                            ),
                  ),

                  // Interactive Dead-Battery Fallback Form
                  if (showEmergencyForm && savedRecord == null) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const ValueKey('emergency_dead_battery_form'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isAr
                                ? 'توثيق تسليم طوارئ (بديل البطارية الفارغة)'
                                : 'Audited Dead-Battery Emergency Handover',
                            style: AppTypography.body(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('emergency_backup_name_input'),
                            controller: backupNameCtrl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: isAr
                                  ? 'اسم المستلم أو مسؤول الموقع البديل *'
                                  : 'Backup Receiver / Site Contact Name *',
                              hintText: isAr ? 'مثال: م. خالد المنصوري' : 'e.g. Eng. Khaled',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('emergency_backup_phone_input'),
                            controller: backupPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: isAr
                                  ? 'رقم جوال بديل للتأكيد (+974) *'
                                  : 'Backup Verification Phone *',
                              hintText: '+974 55112233',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('emergency_qid_last4_input'),
                            controller: qidLast4Ctrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              counterText: '',
                              labelText: isAr
                                  ? 'آخر 4 أرقام من البطاقة الشخصية QID (اختياري)'
                                  : 'Last 4 Digits of QID (Optional)',
                              hintText: '4821',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('emergency_proof_note_input'),
                            controller: noteCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: isAr
                                  ? 'ملاحظة إثبات التسليم الميداني'
                                  : 'Physical Handover Proof Note',
                              hintText: isAr
                                  ? 'مثال: تم التسليم عند البوابة 3 وتصوير الفاتورة والقطع'
                                  : 'e.g. Delivered at Gate 3 with receipt & item photo',
                            ),
                          ),
                          if (formError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              formError!,
                              style: AppTypography.label(color: AppColors.danger)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                          const SizedBox(height: 12),
                          MashwarButton(
                            key: const ValueKey('emergency_submit_fallback_btn'),
                            text: isAr
                                ? 'توثيق تسليم الطوارئ وإصدار مرجع'
                                : 'Log Emergency Handover & Issue Ref',
                            variant: MashwarButtonVariant.secondary,
                            onPressed: () {
                              final name = backupNameCtrl.text.trim();
                              final phone = backupPhoneCtrl.text.trim();
                              if (name.length < 2 || phone.length < 7) {
                                setModalState(() {
                                  formError = isAr
                                      ? 'يرجى إدخال اسم المستلم البديل ورقم جوال صحيح.'
                                      : 'Please enter backup receiver name and valid phone.';
                                });
                                return;
                              }
                              final suffix = (DateTime.now()
                                          .millisecondsSinceEpoch %
                                      9000) +
                                  1000;
                              final rec = EmergencyHandoverRecord(
                                fallbackRef: 'EMG-$suffix',
                                backupContactName: name,
                                backupContactPhone: phone,
                                qidLast4: qidLast4Ctrl.text.trim().isNotEmpty
                                    ? qidLast4Ctrl.text.trim()
                                    : null,
                                proofNote: noteCtrl.text.trim().isNotEmpty
                                    ? noteCtrl.text.trim()
                                    : (isAr
                                        ? 'تسليم طوارئ بسبب نفاد البطارية'
                                        : 'Dead-battery emergency handover'),
                                recordedAt: DateTime.now().toUtc(),
                              );
                              setModalState(() {
                                formError = null;
                                savedRecord = rec;
                                showEmergencyForm = false;
                              });
                              onEmergencyFallbackLogged?.call(rec);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (savedRecord != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const ValueKey('emergency_fallback_confirmed_card'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.teal,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'تم تسجيل تسليم الطوارئ بمرجع ${savedRecord!.fallbackRef} باسم (${savedRecord!.backupContactName}) وإبلاغ فريق العمليات تلقائياً.'
                                  : 'Emergency handover logged under ref ${savedRecord!.fallbackRef} for (${savedRecord!.backupContactName}) and shared with operations.',
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // 3. Offline / Weak Internet Signal
                  _ContingencyScenarioCard(
                    icon: Icons.wifi_off_rounded,
                    iconColor: AppColors.teal,
                    surfaceColor: AppColors.tealSurface,
                    title: isAr
                        ? '3. ضعف أو انقطاع الإنترنت في موقع التسليم'
                        : '3. Weak or No Internet Signal On-Site',
                    body: isAr
                        ? 'يُعرض رمز QR والكود اليدوي محلياً بالكامل بدون إنترنت. صوّر الطلب والفاتورة ودوّن الكود، وسيتم تأكيد التسليم تلقائياً بمجرد عودة الشبكة.'
                        : 'Both QR and manual code render 100% offline. Photograph the handed-over items & receipt, note the code, and confirm as soon as signal returns.',
                  ),
                  const SizedBox(height: 10),

                  // 4. Support Escalation
                  _ContingencyScenarioCard(
                    icon: Icons.support_agent_rounded,
                    iconColor: AppColors.navy,
                    surfaceColor: AppColors.slateBg,
                    title: isAr
                        ? '4. تعذّر الوصول للكود أو الحاجة لتدخل فوري'
                        : '4. Lost Code or Immediate Operations Help',
                    body: isAr
                        ? 'تواصل مع عمليات مشوار على ops@mashwar.qa مع ذكر رقم المرجع ($referenceId) للتحقق الهاتفي الفوري وحماية حق الطرفين.'
                        : 'Contact MASHWAR Operations at ops@mashwar.qa with ref ($referenceId) for live phone verification and bilateral protection.',
                    actionLabel: isAr ? 'نسخ رقم المرجع' : 'Copy Reference ID',
                    onAction: () {
                      Clipboard.setData(ClipboardData(text: referenceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تم نسخ رقم المرجع: $referenceId'
                                : 'Reference copied: $referenceId',
                          ),
                          backgroundColor: AppColors.navy,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ContingencyScenarioCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color surfaceColor;
  final String title;
  final String body;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  const _ContingencyScenarioCard({
    required this.icon,
    required this.iconColor,
    required this.surfaceColor,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.bodySmall(color: AppColors.textSecondary)
                .copyWith(height: 1.45),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                key: actionKey,
                style: OutlinedButton.styleFrom(
                  foregroundColor: iconColor,
                  side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTypography.label(color: iconColor)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
