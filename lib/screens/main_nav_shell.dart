import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_typography.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/mashwar_animations.dart';
import '../core/widgets/mashwar_badge.dart';
import '../core/widgets/mashwar_button.dart';
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
import 'parcel/parcel_tracking_screen.dart';
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
import 'escrow/service_escrow_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  // Segment state for Orders / Requests Tab
  bool _isActiveOrders = true;
  int _ordersFilterIndex = 0; // 0: All, 1: Mobility/Travel, 2: Errands, 3: Logistics/Cargo
  bool _messagesUnreadOnly = false;
  final TextEditingController _messagesSearchController = TextEditingController();

  Widget _buildNavIconPill(IconData icon, {bool active = false}) {
    if (!active) return Icon(icon, size: 22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: AppColors.navy),
    );
  }

  @override
  void dispose() {
    _messagesSearchController.dispose();
    super.dispose();
  }

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
      _buildMyOrdersTab(context, rides, parcels, isAr),
      _buildMessagesTab(context, isAr),
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
                      icon: const Icon(Icons.explore_outlined),
                      selectedIcon: const Icon(Icons.explore_rounded),
                      label: Text(isAr ? 'اللوحة' : 'Board'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.assignment_outlined),
                      selectedIcon: const Icon(Icons.assignment_rounded),
                      label: Text(isAr ? 'طلباتي' : 'My Requests'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: const Icon(Icons.chat_bubble_rounded),
                      label: Text(isAr ? 'الرسائل' : 'Messages'),
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
              border: const Border(
                top: BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedLabelStyle: AppTypography.label().copyWith(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: AppTypography.label().copyWith(fontWeight: FontWeight.w600, fontSize: 11),
              selectedItemColor: AppColors.navy,
              unselectedItemColor: const Color(0xFF8E8E93),
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIconPill(Icons.home_outlined),
                  activeIcon: _buildNavIconPill(Icons.home_rounded, active: true),
                  label: isAr ? 'الرئيسية' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIconPill(Icons.explore_outlined),
                  activeIcon: _buildNavIconPill(Icons.explore_rounded, active: true),
                  label: isAr ? 'اللوحة' : 'Board',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIconPill(Icons.assignment_outlined),
                  activeIcon: _buildNavIconPill(Icons.assignment_rounded, active: true),
                  label: isAr ? 'طلباتي' : 'My Requests',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIconPill(Icons.chat_bubble_outline_rounded),
                  activeIcon: _buildNavIconPill(Icons.chat_bubble_rounded, active: true),
                  label: isAr ? 'الرسائل' : 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIconPill(Icons.person_outline_rounded),
                  activeIcon: _buildNavIconPill(Icons.person_rounded, active: true),
                  label: isAr ? 'حسابي' : 'Account',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // UNIFIED ACTIVITY TAB: طلباتي (My Requests)
  // ==========================================
  Widget _buildMyOrdersTab(
    BuildContext context,
    RidesProvider rides,
    ParcelsProvider parcels,
    bool isAr,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MashwarPinIcon(size: 18),
            const SizedBox(width: 6),
            Text(isAr ? 'طلباتي' : 'My Requests', style: AppTypography.title()),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isAr
                      ? '${rides.bookedRides.length + parcels.parcels.length} نشط'
                      : '${rides.bookedRides.length + parcels.parcels.length} Active',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uber-style Segment Switch: قيد التنفيذ vs المكتملة
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppDimens.space16, 12, AppDimens.space16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isActiveOrders = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isActiveOrders ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isActiveOrders
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'الطلبات النشطة والجارية' : 'Active Requests',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySecondary(
                                        color: _isActiveOrders ? AppColors.navy : AppColors.textSecondary,
                                      ).copyWith(
                                        fontWeight: _isActiveOrders ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isActiveOrders = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isActiveOrders ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isActiveOrders
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'المكتملة والسابقة' : 'Completed / History',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySecondary(
                                        color: !_isActiveOrders ? AppColors.navy : AppColors.textSecondary,
                                      ).copyWith(
                                        fontWeight: !_isActiveOrders ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Illustrated filter chips for service categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 4),
                      child: Row(
                        children: [
                          _buildOrderFilterChip(0, isAr ? 'الكل' : 'All', icon: Icons.apps_rounded),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(
                            1,
                            isAr ? 'سفر وانتقال' : 'Mobility & Travel',
                            assetPath: 'assets/images/service_ride.jpg',
                            icon: Icons.directions_car_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(
                            2,
                            isAr ? 'شراء طلبات ومصالح' : 'Errand & Shopping',
                            assetPath: 'assets/images/service_errand.jpg',
                            icon: Icons.shopping_bag_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(
                            3,
                            isAr ? 'لوجستيات وبضائع' : 'Store Logistics',
                            assetPath: 'assets/images/service_cargo.jpg',
                            icon: Icons.local_shipping_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(
                            4,
                            isAr ? 'شحن أمانات' : 'Parcel Delivery',
                            assetPath: 'assets/images/service_parcel.jpg',
                            icon: Icons.inventory_2_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Orders list
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        child: KeyedSubtree(
                          key: ValueKey('${_isActiveOrders}_$_ordersFilterIndex'),
                          child: _isActiveOrders
                              ? _buildActiveOrdersList(context, rides, parcels, isAr, isWide: isWide)
                              : _buildPastOrdersList(context, isAr, isWide: isWide),
                        ),
                      ),
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

  Widget _buildOrderFilterChip(
    int index,
    String label, {
    String? assetPath,
    IconData icon = Icons.apps_rounded,
  }) {
    final isSelected = _ordersFilterIndex == index;
    return MashwarPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _ordersFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetPath != null)
              Container(
                width: 22,
                height: 22,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: MashwarAssetArt(
                  assetPath: assetPath,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(4),
                  fallbackIcon: icon,
                ),
              )
            else
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.gold : AppColors.navy,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.navy,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersList(
    BuildContext context,
    RidesProvider rides,
    ParcelsProvider parcels,
    bool isAr, {
    bool isWide = false,
  }) {
    final cards = <Widget>[];

    // Category 1: Mobility & Inter-city Travel (Filter 0 or 1)
    if (_ordersFilterIndex == 0 || _ordersFilterIndex == 1) {
      // Dynamic booked rides from provider
      for (final bookedRide in rides.bookedRides) {
        cards.add(
          _buildUnifiedOrderCard(
            context: context,
            categoryTag: isAr ? 'سفر تشاركي' : 'Carpooling',
            categoryColor: AppColors.navy,
            route: '${bookedRide.fromCity} ← ${bookedRide.toCity}',
            description: '${bookedRide.departureDate}، ${bookedRide.departureTime} · السائق: ${bookedRide.driverName}',
            badgeText: isAr ? 'حجز مؤكد' : 'Confirmed',
            badgeType: BadgeType.confirmed,
            otpCode: '4291',
            isAr: isAr,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ActiveTripScreen(ride: bookedRide)),
              );
            },
            actionButtons: [
              OutlinedButton.icon(
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
                        driverName: bookedRide.driverName,
                        driverCar: bookedRide.driverCar,
                        tripRoute: '${bookedRide.fromCity} ← ${bookedRide.toCity}',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.navigation_outlined, size: 16),
                label: Text(isAr ? 'تفاصيل المشوار' : 'Trip Details'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ActiveTripScreen(ride: bookedRide)),
                  );
                },
              ),
            ],
          ),
        );
      }

      // Default Active Inter-city Ride Card
      cards.add(
        _buildUnifiedOrderCard(
          context: context,
          categoryTag: isAr ? 'سفر بين المناطق' : 'Inter-city Travel',
          categoryColor: AppColors.navy,
          route: isAr ? 'الدوحة ← الخور' : 'Doha → Al Khor',
          description: isAr
              ? 'الجمعة 6 نوفمبر، 7:30 ص · الكابتن: جاسم الكواري (تويوتا كامري 2024 مكيفة)'
              : 'Fri Nov 6, 7:30 AM · Captain: Jassim Al-Kuwari (Toyota Camry)',
          badgeText: isAr ? 'مؤكد' : 'Confirmed',
          badgeType: BadgeType.confirmed,
          otpCode: '5912',
          isAr: isAr,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ActiveTripScreen(ride: MockData.initialRides[0])),
            );
          },
          actionButtons: [
            OutlinedButton.icon(
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
                    builder: (_) => const ChatScreen(
                      driverName: 'جاسم الكواري',
                      driverCar: 'تويوتا كامري، أبيض لؤلؤي (قطر 482910)',
                      tripRoute: 'الدوحة ← الخور',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: Text(isAr ? 'تفاصيل المشوار' : 'Trip Details'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ActiveTripScreen(ride: MockData.initialRides[0])),
                );
              },
            ),
          ],
        ),
      );
    }

    // Category 2: Errand, Site Supply & Shopping Service (Filter 0 or 2)
    if (_ordersFilterIndex == 0 || _ordersFilterIndex == 2) {
      // Lusail Engineer Worksite Supply (Bilateral Escrow Highlight)
      cards.add(
        _buildUnifiedOrderCard(
          context: context,
          categoryTag: isAr ? 'توريد موقع هندسي (Escrow)' : 'Site Supply (Escrow)',
          categoryColor: AppColors.qatarMaroon,
          route: isAr ? 'المنطقة الصناعية ← لوسيل' : 'Industrial Area → Lusail',
          description: isAr
              ? 'شراء قواطع كهربائية من شارع 10 · أتعاب 45 ر.ق + فاتورة بالضمان 180 ر.ق'
              : 'Electrical breakers from St 10 · 45 QAR fee + 180 QAR Escrow receipt cap',
          badgeText: isAr ? 'مراجعة الفاتورة' : 'Receipt Check',
          badgeType: BadgeType.underReview,
          otpCode: '4829',
          isAr: isAr,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceEscrowScreen(ad: MockData.initialBoardAds.first),
              ),
            );
          },
          actionButtons: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.qatarMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.verified_user_rounded, size: 16),
              label: Text(isAr ? 'إدارة الضمان وكود OTP' : 'Escrow & OTP'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServiceEscrowScreen(ad: MockData.initialBoardAds.first),
                  ),
                );
              },
            ),
          ],
        ),
      );

      // Shopping & Parts Delivery Order
      cards.add(
        _buildUnifiedOrderCard(
          context: context,
          categoryTag: isAr ? 'شراء طلبات ومستلزمات' : 'Shopping & Errands',
          categoryColor: const Color(0xFF0D9488),
          route: isAr ? 'المنطقة الصناعية ← دخان' : 'Industrial Area → Dukhan',
          description: isAr
              ? 'شراء قطع غيار وفلاتر أصلية للسيارات وإحضارها مع مسافر · المنفذ: راشد الدوسري'
              : 'Original spare parts & filters from Industrial Area · Courier: Rashed Al-Dosari',
          badgeText: isAr ? 'قيد الشراء' : 'Purchasing',
          badgeType: BadgeType.underReview,
          otpCode: '6284',
          isAr: isAr,
          actionButtons: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text(isAr ? 'محادثة المشتري/المنفذ' : 'Chat Courier'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      driverName: 'راشد الدوسري',
                      driverCar: isAr ? 'خدمة شراء مستلزمات وتوصيل' : 'Shopping & Errand Courier',
                      tripRoute: isAr ? 'المنطقة الصناعية ← دخان' : 'Industrial Area → Dukhan',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      // Official Documents Errand
      cards.add(
        _buildUnifiedOrderCard(
          context: context,
          categoryTag: isAr ? 'إنجاز معاملات رسمية' : 'Official Errand',
          categoryColor: const Color(0xFFD97706),
          route: isAr ? 'المدينة التعليمية ← الخور' : 'Education City → Al Khor',
          description: isAr
              ? 'استلام شهادة تخرج ومستندات رسمية من المدينة التعليمية وتسليمها في الخور'
              : 'Official certificate & documents pickup from Education City',
          badgeText: isAr ? 'قيد التنفيذ' : 'In Progress',
          badgeType: BadgeType.underReview,
          otpCode: '4821',
          isAr: isAr,
          actionButtons: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text(isAr ? 'محادثة المنفذ' : 'Chat Provider'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      driverName: 'فهد المري',
                      driverCar: isAr ? 'خدمة إنجاز معاملات وأوراق رسمية' : 'Official Documents Courier',
                      tripRoute: isAr ? 'المدينة التعليمية ← الخور' : 'Education City → Al Khor',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Category 3: Logistics & Merchant Supplies (Filter 0 or 3)
    if (_ordersFilterIndex == 0 || _ordersFilterIndex == 3) {
      cards.add(
        _buildUnifiedOrderCard(
          context: context,
          categoryTag: isAr ? 'لوجستيات وتوريد بضائع' : 'Commercial Cargo',
          categoryColor: const Color(0xFF2563EB),
          route: isAr ? 'المنطقة الصناعية ← مسيعيد' : 'Industrial Area → Mesaieed',
          description: isAr
              ? 'توريد 5 كراتين مستلزمات لمحل تجاري في مسيعيد · الناقل: ناصر المهندي'
              : 'Store stock & supplies (5 cartons) · Carrier: Nasser Al-Muhannadi',
          badgeText: isAr ? 'في الطريق' : 'In Transit',
          badgeType: BadgeType.confirmed,
          otpCode: '9314',
          isAr: isAr,
          actionButtons: [
            OutlinedButton.icon(
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
                      driverName: 'ناصر المهندي',
                      driverCar: isAr ? 'نقل وتوريد بضائع تجارية' : 'Commercial Cargo Transport',
                      tripRoute: isAr ? 'المنطقة الصناعية ← مسيعيد' : 'Industrial Area → Mesaieed',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Category 4: Crowd-shipping & Parcels (Filter 0 or 4)
    if (_ordersFilterIndex == 0 || _ordersFilterIndex == 4) {
      // Parcels from ParcelsProvider
      for (final p in parcels.parcels) {
        cards.add(
          _buildUnifiedOrderCard(
            context: context,
            categoryTag: isAr ? 'شحن أمانات وطرود' : 'Parcel Delivery',
            categoryColor: AppColors.teal,
            route: p.route.split(' · ').first,
            description: '${p.description} · مع الناقل ${p.driverName}',
            badgeText: isAr ? 'في الطريق' : 'In Transit',
            badgeType: BadgeType.confirmed,
            otpCode: p.pickupOtp,
            isAr: isAr,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ParcelTrackingScreen(parcel: p)),
              );
            },
            actionButtons: [
              OutlinedButton.icon(
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
                        driverName: p.driverName,
                        driverCar: 'توصيل أمانة: ${p.route}',
                        tripRoute: 'كود الاستلام: ${p.pickupOtp}',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.track_changes_rounded, size: 16),
                label: Text(isAr ? 'تتبع الشحنة' : 'Track Parcel'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ParcelTrackingScreen(parcel: p)),
                  );
                },
              ),
            ],
          ),
        );
      }
    }

    return _buildResponsiveCardList(cards, isWide);
  }

  Widget _buildPastOrdersList(BuildContext context, bool isAr, {bool isWide = false}) {
    final cards = <Widget>[
      // Completed Trip
      _buildUnifiedOrderCard(
        context: context,
        categoryTag: isAr ? 'سفر تشاركي' : 'Carpooling',
        categoryColor: AppColors.navy,
        route: isAr ? 'الدوحة ← الخور' : 'Doha → Al Khor',
        description: isAr ? 'الأحد 25 أكتوبر · الكابتن: آمنة السويدي (لكزس ES350)' : 'Sun Oct 25 · Captain: Amna Al-Suwaidi',
        badgeText: isAr ? 'مكتمل' : 'Completed',
        badgeType: BadgeType.verified,
        isAr: isAr,
        actionButtons: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            icon: const Icon(Icons.star_outline_rounded, size: 18),
            label: Text(
              isAr ? 'تقييم المشوار' : 'Rate Trip',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RateTripScreen(
                    driverName: 'آمنة السويدي',
                    route: 'الدوحة ← الخور',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Completed Official Errand
      _buildUnifiedOrderCard(
        context: context,
        categoryTag: isAr ? 'إنجاز معاملة رسمية' : 'Official Errand',
        categoryColor: const Color(0xFFD97706),
        route: isAr ? 'مشيرب، الدوحة ← الوكرة' : 'Msheireb, Doha → Al Wakrah',
        description: isAr ? 'تصديق مستندات رسمية في الدوحة · تم الإنجاز 20 أكتوبر' : 'Official documents attestation in Doha · Done Oct 20',
        badgeText: isAr ? 'مكتمل' : 'Completed',
        badgeType: BadgeType.verified,
        isAr: isAr,
        actionButtons: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            icon: const Icon(Icons.star_outline_rounded, size: 18),
            label: Text(
              isAr ? 'تقييم الخدمة' : 'Rate Service',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RateTripScreen(
                    driverName: 'تميم الهاجري',
                    route: 'مشيرب، الدوحة ← الوكرة',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Completed Parcel
      _buildUnifiedOrderCard(
        context: context,
        categoryTag: isAr ? 'شحن أمانات وطرود' : 'Parcel Delivery',
        categoryColor: AppColors.teal,
        route: isAr ? 'لوسيل ← مطار حمد الدولي' : 'Lusail → Hamad Int\'l Airport',
        description: isAr ? 'طرد مستندات وأمانات · تم التسليم بكود OTP' : 'Parcel · Delivered via OTP confirmation',
        badgeText: isAr ? 'تم التسليم' : 'Delivered',
        badgeType: BadgeType.verified,
        isAr: isAr,
        actionButtons: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            icon: const Icon(Icons.star_outline_rounded, size: 18),
            label: Text(
              isAr ? 'تقييم الشحن' : 'Rate Shipping',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RateTripScreen(
                    driverName: 'أحمد العطية',
                    route: 'لوسيل ← مطار حمد الدولي',
                    isParcel: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Disputed/Cancelled
      _buildUnifiedOrderCard(
        context: context,
        categoryTag: isAr ? 'لوجستيات وتوريد' : 'Logistics',
        categoryColor: const Color(0xFF2563EB),
        route: isAr ? 'الريان ← أم صلال' : 'Al Rayyan → Umm Salal',
        description: isAr ? 'طلب توريد ملغى لعدم مطابقة الشروط' : 'Logistics request cancelled',
        badgeText: isAr ? 'ملغى' : 'Cancelled',
        badgeType: BadgeType.rejected,
        isAr: isAr,
      ),
    ];

    return _buildResponsiveCardList(cards, isWide);
  }

  Widget _buildResponsiveCardList(List<Widget> cards, bool isWide) {
    if (!isWide) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space12),
        itemBuilder: (_, i) => cards[i],
      );
    }
    final pairCount = (cards.length / 2).ceil();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
      itemCount: pairCount,
      itemBuilder: (_, rowIdx) {
        final first = rowIdx * 2;
        final second = first + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.space12),
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

  Widget _buildUnifiedOrderCard({
    required BuildContext context,
    required String categoryTag,
    required Color categoryColor,
    required String route,
    required String description,
    required String badgeText,
    required BadgeType badgeType,
    String? otpCode,
    required bool isAr,
    VoidCallback? onTap,
    List<Widget>? actionButtons,
  }) {
    final routeParts = route.contains('←')
        ? route.split('←')
        : route.contains('→')
            ? route.split('→')
            : [route, ''];
    final fromCity = routeParts.first.trim();
    final toCity = routeParts.length > 1 ? routeParts.sublist(1).join(' ← ').trim() : '';

    return MashwarFadeSlideIn(
      duration: const Duration(milliseconds: 260),
      offsetY: 10,
      child: MashwarPressable(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.9),
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
              // Top Row: Category pill & Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: categoryColor).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: MashwarBadge(type: badgeType, customLabel: badgeText),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Visual Route Timeline
              if (toCity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MashwarRouteTimeline(
                    from: fromCity,
                    to: toCity,
                    compact: true,
                  ),
                )
              else
                Text(
                  route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title().copyWith(fontSize: 17),
                ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: AppTypography.bodySecondary().copyWith(fontSize: 13),
              ),

              // OTP Guarantee Box if active
              if (otpCode != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.teal),
                      Text(
                        isAr ? 'كود أمان التسليم:' : 'Security OTP:',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          otpCode,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Actions row
              if (actionButtons != null && actionButtons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actionButtons,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DIRECT MESSAGING TAB: الرسائل (Messages)
  // ==========================================
  Widget _buildMessagesTab(BuildContext context, bool isAr) {
    final List<Map<String, dynamic>> allChats = [
      {
        'id': 'chat_1',
        'name': 'جاسم الكواري',
        'verified': true,
        'tag': isAr ? 'سفر تشاركي' : 'Carpooling',
        'car': 'تويوتا كامري، أبيض لؤلؤي (قطر 482910)',
        'route': isAr ? 'الدوحة ← الخور' : 'Doha → Al Khor',
        'lastMsg': isAr
            ? 'حياك الله، أنا واقف عند المقهى عند بوابة محطة مشيرب. سيارة بيضاء.'
            : 'Hello! I am parked near the coffee shop at Msheireb Station entrance. White car.',
        'time': '7:22 ص',
        'unread': 1,
      },
      {
        'id': 'chat_2',
        'name': 'فهد المري',
        'verified': true,
        'tag': isAr ? 'معاملات رسمية' : 'Official Errand',
        'car': isAr ? 'استلام شهادة ومستندات رسمية' : 'Document Pickup Service',
        'route': isAr ? 'المدينة التعليمية ← الخور' : 'Education City → Al Khor',
        'lastMsg': isAr
            ? 'استلمت الظرف والمستندات الرسمية من المدينة التعليمية ومتوجه للخور الآن.'
            : 'I collected the official envelope from Education City and am heading to Al Khor now.',
        'time': '11:15 ص',
        'unread': 2,
      },
      {
        'id': 'chat_3',
        'name': 'ناصر المهندي',
        'verified': true,
        'tag': isAr ? 'لوجستيات وتوريد' : 'Logistics',
        'car': isAr ? 'نقل وتوريد بضائع ومستلزمات' : 'Goods & Commercial Cargo',
        'route': isAr ? 'المنطقة الصناعية ← مسيعيد' : 'Industrial Area → Mesaieed',
        'lastMsg': isAr
            ? 'وصلت نقطة التسليم أمام المحل في مسيعيد وبانتظار رمز التحقق OTP.'
            : 'Arrived at the shop drop-off in Mesaieed, waiting for OTP code.',
        'time': '1:45 م',
        'unread': 0,
      },
      {
        'id': 'chat_4',
        'name': 'سلمان النعيمي',
        'verified': true,
        'tag': isAr ? 'شحن أمانة وطرود' : 'Parcel Delivery',
        'car': isAr ? 'طرد إلكترونيات وأمانات' : 'Parcel Delivery Service',
        'route': isAr ? 'الوكرة ← لوسيل' : 'Al Wakrah → Lusail',
        'lastMsg': isAr
            ? 'تم تأكيد رمز الاستلام بنجاح، شكراً لك وتشرفت بخدمتك.'
            : 'Delivery OTP confirmed successfully. Thank you!',
        'time': isAr ? 'أمس' : 'Yesterday',
        'unread': 0,
      },
    ];

    final query = _messagesSearchController.text.trim().toLowerCase();
    final unreadTotal = allChats.where((c) => ((c['unread'] as int?) ?? 0) > 0).length;
    final filteredChats = allChats.where((chat) {
      if (_messagesUnreadOnly && ((chat['unread'] as int?) ?? 0) == 0) {
        return false;
      }
      if (query.isEmpty) return true;
      final name = (chat['name'] as String).toLowerCase();
      final lastMsg = (chat['lastMsg'] as String).toLowerCase();
      final route = (chat['route'] as String).toLowerCase();
      return name.contains(query) || lastMsg.contains(query) || route.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MashwarPinIcon(size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isAr ? 'الرسائل والمحادثات' : 'Messages',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(),
              ),
            ),
          ],
        ),
        actions: [
          if (unreadTotal > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isAr ? '$unreadTotal غير مقروء' : '$unreadTotal Unread',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1000 : 720),
                child: Column(
                  children: [
                    // Uber-style Search Capsule + Unread filter pills
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(AppDimens.space16, 10, AppDimens.space16, 10),
                      child: Column(
                        children: [
                          TextField(
                            controller: _messagesSearchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: isAr ? 'بحث في الرسائل، الأسماء أو الخطوط...' : 'Search messages, names & routes...',
                              hintStyle: AppTypography.bodySecondary(
                                color: AppColors.textSecondary.withValues(alpha: 0.72),
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy, size: 20),
                              suffixIcon: _messagesSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _messagesSearchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF3F4F6),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => setState(() => _messagesUnreadOnly = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: !_messagesUnreadOnly ? AppColors.navy : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isAr ? 'كل المحادثات' : 'All Chats',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: !_messagesUnreadOnly ? Colors.white : AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => setState(() => _messagesUnreadOnly = true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _messagesUnreadOnly ? AppColors.teal : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isAr ? 'غير مقروءة ($unreadTotal)' : 'Unread ($unreadTotal)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _messagesUnreadOnly ? Colors.white : AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: Color(0xFFEDF2F7)),

                    // Chat threads list
                    Expanded(
                      child: filteredChats.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFE5E7EB)),
                                      ),
                                      child: const Icon(Icons.forum_outlined, size: 46, color: AppColors.navy),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAr ? 'لا توجد محادثات مطابقة' : 'No matching chats found',
                                      style: AppTypography.bodySecondary(),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 12),
                              itemCount: filteredChats.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                final unread = (chat['unread'] as int?) ?? 0;
                                return MashwarFadeSlideIn(
                                  duration: Duration(milliseconds: 220 + (index.clamp(0, 4) * 35)),
                                  offsetY: 10,
                                  child: MashwarPressable(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            driverName: chat['name'] as String,
                                            driverCar: chat['car'] as String,
                                            tripRoute: chat['route'] as String,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: unread > 0 ? AppColors.teal.withValues(alpha: 0.45) : const Color(0xFFE5E5EA),
                                          width: unread > 0 ? 1.2 : 0.9,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.navy.withValues(alpha: 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Avatar with gold/navy ring & verification badge
                                          Stack(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: unread > 0 ? AppColors.gold : AppColors.navy.withValues(alpha: 0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    (chat['name'] as String).substring(0, 1),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.navy,
                                                      fontSize: 18,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                right: isAr ? null : 0,
                                                left: isAr ? 0 : null,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.verified_rounded,
                                                    size: 14,
                                                    color: AppColors.teal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),

                                          // Name, tags, and message snippet
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        chat['name'] as String,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: AppTypography.title().copyWith(fontSize: 15.5),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      chat['time'] as String,
                                                      style: AppTypography.bodySmall(
                                                        color: unread > 0 ? AppColors.teal : AppColors.textSecondary,
                                                      ).copyWith(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),

                                                // Category tag & route
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.sand,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        chat['tag'] as String,
                                                        style: const TextStyle(
                                                          fontSize: 10.5,
                                                          color: AppColors.navy,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '· ${chat['route']}',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),

                                                // Message text
                                                Text(
                                                  chat['lastMsg'] as String,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.bodySecondary(
                                                    color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                                  ).copyWith(
                                                    fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Unread Badge
                                          if (unread > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: AppColors.teal,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$unread',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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

  // Upgraded Uber & Careem Account Hub Tab
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
                  iconBg: const Color(0xFFE8EEF5),
                  iconColor: AppColors.navy,
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
                  iconBg: const Color(0xFFE8EEF5),
                  iconColor: AppColors.navy,
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
                  iconBg: AppColors.goldSurface,
                  iconColor: const Color(0xFF9A5B00),
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
                  iconBg: const Color(0xFFE8EEF5),
                  iconColor: AppColors.navy,
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
                  icon: Icons.verified_user_rounded,
                  iconBg: AppColors.escrowSurface,
                  iconColor: AppColors.escrowGreen,
                  title: isAr ? 'مركز الضمان المالي وحماية الطرفين (Escrow)' : 'Bilateral Escrow & Dispute Center',
                  trailingText: isAr ? 'نشط' : 'Active',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ServiceEscrowScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.fmd_good_outlined,
                  iconBg: AppColors.tealSurface,
                  iconColor: AppColors.teal,
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
                  iconBg: AppColors.dangerBg,
                  iconColor: AppColors.danger,
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
                  iconBg: AppColors.tealSurface,
                  iconColor: AppColors.teal,
                  title: isAr ? 'توثيق البطاقة الشخصية القطرية (QID)' : 'Qatar ID (QID) Verification',
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
                  iconBg: AppColors.infoBg,
                  iconColor: AppColors.info,
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
                  iconBg: AppColors.tealSurface,
                  iconColor: AppColors.teal,
                  title: isAr ? 'محفظة مشوار وطرق الدفع' : 'Wallet & Payment Methods',
                  trailingText: '${user.walletBalance.toStringAsFixed(0)} ${isAr ? 'ر.ق' : 'QAR'}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),
                _buildMenuItem(
                  icon: Icons.notifications_none_rounded,
                  iconBg: AppColors.goldSurface,
                  iconColor: const Color(0xFF9A5B00),
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
                  iconBg: AppColors.infoBg,
                  iconColor: AppColors.info,
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
                  iconBg: AppColors.chipInactiveBg,
                  iconColor: AppColors.navy,
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
                  iconBg: AppColors.infoBg,
                  iconColor: AppColors.info,
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
                  iconBg: AppColors.chipInactiveBg,
                  iconColor: AppColors.navy,
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
                  iconBg: AppColors.dangerBg,
                  iconColor: AppColors.danger,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        style: AppTypography.title().copyWith(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isIdVerified) const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.phone, style: AppTypography.bodySecondary()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            '${user.rating}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isIdVerified)
                      MashwarBadge(
                        type: BadgeType.verified,
                        customLabel: isAr ? 'موثق بالبطاقة القطرية' : 'Qatar ID Verified',
                      )
                    else if (user.idVerificationStatus == IdVerificationStatus.underReview)
                      MashwarBadge(
                        type: BadgeType.pending,
                        customLabel: isAr ? 'الهوية قيد المراجعة' : 'ID Under Review',
                      )
                    else
                      MashwarBadge(
                        type: BadgeType.rejected,
                        customLabel: isAr ? 'يرجى توثيق البطاقة القطرية' : 'Verify Qatar ID',
                      ),
                  ],
                ),
                if (user.governorate != null || user.occupation != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (user.governorate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.navy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (user.occupation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.teal),
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
          const SizedBox(width: 12),
          // Uber-style trailing interactive profile avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navy.withValues(alpha: 0.14), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'م',
                      style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 26),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
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
          Expanded(child: _buildStatColumn('${user.walletBalance.toStringAsFixed(0)} ${isAr ? 'ر.ق' : 'QAR'}', isAr ? 'المحفظة' : 'Wallet')),
        ],
      );

      return MashwarFadeSlideIn(
        duration: const Duration(milliseconds: 300),
        offsetY: 10,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.9),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 6, child: identityRow),
                    Container(
                      width: 1,
                      height: 70,
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
        ),
      );
    }

    Widget buildQuickBentoRow(BuildContext context) {
      return MashwarFadeSlideIn(
        duration: const Duration(milliseconds: 340),
        offsetY: 12,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildAccountBentoTile(
                  icon: Icons.support_agent_rounded,
                  iconBg: const Color(0xFFE8EEF5),
                  iconColor: AppColors.navy,
                  title: isAr ? 'المساعدة' : 'Help',
                  subtitle: isAr ? 'دعم ٢٤/٧' : '24/7 Support',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAccountBentoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: AppColors.tealSurface,
                  iconColor: AppColors.teal,
                  title: isAr ? 'المحفظة' : 'Wallet',
                  subtitle: '${user.walletBalance.toStringAsFixed(0)} ${isAr ? 'ر.ق' : 'QAR'}',
                  subtitleColor: AppColors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAccountBentoTile(
                  icon: Icons.campaign_rounded,
                  iconBg: AppColors.goldSurface,
                  iconColor: AppColors.navy,
                  title: isAr ? 'إعلاناتي' : 'My Ads',
                  subtitle: isAr ? 'العروض والطلبات' : 'Ads & Offers',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildDriverPartnerCard(BuildContext context) {
      return MashwarFadeSlideIn(
        duration: const Duration(milliseconds: 380),
        offsetY: 12,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [AppColors.navy, Color(0xFF173D61)],
            ),
            borderRadius: BorderRadius.circular(18),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAr ? 'شركاء مشوار في قطر' : 'MASHWAR Qatar Providers',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? 'حوّل مشاويرك وخدماتك لدخل إضافي مضمون' : 'Earn from routes, errands & seats',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAr
                          ? 'نفّذ طلبات الشراء، توريد المواقع، أو شارك مقاعدك بضمان مشوار Escrow'
                          : 'Fulfill shopping errands, site supplies or share seats safely with Escrow',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.navy,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            isAr ? 'توثيق كمقدّم خدمة' : 'Become a Provider',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DriverRidesScreen()),
                            );
                          },
                          child: Text(
                            isAr ? 'خدماتي ورحلاتي' : 'My Services',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MashwarAssetArt(
                assetPath: 'assets/images/hero_qatar_services.jpg',
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(14),
                fallbackIcon: Icons.handshake_rounded,
                fallbackBg: Colors.white.withValues(alpha: 0.12),
                fallbackColor: AppColors.gold,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
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
                      const SizedBox(height: 14),
                      buildQuickBentoRow(context),
                      const SizedBox(height: 14),
                      buildDriverPartnerCard(context),
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
                      const SizedBox(height: AppDimens.space20),
                      const Center(
                        child: Opacity(
                          opacity: 0.78,
                          child: BrandLogo(fontSize: 16, showEnglish: true),
                        ),
                      ),
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

  Widget _buildAccountBentoTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color subtitleColor = AppColors.textSecondary,
    required VoidCallback onTap,
  }) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
                fontFamily: 'Cairo',
              ),
            ),
          ],
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
    Color iconBg = AppColors.chipInactiveBg,
    Color iconColor = AppColors.navy,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(title, style: AppTypography.body().copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) badge,
          if (trailingText != null)
            Text(trailingText, style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
