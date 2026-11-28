import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../escrow/service_escrow_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().syncWalletFromRepository();
    });
  }

  void _showWithdrawSheet(BuildContext parentContext) {
    final settings = parentContext.read<SettingsProvider>();
    final auth = parentContext.read<AuthProvider>();
    final isAr = settings.isArabic;
    final amountController = TextEditingController(text: '100');
    final targetController = TextEditingController(
      text: auth.user.phone.trim().isNotEmpty ? auth.user.phone.trim() : '+974 55123456',
    );
    final channels = [
      ('fawran', isAr ? 'فوراً (Fawran)' : 'Fawran (QCB)'),
      ('qpay', isAr ? 'كيوباي (QPay)' : 'QPay'),
      ('skipcash', isAr ? 'سكيب كاش (SkipCash)' : 'SkipCash'),
    ];
    String selectedChannelKey = channels.first.$1;
    String? errorText;
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final availableBalance = auth.user.walletBalance;
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppDimens.space24,
                  right: AppDimens.space24,
                  top: AppDimens.space16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                      AppDimens.space24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MashwarSheetHeader(
                      title: isAr ? 'سحب رصيد إلى حسابك' : 'Withdraw Wallet Balance',
                      subtitle: isAr
                          ? 'الرصيد المتاح للسحب: ${availableBalance.toStringAsFixed(0)} ر.ق'
                          : 'Available balance: ${availableBalance.toStringAsFixed(0)} QAR',
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Text(
                      isAr ? 'قناة التحويل' : 'Transfer Channel',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: channels.map((ch) {
                        final isSel = selectedChannelKey == ch.$1;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setSheetState(() {
                            selectedChannelKey = ch.$1;
                            errorText = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.navy : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? AppColors.navy : AppColors.slateBorder,
                              ),
                            ),
                            child: Text(
                              ch.$2,
                              style: AppTypography.label(
                                color: isSel ? Colors.white : AppColors.navy,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimens.space14),
                    TextField(
                      key: const ValueKey('wallet_withdraw_amount_input'),
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        if (errorText != null) {
                          setSheetState(() => errorText = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isAr ? 'المبلغ (ر.ق)' : 'Amount (QAR)',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.slateBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.navy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    TextField(
                      key: const ValueKey('wallet_withdraw_dest_input'),
                      controller: targetController,
                      onChanged: (_) {
                        if (errorText != null) {
                          setSheetState(() => errorText = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'رقم الجوال المرتبط بـ فوراً أو IBAN'
                            : 'Fawran Alias, Mobile or IBAN',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.slateBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.navy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          errorText!,
                          style: AppTypography.label(color: AppColors.danger).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.space20),
                    MashwarButton(
                      key: const ValueKey('wallet_confirm_withdraw_btn'),
                      text: isAr ? 'تأكيد طلب السحب الفوري' : 'Confirm Withdrawal',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text.trim()) ?? 0;
                        final dest = targetController.text.trim();
                        if (amount <= 0) {
                          setSheetState(() {
                            errorText = isAr
                                ? 'يرجى إدخال مبلغ صحيح أكبر من صفر'
                                : 'Please enter a valid amount greater than zero';
                          });
                          return;
                        }
                        if (dest.length < 4) {
                          setSheetState(() {
                            errorText = isAr
                                ? 'يرجى إدخال رقم الجوال أو حساب IBAN صحيح'
                                : 'Please enter a valid mobile alias or IBAN';
                          });
                          return;
                        }
                        if (amount > auth.user.walletBalance) {
                          setSheetState(() {
                            errorText = isAr
                                ? 'الرصيد المتاح (${auth.user.walletBalance.toStringAsFixed(0)} ر.ق) غير كافٍ للسحب'
                                : 'Insufficient available balance (${auth.user.walletBalance.toStringAsFixed(0)} QAR)';
                          });
                          return;
                        }

                        setSheetState(() => isSubmitting = true);
                        final chosen = channels
                            .firstWhere((c) => c.$1 == selectedChannelKey);
                        final ok = await auth.withdrawFromWallet(
                          amount: amount,
                          methodKey: selectedChannelKey,
                          destinationAccount: '${chosen.$2} ($dest)',
                          destinationAr: '${chosen.$2} ($dest)',
                          destinationEn: '${chosen.$2} ($dest)',
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!parentContext.mounted) return;
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? (isAr
                                      ? 'تم تحويل ${amount.toStringAsFixed(0)} ر.ق بنجاح عبر ${chosen.$2}'
                                      : 'Withdrawn ${amount.toStringAsFixed(0)} QAR via ${chosen.$2}')
                                  : (isAr
                                      ? 'الرصيد غير كافٍ لإتمام عملية السحب'
                                      : 'Insufficient wallet balance'),
                            ),
                            backgroundColor: ok ? AppColors.teal : AppColors.danger,
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
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        amountController.dispose();
        targetController.dispose();
      });
    });
  }

  void _showAddFundsSheet(BuildContext parentContext) {
    final settings = parentContext.read<SettingsProvider>();
    final isAr = settings.isArabic;
    int selectedAmount = 100;
    final customAmountController = TextEditingController(text: '100');
    String selectedChannel = 'fawran';
    String? errorText;
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final channels = [
              (
                'fawran',
                Icons.flash_on_rounded,
                isAr ? 'فوراً Fawran (تحويل لحظي)' : 'Fawran Instant',
                'Fawran',
              ),
              (
                'qpay',
                Icons.credit_card_rounded,
                isAr ? 'كيوباي QPay / هميان' : 'QPay / Himyan Card',
                'QPay',
              ),
              (
                'skipcash',
                Icons.phone_android_rounded,
                'SkipCash / Apple Pay',
                'SkipCash',
              ),
            ];
            final parsedAmount =
                double.tryParse(customAmountController.text.trim()) ??
                    selectedAmount.toDouble();
            final displayAmount = parsedAmount > 0
                ? parsedAmount.toStringAsFixed(
                    parsedAmount == parsedAmount.roundToDouble() ? 0 : 2,
                  )
                : '0';

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppDimens.space24,
                  right: AppDimens.space24,
                  top: AppDimens.space16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                      AppDimens.space24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MashwarSheetHeader(
                      title: isAr ? 'شحن رصيد المحفظة' : 'Add Wallet Balance',
                      subtitle: isAr
                          ? 'اختر المبلغ للشحن الفوري عبر خدمة فوراً أو البطاقة'
                          : 'Select or enter an amount to top-up via Fawran or QPay',
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Quick Amounts
                    Row(
                      children: [50, 100, 200, 500].map((amount) {
                        final isSel = selectedAmount == amount &&
                            customAmountController.text.trim() == '$amount';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setSheetState(() {
                                selectedAmount = amount;
                                customAmountController.text = '$amount';
                                errorText = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.navy : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.navy
                                        : AppColors.slateBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$amount ${isAr ? 'ر.ق' : 'QAR'}',
                                    style: AppTypography.label(
                                      color: isSel ? Colors.white : AppColors.navy,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppDimens.space12),

                    TextField(
                      key: const ValueKey('wallet_topup_amount_input'),
                      controller: customAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        setSheetState(() {
                          final parsed = int.tryParse(val.trim());
                          if (parsed != null) selectedAmount = parsed;
                          errorText = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'أو أدخل مبلغاً مخصصاً (ر.ق)' : 'Custom Amount (QAR)',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.slateBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.navy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.space16),

                    // Interactive Payment Method selector inside sheet
                    Text(
                      isAr ? 'طريقة الدفع' : 'Payment Method',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...channels.map((ch) {
                      final isSel = selectedChannel == ch.$1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setSheetState(() => selectedChannel = ch.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.cobaltSurface : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.navy
                                    : AppColors.slateBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  ch.$2,
                                  color: AppColors.navy,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ch.$3,
                                    style: AppTypography.body(color: AppColors.navy)
                                        .copyWith(
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                if (isSel)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.navy,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          errorText!,
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.space16),

                    MashwarButton(
                      key: const ValueKey('wallet_confirm_topup_btn'),
                      text: isAr
                          ? 'تأكيد الشحن بمبلغ $displayAmount ر.ق'
                          : 'Confirm Deposit of $displayAmount QAR',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final amount =
                            double.tryParse(customAmountController.text.trim()) ??
                                0;
                        if (amount <= 0 || amount > 50000) {
                          setSheetState(() {
                            errorText = isAr
                                ? 'يرجى إدخال مبلغ صحيح بين 1 و 50,000 ر.ق'
                                : 'Please enter an amount between 1 and 50,000 QAR';
                          });
                          return;
                        }

                        setSheetState(() => isSubmitting = true);
                        final auth = parentContext.read<AuthProvider>();
                        final chosen =
                            channels.firstWhere((e) => e.$1 == selectedChannel);
                        await auth.topUpWallet(
                          amount: amount,
                          methodKey: selectedChannel,
                          methodAr: chosen.$3,
                          methodEn: chosen.$4,
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!parentContext.mounted) return;
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم شحن المحفظة بنجاح بمبلغ $displayAmount ر.ق عبر ${chosen.$3}'
                                  : 'Wallet topped up with $displayAmount QAR via ${chosen.$4}',
                            ),
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
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        customAmountController.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        title: Text(
          isAr ? 'محفظة مشوار' : 'MASHWAR Wallet',
          style: AppTypography.title().copyWith(fontSize: 18),
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.navy),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const MashwarPinIcon(size: 17, isLight: true),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isAr ? 'الرصيد المتاح' : 'Available Balance',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySecondary(
                                    color: Colors.white70,
                                  ).copyWith(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'آمن ومشفر' : 'Encrypted',
                                style: AppTypography.label(color: Colors.white).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                            key: const ValueKey('wallet_balance_value'),
                            style: AppTypography.largeTitle(color: Colors.white).copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'ريال قطري' : 'QAR',
                            style: AppTypography.body(color: Colors.white70).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const ValueKey('wallet_open_topup_btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.navy,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: Text(
                              isAr ? 'شحن رصيد' : 'Deposit',
                              style: AppTypography.label(color: AppColors.navy).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            onPressed: () => _showAddFundsSheet(context),
                          ),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('wallet_open_withdraw_btn'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                            label: Text(
                              isAr ? 'سحب رصيد' : 'Withdraw',
                              style: AppTypography.label(color: Colors.white).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            onPressed: () => _showWithdrawSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            final escrowProtectedCard = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.teal,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'رصيد الضمان المحجوز' : 'Protected Escrow Hold',
                              style: AppTypography.body(color: AppColors.navy).copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'MASHWAR ESCROW',
                              style: AppTypography.label(color: AppColors.teal).copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? '225 ر.ق' : '225 QAR',
                        style: AppTypography.title(color: AppColors.teal).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAr
                        ? 'محفوظ لحماية صفقات الشراء وتوريد المواقع حتى اعتماد الفاتورة وإدخال OTP'
                        : 'Held safely until receipt approval & 4-digit OTP completion',
                    style: AppTypography.bodySecondary().copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Text(
                          isAr ? 'أتعاب جارية: 45 ر.ق' : 'Fee Hold: 45 QAR',
                          style: AppTypography.label(color: AppColors.navy).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Text(
                          isAr ? 'سقف فواتير: 180 ر.ق' : 'Receipt Cap: 180 QAR',
                          style: AppTypography.label(color: AppColors.navy).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.slateBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ServiceEscrowScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 17,
                        color: AppColors.teal,
                      ),
                      label: Text(
                        isAr
                            ? 'إدارة صفقات الضمان وحماية الطرفين'
                            : 'Manage Escrow Deals & Disputes',
                        style: AppTypography.label(color: AppColors.navy).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final paymentMethodsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
                  child: Text(
                    isAr ? 'طرق الدفع المدعومة' : 'Supported Payment Methods',
                    style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.slateBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildPaymentTile(
                        icon: Icons.flash_on_rounded,
                        title: isAr
                            ? 'فوراً Fawran (التحويل اللحظي)'
                            : 'Fawran (QCB Instant Transfer)',
                        subtitle: isAr
                            ? 'تحويل بنكي فوري في قطر بدون رسوم إضافية'
                            : 'Instant zero-fee bank transfer in Qatar',
                        isDefault: auth.selectedPaymentMethod == 'fawran',
                        isAr: isAr,
                        onTap: () => auth.setSelectedPaymentMethod('fawran'),
                      ),
                      const Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: AppColors.slateBorder,
                      ),
                      _buildPaymentTile(
                        icon: Icons.credit_card_rounded,
                        title: isAr
                            ? 'كيوباي QPay وبطاقات البنوك القطرية'
                            : 'QPay Debit & Qatari Bank Cards',
                        subtitle: isAr
                            ? 'بطاقة هميان الوطنية، QPay، فيزا وماستركارد'
                            : 'Himyan National Card, QPay, Visa & Mastercard',
                        isDefault: auth.selectedPaymentMethod == 'qpay',
                        isAr: isAr,
                        onTap: () => auth.setSelectedPaymentMethod('qpay'),
                      ),
                      const Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: AppColors.slateBorder,
                      ),
                      _buildPaymentTile(
                        icon: Icons.phone_android_rounded,
                        title: isAr
                            ? 'سكيب كاش SkipCash و Apple Pay'
                            : 'SkipCash & Apple Pay',
                        subtitle: isAr
                            ? 'دفع رقمي فوري عبر الهاتف في قطر'
                            : 'Instant mobile digital payment in Qatar',
                        isDefault: auth.selectedPaymentMethod == 'skipcash',
                        isAr: isAr,
                        onTap: () => auth.setSelectedPaymentMethod('skipcash'),
                      ),
                      const Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: AppColors.slateBorder,
                      ),
                      _buildPaymentTile(
                        icon: Icons.payments_outlined,
                        title: isAr ? 'الدفع نقداً' : 'Cash upon meeting',
                        subtitle: isAr
                            ? 'دفع قيمة المقعد أو الخدمة باليد مع توثيق OTP'
                            : 'Direct cash handover verified with 4-digit OTP',
                        isDefault: auth.selectedPaymentMethod == 'cash',
                        isAr: isAr,
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
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
                  child: Text(
                    isAr ? 'سجل العمليات الأخير' : 'Recent Transactions',
                    style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.slateBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: auth.walletTransactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppDimens.space24),
                          child: Center(
                            child: Text(
                              isAr
                                  ? 'لا توجد عمليات مسجلة بعد'
                                  : 'No transactions recorded yet',
                              style: AppTypography.bodySecondary(),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: auth.walletTransactions.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 64,
                            endIndent: 16,
                            color: AppColors.slateBorder,
                          ),
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
                                : (tx['titleEn'] ?? tx['titleAr'] ?? tx['title'] ?? '')
                                    .toString();
                            final date = isAr
                                ? (tx['date'] ?? '').toString()
                                : (tx['dateEn'] ?? tx['date'] ?? '').toString();
                            final String amountLabel;
                            if (tx['amountValue'] is num) {
                              final val = (tx['amountValue'] as num).abs();
                              final formatted = val == val.roundToDouble()
                                  ? val.toStringAsFixed(0)
                                  : val.toStringAsFixed(2);
                              amountLabel =
                                  '${isPositive ? '+' : '-'}$formatted ${isAr ? 'ر.ق' : 'QAR'}';
                            } else if (rawAmount is num) {
                              final val = rawAmount.abs();
                              final formatted = val == val.roundToDouble()
                                  ? val.toStringAsFixed(0)
                                  : val.toStringAsFixed(2);
                              amountLabel =
                                  '${isPositive ? '+' : '-'}$formatted ${isAr ? 'ر.ق' : 'QAR'}';
                            } else {
                              final str = rawAmount?.toString() ?? '0';
                              amountLabel = isAr
                                  ? (str.contains('ر.ق')
                                      ? str
                                      : '${str.replaceAll('ج.م', '').trim()} ر.ق')
                                  : str
                                      .replaceAll('ر.ق', 'QAR')
                                      .replaceAll('ج.م', 'QAR');
                            }
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isPositive
                                      ? AppColors.tealSurface
                                      : AppColors.slateBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isPositive
                                        ? AppColors.teal.withValues(alpha: 0.25)
                                        : AppColors.slateBorder,
                                  ),
                                ),
                                child: Icon(
                                  isPositive
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  color: isPositive ? AppColors.teal : AppColors.navy,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                title,
                                style: AppTypography.body(color: AppColors.navy).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                date,
                                style: AppTypography.label(color: AppColors.textSecondary)
                                    .copyWith(fontSize: 11.5),
                              ),
                              trailing: Text(
                                amountLabel,
                                style: AppTypography.body(
                                  color: isPositive ? AppColors.teal : AppColors.navy,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
                                  const SizedBox(height: AppDimens.space16),
                                  escrowProtectedCard,
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
                            const SizedBox(height: AppDimens.space16),
                            escrowProtectedCard,
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
    required String title,
    required String subtitle,
    required bool isDefault,
    required bool isAr,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDefault ? AppColors.tealSurface : AppColors.slateBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDefault
                ? AppColors.teal.withValues(alpha: 0.25)
                : AppColors.slateBorder,
          ),
        ),
        child: Icon(
          icon,
          color: isDefault ? AppColors.teal : AppColors.navy,
          size: 19,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.body(color: AppColors.navy).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.label(color: AppColors.textSecondary).copyWith(
          fontSize: 11.5,
        ),
      ),
      trailing: isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
              ),
              child: Text(
                isAr ? 'أساسي' : 'Default',
                style: AppTypography.label(color: AppColors.teal).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
    );
  }
}
