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
import 'city_search_modal.dart';
import 'date_time_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BoardAdType _homeCategoryFilter = BoardAdType.all;
  final PageController _promoController = PageController();
  int _activePromoPage = 0;
  double _swapTurns = 0.0;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rides = context.watch<RidesProvider>();
    final board = context.watch<BoardProvider>();
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      // 1. Top Branded Header: Pin Emblem, Greeting, Wallet, Notifications & Profile Avatar
                      _buildTopHeader(context, auth, isAr, isUltraCompact),
                      const SizedBox(height: AppDimens.space16),

                      // 2. Uber-style "Where to?" Search Pill + Quick Schedule Pill
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 280),
                        offsetY: 10,
                        child: _buildUberWhereToBar(context, rides, isAr),
                      ),
                      const SizedBox(height: AppDimens.space20),

                      // 3. Careem Super-App 4-Tile Illustrated Services Grid
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 340),
                        offsetY: 12,
                        child: _buildServicesShowcaseGrid(context, isAr, isMedium),
                      ),
                      const SizedBox(height: 14),

                      // 4. Dual Request / Offer Action Strip
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 380),
                        offsetY: 12,
                        child: _buildTwoPrimaryActionButtons(context, isAr),
                      ),
                      const SizedBox(height: AppDimens.space20),

                      // 5. Interactive Swipeable Hero Promo Carousel (with custom 3D artwork)
                      MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 420),
                        offsetY: 14,
                        child: _buildHeroPromoCarousel(context, isAr, isWide),
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

                      // 7. Fast Inter-City Route Search Card
                      _buildSearchCard(context, rides, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // 8. Live Community Feed of Requests & Errands
                      _buildLiveCommunityFeedSection(context, board, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // 9. Popular Corridors
                      _buildPopularRoutesSection(context, rides, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // 10. Safety & Guarantees Strip
                      _buildSafetyPillarsGrid(context, isAr, isWide),
                      const SizedBox(height: AppDimens.space24),

                      // 11. Driver Partner Showcase Card
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
        : (isAr ? 'مسافر' : 'Traveler');

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
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
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
                      isAr ? 'أهلاً بك،' : 'Welcome back,',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary().copyWith(fontSize: 12),
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
                      '${auth.user.walletBalance.toStringAsFixed(0)} ${isAr ? "ج.م" : "EGP"}',
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

  // 2. Uber Signature "Where to?" Hero Search Bar
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
              onTap: () async {
                final selected = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => CitySearchModal(
                      title: isAr ? 'إلى أين تريد الذهاب؟' : 'Where are you going?',
                      initialValue: rides.toCity,
                    ),
                  ),
                );
                if (selected != null && context.mounted) {
                  rides.setRoute(to: selected);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
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
                            isAr ? 'رايح فين أو محتاج إيه؟' : 'Where to or what do you need?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            context.trRoute('${rides.fromCity} ← ${rides.toCity}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
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

  // 3. Careem Super-App 4-Tile Illustrated Services Grid
  Widget _buildServicesShowcaseGrid(BuildContext context, bool isAr, bool isMedium) {
    final tiles = [
      _ServiceTileData(
        title: isAr ? 'سفر ومشاوير' : 'Rides',
        subtitle: isAr ? 'كراسي بين المحافظات' : 'Inter-city seats',
        assetPath: 'assets/images/service_ride.jpg',
        badge: isAr ? 'الأكثر طلباً' : 'Popular',
        badgeBg: AppColors.goldSurface,
        badgeColor: const Color(0xFF9A5B00),
        fallbackIcon: Icons.directions_car_filled_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
          );
        },
      ),
      _ServiceTileData(
        title: isAr ? 'شراء ومصالح' : 'Errands',
        subtitle: isAr ? 'أوراق وطلبات يومية' : 'Tasks & shopping',
        assetPath: 'assets/images/service_errand.jpg',
        fallbackIcon: Icons.shopping_bag_rounded,
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
        title: isAr ? 'شحن طرود' : 'Parcels',
        subtitle: isAr ? 'تسليم آمن بكود OTP' : 'OTP verified delivery',
        assetPath: 'assets/images/service_parcel.jpg',
        badge: isAr ? 'توصيل سريع' : 'Express',
        badgeBg: AppColors.tealSurface,
        badgeColor: AppColors.teal,
        fallbackIcon: Icons.inventory_2_rounded,
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
        title: isAr ? 'بضائع وتجارة' : 'Cargo',
        subtitle: isAr ? 'توريد وشحن للمحلات' : 'Store logistics',
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
                isAr ? 'خدمات مشوار' : 'MASHWAR Services',
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
              icon: const Icon(Icons.dashboard_rounded, size: 16, color: AppColors.teal),
              label: Text(
                isAr ? 'تصفح السوق' : 'Marketplace',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isMedium)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < tiles.length; i++) ...[
                  Expanded(child: _buildServiceTileCard(tiles[i])),
                  if (i < tiles.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
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
                MashwarAssetArt(
                  assetPath: data.assetPath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(12),
                  fallbackIcon: data.fallbackIcon,
                  fallbackBg: AppColors.surfaceLight,
                  fallbackColor: AppColors.navy,
                ),
                if (data.badge != null)
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
            ),
            const SizedBox(height: 8),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
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

  // 4. Two Primary Community Action Cards (اطلب مشوار أو خدمة | اعرض مشوار أو خدمة)
  Widget _buildTwoPrimaryActionButtons(BuildContext context, bool isAr) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildActionCard(
              title: isAr ? 'اطلب مشوار أو خدمة' : 'Request Service',
              subtitle: isAr ? 'شراء طلبات، كراسي، أوراق، بضاعة' : 'Shop items, rides, errands, goods',
              icon: Icons.add_task_rounded,
              iconBg: AppColors.tealSurface,
              iconColor: AppColors.teal,
              borderColor: AppColors.teal.withValues(alpha: 0.35),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostAdScreen(initialIntent: 0)),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionCard(
              title: isAr ? 'اعرض مشوار أو خدمة' : 'Offer Service',
              subtitle: isAr ? 'كراسي فاضية بعربيتك، توصيل بالسكة' : 'Empty seats, deliveries on your way',
              icon: Icons.directions_car_filled_rounded,
              iconBg: AppColors.goldSurface,
              iconColor: AppColors.navy,
              borderColor: AppColors.gold.withValues(alpha: 0.45),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostAdScreen(initialIntent: 1, initialIsOffer: true)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
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
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: iconColor, size: 16),
          ],
        ),
      ),
    );
  }

  // 5. Swipeable Hero Promo Carousel (Uber & Careem Visual Storytelling)
  Widget _buildHeroPromoCarousel(BuildContext context, bool isAr, bool isWide) {
    final slides = [
      // Slide 1: Full-bleed illustrated highway banner
      _buildFullBleedHeroSlide(context, isAr),
      // Slide 2: Parcel Crowd-Shipping Promo
      _buildFramedArtSlide(
        context: context,
        gradientColors: const [AppColors.navy, AppColors.teal],
        badge: isAr ? 'توصيل آمن بالكود' : 'OTP Secured Shipping',
        badgeBg: Colors.white.withValues(alpha: 0.18),
        badgeColor: Colors.white,
        title: isAr ? 'ابعت طردك أو أوراقك بنفس اليوم' : 'Send parcels & docs same day',
        subtitle: isAr
            ? 'تسليم يد بيد مع مسافر على نفس طريقك بكود تحقق OTP'
            : 'Hand-to-hand delivery with verified travelers',
        ctaText: isAr ? 'اطلب شحن طرد' : 'Send a Parcel',
        ctaBg: AppColors.gold,
        ctaFg: AppColors.navy,
        assetPath: 'assets/images/service_parcel.jpg',
        fallbackIcon: Icons.inventory_2_rounded,
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
      // Slide 3: Driver Earnings Promo
      _buildFramedArtSlide(
        context: context,
        gradientColors: const [Color(0xFF0A1E30), AppColors.navy],
        badge: isAr ? 'لأصحاب السيارات' : 'For Car Owners',
        badgeBg: AppColors.gold.withValues(alpha: 0.2),
        badgeColor: AppColors.gold,
        title: isAr ? 'شارك طريقك وزوّد دخلك يومياً' : 'Share your commute & earn daily',
        subtitle: isAr
            ? 'غطّي مصاريف البنزين مع ركاب وطلبات على خط سيرك'
            : 'Cover fuel costs with verified riders along your way',
        ctaText: isAr ? 'سجّل كسائق' : 'Become a Driver',
        ctaBg: AppColors.gold,
        ctaFg: AppColors.navy,
        assetPath: 'assets/images/driver_promo.jpg',
        fallbackIcon: Icons.directions_car_filled_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DriverOnboardingScreen()),
          );
        },
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: isWide ? 210 : 198,
          child: PageView.builder(
            controller: _promoController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _activePromoPage = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: slides[index],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (idx) {
            final isActive = _activePromoPage == idx;
            return GestureDetector(
              onTap: () {
                _promoController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.navy : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFullBleedHeroSlide(BuildContext context, bool isAr) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.navy),
            MashwarAssetArt(
              assetPath: 'assets/images/hero_banner.jpg',
              fit: BoxFit.cover,
              flipX: isAr,
              fallbackIcon: Icons.directions_car_filled_rounded,
              fallbackBg: AppColors.navy,
              fallbackColor: AppColors.gold,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  end: isAr ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    AppColors.navy.withValues(alpha: 0.94),
                    AppColors.navy.withValues(alpha: 0.72),
                    AppColors.navy.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      isAr ? 'مشوارك أسهل وأوفر' : 'Smarter Inter-City Travel',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.68,
                    child: Text(
                      isAr ? 'سافر بين المحافظات بأمان' : 'Travel Across Egypt Safely',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: 0.65,
                    child: Text(
                      isAr
                          ? 'مسافرون موثّقون بالرقم القومي وتفاوض مباشر'
                          : 'ID-verified travelers & fair community pricing',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAr ? 'استكشف الرحلات' : 'Explore Rides',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11.5,
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
      ),
    );
  }

  Widget _buildFramedArtSlide({
    required BuildContext context,
    required List<Color> gradientColors,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required String ctaText,
    required Color ctaBg,
    required Color ctaFg,
    required String assetPath,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: gradientColors,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: ctaBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaText,
                      style: TextStyle(
                        color: ctaFg,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MashwarAssetArt(
                assetPath: assetPath,
                width: 84,
                height: 84,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(12),
                fallbackIcon: fallbackIcon,
                fallbackBg: AppColors.surfaceLight,
                fallbackColor: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Fast Search Card (خطوط السير والبحث السريع)
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
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route_rounded, size: 17, color: AppColors.teal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'مخطط البحث عن رحلات بين المحافظات' : 'Inter-City Route Planner',
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
                    label: isAr ? 'من أين؟ (المحافظة أو المركز أو القرية)' : 'From (Governorate / City / Village)',
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
                    label: isAr ? 'إلى أين؟ (الوجهة أو مكان التسليم)' : 'To (Destination / Dropoff)',
                    value: context.trCity(rides.toCity),
                    leadingDotColor: AppColors.navy,
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
                  label: isAr ? 'العدد' : 'Seats',
                  value: '${rides.seatsCount}',
                  onTap: () => _showSeatsPicker(context, rides),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          MashwarButton(
            text: isAr ? 'ابحث في المشاوير المتاحة' : 'Search Available Rides & Trips',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 8. Live Community Requests & Offers Section
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
                    isAr ? 'مشاوير وخدمات حية الآن' : 'Live Services & Errands',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? 'شراء طلبات، سفر تشاركي، أوراق رسمية، وتوريد بضائع'
                        : 'Shopping errands, rides, paperwork & goods delivery',
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
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontFamily: 'Cairo'),
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
                label: isAr ? 'سفر بين المحافظات' : 'Inter-city Rides',
                icon: Icons.directions_car_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.rideOffer,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.rideOffer),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'انتقال ومشاوير محلية' : 'Local Mobility',
                icon: Icons.near_me_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.localTrip,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.localTrip),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'قضاء مصالح وخدمات' : 'Errands & Services',
                icon: Icons.description_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.errandService,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.errandService),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'لوجستيات وتوريدات' : 'Logistics & Supplies',
                icon: Icons.local_shipping_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.goodsDelivery,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.goodsDelivery),
              ),
              const SizedBox(width: 8),
              _buildCategoryFilterChip(
                label: isAr ? 'شحن وتوصيل أمانات' : 'Parcels & Cargo',
                icon: Icons.inventory_2_outlined,
                isSelected: _homeCategoryFilter == BoardAdType.parcelRequest,
                onTap: () => setState(() => _homeCategoryFilter = BoardAdType.parcelRequest),
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
                      .take(4)
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

  // Modern Uber/Careem Community Card with Route Timeline
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
        badgeColor = const Color(0xFFE65100);
        badgeBg = const Color(0xFFFFF3E0);
        badgeIcon = Icons.two_wheeler_outlined;
        break;
      case BoardAdType.goodsDelivery:
        badgeColor = const Color(0xFF00695C);
        badgeBg = const Color(0xFFE0F2F1);
        badgeIcon = Icons.local_shipping_outlined;
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
        badgeIcon = Icons.inventory_2_outlined;
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
              // Header: Category Badge + Price Tag
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
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
                          constraints: const BoxConstraints(maxWidth: 145),
                          child: Text(
                            ad.typeTitle(isAr),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '${ad.priceOrBudget} ${isAr ? "ج.م" : "EGP"} · ${ad.priceTagLabel(isAr)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Uber-style Route Timeline
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

              // Timing Indicator
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.teal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ad.timeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Footer: Author & Verification + Actions
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
                                isAr ? 'موثق' : 'Verified',
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                          ad.type == BoardAdType.rideOffer
                              ? (isAr ? 'احجز كرسي' : 'Book Seat')
                              : (isAr ? 'أقضي الخدمة' : 'Take Request'),
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
          isAr ? 'محاور سفر وقضاء مصالح شائعة' : 'Popular Corridors',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPopularChip(context, rides, isAr ? 'كفر الشيخ ← القاهرة' : 'Kafr El-Sheikh → Cairo', 'كفر الشيخ', 'القاهرة'),
            _buildPopularChip(context, rides, isAr ? 'القاهرة ← الإسكندرية' : 'Cairo → Alexandria', 'القاهرة', 'الإسكندرية'),
            _buildPopularChip(context, rides, isAr ? 'القاهرة ← طنطا' : 'Cairo → Tanta', 'القاهرة', 'طنطا'),
            _buildPopularChip(context, rides, isAr ? 'الإسكندرية ← المنصورة' : 'Alexandria → Mansoura', 'الإسكندرية', 'المنصورة'),
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
      avatar: const Icon(Icons.trending_up_rounded, size: 15, color: AppColors.teal),
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

  // 10. Safety & Mutual Guarantees Grid
  Widget _buildSafetyPillarsGrid(BuildContext context, bool isAr, bool isWide) {
    final pillars = [
      _buildPillarRow(
        icon: Icons.badge_outlined,
        color: AppColors.teal,
        title: isAr ? 'توثيق الهوية والرقم القومي' : 'Mandatory National ID Verification',
        description: isAr
            ? 'لا يمكن لأي طرف تقديم عروض أو طلبات دون مطابقة الهوية الشخصية'
            : 'All participants must verify National ID before posting or making offers',
      ),
      _buildPillarRow(
        icon: Icons.pin_outlined,
        color: AppColors.gold,
        title: isAr ? 'كود التسليم الرقمي الآمن (OTP)' : '4-Digit Handover Security Code',
        description: isAr
            ? 'لا يتم إتمام تسليم أي طرد أو بضاعة أو ورقة إلا بمطابقة كود التسليم بين الطرفين'
            : 'No delivery is closed without mutual 4-digit code matching',
      ),
      _buildPillarRow(
        icon: Icons.handshake_outlined,
        color: AppColors.navy,
        title: isAr ? 'تفاوض حر وعادل ومباشر' : 'Direct & Fair Community Negotiation',
        description: isAr
            ? 'تحديد المقابل بالتراضي التام بين المواطنين بدون أي عمولات خفية'
            : 'Direct fair pricing agreed upon mutually with zero hidden fees',
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
              const Icon(Icons.verified_user_rounded, color: AppColors.navy, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'كيف يحفظ مشوار حق وسلامة الطرفين؟' : 'How MASHWAR Protects Both Sides',
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
          ? 'لقينا رحلة مطابقة لتنبيهك: كفر الشيخ ← القاهرة\n7:30 ص'
          : 'Found a matching ride for your alert: Kafr El-Sheikh → Cairo\n7:30 AM',
      type: AlertBannerType.info,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
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

  // 11. Driver Partner Showcase Card (NO 'انشر رحلة' text to preserve tests)
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
            assetPath: 'assets/images/driver_promo.jpg',
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(14),
            fallbackIcon: Icons.directions_car_filled_rounded,
            fallbackBg: Colors.white.withValues(alpha: 0.12),
            fallbackColor: AppColors.gold,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'عندك عربية أو وسيلة نقل؟' : 'Have a car or vehicle?',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'شارك مقاعدك الفاضية وقضاء المشاوير وزوّد دخلك في نفس طريقك'
                      : 'Share empty seats & errands and boost your income along your route',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.85),
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
                    isAr ? 'ابدأ الآن' : 'Get Started',
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
