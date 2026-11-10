import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/settings_provider.dart';
import 'publish_ride_screen.dart';

// Page 45: رحلاتي كسائق (Driver Rides Dashboard)
class DriverRidesScreen extends StatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  State<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends State<DriverRidesScreen> {
  bool _isUpcoming = true;

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
        title: Text(isAr ? 'رحلاتي كسائق' : 'My Driver Trips', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            children: [
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
                          _buildTripCard(
                            route: isAr ? 'كفر الشيخ ← القاهرة' : 'Kafr El-Sheikh → Cairo',
                            date: isAr ? 'الجمعة 6 نوفمبر، 7:30 ص' : 'Fri Nov 6, 7:30 AM',
                            stats: isAr ? '2 حجوزات · 1 طلب جديد' : '2 bookings · 1 new request',
                            badge: isAr ? 'منشورة' : 'Active',
                            badgeType: BadgeType.verified,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DriverRequestsScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTripCard(
                            route: isAr ? 'طنطا ← الإسكندرية' : 'Tanta → Alexandria',
                            date: isAr ? 'السبت 7 نوفمبر، 9:00 ص' : 'Sat Nov 7, 9:00 AM',
                            stats: isAr ? 'لا حجوزات بعد' : 'No bookings yet',
                            badge: isAr ? 'منشورة' : 'Active',
                            badgeType: BadgeType.pending,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DriverRequestsScreen()),
                              );
                            },
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildTripCard(
                            route: isAr ? 'القاهرة ← كفر الشيخ' : 'Cairo → Kafr El-Sheikh',
                            date: isAr ? 'الأحد 25 أكتوبر' : 'Sun Oct 25',
                            stats: isAr ? '3 ركاب · طردين' : '3 passengers · 2 parcels',
                            badge: isAr ? 'مكتملة' : 'Completed',
                            badgeType: BadgeType.verified,
                          ),
                          const SizedBox(height: 12),
                          _buildTripCard(
                            route: isAr ? 'طنطا ← القاهرة' : 'Tanta → Cairo',
                            date: isAr ? 'الخميس 22 أكتوبر' : 'Thu Oct 22',
                            stats: isAr ? 'أُلغيت' : 'Cancelled',
                            badge: isAr ? 'ملغاة' : 'Cancelled',
                            badgeType: BadgeType.rejected,
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
                Text(route, style: AppTypography.title().copyWith(fontSize: 16)),
                MashwarBadge(type: badgeType, customLabel: badge),
              ],
            ),
            const SizedBox(height: 6),
            Text(date, style: AppTypography.bodySecondary()),
            const SizedBox(height: 6),
            Text(stats, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
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
      'passenger': 'ياسمين',
      'route': 'طنطا ← القاهرة',
      'pickup': 'محطة طنطا',
      'dropoff': 'محطة المترو',
      'seats': 1,
      'timeLeft': '24 د',
      'price': 120,
    },
    {
      'id': 'req_r2',
      'passenger': 'كريم',
      'route': 'كفر الشيخ ← القاهرة',
      'pickup': 'مدخل كفر الشيخ',
      'dropoff': 'ميدان رمسيس',
      'seats': 2,
      'timeLeft': '11 د',
      'price': 240,
    },
  ];

  final List<Map<String, dynamic>> _parcelRequests = [
    {
      'id': 'req_p1',
      'sender': 'كريم · موثق',
      'desc': 'صغير · 2 كجم · أوراق',
      'val': 300,
      'fee': 40,
    },
  ];

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
            _buildDetailRow(isAr ? 'الكراسي' : 'Seats', '${item['seats']}'),
            _buildDetailRow(isAr ? 'السعر' : 'Price', '${item['price']} ${isAr ? "ج نقداً" : "EGP Cash"}'),
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
                    onPressed: () => Navigator.of(ctx).pop(),
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
      backgroundColor: Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            children: [
              // Segment tabs (Page 46)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tab == 0 ? AppColors.navy : Colors.white,
                        foregroundColor: _tab == 0 ? Colors.white : AppColors.navy,
                      ),
                      onPressed: () => setState(() => _tab = 0),
                      child: Text(isAr ? 'حجوزات (2)' : 'Bookings (2)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tab == 1 ? AppColors.navy : Colors.white,
                        foregroundColor: _tab == 1 ? Colors.white : AppColors.navy,
                      ),
                      onPressed: () => setState(() => _tab = 1),
                      child: Text(isAr ? 'طرود (1)' : 'Parcels (1)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _tab == 0
                    ? ListView(
                        children: _rideRequests.map((r) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
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
                                    Text(r['passenger'] as String, style: AppTypography.title().copyWith(fontSize: 16)),
                                    MashwarBadge(type: BadgeType.newBadge, customLabel: isAr ? 'جديد' : 'New'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${r['route']} · ${r['seats']} ${isAr ? "كرسي" : "seat"} · ${isAr ? "باقي" : "expires in"} ${r['timeLeft']}',
                                  style: AppTypography.bodySecondary(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${r['price']} ${isAr ? "ج" : "EGP"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.teal),
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {},
                                          child: Text(isAr ? 'رفض' : 'Decline'),
                                        ),
                                        const SizedBox(width: 8),
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
                          );
                        }).toList(),
                      )
                    : ListView(
                        children: _parcelRequests.map((p) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['sender'] as String, style: AppTypography.title().copyWith(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(p['desc'] as String, style: AppTypography.bodySecondary()),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${p['fee']} ${isAr ? "ج" : "EGP"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.teal)),
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
                          );
                        }).toList(),
                      ),
              ),
            ],
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
            Text(isAr ? '$name ما حضرش؟' : '$name did not show up?', style: AppTypography.title()),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(8)),
              child: Text(
                isAr
                    ? 'متاح بعد 15 دقيقة من موعد الالتقاء. هيتسجل عليه ويتفضى الكرسي.'
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
        title: Text(isAr ? 'قبل ما تتحرك' : 'Pre-Trip Manifest', style: AppTypography.title()),
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
                title: 'ياسمين',
                subtitle: isAr ? 'محطة طنطا' : 'Tanta Station',
                icon: Icons.person_rounded,
                onCall: () {},
                onNoShow: () => _reportNoShow(context, 'ياسمين'),
                isAr: isAr,
              ),
              const SizedBox(height: 8),
              _buildManifestItem(
                title: 'كريم',
                subtitle: isAr ? 'مدخل كفر الشيخ' : 'Kafr El-Sheikh Entrance',
                icon: Icons.person_rounded,
                onCall: () {},
                onNoShow: () => _reportNoShow(context, 'كريم'),
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
                          Text(isAr ? 'تسليم إلى سارة أحمد' : 'Deliver to Sara Ahmed', style: AppTypography.bodySecondary()),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.sand,
            child: Icon(icon, color: AppColors.navy),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'الوصول 9:40 ص تقريباً' : 'ETA 9:40 AM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(isAr ? 'باقي 45 كم على نقطة النزول' : '45 km remaining to destination', style: AppTypography.bodySecondary()),
                      ],
                    ),
                    const Spacer(),
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
                          Text(isAr ? 'طرد للتسليم: أوراق → سارة' : 'Parcel to deliver: Docs → Sara', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () {},
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
