import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/services/media_upload_service.dart';
import '../../state/auth_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import 'mashwar_animations.dart';

/// Curated vector portrait presets so users (and community demo profiles) can
/// display expressive, sharp avatars without repeating `HomeScreen` photo assets.
class MashwarAvatarPreset {
  final String id;
  final String labelAr;
  final String labelEn;
  final Color bgStart;
  final Color bgEnd;
  final Color coatColor;
  final Color accentColor;
  final Color skinColor;
  final Color hairColor;
  final bool isFemale;
  final bool hasGlasses;

  const MashwarAvatarPreset({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.bgStart,
    required this.bgEnd,
    required this.coatColor,
    required this.accentColor,
    required this.skinColor,
    required this.hairColor,
    this.isFemale = false,
    this.hasGlasses = false,
  });

  String get uri => 'preset:$id';
}

const List<MashwarAvatarPreset> kMashwarAvatarPresets = [
  MashwarAvatarPreset(
    id: 'exec_navy',
    labelAr: 'كلاسيكي كحلي',
    labelEn: 'Classic Navy',
    bgStart: Color(0xFF0F2A43),
    bgEnd: Color(0xFF1E496D),
    coatColor: Color(0xFFF8FAFC),
    accentColor: Color(0xFFF5A524),
    skinColor: Color(0xFFE8B892),
    hairColor: Color(0xFF1E293B),
  ),
  MashwarAvatarPreset(
    id: 'traveler_teal',
    labelAr: 'مسافر فيروزي',
    labelEn: 'Teal Traveler',
    bgStart: Color(0xFF135E59),
    bgEnd: Color(0xFF1B7F79),
    coatColor: Color(0xFF0F2A43),
    accentColor: Color(0xFFF5A524),
    skinColor: Color(0xFFDEAD84),
    hairColor: Color(0xFF27272A),
    hasGlasses: true,
  ),
  MashwarAvatarPreset(
    id: 'lady_pearl',
    labelAr: 'أنيق لؤلؤي',
    labelEn: 'Pearl Elegance',
    bgStart: Color(0xFF1B7F79),
    bgEnd: Color(0xFF2A9D8F),
    coatColor: Color(0xFFFAF7F0),
    accentColor: Color(0xFFF5A524),
    skinColor: Color(0xFFEEC5A4),
    hairColor: Color(0xFF1E293B),
    isFemale: true,
  ),
  MashwarAvatarPreset(
    id: 'engineer_gold',
    labelAr: 'مهندس مشاريع',
    labelEn: 'Site Engineer',
    bgStart: Color(0xFF9A5B00),
    bgEnd: Color(0xFFD98A12),
    coatColor: Color(0xFF0F2A43),
    accentColor: Color(0xFFFAF7F0),
    skinColor: Color(0xFFE2AE86),
    hairColor: Color(0xFF18181B),
  ),
  MashwarAvatarPreset(
    id: 'lady_sand',
    labelAr: 'رملي دافئ',
    labelEn: 'Warm Sand',
    bgStart: Color(0xFF0F2A43),
    bgEnd: Color(0xFF1B7F79),
    coatColor: Color(0xFFFFF8E6),
    accentColor: Color(0xFFF5A524),
    skinColor: Color(0xFFF1C9A8),
    hairColor: Color(0xFF312E81),
    isFemale: true,
  ),
  MashwarAvatarPreset(
    id: 'captain_slate',
    labelAr: 'كابتن الطريق',
    labelEn: 'Route Captain',
    bgStart: Color(0xFF1E293B),
    bgEnd: Color(0xFF334155),
    coatColor: Color(0xFF1B7F79),
    accentColor: Color(0xFFF5A524),
    skinColor: Color(0xFFD8A47F),
    hairColor: Color(0xFF0F172A),
  ),
];

/// Universal MASHWAR profile & community avatar widget.
///
/// Renders in priority order:
/// 1. `data:image/...;base64,...` (`MemoryImage` — uploaded device photo)
/// 2. `preset:<id>` (custom-painted vector portrait)
/// 3. `assets/...` (`AssetImage`)
/// 4. `http://` or `https://` (`NetworkImage` with fallback)
/// 5. Deterministic community vector portrait when [autoCommunityPortrait] is `true`,
///    or clean monogram initial when `false`.
class MashwarUserAvatar extends StatelessWidget {
  static final Map<String, Uint8List> _decodedCache = <String, Uint8List>{};

  final String? avatarUrl;
  final String fullName;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? initialColor;
  final bool showCameraBadge;
  final bool showVerifiedBadge;
  final bool autoCommunityPortrait;
  final VoidCallback? onTap;

  const MashwarUserAvatar({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    this.size = 44,
    this.borderWidth = 2.0,
    this.borderColor,
    this.backgroundColor,
    this.initialColor,
    this.showCameraBadge = false,
    this.showVerifiedBadge = false,
    this.autoCommunityPortrait = false,
    this.onTap,
  });

  bool get hasCustomAvatar =>
      avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  static Uint8List? tryDecodeDataUri(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('data:image/')) return null;
    final cached = _decodedCache[trimmed];
    if (cached != null) return cached;

    final commaIndex = trimmed.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= trimmed.length - 1) return null;
    try {
      final b64 = trimmed.substring(commaIndex + 1);
      final bytes = base64Decode(b64);
      if (bytes.isEmpty) return null;
      if (_decodedCache.length >= 24) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[trimmed] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static MashwarAvatarPreset? resolvePreset(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('preset:')) return null;
    final id = trimmed.substring('preset:'.length).trim();
    for (final preset in kMashwarAvatarPresets) {
      if (preset.id == id) return preset;
    }
    return kMashwarAvatarPresets.first;
  }

  static MashwarAvatarPreset communityPresetForName(String name) {
    final clean = name.trim();
    final isLikelyFemale = clean.startsWith('مريم') ||
        clean.startsWith('نورة') ||
        clean.startsWith('سارة') ||
        clean.startsWith('أم ') ||
        clean.startsWith('فاطمة') ||
        clean.startsWith('دانة') ||
        clean.startsWith('ريم') ||
        clean.startsWith('هند') ||
        clean.startsWith('لطيفة') ||
        clean.startsWith('العنود') ||
        clean.toLowerCase().startsWith('maryam') ||
        clean.toLowerCase().startsWith('noora') ||
        clean.toLowerCase().startsWith('sara');

    final candidates = kMashwarAvatarPresets
        .where((p) => p.isFemale == isLikelyFemale)
        .toList();
    if (candidates.isEmpty) return kMashwarAvatarPresets.first;
    final hash = clean.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);
    return candidates[hash % candidates.length];
  }

  String _initialChar() {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'م';
    if (clean.startsWith('م. ') && clean.length > 3) {
      return clean.substring(3).trim()[0].toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  Widget _buildInnerVisual(double innerSize) {
    final raw = avatarUrl?.trim() ?? '';

    // 1. Uploaded photo (`data:image/...;base64,...`)
    final memoryBytes = tryDecodeDataUri(raw);
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes,
        key: const ValueKey('mashwar_avatar_memory_image'),
        width: innerSize,
        height: innerSize,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallbackVisual(innerSize),
      );
    }

    // 2. Vector portrait preset (`preset:<id>`)
    final preset = resolvePreset(raw);
    if (preset != null) {
      return CustomPaint(
        key: ValueKey('mashwar_avatar_preset_${preset.id}'),
        size: Size.square(innerSize),
        painter: _MashwarPortraitPainter(preset: preset),
      );
    }

    // 3. Bundled asset image (`assets/...`)
    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        width: innerSize,
        height: innerSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackVisual(innerSize),
      );
    }

    // 4. Remote URL (`http://` or `https://`)
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Image.network(
        raw,
        width: innerSize,
        height: innerSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackVisual(innerSize),
      );
    }

    // 5. Fallback (community portrait OR monogram initial)
    return _buildFallbackVisual(innerSize);
  }

  Widget _buildFallbackVisual(double innerSize) {
    if (autoCommunityPortrait) {
      final preset = communityPresetForName(fullName);
      return CustomPaint(
        size: Size.square(innerSize),
        painter: _MashwarPortraitPainter(preset: preset),
      );
    }

    final bg = backgroundColor ?? AppColors.navy;
    final fg = initialColor ?? Colors.white;
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        _initialChar(),
        style: AppTypography.title(color: fg).copyWith(
          fontSize: (innerSize * 0.42).clamp(11.0, 34.0),
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ??
        (hasCustomAvatar
            ? AppColors.gold
            : AppColors.gold.withValues(alpha: 0.75));
    final innerSize = (size - borderWidth * 2).clamp(16.0, 240.0);

    Widget avatarCircle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: effectiveBorderColor, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: _buildInnerVisual(innerSize),
        ),
      ),
    );

    if (showCameraBadge || showVerifiedBadge) {
      final badgeSize = (size * 0.34).clamp(18.0, 28.0);
      avatarCircle = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCircle,
          if (showCameraBadge)
            PositionedDirectional(
              bottom: -1,
              end: -1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: (badgeSize * 0.54).clamp(10.0, 15.0),
                  color: AppColors.gold,
                ),
              ),
            )
          else if (showVerifiedBadge)
            PositionedDirectional(
              bottom: -1,
              end: -1,
              child: Container(
                width: badgeSize * 0.85,
                height: badgeSize * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.14),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: (badgeSize * 0.72).clamp(11.0, 16.0),
                  color: AppColors.teal,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap == null) return avatarCircle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatarCircle,
      ),
    );
  }
}

class _MashwarPortraitPainter extends CustomPainter {
  final MashwarAvatarPreset preset;

  const _MashwarPortraitPainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Rich diagonal gradient backdrop
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [preset.bgStart, preset.bgEnd],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Subtle ambient halo behind head
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.38),
      w * 0.34,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // 2. Hair silhouette (back layer for female portrait)
    final hairPaint = Paint()..color = preset.hairColor;
    if (preset.isFemale) {
      final backHair = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.46),
          width: w * 0.48,
          height: h * 0.48,
        ),
        topLeft: Radius.circular(w * 0.24),
        topRight: Radius.circular(w * 0.24),
        bottomLeft: Radius.circular(w * 0.14),
        bottomRight: Radius.circular(w * 0.14),
      );
      canvas.drawRRect(backHair, hairPaint);
    }

    // 3. Shoulders / jacket silhouette
    final shouldersPath = Path()
      ..moveTo(w * 0.14, h * 1.02)
      ..quadraticBezierTo(w * 0.18, h * 0.68, w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.82, h * 0.68, w * 0.86, h * 1.02)
      ..close();
    canvas.drawPath(shouldersPath, Paint()..color = preset.coatColor);

    // Collar V-accent
    final collarPath = Path()
      ..moveTo(w * 0.39, h * 0.69)
      ..lineTo(w * 0.5, h * 0.83)
      ..lineTo(w * 0.61, h * 0.69)
      ..close();
    canvas.drawPath(collarPath, Paint()..color = preset.accentColor);

    // 4. Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.64),
          width: w * 0.16,
          height: h * 0.14,
        ),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = preset.skinColor,
    );

    // 5. Head
    final headCenter = Offset(w * 0.5, h * 0.43);
    final headRadius = w * 0.195;
    canvas.drawCircle(headCenter, headRadius, Paint()..color = preset.skinColor);

    // 6. Hair crown / headscarf top accent
    final crownPath = Path()
      ..addArc(
        Rect.fromCircle(center: headCenter, radius: headRadius * 1.04),
        3.35,
        2.72,
      );
    canvas.drawPath(crownPath, hairPaint);

    // 7. Friendly minimal facial features (eyes + warm smile)
    final featurePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.435, h * 0.43),
      (w * 0.018).clamp(1.0, 4.0),
      featurePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.565, h * 0.43),
      (w * 0.018).clamp(1.0, 4.0),
      featurePaint,
    );

    if (preset.hasGlasses) {
      final glassesPaint = Paint()
        ..color = preset.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.022).clamp(1.0, 2.4);
      canvas.drawCircle(Offset(w * 0.435, h * 0.43), w * 0.048, glassesPaint);
      canvas.drawCircle(Offset(w * 0.565, h * 0.43), w * 0.048, glassesPaint);
      canvas.drawLine(
        Offset(w * 0.483, h * 0.43),
        Offset(w * 0.517, h * 0.43),
        glassesPaint,
      );
    }

    final smilePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (w * 0.024).clamp(1.0, 2.6);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.475),
        width: w * 0.11,
        height: h * 0.065,
      ),
      0.2,
      2.74,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MashwarPortraitPainter oldDelegate) =>
      oldDelegate.preset.id != preset.id;
}

/// Interactive bottom sheet allowing the user to upload a real photo from their
/// device/camera OR pick a crisp avatar preset, or remove their photo.
Future<String?> showMashwarAvatarPickerSheet(
  BuildContext context, {
  required String? currentAvatarUrl,
  required String fullName,
  ValueChanged<String?>? onAvatarSelected,
}) async {
  final isAr = context.isArabic;
  String? selectedResult;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      String? previewAvatar = currentAvatarUrl;
      bool isPicking = false;
      String? errorMessage;

      Future<void> pickFromDevice(
        StateSetter setSheetState,
        ImageSource source,
      ) async {
        setSheetState(() {
          isPicking = true;
          errorMessage = null;
        });
        try {
          final xfile = await MediaUploadService.instance.pickImage(
            source: source,
            maxWidth: 480,
            imageQuality: 78,
          );
          if (xfile == null) {
            setSheetState(() => isPicking = false);
            return;
          }
          final bytes = await xfile.readAsBytes();
          final mime = MediaUploadService.resolveAndValidateImageMime(
            bytes: bytes,
            fileName: xfile.name,
            explicitMimeType: xfile.mimeType,
          );
          final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
          selectedResult = dataUri;
          onAvatarSelected?.call(dataUri);
          if (sheetCtx.mounted) {
            Navigator.of(sheetCtx).pop();
          }
        } on MediaUploadException catch (e) {
          setSheetState(() {
            isPicking = false;
            errorMessage = e.localizedMessage(isArabic: isAr);
          });
        } catch (_) {
          setSheetState(() {
            isPicking = false;
            errorMessage = isAr
                ? 'تعذّر قراءة الصورة المختارة. يرجى اختيار صورة بصيغة JPG أو PNG.'
                : 'Could not read selected image. Please choose a JPG or PNG photo.';
          });
        }
      }

      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppDimens.radiusBottomSheet),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MashwarSheetHeader(
                          title: isAr
                              ? 'تحديث صورة الملف الشخصي'
                              : 'Update Profile Photo',
                          subtitle: isAr
                              ? 'تظهر صورتك في الصفحة الرئيسية وحسابك والرحلات بدلاً من الحرف الأول'
                              : 'Your photo appears on the Home header, Account, and trips instead of an initial',
                          onClose: () => Navigator.of(sheetCtx).pop(),
                        ),
                        const SizedBox(height: 18),

                        // Live Preview Avatar
                        Center(
                          child: MashwarUserAvatar(
                            avatarUrl: previewAvatar,
                            fullName: fullName,
                            size: 92,
                            borderWidth: 3.0,
                            borderColor: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTypography.label(color: AppColors.danger)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Upload from Device Gallery (Primary)
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            key: const ValueKey('avatar_pick_gallery_btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isPicking
                                ? null
                                : () => pickFromDevice(
                                      setSheetState,
                                      ImageSource.gallery,
                                    ),
                            icon: isPicking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.gold,
                                    ),
                                  )
                                : const Icon(
                                    Icons.photo_library_rounded,
                                    color: AppColors.gold,
                                    size: 20,
                                  ),
                            label: Text(
                              isAr
                                  ? 'رفع صورة شخصية من الجهاز'
                                  : 'Upload Photo from Device',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Camera Capture Option
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            key: const ValueKey('avatar_pick_camera_btn'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              backgroundColor: AppColors.sand,
                              side: BorderSide(
                                color: AppColors.gold.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isPicking
                                ? null
                                : () => pickFromDevice(
                                      setSheetState,
                                      ImageSource.camera,
                                    ),
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            label: Text(
                              isAr
                                  ? 'التقاط صورة بالكاميرا'
                                  : 'Take Photo with Camera',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          isAr
                              ? 'أو اختر أفاتار احترافي سريع:'
                              : 'Or choose a quick illustrated avatar:',
                          style: AppTypography.label(
                            color: AppColors.textSecondary,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: kMashwarAvatarPresets.map((preset) {
                            final isSelected = previewAvatar == preset.uri;
                            return InkWell(
                              key: ValueKey('avatar_preset_${preset.id}'),
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setSheetState(() => previewAvatar = preset.uri);
                                selectedResult = preset.uri;
                                onAvatarSelected?.call(preset.uri);
                                Navigator.of(sheetCtx).pop();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 78,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.tealSurface
                                      : AppColors.slateBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.teal
                                        : AppColors.slateBorder,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MashwarUserAvatar(
                                      avatarUrl: preset.uri,
                                      fullName: fullName,
                                      size: 46,
                                      borderWidth: 1.5,
                                      borderColor: isSelected
                                          ? AppColors.teal
                                          : AppColors.gold,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      isAr ? preset.labelAr : preset.labelEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.label(
                                        color: AppColors.navy,
                                      ).copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        if (currentAvatarUrl != null &&
                            currentAvatarUrl.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          TextButton.icon(
                            key: const ValueKey('avatar_remove_btn'),
                            onPressed: () {
                              selectedResult = '';
                              onAvatarSelected?.call(null);
                              Navigator.of(sheetCtx).pop();
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            label: Text(
                              isAr
                                  ? 'إزالة الصورة والعودة للحرف الأول'
                                  : 'Remove photo & use initial',
                              style: AppTypography.label(color: AppColors.danger)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  return selectedResult;
}

/// Convenience helper that opens the picker sheet and saves the chosen photo
/// directly into [AuthProvider] with visual toast confirmation.
Future<void> pickAndSaveCurrentUserAvatar(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final isAr = context.isArabic;
  await showMashwarAvatarPickerSheet(
    context,
    currentAvatarUrl: auth.user.avatarUrl,
    fullName: auth.user.fullName,
    onAvatarSelected: (newAvatar) async {
      await auth.updateAvatar(newAvatar);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newAvatar == null
                ? (isAr
                    ? 'تمت إزالة الصورة الشخصية'
                    : 'Profile photo removed')
                : (isAr
                    ? 'تم تحديث صورتك الشخصية بنجاح في كل التطبيق'
                    : 'Profile photo updated across MASHWAR'),
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
  );
}
