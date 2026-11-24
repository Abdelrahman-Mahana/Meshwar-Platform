import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/api/mashwar_api_client.dart';
import '../../data/models/admin_platform_models.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminDevOpsSreScreen extends StatefulWidget {
  const AdminDevOpsSreScreen({super.key});

  @override
  State<AdminDevOpsSreScreen> createState() => _AdminDevOpsSreScreenState();
}

class _AdminDevOpsSreScreenState extends State<AdminDevOpsSreScreen> {
  void _openAddFlagDialog(BuildContext context, bool isAr) {
    final admin = context.read<AdminProvider>();
    final keyCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'operations';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isAr ? 'إضافة علم برمجي جديد (Feature Flag)' : 'Create New Feature Flag'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'المفتاح (مثل: qatar_national_day_promo)' : 'Flag Key',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameArCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'العنوان بالعربية' : 'Title (Arabic)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'العنوان بالإنجليزية' : 'Title (English)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوصف' : 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الفئة' : 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'operations', child: Text('operations')),
                      DropdownMenuItem(value: 'security', child: Text('security')),
                      DropdownMenuItem(value: 'payments', child: Text('payments')),
                      DropdownMenuItem(value: 'infra', child: Text('infra')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => category = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              onPressed: () {
                final key = keyCtrl.text.trim();
                if (key.isEmpty) return;
                admin.addFeatureFlag(
                  AdminFeatureFlag(
                    key: key,
                    nameAr: nameArCtrl.text.trim().isEmpty ? key : nameArCtrl.text.trim(),
                    nameEn: nameEnCtrl.text.trim().isEmpty ? key : nameEnCtrl.text.trim(),
                    descriptionAr: descCtrl.text.trim().isEmpty ? 'علم تحكم ديناميكي مضاف عبر DevOps Center' : descCtrl.text.trim(),
                    descriptionEn: descCtrl.text.trim().isEmpty ? 'Dynamic rollout flag added via DevOps Cockpit' : descCtrl.text.trim(),
                    category: category,
                    isEnabled: true,
                    rolloutPct: 100,
                    environment: admin.activeEnvironment,
                    updatedAt: 'الآن',
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: Text(isAr ? 'إضافة وتفعيل' : 'Create Flag'),
            ),
          ],
        ),
      ),
    );
  }

  void _openConfigExportModal(BuildContext context, AdminProvider admin, bool isAr) {
    final jsonStr = admin.exportPlatformConfigJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'نسخة التكوين JSON الكاملة (تم النسخ)' : 'Exported Platform Config JSON (Copied)'),
        content: SizedBox(
          width: 620,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إغلاق' : 'Close')),
        ],
      ),
    );
  }

  void _openConfigImportModal(BuildContext context, AdminProvider admin, bool isAr) {
    final ctrl = TextEditingController(text: admin.exportPlatformConfigJson());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'استيراد وتطبيق تكوين المنصة JSON' : 'Import Platform Config JSON'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: ctrl,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
            onPressed: () {
              final ok = admin.importPlatformConfigJson(ctrl.text);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? (isAr ? 'تم استيراد التكوين وتطبيقه على المنصة بنجاح' : 'Configuration snapshot imported successfully')
                        : (isAr ? 'صيغة JSON غير صالحة' : 'Invalid JSON payload'),
                  ),
                  backgroundColor: ok ? AppColors.teal : AppColors.coral,
                ),
              );
            },
            child: Text(isAr ? 'تطبيق اللقطة' : 'Apply Snapshot'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);
    final apiLogs = MashwarApiClient.instance.recentLogs;

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top DevOps Banner + Environment Switcher + Health Ping
          AdminSectionCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'غرفة عمليات DevOps و SRE ومراقبة البنية التحتية'
                          : 'DevOps, SRE Health & Runtime Configuration Cockpit',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'البيئة النشطة: ${admin.activeEnvironment.toUpperCase()} · تبديل الأعلام البرمجية وتصدير الإعدادات فوراً'
                          : 'Active Env: ${admin.activeEnvironment.toUpperCase()} · Feature Flags, Telemetry & Disaster Recovery',
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DropdownButton<String>(
                      value: admin.activeEnvironment,
                      items: const [
                        DropdownMenuItem(value: 'production', child: Text('ENV: PRODUCTION')),
                        DropdownMenuItem(value: 'staging', child: Text('ENV: STAGING')),
                        DropdownMenuItem(value: 'development', child: Text('ENV: LOCAL_DEV')),
                      ],
                      onChanged: (v) {
                        if (v != null) admin.setEnvironment(v);
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.monitor_heart_rounded, size: 18),
                      label: Text(isAr ? 'فحص حي للأنظمة' : 'Run Health Check'),
                      onPressed: () {
                        admin.runInfraHealthCheck();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'اكتمل فحص الأنظمة الـ 6 بنجاح (HTTP 200)' : 'All 6 subsystems responded HTTP 200'),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6 Infrastructure Subsystems Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1100 ? 3 : (w >= 640 ? 2 : 1);
              final cardW = (w - (14 * (cols - 1))) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: admin.infraServices.map((srv) {
                  final ok = srv.status == 'operational';
                  final col = ok ? t.accentTeal : AppColors.gold;
                  return SizedBox(
                    width: cardW,
                    child: AdminSectionCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAr ? srv.nameAr : srv.nameEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                              Text(
                                '${srv.uptimePct.toStringAsFixed(2)}%',
                                style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(srv.region, style: TextStyle(color: t.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              _metric('p50', '${srv.p50Ms}ms', t),
                              _metric('p95', '${srv.p95Ms}ms', t),
                              _metric('RPS', '${srv.rps}', t),
                              _metric('Err', '${srv.errorRatePct}%', t),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${isAr ? "آخر فحص:" : "Checked:"} ${srv.lastChecked}',
                            style: TextStyle(color: t.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Latency Chart & Live API Inspector Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 940;
              final latencyCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مؤشر زمن الاستجابة p95 وسرعة الطلبات (API Latency)' : 'API Latency (ms) & Throughput Trend',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    const AdminTelemetryLineChart(
                      primarySeries: [44, 39, 42, 36, 31, 29, 28],
                      secondarySeries: [82, 76, 84, 71, 68, 62, 58],
                      labels: ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00', 'Now'],
                      primaryColor: AppColors.teal,
                      secondaryColor: AppColors.gold,
                    ),
                  ],
                ),
              );

              final logsCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'سجل طلبات الشبكة والـ REST API الحي' : 'Live REST / Gateway Request Stream',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    for (final log in apiLogs.take(5))
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: t.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.accentTeal.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${log.statusCode}',
                                style: TextStyle(color: t.accentTeal, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${log.method} ${log.path}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );

              if (isStacked) {
                return Column(
                  children: [
                    latencyCard,
                    const SizedBox(height: 16),
                    logsCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: latencyCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: logsCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Feature Flags & Kill Switches
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isAr ? 'أعلام التشغيل والمفاتيح الفورية (Feature Flags & Kill-Switches)' : 'Runtime Feature Flags & Kill-Switches',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag_rounded, size: 16),
                      label: Text(isAr ? 'إضافة علم جديد' : 'Add Flag'),
                      onPressed: () => _openAddFlagDialog(context, isAr),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final flag in admin.featureFlags)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: flag.isKillSwitch && flag.isEnabled
                          ? AppColors.coral.withValues(alpha: 0.12)
                          : t.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: flag.isKillSwitch && flag.isEnabled ? AppColors.coral : t.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? flag.nameAr : flag.nameEn,
                                    style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${flag.key} · ${flag.category} · ${flag.rolloutPct}%',
                                    style: TextStyle(color: t.textSecondary, fontFamily: 'monospace', fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: flag.isEnabled,
                              activeThumbColor: flag.isKillSwitch ? AppColors.coral : t.accentTeal,
                              onChanged: (_) => admin.toggleFeatureFlag(flag.key),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr ? flag.descriptionAr : flag.descriptionEn,
                          style: TextStyle(color: t.textSecondary, fontSize: 12),
                        ),
                        if (!flag.isKillSwitch)
                          Row(
                            children: [
                              Text('${isAr ? "نطاق الإطلاق:" : "Rollout:"} ${flag.rolloutPct}%', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                              Expanded(
                                child: Slider(
                                  value: flag.rolloutPct.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 10,
                                  activeColor: t.accentTeal,
                                  onChanged: (v) => admin.updateFeatureFlagRollout(flag.key, v.round()),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Future-Proof Config Export / Import / Recovery
          AdminSectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تصدير واستيراد تكوين المنصة الكامل (Infrastructure-as-JSON)' : 'Platform Configuration Portability & Recovery',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'احتفظ بنسخة JSON كاملة لجميع الخدمات والمحاور والأعلام البرمجية والإعدادات لاستعادتها في أي بيئة.'
                          : 'Export, import, or safely reset all services, corridors, flags, and thresholds.',
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: Text(isAr ? 'تصدير JSON' : 'Export JSON'),
                      onPressed: () => _openConfigExportModal(context, admin, isAr),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file_rounded, size: 17),
                      label: Text(isAr ? 'استيراد JSON' : 'Import JSON'),
                      onPressed: () => _openConfigImportModal(context, admin, isAr),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
                      icon: const Icon(Icons.restore_rounded, size: 17),
                      label: Text(isAr ? 'استعادة الافتراضي' : 'Reset Defaults'),
                      onPressed: () {
                        admin.resetPlatformToDefaults();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'تمت استعادة الإعدادات القياسية بأمان' : 'Baseline defaults restored')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String val, AdminThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.border),
      ),
      child: Text('$label: $val', style: TextStyle(color: t.textPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
