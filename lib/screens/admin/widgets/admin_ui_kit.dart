import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../state/admin_provider.dart';

/// Semantic theme tokens supporting both Crisp Enterprise Light & NOC Dark War-Room modes.
class AdminThemeTokens {
  final bool isDark;

  const AdminThemeTokens(this.isDark);

  factory AdminThemeTokens.of(BuildContext context) {
    final admin = context.watch<AdminProvider?>();
    return AdminThemeTokens(admin?.isDarkMode ?? false);
  }

  Color get scaffoldBg => isDark ? const Color(0xFF0A1422) : const Color(0xFFF4F6FA);
  Color get surface => isDark ? const Color(0xFF102033) : Colors.white;
  Color get surfaceAlt => isDark ? const Color(0xFF162B42) : const Color(0xFFF8FAFC);
  Color get surfaceMuted => isDark ? const Color(0xFF1D3550) : const Color(0xFFF1F5F9);
  Color get border => isDark ? const Color(0xFF24405F) : const Color(0xFFE2E8F0);
  Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : AppColors.navy;
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6470);
  Color get headerBg => isDark ? const Color(0xFF0D1B2C) : Colors.white;
  Color get accentPrimary => isDark ? AppColors.gold : AppColors.navy;
  Color get accentMaroon => AppColors.qatarMaroon;
  Color get accentTeal => isDark ? const Color(0xFF2DD4BF) : AppColors.teal;
  Color get accentCoral => isDark ? const Color(0xFFF87171) : AppColors.coral;
  Color get tableHeaderBg => isDark ? const Color(0xFF14273D) : const Color(0xFFF8FAFC);
}

/// Responsive layout wrapper & padding scaler across 320px Mobile -> 1920px+ Wide Desktop.
class AdminPageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AdminPageBody({
    super.key,
    required this.child,
    this.maxWidth = 1680,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double pad = w < 420
            ? 12
            : (w < 900 ? 16 : 24);
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Enterprise KPI card with icon badge, tabular figure, delta pill, and sparkline.
class AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String deltaText;
  final Color accentColor;
  final IconData icon;
  final List<double> sparkPoints;
  final VoidCallback? onTap;

  const AdminKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.deltaText,
    required this.accentColor,
    required this.icon,
    this.sparkPoints = const [0.3, 0.45, 0.4, 0.62, 0.58, 0.78, 0.92],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AdminThemeTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
            boxShadow: t.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: t.isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: t.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 58,
                    height: 24,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        points: sparkPoints,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: t.isDark ? 0.16 : 0.09),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deltaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
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

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  const _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path();
    final stepX = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i].clamp(0.05, 1.0) * (size.height - 4)) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.points != points;
}

/// Adaptive Section Card container used consistently across all 12 screens.
class AdminSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final t = AdminThemeTokens.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
        boxShadow: t.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Automatically switches between crisp touch-friendly Mobile Cards (<760px)
/// and horizontally scrollable Enterprise DataTables (>=760px).
class AdminAdaptiveDataView<T> extends StatelessWidget {
  final List<T> items;
  final List<DataColumn> columns;
  final DataRow Function(T item) buildRow;
  final Widget Function(BuildContext context, T item) buildMobileCard;
  final Widget? emptyState;
  final double minTableWidth;

  const AdminAdaptiveDataView({
    super.key,
    required this.items,
    required this.columns,
    required this.buildRow,
    required this.buildMobileCard,
    this.emptyState,
    this.minTableWidth = 820,
  });

  @override
  Widget build(BuildContext context) {
    final t = AdminThemeTokens.of(context);
    if (items.isEmpty) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      return emptyState ??
          Padding(
            padding: const EdgeInsets.all(36),
            child: Center(
              child: Text(
                isAr ? 'لا توجد بيانات مطابقة للعرض' : 'No matching records found',
                style: TextStyle(color: t.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                buildMobileCard(context, items[i]),
                if (i < items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        final targetW = math.max(constraints.maxWidth, minTableWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: targetW),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(t.tableHeaderBg),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: t.textPrimary,
              ),
              dataTextStyle: TextStyle(
                fontSize: 13,
                color: t.textPrimary,
              ),
              dataRowMinHeight: 62,
              dataRowMaxHeight: 70,
              columnSpacing: 20,
              horizontalMargin: 16,
              dividerThickness: 0.7,
              columns: columns,
              rows: items.map(buildRow).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Pure Flutter CustomPainter Area & Line Telemetry Chart for Dashboard & DevOps SRE.
class AdminTelemetryLineChart extends StatelessWidget {
  final List<double> primarySeries;
  final List<double>? secondarySeries;
  final List<String> labels;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;

  const AdminTelemetryLineChart({
    super.key,
    required this.primarySeries,
    this.secondarySeries,
    required this.labels,
    this.primaryColor = AppColors.teal,
    this.secondaryColor = AppColors.gold,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    final t = AdminThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _TelemetryChartPainter(
              primarySeries: primarySeries,
              secondarySeries: secondarySeries,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              gridColor: t.border,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (lbl) => Flexible(
                  child: Text(
                    lbl,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TelemetryChartPainter extends CustomPainter {
  final List<double> primarySeries;
  final List<double>? secondarySeries;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;

  const _TelemetryChartPainter({
    required this.primarySeries,
    this.secondarySeries,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    for (int g = 0; g < 4; g++) {
      final y = (size.height - 12) * (g / 3) + 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double maxVal = 1.0;
    for (final v in primarySeries) {
      if (v > maxVal) maxVal = v;
    }
    if (secondarySeries != null) {
      for (final v in secondarySeries!) {
        if (v > maxVal) maxVal = v;
      }
    }

    _drawSeries(canvas, size, primarySeries, maxVal, primaryColor, fill: true);
    if (secondarySeries != null && secondarySeries!.length >= 2) {
      _drawSeries(canvas, size, secondarySeries!, maxVal, secondaryColor, fill: false);
    }
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> values,
    double maxVal,
    Color color, {
    required bool fill,
  }) {
    if (values.length < 2) return;
    final linePath = Path();
    final fillPath = Path();
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final norm = (values[i] / maxVal).clamp(0.0, 1.0);
      final y = size.height - 10 - (norm * (size.height - 20));
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height - 6);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.2, Paint()..color = color);
    }
    fillPath.lineTo((values.length - 1) * stepX, size.height - 6);
    fillPath.close();

    if (fill) {
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.01),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TelemetryChartPainter oldDelegate) {
    return !listEquals(primarySeries, oldDelegate.primarySeries) ||
        !listEquals(secondarySeries, oldDelegate.secondarySeries) ||
        primaryColor != oldDelegate.primaryColor ||
        secondaryColor != oldDelegate.secondaryColor ||
        gridColor != oldDelegate.gridColor;
  }
}

/// Spotlight Command Palette Dialog (`Ctrl+K` / `/`) for instant navigation across any section or record.
class AdminCommandPaletteDialog extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const AdminCommandPaletteDialog({super.key, required this.onNavigate});

  @override
  State<AdminCommandPaletteDialog> createState() => _AdminCommandPaletteDialogState();
}

class _AdminCommandPaletteDialogState extends State<AdminCommandPaletteDialog> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AdminThemeTokens.of(context);
    final admin = context.watch<AdminProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final results = admin.searchGlobal(_query, isAr);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 540),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _queryController,
                  autofocus: true,
                  style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'ابحث عن شاشة، تسوية #QA، خدمة، محور، أو Flag...'
                        : 'Jump to module, #QA settlement, user, corridor, or flag...',
                    hintStyle: TextStyle(color: t.textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: t.accentPrimary),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close_rounded, color: t.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.border),
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: t.border),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'لا توجد نتائج مطابقة' : 'No matching records found',
                          style: TextStyle(color: t.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: t.border.withValues(alpha: 0.5)),
                        itemBuilder: (ctx, i) {
                          final r = results[i];
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: t.accentTeal.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.categoryTag,
                                style: TextStyle(
                                  color: t.accentTeal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              r.title,
                              style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              r.subtitle,
                              style: TextStyle(color: t.textSecondary, fontSize: 11),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: t.textSecondary),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onNavigate(r.targetMenuIndex);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
