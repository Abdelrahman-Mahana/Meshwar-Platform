import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/mashwar_handover_qr_panel.dart';
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

  ({String origin, String destination}) _resolveParcelEndpoints() {
    final fromRaw = widget.parcel.fromCity?.trim() ?? '';
    final toRaw = widget.parcel.toCity?.trim() ?? '';
    if (fromRaw.isNotEmpty && toRaw.isNotEmpty) {
      return (origin: fromRaw, destination: toRaw);
    }
    final parts = widget.parcel.route
        .split(RegExp(r'←|→|↔|-'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return (origin: parts.first, destination: parts.last);
    }
    return (
      origin: fromRaw.isNotEmpty ? fromRaw : 'الدوحة',
      destination: toRaw.isNotEmpty ? toRaw : 'الخور',
    );
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
          style: AppTypography.title().copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
            size: 19,
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
                      borderRadius: 16,
                      borderColor: AppColors.slateBorder,
                      child: Row(
                        children: [
                          if (hasTraveler)
                            MashwarUserAvatar(
                              avatarUrl: null,
                              fullName: widget.parcel.driverName,
                              size: 48,
                              borderWidth: 1.5,
                              borderColor: AppColors.slateBorder,
                              autoCommunityPortrait: true,
                              showVerifiedBadge: true,
                            )
                          else
                            const MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.routeParcels,
                              size: 44,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.trRoute(widget.parcel.route),
                                  style: AppTypography.title().copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasTraveler
                                      ? '${isAr ? "المسافر الناقل:" : "Traveler:"} ${widget.parcel.driverName}'
                                      : (isAr
                                          ? 'طلب مفتوح على المسار · بانتظار مسافر متجه'
                                          : 'Open Route Request · Matching Traveler'),
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary,
                                  ).copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.parcel.sizeLabel(isAr)} · ${widget.parcel.weightKg} ${isAr ? "كجم" : "kg"} · ${widget.parcel.fee} ${isAr ? "ر.ق" : "QAR"}',
                                  style: AppTypography.label(
                                    color: AppColors.navy,
                                  ).copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                    const SizedBox(height: 12),

                    // Live Corridor Map & In-App Full-Screen Google Maps Route Tracking
                    Builder(
                      builder: (context) {
                        final endpoints = _resolveParcelEndpoints();
                        return MashwarGoogleMapPanel(
                          origin: endpoints.origin,
                          destination: endpoints.destination,
                          keyPrefix: 'parcel',
                          mapHeight: 210.0,
                          openButtonLabelAr: 'تكبير خريطة المسار داخل التطبيق',
                          openButtonLabelEn: 'Full-Screen Route Map',
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Pickup & Delivery OTP Security Cards
                    if (_status == ParcelStatusStep.requested ||
                        _status == ParcelStatusStep.accepted ||
                        deliveryDigits != null) ...[
                      MashwarSectionCard(
                        borderRadius: 16,
                        borderColor: AppColors.teal.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.teal,
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
                                    style: AppTypography.title().copyWith(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                        color: AppColors.navy,
                                      ).copyWith(fontWeight: FontWeight.w700),
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
                              qrPayload:
                                  'MASHWAR|PARCEL_PICKUP|${widget.parcel.id}|${pickupDigits.join()}',
                              qrKey: const ValueKey('parcel_pickup_qr_code'),
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
                                accentColor: AppColors.teal,
                                qrPayload:
                                    'MASHWAR|PARCEL_DELIVERY|${widget.parcel.id}|${deliveryDigits.join()}',
                                qrKey:
                                    const ValueKey('parcel_delivery_qr_code'),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  key: const ValueKey('parcel_scan_qr_btn'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navy,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.slateBorder,
                                      width: 1.0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final expectedCode =
                                        (deliveryDigits ?? pickupDigits).join();
                                    final scanned =
                                        await showMashwarQrScanSheet(
                                      context,
                                      isAr: isAr,
                                      referenceId: widget.parcel.id,
                                      expectedLength: expectedCode.length,
                                      demoScannedCode: expectedCode,
                                    );
                                    if (scanned != null && mounted) {
                                      final matched =
                                          scanned.trim() == expectedCode;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            matched
                                                ? (isAr
                                                    ? 'تمت مطابقة رمز QR بنجاح ($scanned)!'
                                                    : 'QR code matched successfully ($scanned)!')
                                                : (isAr
                                                    ? 'الرمز الممسوح غير مطابق للكود الفعّال'
                                                    : 'Scanned code does not match active OTP'),
                                          ),
                                          backgroundColor: matched
                                              ? AppColors.teal
                                              : AppColors.danger,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 16,
                                    color: AppColors.teal,
                                  ),
                                  label: Text(
                                    isAr ? 'مسح QR للتحقق' : 'Scan QR',
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  key: const ValueKey(
                                      'parcel_handover_contingency_btn'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navy,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.slateBorder,
                                      width: 1.0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () =>
                                      showMashwarHandoverContingencySheet(
                                    context,
                                    isAr: isAr,
                                    referenceId: widget.parcel.id,
                                    handoverCode:
                                        (deliveryDigits ?? pickupDigits).join(),
                                    onEmergencyFallbackLogged: (record) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isAr
                                                ? 'تم توثيق تسليم الطوارئ (${record.fallbackRef}) باسم ${record.backupContactName}'
                                                : 'Emergency handover logged (${record.fallbackRef}) for ${record.backupContactName}',
                                          ),
                                          backgroundColor: AppColors.teal,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  icon: const Icon(
                                    Icons.battery_alert_rounded,
                                    size: 15,
                                    color: AppColors.navy,
                                  ),
                                  label: Text(
                                    isAr
                                        ? 'البطارية فصلت أو الكاميرا معطّلة؟ حلول بديلة'
                                        : 'Dead battery / broken camera? Fallbacks',
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 5-Step Progress Timeline
                    MashwarSectionCard(
                      borderRadius: 16,
                      borderColor: AppColors.slateBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'مراحل تتبع الشحنة' : 'Shipment Progress',
                            style: AppTypography.title().copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                    const SizedBox(height: 14),

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
    required String qrPayload,
    required Key qrKey,
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
        const SizedBox(height: 10),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              MashwarQrMatrixWidget(
                key: qrKey,
                data: qrPayload,
                size: 74,
                moduleColor: accentColor,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...digits.map((digit) {
                    return Container(
                      width: 42,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        digit,
                        style: AppTypography.title(color: Colors.white)
                            .copyWith(fontSize: 19),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slateBorder),
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
        borderRadius: BorderRadius.circular(16),
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
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'مشاركة التتبع المباشر مع المستلم'
                      : 'Live Tracking for Recipient',
                  style: AppTypography.title().copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
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
            style: AppTypography.bodySmall(color: AppColors.textSecondary)
                .copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
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
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                fontFamily: 'Cairo',
              ),
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
