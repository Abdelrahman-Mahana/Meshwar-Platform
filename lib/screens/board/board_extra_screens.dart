import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/settings_provider.dart';

// Page 63: إعلاناتي في اللوحة (My Board Ads Screen)
class MyBoardAdsScreen extends StatefulWidget {
  const MyBoardAdsScreen({super.key});

  @override
  State<MyBoardAdsScreen> createState() => _MyBoardAdsScreenState();
}

class _MyBoardAdsScreenState extends State<MyBoardAdsScreen> {
  bool _isActiveTab = true;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

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
        title: Text(isAr ? 'إعلاناتي' : 'My Ads', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            children: [
              // Segmented switch (Page 63)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isActiveTab = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isActiveTab ? AppColors.navy : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'نشطة' : 'Active',
                            style: TextStyle(
                              color: _isActiveTab ? Colors.white : AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isActiveTab = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isActiveTab ? AppColors.navy : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'منتهية' : 'Expired',
                            style: TextStyle(
                              color: !_isActiveTab ? Colors.white : AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _isActiveTab
                    ? ListView(
                        children: [
                          _buildAdCard(
                            typeLabel: isAr ? 'طلب مشوار' : 'Ride Request',
                            route: isAr ? 'طنطا ← القاهرة' : 'Tanta → Cairo',
                            details: isAr ? 'الجمعة بعد الظهر · كرسي واحد' : 'Friday afternoon · 1 seat',
                            offersCount: 3,
                            isAr: isAr,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BoardAdOffersScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildAdCard(
                            typeLabel: isAr ? 'طلب طرد' : 'Parcel Request',
                            route: isAr ? 'الإسكندرية ← القاهرة' : 'Alexandria → Cairo',
                            details: isAr ? 'أوراق · قبل الأحد' : 'Documents · Before Sunday',
                            offersCount: 0,
                            isAr: isAr,
                            onTap: () {},
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          isAr ? 'مفيش إعلانات منتهية' : 'No expired ads',
                          style: AppTypography.bodySecondary(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdCard({
    required String typeLabel,
    required String route,
    required String details,
    required int offersCount,
    required bool isAr,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.borderDisabled),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(typeLabel, style: AppTypography.label(color: AppColors.textSecondary)),
                MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'نشط' : 'Active'),
              ],
            ),
            const SizedBox(height: 6),
            Text(route, style: AppTypography.title().copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text(details, style: AppTypography.bodySecondary()),
            const SizedBox(height: 10),
            Text(
              offersCount > 0
                  ? (isAr ? '$offersCount عروض جديدة' : '$offersCount new offers available')
                  : (isAr ? 'بدون عروض لسه' : 'Waiting for driver offers'),
              style: TextStyle(
                color: offersCount > 0 ? AppColors.teal : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 64: العروض على طلبك (Offers on your Ad)
class BoardAdOffersScreen extends StatefulWidget {
  const BoardAdOffersScreen({super.key});

  @override
  State<BoardAdOffersScreen> createState() => _BoardAdOffersScreenState();
}

class _BoardAdOffersScreenState extends State<BoardAdOffersScreen> {
  bool _accepted = false;

  void _confirmSelection(BuildContext context, String driverName, int price, String time) {
    final isAr = context.read<SettingsProvider>().isArabic;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isAr ? 'تختار عرض $driverName؟' : 'Accept offer from $driverName?', style: AppTypography.title()),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'السعر' : 'Price', style: AppTypography.bodySecondary()),
                Text('$price ${isAr ? "ج نقداً" : "EGP Cash"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'الموعد' : 'Schedule', style: AppTypography.bodySecondary()),
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(8)),
              child: Text(
                isAr ? 'باقي العروض هتتلغي، ورقم $driverName هيظهر لك.' : 'Other offers will cancel, and $driverName\'s phone will be shared.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              text: isAr ? 'تأكيد الاختيار' : 'Confirm Selection',
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _accepted = true);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isAr ? 'رجوع' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    if (_accepted) {
      // Page 64: تم الاختيار (اتفقت مع محمد)
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 64),
                const SizedBox(height: 16),
                Text(isAr ? 'اتفقت مع محمد' : 'Agreed with Mohamed', style: AppTypography.largeTitle()),
                const SizedBox(height: 6),
                Text(
                  isAr ? 'رقمه: 0100 123 4567. هتلاقي التفاصيل في رحلاتي.' : 'Phone: 0100 123 4567. Details saved in My Trips.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 24),
                MashwarButton(
                  text: isAr ? 'اتصل بمحمد' : 'Call Mohamed',
                  icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                  onPressed: () {},
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isAr ? 'رحلاتي' : 'My Trips', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
        title: Text(isAr ? 'العروض على طلبك' : 'Offers on your Request', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'طنطا ← القاهرة · ميزانيتك 80 ج' : 'Tanta → Cairo · Budget 80 EGP', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    _buildOfferCard(
                      driverName: 'محمد سعيد',
                      stats: isAr ? 'موثق · 14 رحلة' : 'Verified · 14 rides',
                      price: 70,
                      time: isAr ? 'الجمعة 1:15 م' : 'Fri 1:15 PM',
                      onSelect: () => _confirmSelection(context, 'محمد', 70, 'الجمعة 1:15 م'),
                      isAr: isAr,
                    ),
                    const SizedBox(height: 10),
                    _buildOfferCard(
                      driverName: 'أحمد علي',
                      stats: isAr ? 'موثق · 6 رحلات' : 'Verified · 6 rides',
                      price: 80,
                      time: isAr ? 'الجمعة 2:00 م' : 'Fri 2:00 PM',
                      onSelect: () => _confirmSelection(context, 'أحمد', 80, 'الجمعة 2:00 م'),
                      isAr: isAr,
                    ),
                    const SizedBox(height: 10),
                    _buildOfferCard(
                      driverName: 'منى حسن',
                      stats: isAr ? 'موثقة · 3 رحلات' : 'Verified · 3 rides',
                      price: 75,
                      time: isAr ? 'الجمعة 12:30 م' : 'Fri 12:30 PM',
                      onSelect: () => _confirmSelection(context, 'منى', 75, 'الجمعة 12:30 م'),
                      isAr: isAr,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String driverName,
    required String stats,
    required int price,
    required String time,
    required VoidCallback onSelect,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold,
            child: Text(driverName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(stats, style: AppTypography.bodySecondary()),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.navy)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$price ${isAr ? "ج" : "EGP"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.teal)),
              const SizedBox(height: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                onPressed: onSelect,
                child: Text(isAr ? 'اختيار' : 'Select'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Page 66: تغيير موعد الرحلة (Reschedule Ride by Driver)
class RescheduleRideScreen extends StatefulWidget {
  const RescheduleRideScreen({super.key});

  @override
  State<RescheduleRideScreen> createState() => _RescheduleRideScreenState();
}

class _RescheduleRideScreenState extends State<RescheduleRideScreen> {
  int _state = 0; // 0: بانتظار قرارك, 1: تمت الموافقة, 2: اتلغى حجزك

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    if (_state == 1) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 64),
                const SizedBox(height: 16),
                Text(isAr ? 'تم تحديث موعدك' : 'Schedule Updated', style: AppTypography.largeTitle()),
                const SizedBox(height: 6),
                Text(isAr ? 'الرحلة هتتحرك الجمعة 9:00 ص.' : 'Trip now departs Friday at 9:00 AM.', style: AppTypography.bodySecondary()),
                const SizedBox(height: 24),
                MashwarButton(text: isAr ? 'عرض الحجز' : 'View Booking', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      );
    }

    if (_state == 2) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 64),
                const SizedBox(height: 16),
                Text(isAr ? 'اتلغى حجزك' : 'Booking Cancelled', style: AppTypography.largeTitle()),
                const SizedBox(height: 6),
                Text(
                  isAr ? 'مفيش أي أثر على معدل إلغائك لأن السائق هو اللي عدّل الموعد.' : 'Zero impact on cancellation rate because driver rescheduled.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 24),
                MashwarButton(text: isAr ? 'ابحث عن رحلة تانية' : 'Search Other Rides', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'تغيير موعد الرحلة' : 'Ride Rescheduled', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.goldSurface, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  isAr ? 'محمد غيّر موعد الرحلة. محتاجين موافقتك' : 'Driver changed departure time. Need your decision',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
                child: Column(
                  children: [
                    _buildRow(isAr ? 'الرحلة' : 'Route', 'كفر الشيخ ← القاهرة'),
                    const Divider(height: 16),
                    _buildRow(isAr ? 'الموعد القديم' : 'Previous Time', 'الجمعة 7:30 ص'),
                    const Divider(height: 16),
                    _buildRow(isAr ? 'الموعد الجديد' : 'New Time', 'الجمعة 9:00 ص', isHighlighted: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isAr
                    ? 'لو الموعد الجديد مش مناسب تقدر تلغي حجزك بدون أي أثر على معدل إلغائك. باقي 2:00 ساعة للرد.'
                    : 'If new time does not suit you, cancel penalty-free. 2 hours remaining.',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
              const Spacer(),
              MashwarButton(
                text: isAr ? 'وافق على الموعد الجديد' : 'Accept New Time',
                onPressed: () => setState(() => _state = 1),
              ),
              const SizedBox(height: 10),
              MashwarButton(
                text: isAr ? 'ألغي حجزي' : 'Cancel My Booking',
                variant: MashwarButtonVariant.danger,
                onPressed: () => setState(() => _state = 2),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySecondary()),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppColors.teal : AppColors.navy,
          ),
        ),
      ],
    );
  }
}
