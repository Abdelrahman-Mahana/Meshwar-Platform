import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../data/mock_data.dart';
import '../../state/settings_provider.dart';
import '../ride_details/widgets/ride_route_map_view.dart';

// Page 50: تتبع مباشر وضعف الإشارة (Live Tracking & Weak Signal)
class LiveTripTrackingScreen extends StatefulWidget {
  const LiveTripTrackingScreen({super.key});

  @override
  State<LiveTripTrackingScreen> createState() => _LiveTripTrackingScreenState();
}

class _LiveTripTrackingScreenState extends State<LiveTripTrackingScreen> {
  bool _isWeakSignal = false;

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
        title: Text(isAr ? 'رحلتك الآن' : 'Live Trip', style: AppTypography.title()),
        actions: [
          IconButton(
            icon: Icon(_isWeakSignal ? Icons.signal_cellular_connected_no_internet_4_bar_rounded : Icons.signal_cellular_alt_rounded),
            tooltip: isAr ? 'محاكاة ضعف الإشارة' : 'Toggle Weak Signal',
            onPressed: () => setState(() => _isWeakSignal = !_isWeakSignal),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weak Signal Banner (Page 50)
              if (_isWeakSignal) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.navy, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الإشارة ضعيفة. آخر موقع اتسجل من دقيقتين'
                              : 'Weak signal. Last location recorded 2 mins ago',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Route Progress Visual Box (Pages 50, 52)
              RideRouteMapView(ride: MockData.initialRides.first),

              const SizedBox(height: AppDimens.space16),

              // ETA & Driver Info (Page 50)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isWeakSignal
                                  ? (isAr ? 'الوصول المتوقع 9:45 ص (غير دقيق)' : 'Expected ETA 9:45 AM (approx)')
                                  : (isAr ? 'هتوصل 9:40 ص تقريباً' : 'ETA around 9:40 AM'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isAr ? 'باقي 45 كم · آخر تحديث الآن' : '45 km left · Updated now',
                              style: AppTypography.bodySecondary(),
                            ),
                          ],
                        ),
                        MashwarBadge(
                          type: _isWeakSignal ? BadgeType.pending : BadgeType.verified,
                          customLabel: _isWeakSignal ? (isAr ? 'متقطع' : 'Lagging') : (isAr ? 'جارية' : 'Live'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Driver Tile
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.gold,
                          child: const Text('م', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAr ? 'محمد سعيد' : 'Mohamed Saeed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(isAr ? 'هيونداي إلنترا · أ ب ج 1234' : 'Hyundai Elantra · ABC 1234', style: AppTypography.bodySecondary()),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, color: AppColors.teal),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Emergency & Share Buttons (Page 50)
              MashwarButton(
                text: isAr ? 'طوارئ SOS' : 'Emergency SOS',
                variant: MashwarButtonVariant.danger,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const EmergencySosSheet(),
                ),
              ),
              const SizedBox(height: 10),
              MashwarButton(
                text: isAr ? 'مشاركة الرحلة' : 'Share Trip',
                variant: MashwarButtonVariant.secondary,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => const ShareTripSheet(),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 51: مشاركة رحلتك (Share Trip Sheet)
class ShareTripSheet extends StatefulWidget {
  const ShareTripSheet({super.key});

  @override
  State<ShareTripSheet> createState() => _ShareTripSheetState();
}

class _ShareTripSheetState extends State<ShareTripSheet> {
  bool _sentToNadia = false;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    if (_sentToNadia) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 56),
            const SizedBox(height: 16),
            Text(isAr ? 'اتبعت الرابط لنادية' : 'Link sent to Nadia', style: AppTypography.title()),
            const SizedBox(height: 6),
            Text(
              isAr ? 'هتشوف موقعك لحد ما تخلص الرحلة.' : 'She can track your location until trip completes.',
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 20),
            MashwarButton(
              text: isAr ? 'رجوع للرحلة' : 'Back to Trip',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isAr ? 'مشاركة رحلتك' : 'Share your Trip', style: AppTypography.title()),
          const SizedBox(height: 4),
          Text(
            isAr ? 'الرابط بيشتغل أثناء الرحلة بس، وبيتلغي لما تخلص.' : 'Link is active during trip only and expires on arrival.',
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: 16),

          // Contacts
          ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.gold, child: const Text('ن')),
            title: Text(isAr ? 'نادية (أختي)' : 'Nadia (Sister)', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              onPressed: () => setState(() => _sentToNadia = true),
              child: Text(isAr ? 'إرسال' : 'Send'),
            ),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.gold, child: const Text('أ')),
            title: Text(isAr ? 'أحمد (أبويا)' : 'Ahmed (Father)', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              onPressed: () => setState(() => _sentToNadia = true),
              child: Text(isAr ? 'إرسال' : 'Send'),
            ),
          ),

          const Divider(height: 20),

          MashwarButton(
            text: isAr ? 'مشاركة على واتساب' : 'Share via WhatsApp',
            icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isAr ? 'تم نسخ رابط التتبع' : 'Tracking link copied')),
              );
            },
            child: Text(isAr ? 'نسخ الرابط' : 'Copy Link', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Page 53: طوارئ SOS (Emergency SOS Modal)
class EmergencySosSheet extends StatefulWidget {
  const EmergencySosSheet({super.key});

  @override
  State<EmergencySosSheet> createState() => _EmergencySosSheetState();
}

class _EmergencySosSheetState extends State<EmergencySosSheet> {
  bool _sentToContacts = false;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    if (_sentToContacts) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 56),
            const SizedBox(height: 16),
            Text(isAr ? 'بلّغنا نادية وأحمد' : 'Notified Nadia & Ahmed', textAlign: TextAlign.center, style: AppTypography.title()),
            const SizedBox(height: 6),
            Text(
              isAr ? 'وصلهم موقعك وبيانات الرحلة. لو لسه في خطر اتصل بالطوارئ.' : 'They received your location and trip details. If in danger, call 122.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
              onPressed: () {},
              child: Text(isAr ? 'اتصل بـ الشرطة · 122' : 'Call Police · 122'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
              onPressed: () {},
              child: Text(isAr ? 'اتصل بـ الإسعاف · 123' : 'Call Ambulance · 123'),
            ),
            const SizedBox(height: 12),
            MashwarButton(
              text: isAr ? 'أنا بخير الآن' : 'I am safe now',
              variant: MashwarButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isAr ? 'محتاج مساعدة؟' : 'Need emergency help?', style: AppTypography.largeTitle()),
          const SizedBox(height: 4),
          Text(isAr ? 'لو في خطر اتصل بالطوارئ الأول.' : 'If in immediate danger, call emergency services first.', style: AppTypography.bodySecondary()),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {},
            child: Text(isAr ? 'اتصل بـ الشرطة · 122' : 'Call Police · 122', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {},
            child: Text(isAr ? 'اتصل بـ الإسعاف · 123' : 'Call Ambulance · 123', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => setState(() => _sentToContacts = true),
            child: Text(isAr ? 'أرسل موقعي لجهات الطوارئ' : 'Send location to emergency contacts', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    );
  }
}

// Page 54: العربية ابتعدت عن المسار (Off-Route Detection Alert)
class OffRouteAlertSheet extends StatelessWidget {
  const OffRouteAlertSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 52),
          const SizedBox(height: 12),
          Text(
            isAr ? 'العربية ابتعدت عن المسار' : 'Vehicle has deviated from route',
            textAlign: TextAlign.center,
            style: AppTypography.title(),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'ملاحظين إن السائق خرج عن الطريق المتوقع. أنت بخير؟'
                : 'We detected the vehicle left the planned corridor. Are you okay?',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: 24),
          MashwarButton(
            text: isAr ? 'أنا بخير' : 'I am fine',
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr ? 'تمام. هنكمل نتابع الرحلة معاك' : 'Glad you are okay. We will continue tracking.'),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          MashwarButton(
            text: isAr ? 'محتاج مساعدة' : 'Need Help',
            variant: MashwarButtonVariant.danger,
            onPressed: () {
              Navigator.of(context).pop();
              showModalBottomSheet(context: context, builder: (_) => const EmergencySosSheet());
            },
          ),
        ],
      ),
    );
  }
}

// Page 55: إبلاغ وشكوى (Report Issue Screen)
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedCategory;
  final TextEditingController _detailsController = TextEditingController(text: 'السائق كان بيسوق بسرعة عالية جداً');
  bool _isSent = false;

  final List<String> _categoriesAr = [
    'سلوك غير لائق',
    'تحرش',
    'قيادة متهورة',
    'احتيال',
    'طرد مفقود أو تالف',
    'أخرى',
  ];

  final List<String> _categoriesEn = [
    'Inappropriate Behavior',
    'Harassment',
    'Reckless Driving',
    'Fraud / Scam',
    'Lost or Damaged Parcel',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final categories = isAr ? _categoriesAr : _categoriesEn;

    if (_isSent) {
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
                Text(isAr ? 'وصلنا بلاغك' : 'Report Received', style: AppTypography.largeTitle()),
                const SizedBox(height: 6),
                Text(
                  isAr ? 'فريقنا هيراجعه وهنرد عليك. رقم البلاغ #5127' : 'Our safety team is reviewing it. Report #5127',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 24),
                MashwarButton(
                  text: isAr ? 'تمام' : 'Done',
                  onPressed: () => Navigator.of(context).pop(),
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
        title: Text(isAr ? 'إبلاغ عن مشكلة' : 'Report an Issue', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isAr ? 'إيه المشكلة؟' : 'What went wrong?', style: AppTypography.title().copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final cat in categories) ...[
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: _selectedCategory == cat ? AppColors.navy.withValues(alpha: 0.05) : null,
                        leading: Icon(
                          _selectedCategory == cat ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: _selectedCategory == cat ? AppColors.navy : AppColors.textSecondary,
                        ),
                        title: Text(cat, style: TextStyle(fontWeight: _selectedCategory == cat ? FontWeight.w800 : FontWeight.w600)),
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                      const Divider(height: 1),
                    ],
                    const SizedBox(height: 16),
                    Text(isAr ? 'اشرح اللي حصل:' : 'Describe what happened:', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              MashwarButton(
                text: isAr ? 'إرسال البلاغ' : 'Submit Report',
                onPressed: () => setState(() => _isSent = true),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 56: جهات الطوارئ (Emergency Contacts Management)
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<Map<String, String>> _contacts = [
    {'name': 'نادية (أختي)', 'phone': '0101 111 2222'},
    {'name': 'أحمد (أبويا)', 'phone': '0122 333 4444'},
  ];

  void _addContactDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final isAr = context.read<SettingsProvider>().isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'جهة طوارئ جديدة' : 'New Emergency Contact',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'الاسم أو صلة القرابة' : 'Name or Relationship',
              style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F3F4),
                hintText: isAr ? 'مثال: أحمد (أخي)' : 'e.g. Ahmed (Brother)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
              style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F3F4),
                hintText: '010xxxxxxxx',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: AppTypography.body().copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                setState(() {
                  _contacts.add({'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim()});
                });
                Navigator.of(ctx).pop();
              }
            },
            child: Text(isAr ? 'إضافة' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
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
        title: Text(isAr ? 'جهات الطوارئ' : 'Emergency Contacts', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'يتم إشعار هذه الجهات فورياً عند الضغط على زر SOS مع إرسال رابط التتبع المباشر.'
                            : 'These contacts will be notified instantly if you trigger SOS with live tracking.',
                        style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 4),
              child: Text(
                isAr ? '${_contacts.length} من 3 جهات مسجلة' : '${_contacts.length} of 3 maximum contacts',
                style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final c = _contacts[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.contact_phone_rounded, color: AppColors.navy, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(c['phone']!, style: AppTypography.bodySecondary().copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 22),
                          onPressed: () => setState(() => _contacts.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_contacts.length < 3)
              Padding(
                padding: const EdgeInsets.all(AppDimens.space16),
                child: MashwarButton(
                  text: isAr ? 'أضف جهة طوارئ' : 'Add Emergency Contact',
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  onPressed: () => _addContactDialog(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
