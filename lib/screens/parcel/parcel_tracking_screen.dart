import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/parcel_model.dart';
import 'pickup_code_dialog.dart';
import 'parcel_dispute_screen.dart';

class ParcelTrackingScreen extends StatefulWidget {
  const ParcelTrackingScreen({super.key, required this.parcel});

  final ParcelModel parcel;

  @override
  State<ParcelTrackingScreen> createState() => _ParcelTrackingScreenState();
}

class _ParcelTrackingScreenState extends State<ParcelTrackingScreen> {
  late ParcelStatusStep _status;
  bool _isRejected = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _status = widget.parcel.status;
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'طردي' : 'My Parcel', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Simulation menu to test all 7 status step variations from Page 33
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.navy),
            onSelected: (val) {
              setState(() {
                _isRejected = false;
                _isCancelled = false;
                if (val == 'requested') _status = ParcelStatusStep.requested;
                if (val == 'accepted') _status = ParcelStatusStep.accepted;
                if (val == 'handedOver') _status = ParcelStatusStep.handedOver;
                if (val == 'inTransit') _status = ParcelStatusStep.inTransit;
                if (val == 'delivered') _status = ParcelStatusStep.delivered;
                if (val == 'rejected') _isRejected = true;
                if (val == 'cancelled') _isCancelled = true;
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'requested', child: Text(isAr ? '1. بانتظار السائق' : '1. Waiting for Driver')),
              PopupMenuItem(value: 'accepted', child: Text(isAr ? '2. مقبول' : '2. Accepted')),
              PopupMenuItem(value: 'handedOver', child: Text(isAr ? '3. في عهدة السائق' : '3. In Driver Custody')),
              PopupMenuItem(value: 'inTransit', child: Text(isAr ? '4. في الطريق' : '4. In Transit')),
              PopupMenuItem(value: 'delivered', child: Text(isAr ? '5. تم التسليم' : '5. Delivered')),
              PopupMenuItem(value: 'rejected', child: Text(isAr ? '6. مرفوض' : '6. Rejected')),
              PopupMenuItem(value: 'cancelled', child: Text(isAr ? '7. ملغى' : '7. Cancelled')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.trRoute(widget.parcel.route),
                style: AppTypography.title().copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),

              // Status Top Banner (Page 33)
              _buildStatusBanner(isAr),
              const SizedBox(height: 16),

              // Pickup OTP Security Box (Only shown if status is accepted)
              if (_status == ParcelStatusStep.accepted) ...[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PickupCodeDialog(parcel: widget.parcel)),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(isAr ? 'كود الاستلام' : 'Pickup OTP Code', style: AppTypography.label(color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.parcel.pickupOtp.split(' ').map((digit) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 44,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    digit,
                                    style: AppTypography.title(color: Colors.white).copyWith(fontSize: 22),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAr ? 'اعطيه للسائق وقت ما تسلّمه الطرد' : 'Give this code to the driver upon handover',
                          style: AppTypography.label(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 5-Step Timeline
              _buildTimelineStep(
                isAr ? 'تم إرسال الطلب' : 'Request Sent',
                isDone: _status.index >= ParcelStatusStep.requested.index,
                isLast: false,
              ),
              _buildTimelineStep(
                isAr ? 'وافق السائق' : 'Driver Accepted',
                isDone: _status.index >= ParcelStatusStep.accepted.index,
                isLast: false,
              ),
              _buildTimelineStep(
                isAr ? 'تسليم الطرد للسائق' : 'Handed Over to Driver',
                isDone: _status.index >= ParcelStatusStep.handedOver.index,
                isLast: false,
              ),
              _buildTimelineStep(
                isAr ? 'في الطريق' : 'In Transit',
                isDone: _status.index >= ParcelStatusStep.inTransit.index,
                isLast: false,
              ),
              _buildTimelineStep(
                isAr ? 'تم التسليم' : 'Delivered',
                isDone: _status.index >= ParcelStatusStep.delivered.index,
                isLast: true,
              ),
              const SizedBox(height: 20),

              // Live Recipient WhatsApp Share Card
              _buildRecipientLiveShareCard(context, isAr),
              const SizedBox(height: 24),

              // Action button based on phase
              _buildActionButton(context, isAr),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isAr) {
    switch (_status) {
      case ParcelStatusStep.requested:
        return AlertBanner(
          message: isAr ? 'بانتظار رد السائق على طلبك' : 'Waiting for driver response',
          type: AlertBannerType.info,
        );
      case ParcelStatusStep.accepted:
        return AlertBanner(
          message: isAr ? 'السائق وافق على طردك' : 'Driver accepted your parcel',
          type: AlertBannerType.success,
        );
      case ParcelStatusStep.handedOver:
        return AlertBanner(
          message: isAr ? 'السائق استلم الطرد' : 'Driver received the parcel',
          type: AlertBannerType.success,
        );
      case ParcelStatusStep.inTransit:
        return AlertBanner(
          message: isAr ? 'الطرد في الطريق للوجهة' : 'Parcel is in transit to destination',
          type: AlertBannerType.info,
        );
      case ParcelStatusStep.delivered:
        return AlertBanner(
          message: isAr ? 'الطرد وصل واتسلّم بنجاح' : 'Parcel arrived and delivered successfully',
          type: AlertBannerType.success,
        );
    }
  }

  Widget _buildActionButton(BuildContext context, bool isAr) {
    if (_status == ParcelStatusStep.requested) {
      return MashwarButton(
        text: isAr ? 'إلغاء الطلب' : 'Cancel Request',
        variant: MashwarButtonVariant.secondary,
        onPressed: () => setState(() => _isCancelled = true),
      );
    }

    if (_status == ParcelStatusStep.accepted || _status == ParcelStatusStep.handedOver) {
      return MashwarButton(
        text: isAr ? 'اتصل بالسائق' : 'Call Driver',
        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'الاتصال بالسائق...' : 'Calling driver...')),
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
            icon: const Icon(Icons.share_outlined, color: AppColors.navy, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رابط تتبع الطرد المباشر: https://mashwar.app/track/p_${widget.parcel.id}'
                        : 'Tracking link copied: https://mashwar.app/track/p_${widget.parcel.id}',
                  ),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParcelDisputeScreen(reportId: '#4821')),
              );
            },
            child: Text(isAr ? 'أبلّغ عن مشكلة في الشحن' : 'Report shipping issue', style: AppTypography.bodySecondary(color: AppColors.danger)),
          ),
        ],
      );
    }

    // Delivered State
    return MashwarButton(
      text: isAr ? 'أرسل طرد تاني' : 'Send Another Parcel',
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  Widget _buildTimelineStep(String label, {required bool isDone, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppColors.teal : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.teal : AppColors.borderDisabled,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.teal : AppColors.borderDisabled,
              ),
          ],
        ),
        const SizedBox(width: AppDimens.space16),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: AppTypography.body().copyWith(
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? AppColors.navy : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // Page 33: Rejected View
  Widget _buildRejectedView(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.cancel_outlined, size: 72, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(isAr ? 'السائق اعتذر عن قبول الطرد' : 'Driver declined your parcel', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'ممكن تكون الشنطة مليانة أو الطرد مش مناسب لمسار الرحلة.'
                    : 'The car trunk might be full or parcel does not fit the path.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'ابحث عن مسافر تاني' : 'Find Another Traveler',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Page 33: Cancelled View
  Widget _buildCancelledView(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.remove_circle_outline_rounded, size: 72, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(isAr ? 'تم إلغاء طلب الشحن' : 'Shipping Request Cancelled', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                isAr ? 'ألغيت طلب الشحن بنجاح ولم يتم خصم أي رسوم.' : 'You cancelled the parcel request. No fees were charged.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'الرجوع للرئيسية' : 'Back to Home',
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.share_location_rounded, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'مشاركة التتبع المباشر مع المستلم' : 'Live Tracking for Recipient',
                  style: AppTypography.title().copyWith(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAr ? 'بدون تطبيق' : 'Web Link',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'شارك رابط تتبع مباشر مع المستلم ليرى مسار سيارة السائق لحظياً وموعد الوصول على الخريطة.'
                : 'Share a live tracking link with the recipient to watch real-time driver ETA on the map.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.navy),
            label: Text(
              isAr ? 'إرسال رابط التتبع عبر واتساب' : 'Send Tracking Link via WhatsApp',
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
