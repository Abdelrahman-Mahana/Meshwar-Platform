import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  void _showWithdrawSheet(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final isAr = settings.isArabic;
    final TextEditingController amountController = TextEditingController(text: '100');
    final TextEditingController targetController = TextEditingController(text: auth.user.phone);
    final channels = isAr
        ? ['فوراً (Fawran)', 'كيوباي (QPay)', 'سكيب كاش (SkipCash)']
        : ['Fawran (QCB)', 'QPay', 'SkipCash'];
    String selectedChannel = channels.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppDimens.space24,
                right: AppDimens.space24,
                top: AppDimens.space24,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'سحب رصيد إلى حسابك' : 'Withdraw Wallet Balance',
                    style: AppTypography.title(),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    isAr
                        ? 'الرصيد المتاح للسحب: ${auth.user.walletBalance.toStringAsFixed(0)} ر.ق'
                        : 'Available: ${auth.user.walletBalance.toStringAsFixed(0)} QAR',
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Wrap(
                    spacing: 8,
                    children: channels.map((channel) {
                      final isSel = selectedChannel == channel;
                      return ChoiceChip(
                        label: Text(channel),
                        selected: isSel,
                        selectedColor: AppColors.tealSurface,
                        onSelected: (_) => setSheetState(() => selectedChannel = channel),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isAr ? 'المبلغ (ر.ق)' : 'Amount (QAR)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  TextField(
                    controller: targetController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'رقم الجوال المرتبط بـ فوراً أو IBAN' : 'Fawran Alias, Mobile or IBAN',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space20),
                  MashwarButton(
                    text: isAr ? 'تأكيد طلب السحب الفوري' : 'Confirm Withdrawal',
                    onPressed: () {
                      final amount = double.tryParse(amountController.text.trim()) ?? 0;
                      final ok = auth.withdrawWalletFunds(
                        amount: amount,
                        destinationAr: '$selectedChannel (${targetController.text.trim()})',
                        destinationEn: '$selectedChannel (${targetController.text.trim()})',
                      );
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? (isAr ? 'تم تحويل $amount ر.ق بنجاح عبر $selectedChannel' : 'Withdrawn $amount QAR via $selectedChannel')
                                : (isAr ? 'الرصيد غير كافٍ لإتمام عملية السحب' : 'Insufficient wallet balance'),
                          ),
                          backgroundColor: ok ? AppColors.teal : AppColors.danger,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFundsSheet(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final isAr = settings.isArabic;
    int selectedAmount = 100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'شحن رصيد المحفظة' : 'Add Wallet Balance',
                      style: AppTypography.title(),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      isAr ? 'اختر المبلغ للشحن الفوري عبر خدمة فوراً أو البطاقة' : 'Select amount to top-up via Fawran or QPay',
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Quick Amounts
                    Row(
                      children: [50, 100, 200, 500].map((amount) {
                        final isSel = selectedAmount == amount;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedAmount = amount),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.navy : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? AppColors.navy : AppColors.borderDisabled,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$amount ${isAr ? 'ر.ق' : 'QAR'}',
                                    style: TextStyle(
                                      color: isSel ? Colors.white : AppColors.navy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppDimens.space24),

                    // Payment Method selector inside sheet
                    Text(
                      isAr ? 'طريقة الدفع' : 'Payment Method',
                      style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.teal),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr ? 'فوراً Fawran (تحويل لحظي عبر مصرف قطر المركزي)' : 'Fawran (Instant QCB Transfer)',
                              style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: AppColors.teal),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.space24),

                    MashwarButton(
                      text: isAr ? 'تأكيد الشحن بمبلغ $selectedAmount ر.ق' : 'Confirm Deposit of $selectedAmount QAR',
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        auth.depositWalletFunds(
                          amount: selectedAmount.toDouble(),
                          methodAr: 'فوراً Fawran',
                          methodEn: 'Fawran Instant',
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'تم شحن المحفظة بنجاح بمبلغ $selectedAmount ر.ق' : 'Wallet topped up with $selectedAmount QAR'),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'محفظة مشوار' : 'MASHWAR Wallet',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;

            final balanceCard = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, Color(0xFF1B4368)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const MashwarPinIcon(size: 18, isLight: true),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isAr ? 'الرصيد المتاح' : 'Available Balance',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySecondary(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, color: AppColors.gold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'آمن ومشفر' : 'Encrypted',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          user.walletBalance.toStringAsFixed(2),
                          style: AppTypography.largeTitle(color: Colors.white).copyWith(fontSize: 34),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'ريال قطري' : 'QAR',
                          style: AppTypography.title(color: AppColors.gold).copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.space20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.navy,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          label: Text(
                            isAr ? 'شحن رصيد' : 'Deposit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _showAddFundsSheet(context),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                          label: Text(
                            isAr ? 'سحب رصيد' : 'Withdraw',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _showWithdrawSheet(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final paymentMethodsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'طرق الدفع المدعومة في قطر' : 'Qatar Payment Methods',
                  style: AppTypography.title().copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppDimens.space12),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    side: const BorderSide(color: AppColors.borderDisabled),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildPaymentTile(
                        icon: Icons.flash_on_rounded,
                        iconColor: const Color(0xFF8A1538),
                        title: isAr ? 'فوراً Fawran (التحويل اللحظي)' : 'Fawran (QCB Instant Transfer)',
                        subtitle: isAr ? 'تحويل بنكي فوري في قطر بدون رسوم إضافية' : 'Instant zero-fee bank transfer in Qatar',
                        isDefault: auth.selectedPaymentMethod == 'fawran',
                        onTap: () => auth.setSelectedPaymentMethod('fawran'),
                      ),
                      const Divider(height: 1, color: AppColors.borderDisabled),
                      _buildPaymentTile(
                        icon: Icons.credit_card_rounded,
                        iconColor: AppColors.teal,
                        title: isAr ? 'كيوباي QPay وبطاقات البنوك القطرية' : 'QPay Debit & Qatari Bank Cards',
                        subtitle: isAr ? 'بطاقة هميان الوطنية، QPay، فيزا وماستركارد' : 'Himyan National Card, QPay, Visa & Mastercard',
                        isDefault: auth.selectedPaymentMethod == 'qpay',
                        onTap: () => auth.setSelectedPaymentMethod('qpay'),
                      ),
                      const Divider(height: 1, color: AppColors.borderDisabled),
                      _buildPaymentTile(
                        icon: Icons.phone_android_rounded,
                        iconColor: const Color(0xFF1D4ED8),
                        title: isAr ? 'سكيب كاش SkipCash و Apple Pay' : 'SkipCash & Apple Pay',
                        subtitle: isAr ? 'دفع رقمي فوري عبر الهاتف في قطر' : 'Instant mobile digital payment in Qatar',
                        isDefault: auth.selectedPaymentMethod == 'skipcash',
                        onTap: () => auth.setSelectedPaymentMethod('skipcash'),
                      ),
                      const Divider(height: 1, color: AppColors.borderDisabled),
                      _buildPaymentTile(
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.gold,
                        title: isAr ? 'الدفع نقداً' : 'Cash upon meeting',
                        subtitle: isAr ? 'دفع قيمة المقعد أو شحن الطرد باليد للسائق' : 'Pay in cash directly to the driver',
                        isDefault: auth.selectedPaymentMethod == 'cash',
                        onTap: () => auth.setSelectedPaymentMethod('cash'),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final transactionsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'سجل العمليات الأخير' : 'Recent Transactions',
                  style: AppTypography.title().copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppDimens.space12),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    side: const BorderSide(color: AppColors.borderDisabled),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: auth.walletTransactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderDisabled),
                    itemBuilder: (context, index) {
                      final tx = auth.walletTransactions[index];
                      final rawAmount = tx['amount'];
                      final isPositive = tx['isPositive'] is bool
                          ? tx['isPositive'] as bool
                          : (rawAmount is num
                              ? rawAmount > 0
                              : rawAmount.toString().trim().startsWith('+'));
                      final title = isAr
                          ? (tx['titleAr'] ?? tx['title'] ?? '').toString()
                          : (tx['titleEn'] ?? tx['titleAr'] ?? tx['title'] ?? '').toString();
                      final date = isAr
                          ? (tx['date'] ?? '').toString()
                          : (tx['dateEn'] ?? tx['date'] ?? '').toString();
                      final String amountLabel;
                      if (tx['amountValue'] is num) {
                        final val = (tx['amountValue'] as num).abs();
                        final formatted = val == val.roundToDouble()
                            ? val.toStringAsFixed(0)
                            : val.toStringAsFixed(2);
                        amountLabel = '${isPositive ? '+' : '-'}$formatted ${isAr ? 'ر.ق' : 'QAR'}';
                      } else if (rawAmount is num) {
                        final val = rawAmount.abs();
                        final formatted = val == val.roundToDouble()
                            ? val.toStringAsFixed(0)
                            : val.toStringAsFixed(2);
                        amountLabel = '${isPositive ? '+' : '-'}$formatted ${isAr ? 'ر.ق' : 'QAR'}';
                      } else {
                        final str = rawAmount?.toString() ?? '0';
                        amountLabel = isAr
                            ? (str.contains('ر.ق') ? str : '${str.replaceAll('ج.م', '').trim()} ر.ق')
                            : str.replaceAll('ر.ق', 'QAR').replaceAll('ج.م', 'QAR');
                      }
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPositive ? AppColors.tealSurface : AppColors.sand,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isPositive ? AppColors.teal : AppColors.navy,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          title,
                          style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          date,
                          style: AppTypography.label(),
                        ),
                        trailing: Text(
                          amountLabel,
                          style: TextStyle(
                            color: isPositive ? AppColors.teal : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1160 : 680),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  balanceCard,
                                  const SizedBox(height: AppDimens.space24),
                                  paymentMethodsSection,
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimens.space24),
                            Expanded(
                              flex: 6,
                              child: transactionsSection,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            balanceCard,
                            const SizedBox(height: AppDimens.space24),
                            paymentMethodsSection,
                            const SizedBox(height: AppDimens.space24),
                            transactionsSection,
                            const SizedBox(height: AppDimens.space24),
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

  Widget _buildPaymentTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDefault,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: AppTypography.label()),
      trailing: isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.teal),
              ),
              child: Text(
                context.read<SettingsProvider>().isArabic ? 'أساسي' : 'Default',
                style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
    );
  }
}
