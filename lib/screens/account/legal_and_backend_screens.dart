import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_environment.dart';
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

/// 1. Legal Terms, Qatar PDPL Data Privacy & Regulatory Boundaries Screen
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
              isAr ? 'الشروط القانونية والامتثال التنظيمي' : 'Legal Terms & Regulatory Compliance',
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
                Tab(text: isAr ? 'الحدود التنظيمية والعلامة' : 'Regulatory & Trademark'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildTermsTab(isAr),
              _buildPrivacyTab(isAr),
              _buildRegulatoryBoundariesTab(isAr),
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
          icon: Icons.handyman_outlined,
          title: isAr
              ? 'شروط المرحلة التجريبية لتوريد مواقع العمل (MASHWAR)'
              : 'MASHWAR Worksite Supply Pilot Terms',
          subtitle: isAr
              ? 'نطاق المرحلة الأولى (MVP) — ساري في دولة قطر'
              : 'Phase 1 MVP Pilot Scope — State of Qatar',
          points: isAr
              ? const [
                  'تعمل منصة مشوار في مرحلتها التجريبية الأولى كمنصة تقنية لتنسيق طلبات توريد مستلزمات ومواد مواقع العمل والورش داخل بلديات دولة قطر الثماني.',
                  'يشترط لتقديم عروض التوريد أو تنفيذ الطلبات استكمال توثيق البطاقة الشخصية القطرية المكونة من 11 رقماً (QID) واعتماد حساب المزود من إدارة الامتثال.',
                  'يُحظر تماماً طلب أو نقل أي مواد محظورة قانوناً أو خطرة، ويلتزم المزود بإرفاق صورة فاتورة الشراء عند التوريد متى تطلب الطلب ذلك.',
                  'يُوثق التسليم الفعلي في موقع العمل حصرياً عبر رمز التسليم الأحادي المكون من 6 محارف والخاص بصاحب الطلب (بحد أقصى 5 محاولات وصلاحية 24 ساعة).',
                ]
              : const [
                  'MASHWAR Phase 1 MVP operates solely as a technology coordination platform for worksite supplies, hardware, and site material errands across Qatar\'s 8 municipalities.',
                  'Providers submitting offers or fulfilling orders must complete 11-digit Qatar ID (QID) verification and hold active compliance approval.',
                  'Requesting or transporting unlawful or hazardous materials is strictly prohibited; providers must attach store purchase invoices where applicable.',
                  'On-site delivery completion is verified via the requester\'s single-use 6-character handover code (enforced server-side with a 5-attempt cap and 24-hour expiry).',
                ],
        ),
        const SizedBox(height: AppDimens.space16),
        _buildInfoCard(
          icon: Icons.payments_outlined,
          title: isAr
              ? 'التسعير وطرق التسوية في المرحلة التجريبية'
              : 'Pilot Pricing & Settlement Methods',
          subtitle: isAr
              ? 'الدفع عند الاستلام (cash_on_delivery) أو التحويل البنكي اليدوي (bank_transfer_manual)'
              : 'Direct settlement only: cash_on_delivery or bank_transfer_manual',
          points: isAr
              ? const [
                  'تُعرض جميع الميزانيات وعروض التوريد بالريال القطري (QAR) بشفافية كاملة قبل قبول العرض.',
                  'تقتصر طرق التسوية المعتمدة في المرحلة التجريبية على الدفع النقدي عند الاستلام (cash_on_delivery) أو التحويل البنكي اليدوي المباشر (bank_transfer_manual) مع إرفاق صورة إيصال التحويل للتوثيق.',
                  'لا تحتفظ منصة مشوار بأي أرصدة محافظ رقمية مسبقة الدفع ولا تقدم خدمة الضمان المالي (Escrow) أو تحصيل البطاقات البنكية داخل التطبيق في هذه المرحلة.',
                ]
              : const [
                  'All request budgets and supplier offers are quoted transparently in Qatari Riyals (QAR) prior to offer acceptance.',
                  'Pilot settlement is strictly limited to Cash on Delivery (cash_on_delivery) or direct Manual Bank Transfer (bank_transfer_manual) with uploaded transfer proof.',
                  'MASHWAR does not hold stored-value wallet balances, process in-app card/PSP payments, or act as an escrow custodian during Phase 1.',
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
          title: isAr
              ? 'قانون حماية خصوصية البيانات الشخصية رقم 13 لسنة 2016'
              : 'Qatar Personal Data Privacy Law (PDPL) No. 13 of 2016',
          subtitle: isAr
              ? 'ضوابط الخصوصية وحقوق أصحاب البيانات في دولة قطر'
              : 'Data protection safeguards & data subject rights in Qatar',
          points: isAr
              ? const [
                  'تُجمع البيانات الأساسية (الاسم، البريد الإلكتروني، رقم الجوال +974) وصور البطاقة الشخصية القطرية (QID) بموافقة صريحة ولأغراض التحقق من الهوية وتنفيذ طلبات التوريد فقط.',
                  'تُعزل وثائق التحقق (provider_verifications) بصلاحيات وصول مقيدة للمستخدم نفسه وفريق الامتثال المخول فقط، وتُحفظ رموز التسليم بصيغة تجزئة مشفرة (Salted SHA-256).',
                  'تُشارك تفاصيل الموقع والتواصل بين صاحب الطلب والمزود المعتمد المكلف بالطلب النشط فقط، وتُستضاف البيانات عبر بنية سحابية مشفرة أثناء النقل والتخزين (europe-west1).',
                  'حق حذف الحساب والبيانات: يحق للمستخدم طلب تصحيح بياناته أو حذف حسابه وملفات التوثيق نهائياً من داخل التطبيق فور عدم وجود طلبات نشطة أو نزاعات قائمة.',
                ]
              : const [
                  'Account details (name, email, +974 phone) and 11-digit Qatar ID (QID) KYC images are collected with explicit consent strictly for identity verification and worksite order fulfillment.',
                  'KYC records (provider_verifications) are isolated under strict owner/admin-only access rules, and handover codes are stored solely as salted SHA-256 hashes.',
                  'Contact and site location details are shared strictly between the requester and the assigned approved provider on encrypted cloud infrastructure (europe-west1).',
                  'Account Deletion Rights: Users may update their profile or permanently delete their account and KYC records in-app once any active or disputed worksite orders are closed.',
                ],
        ),
      ],
    );
  }

  Widget _buildRegulatoryBoundariesTab(bool isAr) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 30),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'الإفصاح التنظيمي وحدود المرحلة التجريبية'
                          : 'Regulatory Disclosure & Pilot Scope Boundaries',
                      style: AppTypography.title(color: AppColors.teal).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppEnvironment.pilotScopeDisclaimer(isArabic: isAr),
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
          icon: Icons.policy_outlined,
          title: isAr
              ? 'الخدمات المؤجلة لحين استكمال التراخيص (MoT / QCB)'
              : 'Deferred Modules Pending Licensing (MoT / QCB)',
          subtitle: isAr
              ? 'معطّلة برمجياً بالكامل في إصدار المرحلة الأولى'
              : 'Hard-disabled in Phase 1 software configuration',
          points: isAr
              ? [
                  AppEnvironment.passengerTransportNoticeAr,
                  AppEnvironment.paymentsEscrowNoticeAr,
                ]
              : [
                  AppEnvironment.passengerTransportNoticeEn,
                  AppEnvironment.paymentsEscrowNoticeEn,
                ],
        ),
        const SizedBox(height: AppDimens.space16),
        _buildInfoCard(
          icon: Icons.workspace_premium_outlined,
          title: isAr
              ? 'إشعار العلامة التجارية — وزارة التجارة والصناعة (MoCI)'
              : 'Trademark Notice — Qatar MoCI Single Window',
          subtitle: isAr
              ? 'العلامة التجارية «مشوار / MASHWAR» (الفئات 35 و39 و42)'
              : 'MASHWAR / مشوار Brand Filing (Nice Classes 35, 39 & 42)',
          points: isAr
              ? [
                  'تخضع إجراءات البحث وإيداع العلامة التجارية «مشوار / MASHWAR» في دولة قطر لضوابط إدارة حماية الملكية الفكرية بوزارة التجارة والصناعة عبر النافذة الواحدة (الفئات 35 و39 و42).',
                  AppEnvironment.trademarkNoticeAr,
                ]
              : [
                  'Clearance search and filing for the MASHWAR / مشوار mark in the State of Qatar are governed by the Ministry of Commerce and Industry (MoCI) Single Window IP framework (Nice Classes 35, 39, and 42).',
                  AppEnvironment.trademarkNoticeEn,
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
