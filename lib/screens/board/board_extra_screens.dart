import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../../state/settings_provider.dart';
import '../chat/chat_screen.dart';
import 'make_offer_sheet.dart';
import 'post_ad_screen.dart';

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
    final isAr = context.watch<SettingsProvider>().isArabic;
    final boardProvider = context.watch<BoardProvider>();
    final activeAds = boardProvider.myAds
        .where((a) => a.status != BoardAdStatus.completed && a.status != BoardAdStatus.expired)
        .toList();
    final sentOffers = boardProvider.mySentOffers;
    final completedAds = boardProvider.myAds
        .where((a) => a.status == BoardAdStatus.completed || a.status == BoardAdStatus.expired)
        .toList();

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
        title: Text(isAr ? 'إعلاناتي وعروضي' : 'My Ads & Offers', style: AppTypography.title()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.teal),
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
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            children: [
              // 3-Way Segmented Switch: نشطة | عروضي | منتهية
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        index: 0,
                        label: isAr ? 'نشطة (${activeAds.length})' : 'Active (${activeAds.length})',
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        index: 1,
                        label: isAr ? 'عروضي (${sentOffers.length})' : 'My Offers (${sentOffers.length})',
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        index: 2,
                        label: isAr ? 'منتهية (${completedAds.length})' : 'Done (${completedAds.length})',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _selectedTab == 0
                    ? _buildActiveAdsList(context, activeAds, boardProvider, isAr)
                    : _selectedTab == 1
                        ? _buildSentOffersList(context, sentOffers, boardProvider, isAr)
                        : _buildCompletedAdsList(context, completedAds, boardProvider, isAr),
              ),
            ],
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
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
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
            const Icon(Icons.campaign_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد إعلانات نشطة حالياً' : 'No active ads right now',
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              width: 180,
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
        final typeLabel = ad.typeTitle(isAr);
        return _buildAdCard(
          typeLabel: typeLabel,
          route: context.trRoute('${ad.fromCity} ← ${ad.toCity}'),
          details: '${ad.timeText} · ${ad.description}',
          priceText: '${ad.priceOrBudget} ${isAr ? "ج" : "EGP"}',
          offersCount: index == 0 ? 3 : 2,
          isAr: isAr,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BoardAdOffersScreen(ad: ad)),
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
            const Icon(Icons.local_offer_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لم تقدّم أي عروض بعد على إعلانات اللوحة' : 'You have not sent any offers yet',
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
        return InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => MakeOfferSheet(ad: ad),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${isAr ? "صاحب الإعلان:" : "Author:"} ${ad.authorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: AppColors.textSecondary),
                      ),
                    ),
                    MashwarBadge(
                      type: BadgeType.confirmed,
                      customLabel: isAr ? 'بانتظار الرد' : 'Offer Sent',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.trRoute('${ad.fromCity} ← ${ad.toCity}'),
                  style: AppTypography.title().copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('${ad.timeText} · ${ad.description}', style: AppTypography.bodySecondary()),
                const Divider(height: 20, color: Color(0xFFE5E5EA)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr
                          ? 'عرضك المقدم: ${ad.myOfferPrice ?? ad.priceOrBudget} ج'
                          : 'Your Offer: ${ad.myOfferPrice ?? ad.priceOrBudget} EGP',
                      style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
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
          isAr ? 'مفيش إعلانات منتهية' : 'No completed ads',
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
          typeLabel: isAr ? 'مكتمل' : 'Completed',
          route: context.trRoute('${ad.fromCity} ← ${ad.toCity}'),
          details: '${ad.timeText} · ${ad.description}',
          priceText: '${ad.priceOrBudget} ${isAr ? "ج" : "EGP"}',
          offersCount: 0,
          isAr: isAr,
          onDelete: () => boardProvider.deleteMyAd(ad.id),
        );
      },
    );
  }

  Widget _buildAdCard({
    required String typeLabel,
    required String route,
    required String details,
    required String priceText,
    required int offersCount,
    required bool isAr,
    VoidCallback? onTap,
    VoidCallback? onDelete,
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
                Row(
                  children: [
                    MashwarBadge(
                      type: offersCount > 0 ? BadgeType.verified : BadgeType.confirmed,
                      customLabel: offersCount > 0 ? (isAr ? 'نشط' : 'Active') : (isAr ? 'مكتمل' : 'Completed'),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.coral),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(route, style: AppTypography.title().copyWith(fontSize: 16)),
                ),
                Text(
                  priceText,
                  style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(details, style: AppTypography.bodySecondary()),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    offersCount > 0
                        ? (isAr ? '$offersCount عروض جديدة (اضغط للمراجعة والاختيار)' : '$offersCount new offers (Tap to review)')
                        : (isAr ? 'تم الاتفاق وإغلاق الإعلان' : 'Agreed & closed'),
                    style: TextStyle(
                      color: offersCount > 0 ? AppColors.teal : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (offersCount > 0)
                  Icon(
                    isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
              ],
            ),
          ],
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
  String _selectedDriverName = 'محمد سعيد';
  String _selectedDriverPhone = '0100 123 4567';

  void _confirmSelection(BuildContext context, String driverName, String driverPhone, int price, String time) {
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
                Text(isAr ? 'السعر المتفق عليه' : 'Agreed Price', style: AppTypography.bodySecondary()),
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
                isAr ? 'باقي العروض هتتلغي، ورقم $driverName هيظهر لك للتواصل المباشر.' : 'Other offers will cancel, and $driverName\'s phone will be shared.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            MashwarButton(
              text: isAr ? 'تأكيد الاختيار' : 'Confirm Selection',
              onPressed: () {
                if (widget.ad != null) {
                  context.read<BoardProvider>().markAdCompleted(widget.ad!.id);
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
    final routeText = widget.ad != null
        ? context.trRoute('${widget.ad!.fromCity} ← ${widget.ad!.toCity}')
        : (isAr ? 'كفر الشيخ ← القاهرة' : 'Kafr El-Sheikh → Cairo');
    final budgetPrice = widget.ad?.priceOrBudget ?? 80;

    if (_accepted) {
      // Page 64: تم الاختيار
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
                Text(
                  isAr ? 'اتفقت مع $_selectedDriverName' : 'Agreed with $_selectedDriverName',
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
                  text: isAr ? 'اتصل بـ $_selectedDriverName' : 'Call $_selectedDriverName',
                  icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr
                              ? 'جاري الاتصال بـ $_selectedDriverName على $_selectedDriverPhone...'
                              : 'Calling $_selectedDriverName at $_selectedDriverPhone...',
                        ),
                        backgroundColor: AppColors.teal,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                MashwarButton(
                  text: isAr ? 'محادثة مباشرة' : 'Open Chat',
                  variant: MashwarButtonVariant.secondary,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.navy, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          driverName: _selectedDriverName,
                          driverCar: isAr ? 'اتفاق عبر اللوحة' : 'Board Agreement',
                          tripRoute: routeText,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    isAr ? 'العودة للإعلانات' : 'Back to Ads',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                  ),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routeText, style: AppTypography.title().copyWith(fontSize: 16)),
                          if (widget.ad != null) ...[
                            const SizedBox(height: 2),
                            Text(widget.ad!.timeText, style: AppTypography.label(color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAr ? 'ميزانيتك $budgetPrice ج' : 'Budget $budgetPrice EGP',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    _buildOfferCard(
                      context: context,
                      driverName: 'محمد سعيد',
                      driverPhone: '0100 123 4567',
                      stats: isAr ? 'موثق · 14 رحلة · ★ 4.9' : 'Verified · 14 rides · ★ 4.9',
                      price: (budgetPrice - 5).clamp(20, 9999),
                      time: isAr ? 'الجمعة 1:15 م' : 'Fri 1:15 PM',
                      routeText: routeText,
                      onSelect: () => _confirmSelection(
                        context,
                        'محمد سعيد',
                        '0100 123 4567',
                        (budgetPrice - 5).clamp(20, 9999),
                        isAr ? 'الجمعة 1:15 م' : 'Fri 1:15 PM',
                      ),
                      isAr: isAr,
                    ),
                    const SizedBox(height: 10),
                    _buildOfferCard(
                      context: context,
                      driverName: 'أحمد علي',
                      driverPhone: '0112 345 6789',
                      stats: isAr ? 'موثق · 6 رحلات · ★ 4.8' : 'Verified · 6 rides · ★ 4.8',
                      price: budgetPrice,
                      time: isAr ? 'الجمعة 2:00 م' : 'Fri 2:00 PM',
                      routeText: routeText,
                      onSelect: () => _confirmSelection(
                        context,
                        'أحمد علي',
                        '0112 345 6789',
                        budgetPrice,
                        isAr ? 'الجمعة 2:00 م' : 'Fri 2:00 PM',
                      ),
                      isAr: isAr,
                    ),
                    const SizedBox(height: 10),
                    _buildOfferCard(
                      context: context,
                      driverName: 'منى حسن',
                      driverPhone: '0123 456 7890',
                      stats: isAr ? 'موثقة · 9 رحلات · ★ 4.9' : 'Verified · 9 rides · ★ 4.9',
                      price: budgetPrice + 5,
                      time: isAr ? 'الجمعة 12:30 م' : 'Fri 12:30 PM',
                      routeText: routeText,
                      onSelect: () => _confirmSelection(
                        context,
                        'منى حسن',
                        '0123 456 7890',
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 15, color: AppColors.teal),
                  ],
                ),
                Text(stats, style: AppTypography.bodySecondary()),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.navy)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$price ${isAr ? "ج" : "EGP"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.teal)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.navy),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
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
