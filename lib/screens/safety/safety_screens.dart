import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/mock_data.dart';
import '../../data/models/ride_model.dart';
import '../../data/services/google_maps_service.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

String _buildSafetyGoogleMapsDirectionsUrl(String fromCity, String toCity) {
  final origin = '${fromCity.trim().isNotEmpty ? fromCity.trim() : 'الدوحة'}, Qatar';
  final dest = '${toCity.trim().isNotEmpty ? toCity.trim() : 'الخور'}, Qatar';
  return 'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(dest)}'
      '&travelmode=driving';
}

Future<bool> launchMashwarExternalUri(Uri uri, {LaunchMode? mode}) async {
  try {
    final override = EmergencySosSheet.debugUrlLauncher;
    if (override != null) {
      return await override(uri);
    }
    if (mode != null) {
      return await launchUrl(uri, mode: mode);
    }
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

Future<void> _confirmAndCallOperationsSupport(
  BuildContext context,
  bool isAr,
) async {
  const opsPhone = '+97444009999';
  const opsDisplay = '+974 4400 9999';
  final messenger = ScaffoldMessenger.maybeOf(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: AppColors.navy, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr
                  ? 'الاتصال بغرفة عمليات وأمان مشوار'
                  : 'Call MASHWAR Safety Operations',
              style: AppTypography.title().copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
      content: Text(
        isAr
            ? 'هل ترغب في الاتصال المباشر بفريق العمليات والطوارئ على الرقم $opsDisplay؟ (في حالات الخطر الفوري اتصل بـ 999).'
            : 'Call MASHWAR 24/7 Safety Operations at $opsDisplay? (For immediate life-threatening emergencies, dial 999).',
        style: AppTypography.bodySecondary(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            isAr ? 'إلغاء' : 'Cancel',
            style: AppTypography.label(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          key: const ValueKey('confirm_call_ops_support_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
          label: Text(isAr ? 'اتصال الآن' : 'Call Now'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  final launched = await launchMashwarExternalUri(Uri(scheme: 'tel', path: opsPhone));
  if (!launched) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تعذّر فتح تطبيق الهاتف تلقائياً. يرجى الاتصال بعمليات مشوار على $opsDisplay.'
              : 'Phone dialer unavailable on this device. Please call $opsDisplay.',
        ),
        backgroundColor: AppColors.navy,
      ),
    );
  }
}

// Page 50: تتبع مباشر وضعف الإشارة (Live Tracking & Weak Signal)
class LiveTripTrackingScreen extends StatefulWidget {
  const LiveTripTrackingScreen({super.key, this.ride});

  final RideModel? ride;

  @override
  State<LiveTripTrackingScreen> createState() => _LiveTripTrackingScreenState();
}

class _LiveTripTrackingScreenState extends State<LiveTripTrackingScreen> {
  final bool _isWeakSignal = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final activeRide = widget.ride ?? MockData.initialRides.first;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
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
        title: Text(
          isAr ? 'رحلتك الآن' : 'Live Trip',
          style: AppTypography.title(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navy),
            tooltip: isAr ? 'مشاركة مسار الرحلة' : 'Share Live Trip',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ShareTripSheet(ride: activeRide),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isWeakSignal) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'الإشارة ضعيفة. آخر موقع مسجل منذ دقيقتين'
                                  : 'Weak signal. Last location recorded 2 mins ago',
                              style: AppTypography.label(color: AppColors.navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Live Embedded Google Map inside Safety Live Tracking
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: MashwarEmbeddedGoogleMap(
                      key: const ValueKey('safety_live_embedded_gmap'),
                      origin: activeRide.fromCity,
                      destination: activeRide.toCity,
                      stopover: activeRide.stopoverCity,
                      vehicleMode: MashwarMapVehicleMode.trip,
                      showTraffic: true,
                      height: 270,
                      borderRadius: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1-Tap In-App Google Maps Route Button
                  OutlinedButton.icon(
                    key: const ValueKey('safety_live_open_gmaps_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.slateBorder),
                      minimumSize: const Size(
                        double.infinity,
                        AppDimens.secondaryButtonHeight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusButton,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      final override = EmergencySosSheet.debugUrlLauncher;
                      if (override != null) {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final url = _buildSafetyGoogleMapsDirectionsUrl(
                          activeRide.fromCity,
                          activeRide.toCity,
                        );
                        final ok = await override(Uri.parse(url));
                        if (!ok) {
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
                        origin: activeRide.fromCity,
                        destination: activeRide.toCity,
                        stopover: activeRide.stopoverCity,
                        vehicleMode: MashwarMapVehicleMode.trip,
                        showTraffic: true,
                        titleAr:
                            'التتبع المباشر · ${activeRide.fromCity} ← ${activeRide.toCity}',
                        titleEn:
                            'Live Route · ${activeRide.fromCity} → ${activeRide.toCity}',
                      );
                    },
                    icon: const Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: AppColors.teal,
                    ),
                    label: Text(
                      isAr
                          ? 'تكبير خريطة المسار المباشر داخل التطبيق'
                          : 'Open Live Route Map In-App',
                      style: AppTypography.button(color: AppColors.navy)
                          .copyWith(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: AppDimens.space16),

                  // ETA & Driver Info Card
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isWeakSignal
                                        ? (isAr
                                            ? 'الوصول المتوقع 9:45 ص (تقريبي)'
                                            : 'Expected ETA 9:45 AM (approx)')
                                        : (isAr
                                            ? 'الوصول المتوقع 9:40 ص'
                                            : 'ETA around 9:40 AM'),
                                    style: AppTypography.body(
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    isAr
                                        ? 'متبقي 45 كم · محدّث الآن'
                                        : '45 km remaining · Updated now',
                                    style: AppTypography.bodySecondary(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            MashwarBadge(
                              type: _isWeakSignal
                                  ? BadgeType.pending
                                  : BadgeType.verified,
                              customLabel: _isWeakSignal
                                  ? (isAr ? 'متقطع' : 'Lagging')
                                  : (isAr ? 'جارية' : 'Live'),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.slateBorder),
                        Row(
                          children: [
                            MashwarUserAvatar(
                              avatarUrl: null,
                              fullName: activeRide.driverName,
                              size: 44,
                              borderWidth: 1.5,
                              borderColor: AppColors.slateBorder,
                              autoCommunityPortrait: true,
                              showVerifiedBadge: activeRide.isVerified,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeRide.driverName,
                                    style: AppTypography.body(
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    activeRide.driverCar,
                                    style: AppTypography.bodySecondary(),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('live_trip_call_driver_btn'),
                              icon: const Icon(
                                Icons.phone_in_talk_rounded,
                                color: AppColors.teal,
                              ),
                              onPressed: () async {
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                final phone = activeRide.driverPhone
                                        .replaceAll(' ', '')
                                        .startsWith('+')
                                    ? activeRide.driverPhone.replaceAll(' ', '')
                                    : '+97455234567';
                                final uri = Uri(scheme: 'tel', path: phone);
                                final launched = await launchMashwarExternalUri(uri);
                                if (!launched) {
                                  messenger?.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAr
                                            ? 'لا يدعم هذا الجهاز الاتصال الهاتفي المباشر ($phone).'
                                            : 'This device lacks a phone handler. Dial $phone manually.',
                                      ),
                                      backgroundColor: AppColors.navy,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Calm Executive Safety Operations Support Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.tealSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.teal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'دعم العمليات والأمان 24/7'
                                    : '24/7 Safety Operations Desk',
                                style: AppTypography.body(color: AppColors.navy)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                isAr
                                    ? 'تواصل هاتفي فوري مع فريق متابعة الطرق'
                                    : 'Direct phone line to route safety specialists',
                                style: AppTypography.bodySmall(),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          key: const ValueKey('safety_call_ops_btn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.slateBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () =>
                              _confirmAndCallOperationsSupport(context, isAr),
                          child: Text(isAr ? 'اتصال' : 'Call'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  MashwarButton(
                    text: isAr ? 'طوارئ SOS' : 'Emergency SOS',
                    variant: MashwarButtonVariant.danger,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusBottomSheet),
                        ),
                      ),
                      builder: (_) => const EmergencySosSheet(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MashwarButton(
                    text: isAr ? 'مشاركة الرحلة' : 'Share Trip',
                    variant: MashwarButtonVariant.secondary,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => ShareTripSheet(ride: activeRide),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Page 51: مشاركة رحلتك (Share Trip Sheet)
class ShareTripSheet extends StatefulWidget {
  const ShareTripSheet({
    super.key,
    this.ride,
    this.origin,
    this.destination,
  });

  final RideModel? ride;
  final String? origin;
  final String? destination;

  @override
  State<ShareTripSheet> createState() => _ShareTripSheetState();
}

class _ShareTripSheetState extends State<ShareTripSheet> {
  String? _sentToNameAr;
  String? _sentToNameEn;
  bool _showAddContactForm = false;
  final TextEditingController _customNameCtrl = TextEditingController();
  final TextEditingController _customPhoneCtrl = TextEditingController();
  late List<Map<String, String>> _contacts;
  bool _contactsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_contactsInitialized) {
      _contactsInitialized = true;
      final auth = Provider.of<AuthProvider?>(context, listen: false);
      final savedName = auth?.user.emergencyContactName?.trim() ?? '';
      final savedPhone = auth?.user.emergencyContactPhone?.trim() ?? '';
      _contacts = [
        if (savedName.isNotEmpty)
          {
            'nameAr': savedName,
            'nameEn': savedName,
            'phone': savedPhone.isNotEmpty ? savedPhone : '5500 1122',
          },
        {
          'nameAr': 'نادية (أختي)',
          'nameEn': 'Nadia (Sister)',
          'phone': '5511 2233',
        },
        {
          'nameAr': 'أحمد (والدي)',
          'nameEn': 'Ahmed (Father)',
          'phone': '6622 3344',
        },
      ];
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _customPhoneCtrl.dispose();
    super.dispose();
  }

  String get _fromCity =>
      widget.origin ?? widget.ride?.fromCity ?? 'الدوحة';
  String get _toCity =>
      widget.destination ?? widget.ride?.toCity ?? 'الخور';
  String get _gmapsRouteUrl =>
      _buildSafetyGoogleMapsDirectionsUrl(_fromCity, _toCity);

  String _buildShareMessage(bool isAr) {
    final driverInfo = widget.ride != null
        ? ' (${widget.ride!.driverName} · ${widget.ride!.driverCar})'
        : '';
    return isAr
        ? 'تابع رحلتي المباشرة عبر مشوار ($_fromCity ← $_toCity)$driverInfo:\n$_gmapsRouteUrl'
        : 'Track my live MASHWAR trip ($_fromCity -> $_toCity)$driverInfo:\n$_gmapsRouteUrl';
  }

  Future<void> _copyRouteLink(BuildContext context, bool isAr) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: _gmapsRouteUrl));
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم نسخ رابط التتبع ومسار Google Maps'
              : 'Live trip & Google Maps link copied',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  Future<void> _openRouteInGoogleMaps(BuildContext context, bool isAr) async {
    final override = EmergencySosSheet.debugUrlLauncher;
    if (override != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final ok = await override(Uri.parse(_gmapsRouteUrl));
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: _gmapsRouteUrl));
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم نسخ رابط المسار في Google Maps إلى الحافظة'
                  : 'Google Maps route URL copied to clipboard',
            ),
            backgroundColor: AppColors.navy,
          ),
        );
      }
      return;
    }

    await openMashwarInAppMap(
      context,
      origin: _fromCity,
      destination: _toCity,
      stopover: widget.ride?.stopoverCity,
      vehicleMode: MashwarMapVehicleMode.trip,
      showTraffic: true,
      titleAr: 'مسار الرحلة · $_fromCity ← $_toCity',
      titleEn: 'Trip Route · $_fromCity → $_toCity',
    );
  }

  Future<void> _shareViaWhatsApp(BuildContext context, bool isAr) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);
    final message = _buildShareMessage(isAr);
    final waUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    await Clipboard.setData(ClipboardData(text: _gmapsRouteUrl));
    final ok = await launchMashwarExternalUri(
      waUri,
      mode: LaunchMode.externalApplication,
    );
    if (nav.canPop()) {
      nav.pop();
    }
    if (!ok) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم نسخ رابط الرحلة ومسار Google Maps للمشاركة'
                : 'Live trip & Google Maps link copied for sharing',
          ),
          backgroundColor: AppColors.teal,
        ),
      );
    }
  }

  void _saveCustomContact() {
    final name = _customNameCtrl.text.trim();
    final phone = _customPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    Provider.of<AuthProvider?>(context, listen: false)?.updateProfile(
      emergencyContactName: name,
      emergencyContactPhone: phone,
    );
    setState(() {
      _contacts.insert(0, {
        'nameAr': name,
        'nameEn': name,
        'phone': phone,
      });
      _customNameCtrl.clear();
      _customPhoneCtrl.clear();
      _showAddContactForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    Widget wrapSurface(Widget child) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusBottomSheet),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.space24,
                  AppDimens.space20,
                  AppDimens.space24,
                  AppDimens.space24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    if (_sentToNameAr != null) {
      return wrapSurface(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teal,
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              isAr
                  ? 'تم إرسال رابط التتبع إلى $_sentToNameAr'
                  : 'Link sent to $_sentToNameEn',
              textAlign: TextAlign.center,
              style: AppTypography.title(),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'تم نسخ رابط مسار Google Maps ويمكن متابعة موقعك حتى الوصول.'
                  : 'Google Maps route link copied and active until arrival.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              text: isAr
                  ? 'عرض خريطة المسار داخل التطبيق'
                  : 'View Route Map In-App',
              variant: MashwarButtonVariant.secondary,
              icon: const Icon(
                Icons.map_outlined,
                size: 18,
                color: AppColors.navy,
              ),
              onPressed: () => _openRouteInGoogleMaps(context, isAr),
            ),
            const SizedBox(height: 10),
            MashwarButton(
              text: isAr ? 'رجوع للرحلة' : 'Back to Trip',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      );
    }

    return wrapSurface(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MashwarSheetHeader(
            title: isAr ? 'مشاركة رحلتك' : 'Share Your Trip',
            subtitle: isAr
                ? 'شارك خط سيرك الحي ورابط Google Maps مع عائلتك أو جهات الطوارئ.'
                : 'Share your live corridor and Google Maps route with trusted contacts.',
            leadingIcon: Icons.share_location_rounded,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 14),

          // Live Route & Google Maps Link Preview Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slateBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: AppColors.teal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trRoute('$_fromCity ← $_toCity'),
                        style: AppTypography.body(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      Text(
                        _gmapsRouteUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('share_trip_open_gmaps_btn'),
                  tooltip: isAr ? 'فتح في Google Maps' : 'Open in Google Maps',
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.navy,
                  ),
                  onPressed: () => _openRouteInGoogleMaps(context, isAr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contacts List
          for (var i = 0; i < _contacts.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Row(
                children: [
                  MashwarUserAvatar(
                    avatarUrl: null,
                    fullName: isAr
                        ? _contacts[i]['nameAr']!
                        : _contacts[i]['nameEn']!,
                    size: 38,
                    borderWidth: 1.2,
                    borderColor: AppColors.slateBorder,
                    autoCommunityPortrait: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? _contacts[i]['nameAr']!
                              : _contacts[i]['nameEn']!,
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _contacts[i]['phone'] ?? '',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final nAr = _contacts[i]['nameAr']!;
                      final nEn = _contacts[i]['nameEn']!;
                      await Clipboard.setData(
                        ClipboardData(text: _buildShareMessage(isAr)),
                      );
                      if (!mounted) return;
                      setState(() {
                        _sentToNameAr = nAr;
                        _sentToNameEn = nEn;
                      });
                    },
                    child: Text(isAr ? 'إرسال' : 'Send'),
                  ),
                ],
              ),
            ),
          ],

          // Add Custom Emergency Contact Inline
          if (_showAddContactForm) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('share_trip_contact_name_input'),
                    controller: _customNameCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      hintText: isAr
                          ? 'الاسم وصلة القرابة (مثال: خالد - أخي)'
                          : 'Name & relation (e.g. Khalid - Brother)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.slateBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.slateBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('share_trip_contact_phone_input'),
                          controller: _customPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            hintText: '55XXXXXX',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.slateBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.slateBorder,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        key: const ValueKey('share_trip_save_contact_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _saveCustomContact,
                        child: Text(isAr ? 'حفظ' : 'Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('share_trip_add_contact_btn'),
                onPressed: () => setState(() => _showAddContactForm = true),
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 16,
                  color: AppColors.teal,
                ),
                label: Text(
                  isAr
                      ? 'إضافة جهة اتصال طوارئ مخصصة'
                      : 'Add Custom Emergency Contact',
                  style: AppTypography.label(color: AppColors.teal)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),

          const Divider(height: 20, color: AppColors.slateBorder),

          MashwarButton(
            key: const ValueKey('share_trip_whatsapp_btn'),
            text: isAr ? 'مشاركة على واتساب' : 'Share via WhatsApp',
            icon: const Icon(
              Icons.share_rounded,
              size: 18,
              color: Colors.white,
            ),
            onPressed: () => _shareViaWhatsApp(context, isAr),
          ),
          const SizedBox(height: 8),
          MashwarButton(
            key: const ValueKey('share_trip_copy_link_btn'),
            text: isAr ? 'نسخ الرابط' : 'Copy Link',
            variant: MashwarButtonVariant.secondary,
            icon: const Icon(
              Icons.copy_rounded,
              size: 17,
              color: AppColors.navy,
            ),
            onPressed: () => _copyRouteLink(context, isAr),
          ),
        ],
      ),
    );
  }
}

// Page 53: طوارئ SOS (Emergency SOS Modal)
class EmergencySosSheet extends StatefulWidget {
  /// Optional test hook for intercepting external `tel:` / Google Maps launches.
  static Future<bool> Function(Uri uri)? debugUrlLauncher;

  const EmergencySosSheet({super.key});

  @override
  State<EmergencySosSheet> createState() => _EmergencySosSheetState();
}

class _EmergencySosSheetState extends State<EmergencySosSheet> {
  bool _sentToContacts = false;
  String? _dialerFallbackNotice;

  Future<void> _callQatarEmergency999(BuildContext context, bool isAr) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri(scheme: 'tel', path: '999');
    final launched = await launchMashwarExternalUri(uri);

    if (launched) {
      if (context.mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }

    final fallbackMsg = isAr
        ? 'هذا الجهاز لا يدعم فتح تطبيق الاتصال التلقائي. يرجى الاتصال فوراً بالرقم 999 من أقرب هاتف.'
        : 'This device does not have a phone dialer handler. Please dial 999 on a phone immediately.';
    if (mounted) {
      setState(() => _dialerFallbackNotice = fallbackMsg);
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(fallbackMsg),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    if (_sentToContacts) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teal,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              isAr
                  ? 'تم إبلاغ جهات الطوارئ المسجلة'
                  : 'Emergency Contacts Notified',
              textAlign: TextAlign.center,
              style: AppTypography.title(),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'تم إرسال موقعك وبيانات الرحلة. إذا كنت في خطر اتصل بالطوارئ 999 فوراً.'
                  : 'Your live location and trip details were shared. If in danger, call 999.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(),
            ),
            if (_dialerFallbackNotice != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('sos_dialer_fallback_banner'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _dialerFallbackNotice!,
                  style: AppTypography.label(color: AppColors.danger)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              key: const ValueKey('sos_call_police_after_share_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                ),
              ),
              onPressed: () => _callQatarEmergency999(context, isAr),
              child: Text(
                isAr
                    ? 'اتصل بالطوارئ والشرطة · 999'
                    : 'Call Police / MOI · 999',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const ValueKey('sos_call_ambulance_after_share_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                ),
              ),
              onPressed: () => _callQatarEmergency999(context, isAr),
              child: Text(
                isAr
                    ? 'اتصل بالإسعاف والطوارئ · 999'
                    : 'Call Ambulance · 999',
              ),
            ),
            const SizedBox(height: 10),
            MashwarButton(
              text: isAr ? 'أنا بخير الآن' : 'I am safe now',
              variant: MashwarButtonVariant.secondary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'هل تحتاج مساعدة طارئة؟' : 'Need emergency help?',
            style: AppTypography.largeTitle(),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'إذا كنت في خطر مباشر اتصل بالطوارئ القطرية 999 فوراً.'
                : 'If in immediate danger, call Qatar emergency 999 first.',
            style: AppTypography.bodySecondary(),
          ),
          if (_dialerFallbackNotice != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const ValueKey('sos_dialer_fallback_banner'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _dialerFallbackNotice!,
                style: AppTypography.label(color: AppColors.danger)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 20),

          ElevatedButton.icon(
            key: const ValueKey('sos_call_police_999_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusButton),
              ),
            ),
            onPressed: () => _callQatarEmergency999(context, isAr),
            icon: const Icon(Icons.local_police_outlined, size: 18),
            label: Text(
              isAr ? 'اتصل بالطوارئ والشرطة · 999' : 'Call Police / MOI · 999',
              style: AppTypography.button(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            key: const ValueKey('sos_call_ambulance_999_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusButton),
              ),
            ),
            onPressed: () => _callQatarEmergency999(context, isAr),
            icon: const Icon(Icons.medical_services_outlined, size: 18),
            label: Text(
              isAr ? 'اتصل بالإسعاف والطوارئ · 999' : 'Call Ambulance · 999',
              style: AppTypography.button(),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton.icon(
            key: const ValueKey('sos_share_contacts_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusButton),
              ),
            ),
            onPressed: () => setState(() => _sentToContacts = true),
            icon: const Icon(Icons.share_location_rounded, size: 18),
            label: Text(
              isAr
                  ? 'أرسل موقعي لجهات الطوارئ'
                  : 'Send location to emergency contacts',
              style: AppTypography.button(),
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            key: const ValueKey('sos_call_ops_support_btn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.slateBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusButton),
              ),
            ),
            onPressed: () => _confirmAndCallOperationsSupport(context, isAr),
            icon: const Icon(
              Icons.support_agent_rounded,
              size: 18,
              color: AppColors.teal,
            ),
            label: Text(
              isAr
                  ? 'عمليات وأمان مشوار · 4400 9999'
                  : 'MASHWAR Safety Ops · 4400 9999',
              style: AppTypography.button(color: AppColors.navy)
                  .copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// Page 54: المركبة ابتعدت عن المسار (Off-Route Detection Alert)
class OffRouteAlertSheet extends StatelessWidget {
  const OffRouteAlertSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: AppColors.warning,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'المركبة ابتعدت عن المسار'
                : 'Vehicle deviated from planned route',
            textAlign: TextAlign.center,
            style: AppTypography.title(),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'رصدنا خروج المركبة عن المسار المعتاد. هل الأمور على ما يرام؟'
                : 'We detected the vehicle left the planned corridor. Are you okay?',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: 20),
          MashwarButton(
            text: isAr ? 'أنا بخير' : 'I am fine',
            onPressed: () {
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'حسناً، سنواصل متابعة رحلتك بأمان'
                        : 'Glad you are okay. Live monitoring continues.',
                  ),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          MashwarButton(
            text: isAr ? 'تواصل مع عمليات الأمان' : 'Call Safety Operations',
            variant: MashwarButtonVariant.secondary,
            onPressed: () => _confirmAndCallOperationsSupport(context, isAr),
          ),
          const SizedBox(height: 10),
          MashwarButton(
            text: isAr ? 'بحاجة إلى مساعدة طارئة' : 'Need Emergency Help',
            variant: MashwarButtonVariant.danger,
            onPressed: () {
              Navigator.of(context).maybePop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppDimens.radiusBottomSheet),
                  ),
                ),
                builder: (_) => const EmergencySosSheet(),
              );
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
  String _selectedCategory = 'قيادة متهورة';
  final TextEditingController _detailsController = TextEditingController(
    text: 'السائق كان يقود بسرعة عالية',
  );
  bool _isSent = false;

  static const List<String> _categoriesAr = [
    'سلوك غير لائق',
    'تحرش أو إساءة',
    'قيادة متهورة',
    'احتيال أو خلاف مالي',
    'طرد مفقود أو تالف',
    'أخرى',
  ];

  static const List<String> _categoriesEn = [
    'Inappropriate Behavior',
    'Harassment',
    'Reckless Driving',
    'Fraud / Payment Issue',
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
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final categories = isAr ? _categoriesAr : _categoriesEn;

    if (_isSent) {
      return Scaffold(
        backgroundColor: AppColors.slateBg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.teal,
                      size: 58,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'وصلنا بلاغك' : 'Report Received',
                      style: AppTypography.largeTitle(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'فريق الثقة والأمان يراجع البلاغ #5127 وسيتواصل معك.'
                          : 'Our Trust & Safety team is reviewing Report #5127.',
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
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.slateBg,
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
        title: Text(
          isAr ? 'إبلاغ عن مشكلة' : 'Report an Issue',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusCard,
                            ),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'ما طبيعة المشكلة؟' : 'What went wrong?',
                                style: AppTypography.title()
                                    .copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              for (var i = 0; i < categories.length; i++) ...[
                                Material(
                                  color: _selectedCategory == _categoriesAr[i]
                                      ? AppColors.cobaltSurface
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      _selectedCategory == _categoriesAr[i]
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color:
                                          _selectedCategory == _categoriesAr[i]
                                              ? AppColors.navy
                                              : AppColors.textSecondary,
                                    ),
                                    title: Text(
                                      categories[i],
                                      style: AppTypography.body().copyWith(
                                        fontWeight: _selectedCategory ==
                                                _categoriesAr[i]
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    onTap: () => setState(
                                      () => _selectedCategory = _categoriesAr[i],
                                    ),
                                  ),
                                ),
                                if (i < categories.length - 1)
                                  const Divider(
                                    height: 1,
                                    color: AppColors.slateBorder,
                                  ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                isAr
                                    ? 'اشرح ما حدث:'
                                    : 'Describe what happened:',
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _detailsController,
                                maxLines: 3,
                                style: AppTypography.body(),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.slateBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.slateBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.slateBorder,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: AppColors.slateBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusButton,
                              ),
                            ),
                          ),
                          onPressed: () =>
                              _confirmAndCallOperationsSupport(context, isAr),
                          icon: const Icon(
                            Icons.phone_in_talk_rounded,
                            size: 18,
                            color: AppColors.teal,
                          ),
                          label: Text(
                            isAr
                                ? 'اتصال عاجل بعمليات الأمان'
                                : 'Call Safety Operations Now',
                            style: AppTypography.button(color: AppColors.navy)
                                .copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MashwarButton(
                    key: const ValueKey('report_issue_submit_btn'),
                    text: isAr ? 'إرسال البلاغ' : 'Submit Report',
                    onPressed: () => setState(() => _isSent = true),
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

// Page 56: جهات الطوارئ (Emergency Contacts Management)
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late List<Map<String, String>> _contacts;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final auth = Provider.of<AuthProvider?>(context, listen: false);
      final savedName = auth?.user.emergencyContactName?.trim() ?? '';
      final savedPhone = auth?.user.emergencyContactPhone?.trim() ?? '';
      _contacts = [
        if (savedName.isNotEmpty)
          {
            'name': savedName,
            'phone': savedPhone.isNotEmpty ? savedPhone : '5500 1122',
          },
        {'name': 'نورة (أختي)', 'phone': '5511 2233'},
        {'name': 'راشد (والدي)', 'phone': '6622 3344'},
      ];
    }
  }

  void _syncPrimaryContactToAuth() {
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    if (auth == null || _contacts.isEmpty) return;
    auth.updateProfile(
      emergencyContactName: _contacts.first['name'],
      emergencyContactPhone: _contacts.first['phone'],
    );
  }

  void _addContactDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final settings = Provider.of<SettingsProvider?>(context, listen: false);
    final isAr = settings?.isArabic ?? context.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'جهة طوارئ جديدة' : 'New Emergency Contact',
          style: AppTypography.title(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'الاسم أو صلة القرابة' : 'Name or Relationship',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('emergency_contact_dialog_name_input'),
              controller: nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slateBg,
                hintText: isAr ? 'مثال: حمد (أخي)' : 'e.g. Hamad (Brother)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slateBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slateBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('emergency_contact_dialog_phone_input'),
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slateBg,
                hintText: '55XXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slateBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slateBorder),
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
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('emergency_contact_dialog_save_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty &&
                  phoneCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _contacts.insert(0, {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  });
                });
                _syncPrimaryContactToAuth();
                Navigator.of(ctx).pop();
              }
            },
            child: Text(isAr ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
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
        title: Text(
          isAr ? 'جهات الطوارئ' : 'Emergency Contacts',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.space16,
                    12,
                    AppDimens.space16,
                    8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.space12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'يتم إشعار هذه الجهات فورياً عند تفعيل SOS مع إرسال رابط التتبع المباشر.'
                                : 'These contacts are notified instantly on SOS with your live Google Maps route.',
                            style: AppTypography.label(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                    vertical: 4,
                  ),
                  child: Text(
                    isAr
                        ? '${_contacts.length} جهات طوارئ مسجلة'
                        : '${_contacts.length} saved emergency contacts',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16,
                    ),
                    itemCount: _contacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = _contacts[index];
                      return MashwarFadeSlideIn(
                        offsetY: 8,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusCard,
                            ),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Row(
                            children: [
                              MashwarUserAvatar(
                                avatarUrl: null,
                                fullName: c['name']!,
                                size: 40,
                                borderWidth: 1.2,
                                borderColor: AppColors.slateBorder,
                                autoCommunityPortrait: true,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name']!,
                                      style: AppTypography.body(
                                        color: AppColors.navy,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c['phone']!,
                                      style: AppTypography.bodySecondary(),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: AppColors.teal,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.maybeOf(context);
                                  final raw =
                                      c['phone']!.replaceAll(' ', '').trim();
                                  final path = raw.startsWith('+')
                                      ? raw
                                      : '+974$raw';
                                  final ok = await launchMashwarExternalUri(
                                    Uri(scheme: 'tel', path: path),
                                  );
                                  if (!ok) {
                                    messenger?.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr
                                              ? 'الاتصال على $path'
                                              : 'Dial $path',
                                        ),
                                        backgroundColor: AppColors.navy,
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _contacts.removeAt(index));
                                  _syncPrimaryContactToAuth();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: MashwarButton(
                    key: const ValueKey('emergency_contacts_add_btn'),
                    text: isAr ? 'أضف جهة طوارئ' : 'Add Emergency Contact',
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _addContactDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
