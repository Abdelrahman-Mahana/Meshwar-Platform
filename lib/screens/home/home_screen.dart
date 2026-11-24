import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/board_provider.dart';
import '../search/search_results_screen.dart';
import '../booking/booking_confirmation_screen.dart';
import '../driver/driver_onboarding_screens.dart';
import '../wallet/wallet_screen.dart';
import '../account/account_extra_screens.dart';
import '../chat/chat_screen.dart';
import '../board/board_screen.dart';
import '../board/make_offer_sheet.dart';
import '../board/post_ad_screen.dart';
import '../escrow/service_escrow_screen.dart';
import 'city_search_modal.dart';
import 'date_time_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BoardAdType _homeCategoryFilter = BoardAdType.all;
  double _swapTurns = 0.0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rides = context.watch<RidesProvider>();
    final board = context.watch<BoardProvider>();
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final isMedium = constraints.maxWidth >= 600;
            final isUltraCompact = constraints.maxWidth < 360;
            final horizontalPad = isWide
                ? AppDimens.space32
                : (isUltraCompact ? 14.0 : AppDimens.space20);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: AppDimens.space16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1200 : 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const QatarSaduAccentBar(height: 4, borderRadius: 4),
                      const SizedBox(height: 12),

                      // 1. Top Branded Header: Pin Emblem, Greeting, Wallet, Notifications & Profile Avatar
                      _buildTopHeader(context, auth, isAr, isUltraCompact),
                      const SizedBox(height: AppDimens.space16),

                      // 2. Flagship Live Animated Qatar Services Map + Universal Search Bar
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 280),
                        offsetY: 10,
                        child: _buildLiveQatarMapAndWhereTo(
                          context,
                          rides,
                          isAr,
                          isWide,
                          isUltraCompact,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // 3. Effortless Requester <-> Provider Connection Bridge
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 320),
                        offsetY: 12,
                        child: _buildTwoPrimaryActionButtons(context, isAr, isUltraCompact),
                      ),
                      const SizedBox(height: AppDimens.space20),

                      // 4. Balanced 6-Service Everyday Qatar Community Grid
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 360),
                        offsetY: 12,
                        child: _buildServicesShowcaseGrid(context, isAr, isMedium),
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // 5. Bilateral Anti-Fraud & MASHWAR Escrow Protection Banner
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 390),
                        offsetY: 12,
                        child: _buildBilateralEscrowBanner(context, isAr),
                      ),
                      const SizedBox(height: AppDimens.space20),

                      // 6. Active Alerts & Upcoming Bookings (if any)
                      if (auth.user.hasActiveAlerts) ...[
                        _buildAlertMatchBanner(context, isAr),
                        const SizedBox(height: AppDimens.space16),
                      ],
                      if (rides.activeBooking != null) ...[
                        _buildUpcomingBookingCard(context, rides, isAr),
                        const SizedBox(height: AppDimens.space16),
                      ],

                      // 7. Fast Inter-City Route & Service Search Card
                      _buildSearchCard(context, rides, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // 8. Live Community Feed of Requests & Offers across Qatar
                      _buildLiveCommunityFeedSection(context, board, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // 9. Popular Corridors
                      _buildPopularRoutesSection(context, rides, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // 10. Safety & Bilateral Guarantees Strip
                      _buildSafetyPillarsGrid(context, isAr, isWide),
                      const SizedBox(height: AppDimens.space24),

                      // 11. Universal Service Provider Partner Card
                      _buildDriverPromoCard(context, isAr),
                      const SizedBox(height: AppDimens.space20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 1. Top Header with MASHWAR Pin Emblem, Greeting, Verification Badge, Wallet & Avatar
  Widget _buildTopHeader(BuildContext context, AuthProvider auth, bool isAr, bool isUltraCompact) {
    final firstName = auth.user.fullName.trim().isNotEmpty
        ? auth.user.fullName.trim().split(' ').first
        : (isAr ? 'ضيفنا' : 'Member');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (!isUltraCompact) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.qatarMaroonSurface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.qatarMaroon.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: MashwarPinIcon(size: 22),
                  ),
                ),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'حياك الله في قطر،' : 'Welcome to MASHWAR Qatar,',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary().copyWith(fontSize: 11.5),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title().copyWith(fontSize: isUltraCompact ? 16 : 18),
                          ),
                        ),
                        if (auth.user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.teal),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Wallet Pill
            MashwarPressable(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 8 : 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      '${auth.user.walletBalance.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}',
                      style: AppTypography.label(color: AppColors.teal).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isUltraCompact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Notifications Shortcut
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 22),
              tooltip: isAr ? 'الإشعارات' : 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                );
              },
            ),
            const SizedBox(width: 2),
            // User Profile Avatar Circle -> Opens UserProfileScreen on tap (tested for 'ع')
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                );
              },
              child: Container(
                width: isUltraCompact ? 38 : 42,
                height: isUltraCompact ? 38 : 42,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    auth.user.fullName.isNotEmpty ? auth.user.fullName[0] : 'ع',
                    style: AppTypography.title(color: AppColors.navy),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Flagship Live Animated Qatar Multi-Service Map + Universal Search Prompt Bar
  Widget _buildLiveQatarMapAndWhereTo(
    BuildContext context,
    RidesProvider rides,
    bool isAr,
    bool isWide,
    bool isUltraCompact,
  ) {
    final mapHeight = isWide ? 264.0 : (isUltraCompact ? 172.0 : 216.0);
    final quickCorridors = <List<String>>[
      ['الدوحة', 'الخور'],
      ['الدوحة', 'لوسيل'],
      ['المنطقة الصناعية', 'لوسيل'],
      ['أم صلال', 'الدوحة'],
      ['الدوحة', 'الوكرة'],
      ['الدوحة', 'دخان'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Animated Qatar Map Canvas
          SizedBox(
            height: mapHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                QatarLiveMapCanvas(
                  style: QatarMapStyle.light,
                  activeFromCity: rides.fromCity,
                  activeToCity: rides.toCity,
                  borderRadius: 22,
                  bottomOverlayInset: 42,
                  onHubTap: (selectedHub) {
                    rides.setRoute(to: selectedHub);
                  },
                ),

                // Top Frosted Telemetry & Bilateral Escrow Shortcut
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  end: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MashwarLivePulseDot(color: AppColors.gold, size: 7.5),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isAr
                                      ? '18 منفّذ وكابتن متصل الآن · قطر'
                                      : '18 helpers & drivers live · Qatar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.white.withValues(alpha: 0.96),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.qatarMaroon.withValues(alpha: 0.38)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MashwarPageRoute(builder: (_) => const ServiceEscrowScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 13, color: AppColors.qatarMaroon),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? 'حماية الضمان' : 'Escrow Shield',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.qatarMaroon,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Live Quick-Corridor Selector Inside Map
                PositionedDirectional(
                  bottom: 10,
                  start: 10,
                  end: 10,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickCorridors.map((pair) {
                        final from = pair[0];
                        final to = pair[1];
                        final isSelected = rides.fromCity == from && rides.toCity == to;
                        final label = context.trRoute('$from ← $to');
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => rides.setRoute(from: from, to: to),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.qatarMaroon
                                    : Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.qatarMaroon
                                      : const Color(0xFFDDE3EC),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.navy,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Attached Universal "What Service / Where to?" Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: _buildUberWhereToBar(context, rides, isAr),
          ),
        ],
      ),
    );
  }

  // Universal Service & Corridor Search Capsule
  Widget _buildUberWhereToBar(BuildContext context, RidesProvider rides, bool isAr) {
    final scheduleLabel = rides.date.isEmpty || rides.date == 'الجمعة 6 نوفمبر'
        ? (isAr ? 'الآن' : 'Now')
        : context.trDate(rides.date);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                Navigator.of(context).push(
                  MashwarPageRoute(builder: (_) => const PostAdScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.qatarMaroon,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr
                                ? 'وش الخدمة أو المشوار اللي محتاجه اليوم؟'
                                : 'What service or trip do you need today?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            isAr
                                ? 'شراء بفاتورة · توريد موقع · جلب ورقة · حضانة أو مقعد'
                                : 'Shop with receipt · Site supply · Docs · Nursery or Seat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DateTimePickerSheet(
                    selectedDay: rides.date,
                    selectedTime: rides.timeSlot,
                    onApply: (day, time) {
                      rides.setDate(day);
                      rides.setTimeSlot(time);
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 15, color: AppColors.navy),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        scheduleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.navy),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Balanced 6-Service Everyday Qatar Community Grid (No bias toward rides!)
  Widget _buildServicesShowcaseGrid(BuildContext context, bool isAr, bool isMedium) {
    final tiles = [
      _ServiceTileData(
        title: isAr ? 'شراء وتوصيل بفاتورة' : 'Buy & Deliver',
        subtitle: isAr ? 'طلبات المحلات والصيدليات' : 'Stores & pharmacies',
        assetPath: 'assets/images/service_errand.jpg',
        badge: isAr ? 'بفاتورة المحل' : 'With Receipt',
        badgeBg: AppColors.tealSurface,
        badgeColor: AppColors.teal,
        fallbackIcon: Icons.shopping_bag_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PostAdScreen(
                initialIntent: 0,
                initialCategory: BoardAdType.parcelRequest,
              ),
            ),
          );
        },
      ),
      _ServiceTileData(
        title: isAr ? 'توريد مواقع ومهندسين' : 'Worksite Supply',
        subtitle: isAr ? 'أدوات وقطع للمشاريع' : 'Engineer hardware runs',
        assetPath: 'assets/images/service_site_supply.jpg',
        badge: isAr ? 'مواقع العمل' : 'Field Urgent',
        badgeBg: AppColors.qatarMaroonSurface,
        badgeColor: AppColors.qatarMaroon,
        fallbackIcon: Icons.engineering_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PostAdScreen(
                initialIntent: 0,
                initialCategory: BoardAdType.goodsDelivery,
              ),
            ),
          );
        },
      ),
      _ServiceTileData(
        title: isAr ? 'جلب أوراق وأمانات' : 'Doc & Item Fetch',
        subtitle: isAr ? 'مع مسافر بنفس طريقك' : 'Along traveler route',
        assetPath: 'assets/images/service_parcel.jpg',
        badge: isAr ? 'كود OTP' : 'OTP Safe',
        badgeBg: AppColors.goldSurface,
        badgeColor: const Color(0xFF9A5B00),
        fallbackIcon: Icons.inventory_2_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PostAdScreen(
                initialIntent: 0,
                initialCategory: BoardAdType.errandService,
              ),
            ),
          );
        },
      ),
      _ServiceTileData(
        title: isAr ? 'مشاوير يومية وحضانات' : 'Nursery & Daily',
        subtitle: isAr ? 'مناطق بعيدة ومدارس' : 'Schools & quiet areas',
        assetPath: '__family_commute__',
        badge: isAr ? 'موثق QID' : 'QID Safe',
        badgeBg: AppColors.escrowSurface,
        badgeColor: AppColors.escrowGreen,
        fallbackIcon: Icons.family_restroom_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PostAdScreen(
                initialIntent: 0,
                initialCategory: BoardAdType.localTrip,
              ),
            ),
          );
        },
      ),
      _ServiceTileData(
        title: isAr ? 'سفر ومقاعد شاغرة' : 'Shared Seats',
        subtitle: isAr ? 'مقاعد بين مدن قطر' : 'Inter-city car seats',
        assetPath: 'assets/images/service_ride.jpg',
        fallbackIcon: Icons.directions_car_filled_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
          );
        },
      ),
      _ServiceTileData(
        title: isAr ? 'نقل معدات وبضائع' : 'Equipment & Cargo',
        subtitle: isAr ? 'توريد وشحن تجاري' : 'Store & warehouse freight',
        assetPath: 'assets/images/service_cargo.jpg',
        fallbackIcon: Icons.local_shipping_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PostAdScreen(
                initialIntent: 0,
                initialCategory: BoardAdType.goodsDelivery,
              ),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isAr ? 'كل خدمات مشوار اليومية' : 'MASHWAR Everyday Services',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title().copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BoardScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_rounded, size: 16, color: AppColors.qatarMaroon),
              label: Text(
                isAr ? 'تصفح اللوحة' : 'Explore Board',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.qatarMaroon,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isMedium)
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildServiceTileCard(tiles[0])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[1])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[2])),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildServiceTileCard(tiles[3])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[4])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[5])),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildServiceTileCard(tiles[0])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[1])),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildServiceTileCard(tiles[2])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[3])),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildServiceTileCard(tiles[4])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildServiceTileCard(tiles[5])),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildServiceTileCard(_ServiceTileData data) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(18),
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                data.assetPath == '__family_commute__'
                    ? const MashwarFamilyCommuteArt(size: 54)
                    : MashwarAssetArt(
                        assetPath: data.assetPath,
                        width: 54,
                        height: 54,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(12),
                        fallbackIcon: data.fallbackIcon,
                        fallbackBg: AppColors.surfaceLight,
                        fallbackColor: AppColors.navy,
                      ),
                if (data.badge != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: data.badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: data.badgeColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Bilateral Anti-Fraud & MASHWAR Escrow Flagship Banner
  Widget _buildBilateralEscrowBanner(BuildContext context, bool isAr) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MashwarPageRoute(builder: (_) => const ServiceEscrowScreen()),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [AppColors.navy, Color(0xFF1A2847), AppColors.qatarMaroonDark],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.qatarMaroon.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QatarSaduAccentBar(height: 4.5, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold, width: 1.2),
                    ),
                    child: const MashwarAssetArt(
                      assetPath: 'assets/images/escrow_trust_shield.jpg',
                      width: 66,
                      height: 66,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      fallbackIcon: Icons.shield_rounded,
                      fallbackColor: AppColors.qatarMaroon,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppColors.gold, size: 15),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                isAr
                                    ? 'ضمان مشوار المزدوج (حماية الطرفين 100%)'
                                    : 'MASHWAR Bilateral Escrow Shield',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? 'حجز المبلغ بـ Escrow · تصوير الفاتورة قبل التحرك · كود التسليم OTP · توثيق QID'
                              : 'Escrow Hold · Live Photo Receipt · 4-Digit OTP · QID Verified',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.86),
                            fontFamily: 'Cairo',
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isAr ? 'استعرض آلية الضمان والحماية' : 'Open Escrow & Safety Center',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.navy,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.navy),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Effortless Requester <-> Provider Connection Cards
  Widget _buildTwoPrimaryActionButtons(BuildContext context, bool isAr, bool isUltraCompact) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildActionCard(
              badge: isAr ? 'لطالبي الخدمات' : 'Requester',
              title: isAr ? 'أطلب خدمة أو مشوار' : 'Request Service',
              subtitle: isAr
                  ? 'شراء بفاتورة، توريد موقع، جلب ورقة أو مقعد'
                  : 'Shop with receipt, site supply, docs or ride',
              icon: Icons.add_task_rounded,
              iconBg: AppColors.qatarMaroonSurface,
              iconColor: AppColors.qatarMaroon,
              borderColor: AppColors.qatarMaroon.withValues(alpha: 0.35),
              bgTint: const Color(0xFFFFF8FA),
              isUltraCompact: isUltraCompact,
              onTap: () {
                Navigator.of(context).push(
                  MashwarPageRoute(builder: (_) => const PostAdScreen(initialIntent: 0)),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionCard(
              badge: isAr ? 'للمنفّذين' : 'Provider',
              title: isAr ? 'أقدّم خدمة بطريقي' : 'Offer Service',
              subtitle: isAr
                  ? 'انجز طلبات بالطريق أو شارك مقاعدك بأمان'
                  : 'Fulfill errands on-route or share empty seats',
              icon: Icons.handshake_rounded,
              iconBg: AppColors.tealSurface,
              iconColor: AppColors.teal,
              borderColor: AppColors.teal.withValues(alpha: 0.4),
              bgTint: const Color(0xFFF3FAF8),
              isUltraCompact: isUltraCompact,
              onTap: () {
                Navigator.of(context).push(
                  MashwarPageRoute(builder: (_) => const PostAdScreen(initialIntent: 1, initialIsOffer: true)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String badge,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color borderColor,
    required Color bgTint,
    required bool isUltraCompact,
    required VoidCallback onTap,
  }) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isUltraCompact ? 11 : 14),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isUltraCompact ? 6 : 7.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: borderColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, color: iconColor, size: isUltraCompact ? 17 : 19),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 6 : 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isUltraCompact ? 9.5 : 10,
                              fontWeight: FontWeight.w800,
                              color: iconColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, color: iconColor, size: 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isUltraCompact ? 13 : 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isUltraCompact ? 10 : 11,
                color: AppColors.textSecondary,
                height: 1.3,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Fast Inter-City Route & Service Matcher Card
  Widget _buildSearchCard(BuildContext context, RidesProvider rides, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.qatarMaroonSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route_rounded, size: 17, color: AppColors.qatarMaroon),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'مخطط المسار السريع للخدمات والمشاوير' : 'Qatar Quick Route & Service Matcher',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Stack(
            alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
            children: [
              Column(
                children: [
                  _buildRouteField(
                    label: isAr ? 'من وين؟ (البلدية أو الموقع)' : 'From (Area / Site)',
                    value: context.trCity(rides.fromCity),
                    leadingDotColor: AppColors.teal,
                    isSquare: false,
                    onTap: () async {
                      final selected = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => CitySearchModal(
                            title: isAr ? 'نقطة الانطلاق' : 'Departure Point',
                            initialValue: rides.fromCity,
                          ),
                        ),
                      );
                      if (selected != null) {
                        rides.setRoute(from: selected);
                      }
                    },
                  ),
                  const SizedBox(height: AppDimens.space12),
                  _buildRouteField(
                    label: isAr ? 'إلى أين؟ (الوجهة أو مكان التسليم)' : 'To (Destination / Drop-off)',
                    value: context.trCity(rides.toCity),
                    leadingDotColor: AppColors.qatarMaroon,
                    isSquare: true,
                    onTap: () async {
                      final selected = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => CitySearchModal(
                            title: isAr ? 'الوجهة' : 'Destination',
                            initialValue: rides.toCity,
                          ),
                        ),
                      );
                      if (selected != null) {
                        rides.setRoute(to: selected);
                      }
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xFFE5E5EA), width: 1),
                  ),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() => _swapTurns += 0.5);
                      rides.swapLocations();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedRotation(
                        turns: _swapTurns,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          size: 20,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildRouteField(
                  label: isAr ? 'الموعد المطلوب' : 'Schedule',
                  value: context.trDate(rides.date),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DateTimePickerSheet(
                        selectedDay: rides.date,
                        selectedTime: rides.timeSlot,
                        onApply: (day, time) {
                          rides.setDate(day);
                          rides.setTimeSlot(time);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                flex: 3,
                child: _buildRouteField(
                  label: isAr ? 'المقاعد / القطع' : 'Units / Seats',
                  value: '${rides.seatsCount}',
                  onTap: () => _showSeatsPicker(context, rides),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MashwarButton(
                  text: isAr ? 'ابحث في المسار المتاح' : 'Find Available Matches',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.qatarMaroon,
                  side: BorderSide(color: AppColors.qatarMaroon.withValues(alpha: 0.45)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PostAdScreen(initialIntent: 0)),
                  );
                },
                icon: const Icon(Icons.add_task_rounded, size: 17),
                label: Text(
                  isAr ? 'أطلب' : 'Post',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Live Community Requests & Offers Section across Qatar
  Widget _buildLiveCommunityFeedSection(BuildContext context, BoardProvider board, bool isAr) {
    final allAds = board.filteredAds;
    final displayedAds = _homeCategoryFilter == BoardAdType.all
        ? allAds
        : allAds.where((ad) => ad.type == _homeCategoryFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'طلبات وخدمات مجتمع قطر الآن' : 'Live Qatar Community Requests & Offers',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? 'توريد مواقع، حضانات، جلب أوراق، شراء بفاتورة ومقاعد بالضمان'
                        : 'Site supplies, nursery rides, doc fetches, shopping & shared seats',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySecondary().copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BoardScreen()),
                );
              },
              child: Text(
                isAr ? 'عرض الكل' : 'View All',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.qatarMaroon, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Quick Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryFilterChip(
                label: isAr ? 'الكل' : 'All',
                icon: Icons.all_inclusive_rounded,
                isSelected: _homeCategoryFilter == BoardAdType.all,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.all),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'توريد مواقع وبضائع' : 'Worksite & Cargo',
                icon: Icons.engineering_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.goodsDelivery,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.goodsDelivery),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'شراء بفاتورة وأمانات' : 'Shop & Parcels',
                icon: Icons.shopping_bag_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.parcelRequest,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.parcelRequest),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'جلب أوراق ومصالح' : 'Docs & Errands',
                icon: Icons.description_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.errandService,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.errandService),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'حضانات ومشاوير يومية' : 'Nursery & Daily',
                icon: Icons.family_restroom_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.localTrip,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.localTrip),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'مقاعد وسفر تشاركي' : 'Shared Seats',
                icon: Icons.directions_car_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.rideOffer,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.rideOffer),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: displayedAds.isEmpty
              ? Container(
                  key: ValueKey('empty_$_homeCategoryFilter'),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Center(
                    child: Text(
                      isAr
                          ? 'لا توجد طلبات في هذا القسم حالياً، كن أول من ينشر طلبه!'
                          : 'No requests in this section yet. Post yours now!',
                      style: AppTypography.bodySecondary(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  key: ValueKey('list_$_homeCategoryFilter'),
                  children: displayedAds
                      .take(5)
                      .map((ad) => _buildCommunityAdCard(context, ad, isAr))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE5E5EA),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppColors.navy),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.navy,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Bilateral-Escrow Community Card
  Widget _buildCommunityAdCard(BuildContext context, BoardAdModel ad, bool isAr) {
    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    switch (ad.type) {
      case BoardAdType.errandService:
        badgeColor = const Color(0xFF6A1B9A);
        badgeBg = const Color(0xFFF3E5F5);
        badgeIcon = Icons.description_outlined;
        break;
      case BoardAdType.localTrip:
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
        badgeIcon = Icons.family_restroom_rounded;
        break;
      case BoardAdType.goodsDelivery:
        badgeColor = AppColors.qatarMaroon;
        badgeBg = AppColors.qatarMaroonSurface;
        badgeIcon = Icons.engineering_rounded;
        break;
      case BoardAdType.rideOffer:
        badgeColor = AppColors.navy;
        badgeBg = const Color(0xFFE8EEF5);
        badgeIcon = Icons.directions_car_outlined;
        break;
      case BoardAdType.rideRequest:
        badgeColor = AppColors.warning;
        badgeBg = const Color(0xFFFEF3C7);
        badgeIcon = Icons.person_search_outlined;
        break;
      case BoardAdType.parcelRequest:
        badgeColor = AppColors.teal;
        badgeBg = AppColors.tealSurface;
        badgeIcon = Icons.shopping_bag_outlined;
        break;
      case BoardAdType.all:
        badgeColor = AppColors.navy;
        badgeBg = const Color(0xFFE8EEF5);
        badgeIcon = Icons.campaign_outlined;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MashwarPressable(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => MakeOfferSheet(ad: ad),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Sub-Tag + Escrow Badge + Price Tag (Direct Wrap children -> zero overflow on 320px!)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 13, color: badgeColor),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            ad.displaySubTag(isAr),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ad.hasEscrowProtection) MashwarEscrowBadge(isAr: isAr, compact: true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"} · ${ad.priceTagLabel(isAr)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Route Timeline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MashwarRouteTimeline(
                  from: context.trCity(ad.fromCity),
                  to: context.trCity(ad.toCity),
                  trailingTop: ad.postedAgo,
                  compact: true,
                ),
              ),
              const SizedBox(height: 8),

              // Details
              Text(
                ad.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF374151),
                  fontFamily: 'Cairo',
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),

              // Timing & Receipt Proof Indicator
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.teal),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 210),
                        child: Text(
                          ad.timeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (ad.requiresReceiptProof)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        ad.estimatedItemCost != null
                            ? (isAr
                                ? 'فاتورة حتى ${ad.estimatedItemCost} ر.ق بالضمان'
                                : 'Receipt up to ${ad.estimatedItemCost} QAR')
                            : (isAr ? 'يتطلب صورة الفاتورة' : 'Receipt Photo Req.'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9A5B00),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Footer: Author & Verification + Escrow/Chat/Action
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.navy.withValues(alpha: 0.08),
                        child: Text(
                          ad.authorName.isNotEmpty ? ad.authorName[0] : 'م',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 105),
                                child: Text(
                                  ad.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.verified_rounded, size: 13, color: AppColors.teal),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 11, color: AppColors.teal),
                              const SizedBox(width: 3),
                              Text(
                                isAr ? 'موثق QID' : 'QID Verified',
                                style: AppTypography.label(color: AppColors.teal).copyWith(fontSize: 10.5),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                              const SizedBox(width: 2),
                              Text(
                                '4.9',
                                style: AppTypography.label(color: AppColors.navy).copyWith(fontSize: 10.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ServiceEscrowScreen(ad: ad)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.escrowSurface,
                            border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_outlined, size: 16, color: AppColors.escrowGreen),
                        ),
                      ),
                      const SizedBox(width: 5),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
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
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E5EA)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.navy),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => MakeOfferSheet(ad: ad),
                          );
                        },
                        child: Text(
                          ad.isOfferCard
                              ? (isAr ? 'احجز بالضمان' : 'Book Safe')
                              : (isAr ? 'نفّذ بالضمان' : 'Fulfill Safe'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 9. Popular Corridors
  Widget _buildPopularRoutesSection(BuildContext context, RidesProvider rides, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'محاور الخدمات والمشاوير الأكثر نشاطاً في قطر' : 'Active Qatar Service Corridors',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPopularChip(context, rides, isAr ? 'الصناعية ← لوسيل' : 'Industrial Area → Lusail', 'المنطقة الصناعية', 'لوسيل'),
            _buildPopularChip(context, rides, isAr ? 'الدوحة ← الخور' : 'Doha → Al Khor', 'الدوحة', 'الخور'),
            _buildPopularChip(context, rides, isAr ? 'أم صلال ← الدوحة' : 'Umm Salal → Doha', 'أم صلال', 'الدوحة'),
            _buildPopularChip(context, rides, isAr ? 'الدوحة ← الوكرة' : 'Doha → Al Wakrah', 'الدوحة', 'الوكرة'),
            _buildPopularChip(context, rides, isAr ? 'الدوحة ← دخان' : 'Doha → Dukhan', 'الدوحة', 'دخان'),
          ],
        ),
      ],
    );
  }

  Widget _buildPopularChip(
    BuildContext context,
    RidesProvider rides,
    String label,
    String from,
    String to,
  ) {
    return ActionChip(
      avatar: const Icon(Icons.trending_up_rounded, size: 15, color: AppColors.qatarMaroon),
      label: Text(label),
      backgroundColor: const Color(0xFFF3F3F4),
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.navy, fontFamily: 'Cairo'),
      onPressed: () {
        rides.setRoute(from: from, to: to);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
        );
      },
    );
  }

  // 10. Safety & Bilateral Mutual Guarantees Grid
  Widget _buildSafetyPillarsGrid(BuildContext context, bool isAr, bool isWide) {
    final pillars = [
      _buildPillarRow(
        icon: Icons.lock_outline_rounded,
        color: AppColors.escrowGreen,
        title: isAr ? 'الضمان المالي المعلّق (Escrow)' : 'MASHWAR Escrow Fund Protection',
        description: isAr
            ? 'يُحجز أتعاب الخدمة وسقف الفاتورة في الضمان قبل التحرك لضمان عدم النصب أو التراجع من أي طرف.'
            : 'Service fee & item cap stay locked in Escrow until physical handover.',
      ),
      _buildPillarRow(
        icon: Icons.receipt_long_rounded,
        color: AppColors.qatarMaroon,
        title: isAr ? 'اعتماد الفاتورة وصورة الغرض' : 'Live Store Receipt & Photo Check',
        description: isAr
            ? 'للمشتريات ومواقع العمل: يرفع المنفّذ صورة الفاتورة والغرض وتعتمدها قبل التحرك للتسليم.'
            : 'For store runs & engineering parts: approve photo & original invoice live.',
      ),
      _buildPillarRow(
        icon: Icons.pin_outlined,
        color: AppColors.gold,
        title: isAr ? 'كود الإتمام OTP وتوثيق QID' : '4-Digit Handover OTP & QID',
        description: isAr
            ? 'لا تتحرر المستحقات لمحفظة المنفّذ إلا بإدخال كود 4 أرقام من المستلم، مع تجميد ونزاع فوري عند الخلاف.'
            : 'Payout unlocks only on 4-digit OTP entry, backed by QID & dispute freeze.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.qatarMaroon, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'كيف يمنع مشوار الاحتيال ويحفظ حق الطرفين؟' : 'How MASHWAR Prevents Fraud for Both Sides',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: pillars[0]),
                const SizedBox(width: 14),
                Expanded(child: pillars[1]),
                const SizedBox(width: 14),
                Expanded(child: pillars[2]),
              ],
            )
          else ...[
            pillars[0],
            const SizedBox(height: 10),
            pillars[1],
            const SizedBox(height: 10),
            pillars[2],
          ],
        ],
      ),
    );
  }

  Widget _buildPillarRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertMatchBanner(BuildContext context, bool isAr) {
    return AlertBanner(
      message: isAr
          ? 'وجدنا منفّذين وطلبات مطابقة لمسارك: الدوحة ← الخور\nجاهز للتنفيذ بالضمان'
          : 'Found matching requests & helpers on Doha → Al Khor',
      type: AlertBannerType.info,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BoardScreen()),
        );
      },
    );
  }

  Widget _buildUpcomingBookingCard(BuildContext context, RidesProvider rides, bool isAr) {
    final booking = rides.activeBooking!;
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(isAr ? 'مشوارك القادم' : 'Your Upcoming Trip', style: AppTypography.label()),
              ),
              const MashwarBadge(type: BadgeType.confirmed),
            ],
          ),
          const SizedBox(height: 10),
          MashwarRouteTimeline(
            from: context.trCity(booking.fromCity),
            to: context.trCity(booking.toCity),
            compact: true,
          ),
          const SizedBox(height: 8),
          Text(
            '${context.trDate(booking.departureDate)}، ${booking.departureTime} · ${booking.driverName}',
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: 14),
          MashwarButton(
            text: isAr ? 'عرض الحجز' : 'View Booking',
            variant: MashwarButtonVariant.secondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingConfirmationScreen(ride: booking),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 11. Universal Service Provider Showcase Card (NEVER use 'انشر رحلة' string!)
  Widget _buildDriverPromoCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.navy, Color(0xFF173D61)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          MashwarAssetArt(
            assetPath: 'assets/images/hero_qatar_services.jpg',
            width: 74,
            height: 74,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(14),
            fallbackIcon: Icons.handshake_rounded,
            fallbackBg: Colors.white.withValues(alpha: 0.12),
            fallbackColor: AppColors.gold,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'متحرك بطريقك أو تقدّم خدمات بمنطقتك؟' : 'On the move or ready to help nearby?',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'نفّذ طلبات الشراء، توريد المواقع، أو شارك مقاعدك الشاغرة بأتعاب مضمونة بـ Escrow'
                      : 'Fulfill shopping errands, worksite supplies or share seats with guaranteed Escrow payouts',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.86),
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DriverOnboardingScreen()),
                    );
                  },
                  child: Text(
                    isAr ? 'ابدأ كمزود خدمة' : 'Become a Provider',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteField({
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? leadingDotColor,
    bool isSquare = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        ),
        child: Row(
          children: [
            if (leadingDotColor != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: leadingDotColor,
                  shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isSquare ? BorderRadius.circular(2.5) : null,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSeatsPicker(BuildContext context, RidesProvider rides) {
    final isAr = context.isArabic;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'العدد المطلوب' : 'Units / Seats Needed',
                  style: AppTypography.title(),
                ),
                const SizedBox(height: AppDimens.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [1, 2, 3, 4].map((count) {
                    final isSelected = rides.seatsCount == count;
                    return GestureDetector(
                      onTap: () {
                        rides.setSeatsCount(count);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.navy : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.navy : AppColors.borderDisabled,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: AppTypography.title(
                              color: isSelected ? Colors.white : AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimens.space16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceTileData {
  const _ServiceTileData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onTap,
    this.badge,
    this.badgeBg,
    this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeColor;
}
