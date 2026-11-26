import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/parcel_model.dart';
import '../chat/chat_screen.dart';
import 'parcel_dispute_screen.dart';
import 'pickup_code_dialog.dart';

class ParcelTrackingScreen extends StatefulWidget {
  const ParcelTrackingScreen({super.key, required this.parcel});

  final ParcelModel parcel;

  @override
  State<ParcelTrackingScreen> createState() => _ParcelTrackingScreenState();
}

class _ParcelTrackingScreenState extends State<ParcelTrackingScreen> {
  late ParcelStatusStep _status;
  final bool _isRejected = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _status = widget.parcel.status;
  }

  List<String> _parseOtpDigits(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const ['4', '8', '2', '1'];
    if (trimmed.contains(' ')) {
      return trimmed
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return trimmed.split('');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_isRejected) {
      return _buildRejectedView(isAr);
    }
    if (_isCancelled) {
      return _buildCancelledView(isAr);
    }

    final hasTraveler = widget.parcel.hasAssignedTraveler;
    final pickupDigits = _parseOtpDigits(widget.parcel.pickupOtp);
    final deliveryDigits = widget.parcel.deliveryOtp != null &&
            widget.parcel.deliveryOtp!.trim().isNotEmpty
        ? _parseOtpDigits(widget.parcel.deliveryOtp!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'تتبع الطرد وكود الأمان' : 'Parcel Tracking & OTP',
          style: AppTypography.title().copyWith(fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navy),
            tooltip: isAr
                ? 'مشاركة رابط التتبع مع المستلم'
                : 'Share Tracking Link',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رابط التتبع مع المستلم: ${widget.parcel.receiverName}'
                        : 'Tracking link copied for ${widget.parcel.receiverName}',
                  ),
                  backgroundColor: AppColors.emerald,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.navy),
            tooltip: isAr ? 'المساعدة والنزاعات' : 'Help & Disputes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ParcelDisputeScreen(reportId: widget.parcel.id),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: 12,
              ),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Parcel & Traveler Card
                    MashwarSectionCard(
                      child: Row(
                        children: [
                          if (hasTraveler)
                            MashwarUserAvatar(
                              avatarUrl: null,
                              fullName: widget.parcel.driverName,
                              size: 48,
                              borderWidth: 2.0,
                              borderColor: AppColors.gold,
                              autoCommunityPortrait: true,
                              showVerifiedBadge: true,
                            )
                          else
                            const MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.routeParcels,
                              size: 48,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.trRoute(widget.parcel.route),
                                  style: AppTypography.title()
                                      .copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasTraveler
                                      ? '${isAr ? "المسافر الناقل:" : "Traveler:"} ${widget.parcel.driverName}'
                                      : (isAr
                                          ? 'طلب مفتوح على المسار · بانتظار مسافر متجه'
                                          : 'Open Route Request · Matching Traveler'),
                                  style: AppTypography.bodySecondary()
                                      .copyWith(fontSize: 12.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.parcel.sizeLabel(isAr)} · ${widget.parcel.weightKg} ${isAr ? "كجم" : "kg"} · ${widget.parcel.fee} ${isAr ? "ر.ق" : "QAR"}',
                                  style: AppTypography.label(
                                    color: AppColors.indigo,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          if (hasTraveler)
                            IconButton(
                              tooltip: isAr ? 'محادثة المسافر' : 'Chat Traveler',
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      driverName: widget.parcel.driverName,
                                      driverCar: isAr
                                          ? 'شحن طرد #${widget.parcel.id}'
                                          : 'Route Parcel #${widget.parcel.id}',
                                      tripRoute:
                                          context.trRoute(widget.parcel.route),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildStatusBanner(isAr, hasTraveler: hasTraveler),
                    const SizedBox(height: 16),

                    // Pickup & Delivery OTP Security Cards
                    if (_status == ParcelStatusStep.requested ||
                        _status == ParcelStatusStep.accepted ||
                        deliveryDigits != null) ...[
                      MashwarSectionCard(
                        borderColor: AppColors.indigo.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.indigo,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAr
                                        ? 'أكواد الأمان للاستلام والتسليم (OTP)'
                                        : 'Handover & Delivery OTP Codes',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title()
                                        .copyWith(fontSize: 14.5),
                                  ),
                                ),
                                if (_status == ParcelStatusStep.accepted)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PickupCodeDialog(
                                            parcel: widget.parcel,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      isAr ? 'تكبير الكود' : 'Expand',
                                      style: AppTypography.label(
                                        color: AppColors.indigo,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildOtpRow(
                              label: isAr
                                  ? 'كود استلام الطرد (يُسلّم للمسافر عند الاستلام)'
                                  : 'Pickup OTP (Share with traveler at pickup)',
                              digits: pickupDigits,
                              accentColor: AppColors.navy,
                            ),
                            if (deliveryDigits != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              _buildOtpRow(
                                label: isAr
                                    ? 'كود التسليم النهائي للمستلم (${widget.parcel.receiverName})'
                                    : 'Recipient Delivery OTP (${widget.parcel.receiverName})',
                                digits: deliveryDigits,
                                accentColor: AppColors.emerald,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5-Step Progress Timeline
                    MashwarSectionCard(
                      child: Column(
                        children: [
                          _buildTimelineStep(
                            isAr ? 'تم إرسال الطلب' : 'Request Created',
                            isDone: _status.index >=
                                ParcelStatusStep.requested.index,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            isAr ? 'موافقة المسافر على المسار' : 'Traveler Matched',
                            isDone: _status.index >=
                                ParcelStatusStep.accepted.index,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            isAr
                                ? 'تسليم الطرد للمسافر بكود الاستلام'
                                : 'Handed Over via Pickup OTP',
                            isDone: _status.index >=
                                ParcelStatusStep.handedOver.index,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            isAr ? 'في الطريق للوجهة' : 'In Transit Along Route',
                            isDone: _status.index >=
                                ParcelStatusStep.inTransit.index,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            isAr
                                ? 'تم التسليم للمستلم بنجاح'
                                : 'Delivered to Recipient',
                            isDone: _status.index >=
                                ParcelStatusStep.delivered.index,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Recipient Share Card (Preserved for tests)
                    _buildRecipientLiveShareCard(context, isAr),
                    const SizedBox(height: 20),

                    _buildActionButton(context, isAr, hasTraveler: hasTraveler),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpRow({
    required String label,
    required List<String> digits,
    required Color accentColor,
  }) {
    final fullCode = digits.join();
    final isAr = context.isArabic;
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.label(color: AppColors.textSecondary)
              .copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              ...digits.map((digit) {
                return Container(
                  width: 44,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: AppTypography.title(color: Colors.white)
                        .copyWith(fontSize: 20),
                  ),
                );
              }),
              IconButton(
                tooltip: isAr ? 'نسخ الكود' : 'Copy OTP',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fullCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم نسخ الكود: $fullCode'
                            : 'OTP copied: $fullCode',
                      ),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 17,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(bool isAr, {required bool hasTraveler}) {
    switch (_status) {
      case ParcelStatusStep.requested:
        return AlertBanner(
          message: hasTraveler
              ? (isAr
                  ? 'بانتظار تأكيد المسافر لطلب شحن الطرد'
                  : 'Waiting for traveler confirmation')
              : (isAr
                  ? 'طلب الطرد معروض الآن للمسافرين المتجهين على نفس المسار'
                  : 'Parcel request is live for travelers on this route'),
          type: AlertBannerType.info,
        );
      case ParcelStatusStep.accepted:
        return AlertBanner(
          message: isAr
              ? 'وافق المسافر على توصيل طردك في طريقه'
              : 'Traveler accepted your parcel along their route',
          type: AlertBannerType.success,
        );
      case ParcelStatusStep.handedOver:
        return AlertBanner(
          message: isAr
              ? 'تم استلام الطرد وتوثيق كود الاستلام'
              : 'Parcel handed over with OTP verification',
          type: AlertBannerType.success,
        );
      case ParcelStatusStep.inTransit:
        return AlertBanner(
          message: isAr
              ? 'الطرد في الطريق مع المسافر نحو الوجهة'
              : 'Parcel is in transit to destination',
          type: AlertBannerType.info,
        );
      case ParcelStatusStep.delivered:
        return AlertBanner(
          message: isAr
              ? 'تم تسليم الطرد للمستلم بنجاح'
              : 'Parcel delivered to recipient successfully',
          type: AlertBannerType.success,
        );
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isAr, {
    required bool hasTraveler,
  }) {
    if (_status == ParcelStatusStep.requested) {
      return MashwarButton(
        text: isAr ? 'إلغاء طلب الشحن' : 'Cancel Parcel Request',
        variant: MashwarButtonVariant.secondary,
        onPressed: () => setState(() => _isCancelled = true),
      );
    }

    if (_status == ParcelStatusStep.accepted ||
        _status == ParcelStatusStep.handedOver) {
      return MashwarButton(
        text: hasTraveler
            ? (isAr ? 'تواصل مع المسافر' : 'Contact Traveler')
            : (isAr ? 'مشاركة تفاصيل الطرد' : 'Share Parcel Details'),
        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 19),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'جاري فتح قناة التواصل...' : 'Connecting with traveler...',
              ),
            ),
          );
        },
      );
    }

    if (_status == ParcelStatusStep.inTransit) {
      return Column(
        children: [
          MashwarButton(
            text: isAr ? 'مشاركة رابط التتبع' : 'Share Tracking Link',
            variant: MashwarButtonVariant.secondary,
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.navy,
              size: 19,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رابط تتبع الطرد المباشر: https://mashwar.app/track/p_${widget.parcel.id}'
                        : 'Tracking link copied: https://mashwar.app/track/p_${widget.parcel.id}',
                  ),
                  backgroundColor: AppColors.emerald,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ParcelDisputeScreen(reportId: widget.parcel.id),
                ),
              );
            },
            child: Text(
              isAr ? 'الإبلاغ عن مشكلة في الشحنة' : 'Report shipping issue',
              style: AppTypography.bodySecondary(color: AppColors.danger),
            ),
          ),
        ],
      );
    }

    return MashwarButton(
      text: isAr ? 'العودة للرئيسية' : 'Back to Home',
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  Widget _buildTimelineStep(
    String label, {
    required bool isDone,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppColors.emerald : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.emerald : AppColors.slateBorder,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.emerald : AppColors.slateBorder,
              ),
          ],
        ),
        const SizedBox(width: AppDimens.space16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: AppTypography.body().copyWith(
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                color: isDone ? AppColors.navy : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedView(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(
                Icons.cancel_outlined,
                size: 72,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'تعذّر قبول الطرد من هذا المسافر'
                    : 'Traveler could not take parcel',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'يمكنك اختيار مسافر آخر على نفس المسار بضغطة واحدة.'
                    : 'You can pick another traveler heading along the same route.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'ابحث عن مسافر آخر' : 'Find Another Traveler',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledView(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(
                Icons.remove_circle_outline_rounded,
                size: 72,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'تم إلغاء طلب الشحن' : 'Shipping Request Cancelled',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'ألغيت طلب الشحن بنجاح ولم يتم احتساب أي رسوم.'
                    : 'You cancelled the parcel request with zero charges.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'الرجوع للرئيسية' : 'Back to Home',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientLiveShareCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.share_location_rounded,
                size: 18,
                color: AppColors.cobalt,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'مشاركة التتبع المباشر مع المستلم'
                      : 'Live Tracking for Recipient',
                  style: AppTypography.title().copyWith(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cobaltSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAr ? 'رابط مباشر' : 'Web Link',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cobalt,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'شارك رابط التتبع مع المستلم لمتابعة حالة الطرد وموعد الوصول لحظياً.'
                : 'Share a live tracking link with the recipient to follow real-time ETA.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.slateBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.share_outlined,
              size: 16,
              color: AppColors.navy,
            ),
            label: Text(
              isAr
                  ? 'إرسال رابط التتبع عبر واتساب'
                  : 'Send Tracking Link via WhatsApp',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رسالة ورابط تتبع الطرد المباشر للمستلم: https://mashwar.app/track/p_${widget.parcel.id}'
                        : 'Tracking link copied: https://mashwar.app/track/p_${widget.parcel.id}',
                  ),
                  backgroundColor: AppColors.navy,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
