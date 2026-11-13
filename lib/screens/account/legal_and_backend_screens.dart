import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/api/api_endpoints.dart';
import '../../data/api/mashwar_api_client.dart';
import '../../data/mock_data.dart';
import '../../state/auth_provider.dart';

/// 1. Legal, Privacy & Ministry of Transport Compliance Screen
class LegalComplianceScreen extends StatelessWidget {
  final int initialTabIndex;
  const LegalComplianceScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTabIndex.clamp(0, 2),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'الشروط القانونية والترخيص',
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
              tabs: const [
                Tab(text: 'شروط الخدمة'),
                Tab(text: 'حماية البيانات'),
                Tab(text: 'امتثال وزارة النقل'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildTermsTab(),
              _buildPrivacyTab(),
              _buildMoTComplianceTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        _buildInfoCard(
          icon: Icons.gavel_outlined,
          title: 'اتفاقية الاستخدام لمنصة مشوار (MASHWAR)',
          subtitle: 'آخر تحديث: يونيو 2026 - ساري في جمهورية مصر العربية',
          points: const [
            'منصة مشوار هي منصة تقنية لتنظيم تشارك الركوب (Carpooling) وتوصيل الطرود الخفيفة بين المسافرين على نفس المسار بين المحافظات.',
            'يلتزم جميع السائقين والركاب بتقديم بيانات هوية صحيحة ومطابقة للرقم القومي المصري الساري.',
            'يُحظر تماماً استخدام التطبيق في نقل المواد المحظورة قانوناً أو تجاوز عدد المقاعد المحدد في رخصة تسيير المركبة.',
            'تخضع سياسة الإلغاء واسترداد المبالغ في المحفظة لضوابط الوقت المعلن قبل انطلاق الرحلة (مجاني قبل 24 ساعة من الانطلاق).',
          ],
        ),
        const SizedBox(height: AppDimens.space16),
        _buildInfoCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'الرسوم والمدفوعات الرقمية',
          subtitle: 'تكامل المحفظة مع InstaPay وVodafone Cash وFawry',
          points: const [
            'رسوم الخدمة والمنصة محددة بشفافية كاملة قبل تأكيد الحجز (10% شاملة ضريبة القيمة المضافة).',
            'تُحفظ مبالغ الحجز الإلكتروني في حساب ضامن (Escrow) ولا يتم تحويلها للسائق إلا بعد تأكيد إتمام الرحلة أو تسليم الطرد برمز OTP.',
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        _buildInfoCard(
          icon: Icons.privacy_tip_outlined,
          title: 'قانون حماية البيانات الشخصية رقم 151 لسنة 2020',
          subtitle: 'التزام كامل بمعايير التشفير والخصوصية في مصر',
          points: const [
            'تُشفر صور البطاقات الشخصية ورخص القيادة بتقنية AES-256 وتُستخدم حصرياً للتحقق من الهوية والأمان (KYC).',
            'لا تتم مشاركة رقم الهاتف الكامل بين الأطراف إلا بعد تأكيد الحجز الفعلي للرحلة أو الطرد.',
            'بيانات الموقع الجغرافي الحي (Live GPS) تُفعل فقط أثناء الرحلة النشطة أو عند استخدام زر استغاثة الطوارئ SOS.',
            'يحق للمستخدم طلب تصدير بياناته أو حذف حسابه نهائياً من الخوادم بشرط عدم وجود رحلات أو التزامات مالية معلقة.',
          ],
        ),
      ],
    );
  }

  Widget _buildMoTComplianceTab() {
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
                      'متوافق مع ضوابط النقل الذكي التشاركي',
                      style: AppTypography.title(color: AppColors.teal).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مرخص لتنظيم تشارك تكلفة السفر بين المحافظات (Peer-to-Peer Cost Sharing)',
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
          title: 'ضوابط السائقين والمركبات المسجلة',
          subtitle: 'معايير الفحص والتحقق الدوري',
          points: const [
            'التحقق الآلي واليدوي من سريان رخصة القيادة الخاصة ورخصة تسيير المركبة.',
            'تحديد سقف مساهمة المقعد بما يتناسب مع مسافة الطريق وتكلفة الوقود الفعلية دون تحويل المركبة لسيارة أجرة تجارية.',
            'دعم خيار "مقصورة سيدات فقط" لتعزيز الأمان والخصوصية على خطوط السفر الطويلة.',
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
    return Container(
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
            children: [
              Icon(icon, color: AppColors.teal, size: 24),
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
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_getSampleJson(context));
    final logs = MashwarApiClient.instance.recentLogs;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'جاهزية الباك إند وواجهات API',
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
