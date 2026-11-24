import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../data/mock_data.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/settings_provider.dart';

/// Bilateral Anti-Fraud & Smart Service Escrow Screen ("نظام ضمان مشوار لحفظ حق الطرفين").
///
/// Guarantees:
/// 1. Requester Protection: Funds + item purchase budget remain frozen in MASHWAR Escrow;
///    store receipt & item photos require approval before handover; 4-digit OTP unlocks release.
/// 2. Provider Protection: Agreed service fee + item cap are verified & locked in Escrow
///    before driving or paying at any store, plus 1-tap fair dispute arbitration.
class ServiceEscrowScreen extends StatefulWidget {
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
  final TextEditingController _otpController = TextEditingController();
  String? _otpError;

  BoardAdModel get _activeAd => widget.ad ?? MockData.initialBoardAds.first;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.qatarMaroon, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr ? 'تجميد الضمان وفتح نزاع محايد' : 'Freeze Escrow & Dispute Arbitration',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'عند تفعيل التجميد، يوقف مشوار تحويل أي مبلغ من الضمان فوراً لحين مراجعة سجل الدردشة، صورة الفاتورة، إحداثيات GPS، والهوية القطرية QID لكلا الطرفين خلال 2 ساعة.'
              : 'Freezing immediately pauses all Escrow transfers while MASHWAR Trust & Safety audits chat logs, receipt photos, GPS trail, and QID verification within 2 hours.',
          style: AppTypography.bodySecondary(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.qatarMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  backgroundColor: AppColors.qatarMaroon,
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
    final isAr = context.watch<SettingsProvider>().isArabic;
    final ad = _activeAd;
    final serviceFee = ad.priceOrBudget;
    final itemBudget = ad.estimatedItemCost ?? (ad.requiresReceiptProof ? 150 : 0);
    final totalLocked = serviceFee + itemBudget;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.qatarMaroon, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isAr ? 'الضمان المالي وحماية الطرفين' : 'Bilateral Escrow Shield',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title().copyWith(fontSize: 17),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
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
                      // 1. Hero Shield Card + Qatari Al-Adaam Sadu Ribbon
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
                          isAr,
                          ad: ad,
                          itemBudget: itemBudget,
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Emergency & Dispute Arbitration Strip
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
          colors: [AppColors.navy, Color(0xFF1A2847), AppColors.qatarMaroonDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const QatarSaduAccentBar(height: 5, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MashwarLivePulseDot(color: AppColors.gold, size: 7),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isAr ? 'عقد مشوار الذكي · قطر' : 'MASHWAR Smart Escrow · Qatar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
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
                        style: AppTypography.title(color: Colors.white).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${ad.displaySubTag(isAr)} · ${context.trRoute(ad.route)} ($totalLocked ${isAr ? "ر.ق" : "QAR"})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  child: const MashwarAssetArt(
                    assetPath: 'assets/images/escrow_trust_shield.jpg',
                    width: 82,
                    height: 82,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    fallbackIcon: Icons.shield_rounded,
                    fallbackColor: AppColors.qatarMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrozenAlertBanner(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.qatarMaroonSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.qatarMaroon.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: AppColors.qatarMaroon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'حساب الضمان مجمّد قيد المراجعة المحايدة من فريق ثقة مشوار — لن يُصرف أي ريال قبل الفصل.'
                  : 'Escrow frozen under neutral MASHWAR arbitration — zero funds move until resolved.',
              style: AppTypography.bodySmall(color: AppColors.qatarMaroonDark).copyWith(
                fontWeight: FontWeight.w800,
              ),
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
              isAr ? 'مبلغك محفوظ بالضمان وليس بيد المنفّذ' : 'Funds stay locked in Escrow',
              isAr
                  ? 'لا يذهب أي مبلغ لحساب المنفّذ مقدمًا قبل استلامك وموافقتك.'
                  : 'Zero payout upfront until handover is confirmed.',
            ),
            (
              Icons.receipt_long_rounded,
              isAr ? 'تصوير الفاتورة الأصلية والغرض قبل التحرك' : 'Live receipt & item photo check',
              isAr
                  ? 'تشاهد صورة الغرض وفاتورة المحل وتعتمدها بنقرة قبل الدفع.'
                  : 'Inspect the bought item & store invoice before dispatch.',
            ),
            (
              Icons.pin_rounded,
              isAr ? 'كود الاستلام OTP بيدك وحدك' : '4-digit OTP strictly in your hands',
              isAr
                  ? 'أعطِ المنفّذ كود الإتمام فقط عند تسليم الغرض أو وصول المشوار.'
                  : 'Release funds only after physical verification.',
            ),
          ]
        : [
            (
              Icons.verified_rounded,
              isAr ? 'مستحقاتك + ميزانية الشراء محجوزة مسبقاً' : 'Fee + purchase cap locked upfront',
              isAr
                  ? 'لن تشتري غرضاً أو تتحرك إلا والمبلغ محجوز ومؤكد في الضمان عبر فوراً.'
                  : 'Never spend upfront without verified Escrow backing.',
            ),
            (
              Icons.no_encryption_gmailerrorred_outlined,
              isAr ? 'حماية تامة من التراجع أو رفض الاستلام' : 'Protection against cancellation/ghosting',
              isAr
                  ? 'بمجرد اعتماد الطالب للفاتورة بالصورة، لا يمكنه إلغاء الطلب بدون تعويضك.'
                  : 'Once receipt is approved, cancellation cannot forfeit your fee.',
            ),
            (
              Icons.flash_on_rounded,
              isAr ? 'تحويل فوري لمحفظتك بمجرد إدخال OTP' : 'Instant payout on OTP entry',
              isAr
                  ? 'فور تسليم الطلب وإدخال الكود يدخل أتعابك وقيمة الفاتورة لحسابك مباشرة.'
                  : 'Escrow credits your wallet the second OTP matches.',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'كيف نضمن حق الطرفين ومنع النصب؟' : 'How Both Parties Are Protected',
            style: AppTypography.title().copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildRoleSegmentBtn(
                    label: isAr ? 'حماية طالب الخدمة' : 'Requester Shield',
                    selected: _viewAsRequester,
                    activeColor: AppColors.qatarMaroon,
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
                          ? AppColors.qatarMaroonSurface
                          : AppColors.tealSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      pt.$1,
                      size: 16,
                      color: _viewAsRequester ? AppColors.qatarMaroon : AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pt.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pt.$3,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                            height: 1.35,
                          ),
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
          border: selected ? Border.all(color: activeColor.withValues(alpha: 0.45)) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? activeColor : AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
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
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: AppColors.navy, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'ملخص خزينة الضمان المعلّق (Escrow)' : 'Escrow Vault Breakdown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFinanceRow(
            label: isAr ? 'أتعاب المشوار / التوصيل المتفق عليها' : 'Agreed Service / Delivery Fee',
            value: '$serviceFee ${isAr ? "ر.ق" : "QAR"}',
          ),
          if (itemBudget > 0) ...[
            const SizedBox(height: 6),
            _buildFinanceRow(
              label: isAr ? 'سقف فاتورة المشتريات المودع بالضمان' : 'Reserved Store Receipt Budget',
              value: '$itemBudget ${isAr ? "ر.ق" : "QAR"}',
            ),
          ],
          const Divider(height: 18, color: Color(0xFFD6CBB5)),
          _buildFinanceRow(
            label: isAr ? 'إجمالي المحجوز في الضمان' : 'Total Protected in Escrow',
            value: '$totalLocked ${isAr ? "ر.ق" : "QAR"}',
            isHighlight: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _escrowReleased
                      ? Icons.check_circle_rounded
                      : (_escrowLocked ? Icons.lock_rounded : Icons.lock_open_rounded),
                  size: 16,
                  color: _escrowReleased
                      ? AppColors.escrowGreen
                      : (_escrowLocked ? AppColors.teal : AppColors.warning),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _escrowReleased
                        ? (isAr ? 'تم تحرير المستحقات بالكامل بعد مطابقة OTP' : 'Escrow settled after OTP match')
                        : (_escrowLocked
                            ? (isAr
                                ? 'محجوز عبر فوراً Fawran / محفظة مشوار (جاهز للتنفيذ)'
                                : 'Locked via Fawran / Wallet — Ready to execute')
                            : (isAr ? 'في انتظار تأمين المبلغ' : 'Awaiting Escrow Lock')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontFamily: 'Cairo',
                    ),
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
            style: TextStyle(
              fontSize: isHighlight ? 13 : 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppColors.navy : AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 13,
            fontWeight: FontWeight.w900,
            color: isHighlight ? AppColors.escrowGreen : AppColors.navy,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildFiveStageExecutionCard(
    bool isAr, {
    required BoardAdModel ad,
    required int itemBudget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'مراحل التنفيذ الموثّقة خطوة بخطوة' : '5-Stage Anti-Fraud Execution',
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
            title: isAr ? 'توثيق الهوية بالبطاقة القطرية (QID) للطرفين' : 'Mutual Qatar ID (QID) Verification',
            subtitle: isAr
                ? '${ad.authorName} & عبدالرحمن المهنا · كلاهما موثق برقم قطري'
                : '${ad.authorName} & Abdelrahman · Both QID Verified',
          ),

          // Step 2
          _buildStageRow(
            number: '2',
            isDone: _escrowLocked,
            title: isAr ? 'حجز المبلغ في ضمان مشوار المالي (Escrow)' : 'Lock Agreed Amount in MASHWAR Escrow',
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
            title: isAr ? 'توثيق صورة الغرض والفاتورة الأصلية' : 'Verify Item Photo & Original Receipt',
            subtitle: isAr
                ? 'للمشتريات ومواقع الهندسة: اعتماد الفاتورة يمنع اختلاف الأسعار'
                : 'For shopping & site supplies: approve receipt before dispatch',
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(start: 34, bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _receiptApproved ? AppColors.escrowSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _receiptApproved
                    ? AppColors.escrowGreen.withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.navy, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'معاينة فاتورة وصورة الشراء المرفقة' : 'Attached Store Receipt & Item Preview',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            itemBudget > 0
                                ? (isAr
                                    ? 'فاتورة بقيمة ${(itemBudget * 0.92).round()} ر.ق ضمن السقف المحدد'
                                    : 'Receipt ${(itemBudget * 0.92).round()} QAR within approved cap')
                                : (isAr ? 'مستند / غرض مطابق للمواصفات المتفق عليها' : 'Item matches agreed specs'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _receiptApproved ? AppColors.escrowGreen : AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _receiptApproved = true);
                    },
                    icon: Icon(
                      _receiptApproved ? Icons.check_circle_rounded : Icons.fact_check_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _receiptApproved
                          ? (isAr ? 'تم اعتماد الفاتورة وصورة الغرض ✓' : 'Receipt & Item Approved ✓')
                          : (isAr ? 'اعتماد الفاتورة وصورة الغرض' : 'Approve Receipt & Photo'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Step 4: Live GPS Tracking Preview
          _buildStageRow(
            number: '4',
            isDone: _receiptApproved,
            title: isAr ? 'التتبع الحي عبر GPS ومشاركة المسار' : 'Live GPS Tracking & Route Share',
            subtitle: isAr
                ? '${context.trCity(ad.fromCity)} ← ${context.trCity(ad.toCity)}'
                : '${context.trCity(ad.fromCity)} → ${context.trCity(ad.toCity)}',
          ),
          Container(
            height: 112,
            margin: const EdgeInsetsDirectional.only(start: 34, bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: QatarLiveMapCanvas(
              style: QatarMapStyle.routeFocused,
              activeFromCity: ad.fromCity,
              activeToCity: ad.toCity,
              borderRadius: 13,
            ),
          ),

          // Step 5: 4-Digit OTP Settlement
          _buildStageRow(
            number: '5',
            isDone: _escrowReleased,
            title: isAr ? 'كود إتمام التسليم (4-Digit OTP) وتحرير الضمان' : '4-Digit Handover OTP Settlement',
            subtitle: isAr
                ? 'أدخل كود المستلم عند التسليم لتحرير أتعاب المنفّذ وقيمة الفاتورة فوراً'
                : 'Enter the 4-digit OTP at physical handover to release Escrow immediately',
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(start: 34),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _escrowReleased ? AppColors.escrowSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _escrowReleased ? AppColors.escrowGreen : const Color(0xFFE2E8F0),
              ),
            ),
            child: _escrowReleased
                ? Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.escrowGreen, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'تم التسليم وتحرير مبلغ الضمان بنجاح! شكراً لاستخدامك حماية مشوار.'
                              : 'Handover complete & Escrow released! Protected by MASHWAR.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.escrowGreen,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                counterText: '',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                labelText: isAr ? 'كود الإتمام (4 أرقام)' : '4-Digit OTP',
                                hintText: '4829',
                                errorText: _otpError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              isAr ? 'تعبئة 4829' : 'Fill 4829',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MashwarButton(
                        text: isAr ? 'تأكيد الكود وتحرير المستحقات' : 'Verify OTP & Release Escrow',
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
              color: isDone ? AppColors.escrowGreen : AppColors.navy.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text(
                      number,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
        ],
      ),
    );
  }

  Widget _buildBottomArbitrationBar(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          final msgRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.support_agent_rounded, color: AppColors.qatarMaroon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'في حال أي اختلاف في الغرض أو السعر، جمّد الضمان بضغطة واحدة.'
                      : 'Notice a mismatch? Freeze Escrow immediately for arbitration.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          );
          final disputeBtn = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.qatarMaroon,
              side: BorderSide(color: AppColors.qatarMaroon.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _openDisputeDialog(isAr),
            icon: const Icon(Icons.gavel_rounded, size: 16),
            label: Text(
              isAr ? 'تجميد الضمان وفتح نزاع' : 'Freeze & Dispute',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                msgRow,
                const SizedBox(height: 10),
                Align(alignment: AlignmentDirectional.centerEnd, child: disputeBtn),
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
