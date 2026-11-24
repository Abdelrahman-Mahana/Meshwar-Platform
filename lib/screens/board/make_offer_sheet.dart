import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../chat/chat_screen.dart';
import '../escrow/service_escrow_screen.dart';

class MakeOfferSheet extends StatefulWidget {
  const MakeOfferSheet({super.key, required this.ad});

  final BoardAdModel ad;

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  bool _isMakingOffer = false;
  String _selectedChannel = 'fawran';
  late TextEditingController _priceController;
  late TextEditingController _noteController;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: '${widget.ad.myOfferPrice ?? widget.ad.priceOrBudget}',
    );
    final defaultNote = widget.ad.type == BoardAdType.parcelRequest
        ? 'أقدر أستلم الطرد وأوصّله في موعد رحلتي'
        : widget.ad.type == BoardAdType.rideOffer
            ? 'أرغب في الحجز معك في هذه الرحلة'
            : widget.ad.type == BoardAdType.errandService
                ? 'متجه في نفس المسار ومستعد لشراء طلباتك أو إنجاز معاملتك'
                : widget.ad.type == BoardAdType.localTrip
                    ? 'أنا قريب من موقعك ومعي سيارة وأقدر أوصلك الآن'
                    : widget.ad.type == BoardAdType.goodsDelivery
                        ? 'مستعد لنقل البضاعة للمحل بأمان مع رمز التسليم'
                        : 'أقدر أستلم طلبك في طريقي';
    _noteController = TextEditingController(text: defaultNote);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context, bool isAr) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          driverName: widget.ad.authorName,
          driverCar: widget.ad.timeText,
          tripRoute: context.trRoute(widget.ad.route),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardProvider>();
    // Get live updated ad from provider if available
    final currentAd = board.filteredAds.firstWhere(
      (a) => a.id == widget.ad.id && a.type == widget.ad.type && a.priceOrBudget == widget.ad.priceOrBudget,
      orElse: () => board.mySentOffers.firstWhere(
        (a) => a.id == widget.ad.id && a.type == widget.ad.type && a.priceOrBudget == widget.ad.priceOrBudget,
        orElse: () => widget.ad,
      ),
    );
    final isAr = context.isArabic;
    final isOfferSent = currentAd.status == BoardAdStatus.offerSent;
    final isExpired = currentAd.status == BoardAdStatus.expired || currentAd.status == BoardAdStatus.completed;

    final int minFair = ((currentAd.priceOrBudget * 0.75) / 5).round() * 5;
    final int maxFair = ((currentAd.priceOrBudget * 1.25) / 5).round() * 5;

    String primaryButtonLabel;
    if (currentAd.type == BoardAdType.parcelRequest) {
      primaryButtonLabel = isAr ? 'أقدر أوصّل الطرد' : 'I Can Deliver This Parcel';
    } else if (currentAd.type == BoardAdType.rideOffer) {
      primaryButtonLabel = isAr ? 'طلب حجز / تقديم عرض' : 'Request Seat / Make Offer';
    } else if (currentAd.type == BoardAdType.localTrip) {
      primaryButtonLabel = isAr ? 'أقدر أوصلك الآن' : 'I Can Take This Ride';
    } else if (currentAd.type == BoardAdType.errandService) {
      primaryButtonLabel = isAr ? 'مستعد لإنجاز المعاملة' : 'I Can Fulfill This Errand';
    } else if (currentAd.type == BoardAdType.goodsDelivery) {
      primaryButtonLabel = isAr ? 'مستعد أنقل البضاعة' : 'I Can Deliver Goods';
    } else {
      primaryButtonLabel = isAr ? 'قدّم عرض توصيل' : 'Make a Ride Offer';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
        ),
        padding: const EdgeInsets.all(AppDimens.space24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              if (isExpired) ...[
                // Expired state (Page 22)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.close_rounded, size: 54, color: AppColors.danger),
                      const SizedBox(height: 12),
                      Text(isAr ? 'انتهت صلاحية هذا الإعلان' : 'This ad has expired', style: AppTypography.largeTitle()),
                      const SizedBox(height: 6),
                      Text(
                        isAr ? 'اختار صاحب الإعلان عرضاً آخر أو انتهى الموعد.' : 'Author chose another offer or time has passed.',
                        style: AppTypography.bodySecondary(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      MashwarButton(
                        text: isAr ? 'تصفح إعلانات أخرى' : 'Browse other ads',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ] else if (isOfferSent && !_isMakingOffer) ...[
                // Offer Sent State (Page 22)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'تم إرسال عرضك (${currentAd.myOfferPrice ?? currentAd.priceOrBudget} ر.ق) إلى ${currentAd.authorName}. سنبلّغك فور الرد.'
                              : 'Your offer (${currentAd.myOfferPrice ?? currentAd.priceOrBudget} QAR) was sent to ${currentAd.authorName}.',
                          style: AppTypography.body().copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailsCard(currentAd, isAr),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: MashwarButton(
                        text: isAr ? 'محادثة ${currentAd.authorName}' : 'Chat with ${currentAd.authorName}',
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                        onPressed: () => _openChat(context, isAr),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MashwarButton(
                        text: isAr ? 'تعديل العرض' : 'Edit Offer',
                        variant: MashwarButtonVariant.secondary,
                        onPressed: () => setState(() => _isMakingOffer = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.escrowGreen,
                      backgroundColor: AppColors.escrowSurface,
                      side: BorderSide(color: AppColors.escrowGreen.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: Text(
                      isAr ? 'افتح شاشة الضمان وكود OTP' : 'Open Bilateral Escrow & OTP',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, fontFamily: 'Cairo'),
                    ),
                    onPressed: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(
                        MaterialPageRoute(builder: (_) => ServiceEscrowScreen(ad: currentAd)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: Text(
                      isAr ? 'سحب العرض وإلغاؤه' : 'Withdraw Offer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      board.withdrawOffer(currentAd.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ] else if (_isMakingOffer) ...[
                // Offer Input Mode (Page 22)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentAd.type == BoardAdType.rideOffer
                            ? (isAr ? 'تأكيد السعر أو تقديم عرض' : 'Confirm Price or Make Offer')
                            : (isAr ? 'قدّم عرضك لـ ${currentAd.authorName}' : 'Make Offer to ${currentAd.authorName}'),
                        style: AppTypography.title(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _isMakingOffer = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MashwarTextField(
                  controller: _priceController,
                  label: currentAd.type == BoardAdType.parcelRequest
                      ? (isAr ? 'مكافأة التوصيل المقترحة (ر.ق)' : 'Proposed Delivery Fee (QAR)')
                      : (isAr ? 'سعرك للمقعد (ر.ق)' : 'Your Price per Seat (QAR)'),
                  hint: '${currentAd.priceOrBudget}',
                  errorText: _priceError,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // Quick inDrive-style Price Increment Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (currentAd.priceOrBudget > 15) ...[
                        _buildQuickPriceChip(
                          '-10 ${isAr ? "ر.ق" : "QAR"}',
                          currentAd.priceOrBudget - 10,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildQuickPriceChip(
                        isAr ? 'المعروض (${currentAd.priceOrBudget} ر.ق)' : 'Listed (${currentAd.priceOrBudget})',
                        currentAd.priceOrBudget,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickPriceChip('+10 ${isAr ? "ر.ق" : "QAR"}', currentAd.priceOrBudget + 10),
                      const SizedBox(width: 8),
                      _buildQuickPriceChip('+20 ${isAr ? "ر.ق" : "QAR"}', currentAd.priceOrBudget + 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Fair Price Indicator Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAr
                              ? 'نطاق مشاركة التكلفة العادل لهذا المسار: $minFair - $maxFair ر.ق'
                              : 'Fair cost-sharing range for this route: $minFair - $maxFair QAR',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(isAr ? 'المسار والموعد' : 'Route & Schedule', style: AppTypography.label()),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppDimens.radiusField),
                    border: Border.all(color: AppColors.borderDisabled),
                  ),
                  child: Text(
                    '${context.trRoute(currentAd.route)} · ${currentAd.timeText}',
                    style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isAr ? 'قناة الدفع / الاستلام المضمونة' : 'Protected Payment / Payout Channel',
                  style: AppTypography.label(),
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
                    final sel = _selectedChannel == ch.$1;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedChannel = ch.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.escrowSurface : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel ? AppColors.escrowGreen : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          ch.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: sel ? AppColors.escrowGreen : AppColors.navy,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                MashwarTextField(
                  controller: _noteController,
                  label: isAr ? 'رسالة أو ملاحظة لصاحب الإعلان' : 'Message / Note to Author',
                  hint: isAr ? 'أقدر أعدّي عليك في الطريق' : 'I can pick you up on the way',
                ),
                const SizedBox(height: 20),
                MashwarButton(
                  text: isAr ? 'إرسال العرض الآن' : 'Send Offer Now',
                  onPressed: () {
                    final price = int.tryParse(_priceController.text.trim());
                    if (price == null || price <= 0) {
                      setState(() {
                        _priceError = isAr ? 'ادخل سعراً صحيحاً' : 'Please enter a valid price';
                      });
                      return;
                    }
                    setState(() => _priceError = null);
                    board.submitOffer(
                      adId: currentAd.id,
                      offerPrice: price,
                      note: _noteController.text.trim(),
                    );
                    setState(() => _isMakingOffer = false);
                  },
                ),
              ] else ...[
                // Ad details overview before offer (Page 22)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                currentAd.authorName.isNotEmpty ? currentAd.authorName[0] : 'م',
                                style: AppTypography.title(color: AppColors.navy),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        currentAd.authorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    if (currentAd.isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.teal),
                                    ],
                                  ],
                                ),
                                Text(
                                  '★ ${currentAd.authorRating} · ${currentAd.tripCount} ${isAr ? "خدمة" : "trips"} · ${context.trDate(currentAd.timeAgo)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MashwarBadge(
                      type: currentAd.isLadiesOnly ? BadgeType.ladiesOnly : BadgeType.newBadge,
                      customLabel: currentAd.displaySubTag(isAr),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDetailsCard(currentAd, isAr),
                const SizedBox(height: 12),

                // Bilateral Escrow Protection Card inside MakeOfferSheet
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(builder: (_) => ServiceEscrowScreen(ad: currentAd)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.escrowSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.escrowGreen, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'معاملة محمية بضمان مشوار المزدوج (Escrow)'
                                    : 'Protected by MASHWAR Bilateral Escrow',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.escrowGreen,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                isAr
                                    ? 'حجز الأتعاب والفاتورة + اعتماد بالصورة + كود تسليم OTP · اضغط للمعاينة'
                                    : 'Locked fees & receipt check + 4-digit OTP · Tap to inspect',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.navy,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.escrowGreen, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: MashwarButton(
                        text: primaryButtonLabel,
                        onPressed: () => setState(() => _isMakingOffer = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: MashwarButton(
                        text: isAr ? 'محادثة' : 'Chat',
                        variant: MashwarButtonVariant.secondary,
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.navy, size: 18),
                        onPressed: () => _openChat(context, isAr),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BoardAdModel ad, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MashwarRouteTimeline(
                  from: context.trCity(ad.fromCity),
                  to: context.trCity(ad.toCity),
                  compact: true,
                ),
              ),
              if (ad.isLadiesOnly) ...[
                const SizedBox(width: 8),
                const MashwarBadge(type: BadgeType.ladiesOnly),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: AppColors.teal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ad.timeText,
                  style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(ad.description, style: AppTypography.bodySecondary()),
          if (ad.notes != null && ad.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.notes_rounded, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ad.notes!,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 20, color: AppColors.borderDisabled),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ad.type == BoardAdType.rideOffer
                    ? (isAr ? 'سعر المقعد المعروض' : 'Listed Seat Price')
                    : (isAr ? 'الميزانية / المكافأة المعروضة' : 'Offered Budget / Reward'),
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
              Text(
                '${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
                style: AppTypography.title().copyWith(color: AppColors.teal),
              ),
            ],
          ),
          if (ad.requiresReceiptProof && ad.estimatedItemCost != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'سقف فاتورة المشتريات بالضمان' : 'Escrow Receipt Budget Cap',
                  style: AppTypography.label(color: AppColors.qatarMaroon),
                ),
                Text(
                  '${ad.estimatedItemCost} ${isAr ? "ر.ق" : "QAR"}',
                  style: AppTypography.body(color: AppColors.qatarMaroon).copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPriceChip(String label, int value) {
    final isSelected = int.tryParse(_priceController.text) == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priceController.text = '$value';
          _priceError = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE5E5EA),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
