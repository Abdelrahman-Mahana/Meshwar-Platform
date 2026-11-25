import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Visual presentation mode for worksite supply category banners.
enum MashwarCategoryVisualType {
  photography,
  vectorDiorama,
}

/// Metadata describing each Qatar Worksite Supply category for consistent
/// bilingual titles, semantic color tokens, vector icons, and banner visuals.
@immutable
class MashwarCategoryMeta {
  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final Color accentColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final MashwarCategoryVisualType visualType;
  final String? imageAssetPath;

  const MashwarCategoryMeta({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.accentColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.visualType,
    this.imageAssetPath,
  });

  String title({required bool isArabic}) => isArabic ? titleAr : titleEn;

  String subtitle({required bool isArabic}) =>
      isArabic ? subtitleAr : subtitleEn;
}

const MashwarCategoryMeta _electricalMeta = MashwarCategoryMeta(
  id: 'electrical',
  titleAr: 'كهرباء وكابلات',
  titleEn: 'Electrical & Cables',
  subtitleAr: 'قواطع ولوحات توزيع وكابلات وإنارة مواقع',
  subtitleEn: 'Breakers, distribution panels, copper cables & LED lighting',
  accentColor: AppColors.warning,
  secondaryColor: AppColors.gold,
  surfaceColor: AppColors.goldSurface,
  visualType: MashwarCategoryVisualType.vectorDiorama,
);

const MashwarCategoryMeta _plumbingMeta = MashwarCategoryMeta(
  id: 'plumbing',
  titleAr: 'سباكة ومواسير',
  titleEn: 'Plumbing & Pipes',
  subtitleAr: 'مواسير PPR ومحابس نحاس ومضخات ضغط',
  subtitleEn: 'PPR pipes, brass manifolds, check valves & booster pumps',
  accentColor: AppColors.info,
  secondaryColor: AppColors.teal,
  surfaceColor: AppColors.infoBg,
  visualType: MashwarCategoryVisualType.vectorDiorama,
);

const MashwarCategoryMeta _hardwareMeta = MashwarCategoryMeta(
  id: 'hardware',
  titleAr: 'عدد ومسامير',
  titleEn: 'Hardware & Fasteners',
  subtitleAr: 'براغي ومرابط فولاذية وأقفال ومفاتيح عزم',
  subtitleEn: 'Anchor bolts, fasteners, heavy padlocks & torque wrenches',
  accentColor: AppColors.navy,
  secondaryColor: Color(0xFF475569),
  surfaceColor: AppColors.slateBg,
  visualType: MashwarCategoryVisualType.photography,
  imageAssetPath: 'assets/images/cat_tools_ppe.jpg',
);

const MashwarCategoryMeta _safetyPpeMeta = MashwarCategoryMeta(
  id: 'safety_ppe',
  titleAr: 'سلامة مهنية PPE',
  titleEn: 'Safety & PPE',
  subtitleAr: 'خوذات سلامة وسترات عاكسة وطفايات معتمدة',
  subtitleEn: 'HSE helmets, reflective vests & fire safety equipment',
  accentColor: AppColors.qatarMaroon,
  secondaryColor: AppColors.gold,
  surfaceColor: AppColors.qatarMaroonSurface,
  visualType: MashwarCategoryVisualType.photography,
  imageAssetPath: 'assets/images/cat_tools_ppe.jpg',
);

const MashwarCategoryMeta _toolsMeta = MashwarCategoryMeta(
  id: 'tools',
  titleAr: 'معدات وأدوات',
  titleEn: 'Power & Hand Tools',
  subtitleAr: 'مثاقيب وأجهزة قياس ليزرية ومعدات موقع',
  subtitleEn: 'Cordless drills, laser levels & site power tools',
  accentColor: AppColors.teal,
  secondaryColor: AppColors.navy,
  surfaceColor: AppColors.tealSurface,
  visualType: MashwarCategoryVisualType.photography,
  imageAssetPath: 'assets/images/cat_tools_ppe.jpg',
);

const MashwarCategoryMeta _civilMaterialsMeta = MashwarCategoryMeta(
  id: 'civil_materials',
  titleAr: 'مواد بناء وتشطيب',
  titleEn: 'Civil & Finishing',
  subtitleAr: 'أسمنت مقاوم وعوازل مائية ومواد إنشائية',
  subtitleEn: 'Cement, bitumen waterproofing, adhesives & structural blocks',
  accentColor: Color(0xFF8C5319),
  secondaryColor: AppColors.navy,
  surfaceColor: AppColors.sand,
  visualType: MashwarCategoryVisualType.photography,
  imageAssetPath: 'assets/images/service_site_supply.jpg',
);

const MashwarCategoryMeta _generalSiteSupplyMeta = MashwarCategoryMeta(
  id: 'general_site_supply',
  titleAr: 'توريد موقع عام',
  titleEn: 'General Site Supply',
  subtitleAr: 'مستلزمات التشغيل اليومية وتجهيزات المواقع',
  subtitleEn: 'Daily site consumables, packaging & general logistics supply',
  accentColor: AppColors.escrowGreen,
  secondaryColor: AppColors.navy,
  surfaceColor: AppColors.escrowSurface,
  visualType: MashwarCategoryVisualType.photography,
  imageAssetPath: 'assets/images/mvp_hero_lusail_supply.jpg',
);

/// Canonical ordered catalog of all 7 Qatar Worksite Supply categories.
const List<MashwarCategoryMeta> mashwarWorksiteCategories = [
  _generalSiteSupplyMeta,
  _electricalMeta,
  _plumbingMeta,
  _hardwareMeta,
  _safetyPpeMeta,
  _toolsMeta,
  _civilMaterialsMeta,
];

/// Resolves [MashwarCategoryMeta] for any of the 7 canonical categories with
/// graceful fallback to `general_site_supply`.
MashwarCategoryMeta mashwarCategoryMetaFor(String category) {
  switch (category.trim().toLowerCase()) {
    case 'electrical':
      return _electricalMeta;
    case 'plumbing':
      return _plumbingMeta;
    case 'hardware':
      return _hardwareMeta;
    case 'safety_ppe':
    case 'safety':
      return _safetyPpeMeta;
    case 'tools':
      return _toolsMeta;
    case 'civil_materials':
    case 'civil':
      return _civilMaterialsMeta;
    case 'general_site_supply':
    case 'general':
    case 'worksite_supply':
    default:
      return _generalSiteSupplyMeta;
  }
}

/// Crisp custom vector duotone icon for each of the 7 worksite supply categories.
class MashwarCategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final bool showSurface;

  const MashwarCategoryIcon({
    super.key,
    required this.category,
    this.size = 36,
    this.showSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final meta = mashwarCategoryMetaFor(category);
    final iconSize = showSurface ? size * 0.62 : size;
    final paint = SizedBox.square(
      dimension: iconSize,
      child: CustomPaint(
        painter: _MashwarCategoryIconPainter(
          categoryId: meta.id,
          accent: meta.accentColor,
          secondary: meta.secondaryColor,
        ),
      ),
    );

    if (!showSurface) {
      return Semantics(
        label: meta.titleEn,
        child: paint,
      );
    }

    return Semantics(
      label: meta.titleEn,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: meta.surfaceColor,
          borderRadius: BorderRadius.circular((size * 0.28).clamp(6.0, 14.0)),
          border: Border.all(
            color: meta.accentColor.withValues(alpha: 0.24),
            width: 1.0,
          ),
        ),
        child: Center(child: paint),
      ),
    );
  }
}

class _MashwarCategoryIconPainter extends CustomPainter {
  final String categoryId;
  final Color accent;
  final Color secondary;

  const _MashwarCategoryIconPainter({
    required this.categoryId,
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    if (s <= 0) return;

    switch (categoryId) {
      case 'electrical':
        _paintElectrical(canvas, s);
        break;
      case 'plumbing':
        _paintPlumbing(canvas, s);
        break;
      case 'hardware':
        _paintHardware(canvas, s);
        break;
      case 'safety_ppe':
        _paintSafetyPpe(canvas, s);
        break;
      case 'tools':
        _paintTools(canvas, s);
        break;
      case 'civil_materials':
        _paintCivilMaterials(canvas, s);
        break;
      case 'general_site_supply':
      default:
        _paintGeneralSupply(canvas, s);
        break;
    }
  }

  void _paintElectrical(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.08).clamp(1.2, 2.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Breaker enclosure housing
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.14, s * 0.12, s * 0.56, s * 0.76),
      Radius.circular(s * 0.10),
    );
    canvas.drawRRect(box, Paint()..color = AppColors.navy.withValues(alpha: 0.12));
    canvas.drawRRect(box, stroke);

    // DIN rail switch toggle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.25, s * 0.28, s * 0.26, s * 0.16),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = accent,
    );
    canvas.drawLine(
      Offset(s * 0.24, s * 0.62),
      Offset(s * 0.44, s * 0.62),
      stroke,
    );

    // High-voltage lightning bolt overlapping front-right
    final bolt = Path()
      ..moveTo(s * 0.70, s * 0.24)
      ..lineTo(s * 0.52, s * 0.54)
      ..lineTo(s * 0.67, s * 0.54)
      ..lineTo(s * 0.57, s * 0.88)
      ..lineTo(s * 0.88, s * 0.46)
      ..lineTo(s * 0.71, s * 0.46)
      ..close();
    canvas.drawPath(bolt, Paint()..color = secondary);
    canvas.drawPath(
      bolt,
      Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.06).clamp(1.0, 2.0)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintPlumbing(Canvas canvas, double s) {
    final pipeFill = Paint()..color = accent.withValues(alpha: 0.18);
    final pipeStroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.085).clamp(1.3, 3.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Horizontal manifold body
    final hPipe = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.14, s * 0.50, s * 0.72, s * 0.22),
      Radius.circular(s * 0.05),
    );
    canvas.drawRRect(hPipe, pipeFill);
    canvas.drawRRect(hPipe, pipeStroke);

    // End flange collars
    canvas.drawLine(Offset(s * 0.12, s * 0.44), Offset(s * 0.12, s * 0.78), pipeStroke);
    canvas.drawLine(Offset(s * 0.88, s * 0.44), Offset(s * 0.88, s * 0.78), pipeStroke);

    // Vertical valve stem & brass shutoff handle
    canvas.drawRect(
      Rect.fromLTWH(s * 0.42, s * 0.30, s * 0.16, s * 0.20),
      Paint()..color = secondary.withValues(alpha: 0.25),
    );
    canvas.drawRect(
      Rect.fromLTWH(s * 0.42, s * 0.30, s * 0.16, s * 0.20),
      pipeStroke,
    );

    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.26, s * 0.16, s * 0.48, s * 0.12),
      Radius.circular(s * 0.06),
    );
    canvas.drawRRect(handle, Paint()..color = AppColors.gold);
    canvas.drawRRect(
      handle,
      Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.06).clamp(1.0, 2.0),
    );
  }

  void _paintHardware(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.08).clamp(1.2, 2.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hex bolt head + threaded shaft (left)
    final hex = Path();
    final cx = s * 0.32;
    final cy = s * 0.28;
    final r = s * 0.17;
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - (math.pi / 6);
      final pt = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      if (i == 0) {
        hex.moveTo(pt.dx, pt.dy);
      } else {
        hex.lineTo(pt.dx, pt.dy);
      }
    }
    hex.close();
    canvas.drawPath(hex, Paint()..color = AppColors.gold.withValues(alpha: 0.35));
    canvas.drawPath(hex, stroke);

    final shaft = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.23, s * 0.44, s * 0.18, s * 0.42),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(shaft, Paint()..color = accent.withValues(alpha: 0.14));
    canvas.drawRRect(shaft, stroke);
    for (final y in [0.56, 0.67, 0.78]) {
      canvas.drawLine(Offset(s * 0.24, s * y), Offset(s * 0.40, s * y), stroke);
    }

    // Open-end wrench (right)
    final wrench = Path()
      ..moveTo(s * 0.68, s * 0.16)
      ..arcToPoint(
        Offset(s * 0.84, s * 0.30),
        radius: Radius.circular(s * 0.14),
        clockwise: false,
      )
      ..lineTo(s * 0.82, s * 0.44)
      ..lineTo(s * 0.74, s * 0.50)
      ..lineTo(s * 0.74, s * 0.82)
      ..arcToPoint(
        Offset(s * 0.60, s * 0.82),
        radius: Radius.circular(s * 0.07),
      )
      ..lineTo(s * 0.60, s * 0.50)
      ..lineTo(s * 0.53, s * 0.42)
      ..close();
    canvas.drawPath(wrench, Paint()..color = secondary.withValues(alpha: 0.22));
    canvas.drawPath(wrench, stroke);
  }

  void _paintSafetyPpe(Canvas canvas, double s) {
    // Hard hat dome
    final hatDome = Path()
      ..moveTo(s * 0.16, s * 0.56)
      ..cubicTo(s * 0.16, s * 0.22, s * 0.72, s * 0.22, s * 0.72, s * 0.56)
      ..close();
    canvas.drawPath(hatDome, Paint()..color = AppColors.gold.withValues(alpha: 0.35));
    canvas.drawPath(
      hatDome,
      Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.075).clamp(1.2, 2.6)
        ..strokeJoin = StrokeJoin.round,
    );

    // Center helmet crest rib
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.39, s * 0.20, s * 0.10, s * 0.26),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = accent,
    );

    // Brim
    canvas.drawLine(
      Offset(s * 0.10, s * 0.56),
      Offset(s * 0.78, s * 0.56),
      Paint()
        ..color = AppColors.navy
        ..strokeWidth = (s * 0.085).clamp(1.4, 3.0)
        ..strokeCap = StrokeCap.round,
    );

    // Qatar Maroon safety shield crest on bottom-right
    final shield = Path()
      ..moveTo(s * 0.58, s * 0.48)
      ..lineTo(s * 0.88, s * 0.54)
      ..lineTo(s * 0.88, s * 0.68)
      ..cubicTo(s * 0.88, s * 0.80, s * 0.73, s * 0.89, s * 0.73, s * 0.89)
      ..cubicTo(s * 0.73, s * 0.89, s * 0.58, s * 0.80, s * 0.58, s * 0.68)
      ..close();
    canvas.drawPath(shield, Paint()..color = accent);
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.05).clamp(1.0, 1.8),
    );
    final check = Path()
      ..moveTo(s * 0.66, s * 0.69)
      ..lineTo(s * 0.71, s * 0.75)
      ..lineTo(s * 0.81, s * 0.63);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.065).clamp(1.1, 2.2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintTools(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.075).clamp(1.2, 2.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Drill body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.16, s * 0.24, s * 0.44, s * 0.20),
      Radius.circular(s * 0.06),
    );
    canvas.drawRRect(body, Paint()..color = accent.withValues(alpha: 0.24));
    canvas.drawRRect(body, stroke);

    // Drill chuck & bit
    canvas.drawRect(
      Rect.fromLTWH(s * 0.60, s * 0.28, s * 0.11, s * 0.12),
      Paint()..color = AppColors.navy,
    );
    canvas.drawLine(
      Offset(s * 0.71, s * 0.34),
      Offset(s * 0.84, s * 0.34),
      stroke,
    );

    // Grip & battery pack
    final grip = Path()
      ..moveTo(s * 0.28, s * 0.44)
      ..lineTo(s * 0.22, s * 0.74)
      ..lineTo(s * 0.36, s * 0.74)
      ..lineTo(s * 0.42, s * 0.44)
      ..close();
    canvas.drawPath(grip, Paint()..color = accent.withValues(alpha: 0.24));
    canvas.drawPath(grip, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.16, s * 0.74, s * 0.26, s * 0.12),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = AppColors.navy,
    );

    // Laser beam & target crosshair
    canvas.drawLine(
      Offset(s * 0.58, s * 0.68),
      Offset(s * 0.84, s * 0.68),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = (s * 0.065).clamp(1.2, 2.2)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(s * 0.82, s * 0.68),
      s * 0.09,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.06).clamp(1.0, 2.0),
    );
  }

  void _paintCivilMaterials(Canvas canvas, double s) {
    final blockFill = Paint()..color = accent.withValues(alpha: 0.2);
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.075).clamp(1.2, 2.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Masonry blocks
    final b1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.56, s * 0.34, s * 0.24),
      Radius.circular(s * 0.03),
    );
    final b2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.50, s * 0.56, s * 0.34, s * 0.24),
      Radius.circular(s * 0.03),
    );
    final b3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.31, s * 0.28, s * 0.34, s * 0.24),
      Radius.circular(s * 0.03),
    );
    for (final b in [b1, b2, b3]) {
      canvas.drawRRect(b, blockFill);
      canvas.drawRRect(b, stroke);
    }

    // Pointing trowel on top-right
    final trowel = Path()
      ..moveTo(s * 0.56, s * 0.38)
      ..lineTo(s * 0.82, s * 0.14)
      ..lineTo(s * 0.86, s * 0.40)
      ..close();
    canvas.drawPath(trowel, Paint()..color = AppColors.gold);
    canvas.drawPath(trowel, stroke);
  }

  void _paintGeneralSupply(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.075).clamp(1.2, 2.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sealed site supply crate
    final crate = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.14, s * 0.28, s * 0.58, s * 0.56),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(crate, Paint()..color = accent.withValues(alpha: 0.16));
    canvas.drawRRect(crate, stroke);
    canvas.drawLine(Offset(s * 0.14, s * 0.44), Offset(s * 0.72, s * 0.44), stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.35, s * 0.28, s * 0.16, s * 0.28),
        Radius.circular(s * 0.03),
      ),
      Paint()..color = AppColors.gold.withValues(alpha: 0.7),
    );

    // Location pin badge on top-right
    final pin = Path()
      ..moveTo(s * 0.74, s * 0.54)
      ..cubicTo(s * 0.60, s * 0.40, s * 0.58, s * 0.24, s * 0.65, s * 0.17)
      ..arcToPoint(
        Offset(s * 0.83, s * 0.17),
        radius: Radius.circular(s * 0.12),
      )
      ..cubicTo(s * 0.90, s * 0.24, s * 0.88, s * 0.40, s * 0.74, s * 0.54)
      ..close();
    canvas.drawPath(pin, Paint()..color = accent);
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.05).clamp(1.0, 1.8),
    );
    canvas.drawCircle(
      Offset(s * 0.74, s * 0.28),
      s * 0.05,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MashwarCategoryIconPainter oldDelegate) {
    return oldDelegate.categoryId != categoryId ||
        oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary;
  }
}

/// High-impact category visual banner blending real Qatar worksite photography
/// (with graceful vector fallback) and multi-layered CustomPainter dioramas
/// for `electrical` and `plumbing`.
class MashwarCategoryVisualBanner extends StatelessWidget {
  final String category;
  final double height;
  final double borderRadius;

  const MashwarCategoryVisualBanner({
    super.key,
    required this.category,
    this.height = 88,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final meta = mashwarCategoryMetaFor(category);
    final radius = BorderRadius.circular(borderRadius);

    return Semantics(
      label: meta.titleEn,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (meta.visualType == MashwarCategoryVisualType.photography &&
                  meta.imageAssetPath != null)
                Image.asset(
                  meta.imageAssetPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _BannerDioramaFallback(meta: meta),
                )
              else
                CustomPaint(
                  painter: _CategoryDioramaPainter(meta: meta),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      AppColors.navy.withValues(alpha: 0.45),
                      Colors.transparent,
                      meta.accentColor.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                start: 10,
                child: MashwarCategoryIcon(
                  category: meta.id,
                  size: (height * 0.42).clamp(28.0, 42.0),
                  showSurface: true,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        meta.accentColor,
                        meta.secondaryColor,
                        AppColors.gold,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerDioramaFallback extends StatelessWidget {
  final MashwarCategoryMeta meta;

  const _BannerDioramaFallback({required this.meta});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CategoryDioramaPainter(meta: meta),
    );
  }
}

class _CategoryDioramaPainter extends CustomPainter {
  final MashwarCategoryMeta meta;

  const _CategoryDioramaPainter({required this.meta});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    if (meta.id == 'electrical') {
      _paintElectricalDiorama(canvas, w, h);
    } else if (meta.id == 'plumbing') {
      _paintPlumbingDiorama(canvas, w, h);
    } else {
      _paintGenericTechDiorama(canvas, w, h);
    }
  }

  void _paintBlueprintGrid(Canvas canvas, double w, double h, Color tint) {
    final gridPaint = Paint()
      ..color = tint.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;
    const step = 18.0;
    for (double x = 0; x <= w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  void _paintElectricalDiorama(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1D30), Color(0xFF133654), Color(0xFF1E4466)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    _paintBlueprintGrid(canvas, w, h, Colors.white);

    // Industrial breaker panel (left-center)
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.14, w * 0.24, h * 0.72),
      const Radius.circular(8),
    );
    canvas.drawRRect(panelRect, Paint()..color = const Color(0xFF1F3B57));
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3 DIN-rail switches + LED indicators inside panel
    for (var i = 0; i < 3; i++) {
      final y = h * (0.24 + i * 0.19);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.27, y, w * 0.14, h * 0.11),
          const Radius.circular(3),
        ),
        Paint()..color = AppColors.navy,
      );
      canvas.drawCircle(
        Offset(w * 0.435, y + h * 0.055),
        2.8,
        Paint()..color = i == 1 ? AppColors.gold : AppColors.teal,
      );
    }

    // Armored copper coil loops (center-right)
    final copperCenter = Offset(w * 0.62, h * 0.56);
    for (final rMul in [0.27, 0.21, 0.15]) {
      canvas.drawCircle(
        copperCenter,
        h * rMul,
        Paint()
          ..color = const Color(0xFFD97706)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }
    canvas.drawCircle(
      copperCenter,
      h * 0.23,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // LED floodlight beam arc from top-right
    final beamOrigin = Offset(w * 0.90, h * 0.16);
    final beam = Path()
      ..moveTo(beamOrigin.dx, beamOrigin.dy)
      ..lineTo(w * 0.68, h * 0.88)
      ..lineTo(w * 0.96, h * 0.88)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, -0.7),
          radius: 1.0,
          colors: [
            AppColors.gold.withValues(alpha: 0.45),
            AppColors.gold.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTWH(w * 0.62, 0, w * 0.38, h)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: beamOrigin, width: 18, height: 10),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.gold,
    );
  }

  void _paintPlumbingDiorama(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C273B), Color(0xFF14425B), Color(0xFF175E6E)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    _paintBlueprintGrid(canvas, w, h, Colors.white);

    // PPR green/teal pipes running horizontally & vertically
    final pprPaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pprPath = Path()
      ..moveTo(w * 0.18, h * 0.34)
      ..lineTo(w * 0.44, h * 0.34)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.88, h * 0.68);
    canvas.drawPath(pprPath, pprPaint);
    canvas.drawPath(
      pprPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Brass manifold block with 3 vertical ports & quarter-turn valves
    final manifold = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.48, h * 0.50, w * 0.26, h * 0.14),
      const Radius.circular(4),
    );
    canvas.drawRRect(manifold, Paint()..color = AppColors.gold);
    for (var i = 0; i < 3; i++) {
      final vx = w * (0.53 + i * 0.08);
      canvas.drawLine(
        Offset(vx, h * 0.50),
        Offset(vx, h * 0.32),
        Paint()
          ..color = const Color(0xFFE2B04A)
          ..strokeWidth = 3.2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(vx, h * 0.29), width: 12, height: 5),
          const Radius.circular(2.5),
        ),
        Paint()..color = i == 1 ? AppColors.qatarMaroon : AppColors.teal,
      );
    }

    // Pressure gauge dial (right)
    final gaugeCenter = Offset(w * 0.84, h * 0.38);
    final gaugeR = (h * 0.22).clamp(14.0, 24.0);
    canvas.drawCircle(gaugeCenter, gaugeR, Paint()..color = Colors.white);
    canvas.drawCircle(
      gaugeCenter,
      gaugeR,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: gaugeR * 0.72),
      math.pi * 0.85,
      math.pi * 1.1,
      false,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      gaugeCenter,
      Offset(gaugeCenter.dx + gaugeR * 0.52, gaugeCenter.dy - gaugeR * 0.38),
      Paint()
        ..color = AppColors.qatarMaroon
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(gaugeCenter, 2.4, Paint()..color = AppColors.navy);
  }

  void _paintGenericTechDiorama(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy,
            Color.lerp(AppColors.navy, meta.accentColor, 0.45)!,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    _paintBlueprintGrid(canvas, w, h, Colors.white);
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.48),
      h * 0.36,
      Paint()..color = meta.secondaryColor.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _CategoryDioramaPainter oldDelegate) =>
      oldDelegate.meta.id != meta.id;
}

/// Trust & security emblem types for Qatar Worksite Supply MVP.
enum MashwarTrustType {
  handoverShield,
  verifiedReceipt,
  qatarIdCrest,
  liveCorridor,
}

/// Crisp custom vector emblem for handover security, verified invoices,
/// Qatar QID approval, and active Qatar supply corridors.
class MashwarTrustEmblem extends StatelessWidget {
  final MashwarTrustType type;
  final double size;

  const MashwarTrustEmblem({
    super.key,
    required this.type,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MashwarTrustEmblemPainter(type: type),
      ),
    );
  }
}

class _MashwarTrustEmblemPainter extends CustomPainter {
  final MashwarTrustType type;

  const _MashwarTrustEmblemPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    if (s <= 0) return;

    switch (type) {
      case MashwarTrustType.handoverShield:
        _paintHandoverShield(canvas, s);
        break;
      case MashwarTrustType.verifiedReceipt:
        _paintVerifiedReceipt(canvas, s);
        break;
      case MashwarTrustType.qatarIdCrest:
        _paintQatarIdCrest(canvas, s);
        break;
      case MashwarTrustType.liveCorridor:
        _paintLiveCorridor(canvas, s);
        break;
    }
  }

  void _paintHandoverShield(Canvas canvas, double s) {
    final shield = Path()
      ..moveTo(s * 0.50, s * 0.08)
      ..lineTo(s * 0.86, s * 0.22)
      ..lineTo(s * 0.86, s * 0.50)
      ..cubicTo(s * 0.86, s * 0.74, s * 0.50, s * 0.92, s * 0.50, s * 0.92)
      ..cubicTo(s * 0.50, s * 0.92, s * 0.14, s * 0.74, s * 0.14, s * 0.50)
      ..lineTo(s * 0.14, s * 0.22)
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.escrowSurface);
    canvas.drawPath(
      shield,
      Paint()
        ..color = AppColors.escrowGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.065).clamp(1.2, 2.8)
        ..strokeJoin = StrokeJoin.round,
    );

    // Inner gold badge + checkmark
    canvas.drawCircle(
      Offset(s * 0.50, s * 0.48),
      s * 0.19,
      Paint()..color = AppColors.escrowGreen,
    );
    final check = Path()
      ..moveTo(s * 0.40, s * 0.48)
      ..lineTo(s * 0.47, s * 0.56)
      ..lineTo(s * 0.61, s * 0.41);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.065).clamp(1.2, 2.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // 6-char handover dots along bottom crest
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(s * (0.40 + i * 0.10), s * 0.74),
        s * 0.025,
        Paint()..color = AppColors.gold,
      );
    }
  }

  void _paintVerifiedReceipt(Canvas canvas, double s) {
    final doc = Path()
      ..moveTo(s * 0.20, s * 0.12)
      ..lineTo(s * 0.72, s * 0.12)
      ..lineTo(s * 0.72, s * 0.86)
      ..lineTo(s * 0.61, s * 0.79)
      ..lineTo(s * 0.50, s * 0.86)
      ..lineTo(s * 0.39, s * 0.79)
      ..lineTo(s * 0.28, s * 0.86)
      ..lineTo(s * 0.20, s * 0.80)
      ..close();
    canvas.drawPath(doc, Paint()..color = Colors.white);
    canvas.drawPath(
      doc,
      Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.055).clamp(1.2, 2.4)
        ..strokeJoin = StrokeJoin.round,
    );

    final linePaint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.4)
      ..strokeWidth = (s * 0.055).clamp(1.1, 2.2)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.30, s * 0.30), Offset(s * 0.60, s * 0.30), linePaint);
    canvas.drawLine(Offset(s * 0.30, s * 0.44), Offset(s * 0.56, s * 0.44), linePaint);
    canvas.drawLine(Offset(s * 0.30, s * 0.58), Offset(s * 0.48, s * 0.58), linePaint);

    // Verified teal stamp circle on bottom-right
    final stampCenter = Offset(s * 0.72, s * 0.66);
    canvas.drawCircle(stampCenter, s * 0.18, Paint()..color = AppColors.teal);
    canvas.drawCircle(
      stampCenter,
      s * 0.18,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.045).clamp(1.0, 1.8),
    );
    final check = Path()
      ..moveTo(s * 0.64, s * 0.66)
      ..lineTo(s * 0.70, s * 0.72)
      ..lineTo(s * 0.80, s * 0.60);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.055).clamp(1.1, 2.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintQatarIdCrest(Canvas canvas, double s) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.10, s * 0.20, s * 0.80, s * 0.60),
      Radius.circular(s * 0.10),
    );
    canvas.drawRRect(card, Paint()..color = AppColors.qatarMaroonSurface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = AppColors.qatarMaroon
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.06).clamp(1.2, 2.5),
    );

    // Qatari serrated Al-Adaam accent strip on left
    final strip = Path()
      ..moveTo(s * 0.10, s * 0.22)
      ..lineTo(s * 0.26, s * 0.22)
      ..lineTo(s * 0.32, s * 0.30)
      ..lineTo(s * 0.26, s * 0.38)
      ..lineTo(s * 0.32, s * 0.46)
      ..lineTo(s * 0.26, s * 0.54)
      ..lineTo(s * 0.32, s * 0.62)
      ..lineTo(s * 0.26, s * 0.70)
      ..lineTo(s * 0.32, s * 0.78)
      ..lineTo(s * 0.10, s * 0.78)
      ..close();
    canvas.drawPath(strip, Paint()..color = AppColors.qatarMaroon);

    // Gold biometric chip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.40, s * 0.34, s * 0.18, s * 0.14),
        Radius.circular(s * 0.03),
      ),
      Paint()..color = AppColors.gold,
    );

    // Verified lines + seal
    canvas.drawLine(
      Offset(s * 0.40, s * 0.60),
      Offset(s * 0.78, s * 0.60),
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.45)
        ..strokeWidth = (s * 0.055).clamp(1.0, 2.0)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(s * 0.74, s * 0.39),
      s * 0.10,
      Paint()..color = AppColors.teal,
    );
  }

  void _paintLiveCorridor(Canvas canvas, double s) {
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.08, s * 0.08, s * 0.84, s * 0.84),
      Radius.circular(s * 0.22),
    );
    canvas.drawRRect(bg, Paint()..color = AppColors.navy);

    // Corridor arc
    final route = Path()
      ..moveTo(s * 0.24, s * 0.72)
      ..cubicTo(s * 0.26, s * 0.36, s * 0.64, s * 0.66, s * 0.72, s * 0.28);
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.075).clamp(1.4, 3.0)
        ..strokeCap = StrokeCap.round,
    );

    // Origin pickup node (Teal)
    canvas.drawCircle(
      Offset(s * 0.24, s * 0.72),
      s * 0.095,
      Paint()..color = AppColors.teal,
    );
    canvas.drawCircle(
      Offset(s * 0.24, s * 0.72),
      s * 0.045,
      Paint()..color = Colors.white,
    );

    // Destination worksite node (Gold)
    canvas.drawCircle(
      Offset(s * 0.72, s * 0.28),
      s * 0.11,
      Paint()..color = AppColors.gold,
    );
    canvas.drawCircle(
      Offset(s * 0.72, s * 0.28),
      s * 0.045,
      Paint()..color = AppColors.navy,
    );
  }

  @override
  bool shouldRepaint(covariant _MashwarTrustEmblemPainter oldDelegate) =>
      oldDelegate.type != type;
}

/// Core pillars of the international MASHWAR 3-Service platform.
enum MashwarServicePillar {
  sharedTrips,
  routeParcels,
  smartSupply,
}

/// Crisp custom vector duotone icon for MASHWAR's 3 international pillars:
/// - [MashwarServicePillar.sharedTrips]: sleek touring car + route seat pin
/// - [MashwarServicePillar.routeParcels]: express route parcel + OTP shield
/// - [MashwarServicePillar.smartSupply]: verified checklist + supply crate
class MashwarServicePillarIcon extends StatelessWidget {
  const MashwarServicePillarIcon({
    super.key,
    required this.pillar,
    this.size = 42,
    this.showSurface = true,
  });

  final MashwarServicePillar pillar;
  final double size;
  final bool showSurface;

  (Color accent, Color surface, String labelEn) _tokens() {
    switch (pillar) {
      case MashwarServicePillar.sharedTrips:
        return (AppColors.cobalt, AppColors.cobaltSurface, 'Shared Trips');
      case MashwarServicePillar.routeParcels:
        return (AppColors.indigo, AppColors.indigoSurface, 'Parcels on Route');
      case MashwarServicePillar.smartSupply:
        return (AppColors.emerald, AppColors.emeraldSurface, 'Smart Supply');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (accent, surface, labelEn) = _tokens();
    final innerSize = showSurface ? size * 0.64 : size;
    final vector = SizedBox.square(
      dimension: innerSize,
      child: CustomPaint(
        painter: _MashwarServicePillarPainter(pillar: pillar),
      ),
    );

    if (!showSurface) {
      return Semantics(label: labelEn, child: vector);
    }

    return Semantics(
      label: labelEn,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular((size * 0.30).clamp(8.0, 16.0)),
          border: Border.all(
            color: accent.withValues(alpha: 0.22),
            width: 1.0,
          ),
        ),
        child: Center(child: vector),
      ),
    );
  }
}

class _MashwarServicePillarPainter extends CustomPainter {
  const _MashwarServicePillarPainter({required this.pillar});

  final MashwarServicePillar pillar;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    if (s <= 0) return;

    switch (pillar) {
      case MashwarServicePillar.sharedTrips:
        _paintSharedTrips(canvas, s);
        break;
      case MashwarServicePillar.routeParcels:
        _paintRouteParcels(canvas, s);
        break;
      case MashwarServicePillar.smartSupply:
        _paintSmartSupply(canvas, s);
        break;
    }
  }

  void _paintSharedTrips(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.072).clamp(1.2, 2.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Touring car lower body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.08, s * 0.48, s * 0.72, s * 0.24),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.cobalt.withValues(alpha: 0.20));
    canvas.drawRRect(body, stroke);

    // Aerodynamic cabin roof
    final cabin = Path()
      ..moveTo(s * 0.20, s * 0.48)
      ..lineTo(s * 0.30, s * 0.30)
      ..lineTo(s * 0.58, s * 0.30)
      ..lineTo(s * 0.68, s * 0.48)
      ..close();
    canvas.drawPath(cabin, Paint()..color = AppColors.cobalt.withValues(alpha: 0.12));
    canvas.drawPath(cabin, stroke);

    // Wheels
    for (final wx in [0.25, 0.63]) {
      canvas.drawCircle(
        Offset(s * wx, s * 0.74),
        s * 0.085,
        Paint()..color = AppColors.navy,
      );
      canvas.drawCircle(
        Offset(s * wx, s * 0.74),
        s * 0.036,
        Paint()..color = Colors.white,
      );
    }

    // Floating route seat pin on top-right
    final pin = Path()
      ..moveTo(s * 0.79, s * 0.47)
      ..cubicTo(s * 0.66, s * 0.34, s * 0.65, s * 0.19, s * 0.71, s * 0.13)
      ..arcToPoint(
        Offset(s * 0.87, s * 0.13),
        radius: Radius.circular(s * 0.11),
      )
      ..cubicTo(s * 0.93, s * 0.19, s * 0.92, s * 0.34, s * 0.79, s * 0.47)
      ..close();
    canvas.drawPath(pin, Paint()..color = AppColors.cobalt);
    canvas.drawCircle(
      Offset(s * 0.79, s * 0.23),
      s * 0.045,
      Paint()..color = Colors.white,
    );
  }

  void _paintRouteParcels(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.072).clamp(1.2, 2.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Express motion lines on left
    final motionPaint = Paint()
      ..color = AppColors.indigo.withValues(alpha: 0.55)
      ..strokeWidth = (s * 0.065).clamp(1.1, 2.2)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.06, s * 0.38), Offset(s * 0.18, s * 0.38), motionPaint);
    canvas.drawLine(Offset(s * 0.09, s * 0.54), Offset(s * 0.18, s * 0.54), motionPaint);

    // Isometric/sealed parcel box
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.20, s * 0.22, s * 0.56, s * 0.56),
      Radius.circular(s * 0.09),
    );
    canvas.drawRRect(box, Paint()..color = AppColors.indigo.withValues(alpha: 0.16));
    canvas.drawRRect(box, stroke);

    // Center parcel tape band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.41, s * 0.22, s * 0.14, s * 0.24),
        Radius.circular(s * 0.03),
      ),
      Paint()..color = AppColors.gold,
    );
    canvas.drawLine(Offset(s * 0.20, s * 0.40), Offset(s * 0.76, s * 0.40), stroke);

    // Protective OTP shield badge on bottom-right
    final shield = Path()
      ..moveTo(s * 0.76, s * 0.48)
      ..lineTo(s * 0.94, s * 0.54)
      ..lineTo(s * 0.94, s * 0.69)
      ..cubicTo(s * 0.94, s * 0.82, s * 0.76, s * 0.91, s * 0.76, s * 0.91)
      ..cubicTo(s * 0.76, s * 0.91, s * 0.58, s * 0.82, s * 0.58, s * 0.69)
      ..lineTo(s * 0.58, s * 0.54)
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.indigo);
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.045).clamp(1.0, 1.8),
    );
    final check = Path()
      ..moveTo(s * 0.69, s * 0.69)
      ..lineTo(s * 0.74, s * 0.75)
      ..lineTo(s * 0.84, s * 0.63);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.06).clamp(1.1, 2.1)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintSmartSupply(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.072).clamp(1.2, 2.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Verified supply checklist clipboard (back-left)
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.16, s * 0.50, s * 0.66),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(board, Paint()..color = AppColors.emerald.withValues(alpha: 0.15));
    canvas.drawRRect(board, stroke);

    // Top clip bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.26, s * 0.10, s * 0.22, s * 0.11),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = AppColors.navy,
    );

    // Checklist lines
    final linePaint = Paint()
      ..color = AppColors.emerald
      ..strokeWidth = (s * 0.065).clamp(1.1, 2.2)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.22, s * 0.36), Offset(s * 0.48, s * 0.36), linePaint);
    canvas.drawLine(Offset(s * 0.22, s * 0.50), Offset(s * 0.42, s * 0.50), linePaint);

    // Supply crate overlapping front-right
    final crate = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.48, s * 0.48, s * 0.42, s * 0.38),
      Radius.circular(s * 0.07),
    );
    canvas.drawRRect(crate, Paint()..color = AppColors.emerald);
    canvas.drawRRect(
      crate,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.045).clamp(1.0, 1.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.63, s * 0.48, s * 0.12, s * 0.15),
        Radius.circular(s * 0.025),
      ),
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _MashwarServicePillarPainter oldDelegate) =>
      oldDelegate.pillar != pillar;
}
