import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_typography.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/mashwar_badge.dart';
import '../core/widgets/mashwar_button.dart';
import '../core/localization/app_strings.dart';
import '../data/mock_data.dart';
import '../data/models/user_model.dart';
import '../state/auth_provider.dart';
import '../state/rides_provider.dart';
import '../state/parcels_provider.dart';
import '../state/settings_provider.dart';
import 'home/home_screen.dart';
import 'board/board_screen.dart';
import 'trip/active_trip_screen.dart';
import 'trip/rate_trip_screen.dart';
import 'chat/chat_screen.dart';
import 'booking/booking_waiting_screen.dart';
import 'parcel/parcel_tracking_screen.dart';
import 'parcel/parcel_dispute_screen.dart';
import 'alerts/my_alerts_screen.dart';
import 'auth/id_verification_screen.dart';
import 'settings/settings_screen.dart';
import 'vehicle/vehicle_registration_screen.dart';
import 'wallet/wallet_screen.dart';
import 'auth/welcome_screen.dart';
import 'driver/driver_rides_management_screens.dart';
import 'driver/driver_onboarding_screens.dart';
import 'safety/safety_screens.dart';
import 'account/account_extra_screens.dart';
import 'account/legal_and_backend_screens.dart';
import 'board/board_extra_screens.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  // Segment states for Tabs
  bool _isUpcomingRides = true;
  bool _isUpcomingParcels = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rides = context.watch<RidesProvider>();
    final parcels = context.watch<ParcelsProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;

    final List<Widget> pages = [
      const HomeScreen(),
      const BoardScreen(),
      _buildMyRidesTab(context, rides, isAr),
      _buildMyParcelsTab(context, parcels, isAr),
      _buildAccountTab(context, auth, settings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;
        final isExtended = constraints.maxWidth >= 1120;

        if (isWide) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) => setState(() => _currentIndex = index),
                  extended: isExtended,
                  minWidth: 80,
                  minExtendedWidth: 220,
                  backgroundColor: Colors.white,
                  indicatorColor: AppColors.navy.withValues(alpha: 0.08),
                  selectedIconTheme: const IconThemeData(color: AppColors.navy, size: 22),
                  unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
                  selectedLabelTextStyle: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 13,
                  ),
                  unselectedLabelTextStyle: AppTypography.bodySecondary().copyWith(fontSize: 13),
                  leading: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: isExtended ? 16 : 8,
                    ),
                    child: isExtended
                        ? const BrandLogo(fontSize: 24, showEnglish: true)
                        : const MashwarPinIcon(size: 32),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
                        child: isExtended
                            ? OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  side: const BorderSide(color: Color(0xFFE5E5EA)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => settings.toggleLanguage(),
                                icon: const Icon(Icons.language_rounded, size: 18),
                                label: Text(
                                  isAr ? 'English' : 'العربية',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              )
                            : IconButton(
                                tooltip: isAr ? 'English' : 'العربية',
                                icon: const Icon(Icons.language_rounded, color: AppColors.navy),
                                onPressed: () => settings.toggleLanguage(),
                              ),
                      ),
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: Text(isAr ? 'الرئيسية' : 'Home'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded),
                      label: Text(isAr ? 'اللوحة' : 'Board'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.directions_car_outlined),
                      selectedIcon: const Icon(Icons.directions_car_rounded),
                      label: Text(isAr ? 'رحلاتي' : 'My Rides'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2_rounded),
                      label: Text(isAr ? 'طرودي' : 'My Parcels'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: Text(isAr ? 'حسابي' : 'Account'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E5EA)),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.borderDisabled.withValues(alpha: 0.5)),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedLabelStyle: AppTypography.label().copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.label(),
              selectedItemColor: AppColors.navy,
              unselectedItemColor: AppColors.textSecondary,
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: isAr ? 'الرئيسية' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard_outlined),
                  activeIcon: const Icon(Icons.dashboard_rounded),
                  label: isAr ? 'اللوحة' : 'Board',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.directions_car_outlined),
                  activeIcon: const Icon(Icons.directions_car_rounded),
                  label: isAr ? 'رحلاتي' : 'My Rides',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.inventory_2_outlined),
                  activeIcon: const Icon(Icons.inventory_2_rounded),
                  label: isAr ? 'طرودي' : 'My Parcels',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded),
                  activeIcon: const Icon(Icons.person_rounded),
                  label: isAr ? 'حسابي' : 'Account',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Page 28: My Rides Tab (رحلاتي)
  Widget _buildMyRidesTab(BuildContext context, RidesProvider rides, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'رحلاتي' : 'My Rides', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Switch: قادمة vs سابقة (Page 28)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: 10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWide ? 380 : double.infinity),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isUpcomingRides = true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isUpcomingRides ? AppColors.navy : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isAr ? 'قادمة' : 'Upcoming',
                                        style: AppTypography.bodySecondary(
                                          color: _isUpcomingRides ? Colors.white : AppColors.textPrimary,
                                        ).copyWith(fontWeight: _isUpcomingRides ? FontWeight.w700 : FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isUpcomingRides = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isUpcomingRides ? AppColors.navy : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isAr ? 'سابقة' : 'Past',
                                        style: AppTypography.bodySecondary(
                                          color: !_isUpcomingRides ? Colors.white : AppColors.textPrimary,
                                        ).copyWith(fontWeight: !_isUpcomingRides ? FontWeight.w700 : FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Rides List or Empty State
                    Expanded(
                      child: _isUpcomingRides
                          ? _buildUpcomingRidesList(context, rides, isAr, isWide: isWide)
                          : _buildPastRidesList(context, isAr, isWide: isWide),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveCardList(List<Widget> cards, bool isWide) {
    if (!isWide) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space12),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space16),
        itemBuilder: (_, i) => cards[i],
      );
    }
    final pairCount = (cards.length / 2).ceil();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space12),
      itemCount: pairCount,
      itemBuilder: (_, rowIdx) {
        final first = rowIdx * 2;
        final second = first + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[first]),
              const SizedBox(width: AppDimens.space16),
              Expanded(
                child: second < cards.length ? cards[second] : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingRidesList(BuildContext context, RidesProvider rides, bool isAr, {bool isWide = false}) {
    final cards = <Widget>[
      // Dynamically booked rides from RidesProvider
      ...rides.bookedRides.map(
        (bookedRide) => _buildTripCard(
          context: context,
          route: context.trRoute('${bookedRide.fromCity} ← ${bookedRide.toCity}'),
          dateText: '${context.trDate(bookedRide.departureDate)}، ${bookedRide.departureTime}',
          driverName: bookedRide.driverName,
          badgeText: isAr ? 'حجز جديد' : 'New Booking',
          badgeType: BadgeType.confirmed,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActiveTripScreen(ride: bookedRide),
              ),
            );
          },
        ),
      ),
      // Card 1: مؤكد
      _buildTripCard(
        context: context,
        route: context.trRoute('كفر الشيخ ← القاهرة'),
        dateText: isAr ? 'الجمعة 6 نوفمبر، 7:30 ص' : 'Fri Nov 6, 7:30 AM',
        driverName: 'محمد سعيد',
        badgeText: isAr ? 'مؤكد' : 'Confirmed',
        badgeType: BadgeType.confirmed,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActiveTripScreen(ride: MockData.initialRides[0]),
            ),
          );
        },
        actionButton: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.teal,
            side: const BorderSide(color: AppColors.teal),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: Text(isAr ? 'محادثة السائق' : 'Chat Driver'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  driverName: 'محمد سعيد',
                  driverCar: 'هيونداي إلنترا، أبيض (س ق ر 1942)',
                  tripRoute: context.trRoute('كفر الشيخ ← القاهرة'),
                ),
              ),
            );
          },
        ),
      ),
      // Card 2: بانتظار الرد
      _buildTripCard(
        context: context,
        route: context.trRoute('طنطا ← الإسكندرية'),
        dateText: isAr ? 'السبت 7 نوفمبر، 9:00 ص' : 'Sat Nov 7, 9:00 AM',
        driverName: 'أحمد علي',
        badgeText: isAr ? 'بانتظار الرد' : 'Waiting',
        badgeType: BadgeType.underReview,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookingWaitingScreen(
                ride: MockData.initialRides[1],
                seatsCount: 1,
                totalPrice: 110,
              ),
            ),
          );
        },
      ),
    ];

    return _buildResponsiveCardList(cards, isWide);
  }

  Widget _buildPastRidesList(BuildContext context, bool isAr, {bool isWide = false}) {
    final cards = <Widget>[
      // Past Card 1: مكتمل
      _buildTripCard(
        context: context,
        route: context.trRoute('القاهرة ← كفر الشيخ'),
        dateText: isAr ? 'الأحد 25 أكتوبر' : 'Sun Oct 25',
        driverName: 'منى حسن',
        badgeText: isAr ? 'مكتمل' : 'Completed',
        badgeType: BadgeType.verified,
        actionButton: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          icon: const Icon(Icons.star_outline_rounded, size: 18),
          label: Text(
            isAr ? 'تقييم المشوار' : 'Rate Trip',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RateTripScreen(
                  driverName: 'منى حسن',
                  route: context.trRoute('القاهرة ← كفر الشيخ'),
                ),
              ),
            );
          },
        ),
      ),
      // Past Card 2: ملغى
      _buildTripCard(
        context: context,
        route: context.trRoute('طنطا ← القاهرة'),
        dateText: isAr ? 'الخميس 22 أكتوبر' : 'Thu Oct 22',
        driverName: 'أحمد علي',
        badgeText: isAr ? 'ملغى' : 'Cancelled',
        badgeType: BadgeType.rejected,
      ),
    ];

    return _buildResponsiveCardList(cards, isWide);
  }

  Widget _buildTripCard({
    required BuildContext context,
    required String route,
    required String dateText,
    required String driverName,
    required String badgeText,
    required BadgeType badgeType,
    VoidCallback? onTap,
    Widget? actionButton,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                  child: Text(
                    route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 8),
                MashwarBadge(type: badgeType, customLabel: badgeText),
              ],
            ),
            const SizedBox(height: 6),
            Text(dateText, style: AppTypography.bodySecondary()),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    driverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ),
                if (actionButton != null) actionButton,
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Page 35: My Parcels Tab (طرودي)
  Widget _buildMyParcelsTab(BuildContext context, ParcelsProvider parcels, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'طرودي' : 'My Parcels', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Switch: قادمة vs سابقة (Page 35)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: 10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWide ? 380 : double.infinity),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isUpcomingParcels = true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isUpcomingParcels ? AppColors.navy : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isAr ? 'قادمة' : 'Active',
                                        style: AppTypography.bodySecondary(
                                          color: _isUpcomingParcels ? Colors.white : AppColors.textPrimary,
                                        ).copyWith(fontWeight: _isUpcomingParcels ? FontWeight.w700 : FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isUpcomingParcels = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isUpcomingParcels ? AppColors.navy : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isAr ? 'سابقة' : 'Delivered',
                                        style: AppTypography.bodySecondary(
                                          color: !_isUpcomingParcels ? Colors.white : AppColors.textPrimary,
                                        ).copyWith(fontWeight: !_isUpcomingParcels ? FontWeight.w700 : FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Parcels List
                    Expanded(
                      child: _isUpcomingParcels
                          ? _buildUpcomingParcelsList(context, parcels, isAr, isWide: isWide)
                          : _buildPastParcelsList(context, isAr, isWide: isWide),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingParcelsList(BuildContext context, ParcelsProvider parcels, bool isAr, {bool isWide = false}) {
    final cards = parcels.parcels
        .map(
          (parcelItem) => _buildParcelCard(
            context: context,
            route: context.trRoute(parcelItem.route.split(' · ').first),
            descText: isAr
                ? '${parcelItem.description} · مع السائق ${parcelItem.driverName}'
                : '${parcelItem.description} · With driver ${parcelItem.driverName}',
            badgeText: isAr ? 'في الطريق' : 'In Transit',
            badgeType: BadgeType.confirmed,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParcelTrackingScreen(
                    parcel: parcelItem,
                  ),
                ),
              );
            },
            actionButton: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text(isAr ? 'محادثة الناقل' : 'Chat Carrier'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      driverName: parcelItem.driverName,
                      driverCar: isAr
                          ? 'توصيل طرد ${parcelItem.route}'
                          : 'Parcel: ${parcelItem.route}',
                      tripRoute: isAr
                          ? 'كود الاستلام: ${parcelItem.pickupOtp}'
                          : 'Pickup OTP: ${parcelItem.pickupOtp}',
                    ),
                  ),
                );
              },
            ),
          ),
        )
        .toList();

    return _buildResponsiveCardList(cards, isWide);
  }

  Widget _buildPastParcelsList(BuildContext context, bool isAr, {bool isWide = false}) {
    final cards = <Widget>[
      // Past Parcel 1: تم التسليم
      _buildParcelCard(
        context: context,
        route: context.trRoute('الإسكندرية ← كفر الشيخ'),
        descText: isAr ? 'ملابس · تم التسليم 28 أكتوبر' : 'Clothes · Delivered Oct 28',
        badgeText: isAr ? 'تم التسليم' : 'Delivered',
        badgeType: BadgeType.verified,
        actionButton: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          icon: const Icon(Icons.star_outline_rounded, size: 18),
          label: Text(isAr ? 'تقييم الشحن' : 'Rate Shipping', style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RateTripScreen(
                  driverName: 'أحمد علي',
                  route: context.trRoute('الإسكندرية ← كفر الشيخ'),
                  isParcel: true,
                ),
              ),
            );
          },
        ),
      ),
      // Past Parcel 2: متنازع عليه (Page 35)
      _buildParcelCard(
        context: context,
        route: context.trRoute('طنطا ← القاهرة'),
        descText: isAr ? 'هدية · 12 أكتوبر' : 'Gift · Oct 12',
        badgeText: isAr ? 'متنازع عليه' : 'Disputed',
        badgeType: BadgeType.rejected,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ParcelDisputeScreen(reportId: '#4821')),
          );
        },
      ),
    ];

    return _buildResponsiveCardList(cards, isWide);
  }

  Widget _buildParcelCard({
    required BuildContext context,
    required String route,
    required String descText,
    required String badgeText,
    required BadgeType badgeType,
    VoidCallback? onTap,
    Widget? actionButton,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                  child: Text(
                    route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 8),
                MashwarBadge(type: badgeType, customLabel: badgeText),
              ],
            ),
            const SizedBox(height: 6),
            Text(descText, style: AppTypography.bodySecondary()),
            if (actionButton != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: actionButton,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Upgraded Account Tab
  Widget _buildAccountTab(BuildContext context, AuthProvider auth, SettingsProvider settings) {
    final isAr = settings.isArabic;
    final user = auth.user;
    final isIdVerified = user.idVerificationStatus == IdVerificationStatus.verified;

    Widget buildGroup1(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isAr ? 'خدمات السائق والرحلات' : 'Driver & Trip Operations',
              style: AppTypography.title().copyWith(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              side: const BorderSide(color: AppColors.borderDisabled),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.alt_route_rounded,
                  title: isAr ? 'رحلاتي وطلباتي كسائق' : 'My Driver Rides & Requests',
                  trailingText: isAr ? 'إدارة' : 'Manage',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DriverRidesScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.airline_seat_recline_extra_rounded,
                  title: isAr ? 'توثيق السائق وعرض المقاعد' : 'Driver Onboarding & Verification',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DriverOnboardingScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.campaign_outlined,
                  title: isAr ? 'إعلاناتي وعروضي في اللوحة' : 'My Board Ads & Offers',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.directions_car_filled_outlined,
                  title: isAr ? 'بيانات سيارتي ورخص القيادة' : 'My Car & Driver Licenses',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildGroup2(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isAr ? 'الأمان والسلامة' : 'Safety & Security',
              style: AppTypography.title().copyWith(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              side: const BorderSide(color: AppColors.borderDisabled),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.fmd_good_outlined,
                  title: isAr ? 'تتبع الرحلة المباشر ومشاركة المسار' : 'Live Trip Tracking & Share',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LiveTripTrackingScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.emergency_outlined,
                  title: isAr ? 'جهات الطوارئ والأمان (SOS)' : 'Emergency Contacts & SOS',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.badge_outlined,
                  title: isAr ? 'توثيق بطاقة الرقم القومي' : 'National ID Verification',
                  badge: isIdVerified
                      ? MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'موثق' : 'Verified')
                      : MashwarBadge(type: BadgeType.pending, customLabel: isAr ? 'مطلوب' : 'Action Required'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IdVerificationScreen(isOnboarding: false)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildGroup3(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isAr ? 'الحساب والإعدادات' : 'Account & Preferences',
              style: AppTypography.title().copyWith(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              side: const BorderSide(color: AppColors.borderDisabled),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: isAr ? 'محفظة مشوار وطرق الدفع' : 'Wallet & Payment Methods',
                  trailingText: '${user.walletBalance.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: isAr ? 'مركز الإشعارات' : 'Notification Center',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.notifications_active_outlined,
                  title: isAr ? 'تنبيهات الخطوط والمشاوير' : 'Route Alerts',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: isAr ? 'إعدادات التطبيق واللغة' : 'App Settings & Language',
                  trailingText: isAr ? 'العربية' : 'English',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildGroup4(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isAr ? 'الدعم والشروط القانونية' : 'Support & Legal',
              style: AppTypography.title().copyWith(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              side: const BorderSide(color: AppColors.borderDisabled),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: isAr ? 'المساعدة والأسئلة الشائعة' : 'Help, Support & FAQs',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.gavel_outlined,
                  title: isAr ? 'الشروط القانونية وامتثال وزارة النقل' : 'Legal Terms & MoT Compliance',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LegalComplianceScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.person_remove_outlined,
                  title: isAr ? 'حذف الحساب نهائياً' : 'Delete Account Permanently',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildIdentitySummary(bool isWide) {
      final identityRow = Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0] : 'م',
                style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title().copyWith(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isIdVerified) const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20),
                  ],
                ),
                Text(user.phone, style: AppTypography.bodySecondary()),
                const SizedBox(height: 6),
                if (isIdVerified)
                  MashwarBadge(
                    type: BadgeType.verified,
                    customLabel: isAr ? 'موثق بالرقم القومي' : 'National ID Verified',
                  )
                else if (user.idVerificationStatus == IdVerificationStatus.underReview)
                  MashwarBadge(
                    type: BadgeType.pending,
                    customLabel: isAr ? 'الهوية قيد المراجعة' : 'ID Under Review',
                  )
                else
                  MashwarBadge(
                    type: BadgeType.rejected,
                    customLabel: isAr ? 'يرجى توثيق الهوية' : 'Verify National ID',
                  ),
                if (user.governorate != null || user.occupation != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (user.governorate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.navy),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  user.city != null ? '${user.governorate} · ${user.city}' : user.governorate!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (user.occupation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline_rounded, size: 12, color: AppColors.teal),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  user.occupation!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.teal),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );

      final statsRow = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildStatColumn('${user.completedRides}', isAr ? 'رحلة' : 'Rides')),
          _buildStatDivider(),
          Expanded(child: _buildStatColumn('${user.completedParcels}', isAr ? 'طرد' : 'Parcels')),
          _buildStatDivider(),
          Expanded(child: _buildStatColumn('${user.rating} ★', isAr ? 'تقييم' : 'Rating')),
          _buildStatDivider(),
          Expanded(child: _buildStatColumn('${user.walletBalance.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}', isAr ? 'المحفظة' : 'Wallet')),
        ],
      );

      return Container(
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isWide
            ? Row(
                children: [
                  Expanded(flex: 6, child: identityRow),
                  Container(
                    width: 1,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: AppColors.borderDisabled,
                  ),
                  Expanded(flex: 5, child: statsRow),
                ],
              )
            : Column(
                children: [
                  identityRow,
                  const SizedBox(height: AppDimens.space16),
                  const Divider(height: 1, color: AppColors.borderDisabled),
                  const SizedBox(height: AppDimens.space12),
                  statsRow,
                ],
              ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'حسابي' : 'Account', style: AppTypography.title()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.navy),
            tooltip: isAr ? 'إعدادات التطبيق' : 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: AppDimens.space16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildIdentitySummary(isWide),
                      const SizedBox(height: AppDimens.space20),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildGroup1(context),
                                  const SizedBox(height: AppDimens.space20),
                                  buildGroup3(context),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimens.space20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildGroup2(context),
                                  const SizedBox(height: AppDimens.space20),
                                  buildGroup4(context),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        buildGroup1(context),
                        const SizedBox(height: AppDimens.space16),
                        buildGroup2(context),
                        const SizedBox(height: AppDimens.space16),
                        buildGroup3(context),
                        const SizedBox(height: AppDimens.space16),
                        buildGroup4(context),
                      ],
                      const SizedBox(height: AppDimens.space24),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
                          child: MashwarButton(
                            text: isAr ? 'تسجيل الخروج' : 'Log Out',
                            variant: MashwarButtonVariant.danger,
                            onPressed: () {
                              auth.logout();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.space24),
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

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTypography.title().copyWith(fontSize: 15, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.label(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 24, color: AppColors.borderDisabled);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
    Widget? badge,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F3F4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.navy, size: 18),
      ),
      title: Text(title, style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) badge,
          if (trailingText != null)
            Text(trailingText, style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Color(0xFF8E8E93)),
        ],
      ),
      onTap: onTap,
    );
  }
}
