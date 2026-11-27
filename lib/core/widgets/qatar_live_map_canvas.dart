import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../localization/app_strings.dart';
import 'mashwar_animations.dart';

/// Visual themes supported by [QatarLiveMapCanvas].
enum QatarMapStyle {
  /// Clean daylight Uber-style vector cartography for Home & Permissions.
  light,

  /// Executive midnight navy cartography for Splash, Welcome & Desktop Split panels.
  darkExecutive,

  /// Compact route-corridor preview banner for Search Results & Active Booking cards.
  routeFocused,
}

/// Bespoke, GPU-smooth animated interactive Qatar Peninsula vector map featuring:
/// - Authentic Qatar coastline & Corniche silhouette on the Arabian Gulf
/// - Qatar arterial expressways (Al Shamal, Lusail, Al Khor Coastal, Al Wakrah, Dukhan, Salwa)
/// - Smoothly cruising top-down vehicles rotating realistically along highway curves
/// - Highlighted animated active corridor between selected Qatar municipalities
/// - Concentric radar pickup beacons and crisp Arabic/English hub pills
class QatarLiveMapCanvas extends StatefulWidget {
  const QatarLiveMapCanvas({
    super.key,
    this.style = QatarMapStyle.light,
    this.activeFromCity,
    this.activeToCity,
    this.showHubLabels = true,
    this.showCarTrails = true,
    this.showWaterLabels = true,
    this.forceAnimate = false,
    this.borderRadius = 20.0,
    this.bottomOverlayInset = 0.0,
    this.onHubTap,
  });

  final QatarMapStyle style;
  final String? activeFromCity;
  final String? activeToCity;
  final bool showHubLabels;
  final bool showCarTrails;
  final bool showWaterLabels;
  final bool forceAnimate;
  final double borderRadius;
  final double bottomOverlayInset;
  final ValueChanged<String>? onHubTap;

  @override
  State<QatarLiveMapCanvas> createState() => _QatarLiveMapCanvasState();
}

class _QatarLiveMapCanvasState extends State<QatarLiveMapCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (mashwarShouldAnimateContinuous(widget.forceAnimate)) {
      _controller.repeat();
    } else {
      // Deterministic showcase frame so widget tests using pumpAndSettle() pass cleanly.
      _controller.value = 0.36;
    }
  }

  @override
  void didUpdateWidget(covariant QatarLiveMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.forceAnimate != widget.forceAnimate) {
      if (mashwarShouldAnimateContinuous(widget.forceAnimate)) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0.36;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (widget.onHubTap == null) return;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (w <= 0 || h <= 0) return;

    final isAr = context.isArabic;
    final tap = details.localPosition;
    String? closestHub;
    double bestDist = 44.0;

    for (final hub in _qatarHubs) {
      final hubPos = Offset(hub.nx * w, hub.ny * h);
      final dist = (tap - hubPos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        closestHub = isAr ? hub.nameAr : hub.nameEn;
      }
    }
    if (closestHub != null) {
      widget.onHubTap!(closestHub);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onHubTap != null
                ? (details) => _handleTapDown(details, constraints)
                : null,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _QatarLiveMapPainter(
                    progress: _controller.value,
                    style: widget.style,
                    activeFromCity: widget.activeFromCity,
                    activeToCity: widget.activeToCity,
                    showHubLabels: widget.showHubLabels,
                    showCarTrails: widget.showCarTrails,
                    showWaterLabels: widget.showWaterLabels,
                    bottomOverlayInset: widget.bottomOverlayInset,
                    isAr: isAr,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _QatarHub {
  const _QatarHub({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nx,
    required this.ny,
    this.isPrimary = false,
    this.isCourierHub = false,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double nx;
  final double ny;
  final bool isPrimary;
  final bool isCourierHub;
}

const List<_QatarHub> _qatarHubs = [
  _QatarHub(id: 'shamal', nameAr: 'الشمال', nameEn: 'Al Shamal', nx: 0.45, ny: 0.14),
  _QatarHub(id: 'khor', nameAr: 'الخور', nameEn: 'Al Khor', nx: 0.62, ny: 0.27, isPrimary: true),
  _QatarHub(id: 'lusail', nameAr: 'لوسيل', nameEn: 'Lusail', nx: 0.61, ny: 0.43, isPrimary: true),
  _QatarHub(id: 'doha', nameAr: 'الدوحة', nameEn: 'Doha', nx: 0.59, ny: 0.56, isPrimary: true),
  _QatarHub(id: 'rayyan', nameAr: 'الريان', nameEn: 'Al Rayyan', nx: 0.42, ny: 0.55),
  _QatarHub(id: 'airport', nameAr: 'مطار حمد', nameEn: 'HIA Airport', nx: 0.68, ny: 0.62, isCourierHub: true),
  _QatarHub(id: 'industrial', nameAr: 'الصناعية', nameEn: 'Industrial', nx: 0.45, ny: 0.70, isCourierHub: true),
  _QatarHub(id: 'wakrah', nameAr: 'الوكرة', nameEn: 'Al Wakrah', nx: 0.63, ny: 0.74, isPrimary: true),
  _QatarHub(id: 'mesaieed', nameAr: 'مسيعيد', nameEn: 'Mesaieed', nx: 0.59, ny: 0.87),
  _QatarHub(id: 'dukhan', nameAr: 'دخان', nameEn: 'Dukhan', nx: 0.19, ny: 0.56),
];

_QatarHub _resolveHub(String? rawCity, {required _QatarHub fallback}) {
  if (rawCity == null || rawCity.trim().isEmpty) return fallback;
  final q = rawCity.toLowerCase();
  if (q.contains('خور') || q.contains('khor') || q.contains('ذخيرة') || q.contains('لفان') || q.contains('laffan') || q.contains('سميسمة')) {
    return _qatarHubs[1];
  }
  if (q.contains('لوسيل') || q.contains('lusail') || q.contains('الضعاين') || q.contains('daayen') || q.contains('اللؤلؤة') || q.contains('pearl') || q.contains('كتارا') || q.contains('katara') || q.contains('أم صلال') || q.contains('umm salal')) {
    return _qatarHubs[2];
  }
  if (q.contains('مطار') || q.contains('airport') || q.contains('hia') || q.contains('مطار حمد')) {
    return _qatarHubs[5];
  }
  if (q.contains('صناعية') || q.contains('industrial') || q.contains('سلوى') || q.contains('salwa') || q.contains('أبو سمرة') || q.contains('abu samra')) {
    return _qatarHubs[6];
  }
  if (q.contains('مسيعيد') || q.contains('mesaieed') || q.contains('ميناء حمد') || q.contains('hamad port') || q.contains('سيلين') || q.contains('sealine')) {
    return _qatarHubs[8];
  }
  if (q.contains('وكرة') || q.contains('wakrah') || q.contains('وكير')) {
    return _qatarHubs[7];
  }
  if (q.contains('دخان') || q.contains('الشيحانية') || q.contains('dukhan') || q.contains('shahaniya')) {
    return _qatarHubs[9];
  }
  if (q.contains('الشمال') || q.contains('shamal') || q.contains('الرويس') || q.contains('ruwais')) {
    return _qatarHubs[0];
  }
  if (q.contains('ريان') || q.contains('التعليمية') || q.contains('rayyan') || q.contains('education') || q.contains('غرافة') || q.contains('gharafa')) {
    return _qatarHubs[4];
  }
  if (q.contains('الدوحة') || q.contains('مشيرب') || q.contains('السد') || q.contains('الدفنة') || q.contains('doha') || q.contains('msheireb') || q.contains('west bay') || q.contains('وقود') || q.contains('woqod') || q.contains('مترو') || q.contains('metro')) {
    return _qatarHubs[3];
  }
  return fallback;
}

class _QatarLiveMapPainter extends CustomPainter {
  _QatarLiveMapPainter({
    required this.progress,
    required this.style,
    required this.activeFromCity,
    required this.activeToCity,
    required this.showHubLabels,
    required this.showCarTrails,
    required this.showWaterLabels,
    required this.isAr,
    this.bottomOverlayInset = 0.0,
  });

  final double progress;
  final QatarMapStyle style;
  final String? activeFromCity;
  final String? activeToCity;
  final bool showHubLabels;
  final bool showCarTrails;
  final bool showWaterLabels;
  final bool isAr;
  final double bottomOverlayInset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final isDark = style == QatarMapStyle.darkExecutive;
    final isCompact = h < 145;

    // 1. Sea (Arabian Gulf) Canvas Backdrop
    final seaRect = Rect.fromLTWH(0, 0, w, h);
    final seaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF071929), Color(0xFF0B253B)]
            : const [Color(0xFFDCEEF8), Color(0xFFCCE5F4)],
      ).createShader(seaRect);
    canvas.drawRect(seaRect, seaPaint);

    // Subtle nautical grid lines in sea
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.035)
          : const Color(0xFF94C5E0).withValues(alpha: 0.28)
      ..strokeWidth = 0.8;
    const step = 28.0;
    for (double x = 14; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 14; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Subtle Arabian Gulf wave contour arcs
    final wavePaint = Paint()
      ..color = isDark
          ? AppColors.teal.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final wy = h * (0.18 + i * 0.19);
      final wx = w * (0.76 + (i % 2) * 0.05);
      final wave = Path()
        ..moveTo(wx, wy)
        ..quadraticBezierTo(wx + w * 0.05, wy - 4, wx + w * 0.10, wy)
        ..quadraticBezierTo(wx + w * 0.14, wy + 4, wx + w * 0.18, wy);
      canvas.drawPath(wave, wavePaint);
    }

    // 2. Authentic Qatar Peninsula Silhouette Polygon
    final peninsula = Path()
      ..moveTo(w * 0.42, h * 0.06)
      ..quadraticBezierTo(w * 0.50, h * 0.05, w * 0.56, h * 0.13)
      ..quadraticBezierTo(w * 0.63, h * 0.20, w * 0.67, h * 0.28) // Al Khor bay
      ..quadraticBezierTo(w * 0.63, h * 0.35, w * 0.66, h * 0.43) // Lusail & Pearl
      ..quadraticBezierTo(w * 0.61, h * 0.49, w * 0.60, h * 0.54) // West Bay / Corniche crescent
      ..quadraticBezierTo(w * 0.67, h * 0.57, w * 0.72, h * 0.62) // Hamad Airport peninsula
      ..quadraticBezierTo(w * 0.68, h * 0.69, w * 0.66, h * 0.76) // Al Wakrah coast
      ..quadraticBezierTo(w * 0.64, h * 0.86, w * 0.62, h * 0.96) // Mesaieed & Khor Al Adaid
      ..lineTo(w * 0.18, h * 0.96) // Southern Saudi border corridor
      ..quadraticBezierTo(w * 0.16, h * 0.77, w * 0.14, h * 0.58) // Zekreet / Dukhan west coast
      ..quadraticBezierTo(w * 0.16, h * 0.40, w * 0.26, h * 0.28) // Al Zubarah / west inlet
      ..quadraticBezierTo(w * 0.33, h * 0.14, w * 0.42, h * 0.06)
      ..close();

    // Soft coastal halo
    canvas.drawPath(
      peninsula,
      Paint()
        ..color = isDark
            ? AppColors.teal.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Landmass fill
    canvas.drawPath(
      peninsula,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF102A43), Color(0xFF0C2238)]
              : const [Color(0xFFFDFBF6), Color(0xFFF5F1E6)],
        ).createShader(seaRect),
    );

    // Crisp coastline stroke
    canvas.drawPath(
      peninsula,
      Paint()
        ..color = isDark
            ? AppColors.teal.withValues(alpha: 0.45)
            : const Color(0xFF9AC5DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Subtle green zones (Aspire Zone / Mia Park / Lusail Boulevard greenery)
    final parkPaint = Paint()
      ..color = isDark
          ? AppColors.teal.withValues(alpha: 0.14)
          : const Color(0xFFDDF1E4).withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.59), width: w * 0.08, height: h * 0.07),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.61, h * 0.40), width: w * 0.06, height: h * 0.05),
      parkPaint,
    );

    // Subtle Pearl-Qatar & Lusail marine crescent + western sand dune contours
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.46),
      isCompact ? 3.5 : 4.8,
      Paint()..color = isDark ? const Color(0xFF143554) : const Color(0xFFFDFBF6),
    );
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.46),
      isCompact ? 3.5 : 4.8,
      Paint()
        ..color = isDark ? AppColors.teal.withValues(alpha: 0.45) : const Color(0xFF9AC5DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final dunePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.045)
          : const Color(0xFFD8CEB8).withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.42)
        ..quadraticBezierTo(w * 0.28, h * 0.39, w * 0.34, h * 0.43),
      dunePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.24, h * 0.72)
        ..quadraticBezierTo(w * 0.30, h * 0.69, w * 0.36, h * 0.73),
      dunePaint,
    );

    // 3. Arterial Qatar Highway Corridors (Dual-casing Uber cartography)
    Offset hubOffset(_QatarHub hub) => Offset(hub.nx * w, hub.ny * h);

    final shamal = hubOffset(_qatarHubs[0]);
    final khor = hubOffset(_qatarHubs[1]);
    final lusail = hubOffset(_qatarHubs[2]);
    final doha = hubOffset(_qatarHubs[3]);
    final rayyan = hubOffset(_qatarHubs[4]);
    final airport = hubOffset(_qatarHubs[5]);
    final industrial = hubOffset(_qatarHubs[6]);
    final wakrah = hubOffset(_qatarHubs[7]);
    final mesaieed = hubOffset(_qatarHubs[8]);
    final dukhan = hubOffset(_qatarHubs[9]);

    final roadNorth = Path()
      ..moveTo(doha.dx, doha.dy)
      ..quadraticBezierTo(w * 0.55, h * 0.44, w * 0.53, h * 0.34)
      ..quadraticBezierTo(w * 0.50, h * 0.22, shamal.dx, shamal.dy);

    final roadCoastalNorth = Path()
      ..moveTo(doha.dx, doha.dy)
      ..quadraticBezierTo(w * 0.62, h * 0.49, lusail.dx, lusail.dy)
      ..quadraticBezierTo(w * 0.63, h * 0.35, khor.dx, khor.dy)
      ..quadraticBezierTo(w * 0.54, h * 0.19, shamal.dx, shamal.dy);

    final roadSouthCoast = Path()
      ..moveTo(doha.dx, doha.dy)
      ..quadraticBezierTo(w * 0.64, h * 0.60, airport.dx, airport.dy)
      ..quadraticBezierTo(w * 0.64, h * 0.68, wakrah.dx, wakrah.dy)
      ..quadraticBezierTo(w * 0.61, h * 0.81, mesaieed.dx, mesaieed.dy);

    final roadWestDukhan = Path()
      ..moveTo(doha.dx, doha.dy)
      ..quadraticBezierTo(w * 0.50, h * 0.55, rayyan.dx, rayyan.dy)
      ..quadraticBezierTo(w * 0.30, h * 0.55, dukhan.dx, dukhan.dy);

    final roadSalwaInd = Path()
      ..moveTo(doha.dx, doha.dy)
      ..quadraticBezierTo(w * 0.51, h * 0.64, industrial.dx, industrial.dy)
      ..quadraticBezierTo(w * 0.54, h * 0.76, wakrah.dx, wakrah.dy);

    final highways = [
      roadNorth,
      roadCoastalNorth,
      roadSouthCoast,
      roadWestDukhan,
      roadSalwaInd,
    ];

    final roadCasingPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1A3A59)
          : const Color(0xFFD6DEE8)
      ..strokeWidth = isCompact ? 5.0 : 6.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadCorePaint = Paint()
      ..color = isDark
          ? const Color(0xFF234B72)
          : Colors.white
      ..strokeWidth = isCompact ? 3.0 : 3.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final p in highways) {
      canvas.drawPath(p, roadCasingPaint);
      canvas.drawPath(p, roadCorePaint);
    }

    // Glowing highway interchange junctions
    for (final jPt in [doha, lusail, rayyan, wakrah, industrial]) {
      canvas.drawCircle(
        jPt,
        isCompact ? 3.4 : 4.2,
        Paint()..color = AppColors.gold.withValues(alpha: isDark ? 0.25 : 0.20),
      );
    }

    // 4. Highlighted Active Corridor Route (between fromCity and toCity)
    final fromHub = _resolveHub(activeFromCity, fallback: _qatarHubs[3]);
    final toHub = _resolveHub(activeToCity, fallback: _qatarHubs[1]);
    final fromPt = hubOffset(fromHub);
    final toPt = hubOffset(toHub);

    if (fromHub.id != toHub.id) {
      final midCtrl = Offset(
        (fromPt.dx + toPt.dx) / 2 + (fromPt.dy - toPt.dy) * 0.12,
        (fromPt.dy + toPt.dy) / 2 + (toPt.dx - fromPt.dx) * 0.08,
      );
      final activeCorridor = Path()
        ..moveTo(fromPt.dx, fromPt.dy)
        ..quadraticBezierTo(midCtrl.dx, midCtrl.dy, toPt.dx, toPt.dy);

      // Soft outer glow
      canvas.drawPath(
        activeCorridor,
        Paint()
          ..color = AppColors.teal.withValues(alpha: isDark ? 0.42 : 0.25)
          ..strokeWidth = isCompact ? 9 : 11
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Solid main corridor line
      canvas.drawPath(
        activeCorridor,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [AppColors.teal, AppColors.gold],
          ).createShader(seaRect)
          ..strokeWidth = isCompact ? 3.4 : 4.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Animated white direction flow dashes along active corridor
      _drawAnimatedFlowDashes(canvas, activeCorridor, progress);
    }

    // 5. 8 Smoothly Moving Multi-Service Vehicles across Qatar Expressways
    final specs = <_VehicleSpec>[
      _VehicleSpec(path: roadCoastalNorth, speed: 1.0, phase: 0.08, role: _MapVehicleRole.ride),
      _VehicleSpec(path: roadCoastalNorth, speed: 1.0, phase: 0.56, role: _MapVehicleRole.siteSupply, reverse: true),
      _VehicleSpec(path: roadNorth, speed: 1.0, phase: 0.34, role: _MapVehicleRole.courier),
      _VehicleSpec(path: roadSouthCoast, speed: 1.0, phase: 0.22, role: _MapVehicleRole.ride),
      _VehicleSpec(path: roadSouthCoast, speed: 1.0, phase: 0.76, role: _MapVehicleRole.courier, reverse: true),
      _VehicleSpec(path: roadWestDukhan, speed: 1.0, phase: 0.42, role: _MapVehicleRole.ride),
      _VehicleSpec(path: roadWestDukhan, speed: 1.0, phase: 0.85, role: _MapVehicleRole.courier, reverse: true),
      _VehicleSpec(path: roadSalwaInd, speed: 1.0, phase: 0.18, role: _MapVehicleRole.siteSupply),
    ];

    for (final spec in specs) {
      final tRaw = (progress * spec.speed + spec.phase) % 1.0;
      final t = spec.reverse ? (1.0 - tRaw) : tRaw;
      _drawVehicleAlongPath(
        canvas: canvas,
        path: spec.path,
        t: t,
        reverseHeading: spec.reverse,
        role: spec.role,
        isDark: isDark,
        scale: isCompact ? 0.82 : 1.0,
        showTrail: showCarTrails,
      );
    }

    // 6. Pulsing Hub Beacons
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
    _drawPulseBeacon(canvas, fromPt, AppColors.teal, pulse, baseRadius: isCompact ? 4.5 : 5.5);
    if (toHub.id != fromHub.id) {
      _drawPulseBeacon(canvas, toPt, AppColors.gold, (pulse + 0.5) % 1.0,
          baseRadius: isCompact ? 4.5 : 5.5);
    }
    _drawPulseBeacon(canvas, rayyan, AppColors.teal.withValues(alpha: 0.8), (pulse + 0.25) % 1.0,
        baseRadius: 3.5);

    // 7. Hub Nodes & Pill Labels
    if (showHubLabels) {
      final hubsToDraw = isCompact
          ? _qatarHubs.where((e) => e.isPrimary || e.id == fromHub.id || e.id == toHub.id).toList()
          : _qatarHubs.where((e) => e.id != 'airport' && e.id != 'shamal').toList();

      for (final hub in hubsToDraw) {
        final pos = hubOffset(hub);
        final isHighlighted = hub.id == fromHub.id || hub.id == toHub.id;
        if (!isHighlighted && bottomOverlayInset > 0 && pos.dy > h - bottomOverlayInset - 8) {
          continue;
        }
        _drawCityBadge(
          canvas: canvas,
          label: isAr ? hub.nameAr : hub.nameEn,
          pos: pos,
          isDark: isDark,
          isHighlighted: isHighlighted,
          canvasWidth: w,
          canvasHeight: h,
          compact: isCompact,
          bottomInset: bottomOverlayInset,
        );
      }
    }

    // 8. Subtle Arabian Gulf water watermark
    if (showWaterLabels && w >= 240 && !isCompact) {
      final gulfTp = TextPainter(
        text: TextSpan(
          text: isAr ? 'الخليج العربي' : 'ARABIAN GULF',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFF4B84A3).withValues(alpha: 0.55),
            fontSize: 9.5,
            letterSpacing: isAr ? 0 : 1.4,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
          ),
        ),
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      )..layout();
      gulfTp.paint(canvas, Offset(w * 0.74, h * 0.20));
    }
  }

  void _drawAnimatedFlowDashes(Canvas canvas, Path path, double t) {
    final metrics = path.computeMetrics();
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in metrics) {
      final len = metric.length;
      if (len <= 0) continue;
      const double dashLen = 8.0;
      const double gap = 14.0;
      final double offsetStart = (t * (dashLen + gap) * 6) % (dashLen + gap);
      for (double d = offsetStart; d < len; d += dashLen + gap) {
        final end = math.min(d + dashLen, len);
        final seg = metric.extractPath(d, end);
        canvas.drawPath(seg, dashPaint);
      }
    }
  }

  void _drawVehicleAlongPath({
    required Canvas canvas,
    required Path path,
    required double t,
    required bool reverseHeading,
    required _MapVehicleRole role,
    required bool isDark,
    required double scale,
    required bool showTrail,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final dist = (metric.length * t).clamp(0.0, metric.length);
    final tangent = metric.getTangentForOffset(dist);
    if (tangent == null) return;

    final pos = tangent.position;
    double angle = math.atan2(-tangent.vector.dy, tangent.vector.dx);
    if (reverseHeading) angle += math.pi;

    final accentColor = switch (role) {
      _MapVehicleRole.courier => AppColors.teal,
      _MapVehicleRole.siteSupply => AppColors.qatarMaroon,
      _MapVehicleRole.ride => AppColors.gold,
    };

    // Optional soft motion trail behind vehicle
    if (showTrail) {
      final trailStart = (dist - (reverseHeading ? -16.0 : 16.0)).clamp(0.0, metric.length);
      final minD = math.min(trailStart, dist);
      final maxD = math.max(trailStart, dist);
      if (maxD - minD > 1.0) {
        final trailPath = metric.extractPath(minD, maxD);
        canvas.drawPath(
          trailPath,
          Paint()
            ..color = accentColor.withValues(alpha: 0.45)
            ..strokeWidth = 3.2 * scale
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
    }

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    // Headlight beam cone pointing +X
    final beamPath = Path()
      ..moveTo(7, -2.5)
      ..lineTo(20, -6.5)
      ..lineTo(20, 6.5)
      ..lineTo(7, 2.5)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentColor.withValues(alpha: isDark ? 0.35 : 0.24),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(6, -7, 15, 14)),
    );

    // Ground drop shadow
    final isPickup = role == _MapVehicleRole.siteSupply;
    final bodyRect = isPickup
        ? const Rect.fromLTWH(-10, -5.6, 20, 11.2)
        : const Rect.fromLTWH(-9, -5.2, 18, 10.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bodyRect.translate(0.5, 0.8),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: isDark ? 0.48 : 0.22),
    );

    // Car body shell (Teal Courier w/ Parcel Pod, Maroon Site Pickup w/ Cargo Bed, Navy/White Executive Ride)
    final bodyColor = switch (role) {
      _MapVehicleRole.courier => AppColors.teal,
      _MapVehicleRole.siteSupply => AppColors.qatarMaroon,
      _MapVehicleRole.ride => isDark ? Colors.white : AppColors.navy,
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..color = bodyColor,
    );

    // Crisp rim highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()
        ..color = role == _MapVehicleRole.ride
            ? (isDark ? AppColors.gold : Colors.white.withValues(alpha: 0.85))
            : Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (isPickup) {
      // Utility pickup cab + sunlit cargo bed at rear (-X)
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-1.0, -3.7, 8.2, 7.4), const Radius.circular(2.2)),
        Paint()..color = AppColors.qatarMaroonDark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-8.6, -3.8, 6.4, 7.6), const Radius.circular(1.8)),
        Paint()..color = AppColors.sand,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-7.4, -2.5, 4.0, 5.0), const Radius.circular(1.2)),
        Paint()..color = AppColors.gold,
      );
    } else if (role == _MapVehicleRole.courier) {
      // Courier windshield + roof parcel box with golden strap
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, -3.5, 9.5, 7.0), const Radius.circular(2.4)),
        Paint()..color = const Color(0xFF0E4D49),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -2.6, 5.2, 5.2), const Radius.circular(1.4)),
        Paint()..color = Colors.white,
      );
      canvas.drawLine(
        const Offset(-0.9, -2.6),
        const Offset(-0.9, 2.6),
        Paint()
          ..color = AppColors.gold
          ..strokeWidth = 1.2,
      );
    } else {
      // Executive ride panoramic windshield & roof cabin
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, -3.5, 9.5, 7.0), const Radius.circular(2.4)),
        Paint()..color = isDark ? const Color(0xFF0F2A43) : const Color(0xFF284D70),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-1.5, -2.0, 3.8, 4.0), const Radius.circular(1.2)),
        Paint()..color = isDark ? AppColors.teal : AppColors.gold,
      );
    }

    canvas.restore();
  }

  void _drawPulseBeacon(
    Canvas canvas,
    Offset center,
    Color color,
    double pulse, {
    double baseRadius = 5.0,
  }) {
    final ringRadius = baseRadius + 4.0 + (pulse * 12.0);
    final ringAlpha = (1.0 - pulse) * 0.42;
    canvas.drawCircle(center, ringRadius, Paint()..color = color.withValues(alpha: ringAlpha));
    canvas.drawCircle(center, baseRadius + 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, baseRadius, Paint()..color = color);
    canvas.drawCircle(center, baseRadius * 0.42, Paint()..color = Colors.white);
  }

  void _drawCityBadge({
    required Canvas canvas,
    required String label,
    required Offset pos,
    required bool isDark,
    required bool isHighlighted,
    required double canvasWidth,
    required double canvasHeight,
    required bool compact,
    double bottomInset = 0.0,
  }) {
    // Anchor dot on map
    canvas.drawCircle(
      pos,
      isHighlighted ? 4.2 : 3.2,
      Paint()..color = isHighlighted ? AppColors.gold : (isDark ? Colors.white : AppColors.navy),
    );
    canvas.drawCircle(
      pos,
      isHighlighted ? 2.0 : 1.5,
      Paint()..color = isHighlighted ? AppColors.navy : Colors.white,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isHighlighted
              ? Colors.white
              : (isDark ? Colors.white : AppColors.navy),
          fontSize: compact ? 8.8 : 9.8,
          fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
          fontFamily: 'Cairo',
          height: 1.1,
        ),
      ),
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
    )..layout();

    final padX = compact ? 6.0 : 7.5;
    final padY = compact ? 2.5 : 3.0;
    final pillW = tp.width + padX * 2;
    final pillH = tp.height + padY * 2;

    // Position pill to the left of coastal cities so it sits gracefully over land without clipping.
    final rawLeft = pos.dx - pillW - 7;
    final double clampedLeft = (rawLeft < 6
            ? (pos.dx + 7).clamp(6.0, math.max(6.0, canvasWidth - pillW - 6.0))
            : rawLeft.clamp(6.0, math.max(6.0, canvasWidth - pillW - 6.0)))
        .toDouble();
    final double maxTop = math.max(6.0, canvasHeight - bottomInset - pillH - 6.0);
    final double clampedTop = (pos.dy - pillH / 2).clamp(6.0, maxTop).toDouble();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(clampedLeft, clampedTop, pillW, pillH),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = isHighlighted
            ? AppColors.navy
            : (isDark
                ? const Color(0xFF0A1D2E).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.94)),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = isHighlighted
            ? AppColors.gold
            : (isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFFDDE3EC))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 1.2 : 0.8,
    );

    tp.paint(canvas, Offset(clampedLeft + padX, clampedTop + padY));
  }

  @override
  bool shouldRepaint(covariant _QatarLiveMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.style != style ||
        oldDelegate.activeFromCity != activeFromCity ||
        oldDelegate.activeToCity != activeToCity ||
        oldDelegate.showHubLabels != showHubLabels ||
        oldDelegate.isAr != isAr;
  }
}

enum _MapVehicleRole { ride, courier, siteSupply }

class _VehicleSpec {
  const _VehicleSpec({
    required this.path,
    required this.speed,
    required this.phase,
    required this.role,
    this.reverse = false,
  });

  final Path path;
  final double speed;
  final double phase;
  final _MapVehicleRole role;
  final bool reverse;
}
