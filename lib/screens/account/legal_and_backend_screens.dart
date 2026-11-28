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
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../data/api/api_endpoints.dart';
import '../../data/api/mashwar_api_client.dart';
import '../../data/mock_data.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';
import '../../data/services/google_maps_service.dart';
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
          backgroundColor: AppColors.slateBg,
          appBar: AppBar(
            title: Text(
              isAr
                  ? 'الشروط القانونية والامتثال التنظيمي'
                  : 'Legal Terms & Regulatory Compliance',
              style: AppTypography.title().copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.navy,
                size: 19,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              labelColor: AppColors.teal,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.teal,
              indicatorWeight: 2.5,
              dividerColor: AppColors.slateBorder,
              labelStyle: AppTypography.bodySecondary()
                  .copyWith(fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: isAr ? 'شروط الخدمة' : 'Terms of Service'),
                Tab(text: isAr ? 'حماية البيانات' : 'Data Privacy'),
                Tab(
                  text: isAr
                      ? 'الحدود التنظيمية والعلامة'
                      : 'Regulatory & Trademark',
                ),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: TabBarView(
                children: [
                  _buildTermsTab(isAr),
                  _buildPrivacyTab(isAr),
                  _buildRegulatoryBoundariesTab(isAr),
                ],
              ),
            ),
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
              ? 'التسعير وطرق التسوية المباشرة'
              : 'Transparent Pricing & Direct Settlement',
          subtitle: isAr
              ? 'الدفع النقدي عند الاستلام أو التحويل البنكي المباشر الموثّق'
              : 'Direct settlement only: Cash on Delivery or Verified Bank Transfer',
          points: isAr
              ? const [
                  'تُعرض جميع الميزانيات وعروض التوريد بالريال القطري (QAR) بشفافية كاملة قبل قبول العرض.',
                  'تتم التسوية المباشرة بين الأطراف عبر الدفع النقدي عند الاستلام أو التحويل البنكي اليدوي المباشر مع إرفاق صورة إيصال التحويل للتوثيق.',
                  'لا تحتفظ منصة مشوار بأرصدة محافظ رقمية مسبقة الدفع ولا تحجز أموال المستخدمين أو تعالج مدفوعات بطاقات داخل التطبيق في هذه المرحلة.',
                ]
              : const [
                  'All request budgets and supplier offers are quoted transparently in Qatari Riyals (QAR) prior to offer acceptance.',
                  'Settlement happens directly between members via Cash on Delivery or direct Manual Bank Transfer with uploaded transfer proof.',
                  'MASHWAR does not hold stored-value wallet balances, process in-app card payments, or lock customer funds in custody during Phase 1.',
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
                  'تُجمع البيانات الأساسية (الاسم، البريد الإلكتروني، رقم الجوال +974) وصور البطاقة الشخصية القطرية (QID) بموافقة صريحة ولأغراض التحقق من الهوية وتنفيذ الطلبات فقط.',
                  'تُحفظ وثائق التحقق من الهوية بصلاحيات وصول مقيدة للمستخدم نفسه وفريق الامتثال المخوّل فقط، وتُحمى رموز التسليم بتشفير أحادي الاتجاه غير قابل للاسترجاع.',
                  'تُشارك تفاصيل الموقع والتواصل بين صاحب الطلب والمزود المعتمد المكلف بالطلب النشط فقط، وتُستضاف البيانات عبر بنية سحابية مؤمّنة ومشفّرة أثناء النقل والتخزين.',
                  'حق حذف الحساب والبيانات: يحق للمستخدم طلب تصحيح بياناته أو حذف حسابه وملفات التوثيق نهائياً من داخل التطبيق فور عدم وجود طلبات نشطة أو نزاعات قائمة.',
                ]
              : const [
                  'Account details (name, email, +974 phone) and 11-digit Qatar ID (QID) identity documents are collected with explicit consent strictly for identity verification and order fulfillment.',
                  'Identity verification documents are isolated under strict owner and authorized compliance access only, and handover codes are protected with secure one-way encryption.',
                  'Contact and site location details are shared strictly between the requester and the assigned approved provider on encrypted, high-security cloud infrastructure.',
                  'Account Deletion Rights: Users may update their profile or permanently delete their account and identity records in-app once any active or disputed orders are closed.',
                ],
        ),
        const SizedBox(height: AppDimens.space16),
        _buildInfoCard(
          icon: Icons.map_outlined,
          title: isAr
              ? 'خدمات الخرائط والملاحة الجغرافية (Google Maps Platform)'
              : 'Geolocation & Google Maps Platform Terms',
          subtitle: isAr
              ? 'البحث المكاني وحساب المسارات وروابط الملاحة الخارجية'
              : 'Places Autocomplete, Route Estimation & External Navigation',
          points: isAr
              ? const [
                  'يدمج التطبيق ميزات البحث الجغرافي وحساب المسارات وروابط التوجيه من Google Maps Platform، ويخضع استخدامها لشروط خدمة Google Maps الإضافية للمستخدم النهائي (maps.google.com/help/terms_maps) وسياسة خصوصية Google (policies.google.com/privacy).',
                  'لا يتم تتبع الموقع الجغرافي في الخلفية دون إذن صريح وقابل للإلغاء من المستخدم، ولا تُستخدم بيانات الخرائط لتدريب أي نماذج ذكاء اصطناعي.',
                ]
              : const [
                  'This application integrates Google Maps Platform features governed by the Google Maps/Google Earth Additional Terms of Service (maps.google.com/help/terms_maps) and the Google Privacy Policy (policies.google.com/privacy).',
                  'Location lookup requires explicit, revocable user consent, and Google Maps Content is never cached beyond permitted session scope or used for model training.',
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.teal,
                size: 28,
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'الإفصاح التنظيمي وحدود المرحلة التجريبية'
                          : 'Regulatory Disclosure & Pilot Scope Boundaries',
                      style: AppTypography.title(color: AppColors.teal)
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppEnvironment.pilotScopeDisclaimer(isArabic: isAr),
                      style: AppTypography.bodySecondary(
                        color: AppColors.textPrimary,
                      ).copyWith(height: 1.5),
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
              ? 'ضوابط النطاق التشغيلي والتراخيص التنظيمية'
              : 'Operational scope & regulatory licensing boundaries',
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
        borderRadius: 16,
        borderColor: AppColors.slateBorder,
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
                    color: AppColors.tealSurface,
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
                        style: AppTypography.title().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style:
                            AppTypography.label(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(
              height: AppDimens.space24,
              color: AppColors.slateBorder,
            ),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.space12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: Text(
                        point,
                        style: AppTypography.bodySecondary(
                          color: AppColors.textPrimary,
                        ).copyWith(height: 1.5),
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

/// 2. Backend API Readiness, Google Maps Platform Config & Data Contracts Inspector Screen
class BackendReadinessScreen extends StatefulWidget {
  const BackendReadinessScreen({super.key});

  @override
  State<BackendReadinessScreen> createState() => _BackendReadinessScreenState();
}

class _BackendReadinessScreenState extends State<BackendReadinessScreen> {
  final TextEditingController _baseUrlController = TextEditingController(
    text: ApiEndpoints.baseUrl,
  );
  final TextEditingController _mapsApiKeyController = TextEditingController();

  String _selectedModelPreview = 'UserModel';
  bool _isTestingEndpoint = false;
  bool _obscureMapsKey = true;
  bool _isTestingMapsRoute = false;
  int _selectedCorridorIndex = 0;
  RouteDetails? _testedRouteDetails;

  static const List<({String from, String to, String labelAr, String labelEn})>
      _corridorPresets = [
    (
      from: 'الدوحة',
      to: 'الخور',
      labelAr: 'الدوحة ← الخور',
      labelEn: 'Doha → Al Khor',
    ),
    (
      from: 'الدوحة',
      to: 'دخان',
      labelAr: 'الدوحة ← دخان',
      labelEn: 'Doha → Dukhan',
    ),
    (
      from: 'لوسيل',
      to: 'مسيعيد',
      labelAr: 'لوسيل ← مسيعيد',
      labelEn: 'Lusail → Mesaieed',
    ),
    (
      from: 'المنطقة الصناعية',
      to: 'رأس لفان',
      labelAr: 'الصناعية ← رأس لفان',
      labelEn: 'Industrial → Ras Laffan',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final preset = _corridorPresets[_selectedCorridorIndex];
    _testedRouteDetails = GoogleMapsService.estimateRouteSync(
      preset.from,
      preset.to,
    );
    GoogleMapsService.loadRuntimeApiKey().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _mapsApiKeyController.dispose();
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
    final isAr = context.read<SettingsProvider?>()?.isArabic ?? true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم تسجيل طلب $method $path بنجاح في سجل API'
              : 'Recorded $method $path in live API log',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  Future<void> _saveRuntimeMapsKey(bool isAr) async {
    final candidate = _mapsApiKeyController.text.trim();
    if (candidate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'أدخل مفتاح GOOGLE_MAPS_API_KEY أولاً للحفظ.'
                : 'Enter a GOOGLE_MAPS_API_KEY value first.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    await GoogleMapsService.setRuntimeApiKey(candidate);
    _mapsApiKeyController.clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم حفظ مفتاح Google Maps محلياً وتفعيل Places API (New) و Routes API.'
              : 'Runtime Google Maps API key saved locally and activated.',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
    await _runLiveRouteTest();
  }

  Future<void> _clearRuntimeMapsKey(bool isAr) async {
    await GoogleMapsService.clearRuntimeApiKey();
    _mapsApiKeyController.clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم مسح مفتاح Google Maps المحلي والعودة لمحرك الخرائط المدمج.'
              : 'Cleared runtime Google Maps key; using built-in Geo Engine.',
        ),
        backgroundColor: AppColors.navy,
      ),
    );
  }

  Future<void> _runLiveRouteTest() async {
    setState(() => _isTestingMapsRoute = true);
    final preset = _corridorPresets[_selectedCorridorIndex];
    try {
      final result = await AppRepositories.instance.maps.getRouteDetails(
        preset.from,
        preset.to,
      );
      if (!mounted) return;
      setState(() {
        _testedRouteDetails = result;
        _isTestingMapsRoute = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTestingMapsRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider?>()?.isArabic ?? true;
    final prettyJson =
        const JsonEncoder.withIndent('  ').convert(_getSampleJson(context));
    final logs = MashwarApiClient.instance.recentLogs;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.slateBg,
        appBar: AppBar(
          title: Text(
            isAr
                ? 'جاهزية الباك إند وواجهات API'
                : 'Backend API & JSON Contracts',
            style: AppTypography.title().copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
              size: 19,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // 1. Architecture Readiness Banner
                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.cloud_done_outlined,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: AppDimens.space8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'التطبيق جاهز للربط المباشر مع الباك إند (Firebase / REST / Google Maps)'
                                  : 'Production-Ready Backend, Firebase & Google Maps Layer',
                              style: AppTypography.title(color: AppColors.teal)
                                  .copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const MashwarBadge(
                            customLabel: 'Ready v1',
                            type: BadgeType.verified,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space8),
                      Text(
                        isAr
                            ? 'جميع الـ Models مزودة بـ fromJson / toJson / copyWith، مع طبقة MashwarApiClient و GoogleMapsService الموحدة.'
                            : 'All models expose strict JSON contracts alongside MashwarApiClient, Firebase repositories, and GoogleMapsService.',
                        style: AppTypography.bodySecondary(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space16),

                // 2. Base URL Config
                MashwarSectionCard(
                  borderRadius: 16,
                  borderColor: AppColors.slateBorder,
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'عنوان الخادم الأساسي (API Base URL)'
                            : 'Primary REST API Base URL',
                        style: AppTypography.title().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          controller: _baseUrlController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.slateBg,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusField),
                              borderSide:
                                  const BorderSide(color: AppColors.slateBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusField),
                              borderSide:
                                  const BorderSide(color: AppColors.slateBorder),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _baseUrlController.text),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAr
                                          ? 'تم نسخ رابط الـ API الأساسي'
                                          : 'API Base URL copied',
                                    ),
                                  ),
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

                // 3. JSON Model Contract Inspector (kept above-the-fold for instant inspection)
                MashwarSectionCard(
                  borderRadius: 16,
                  borderColor: AppColors.slateBorder,
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'معاينة عقود البيانات (JSON Schema)'
                                  : 'Data Contract Inspector (JSON Schema)',
                              style: AppTypography.title().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_all_outlined,
                              color: AppColors.teal,
                            ),
                            tooltip: isAr ? 'نسخ JSON' : 'Copy JSON',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: prettyJson));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr
                                        ? 'تم نسخ JSON الخاص بـ $_selectedModelPreview'
                                        : 'Copied $_selectedModelPreview JSON',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space8),
                      Wrap(
                        spacing: AppDimens.space8,
                        runSpacing: 6,
                        children: [
                          'UserModel',
                          'RideModel',
                          'ParcelModel',
                          'BoardAdModel',
                        ].map((model) {
                          final selected = _selectedModelPreview == model;
                          return ChoiceChip(
                            label: Text(model),
                            selected: selected,
                            selectedColor: AppColors.tealSurface,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.teal
                                  : AppColors.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedModelPreview = model),
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
                            borderRadius: BorderRadius.circular(12),
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

                // 4. Interactive Google Maps Platform Configuration & Live Route Test Card
                _buildGoogleMapsConfigCard(context, isAr),
                const SizedBox(height: AppDimens.space16),

                // 5. Endpoints List & Quick Test
                MashwarSectionCard(
                  borderRadius: 16,
                  borderColor: AppColors.slateBorder,
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'نقاط الاتصال الجاهزة (REST Endpoints)'
                            : 'Ready REST Endpoints',
                        style: AppTypography.title().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space12),
                      _buildEndpointRow(
                        'POST',
                        ApiEndpoints.sendPhoneOtp,
                        isAr ? 'إرسال رمز التحقق OTP' : 'Send Phone OTP',
                      ),
                      _buildEndpointRow(
                        'POST',
                        ApiEndpoints.verifyOtp,
                        isAr
                            ? 'تأكيد OTP وإصدار JWT'
                            : 'Verify OTP & Mint JWT',
                      ),
                      _buildEndpointRow(
                        'GET',
                        ApiEndpoints.userProfile,
                        isAr
                            ? 'جلب وتحديث ملف المستخدم'
                            : 'Fetch & Update User Profile',
                      ),
                      _buildEndpointRow(
                        'GET',
                        ApiEndpoints.searchRides,
                        isAr
                            ? 'البحث عن الرحلات المتاحة'
                            : 'Search Available Trips',
                      ),
                      _buildEndpointRow(
                        'POST',
                        ApiEndpoints.publishRide,
                        isAr
                            ? 'نشر رحلة سائق جديدة'
                            : 'Publish Traveler Trip',
                      ),
                      _buildEndpointRow(
                        'POST',
                        ApiEndpoints.bookings,
                        isAr
                            ? 'إنشاء حجز مقعد وتأكيد الدفع'
                            : 'Create Seat Booking',
                      ),
                      _buildEndpointRow(
                        'POST',
                        ApiEndpoints.parcels,
                        isAr
                            ? 'إنشاء طلب إرسال طرد مع كود استلام'
                            : 'Create Parcel Request with OTP',
                      ),
                      _buildEndpointRow(
                        'GET',
                        ApiEndpoints.boardAds,
                        isAr
                            ? 'جلب ونشر إعلانات لوحة المشاوير'
                            : 'List & Publish Route Ads',
                      ),
                      _buildEndpointRow(
                        'POST',
                        ApiEndpoints.walletDeposit,
                        isAr
                            ? 'شحن وسحب رصيد المحفظة'
                            : 'Wallet Ledger Operations',
                      ),
                      _buildEndpointRow(
                        'GET',
                        ApiEndpoints.adminKpiStats,
                        isAr
                            ? 'إحصائيات وتقارير لوحة الإدارة'
                            : 'Admin KPI & Operations Metrics',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space16),

                // 6. Live API Request Log
                MashwarSectionCard(
                  borderRadius: 16,
                  borderColor: AppColors.slateBorder,
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'سجل طلبات الشبكة الحية (${logs.length})'
                            : 'Live Network Request Log (${logs.length})',
                        style: AppTypography.title().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space8),
                      MashwarButton(
                        text: isAr
                            ? 'اختبار طلب حي (GET /rides/search)'
                            : 'Simulate Request (GET /rides/search)',
                        variant: MashwarButtonVariant.secondary,
                        isLoading: _isTestingEndpoint,
                        onPressed: () => _simulateEndpointCall(
                          'GET',
                          ApiEndpoints.searchRides,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space12),
                      if (logs.isEmpty)
                        Text(
                          isAr
                              ? 'اضغط "اختبار طلب حي" أو أي نقطة اتصال بالأعلى لمعاينة سجل الطلبات.'
                              : 'Tap "Simulate Request" or any endpoint above to inspect live logs.',
                          style: AppTypography.bodySecondary(),
                        )
                      else
                        ...logs.take(5).map(
                              (log) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppDimens.space8,
                                ),
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(AppDimens.space8),
                                    decoration: BoxDecoration(
                                      color: AppColors.slateBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.slateBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.teal,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            log.method,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            log.path,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${log.statusCode}',
                                          style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
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

                // 7. System State Screens Inspector
                MashwarSectionCard(
                  borderRadius: 16,
                  borderColor: AppColors.slateBorder,
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'معاينة شاشات وحالات النظام (System States)'
                            : 'System State Screens Preview',
                        style: AppTypography.title().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                            avatar: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: AppColors.navy,
                            ),
                            label:
                                Text(isAr ? 'تحديث إجباري' : 'Force Update'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForceUpdateScreen(),
                              ),
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.build_circle_outlined,
                              size: 16,
                              color: AppColors.navy,
                            ),
                            label: Text(isAr ? 'شاشة الصيانة' : 'Maintenance'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MaintenanceScreen(),
                              ),
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.wifi_off_rounded,
                              size: 16,
                              color: AppColors.navy,
                            ),
                            label:
                                Text(isAr ? 'انقطاع الاتصال' : 'Offline Mode'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OfflineScreen(),
                              ),
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.coral,
                            ),
                            label: Text(isAr ? 'خطأ عام' : 'General Error'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GeneralErrorScreen(),
                              ),
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.lock_clock_rounded,
                              size: 16,
                              color: AppColors.navy,
                            ),
                            label: Text(
                              isAr ? 'انتهاء الجلسة' : 'Session Expired',
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SessionExpiredScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleMapsConfigCard(BuildContext context, bool isAr) {
    final hasKey = GoogleMapsService.hasActiveApiKey;
    final hasRuntime = GoogleMapsService.hasRuntimeApiKey;
    final hasCompileTime = GoogleMapsService.hasCompileTimeApiKey;
    final maskedKey = GoogleMapsService.maskedActiveApiKey;
    final preset = _corridorPresets[_selectedCorridorIndex];
    final route = _testedRouteDetails ??
        GoogleMapsService.estimateRouteSync(preset.from, preset.to);

    final statusLabel = hasRuntime
        ? (isAr ? 'مفتاح تشغيلي مفعّل' : 'Runtime Key Active')
        : (hasCompileTime
            ? (isAr ? 'مفتاح بناء مفعّل' : 'Compile-Time Key Active')
            : (isAr ? 'المحرك الجغرافي المدمج' : 'Built-in Geo Engine'));

    return Container(
      key: const ValueKey('backend_gmaps_config_card'),
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasKey
              ? AppColors.teal.withValues(alpha: 0.45)
              : AppColors.slateBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hasKey ? AppColors.tealSurface : AppColors.sand,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: hasKey ? AppColors.teal : AppColors.navy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'إعدادات Google Maps Platform واختبار المسارات'
                              : 'Google Maps Platform Config & Live Route Tester',
                          style: AppTypography.title().copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Places API (New) v1 · Routes API v2 · Maps URLs',
                          style: AppTypography.label(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              MashwarBadge(
                type: hasKey ? BadgeType.verified : BadgeType.confirmed,
                customLabel: statusLabel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasKey
                ? (isAr
                    ? 'المفتاح النشط ($maskedKey) جاهز لطلبات Places API (New) عبر POST و Routes API v2 مع تراجع آمن تلقائي.'
                    : 'Active key ($maskedKey) is wired to Places API (New) POST & Routes API v2 with automatic resilient fallback.')
                : (isAr
                    ? 'يعمل التطبيق حالياً بمحرك قطر والخليج المدمج (Haversine + المحاور السريعة) وروابط الملاحة الرسمية. يمكنك لصق مفتاح GOOGLE_MAPS_API_KEY أدناه للتفعيل الفوري وقت التشغيل دون إعادة بناء.'
                    : 'Currently running on the built-in Qatar & GCC Geo Engine + official Maps URLs. Paste a GOOGLE_MAPS_API_KEY below to enable live Places API (New) & Routes API at runtime.'),
            style: AppTypography.bodySmall(color: AppColors.textSecondary)
                .copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),

          // Runtime API Key Input (Never hardcodes secrets; obscured by default)
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const ValueKey('backend_gmaps_api_key_input'),
              controller: _mapsApiKeyController,
              obscureText: _obscureMapsKey,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slateBg,
                hintText: 'AIza... (GOOGLE_MAPS_API_KEY)',
                prefixIcon: const Icon(
                  Icons.vpn_key_outlined,
                  size: 18,
                  color: AppColors.navy,
                ),
                suffixIcon: IconButton(
                  tooltip: _obscureMapsKey ? 'Show' : 'Hide',
                  icon: Icon(
                    _obscureMapsKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureMapsKey = !_obscureMapsKey),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slateBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slateBorder),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                key: const ValueKey('backend_gmaps_save_key_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _saveRuntimeMapsKey(isAr),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: Text(
                  isAr ? 'حفظ وتفعيل المفتاح' : 'Save Runtime Key',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              if (hasRuntime)
                OutlinedButton.icon(
                  key: const ValueKey('backend_gmaps_clear_key_btn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.slateBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _clearRuntimeMapsKey(isAr),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(
                    isAr ? 'مسح المفتاح المحلي' : 'Clear Saved Key',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'تنبيه أمان وتكلفة: قيّد مفتاح الإنتاج بنطاق HTTP Referrer أو حزمة qa.mashwar.app وواجهات Places API (New) و Routes API. قد يترتب على الاستخدام الفعلي رسوم فوترة على حساب Google Cloud.'
                : 'Security & Billing Notice: Restrict production keys by HTTP referrer / qa.mashwar.app bundle ID and limit to Places API (New) & Routes API. Google Maps Platform usage may incur Google Cloud billing costs.',
            style: AppTypography.label(color: AppColors.textSecondary)
                .copyWith(fontSize: 10.5, height: 1.4),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.slateBorder),
          ),

          // Live Corridor Tester
          Text(
            isAr
                ? 'اختبار حساب المسار والمحور السريع المباشر'
                : 'Live Corridor & Highway Route Tester',
            style: AppTypography.body(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_corridorPresets.length, (idx) {
              final item = _corridorPresets[idx];
              final selected = _selectedCorridorIndex == idx;
              return ChoiceChip(
                key: ValueKey('backend_gmaps_preset_$idx'),
                label: Text(isAr ? item.labelAr : item.labelEn),
                selected: selected,
                selectedColor: AppColors.tealSurface,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  color: selected ? AppColors.tealDark : AppColors.navy,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCorridorIndex = idx;
                    _testedRouteDetails = GoogleMapsService.estimateRouteSync(
                      item.from,
                      item.to,
                    );
                  });
                  _runLiveRouteTest();
                },
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      isAr
                          ? 'المسافة: ${route.distanceKm.round()} كم'
                          : 'Distance: ${route.distanceKm.round()} km',
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      isAr
                          ? 'الزمن التقديري: ${route.durationMinutes} دقيقة'
                          : 'Est. Time: ${route.durationMinutes} min',
                      style: AppTypography.body(color: AppColors.teal)
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  route.corridorHighway(isArabic: isAr),
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                if (route.originLat != null && route.destLat != null) ...[
                  const SizedBox(height: 3),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '(${route.originLat!.toStringAsFixed(4)}, ${route.originLng!.toStringAsFixed(4)}) → (${route.destLat!.toStringAsFixed(4)}, ${route.destLng!.toStringAsFixed(4)})',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: MashwarEmbeddedGoogleMap(
                    origin: preset.from,
                    destination: preset.to,
                    vehicleMode: MashwarMapVehicleMode.trip,
                    showTraffic: true,
                    distanceKm: route.distanceKm,
                    durationMinutes: route.durationMinutes,
                    highwayName: route.corridorHighway(isArabic: isAr),
                    height: 230,
                    borderRadius: 11,
                    interactive: true,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('backend_gmaps_test_route_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.slateBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isTestingMapsRoute ? null : _runLiveRouteTest,
                      icon: _isTestingMapsRoute
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.teal,
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 15,
                              color: AppColors.teal,
                            ),
                      label: Text(
                        isAr ? 'اختبار حساب المسار الحي' : 'Test Live Route',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('backend_gmaps_open_route_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.slateBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => openMashwarInAppMap(
                        context,
                        origin: preset.from,
                        destination: preset.to,
                        vehicleMode: MashwarMapVehicleMode.trip,
                        showTraffic: true,
                        titleAr: preset.labelAr,
                        titleEn: preset.labelEn,
                      ),
                      icon: const Icon(
                        Icons.open_in_full_rounded,
                        size: 15,
                        color: AppColors.teal,
                      ),
                      label: Text(
                        isAr
                            ? 'تكبير الخريطة داخل التطبيق'
                            : 'Full-Screen In-App Map',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
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

  Widget _buildEndpointRow(String method, String path, String description) {
    final isPost = method == 'POST';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
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
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_outline,
              size: 20,
              color: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
