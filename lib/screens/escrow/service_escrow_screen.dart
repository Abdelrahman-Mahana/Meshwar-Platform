import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/mashwar_handover_qr_panel.dart';
import '../../data/mock_data.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/settings_provider.dart';
import '../chat/chat_screen.dart';
import '../safety/safety_screens.dart';

/// Bilateral Anti-Fraud & Smart Service Escrow Screen ("نظام ضمان مشوار لحفظ حق الطرفين").
class ServiceEscrowScreen extends StatefulWidget {
  @visibleForTesting
  static Future<bool> Function(Uri uri)? debugUrlLauncher;

  const ServiceEscrowScreen({
    super.key,
    this.ad,
  });

  final BoardAdModel? ad;

  @override
  State<ServiceEscrowScreen> createState() => _ServiceEscrowScreenState();
}

class _ServiceEscrowScreenState extends State<ServiceEscrowScreen> {
  bool _viewAsRequester = true;
  bool _escrowLocked = true;
  bool _receiptApproved = false;
  bool _escrowReleased = false;
  bool _disputeFrozen = false;
  String _fundingChannel = 'fawran';
  int _selectedStars = 5;
  bool _ratingSubmitted = false;
  final TextEditingController _otpController = TextEditingController();
  String? _otpError;

  BoardAdModel get _activeAd => widget.ad ?? MockData.initialBoardAds.first;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _openEscrowRouteInGoogleMaps(
    BuildContext context,
    BoardAdModel ad,
    bool isAr,
  ) async {
    final override = ServiceEscrowScreen.debugUrlLauncher ??
        EmergencySosSheet.debugUrlLauncher;
    if (override != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final origin = '${ad.fromCity.trim()}, Qatar';
      final dest = '${ad.toCity.trim()}, Qatar';
      final buffer = StringBuffer(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${Uri.encodeComponent(origin)}'
        '&destination=${Uri.encodeComponent(dest)}',
      );
      if (ad.stopoverCity != null && ad.stopoverCity!.trim().isNotEmpty) {
        buffer.write(
          '&waypoints=${Uri.encodeComponent('${ad.stopoverCity!.trim()}, Qatar')}',
        );
      }
      buffer.write('&travelmode=driving');
      final url = buffer.toString();

      final launched = await override(Uri.parse(url));
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: url));
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم نسخ رابط المسار في Google Maps إلى الحافظة'
                  : 'Google Maps route link copied to clipboard',
            ),
            backgroundColor: AppColors.navy,
          ),
        );
      }
      return;
    }

    await openMashwarInAppMap(
      context,
      origin: ad.fromCity,
      destination: ad.toCity,
      stopover: ad.stopoverCity,
      titleAr: 'مسار الضمان · ${ad.fromCity} ← ${ad.toCity}',
      titleEn: 'Escrow Route · ${ad.fromCity} → ${ad.toCity}',
    );
  }

  void _releaseEscrowWithOtp(bool isAr) {
    final code = _otpController.text.trim();
    if (code.length != 4 || int.tryParse(code) == null) {
      setState(() {
        _otpError = isAr
            ? 'الرجاء إدخال كود التسليم المكوّن من 4 أرقام'
            : 'Please enter the 4-digit handover OTP';
      });
      return;
    }
    setState(() {
      _otpError = null;
      _escrowReleased = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم التحقق من الكود وتحرير المستحقات لمحفظة المنفّذ بنجاح'
              : 'OTP verified and Escrow funds released to provider wallet',
        ),
        backgroundColor: AppColors.escrowGreen,
      ),
    );
  }

  void _openDisputeDialog(bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.navy, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr
                    ? 'تجميد الضمان وفتح نزاع محايد'
                    : 'Freeze Escrow & Dispute Arbitration',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'عند تفعيل التجميد، يوقف مشوار تحويل أي مبلغ من الضمان فوراً لحين مراجعة سجل الدردشة، صورة الفاتورة، وإحداثيات GPS لكلا الطرفين خلال 2 ساعة.'
              : 'Freezing immediately pauses all Escrow transfers while MASHWAR Trust & Safety audits chat logs, receipt photos, and GPS trail within 2 hours.',
          style: AppTypography.bodySecondary(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() => _disputeFrozen = true);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم تجميد المبلغ في محفظة الضمان وحفظ حقوق الطرفين'
                        : 'Escrow funds frozen securely pending arbitration',
                  ),
                  backgroundColor: AppColors.navy,
                ),
              );
            },
            child: Text(isAr ? 'تجميد المبلغ الآن' : 'Freeze Escrow Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final ad = _activeAd;
    final serviceFee = ad.priceOrBudget;
    final itemBudget =
        ad.estimatedItemCost ?? (ad.requiresReceiptProof ? 150 : 0);
    final totalLocked = serviceFee + itemBudget;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: AppColors.teal,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isAr
                    ? 'الضمان المالي وحماية الطرفين'
                    : 'Bilateral Escrow Shield',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title().copyWith(fontSize: 17),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 860;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1140 : 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroShieldBanner(isAr, ad, totalLocked),
                      const SizedBox(height: 16),

                      if (_disputeFrozen) ...[
                        _buildFrozenAlertBanner(isAr),
                        const SizedBox(height: 16),
                      ],

                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildBilateralGuaranteeToggleCard(isAr),
                                  const SizedBox(height: 16),
                                  _buildFinancialVaultCard(
                                    isAr,
                                    serviceFee: serviceFee,
                                    itemBudget: itemBudget,
                                    totalLocked: totalLocked,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 6,
                              child: _buildFiveStageExecutionCard(
                                context,
                                isAr,
                                ad: ad,
                                itemBudget: itemBudget,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildBilateralGuaranteeToggleCard(isAr),
                        const SizedBox(height: 16),
                        _buildFinancialVaultCard(
                          isAr,
                          serviceFee: serviceFee,
                          itemBudget: itemBudget,
                          totalLocked: totalLocked,
                        ),
                        const SizedBox(height: 16),
                        _buildFiveStageExecutionCard(
                          context,
                          isAr,
                          ad: ad,
                          itemBudget: itemBudget,
                        ),
                      ],
                      const SizedBox(height: 16),

                      _buildBottomArbitrationBar(isAr),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroShieldBanner(bool isAr, BoardAdModel ad, int totalLocked) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.navy, Color(0xFF132F4C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MashwarLivePulseDot(
                          color: AppColors.teal,
                          size: 7,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isAr
                                ? 'عقد مشوار الذكي للضمان'
                                : 'MASHWAR Smart Escrow',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(color: Colors.white)
                                .copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAr
                        ? 'حق الطالب وحق المنفّذ محفوظ 100% قبل التحرك'
                        : '100% Bilateral Protection Before Execution',
                    style: AppTypography.title(color: Colors.white)
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${ad.displaySubTag(isAr)} · ${context.trRoute(ad.route)} ($totalLocked ${isAr ? "ر.ق" : "QAR"})',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: const MashwarAssetArt(
                assetPath: 'assets/images/escrow_trust_shield.jpg',
                width: 78,
                height: 78,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                fallbackIcon: Icons.shield_rounded,
                fallbackColor: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrozenAlertBanner(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cobaltSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            color: AppColors.navy,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'حساب الضمان مجمّد قيد المراجعة المحايدة من فريق ثقة مشوار — لن يُصرف أي مبلغ قبل الفصل.'
                  : 'Escrow frozen under neutral MASHWAR arbitration — zero funds move until resolved.',
              style: AppTypography.bodySmall(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilateralGuaranteeToggleCard(bool isAr) {
    final points = _viewAsRequester
        ? [
            (
              Icons.savings_outlined,
              isAr
                  ? 'مبلغك محفوظ بالضمان وليس بيد المنفّذ'
                  : 'Funds stay locked in Escrow',
              isAr
                  ? 'لا يذهب أي مبلغ لحساب المنفّذ مقدمًا قبل استلامك وموافقتك.'
                  : 'Zero payout upfront until handover is confirmed.',
            ),
            (
              Icons.receipt_long_rounded,
              isAr
                  ? 'تصوير الفاتورة الأصلية والغرض قبل التحرك'
                  : 'Live receipt & item photo check',
              isAr
                  ? 'تشاهد صورة الغرض وفاتورة المحل وتعتمدها بنقرة قبل الدفع.'
                  : 'Inspect the bought item & store invoice before dispatch.',
            ),
            (
              Icons.pin_rounded,
              isAr
                  ? 'كود الاستلام OTP بيدك وحدك'
                  : '4-digit OTP strictly in your hands',
              isAr
                  ? 'أعطِ المنفّذ كود الإتمام فقط عند تسليم الغرض أو وصول المشوار.'
                  : 'Release funds only after physical verification.',
            ),
          ]
        : [
            (
              Icons.verified_rounded,
              isAr
                  ? 'مستحقاتك + ميزانية الشراء محجوزة مسبقاً'
                  : 'Fee + purchase cap locked upfront',
              isAr
                  ? 'لن تشتري غرضاً أو تتحرك إلا والمبلغ محجوز ومؤكد في الضمان عبر فوراً.'
                  : 'Never spend upfront without verified Escrow backing.',
            ),
            (
              Icons.no_encryption_gmailerrorred_outlined,
              isAr
                  ? 'حماية تامة من التراجع أو رفض الاستلام'
                  : 'Protection against cancellation/ghosting',
              isAr
                  ? 'بمجرد اعتماد الطالب للفاتورة بالصورة، لا يمكنه إلغاء الطلب بدون تعويضك.'
                  : 'Once receipt is approved, cancellation cannot forfeit your fee.',
            ),
            (
              Icons.flash_on_rounded,
              isAr
                  ? 'تحويل فوري لمحفظتك بمجرد إدخال OTP'
                  : 'Instant payout on OTP entry',
              isAr
                  ? 'فور تسليم الطلب وإدخال الكود يدخل أتعابك وقيمة الفاتورة لحسابك مباشرة.'
                  : 'Escrow credits your wallet the second OTP matches.',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr
                ? 'كيف نضمن حق الطرفين ومنع النصب؟'
                : 'How Both Parties Are Protected',
            style: AppTypography.title().copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.slateBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildRoleSegmentBtn(
                    label: isAr ? 'حماية طالب الخدمة' : 'Requester Shield',
                    selected: _viewAsRequester,
                    activeColor: AppColors.navy,
                    onTap: () => setState(() => _viewAsRequester = true),
                  ),
                ),
                Expanded(
                  child: _buildRoleSegmentBtn(
                    label: isAr ? 'حماية منفّذ الخدمة' : 'Provider Shield',
                    selected: !_viewAsRequester,
                    activeColor: AppColors.teal,
                    onTap: () => setState(() => _viewAsRequester = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...points.map((pt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _viewAsRequester
                          ? AppColors.cobaltSurface
                          : AppColors.tealSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      pt.$1,
                      size: 16,
                      color:
                          _viewAsRequester ? AppColors.navy : AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pt.$2,
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pt.$3,
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoleSegmentBtn({
    required String label,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: selected
              ? Border.all(color: activeColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.label(
            color: selected ? activeColor : AppColors.textSecondary,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFinancialVaultCard(
    bool isAr, {
    required int serviceFee,
    required int itemBudget,
    required int totalLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: AppColors.navy,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'ملخص خزينة الضمان المعلّق (Escrow)'
                      : 'Escrow Vault Breakdown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFinanceRow(
            label: isAr
                ? 'أتعاب المشوار / التوصيل المتفق عليها'
                : 'Agreed Service / Delivery Fee',
            value: '$serviceFee ${isAr ? "ر.ق" : "QAR"}',
          ),
          if (itemBudget > 0) ...[
            const SizedBox(height: 6),
            _buildFinanceRow(
              label: isAr
                  ? 'سقف فاتورة المشتريات المودع بالضمان'
                  : 'Reserved Store Receipt Budget',
              value: '$itemBudget ${isAr ? "ر.ق" : "QAR"}',
            ),
          ],
          const Divider(height: 18, color: AppColors.slateBorder),
          _buildFinanceRow(
            label: isAr
                ? 'إجمالي المحجوز في الضمان'
                : 'Total Protected in Escrow',
            value: '$totalLocked ${isAr ? "ر.ق" : "QAR"}',
            isHighlight: true,
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'وسيلة الحجز والتسوية المعتمدة'
                : 'Escrow Funding & Payout Channel',
            style: AppTypography.label(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ('fawran', isAr ? 'فوراً Fawran' : 'Fawran'),
              ('qpay', isAr ? 'QPay / هميان' : 'QPay'),
              ('wallet', isAr ? 'محفظة مشوار' : 'Wallet'),
              ('skipcash', 'SkipCash'),
            ].map((ch) {
              final sel = _fundingChannel == ch.$1;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _fundingChannel = ch.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.navy : AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppColors.navy : AppColors.slateBorder,
                    ),
                  ),
                  child: Text(
                    ch.$2,
                    style: AppTypography.label(
                      color: sel ? Colors.white : AppColors.navy,
                    ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slateBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _escrowReleased
                      ? Icons.check_circle_rounded
                      : (_escrowLocked
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded),
                  size: 16,
                  color: _escrowReleased
                      ? AppColors.escrowGreen
                      : (_escrowLocked ? AppColors.teal : AppColors.warning),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _escrowReleased
                        ? (isAr
                            ? 'تم تحرير المستحقات بالكامل بعد مطابقة OTP'
                            : 'Escrow settled after OTP match')
                        : (_escrowLocked
                            ? (isAr
                                ? 'محجوز عبر ${_fundingChannel.toUpperCase()} / محفظة مشوار (جاهز للتنفيذ)'
                                : 'Locked via ${_fundingChannel.toUpperCase()} / Wallet — Ready')
                            : (isAr
                                ? 'في انتظار تأمين المبلغ'
                                : 'Awaiting Escrow Lock')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.navy)
                        .copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isHighlight
                ? AppTypography.body(color: AppColors.navy)
                    .copyWith(fontSize: 13, fontWeight: FontWeight.w700)
                : AppTypography.label(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.title(
            color: isHighlight ? AppColors.escrowGreen : AppColors.navy,
          ).copyWith(fontSize: isHighlight ? 16 : 13.5),
        ),
      ],
    );
  }

  Widget _buildFiveStageExecutionCard(
    BuildContext context,
    bool isAr, {
    required BoardAdModel ad,
    required int itemBudget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'مراحل التنفيذ الموثّقة خطوة بخطوة'
                      : '5-Stage Anti-Fraud Execution',
                  style: AppTypography.title().copyWith(fontSize: 15.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Step 1
          _buildStageRow(
            number: '1',
            isDone: true,
            title: isAr
                ? 'توثيق الهوية بالبطاقة القطرية (QID) للطرفين'
                : 'Mutual Qatar ID (QID) Verification',
            subtitle: isAr
                ? '${ad.authorName} & عبدالرحمن المهنا · كلاهما موثق برقم قطري'
                : '${ad.authorName} & Abdelrahman · Both QID Verified',
          ),

          // Step 2
          _buildStageRow(
            number: '2',
            isDone: _escrowLocked,
            title: isAr
                ? 'حجز المبلغ في ضمان مشوار المالي (Escrow)'
                : 'Lock Agreed Amount in MASHWAR Escrow',
            subtitle: isAr
                ? 'لا يتحرك المنفّذ قبل التأكد من وجود كامل المبلغ في الخزينة'
                : 'Provider is guaranteed full funds are reserved beforehand',
            trailingAction: _escrowLocked
                ? null
                : TextButton(
                    onPressed: () => setState(() => _escrowLocked = true),
                    child: Text(isAr ? 'حجز المبلغ الآن' : 'Lock Funds'),
                  ),
          ),

          // Step 3: Live Store Receipt & Item Photo Proof
          _buildStageRow(
            number: '3',
            isDone: _receiptApproved,
            title: isAr
                ? 'توثيق صورة الغرض والفاتورة الأصلية'
                : 'Verify Item Photo & Original Receipt',
            subtitle: isAr
                ? 'للمشتريات ومواقع الهندسة: اعتماد الفاتورة يمنع اختلاف الأسعار'
                : 'For shopping & site supplies: approve receipt before dispatch',
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(start: 34, bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _receiptApproved ? AppColors.escrowSurface : AppColors.slateBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _receiptApproved
                    ? AppColors.escrowGreen.withValues(alpha: 0.4)
                    : AppColors.slateBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
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
                                ? 'معاينة فاتورة وصورة الشراء المرفقة'
                                : 'Attached Store Receipt & Item Preview',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            itemBudget > 0
                                ? (isAr
                                    ? 'فاتورة بقيمة ${(itemBudget * 0.92).round()} ر.ق ضمن السقف المحدد'
                                    : 'Receipt ${(itemBudget * 0.92).round()} QAR within approved cap')
                                : (isAr
                                    ? 'مستند / غرض مطابق للمواصفات المتفق عليها'
                                    : 'Item matches agreed specs'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildMiniReceiptTag(
                      isAr ? 'فاتورة #QA-8492' : 'Invoice #QA-8492',
                    ),
                    _buildMiniReceiptTag(
                      isAr ? 'صورة الغرض مرفقة ✓' : 'Item Photo ✓',
                    ),
                    _buildMiniReceiptTag(
                      isAr ? 'ختم توثيق QID' : 'QID Stamped',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _receiptApproved ? AppColors.escrowGreen : AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _receiptApproved = true);
                    },
                    icon: Icon(
                      _receiptApproved
                          ? Icons.check_circle_rounded
                          : Icons.fact_check_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _receiptApproved
                          ? (isAr
                              ? 'تم اعتماد الفاتورة وصورة الغرض ✓'
                              : 'Receipt & Item Approved ✓')
                          : (isAr
                              ? 'اعتماد الفاتورة وصورة الغرض'
                              : 'Approve Receipt & Photo'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Step 4: Live GPS Tracking Preview + Direct Chat + 1-Tap Google Maps
          _buildStageRow(
            number: '4',
            isDone: _receiptApproved,
            title: isAr
                ? 'التتبع الحي عبر GPS ومشاركة المسار'
                : 'Live GPS Tracking & Route Share',
            subtitle: isAr
                ? '${context.trCity(ad.fromCity)} ← ${context.trCity(ad.toCity)}'
                : '${context.trCity(ad.fromCity)} → ${context.trCity(ad.toCity)}',
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(start: 34, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.slateBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isAr ? 'الوصول المتوقع ~22 د' : 'ETA ~22 min',
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MashwarPageRoute(
                                builder: (_) => ChatScreen(
                                  driverName: ad.authorName,
                                  driverCar: ad.timeText,
                                  tripRoute: context.trRoute(ad.route),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? 'محادثة' : 'Chat',
                                  style: AppTypography.label(
                                    color: Colors.white,
                                  ).copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: MashwarEmbeddedGoogleMap(
                    key: const ValueKey('escrow_embedded_gmap'),
                    origin: ad.fromCity,
                    destination: ad.toCity,
                    stopover: ad.stopoverCity,
                    height: 175,
                    borderRadius: 12,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      key: const ValueKey('escrow_open_gmaps_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.slateBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          _openEscrowRouteInGoogleMaps(context, ad, isAr),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 15,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isAr
                                  ? 'تكبير الخريطة داخل التطبيق'
                                  : 'View Route Map In-App',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Step 5: 4-Digit OTP Settlement + Interactive Post-Completion Star Rating
          _buildStageRow(
            number: '5',
            isDone: _escrowReleased,
            title: isAr
                ? 'كود إتمام التسليم (4-Digit OTP) وتحرير الضمان'
                : '4-Digit Handover OTP Settlement',
            subtitle: isAr
                ? 'أدخل كود المستلم عند التسليم لتحرير أتعاب المنفّذ وقيمة الفاتورة فوراً'
                : 'Enter the 4-digit OTP at physical handover to release Escrow immediately',
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(start: 34),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _escrowReleased ? AppColors.escrowSurface : AppColors.slateBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _escrowReleased
                    ? AppColors.escrowGreen
                    : AppColors.slateBorder,
              ),
            ),
            child: _escrowReleased
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.escrowGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'تم التسليم وتحرير مبلغ الضمان بنجاح! شكراً لاستخدامك حماية مشوار.'
                                  : 'Handover complete & Escrow released! Protected by MASHWAR.',
                              style: AppTypography.label(
                                color: AppColors.escrowGreen,
                              ).copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: _ratingSubmitted
                            ? Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'شكراً! تم تسجيل تقييمك ($_selectedStars / 5 ★)'
                                          : 'Thank you! Rating ($_selectedStars / 5 ★) recorded.',
                                      style: AppTypography.label(
                                        color: AppColors.navy,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              )
                            : Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    isAr
                                        ? 'قيّم تجربتك مع الطرف الآخر:'
                                        : 'Rate your experience:',
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ).copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) {
                                      final star = i + 1;
                                      return GestureDetector(
                                        onTap: () =>
                                            setState(() => _selectedStars = star),
                                        child: Icon(
                                          star <= _selectedStars
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 20,
                                          color: AppColors.gold,
                                        ),
                                      );
                                    }),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                    ),
                                    onPressed: () =>
                                        setState(() => _ratingSubmitted = true),
                                    child: Text(
                                      isAr ? 'إرسال' : 'Submit',
                                      style: AppTypography.label(
                                        color: AppColors.teal,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Row(
                          children: [
                            MashwarQrMatrixWidget(
                              key: const ValueKey('escrow_handover_qr'),
                              data: 'MASHWAR|ESCROW|${ad.id}|4829',
                              size: 76,
                              showFrame: false,
                              moduleColor: AppColors.navy,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'امسح QR أو أدخل الكود 4829'
                                        : 'Scan QR or Enter OTP 4829',
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ).copyWith(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        key: const ValueKey(
                                          'escrow_scan_qr_btn',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.teal,
                                          side: const BorderSide(
                                            color: AppColors.teal,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () async {
                                          final scanned =
                                              await showMashwarQrScanSheet(
                                            context,
                                            isAr: isAr,
                                            referenceId: ad.id,
                                            expectedLength: 4,
                                            demoScannedCode: '4829',
                                          );
                                          if (scanned != null && mounted) {
                                            setState(() {
                                              _otpController.text = scanned;
                                              _otpError = null;
                                            });
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          size: 14,
                                        ),
                                        label: Text(
                                          isAr ? 'مسح QR' : 'Scan QR',
                                          style: AppTypography.label(
                                            color: AppColors.teal,
                                          ).copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        key: const ValueKey(
                                          'escrow_contingency_btn',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.warning,
                                          side: BorderSide(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.55),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            showMashwarHandoverContingencySheet(
                                          context,
                                          isAr: isAr,
                                          referenceId: ad.id,
                                          handoverCode: '4829',
                                        ),
                                        icon: const Icon(
                                          Icons.battery_alert_rounded,
                                          size: 14,
                                        ),
                                        label: Text(
                                          isAr ? 'حلول بديلة' : 'Fallbacks',
                                          style: AppTypography.label(
                                            color: AppColors.warning,
                                          ).copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                labelText: isAr
                                    ? 'كود الإتمام (4 أرقام)'
                                    : '4-Digit OTP',
                                hintText: '4829',
                                errorText: _otpError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.slateBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.slateBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _otpController.text = '4829';
                                _otpError = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.slateBorder,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isAr ? 'تعبئة 4829' : 'Fill 4829',
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MashwarButton(
                        text: isAr
                            ? 'تأكيد الكود وتحرير المستحقات'
                            : 'Verify OTP & Release Escrow',
                        onPressed: () => _releaseEscrowWithOtp(isAr),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageRow({
    required String number,
    required bool isDone,
    required String title,
    required String subtitle,
    Widget? trailingAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? AppColors.escrowGreen : AppColors.cobaltSurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : Text(
                      number,
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(),
                ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
        ],
      ),
    );
  }

  Widget _buildMiniReceiptTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Text(
        label,
        style: AppTypography.label(color: AppColors.navy)
            .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildBottomArbitrationBar(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          final msgRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: AppColors.navy,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'في حال أي اختلاف في الغرض أو السعر، جمّد الضمان بضغطة واحدة.'
                      : 'Notice a mismatch? Freeze Escrow immediately for arbitration.',
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
          final disputeBtn = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.slateBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _openDisputeDialog(isAr),
            icon: const Icon(Icons.gavel_rounded, size: 16),
            label: Text(
              isAr ? 'تجميد الضمان وفتح نزاع' : 'Freeze & Dispute',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                msgRow,
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: disputeBtn,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: msgRow),
              const SizedBox(width: 12),
              disputeBtn,
            ],
          );
        },
      ),
    );
  }
}
