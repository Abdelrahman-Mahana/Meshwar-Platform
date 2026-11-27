import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/auth_provider.dart';
import '../../state/board_provider.dart';
import '../chat/chat_screen.dart';
import '../escrow/service_escrow_screen.dart';
import '../safety/safety_screens.dart';

class MakeOfferSheet extends StatefulWidget {
  const MakeOfferSheet({super.key, required this.ad});

  final BoardAdModel ad;

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  bool _isMakingOffer = false;
  String _selectedChannel = 'cash_on_delivery';
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
                        ? 'مستعد لنقل البضاعة بأمان مع رمز التسليم'
                        : 'أقدر أستلم طلبك في طريقي';
    _noteController = TextEditingController(text: defaultNote);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context, BoardAdModel ad) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          driverName: ad.authorName,
          driverCar: ad.timeText,
          tripRoute: context.trRoute(ad.route),
        ),
      ),
    );
  }

  Future<void> _openRouteInGoogleMaps(
    BuildContext context,
    BoardAdModel ad,
    bool isAr,
  ) async {
    final override = EmergencySosSheet.debugUrlLauncher;
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
                  ? 'تم نسخ رابط المسار في Google Maps'
                  : 'Google Maps route link copied',
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
      titleAr: 'مسار الطلب · ${ad.fromCity} ← ${ad.toCity}',
      titleEn: 'Listing Route · ${ad.fromCity} → ${ad.toCity}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardProvider>();
    final currentAd = board.allAds.firstWhere(
      (a) => a.id == widget.ad.id,
      orElse: () => board.mySentOffers.firstWhere(
        (a) => a.id == widget.ad.id,
        orElse: () => widget.ad,
      ),
    );
    final isAr = context.isArabic;
    final isOfferSent = currentAd.status == BoardAdStatus.offerSent;
    final isExpired = currentAd.status == BoardAdStatus.expired ||
        currentAd.status == BoardAdStatus.completed;

    final int minFair = ((currentAd.priceOrBudget * 0.75) / 5).round() * 5;
    final int maxFair = ((currentAd.priceOrBudget * 1.25) / 5).round() * 5;

    String primaryButtonLabel;
    if (currentAd.type == BoardAdType.parcelRequest) {
      primaryButtonLabel =
          isAr ? 'أقدر أوصّل الطرد' : 'I Can Deliver This Parcel';
    } else if (currentAd.type == BoardAdType.rideOffer) {
      primaryButtonLabel =
          isAr ? 'طلب حجز / تقديم عرض' : 'Request Seat / Make Offer';
    } else if (currentAd.type == BoardAdType.localTrip) {
      primaryButtonLabel =
          isAr ? 'أقدر أوصلك الآن' : 'I Can Take This Ride';
    } else if (currentAd.type == BoardAdType.errandService) {
      primaryButtonLabel =
          isAr ? 'مستعد لإنجاز المعاملة' : 'I Can Fulfill This Errand';
    } else if (currentAd.type == BoardAdType.goodsDelivery) {
      primaryButtonLabel = isAr ? 'مستعد أنقل البضاعة' : 'I Can Deliver Goods';
    } else {
      primaryButtonLabel = isAr ? 'قدّم عرض توصيل' : 'Make a Ride Offer';
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusBottomSheet),
              ),
            ),
            padding: const EdgeInsets.all(AppDimens.space24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slateBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  if (isExpired) ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            size: 54,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAr
                                ? 'انتهت صلاحية هذا الإعلان'
                                : 'This listing has closed',
                            style: AppTypography.largeTitle(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr
                                ? 'اختار صاحب الطلب عرضاً آخر أو انتهى الموعد.'
                                : 'Author chose another offer or schedule passed.',
                            style: AppTypography.bodySecondary(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          MashwarButton(
                            text: isAr
                                ? 'تصفح طلبات أخرى'
                                : 'Browse other requests',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isOfferSent && !_isMakingOffer) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.teal,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'تم إرسال عرضك (${currentAd.myOfferPrice ?? currentAd.priceOrBudget} ر.ق) إلى ${currentAd.authorName}. سنبلغك فور الرد.'
                                  : 'Your offer (${currentAd.myOfferPrice ?? currentAd.priceOrBudget} QAR) was sent to ${currentAd.authorName}.',
                              style: AppTypography.body(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailsCard(context, currentAd, isAr),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: MashwarButton(
                            text: isAr
                                ? 'محادثة ${currentAd.authorName}'
                                : 'Chat with ${currentAd.authorName}',
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () => _openChat(context, currentAd),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MashwarButton(
                            text: isAr ? 'تعديل العرض' : 'Edit Offer',
                            variant: MashwarButtonVariant.secondary,
                            onPressed: () =>
                                setState(() => _isMakingOffer = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          backgroundColor: AppColors.tealSurface,
                          side: BorderSide(
                            color: AppColors.teal.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            const Icon(Icons.verified_user_rounded, size: 18),
                        label: Text(
                          isAr
                              ? 'معاينة كود الأمان OTP وتوثيق التسليم'
                              : 'Inspect OTP Handover Verification',
                          style: AppTypography.label(color: AppColors.teal)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        onPressed: () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceEscrowScreen(ad: currentAd),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: Text(
                          isAr ? 'سحب العرض وإلغاؤه' : 'Withdraw Offer',
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          board.withdrawOffer(currentAd.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ] else if (_isMakingOffer) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentAd.type == BoardAdType.rideOffer
                                ? (isAr
                                    ? 'تأكيد السعر أو تقديم عرض'
                                    : 'Confirm Price or Make Offer')
                                : (isAr
                                    ? 'قدّم عرضك لـ ${currentAd.authorName}'
                                    : 'Make Offer to ${currentAd.authorName}'),
                            style: AppTypography.title(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _isMakingOffer = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MashwarTextField(
                      key: const ValueKey('make_offer_price_input'),
                      controller: _priceController,
                      label: currentAd.type == BoardAdType.parcelRequest
                          ? (isAr
                              ? 'مكافأة التوصيل المقترحة (ر.ق)'
                              : 'Proposed Delivery Fee (QAR)')
                          : (isAr
                              ? 'سعرك المقترح (ر.ق)'
                              : 'Your Proposed Price (QAR)'),
                      hint: '${currentAd.priceOrBudget}',
                      errorText: _priceError,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        if (_priceError != null) {
                          setState(() => _priceError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Quick Price Increment Chips (Preserved for tests)
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
                            isAr
                                ? 'المعروض (${currentAd.priceOrBudget} ر.ق)'
                                : 'Listed (${currentAd.priceOrBudget})',
                            currentAd.priceOrBudget,
                          ),
                          const SizedBox(width: 8),
                          _buildQuickPriceChip(
                            '+10 ${isAr ? "ر.ق" : "QAR"}',
                            currentAd.priceOrBudget + 10,
                          ),
                          const SizedBox(width: 8),
                          _buildQuickPriceChip(
                            '+20 ${isAr ? "ر.ق" : "QAR"}',
                            currentAd.priceOrBudget + 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isAr
                                  ? 'نطاق مشاركة التكلفة العادل لهذا المسار: $minFair - $maxFair ر.ق'
                                  : 'Fair cost-sharing range for this route: $minFair - $maxFair QAR',
                              style: AppTypography.label(color: AppColors.teal)
                                  .copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'طريقة التسوية المفضلة' : 'Settlement Method',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        (
                          'cash_on_delivery',
                          isAr ? 'نقداً عند التسليم' : 'Cash on Handover',
                        ),
                        (
                          'bank_transfer_manual',
                          isAr ? 'تحويل بنكي مباشر' : 'Direct Bank Transfer',
                        ),
                      ].map((ch) {
                        final sel = _selectedChannel == ch.$1;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setState(() => _selectedChannel = ch.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.navy : AppColors.slateBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? AppColors.navy
                                    : AppColors.slateBorder,
                              ),
                            ),
                            child: Text(
                              ch.$2,
                              style: AppTypography.label(
                                color: sel ? Colors.white : AppColors.navy,
                              ).copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    MashwarTextField(
                      key: const ValueKey('make_offer_note_input'),
                      controller: _noteController,
                      label: isAr
                          ? 'رسالة أو ملاحظة لصاحب الطلب'
                          : 'Note to Requester',
                      hint: isAr
                          ? 'أنا في نفس الطريق ومستعد للتسليم في الموعد'
                          : 'I am heading along this route and can assist',
                    ),
                    const SizedBox(height: 20),
                    MashwarButton(
                      key: const ValueKey('make_offer_submit_btn'),
                      text: isAr ? 'إرسال العرض الآن' : 'Send Offer Now',
                      onPressed: () {
                        final price =
                            int.tryParse(_priceController.text.trim());
                        if (price == null || price <= 0 || price > 50000) {
                          setState(() {
                            _priceError = isAr
                                ? 'أدخل سعراً صحيحاً بين 1 و 50,000 ر.ق'
                                : 'Please enter a valid price (1 - 50,000 QAR)';
                          });
                          return;
                        }
                        final auth = Provider.of<AuthProvider?>(
                          context,
                          listen: false,
                        );
                        setState(() => _priceError = null);
                        board.submitOffer(
                          adId: currentAd.id,
                          offerPrice: price,
                          note: _noteController.text.trim(),
                          driverName: auth?.user.fullName,
                          driverId: auth?.user.id,
                          timeText: currentAd.timeText,
                        );
                        setState(() => _isMakingOffer = false);
                      },
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              MashwarUserAvatar(
                                avatarUrl: null,
                                fullName: currentAd.authorName,
                                size: 46,
                                borderWidth: 1.5,
                                borderColor: AppColors.slateBorder,
                                autoCommunityPortrait: true,
                                showVerifiedBadge: currentAd.isVerified,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentAd.authorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body(
                                        color: AppColors.navy,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '★ ${currentAd.authorRating} · ${currentAd.tripCount} ${isAr ? "رحلة/طلب" : "trips"} · ${context.trDate(currentAd.timeAgo)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.label(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        MashwarBadge(
                          type: currentAd.isLadiesOnly
                              ? BadgeType.ladiesOnly
                              : BadgeType.newBadge,
                          customLabel: currentAd.displaySubTag(isAr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailsCard(context, currentAd, isAr),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: MashwarButton(
                            text: primaryButtonLabel,
                            onPressed: () =>
                                setState(() => _isMakingOffer = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: MashwarButton(
                            text: isAr ? 'محادثة' : 'Chat',
                            variant: MashwarButtonVariant.secondary,
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.navy,
                              size: 18,
                            ),
                            onPressed: () => _openChat(context, currentAd),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, BoardAdModel ad, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MashwarRouteTimeline(
                  from: context.trCity(ad.fromCity),
                  to: context.trCity(ad.toCity),
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('make_offer_open_gmaps_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.slateBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _openRouteInGoogleMaps(context, ad, isAr),
                icon: const Icon(
                  Icons.map_outlined,
                  size: 14,
                  color: AppColors.teal,
                ),
                label: Text(
                  isAr ? 'الخريطة' : 'Maps',
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MashwarEmbeddedGoogleMap(
            key: const ValueKey('make_offer_embedded_gmap'),
            origin: ad.fromCity,
            destination: ad.toCity,
            stopover: ad.stopoverCity,
            height: 150,
            borderRadius: 12,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.navy,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ad.timeText,
                  style: AppTypography.body()
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(ad.description, style: AppTypography.bodySecondary()),
          if (ad.notes != null && ad.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ad.notes!,
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
          const Divider(height: 20, color: AppColors.slateBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ad.type == BoardAdType.rideOffer
                      ? (isAr ? 'سعر المقعد المعروض' : 'Listed Seat Price')
                      : (isAr
                          ? 'الميزانية / المكافأة المعروضة'
                          : 'Offered Budget / Reward'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
                style: AppTypography.title(color: AppColors.navy),
              ),
            ],
          ),
          if (ad.requiresReceiptProof && ad.estimatedItemCost != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAr
                        ? 'سقف فاتورة المشتريات التقديري'
                        : 'Estimated Receipt Budget Cap',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.teal),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ad.estimatedItemCost} ${isAr ? "ر.ق" : "QAR"}',
                  style: AppTypography.body(color: AppColors.teal)
                      .copyWith(fontWeight: FontWeight.w700),
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
          color: isSelected ? AppColors.navy : AppColors.slateBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.slateBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label(
            color: isSelected ? Colors.white : AppColors.navy,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
