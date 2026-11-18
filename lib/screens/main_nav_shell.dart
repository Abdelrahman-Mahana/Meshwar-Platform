import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_typography.dart';
import '../core/widgets/brand_logo.dart';
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
  final TextEditingController _messagesSearchController = TextEditingController();

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
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: isAr ? 'الرئيسية' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.explore_outlined),
                  activeIcon: const Icon(Icons.explore_rounded),
                  label: isAr ? 'اللوحة' : 'Board',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.assignment_outlined),
                  activeIcon: const Icon(Icons.assignment_rounded),
                  label: isAr ? 'طلباتي' : 'My Requests',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: const Icon(Icons.chat_bubble_rounded),
                  label: isAr ? 'الرسائل' : 'Messages',
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'طلباتي' : 'My Requests', style: AppTypography.title()),
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
                    // Segment Switch: قيد التنفيذ vs المكتملة
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppDimens.space16, 12, AppDimens.space16, 6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBEBF0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isActiveOrders = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isActiveOrders ? AppColors.navy : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'الطلبات النشطة والجارية' : 'Active Requests',
                                      style: AppTypography.bodySecondary(
                                        color: _isActiveOrders ? Colors.white : AppColors.textPrimary,
                                      ).copyWith(fontWeight: _isActiveOrders ? FontWeight.w700 : FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isActiveOrders = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isActiveOrders ? AppColors.navy : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'المكتملة والسابقة' : 'Completed / History',
                                      style: AppTypography.bodySecondary(
                                        color: !_isActiveOrders ? Colors.white : AppColors.textPrimary,
                                      ).copyWith(fontWeight: !_isActiveOrders ? FontWeight.w700 : FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Filter chips for service categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 4),
                      child: Row(
                        children: [
                          _buildOrderFilterChip(0, isAr ? 'الكل' : 'All'),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(1, isAr ? 'سفر وانتقال' : 'Mobility & Travel'),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(2, isAr ? 'شراء طلبات ومصالح' : 'Errand & Shopping'),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(3, isAr ? 'لوجستيات وبضائع' : 'Store Logistics'),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(4, isAr ? 'شحن أمانات' : 'Parcel Delivery'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Orders list
                    Expanded(
                      child: _isActiveOrders
                          ? _buildActiveOrdersList(context, rides, parcels, isAr, isWide: isWide)
                          : _buildPastOrdersList(context, isAr, isWide: isWide),
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

  Widget _buildOrderFilterChip(int index, String label) {
    final isSelected = _ordersFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _ordersFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFD1D1D6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
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
          categoryTag: isAr ? 'سفر بين المحافظات' : 'Inter-city Travel',
          categoryColor: AppColors.navy,
          route: isAr ? 'كفر الشيخ ← القاهرة' : 'Kafr El-Sheikh ← Cairo',
          description: isAr
              ? 'الجمعة 6 نوفمبر، 7:30 ص · الكابتن: محمد سعيد (سيارة خاصة إلنترا مكيفة)'
              : 'Fri Nov 6, 7:30 AM · Captain: Mohamed Saeed (Hyundai Elantra)',
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
                      driverName: 'محمد سعيد',
                      driverCar: 'هيونداي إلنترا، أبيض (س ق ر 1942)',
                      tripRoute: 'كفر الشيخ ← القاهرة',
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

    // Category 2: Errand & Shopping Service (Filter 0 or 2)
    if (_ordersFilterIndex == 0 || _ordersFilterIndex == 2) {
      // Shopping & Parts Delivery Order
      cards.add(
        _buildUnifiedOrderCard(
          context: context,
          categoryTag: isAr ? 'شراء طلبات ومستلزمات' : 'Shopping & Errands',
          categoryColor: const Color(0xFF0D9488),
          route: isAr ? 'التوفيقية، القاهرة ← بلطيم' : 'Tawfikiya, Cairo ← Baltim',
          description: isAr
              ? 'شراء قطع غيار وفلاتر أصلية للسيارات وجلبها مع مسافر · المنفذ: إبراهيم الدسوقي'
              : 'Original spare parts & filters purchased from Cairo · Courier: Ibrahim El-Desouky',
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
                      driverName: 'إبراهيم الدسوقي',
                      driverCar: isAr ? 'خدمة شراء مستلزمات وتوصيل' : 'Shopping & Errand Courier',
                      tripRoute: isAr ? 'التوفيقية، القاهرة ← بلطيم' : 'Cairo ← Baltim',
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
          categoryTag: isAr ? 'قضاء مصالح رسمية' : 'Official Errand',
          categoryColor: const Color(0xFFD97706),
          route: isAr ? 'القاهرة ← كفر الشيخ' : 'Cairo ← Kafr El-Sheikh',
          description: isAr
              ? 'استخراج شهادة تخرج ومستندات رسمية من جامعة القاهرة وتسليمها في كفر الشيخ'
              : 'Official certificate & documents pickup from Cairo University',
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
                      driverName: 'أحمد نبيل',
                      driverCar: isAr ? 'خدمة قضاء مصالح وأوراق رسمية' : 'Official Documents Courier',
                      tripRoute: isAr ? 'القاهرة ← كفر الشيخ' : 'Cairo ← Kafr El-Sheikh',
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
          route: isAr ? 'العتبة، القاهرة ← كفر الشيخ' : 'Attaba, Cairo ← Kafr El-Sheikh',
          description: isAr
              ? 'توريد 5 كراتين مستلزمات لمحل تجاري وسط البلد · الناقل: طارق رضوان'
              : 'Store stock & supplies (5 cartons) · Carrier: Tarek Radwan',
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
                      driverName: 'طارق رضوان',
                      driverCar: isAr ? 'نقل وتوريد بضائع تجارية' : 'Commercial Cargo Transport',
                      tripRoute: isAr ? 'القاهرة ← كفر الشيخ' : 'Cairo ← Kafr El-Sheikh',
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
        route: isAr ? 'القاهرة ← كفر الشيخ' : 'Cairo ← Kafr El-Sheikh',
        description: isAr ? 'الأحد 25 أكتوبر · الكابتن: منى حسن (تويوتا كورولا)' : 'Sun Oct 25 · Captain: Mona Hassan',
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
                    driverName: 'منى حسن',
                    route: 'القاهرة ← كفر الشيخ',
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
        categoryTag: isAr ? 'قضاء مصلحة رسمية' : 'Official Errand',
        categoryColor: const Color(0xFFD97706),
        route: isAr ? 'مجمع التحرير ← كفر الشيخ' : 'Tahrir Complex ← Kafr El-Sheikh',
        description: isAr ? 'استخراج شهادة قيد رسمي · تم الإنجاز 20 أكتوبر' : 'Official records retrieval · Done Oct 20',
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
                    driverName: 'إسلام رجب',
                    route: 'مجمع التحرير ← كفر الشيخ',
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
        route: isAr ? 'الإسكندرية ← كفر الشيخ' : 'Alexandria ← Kafr El-Sheikh',
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
                    driverName: 'أحمد علي',
                    route: 'الإسكندرية ← كفر الشيخ',
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
        route: isAr ? 'طنطا ← القاهرة' : 'Tanta ← Cairo',
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
            // Top Row: Category pill & Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoryTag,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                MashwarBadge(type: badgeType, customLabel: badgeText),
              ],
            ),
            const SizedBox(height: 8),

            // Route
            Text(
              route,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title().copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              description,
              style: AppTypography.bodySecondary().copyWith(fontSize: 13),
            ),

            // OTP Guarantee Box if active
            if (otpCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                    Text(
                      isAr ? 'كود أمان التسليم: ' : 'Security OTP: ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      otpCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
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
    );
  }

  // ==========================================
  // DIRECT MESSAGING TAB: الرسائل (Messages)
  // ==========================================
  Widget _buildMessagesTab(BuildContext context, bool isAr) {
    final List<Map<String, dynamic>> allChats = [
      {
        'id': 'chat_1',
        'name': 'محمد سعيد',
        'verified': true,
        'tag': isAr ? 'سفر تشاركي' : 'Carpooling',
        'car': 'هيونداي إلنترا، أبيض (س ق ر 1942)',
        'route': isAr ? 'كفر الشيخ ← القاهرة' : 'Kafr El-Sheikh ← Cairo',
        'lastMsg': isAr
            ? 'تمام يا غالي، أنا ركنت قدام الكافيه عند مدخل المحطة. سيارة بيضاء.'
            : 'Great! I parked near the station entrance in a white car.',
        'time': '7:22 ص',
        'unread': 1,
      },
      {
        'id': 'chat_2',
        'name': 'أحمد نبيل',
        'verified': true,
        'tag': isAr ? 'قضاء مصلحة رسمية' : 'Official Errand',
        'car': isAr ? 'استخراج شهادة ومستندات رسمية' : 'Document Pickup Service',
        'route': isAr ? 'القاهرة ← كفر الشيخ' : 'Cairo ← Kafr El-Sheikh',
        'lastMsg': isAr
            ? 'استلمت الظرف والمستندات الرسمية وجاري التحرك للموقف.'
            : 'I collected the official envelope and heading to the station.',
        'time': '11:15 ص',
        'unread': 2,
      },
      {
        'id': 'chat_3',
        'name': 'طارق رضوان',
        'verified': true,
        'tag': isAr ? 'لوجستيات وتوريد' : 'Logistics',
        'car': isAr ? 'نقل وتوريد بضائع ومستلزمات' : 'Goods & Commercial Cargo',
        'route': isAr ? 'العتبة، القاهرة ← كفر الشيخ' : 'Attaba, Cairo ← Kafr El-Sheikh',
        'lastMsg': isAr
            ? 'وصلت نقطة التسليم أمام المحل التجاري في انتظار كود OTP.'
            : 'Arrived at the shop drop-off, waiting for OTP code.',
        'time': '1:45 م',
        'unread': 0,
      },
      {
        'id': 'chat_4',
        'name': 'خالد السيد',
        'verified': true,
        'tag': isAr ? 'شحن أمانة وطرود' : 'Parcel Delivery',
        'car': isAr ? 'طرد إلكترونيات وأمانات' : 'Parcel Delivery Service',
        'route': isAr ? 'طنطا ← الإسكندرية' : 'Tanta ← Alexandria',
        'lastMsg': isAr
            ? 'تم تأكيد كود الاستلام بنجاح، شكراً لذوقك.'
            : 'Delivery OTP confirmed successfully. Thank you!',
        'time': isAr ? 'أمس' : 'Yesterday',
        'unread': 0,
      },
    ];

    final query = _messagesSearchController.text.trim().toLowerCase();
    final filteredChats = query.isEmpty
        ? allChats
        : allChats.where((chat) {
            final name = (chat['name'] as String).toLowerCase();
            final lastMsg = (chat['lastMsg'] as String).toLowerCase();
            final route = (chat['route'] as String).toLowerCase();
            return name.contains(query) || lastMsg.contains(query) || route.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'الرسائل والمحادثات' : 'Messages', style: AppTypography.title()),
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
                    // Search Field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppDimens.space16, 12, AppDimens.space16, 6),
                      child: TextField(
                        controller: _messagesSearchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث في الرسائل والأسماء...' : 'Search messages & names...',
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
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Chat threads list
                    Expanded(
                      child: filteredChats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFC7C7CC)),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAr ? 'لا توجد محادثات مطابقة للبحث' : 'No matching chats found',
                                    style: AppTypography.bodySecondary(),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
                              itemCount: filteredChats.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                final unread = (chat['unread'] as int?) ?? 0;
                                return InkWell(
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
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: unread > 0 ? AppColors.teal.withValues(alpha: 0.5) : const Color(0xFFE5E5EA),
                                        width: unread > 0 ? 1.2 : 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar with verification badge
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                                              child: Text(
                                                (chat['name'] as String).substring(0, 1),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.navy,
                                                  fontSize: 16,
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
                                                      style: AppTypography.title().copyWith(fontSize: 15),
                                                    ),
                                                  ),
                                                  Text(
                                                    chat['time'] as String,
                                                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
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
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      chat['tag'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.navy,
                                                        fontWeight: FontWeight.w700,
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
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: const BoxDecoration(
                                              color: AppColors.teal,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '$unread',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
    final isAr = Directionality.of(context) == TextDirection.rtl;
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
          Icon(
            isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 16,
            color: const Color(0xFF8E8E93),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
