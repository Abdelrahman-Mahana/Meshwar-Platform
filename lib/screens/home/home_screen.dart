import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
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
            final horizontalPad = isWide ? AppDimens.space32 : AppDimens.space20;

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
                      // Top User Greeting, Wallet Shortcut, Notifications & Avatar
                      _buildTopHeader(context, auth, isAr),
                      const SizedBox(height: AppDimens.space16),

                      // Two Primary Community Action Cards (اطلب مشوار أو خدمة | اعرض مشوار أو خدمة)
                      _buildTwoPrimaryActionButtons(context, isAr),
                      const SizedBox(height: AppDimens.space20),

                      // Active Alerts & Upcoming Bookings (if any)
                      if (auth.user.hasActiveAlerts) ...[
                        _buildAlertMatchBanner(context, isAr),
                        const SizedBox(height: AppDimens.space16),
                      ],
                      if (rides.activeBooking != null) ...[
                        _buildUpcomingBookingCard(context, rides, isAr),
                        const SizedBox(height: AppDimens.space16),
                      ],

                      // Fast Search Card (البحث السريع في خطوط السير والمحافظات)
                      _buildSearchCard(context, rides, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // Live Community Feed of Requests & Errands (المشاوير والخدمات الحية الآن)
                      _buildLiveCommunityFeedSection(context, board, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // Popular Corridors (محاور شائعة)
                      _buildPopularRoutesSection(context, rides, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // Safety & Guarantees Strip (ضمانات وأمان مشوار)
                      _buildSafetyPillarsGrid(context, isAr),
                      const SizedBox(height: AppDimens.space24),

                      // Driver Partner Card
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

  // 1. Top Header with User Profile, Verification badge & Wallet
  Widget _buildTopHeader(BuildContext context, AuthProvider auth, bool isAr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'أهلاً بك،' : 'Welcome back,',
                style: AppTypography.bodySecondary().copyWith(fontSize: 13),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      auth.user.fullName.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (auth.user.isVerified)
                    const Icon(Icons.verified_rounded, size: 18, color: AppColors.teal),
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Wallet Pill
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 15, color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      '${auth.user.walletBalance.toStringAsFixed(0)} ${isAr ? "ج.م" : "EGP"}',
                      style: AppTypography.label(color: AppColors.teal).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notifications Shortcut
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.navy),
              tooltip: isAr ? 'الإشعارات' : 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
            // User Profile Avatar Circle -> Opens UserProfileScreen on tap (tested for 'ع')
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
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

  // 2. Two Primary Community Action Cards (اطلب مشوار أو خدمة | اعرض مشوار أو خدمة)
  Widget _buildTwoPrimaryActionButtons(BuildContext context, bool isAr) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: اطلب مشوار أو خدمة
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

          // Card 2: اعرض مشوارك أو خدمتك
          Expanded(
            child: _buildActionCard(
              title: isAr ? 'اعرض مشوار أو خدمة' : 'Offer Service',
              subtitle: isAr ? 'كراسي فاضية بعربيتك، توصيل بالسكة' : 'Empty seats, deliveries on your way',
              icon: Icons.directions_car_filled_rounded,
              iconBg: AppColors.goldSurface,
              iconColor: AppColors.navy,
              borderColor: AppColors.borderDisabled,
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Icon(Icons.arrow_forward_rounded, color: iconColor, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
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
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Fast Search Card (خطوط السير والبحث السريع)
  Widget _buildSearchCard(BuildContext context, RidesProvider rides, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: AppColors.navy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAr ? 'البحث عن مشوار أو سفر متاح' : 'Search Available Rides & Routes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
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
                    onTap: () => rides.swapLocations(),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.swap_vert_rounded,
                        size: 20,
                        color: AppColors.teal,
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

  // 5. Live Community Requests & Offers Section (خلاصة المشاوير والخدمات الحية الآن)
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

        if (displayedAds.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Center(
              child: Text(
                isAr ? 'لا توجد طلبات في هذا القسم حالياً، كن أول من ينشر طلبه!' : 'No requests in this section yet. Post yours now!',
                style: AppTypography.bodySecondary(),
              ),
            ),
          )
        else
          ...displayedAds.take(4).map((ad) => _buildCommunityAdCard(context, ad, isAr)),
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

  // Modern Community Card for Services & Errands (Fully responsive)
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Badge + Price Tag (Wrap guarantees zero overflow on narrow screens)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const SizedBox(height: 8),

          // Route: From ← To
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.teal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  context.trRoute('${ad.fromCity} ← ${ad.toCity}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                ad.postedAgo,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo'),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Details
          Text(
            ad.description,
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
              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ad.timeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Footer: Author & ID Verification Badge + Quick Actions (Wrap handles narrow screens)
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
                    radius: 13,
                    backgroundColor: AppColors.navy.withValues(alpha: 0.08),
                    child: Text(
                      ad.authorName.isNotEmpty ? ad.authorName[0] : 'ع',
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
                            constraints: const BoxConstraints(maxWidth: 100),
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
                    borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                        borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  // 6. Safety & Mutual Guarantees Grid (ضمانات مشوار لحفظ حقوق الطرفين)
  Widget _buildSafetyPillarsGrid(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.navy, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'كيف يحفظ مشوار حق وسلامة الطرفين؟' : 'How MASHWAR Protects Both Sides',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPillarRow(
            icon: Icons.badge_outlined,
            color: AppColors.teal,
            title: isAr ? 'توثيق الهوية والرقم القومي' : 'Mandatory National ID Verification',
            description: isAr
                ? 'لا يمكن لأي طرف تقديم عروض أو طلبات دون مطابقة الهوية الشخصية'
                : 'All participants must verify National ID before posting or making offers',
          ),
          const SizedBox(height: 10),
          _buildPillarRow(
            icon: Icons.pin_outlined,
            color: AppColors.gold,
            title: isAr ? 'كود التسليم الرقمي الآمن (OTP)' : '4-Digit Handover Security Code',
            description: isAr
                ? 'لا يتم إتمام تسليم أي طرد أو بضاعة أو ورقة إلا بمطابقة كود التسليم بين الطرفين'
                : 'No delivery is closed without mutual 4-digit code matching',
          ),
          const SizedBox(height: 10),
          _buildPillarRow(
            icon: Icons.handshake_outlined,
            color: AppColors.navy,
            title: isAr ? 'تفاوض حر وعادل ومباشر' : 'Direct & Fair Community Negotiation',
            description: isAr
                ? 'تحديد المقابل بالتراضي التام بين المواطنين بدون أي عمولات خفية'
                : 'Direct fair pricing agreed upon mutually with zero hidden fees',
          ),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
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

  // 7. Popular Routes
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
      label: Text(label),
      backgroundColor: const Color(0xFFF3F3F4),
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy, fontFamily: 'Cairo'),
      onPressed: () {
        rides.setRoute(from: from, to: to);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
        );
      },
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
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
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
              Expanded(
                child: Text(isAr ? 'مشوارك القادم' : 'Your Upcoming Trip', style: AppTypography.label()),
              ),
              const MashwarBadge(type: BadgeType.confirmed),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.trRoute('${rides.activeBooking!.fromCity} ← ${rides.activeBooking!.toCity}'),
            style: AppTypography.title(),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.trDate(rides.activeBooking!.departureDate)}، ${rides.activeBooking!.departureTime} · ${rides.activeBooking!.driverName}',
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: 14),
          MashwarButton(
            text: isAr ? 'عرض الحجز' : 'View Booking',
            variant: MashwarButtonVariant.secondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingConfirmationScreen(ride: rides.activeBooking!),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverPromoCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.navy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'عندك عربية أو وسيلة نقل؟' : 'Have a car or vehicle?',
                  style: AppTypography.title().copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  isAr
                      ? 'انشر رحلتك واكسب من الكراسي الفاضية وقضاء المشاوير'
                      : 'Publish trips and earn from empty seats & errands',
                  style: AppTypography.bodySecondary(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MashwarButton(
            width: 88,
            height: 40,
            text: isAr ? 'ابدأ' : 'Start',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverOnboardingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                    style: AppTypography.body(color: AppColors.navy).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
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
