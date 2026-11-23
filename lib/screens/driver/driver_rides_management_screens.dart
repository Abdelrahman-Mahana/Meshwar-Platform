import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../board/board_extra_screens.dart';
import '../chat/chat_screen.dart';
import '../safety/safety_screens.dart';
import 'publish_ride_screen.dart';

// Page 45: رحلاتي كسائق (Driver Rides Dashboard)
class DriverRidesScreen extends StatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  State<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends State<DriverRidesScreen> {
  bool _isUpcoming = true;

  void _showDriverEarningsAnalyticsSheet(BuildContext context, bool isAr, int publishedCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isAr ? 'تقرير أرباح وإحصائيات السائق' : 'Driver Earnings & Trip Analytics',
                      style: AppTypography.title(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'إجمالي أرباح الشهر الحالي' : 'Current Month Total Earnings',
                      style: AppTypography.label(color: AppColors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? '1,850 ر.ق' : '1,850 QAR',
                      style: AppTypography.largeTitle(color: AppColors.navy).copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'وفرّت نحو 78% من تكاليف الوقود والصيانة عبر مشاركة المقاعد والطرود.'
                          : 'Saved ~78% of fuel & maintenance costs via shared seats and parcels.',
                      style: AppTypography.bodySecondary(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      isAr ? 'الرحلات المكتملة' : 'Completed Trips',
                      '14',
                      Icons.directions_car_filled_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      isAr ? 'الطرود المسلمة' : 'Parcels Delivered',
                      '9',
                      Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      isAr ? 'تقييم السائق' : 'Driver Rating',
                      '4.9 ★',
                      Icons.star_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MashwarButton(
                text: isAr ? 'حسناً' : 'Done',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.title().copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final publishedRides = context.watch<RidesProvider>().myPublishedRides;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'رحلاتي كسائق' : 'My Driver Trips', style: AppTypography.title()),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.teal),
            tooltip: isAr ? 'أرباحي وإحصائياتي' : 'Earnings & Analytics',
            onPressed: () => _showDriverEarningsAnalyticsSheet(context, isAr, publishedRides.length),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            children: [
              // Driver Earnings Summary Banner
              MashwarFadeSlideIn(
                child: MashwarPressable(
                  onTap: () => _showDriverEarningsAnalyticsSheet(context, isAr, publishedRides.length),
                  child: MashwarSectionCard(
                    backgroundColor: AppColors.tealSurface,
                    borderColor: AppColors.teal.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: const MashwarAssetArt(
                            assetPath: 'assets/images/driver_promo.jpg',
                            width: 48,
                            height: 48,
                            fallbackIcon: Icons.insights_rounded,
                            fallbackBg: Colors.white,
                            fallbackColor: AppColors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'أرباحك هذا الشهر: 1,850 ر.ق' : 'Monthly Earnings: 1,850 QAR',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body().copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
                              ),
                              Text(
                                isAr ? 'اضغط لعرض تفاصيل الأرباح وتوفير الوقود' : 'Tap to view earnings & fuel savings breakdown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.teal),
                      ],
                    ),
                  ),
                ),
              ),

              // Segmented switch (Page 45)
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
                        onTap: () => setState(() => _isUpcoming = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isUpcoming ? AppColors.navy : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'قادمة' : 'Upcoming',
                            style: TextStyle(
                              color: _isUpcoming ? Colors.white : AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isUpcoming = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isUpcoming ? AppColors.navy : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'سابقة' : 'Past',
                            style: TextStyle(
                              color: !_isUpcoming ? Colors.white : AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              Expanded(
                child: _isUpcoming
                    ? ListView(
                        children: [
                          for (final ride in publishedRides) ...[
                            _buildTripCard(
                              route: '${ride.fromCity} ← ${ride.toCity}',
                              date: '${ride.departureDate}، ${ride.departureTime}',
                              stats: isAr
                                  ? '${ride.remainingSeats} مقاعد متاحة · ${ride.pricePerSeat} ر.ق/مقعد'
                                  : '${ride.remainingSeats} seats left · ${ride.pricePerSeat} QAR/seat',
                              badge: isAr ? 'منشورة' : 'Active',
                              badgeType: BadgeType.verified,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const DriverRequestsScreen()),
                                );
                              },
                              onReschedule: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RescheduleRideScreen()),
                                );
                              },
                              isAr: isAr,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildTripCard(
                            route: isAr ? 'الوكرة ← لوسيل' : 'Al Wakrah → Lusail',
                            date: isAr ? 'السبت 7 نوفمبر، 9:00 ص' : 'Sat Nov 7, 9:00 AM',
                            stats: isAr ? 'لا حجوزات بعد' : 'No bookings yet',
                            badge: isAr ? 'منشورة' : 'Active',
                            badgeType: BadgeType.pending,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DriverRequestsScreen()),
                              );
                            },
                            onReschedule: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RescheduleRideScreen()),
                              );
                            },
                            isAr: isAr,
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildTripCard(
                            route: isAr ? 'الخور ← الدوحة' : 'Al Khor → Doha',
                            date: isAr ? 'الأحد 25 أكتوبر' : 'Sun Oct 25',
                            stats: isAr ? '3 ركاب · طردان' : '3 passengers · 2 parcels',
                            badge: isAr ? 'مكتملة' : 'Completed',
                            badgeType: BadgeType.verified,
                            isAr: isAr,
                          ),
                          const SizedBox(height: 12),
                          _buildTripCard(
                            route: isAr ? 'الريان ← دخان' : 'Al Rayyan → Dukhan',
                            date: isAr ? 'الخميس 22 أكتوبر' : 'Thu Oct 22',
                            stats: isAr ? 'أُلغيت' : 'Cancelled',
                            badge: isAr ? 'ملغاة' : 'Cancelled',
                            badgeType: BadgeType.rejected,
                            isAr: isAr,
                          ),
                        ],
                      ),
              ),

              // Publish CTA at bottom (Page 45)
              MashwarButton(
                text: isAr ? 'انشر رحلة جديدة' : 'Post New Ride',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PublishRideScreen()),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard({
    required String route,
    required String date,
    required String stats,
    required String badge,
    required BadgeType badgeType,
    required bool isAr,
    VoidCallback? onTap,
    VoidCallback? onReschedule,
  }) {
    final parts = route.split(RegExp(r'\s*[←→]\s*'));
    final fromLabel = parts.isNotEmpty ? parts.first : route;
    final toLabel = parts.length > 1 ? parts.last : route;
    return MashwarFadeSlideIn(
      offsetY: 12,
      child: MashwarPressable(
        onTap: onTap,
        child: MashwarSectionCard(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MashwarRouteTimeline(
                      from: fromLabel,
                      to: toLabel,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MashwarBadge(type: badgeType, customLabel: badge),
                ],
              ),
              const SizedBox(height: 8),
              Text(date, style: AppTypography.bodySecondary()),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stats,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  if (onReschedule != null)
                    TextButton.icon(
                      onPressed: onReschedule,
                      icon: const Icon(Icons.schedule_rounded, size: 15, color: AppColors.navy),
                      label: Text(
                        isAr ? 'تعديل الموعد' : 'Reschedule',
                        style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 46: طلبات الحجوزات والطرود للسائق (Incoming Driver Requests)
class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  int _tab = 0; // 0: حجوزات, 1: طرود

  final List<Map<String, dynamic>> _rideRequests = [
    {
      'id': 'req_r1',
      'passenger': 'نورة العطية',
      'route': 'الوكرة ← الدوحة',
      'pickup': 'محطة مترو الوكرة',
      'dropoff': 'مترو مشيرب',
      'seats': 1,
      'timeLeft': '24 د',
      'price': 25,
    },
    {
      'id': 'req_r2',
      'passenger': 'تميم الهاجري',
      'route': 'الخور ← الدوحة',
      'pickup': 'مدخل الخور الرئيسي',
      'dropoff': 'برج الدفنة',
      'seats': 2,
      'timeLeft': '11 د',
      'price': 70,
    },
  ];

  final List<Map<String, dynamic>> _parcelRequests = [
    {
      'id': 'req_p1',
      'sender': 'حمد الكواري · موثق',
      'desc': 'صغير · 2 كجم · أوراق',
      'val': 300,
      'fee': 25,
    },
  ];

  void _declineRequest(String id, String passengerName, bool isAr) {
    setState(() {
      _rideRequests.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم رفض طلب $passengerName' : 'Declined request from $passengerName'),
        backgroundColor: AppColors.coral,
      ),
    );
  }

  void _showPassengerDetails(BuildContext context, Map<String, dynamic> item) {
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
            Text(isAr ? 'طلب حجز مقعد' : 'Seat Booking Request', style: AppTypography.title()),
            const SizedBox(height: 12),
            _buildDetailRow(isAr ? 'الراكب' : 'Passenger', item['passenger'] as String),
            _buildDetailRow(isAr ? 'الصعود' : 'Pickup', item['pickup'] as String),
            _buildDetailRow(isAr ? 'النزول' : 'Dropoff', item['dropoff'] as String),
            _buildDetailRow(isAr ? 'المقاعد' : 'Seats', '${item['seats']}'),
            _buildDetailRow(isAr ? 'السعر' : 'Price', '${item['price']} ${isAr ? "ر.ق نقداً" : "QAR Cash"}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MashwarButton(
                    text: isAr ? 'قبول' : 'Accept',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DriverPreTripScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MashwarButton(
                    text: isAr ? 'رفض' : 'Decline',
                    variant: MashwarButtonVariant.danger,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _declineRequest(item['id'] as String, item['passenger'] as String, isAr);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: AppTypography.bodySecondary()),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'الطلبات' : 'Incoming Requests', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                children: [
                  // Segment tabs (Page 46)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tab == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAr ? 'حجوزات (${_rideRequests.length})' : 'Bookings (${_rideRequests.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tab == 0 ? AppColors.navy : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tab == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAr ? 'طرود (${_parcelRequests.length})' : 'Parcels (${_parcelRequests.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tab == 1 ? AppColors.navy : AppColors.textSecondary,
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
                    child: _tab == 0
                        ? (_rideRequests.isEmpty
                            ? Center(
                                child: Text(
                                  isAr ? 'لا توجد طلبات حجز معلقة حالياً' : 'No pending booking requests',
                                  style: AppTypography.bodySecondary(),
                                ),
                              )
                            : ListView(
                                children: _rideRequests.map((r) {
                                  final routeText = (r['route'] as String?) ?? '';
                                  final routeParts = routeText.split(RegExp(r'\s*[←→]\s*'));
                                  final fromCity = routeParts.isNotEmpty ? routeParts.first : routeText;
                                  final toCity = routeParts.length > 1 ? routeParts.last : routeText;
                                  final passengerName = r['passenger'] as String;
                                  return MashwarFadeSlideIn(
                                    offsetY: 10,
                                    child: MashwarSectionCard(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: AppColors.gold, width: 1.5),
                                                ),
                                                child: CircleAvatar(
                                                  radius: 17,
                                                  backgroundColor: AppColors.goldSurface,
                                                  child: Text(
                                                    passengerName[0],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  passengerName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.title().copyWith(fontSize: 16),
                                                ),
                                              ),
                                              MashwarBadge(type: BadgeType.newBadge, customLabel: isAr ? 'جديد' : 'New'),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          MashwarRouteTimeline(
                                            from: fromCity,
                                            to: toCity,
                                            compact: true,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${r['seats']} ${isAr ? "مقعد" : "seat"} · ${isAr ? "متبقي" : "expires in"} ${r['timeLeft']}',
                                            style: AppTypography.bodySecondary(),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${r['price']} ${isAr ? "ر.ق" : "QAR"}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.teal),
                                              ),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  IconButton(
                                                    visualDensity: VisualDensity.compact,
                                                    tooltip: isAr ? 'محادثة الراكب' : 'Chat Passenger',
                                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppColors.navy),
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) => ChatScreen(
                                                            driverName: passengerName,
                                                            driverCar: isAr ? 'طلب حجز مقعد' : 'Seat Booking Request',
                                                            tripRoute: routeText,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  OutlinedButton(
                                                    onPressed: () => _declineRequest(r['id'] as String, passengerName, isAr),
                                                    child: Text(isAr ? 'رفض' : 'Decline'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                                                    onPressed: () => _showPassengerDetails(context, r),
                                                    child: Text(isAr ? 'قبول' : 'Accept'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ))
                        : ListView(
                            children: _parcelRequests.map((p) {
                              final senderName = p['sender'] as String;
                              return MashwarFadeSlideIn(
                                offsetY: 10,
                                child: MashwarSectionCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(senderName, style: AppTypography.title().copyWith(fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(p['desc'] as String, style: AppTypography.bodySecondary()),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${p['fee']} ${isAr ? "ر.ق" : "QAR"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.teal)),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                tooltip: isAr ? 'محادثة المرسل' : 'Chat Sender',
                                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppColors.navy),
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ChatScreen(
                                                        driverName: senderName,
                                                        driverCar: isAr ? 'طلب توصيل طرد' : 'Parcel Request',
                                                        tripRoute: p['desc'] as String,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(builder: (_) => const DriverPreTripScreen()),
                                                  );
                                                },
                                                child: Text(isAr ? 'قبول' : 'Accept'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Page 47: قائمة الركاب والطرود قبل ما تتحرك (Driver Pre-Trip Manifest)
class DriverPreTripScreen extends StatefulWidget {
  const DriverPreTripScreen({super.key});

  @override
  State<DriverPreTripScreen> createState() => _DriverPreTripScreenState();
}

class _DriverPreTripScreenState extends State<DriverPreTripScreen> {
  void _reportNoShow(BuildContext context, String name) {
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
            Text(isAr ? '$name لم يحضر؟' : '$name did not show up?', style: AppTypography.title()),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(8)),
              child: Text(
                isAr
                    ? 'متاح بعد 15 دقيقة من موعد الالتقاء. سيتم تسجيل عدم الحضور وإتاحة المقعد.'
                    : 'Available after 15 mins past meetup. Will record penalty on rider and free up seat.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              text: isAr ? 'تأكيد: لم يحضر' : 'Confirm: No Show',
              variant: MashwarButtonVariant.danger,
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تم تسجيل عدم حضور الراكب' : 'Rider marked as no show'),
                    backgroundColor: AppColors.coral,
                  ),
                );
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

  void _callPassenger(BuildContext context, String name, bool isAr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'جاري الاتصال بالراكب $name...' : 'Calling passenger $name...'),
        backgroundColor: AppColors.teal,
      ),
    );
  }

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
        title: Text(isAr ? 'قائمة الرحلة' : 'Pre-Trip Manifest', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Passengers Section (Page 47)
              Text(isAr ? 'الركاب (2)' : 'Passengers (2)', style: AppTypography.title().copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              _buildManifestItem(
                title: 'نورة العطية',
                subtitle: isAr ? 'محطة مترو الوكرة' : 'Al Wakrah Metro Station',
                icon: Icons.person_rounded,
                onCall: () => _callPassenger(context, 'نورة العطية', isAr),
                onNoShow: () => _reportNoShow(context, 'نورة العطية'),
                isAr: isAr,
              ),
              const SizedBox(height: 8),
              _buildManifestItem(
                title: 'تميم الهاجري',
                subtitle: isAr ? 'مدخل الخور الرئيسي' : 'Al Khor Main Entrance',
                icon: Icons.person_rounded,
                onCall: () => _callPassenger(context, 'تميم الهاجري', isAr),
                onNoShow: () => _reportNoShow(context, 'تميم الهاجري'),
                isAr: isAr,
              ),

              const SizedBox(height: AppDimens.space20),

              // Parcels Section (Page 47)
              Text(isAr ? 'الطرود (1)' : 'Parcels (1)', style: AppTypography.title().copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.navy, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'أوراق · صغير' : 'Documents · Small', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(isAr ? 'تسليم إلى نورة الكواري' : 'Deliver to Noura Al-Kuwari', style: AppTypography.bodySecondary()),
                        ],
                      ),
                    ),
                    MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'في عهدتك' : 'With Driver'),
                  ],
                ),
              ),

              const Spacer(),

              // Start Trip CTA (Page 47)
              MashwarButton(
                text: isAr ? 'بدأت الرحلة' : 'Start Trip Now',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DriverInTransitScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManifestItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onCall,
    required VoidCallback onNoShow,
    required bool isAr,
  }) {
    return MashwarSectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.sand,
              child: Icon(icon, color: AppColors.navy),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: AppTypography.bodySecondary()),
              ],
            ),
          ),
          TextButton(
            onPressed: onNoShow,
            child: Text(isAr ? 'لم يحضر' : 'No Show', style: const TextStyle(color: AppColors.coral, fontSize: 12)),
          ),
          IconButton(
            tooltip: isAr ? 'محادثة' : 'Chat',
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.navy, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    driverName: title,
                    driverCar: subtitle,
                    tripRoute: isAr ? 'نقطة التجمع' : 'Pickup Point',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: isAr ? 'اتصال' : 'Call',
            icon: const Icon(Icons.phone_rounded, color: AppColors.teal),
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}

// Page 48: الرحلة جارية للسائق وإدخال كود التسليم (Driver In-Transit & Parcel Handover)
class DriverInTransitScreen extends StatefulWidget {
  const DriverInTransitScreen({super.key});

  @override
  State<DriverInTransitScreen> createState() => _DriverInTransitScreenState();
}

class _DriverInTransitScreenState extends State<DriverInTransitScreen> {
  void _openHandoverCodeSheet(BuildContext context) {
    final isAr = context.read<SettingsProvider>().isArabic;
    final codeCtrl = TextEditingController();
    bool isError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard))),
      builder: (ctx) => StatefulBuilder(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isAr ? 'تسليم الطرد' : 'Parcel Handover', style: AppTypography.title()),
                const SizedBox(height: 6),
                Text(
                  isAr ? 'اطلب كود التسليم من المستلمة سارة' : 'Ask recipient Sara for the 4-digit code',
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.sand,
                    errorText: isError ? (isAr ? 'الكود غلط. باقي لك محاولتان' : 'Wrong code. 2 attempts left') : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                MashwarButton(
                  text: isAr ? 'تأكيد التسليم' : 'Confirm Delivery',
                  onPressed: () {
                    if (codeCtrl.text == '4821') {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAr ? 'تم تسليم الطرد بنجاح!' : 'Parcel successfully delivered!'),
                          backgroundColor: AppColors.teal,
                        ),
                      );
                    } else {
                      setSheetState(() => isError = true);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isAr ? 'رجوع' : 'Back'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'الرحلة جارية' : 'In Transit (Driver)', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ETA Card (Page 48)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.teal),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: AppColors.teal, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'الوصول 9:40 ص تقريباً' : 'ETA 9:40 AM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            isAr ? 'باقي 45 كم على نقطة النزول' : '45 km remaining to destination',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySecondary(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'جارية' : 'Live'),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // Deliver with code tile (Page 48)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.navy, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'طرد للتسليم: أوراق ← سارة' : 'Parcel to deliver: Docs → Sara', style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
                          Text(isAr ? 'اطلب الكود عند الالتقاء' : 'Verify recipient code', style: AppTypography.bodySecondary()),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                      onPressed: () => _openHandoverCodeSheet(context),
                      child: Text(isAr ? 'سلّم بالكود' : 'Deliver Code'),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // End Trip CTA (Page 48)
              MashwarButton(
                text: isAr ? 'انتهت الرحلة' : 'End Trip',
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم إنهاء الرحلة وتسجيل الأرباح في المحفظة' : 'Trip ended & earnings credited'),
                      backgroundColor: AppColors.teal,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const EmergencySosSheet(),
                  );
                },
                child: Text(isAr ? 'طوارئ SOS' : 'Emergency SOS', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

