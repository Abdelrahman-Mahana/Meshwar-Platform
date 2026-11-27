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
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/board_ad_model.dart';
import '../../data/models/ride_model.dart';
import '../../state/board_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../chat/chat_screen.dart';
import '../escrow/service_escrow_screen.dart';
import '../safety/safety_screens.dart';
import 'make_offer_sheet.dart';
import 'post_ad_screen.dart';

Future<void> _openBoardRouteInGoogleMaps(
  BuildContext context, {
  required String fromCity,
  required String toCity,
  String? stopoverCity,
  required bool isAr,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final origin = '${fromCity.trim().isNotEmpty ? fromCity.trim() : 'الدوحة'}, Qatar';
  final dest = '${toCity.trim().isNotEmpty ? toCity.trim() : 'الخور'}, Qatar';
  final buffer = StringBuffer(
    'https://www.google.com/maps/dir/?api=1'
    '&origin=${Uri.encodeComponent(origin)}'
    '&destination=${Uri.encodeComponent(dest)}',
  );
  if (stopoverCity != null && stopoverCity.trim().isNotEmpty) {
    buffer.write(
      '&waypoints=${Uri.encodeComponent('${stopoverCity.trim()}, Qatar')}',
    );
  }
  buffer.write('&travelmode=driving');
  final url = buffer.toString();

  final launched = await launchMashwarExternalUri(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );

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
}

Future<void> _dialBoardContactPhone(
  BuildContext context,
  String rawPhone,
  bool isAr,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final compact = rawPhone.replaceAll(' ', '').trim();
  final dialPath = compact.startsWith('+') ? compact : '+974$compact';
  final uri = Uri(scheme: 'tel', path: dialPath);
  final launched = await launchMashwarExternalUri(uri);

  if (!launched) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تعذّر فتح تطبيق الهاتف. اتصل على $dialPath'
              : 'Dialer unavailable. Call $dialPath',
        ),
        backgroundColor: AppColors.navy,
      ),
    );
  }
}

// Page 63: إعلاناتي وعروضي في اللوحة (My Board Ads & Offers Screen)
class MyBoardAdsScreen extends StatefulWidget {
  const MyBoardAdsScreen({super.key, this.initialTab = 0});

  final int initialTab; // 0: نشطة, 1: عروضي المقدمة, 2: منتهية

  @override
  State<MyBoardAdsScreen> createState() => _MyBoardAdsScreenState();
}

class _MyBoardAdsScreenState extends State<MyBoardAdsScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final boardProvider = context.watch<BoardProvider>();
    final activeAds = boardProvider.myAds
        .where(
          (a) =>
              a.status != BoardAdStatus.completed &&
              a.status != BoardAdStatus.expired &&
              a.status != BoardAdStatus.cancelled,
        )
        .toList();
    final sentOffers = boardProvider.mySentOffers;
    final completedAds = boardProvider.myAds
        .where(
          (a) =>
              a.status == BoardAdStatus.completed ||
              a.status == BoardAdStatus.expired,
        )
        .toList();

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
          isAr ? 'إعلاناتي وعروضي' : 'My Ads & Offers',
          style: AppTypography.title(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('my_board_ads_new_btn'),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.navy,
            ),
            tooltip: isAr ? 'نشر إعلان جديد' : 'Post New Ad',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PostAdScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            index: 0,
                            label: isAr
                                ? 'نشطة (${activeAds.length})'
                                : 'Active (${activeAds.length})',
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            index: 1,
                            label: isAr
                                ? 'عروضي (${sentOffers.length})'
                                : 'My Offers (${sentOffers.length})',
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            index: 2,
                            label: isAr
                                ? 'منتهية (${completedAds.length})'
                                : 'Done (${completedAds.length})',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildActiveAdsList(
                            context,
                            activeAds,
                            boardProvider,
                            isAr,
                          )
                        : _selectedTab == 1
                            ? _buildSentOffersList(
                                context,
                                sentOffers,
                                boardProvider,
                                isAr,
                              )
                            : _buildCompletedAdsList(
                                context,
                                completedAds,
                                boardProvider,
                                isAr,
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

  Widget _buildTabButton({required int index, required String label}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.label(
              color: isSelected ? Colors.white : AppColors.navy,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAdsList(
    BuildContext context,
    List<BoardAdModel> activeAds,
    BoardProvider boardProvider,
    bool isAr,
  ) {
    if (activeAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد إعلانات نشطة حالياً' : 'No active ads right now',
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              width: 200,
              text: isAr ? 'انشر إعلان جديد' : 'Post New Ad',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostAdScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: activeAds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ad = activeAds[index];
        return _buildAdCard(
          context: context,
          ad: ad,
          typeLabel: ad.typeTitle(isAr),
          route: context.trRoute('${ad.fromCity} ← ${ad.toCity}'),
          details: '${ad.timeText} · ${ad.description}',
          priceText: '${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
          offersCount: index == 0 ? 3 : 2,
          isAr: isAr,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BoardAdOffersScreen(ad: ad)),
            );
          },
          onComplete: () {
            boardProvider.acceptOfferOnMyAd(ad.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr
                      ? 'تم تحديث حالة الإعلان إلى مكتمل'
                      : 'Ad marked as completed',
                ),
                backgroundColor: AppColors.teal,
              ),
            );
          },
          onDelete: () => boardProvider.deleteMyAd(ad.id),
        );
      },
    );
  }

  Widget _buildSentOffersList(
    BuildContext context,
    List<BoardAdModel> sentOffers,
    BoardProvider boardProvider,
    bool isAr,
  ) {
    if (sentOffers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'لم تقدّم أي عروض بعد على إعلانات اللوحة'
                  : 'You have not sent any offers yet',
              style: AppTypography.bodySecondary(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: sentOffers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ad = sentOffers[index];
        return MashwarFadeSlideIn(
          offsetY: 10,
          child: Container(
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
                    MashwarUserAvatar(
                      avatarUrl: null,
                      fullName: ad.authorName,
                      size: 36,
                      borderWidth: 1.2,
                      borderColor: AppColors.slateBorder,
                      autoCommunityPortrait: true,
                      showVerifiedBadge: ad.isVerified,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ad.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    MashwarBadge(
                      type: BadgeType.confirmed,
                      customLabel: isAr ? 'بانتظار الرد' : 'Offer Sent',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MashwarRouteTimeline(
                  from: context.trCity(ad.fromCity),
                  to: context.trCity(ad.toCity),
                  compact: true,
                ),
                const SizedBox(height: 8),
                Text(
                  '${ad.timeText} · ${ad.description}',
                  style: AppTypography.bodySecondary(),
                ),
                const Divider(height: 20, color: AppColors.slateBorder),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      isAr
                          ? 'عرضك المقدم: ${ad.myOfferPrice ?? ad.priceOrBudget} ر.ق'
                          : 'Your Offer: ${ad.myOfferPrice ?? ad.priceOrBudget} QAR',
                      style: AppTypography.body(color: AppColors.teal)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: isAr ? 'الخريطة' : 'Google Maps',
                          icon: const Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: AppColors.navy,
                          ),
                          onPressed: () => _openBoardRouteInGoogleMaps(
                            context,
                            fromCity: ad.fromCity,
                            toCity: ad.toCity,
                            stopoverCity: ad.stopoverCity,
                            isAr: isAr,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: isAr ? 'محادثة' : 'Chat',
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: AppColors.navy,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  driverName: ad.authorName,
                                  driverCar: ad.timeText,
                                  tripRoute: context.trRoute(ad.route),
                                ),
                              ),
                            );
                          },
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(
                              color: AppColors.slateBorder,
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MakeOfferSheet(ad: ad),
                            );
                          },
                          child: Text(isAr ? 'تعديل' : 'Edit'),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => boardProvider.withdrawOffer(ad.id),
                          icon: const Icon(Icons.undo_rounded, size: 16),
                          label: Text(isAr ? 'سحب العرض' : 'Withdraw'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedAdsList(
    BuildContext context,
    List<BoardAdModel> completedAds,
    BoardProvider boardProvider,
    bool isAr,
  ) {
    if (completedAds.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا توجد إعلانات منتهية' : 'No completed ads',
          style: AppTypography.bodySecondary(),
        ),
      );
    }

    return ListView.separated(
      itemCount: completedAds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ad = completedAds[index];
        return _buildAdCard(
          context: context,
          ad: ad,
          typeLabel: isAr ? 'مكتمل' : 'Completed',
          route: context.trRoute('${ad.fromCity} ← ${ad.toCity}'),
          details: '${ad.timeText} · ${ad.description}',
          priceText: '${ad.myOfferPrice ?? ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
          offersCount: 0,
          isAr: isAr,
          onDelete: () => boardProvider.deleteMyAd(ad.id),
        );
      },
    );
  }

  Widget _buildAdCard({
    required BuildContext context,
    required BoardAdModel ad,
    required String typeLabel,
    required String route,
    required String details,
    required String priceText,
    required int offersCount,
    required bool isAr,
    VoidCallback? onTap,
    VoidCallback? onComplete,
    VoidCallback? onDelete,
  }) {
    final routeParts = route.split(RegExp(r'\s*[←→]\s*'));
    final fromLabel = routeParts.isNotEmpty ? routeParts.first : route;
    final toLabel = routeParts.length > 1 ? routeParts.last : route;
    return MashwarFadeSlideIn(
      offsetY: 10,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: const BorderSide(color: AppColors.slateBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MashwarBadge(
                          type: offersCount > 0
                              ? BadgeType.verified
                              : BadgeType.confirmed,
                          customLabel: offersCount > 0
                              ? (isAr ? 'نشط' : 'Active')
                              : (isAr ? 'مكتمل' : 'Completed'),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          key: ValueKey('my_ad_gmaps_${ad.id}'),
                          onTap: () => _openBoardRouteInGoogleMaps(
                            context,
                            fromCity: ad.fromCity,
                            toCity: ad.toCity,
                            stopoverCity: ad.stopoverCity,
                            isAr: isAr,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        if (onComplete != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            key: ValueKey('my_ad_complete_${ad.id}'),
                            onTap: onComplete,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ],
                        if (onDelete != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            key: ValueKey('my_ad_delete_${ad.id}'),
                            onTap: onDelete,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MashwarRouteTimeline(
                  from: fromLabel,
                  to: toLabel,
                  trailingTop: priceText,
                  compact: true,
                ),
                const SizedBox(height: 8),
                Text(details, style: AppTypography.bodySecondary()),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        offersCount > 0
                            ? (isAr
                                ? '$offersCount عروض جديدة (اضغط للمراجعة والاختيار)'
                                : '$offersCount new offers (Tap to review)')
                            : (isAr
                                ? 'تم الاتفاق وإغلاق الإعلان'
                                : 'Agreed & closed'),
                        style: AppTypography.label(
                          color: offersCount > 0
                              ? AppColors.teal
                              : AppColors.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (offersCount > 0)
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.teal,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Page 64: العروض على طلبك (Offers on your Ad)
class BoardAdOffersScreen extends StatefulWidget {
  const BoardAdOffersScreen({super.key, this.ad});

  final BoardAdModel? ad;

  @override
  State<BoardAdOffersScreen> createState() => _BoardAdOffersScreenState();
}

class _BoardAdOffersScreenState extends State<BoardAdOffersScreen> {
  bool _accepted = false;
  String _selectedDriverName = 'جاسم الكواري';
  String _selectedDriverPhone = '5523 4567';

  void _confirmSelection(
    BuildContext context,
    String driverName,
    String driverPhone,
    int price,
    String time,
  ) {
    final settings = Provider.of<SettingsProvider?>(context, listen: false);
    final isAr = settings?.isArabic ?? context.isArabic;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAr ? 'اعتماد عرض $driverName؟' : 'Accept offer from $driverName?',
              style: AppTypography.title(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'السعر المتفق عليه' : 'Agreed Price',
                  style: AppTypography.bodySecondary(),
                ),
                Text(
                  '$price ${isAr ? "ر.ق" : "QAR"}',
                  style: AppTypography.title(color: AppColors.navy),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.slateBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'الموعد' : 'Schedule',
                  style: AppTypography.bodySecondary(),
                ),
                Text(
                  time,
                  style: AppTypography.body(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Text(
                isAr
                    ? 'سيتم إغلاق باقي العروض ومشاركة رقم $driverName للتواصل المباشر.'
                    : 'Other offers will close and $driverName\'s phone will be shared.',
                style: AppTypography.bodySmall(),
              ),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              key: const ValueKey('board_offers_confirm_accept_btn'),
              text: isAr ? 'تأكيد الاختيار' : 'Confirm Selection',
              onPressed: () {
                if (widget.ad != null) {
                  Provider.of<BoardProvider?>(context, listen: false)
                      ?.acceptOfferOnMyAd(
                    widget.ad!.id,
                    acceptedPrice: price,
                    providerName: driverName,
                  );
                }
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedDriverName = driverName;
                  _selectedDriverPhone = driverPhone;
                  _accepted = true;
                });
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isAr ? 'رجوع' : 'Back',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final fromCity = widget.ad?.fromCity ?? 'الدوحة';
    final toCity = widget.ad?.toCity ?? 'الخور';
    final routeText = context.trRoute('$fromCity ← $toCity');
    final budgetPrice = widget.ad?.priceOrBudget ?? 80;

    if (_accepted) {
      return Scaffold(
        backgroundColor: AppColors.slateBg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: MashwarFadeSlideIn(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.teal,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'اتفقت مع $_selectedDriverName'
                            : 'Agreed with $_selectedDriverName',
                        style: AppTypography.largeTitle(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'رقمه: $_selectedDriverPhone · المسار: $routeText'
                            : 'Phone: $_selectedDriverPhone · Route: $routeText',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary(),
                      ),
                      const SizedBox(height: 24),
                      MashwarButton(
                        key: const ValueKey('board_accepted_call_btn'),
                        text: isAr
                            ? 'اتصل بـ $_selectedDriverName'
                            : 'Call $_selectedDriverName',
                        icon: const Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => _dialBoardContactPhone(
                          context,
                          _selectedDriverPhone,
                          isAr,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MashwarButton(
                        text: isAr ? 'محادثة مباشرة' : 'Open Chat',
                        variant: MashwarButtonVariant.secondary,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.navy,
                          size: 18,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                driverName: _selectedDriverName,
                                driverCar: isAr
                                    ? 'اتفاق عبر اللوحة'
                                    : 'Board Agreement',
                                tripRoute: routeText,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      MashwarButton(
                        text: isAr
                            ? 'فتح المسار في Google Maps'
                            : 'Open Route in Google Maps',
                        variant: MashwarButtonVariant.secondary,
                        icon: const Icon(
                          Icons.map_outlined,
                          color: AppColors.teal,
                          size: 18,
                        ),
                        onPressed: () => _openBoardRouteInGoogleMaps(
                          context,
                          fromCity: fromCity,
                          toCity: toCity,
                          stopoverCity: widget.ad?.stopoverCity,
                          isAr: isAr,
                        ),
                      ),
                      if (widget.ad != null) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServiceEscrowScreen(ad: widget.ad),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: AppColors.teal,
                          ),
                          label: Text(
                            isAr
                                ? 'الضمان المالي وكود التسليم OTP'
                                : 'Escrow Shield & Handover OTP',
                            style: AppTypography.label(color: AppColors.teal)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          isAr ? 'العودة للإعلانات' : 'Back to Ads',
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final headerParts = routeText.split(RegExp(r'\s*[←→]\s*'));
    final headerFrom = headerParts.isNotEmpty ? headerParts.first : routeText;
    final headerTo = headerParts.length > 1 ? headerParts.last : routeText;

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
          isAr ? 'العروض على طلبك' : 'Offers on your Request',
          style: AppTypography.title(),
        ),
        actions: [
          if (widget.ad != null)
            IconButton(
              tooltip: isAr ? 'حذف الإعلان' : 'Cancel Ad',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              onPressed: () {
                Provider.of<BoardProvider?>(context, listen: false)
                    ?.deleteMyAd(widget.ad!.id);
                Navigator.of(context).pop();
              },
            ),
        ],
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
                  MashwarFadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.all(14),
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
                          Row(
                            children: [
                              Expanded(
                                child: MashwarRouteTimeline(
                                  from: headerFrom,
                                  to: headerTo,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tealSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isAr
                                      ? 'ميزانيتك $budgetPrice ر.ق'
                                      : 'Budget $budgetPrice QAR',
                                  style: AppTypography.label(
                                    color: AppColors.teal,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (widget.ad != null)
                                Expanded(
                                  child: Text(
                                    widget.ad!.timeText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              OutlinedButton.icon(
                                key: const ValueKey(
                                  'board_offers_open_gmaps_btn',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  side: const BorderSide(
                                    color: AppColors.slateBorder,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _openBoardRouteInGoogleMaps(
                                  context,
                                  fromCity: fromCity,
                                  toCity: toCity,
                                  stopoverCity: widget.ad?.stopoverCity,
                                  isAr: isAr,
                                ),
                                icon: const Icon(
                                  Icons.map_outlined,
                                  size: 15,
                                  color: AppColors.teal,
                                ),
                                label: Text(
                                  isAr
                                      ? 'فتح المسار في Google Maps'
                                      : 'Open in Google Maps',
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
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildOfferCard(
                          context: context,
                          driverName: 'جاسم الكواري',
                          driverPhone: '5523 4567',
                          stats: isAr
                              ? 'موثق · 14 رحلة · ★ 4.9'
                              : 'Verified · 14 rides · ★ 4.9',
                          price: (budgetPrice - 5).clamp(20, 9999),
                          time: isAr ? 'الجمعة 1:15 م' : 'Fri 1:15 PM',
                          routeText: routeText,
                          onSelect: () => _confirmSelection(
                            context,
                            'جاسم الكواري',
                            '5523 4567',
                            (budgetPrice - 5).clamp(20, 9999),
                            isAr ? 'الجمعة 1:15 م' : 'Fri 1:15 PM',
                          ),
                          isAr: isAr,
                        ),
                        const SizedBox(height: 10),
                        _buildOfferCard(
                          context: context,
                          driverName: 'علي الهاجري',
                          driverPhone: '6612 3456',
                          stats: isAr
                              ? 'موثق · 6 رحلات · ★ 4.8'
                              : 'Verified · 6 rides · ★ 4.8',
                          price: budgetPrice,
                          time: isAr ? 'الجمعة 2:00 م' : 'Fri 2:00 PM',
                          routeText: routeText,
                          onSelect: () => _confirmSelection(
                            context,
                            'علي الهاجري',
                            '6612 3456',
                            budgetPrice,
                            isAr ? 'الجمعة 2:00 م' : 'Fri 2:00 PM',
                          ),
                          isAr: isAr,
                        ),
                        const SizedBox(height: 10),
                        _buildOfferCard(
                          context: context,
                          driverName: 'آمنة السويدي',
                          driverPhone: '7710 2345',
                          stats: isAr
                              ? 'موثقة · 9 رحلات · ★ 4.9'
                              : 'Verified · 9 rides · ★ 4.9',
                          price: budgetPrice + 5,
                          time: isAr ? 'الجمعة 12:30 م' : 'Fri 12:30 PM',
                          routeText: routeText,
                          onSelect: () => _confirmSelection(
                            context,
                            'آمنة السويدي',
                            '7710 2345',
                            budgetPrice + 5,
                            isAr ? 'الجمعة 12:30 م' : 'Fri 12:30 PM',
                          ),
                          isAr: isAr,
                        ),
                      ],
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

  Widget _buildOfferCard({
    required BuildContext context,
    required String driverName,
    required String driverPhone,
    required String stats,
    required int price,
    required String time,
    required String routeText,
    required VoidCallback onSelect,
    required bool isAr,
  }) {
    return MashwarFadeSlideIn(
      offsetY: 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.slateBorder),
        ),
        child: Row(
          children: [
            MashwarUserAvatar(
              avatarUrl: null,
              fullName: driverName,
              size: 46,
              borderWidth: 1.5,
              borderColor: AppColors.slateBorder,
              autoCommunityPortrait: true,
              showVerifiedBadge: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(stats, style: AppTypography.bodySecondary()),
                  Text(
                    time,
                    style: AppTypography.bodySmall(color: AppColors.navy),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$price ${isAr ? "ر.ق" : "QAR"}',
                  style: AppTypography.title(color: AppColors.navy),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 18,
                        color: AppColors.teal,
                      ),
                      tooltip: isAr ? 'اتصال' : 'Call',
                      onPressed: () =>
                          _dialBoardContactPhone(context, driverPhone, isAr),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.navy,
                      ),
                      tooltip: isAr ? 'محادثة' : 'Chat',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              driverName: driverName,
                              driverCar: stats,
                              tripRoute: routeText,
                            ),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onSelect,
                      child: Text(isAr ? 'اختيار' : 'Select'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Page 66: تغيير موعد الرحلة (Reschedule Ride by Driver)
class RescheduleRideScreen extends StatefulWidget {
  const RescheduleRideScreen({super.key, this.ride});

  final RideModel? ride;

  @override
  State<RescheduleRideScreen> createState() => _RescheduleRideScreenState();
}

class _RescheduleRideScreenState extends State<RescheduleRideScreen> {
  int _state = 0; // 0: بانتظار قرارك, 1: تمت الموافقة, 2: اتلغى حجزك

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final ridesProvider = Provider.of<RidesProvider?>(context);
    final targetRide = widget.ride ?? ridesProvider?.activeBooking;
    final routeLabel = targetRide != null
        ? context.trRoute('${targetRide.fromCity} ← ${targetRide.toCity}')
        : (isAr ? 'الدوحة ← الخور' : 'Doha → Al Khor');

    if (_state == 1) {
      return Scaffold(
        backgroundColor: AppColors.slateBg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: MashwarFadeSlideIn(
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
                        isAr ? 'تم تحديث موعدك' : 'Schedule Updated',
                        style: AppTypography.largeTitle(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'تم حفظ موعد الانطلاق الجديد (الجمعة 9:00 ص).'
                            : 'Trip now departs Friday at 9:00 AM.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary(),
                      ),
                      const SizedBox(height: 24),
                      MashwarButton(
                        text: isAr ? 'عرض الحجز' : 'View Booking',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_state == 2) {
      return Scaffold(
        backgroundColor: AppColors.slateBg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: MashwarFadeSlideIn(
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
                        isAr ? 'تم إلغاء حجزك' : 'Booking Cancelled',
                        style: AppTypography.largeTitle(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'لا يوجد أي أثر على معدل إلغائك لأن السائق هو من عدّل الموعد.'
                            : 'Zero impact on cancellation rate because driver rescheduled.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary(),
                      ),
                      const SizedBox(height: 24),
                      MashwarButton(
                        text: isAr ? 'ابحث عن رحلة أخرى' : 'Search Other Rides',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
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
          isAr ? 'تغيير موعد الرحلة' : 'Ride Rescheduled',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(0.0, 2000.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: MashwarFadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                isAr
                                    ? 'قام السائق بتحديث موعد الانطلاق. يرجى التأكيد أو الإلغاء مجاناً.'
                                    : 'Driver updated departure time. Confirm or cancel free of charge.',
                                style: AppTypography.body(color: AppColors.navy)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusCard,
                                ),
                                border: Border.all(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildRow(
                                    isAr ? 'الرحلة' : 'Route',
                                    routeLabel,
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildRow(
                                    isAr ? 'الموعد السابق' : 'Previous Time',
                                    targetRide?.departureTime ??
                                        (isAr ? 'الجمعة 7:30 ص' : 'Fri 7:30 AM'),
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildRow(
                                    isAr ? 'الموعد الجديد' : 'New Time',
                                    isAr ? 'الجمعة 9:00 ص' : 'Fri 9:00 AM',
                                    isHighlighted: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isAr
                                  ? 'إذا كان الموعد الجديد لا يناسبك يمكنك إلغاء حجزك دون أي أثر على حسابك.'
                                  : 'If the new time does not suit you, cancel penalty-free.',
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MashwarButton(
                                text: isAr
                                    ? 'وافق على الموعد الجديد'
                                    : 'Accept New Time',
                                onPressed: () {
                                  if (targetRide != null) {
                                    Provider.of<RidesProvider?>(
                                      context,
                                      listen: false,
                                    )?.rescheduleRide(
                                      rideId: targetRide.id,
                                      newDate: targetRide.departureDate,
                                      newTime: '9:00 ص',
                                    );
                                  }
                                  setState(() => _state = 1);
                                },
                              ),
                              const SizedBox(height: 10),
                              MashwarButton(
                                text: isAr ? 'ألغي حجزي' : 'Cancel My Booking',
                                variant: MashwarButtonVariant.danger,
                                onPressed: () {
                                  Provider.of<RidesProvider?>(
                                    context,
                                    listen: false,
                                  )?.cancelBooking();
                                  setState(() => _state = 2);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body(
              color: isHighlighted ? AppColors.teal : AppColors.navy,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
