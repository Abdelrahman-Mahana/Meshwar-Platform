import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/api/api_endpoints.dart';
import '../../data/api/mashwar_api_client.dart';
import '../../data/mock_data.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../system/system_screens.dart';

/// 1. Legal, Privacy & Ministry of Transport Compliance Screen
class LegalComplianceScreen extends StatelessWidget {
  final int initialTabIndex;
  const LegalComplianceScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider?>()?.isArabic ?? true;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTabIndex.clamp(0, 2),
        child: Scaffold(
          backgroundColor: const Color(0xFFFCFCFD),
          appBar: AppBar(
            title: Text(
              isAr ? 'الشروط القانونية والترخيص' : 'Legal Terms & MoT License',
              style: AppTypography.title(),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.navy,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              labelColor: AppColors.teal,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.teal,
              labelStyle: AppTypography.bodySecondary().copyWith(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: isAr ? 'شروط الخدمة' : 'Terms of Service'),
                Tab(text: isAr ? 'حماية البيانات' : 'Data Privacy'),
                Tab(text: isAr ? 'امتثال وزارة النقل' : 'MoT Compliance'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildTermsTab(isAr),
              _buildPrivacyTab(isAr),
              _buildMoTComplianceTab(isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsTab(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        _buildInfoCard(
          icon: Icons.gavel_outlined,
          title: isAr ? 'اتفاقية الاستخدام لمنصة مشوار (MASHWAR)' : 'MASHWAR Platform Terms of Use',
          subtitle: isAr ? 'آخر تحديث: يونيو 2026 - ساري في دولة قطر' : 'Last Updated: June 2026 - Valid in State of Qatar',
          points: isAr
              ? const [
                  'منصة مشوار هي منصة تقنية لتنظيم تشارك الركوب (Carpooling) وتوصيل الطرود الخفيفة بين المسافرين على نفس المسار بين مناطق ومدن دولة قطر.',
                  'يلتزم جميع السائقين والركاب بتقديم بيانات هوية صحيحة ومطابقة للبطاقة الشخصية القطرية (QID) السارية.',
                  'يُحظر تماماً استخدام التطبيق في نقل المواد المحظورة قانوناً أو تجاوز عدد المقاعد المحدد في استمارة المركبة.',
                  'تخضع سياسة الإلغاء واسترداد المبالغ في المحفظة لضوابط الوقت المعلن قبل انطلاق الرحلة (مجاني قبل 24 ساعة من الانطلاق).',
                ]
              : const [
                  'MASHWAR is a technology platform connecting inter-area travelers in Qatar for shared rides (Carpooling) and light parcel delivery along the same corridor.',
                  'All drivers and passengers must provide valid Qatar ID (QID) details.',
                  'Transporting prohibited items or exceeding the licensed seat capacity is strictly forbidden.',
                  'Cancellations and wallet refunds follow the published schedule (free up to 24 hours before departure).',
                ],
        ),
        const SizedBox(height: AppDimens.space16),
        _buildInfoCard(
          icon: Icons.account_balance_wallet_outlined,
          title: isAr ? 'الرسوم والمدفوعات الرقمية' : 'Fees & Digital Payments',
          subtitle: isAr ? 'تكامل المحفظة مع فوراً (Fawran) وQPay وSkipCash وApple Pay' : 'Integrated with Fawran, QPay, SkipCash & Apple Pay',
          points: isAr
              ? const [
                  'رسوم الخدمة والمنصة محددة بشفافية كاملة بالريال القطري (ر.ق) قبل تأكيد الحجز.',
                  'تُحفظ مبالغ الحجز الإلكتروني في حساب ضامن (Escrow) ولا يتم تحويلها للسائق إلا بعد تأكيد إتمام الرحلة أو تسليم الطرد برمز OTP.',
                ]
              : const [
                  'Platform service fees are transparently displayed in QAR prior to booking confirmation.',
                  'Digital payments are held in escrow and released to the driver only after trip completion or 4-digit OTP parcel handover.',
                ],
        ),
      ],
    );
  }

  Widget _buildPrivacyTab(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        _buildInfoCard(
          icon: Icons.privacy_tip_outlined,
          title: isAr ? 'قانون حماية خصوصية البيانات الشخصية رقم 13 لسنة 2016' : 'Qatar Personal Data Privacy Law No. 13 of 2016',
          subtitle: isAr ? 'التزام كامل بمعايير التشفير والخصوصية في دولة قطر' : 'Full compliance with Qatar NCSA encryption & KYC privacy standards',
          points: isAr
              ? const [
                  'تُشفر صور البطاقات الشخصية القطرية (QID) ورخص القيادة بتقنية AES-256 وتُستخدم حصرياً للتحقق من الهوية والأمان (KYC).',
                  'لا تتم مشاركة رقم الجوال الكامل بين الأطراف إلا بعد تأكيد الحجز الفعلي للرحلة أو الطرد.',
                  'بيانات الموقع الجغرافي الحي (Live GPS) تُفعل فقط أثناء الرحلة النشطة أو عند استخدام زر استغاثة الطوارئ SOS (999).',
                  'يحق للمستخدم طلب تصدير بياناته أو حذف حسابه نهائياً من الخوادم بشرط عدم وجود رحلات أو التزامات مالية معلقة.',
                ]
              : const [
                  'Qatar ID (QID) and driver license images are AES-256 encrypted and used exclusively for KYC verification.',
                  'Mobile numbers are masked until a ride or parcel booking is officially confirmed.',
                  'Live GPS location sharing is active only during an ongoing trip or when Emergency SOS (999) is triggered.',
                  'Users may export their data or permanently delete their account when no active rides or balances are pending.',
                ],
        ),
      ],
    );
  }

  Widget _buildMoTComplianceTab(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.tealSurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: AppColors.teal, size: 32),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'متوافق مع ضوابط النقل الذكي التشاركي' : 'Compliant with Smart Shared Mobility Regulations',
                      style: AppTypography.title(color: AppColors.teal).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'مرخص لتنظيم تشارك تكلفة التنقل بين مناطق قطر (Peer-to-Peer Cost Sharing)'
                          : 'Licensed for inter-area peer-to-peer travel cost sharing in Qatar',
                      style: AppTypography.bodySecondary(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space16),
        _buildInfoCard(
          icon: Icons.directions_car_filled_outlined,
          title: isAr ? 'ضوابط السائقين والمركبات المسجلة' : 'Registered Driver & Vehicle Controls',
          subtitle: isAr ? 'معايير وزارة المواصلات وإدارة المرور في قطر' : 'MOT Qatar & General Directorate of Traffic standards',
          points: isAr
              ? const [
                  'التحقق الآلي واليدوي من سريان رخصة القيادة الخاصة ورخصة تسيير المركبة.',
                  'تحديد سقف مساهمة المقعد بما يتناسب مع مسافة الطريق وتكلفة الوقود الفعلية دون تحويل المركبة لسيارة أجرة تجارية.',
                  'دعم خيار "مقصورة سيدات فقط" لتعزيز الأمان والخصوصية على خطوط السفر الطويلة.',
                ]
              : const [
                  'Automated and manual verification of private driver licenses and vehicle registration cards.',
                  'Seat cost contribution caps aligned with corridor distance and fuel sharing.',
                  'Dedicated "Ladies Only" cabin option for enhanced safety and comfort on intercity routes.',
                ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> points,
  }) {
    return MashwarFadeSlideIn(
      offsetY: 10,
      child: MashwarSectionCard(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.title().copyWith(fontSize: 16),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.label(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppDimens.space24, color: AppColors.borderDisabled),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.space12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.check_circle, size: 16, color: AppColors.teal),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: Text(
                        point,
                        style: AppTypography.bodySecondary(color: AppColors.textPrimary).copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Backend API Readiness & Data Contracts Inspector Screen
class BackendReadinessScreen extends StatefulWidget {
  const BackendReadinessScreen({super.key});

  @override
  State<BackendReadinessScreen> createState() => _BackendReadinessScreenState();
}

class _BackendReadinessScreenState extends State<BackendReadinessScreen> {
  final TextEditingController _baseUrlController = TextEditingController(
    text: ApiEndpoints.baseUrl,
  );
  String _selectedModelPreview = 'UserModel';
  bool _isTestingEndpoint = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getSampleJson(BuildContext context) {
    final auth = context.read<AuthProvider>();
    switch (_selectedModelPreview) {
      case 'UserModel':
        return auth.user.toJson();
      case 'RideModel':
        return MockData.initialRides.first.toJson();
      case 'ParcelModel':
        return MockData.activeParcel.toJson();
      case 'BoardAdModel':
        return MockData.initialBoardAds.first.toJson();
      default:
        return auth.user.toJson();
    }
  }

  Future<void> _simulateEndpointCall(String method, String path) async {
    setState(() => _isTestingEndpoint = true);
    final client = MashwarApiClient.instance;
    client.recordRequest(
      method,
      path,
      body: method == 'POST' ? _getSampleJson(context) : null,
      statusCode: method == 'POST' ? 201 : 200,
    );
    if (!mounted) return;
    setState(() => _isTestingEndpoint = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل طلب $method $path بنجاح في سجل API'),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider?>()?.isArabic ?? true;
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_getSampleJson(context));
    final logs = MashwarApiClient.instance.recentLogs;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        appBar: AppBar(
          title: Text(
            isAr ? 'جاهزية الباك إند وواجهات API' : 'Backend API & JSON Contracts',
            style: AppTypography.title(),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppDimens.space16),
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.teal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined, color: AppColors.teal),
                      const SizedBox(width: AppDimens.space8),
                      Expanded(
                        child: Text(
                          'التطبيق جاهز للربط المباشر مع الباك إند (REST / JSON)',
                          style: AppTypography.title(color: AppColors.teal).copyWith(fontSize: 16),
                        ),
                      ),
                      const MashwarBadge(customLabel: 'Ready v1', type: BadgeType.verified),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    'جميع الـ Models مزودة بـ fromJson / toJson / copyWith، مع طبقة MashwarApiClient و ApiEndpoints الموحدة وحفظ التوكن JWT.',
                    style: AppTypography.bodySecondary(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Base URL Config
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عنوان الخادم الأساسي (API Base URL)', style: AppTypography.title().copyWith(fontSize: 16)),
                  const SizedBox(height: AppDimens.space8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _baseUrlController,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusField),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _baseUrlController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ رابط الـ API الأساسي')),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // JSON Model Contract Inspector
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('معاينة عقود البيانات (JSON Schema)', style: AppTypography.title().copyWith(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.copy_all_outlined, color: AppColors.teal),
                        tooltip: 'نسخ JSON',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: prettyJson));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم نسخ JSON الخاص بـ $_selectedModelPreview')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Wrap(
                    spacing: AppDimens.space8,
                    children: ['UserModel', 'RideModel', 'ParcelModel', 'BoardAdModel'].map((model) {
                      final selected = _selectedModelPreview == model;
                      return ChoiceChip(
                        label: Text(model),
                        selected: selected,
                        selectedColor: AppColors.tealSurface,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.teal : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedModelPreview = model),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.space12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        prettyJson,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Endpoints List & Quick Test
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نقاط الاتصال الجاهزة (REST Endpoints)', style: AppTypography.title().copyWith(fontSize: 16)),
                  const SizedBox(height: AppDimens.space12),
                  _buildEndpointRow('POST', ApiEndpoints.sendPhoneOtp, 'إرسال رمز التحقق OTP'),
                  _buildEndpointRow('POST', ApiEndpoints.verifyOtp, 'تأكيد OTP وإصدار JWT'),
                  _buildEndpointRow('GET', ApiEndpoints.userProfile, 'جلب وتحديث ملف المستخدم'),
                  _buildEndpointRow('GET', ApiEndpoints.searchRides, 'البحث عن الرحلات المتاحة'),
                  _buildEndpointRow('POST', ApiEndpoints.publishRide, 'نشر رحلة سائق جديدة'),
                  _buildEndpointRow('POST', ApiEndpoints.bookings, 'إنشاء حجز مقعد وتأكيد الدفع'),
                  _buildEndpointRow('POST', ApiEndpoints.parcels, 'إنشاء طلب إرسال طرد مع كود استلام'),
                  _buildEndpointRow('GET', ApiEndpoints.boardAds, 'جلب ونشر إعلانات لوحة المشاوير'),
                  _buildEndpointRow('POST', ApiEndpoints.walletDeposit, 'شحن وسحب رصيد المحفظة'),
                  _buildEndpointRow('GET', ApiEndpoints.adminKpiStats, 'إحصائيات وتقارير لوحة الإدارة'),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Live API Request Log
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سجل طلبات الشبكة الحية (${logs.length})', style: AppTypography.title().copyWith(fontSize: 16)),
                  const SizedBox(height: AppDimens.space8),
                  MashwarButton(
                    text: 'اختبار طلب حي (GET /rides/search)',
                    variant: MashwarButtonVariant.secondary,
                    isLoading: _isTestingEndpoint,
                    onPressed: () => _simulateEndpointCall('GET', ApiEndpoints.searchRides),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  if (logs.isEmpty)
                    Text(
                      'اضغط "اختبار طلب حي" أو أي نقطة اتصال بالأعلى لمعاينة سجل الطلبات.',
                      style: AppTypography.bodySecondary(),
                    )
                  else
                    ...logs.take(5).map(
                          (log) => Padding(
                            padding: const EdgeInsets.only(bottom: AppDimens.space8),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Container(
                                padding: const EdgeInsets.all(AppDimens.space8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.teal,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.method,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        log.path,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      '${log.statusCode}',
                                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // System State Screens Inspector (معاينة حالات النظام والاستجابة)
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'معاينة شاشات وحالات النظام (System States)' : 'System State Screens Preview',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'تتيح هذه اللوحة فحص استجابة الواجهة لكل الحالات الاستثنائية كالتحديث والصيانة وانقطاع الاتصال.'
                        : 'Inspect how the application behaves under force updates, maintenance, offline mode, and expired sessions.',
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.navy),
                        label: Text(isAr ? 'تحديث إجباري' : 'Force Update'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForceUpdateScreen()),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.navy),
                        label: Text(isAr ? 'شاشة الصيانة' : 'Maintenance'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.navy),
                        label: Text(isAr ? 'انقطاع الاتصال' : 'Offline Mode'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OfflineScreen()),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.coral),
                        label: Text(isAr ? 'خطأ عام' : 'General Error'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GeneralErrorScreen()),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.navy),
                        label: Text(isAr ? 'انتهاء الجلسة' : 'Session Expired'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SessionExpiredScreen()),
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
    );
  }

  Widget _buildEndpointRow(String method, String path, String description) {
    final isPost = method == 'POST';
    return InkWell(
      onTap: () => _simulateEndpointCall(method, path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
        child: Row(
          children: [
            Container(
              width: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isPost ? AppColors.infoBg : AppColors.tealSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                method,
                style: AppTypography.label(
                  color: isPost ? AppColors.info : AppColors.teal,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      path,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline, size: 20, color: AppColors.teal),
          ],
        ),
      ),
    );
  }
}
