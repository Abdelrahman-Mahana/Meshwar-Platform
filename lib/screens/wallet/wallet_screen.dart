import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'حجز مقعد: القاهرة ← طنطا',
      'titleEn': 'Seat Booking: Cairo → Tanta',
      'date': 'اليوم، 10:30 ص',
      'dateEn': 'Today, 10:30 AM',
      'amount': -65.0,
      'isRide': true,
    },
    {
      'title': 'شحن رصيد عبر إنستاباي InstaPay',
      'titleEn': 'Deposit via InstaPay IPN',
      'date': '5 نوفمبر، 4:15 م',
      'dateEn': 'Nov 5, 4:15 PM',
      'amount': 200.0,
      'isRide': false,
    },
    {
      'title': 'توصيل طرد: كفر الشيخ ← الإسكندرية',
      'titleEn': 'Parcel Delivery: Kafr El-Sheikh → Alex',
      'date': '3 نوفمبر، 2:00 م',
      'dateEn': 'Nov 3, 2:00 PM',
      'amount': 120.0,
      'isRide': false,
    },
    {
      'title': 'استرداد إلغاء رحلة المنصورة',
      'titleEn': 'Refund: Mansoura Ride Cancelled',
      'date': '1 نوفمبر، 9:00 ص',
      'dateEn': 'Nov 1, 9:00 AM',
      'amount': 75.0,
      'isRide': true,
    },
  ];

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
                      isAr ? 'اختر المبلغ للشحن الفوري عبر إنستاباي أو المحفظة الذكية' : 'Select amount to top-up via InstaPay or Mobile Wallet',
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Quick Amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [50, 100, 200, 500].map((amount) {
                        final isSel = selectedAmount == amount;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedAmount = amount),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.navy : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? AppColors.navy : AppColors.borderDisabled,
                              ),
                            ),
                            child: Text(
                              '$amount ${isAr ? 'ج.م' : 'EGP'}',
                              style: TextStyle(
                                color: isSel ? Colors.white : AppColors.navy,
                                fontWeight: FontWeight.bold,
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
                              isAr ? 'إنستاباي InstaPay (تحويل لحظي مباشر)' : 'InstaPay (Instant Bank Transfer)',
                              style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: AppColors.teal),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.space24),

                    MashwarButton(
                      text: isAr ? 'تأكيد الشحن بمبلغ $selectedAmount ج.م' : 'Confirm Deposit of $selectedAmount EGP',
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        final newBalance = auth.user.walletBalance + selectedAmount;
                        auth.updateWalletBalance(newBalance);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'تم شحن المحفظة بنجاح بمبلغ $selectedAmount ج.م' : 'Wallet topped up with $selectedAmount EGP'),
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
      backgroundColor: Colors.white,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Container(
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
                        Text(
                          isAr ? 'الرصيد المتاح' : 'Available Balance',
                          style: AppTypography.bodySecondary(color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.shield_rounded, color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text('آمن ومشفر', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          user.walletBalance.toStringAsFixed(2),
                          style: AppTypography.largeTitle(color: Colors.white).copyWith(fontSize: 34),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'جنيه مصري' : 'EGP',
                          style: AppTypography.title(color: AppColors.gold).copyWith(fontSize: 18),
                        ),
                      ],
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'يمكنك سحب أرباحك إلى حسابك البنكي أو محفظتك خلال 24 ساعة' : 'Payout will be sent within 24 hours'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // Egyptian Payment Methods Section
              Text(
                isAr ? 'طرق الدفع المدعومة في مصر' : 'Egyptian Payment Methods',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppDimens.space12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  children: [
                    _buildPaymentTile(
                      icon: Icons.flash_on_rounded,
                      iconColor: const Color(0xFF6A1B9A),
                      title: isAr ? 'إنستاباي InstaPay (IPN)' : 'InstaPay (IPN)',
                      subtitle: isAr ? 'تحويل بنكي فوري بدون مصاريف إضافية' : 'Instant free bank transfer',
                      isDefault: true,
                    ),
                    const Divider(height: 1, color: AppColors.borderDisabled),
                    _buildPaymentTile(
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFFE53935),
                      title: isAr ? 'فودافون كاش والمحافظ الذكية' : 'Vodafone Cash & Mobile Wallets',
                      subtitle: isAr ? 'فودافون، أورنج، اتصالات، وي باي' : 'Vodafone, Orange, Etisalat, WE Pay',
                      isDefault: false,
                    ),
                    const Divider(height: 1, color: AppColors.borderDisabled),
                    _buildPaymentTile(
                      icon: Icons.credit_card_rounded,
                      iconColor: AppColors.teal,
                      title: isAr ? 'بطاقات ميزة والفيزا والماستركارد' : 'Meeza & Bank Cards',
                      subtitle: isAr ? 'دفع آمن بالبطاقات الائتمانية والخصم المباشر' : 'Debit/Credit & Meeza cards',
                      isDefault: false,
                    ),
                    const Divider(height: 1, color: AppColors.borderDisabled),
                    _buildPaymentTile(
                      icon: Icons.payments_outlined,
                      iconColor: AppColors.gold,
                      title: isAr ? 'الدفع كاش نقداً' : 'Cash upon meeting',
                      subtitle: isAr ? 'دفع قيمة المقعد أو شحن الطرد باليد للسائق' : 'Pay in cash directly to the driver',
                      isDefault: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // Recent Transactions History
              Text(
                isAr ? 'سجل العمليات الأخير' : 'Recent Transactions',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppDimens.space12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderDisabled),
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final isPositive = (tx['amount'] as double) > 0;
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
                        isAr ? tx['title'] : tx['titleEn'],
                        style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        isAr ? tx['date'] : tx['dateEn'],
                        style: AppTypography.label(),
                      ),
                      trailing: Text(
                        '${isPositive ? '+' : ''}${tx['amount']} ${isAr ? 'ج.م' : 'EGP'}',
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

              const SizedBox(height: AppDimens.space24),
            ],
          ),
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
  }) {
    return ListTile(
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
              child: const Text('أساسي', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : const Icon(Icons.chevron_left_rounded, color: AppColors.borderDisabled),
    );
  }
}
