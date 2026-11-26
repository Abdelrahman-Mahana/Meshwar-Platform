import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/config/app_environment.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_typography.dart';
import '../core/localization/app_strings.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/mashwar_animations.dart';
import '../core/widgets/mashwar_badge.dart';
import '../core/widgets/mashwar_button.dart';
import '../core/widgets/mashwar_user_avatar.dart';
import '../core/widgets/mashwar_worksite_icons.dart';
import '../data/models/board_ad_model.dart';
import '../data/models/parcel_model.dart';
import '../data/models/ride_model.dart';
import '../data/models/user_model.dart';
import '../data/models/worksite_models.dart';
import '../state/auth_provider.dart';
import '../state/board_provider.dart';
import '../state/parcels_provider.dart';
import '../state/rides_provider.dart';
import '../state/settings_provider.dart';
import '../state/worksite_provider.dart';
import 'account/account_extra_screens.dart';
import 'account/legal_and_backend_screens.dart';
import 'auth/id_verification_screen.dart';
import 'auth/welcome_screen.dart';
import 'board/board_extra_screens.dart';
import 'chat/chat_screen.dart';
import 'driver/driver_rides_management_screens.dart';
import 'driver/publish_ride_screen.dart';
import 'home/home_screen.dart';
import 'parcel/parcel_tracking_screen.dart';
import 'parcel/send_parcel_screen.dart';
import 'settings/settings_screen.dart';
import 'trip/active_trip_screen.dart';
import 'trips/trips_and_parcels_hub_screen.dart';
import 'worksite/create_work_request_screen.dart';
import 'worksite/provider_profile_screen.dart';
import 'worksite/work_request_details_screen.dart';
import 'worksite/work_requests_feed_screen.dart';

/// Clean 5-Tab International Navigation Shell for MASHWAR:
/// 1. `الرئيسية` / `Home` (`HomeScreen`)
/// 2. `الرحلات والطرود` / `Trips & Parcels` (`TripsAndParcelsHubScreen`)
/// 3. `التوريد والمهام` / `Supply & Tasks` (`WorkRequestsFeedScreen`)
/// 4. `نشاطي` / `My Activity` (Unified multi-service activity hub)
/// 5. `حسابي` / `Account` (Clean international account hub)
class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  static bool switchToTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_MainNavShellState>();
    if (state == null) return false;
    state.setTab(tabIndex);
    return true;
  }

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  // Unified Activity Tab state
  bool _isActiveOrders = true;
  int _activityServiceFilter = 0; // 0 = All, 1 = Trips, 2 = Parcels, 3 = Supply

  WorksiteProvider? _fallbackWorksiteProvider;
  RidesProvider? _fallbackRidesProvider;
  ParcelsProvider? _fallbackParcelsProvider;
  BoardProvider? _fallbackBoardProvider;
  bool _didAttemptInitialSync = false;

  void setTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index.clamp(0, 4));
  }

  WorksiteProvider _resolveWorksite(BuildContext context, AuthProvider auth) {
    final provided = context.watch<WorksiteProvider?>();
    if (provided != null) return provided;
    return _fallbackWorksiteProvider ??= WorksiteProvider(
      initialUserId: auth.user.id.isNotEmpty ? auth.user.id : null,
      initialUserName:
          auth.user.fullName.isNotEmpty ? auth.user.fullName : null,
    );
  }

  RidesProvider _resolveRides(BuildContext context) {
    final provided = context.watch<RidesProvider?>();
    if (provided != null) return provided;
    return _fallbackRidesProvider ??= RidesProvider();
  }

  ParcelsProvider _resolveParcels(BuildContext context) {
    final provided = context.watch<ParcelsProvider?>();
    if (provided != null) return provided;
    return _fallbackParcelsProvider ??= ParcelsProvider();
  }

  BoardProvider _resolveBoard(BuildContext context) {
    final provided = context.watch<BoardProvider?>();
    if (provided != null) return provided;
    return _fallbackBoardProvider ??= BoardProvider();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAttemptInitialSync) return;
      _didAttemptInitialSync = true;
      final ws = context.read<WorksiteProvider?>();
      final rides = context.read<RidesProvider?>();
      final parcels = context.read<ParcelsProvider?>();
      final board = context.read<BoardProvider?>();
      final auth = context.read<AuthProvider?>();

      rides?.loadRides();
      parcels?.loadParcels();
      board?.loadBoardAds();

      if (ws != null) {
        final uid = ws.currentUserId ?? auth?.user.id ?? '';
        if (ws.allLoadedRequests.isEmpty && !ws.isLoading && !ws.hasError) {
          ws.loadRequests();
        }
        if (ws.notifications.isEmpty) {
          ws.loadNotifications();
        }
        if (uid.isNotEmpty && ws.providerProfile == null) {
          ws.loadProviderProfile(uid);
          ws.loadSavedWorksites(uid);
        }
      }
    });
  }

  @override
  void dispose() {
    _fallbackWorksiteProvider?.dispose();
    _fallbackRidesProvider?.dispose();
    _fallbackParcelsProvider?.dispose();
    _fallbackBoardProvider?.dispose();
    super.dispose();
  }

  Widget _buildIconWithBadge(
    IconData icon, {
    required Color color,
    int badgeCount = 0,
  }) {
    final iconWidget = Icon(icon, size: 22, color: color);
    if (badgeCount <= 0) return iconWidget;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        PositionedDirectional(
          top: -5,
          end: -7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.qatarMaroon,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            constraints: const BoxConstraints(minWidth: 15),
            child: Text(
              badgeCount > 9 ? '9+' : '$badgeCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavIconPill(
    IconData icon, {
    bool active = false,
    int badgeCount = 0,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: active ? 12 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.navy.withValues(alpha: 0.11)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _buildIconWithBadge(
        icon,
        color: active ? AppColors.navy : const Color(0xFF64748B),
        badgeCount: badgeCount,
      ),
    );
  }

  Widget _buildAccountNavIcon({
    required UserModel user,
    required bool active,
    required int badgeCount,
    bool pillStyle = false,
  }) {
    final hasCustomAvatar =
        user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;
    Widget coreIcon;
    if (hasCustomAvatar) {
      coreIcon = MashwarUserAvatar(
        avatarUrl: user.avatarUrl,
        fullName: user.fullName.isNotEmpty ? user.fullName : 'م',
        size: 25,
        borderWidth: active ? 2.0 : 1.5,
        borderColor: active ? AppColors.gold : AppColors.teal,
      );
      if (badgeCount > 0) {
        coreIcon = Stack(
          clipBehavior: Clip.none,
          children: [
            coreIcon,
            PositionedDirectional(
              top: -4,
              end: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.qatarMaroon,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                constraints: const BoxConstraints(minWidth: 15),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    } else {
      coreIcon = _buildIconWithBadge(
        active ? Icons.person_rounded : Icons.person_outline_rounded,
        color: active ? AppColors.navy : const Color(0xFF64748B),
        badgeCount: badgeCount,
      );
    }

    if (!pillStyle) return coreIcon;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: active ? 12 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.navy.withValues(alpha: 0.11)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: coreIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final worksite = _resolveWorksite(context, auth);
    final rides = _resolveRides(context);
    final parcels = _resolveParcels(context);
    final board = _resolveBoard(context);
    final isAr = settings.isArabic;

    final currentUid = worksite.currentUserId ??
        (auth.user.id.isNotEmpty ? auth.user.id : null);
    final unreadNotificationsCount = worksite.unreadNotificationsCount;
    final supplyAttentionCount = currentUid == null
        ? 0
        : worksite.allLoadedRequests.where((r) {
            if (r.requesterId == currentUid) {
              return r.status == WorkRequestStatus.offerReceived ||
                  r.status == WorkRequestStatus.deliveredPendingConfirmation;
            }
            if (r.assignedProviderId == currentUid) {
              return r.status == WorkRequestStatus.deliveredPendingConfirmation;
            }
            return false;
          }).length;
    final activeParcelsAttention = parcels.parcels
        .where((p) => p.status != ParcelStatusStep.delivered)
        .length;
    final activityBadgeCount = supplyAttentionCount + activeParcelsAttention;

    final pages = <Widget>[
      const HomeScreen(),
      const TripsAndParcelsHubScreen(embeddedInTab: true),
      const WorkRequestsFeedScreen(embeddedInTab: true),
      _buildUnifiedActivityTab(
        context: context,
        worksite: worksite,
        rides: rides,
        parcels: parcels,
        board: board,
        auth: auth,
        isAr: isAr,
      ),
      _buildInternationalAccountTab(
        context: context,
        worksite: worksite,
        rides: rides,
        parcels: parcels,
        board: board,
        auth: auth,
        settings: settings,
      ),
    ];

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    final railDestinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: Text(isAr ? 'الرئيسية' : 'Home'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.route_outlined),
        selectedIcon: const Icon(Icons.route_rounded),
        label: Text(isAr ? 'الرحلات والطرود' : 'Trips & Parcels'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.fact_check_outlined),
        selectedIcon: const Icon(Icons.fact_check_rounded),
        label: Text(isAr ? 'التوريد والمهام' : 'Supply & Tasks'),
      ),
      NavigationRailDestination(
        icon: _buildIconWithBadge(
          Icons.assignment_outlined,
          color: AppColors.textSecondary,
          badgeCount: activityBadgeCount,
        ),
        selectedIcon: _buildIconWithBadge(
          Icons.assignment_rounded,
          color: AppColors.cobalt,
          badgeCount: activityBadgeCount,
        ),
        label: Text(isAr ? 'نشاطي' : 'My Activity'),
      ),
      NavigationRailDestination(
        icon: _buildAccountNavIcon(
          user: auth.user,
          active: false,
          badgeCount: unreadNotificationsCount,
        ),
        selectedIcon: _buildAccountNavIcon(
          user: auth.user,
          active: true,
          badgeCount: unreadNotificationsCount,
        ),
        label: Text(isAr ? 'حسابي' : 'Account'),
      ),
    ];

    final bottomItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: _buildNavIconPill(Icons.home_outlined),
        activeIcon: _buildNavIconPill(Icons.home_rounded, active: true),
        label: isAr ? 'الرئيسية' : 'Home',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIconPill(Icons.route_outlined),
        activeIcon: _buildNavIconPill(Icons.route_rounded, active: true),
        label: isAr ? 'الرحلات والطرود' : 'Trips & Parcels',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIconPill(Icons.fact_check_outlined),
        activeIcon: _buildNavIconPill(Icons.fact_check_rounded, active: true),
        label: isAr ? 'التوريد والمهام' : 'Supply & Tasks',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIconPill(
          Icons.assignment_outlined,
          badgeCount: activityBadgeCount,
        ),
        activeIcon: _buildNavIconPill(
          Icons.assignment_rounded,
          active: true,
          badgeCount: activityBadgeCount,
        ),
        label: isAr ? 'نشاطي' : 'My Activity',
      ),
      BottomNavigationBarItem(
        icon: _buildAccountNavIcon(
          user: auth.user,
          active: false,
          badgeCount: unreadNotificationsCount,
          pillStyle: true,
        ),
        activeIcon: _buildAccountNavIcon(
          user: auth.user,
          active: true,
          badgeCount: unreadNotificationsCount,
          pillStyle: true,
        ),
        label: isAr ? 'حسابي' : 'Account',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;
        final isExtended = constraints.maxWidth >= 1140;

        if (isWide) {
          return Scaffold(
            backgroundColor: AppColors.slateBg,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  extended: isExtended,
                  minWidth: 82,
                  minExtendedWidth: 232,
                  backgroundColor: Colors.white,
                  indicatorColor: AppColors.cobaltSurface,
                  selectedIconTheme:
                      const IconThemeData(color: AppColors.cobalt, size: 22),
                  unselectedIconTheme: const IconThemeData(
                      color: AppColors.textSecondary, size: 22),
                  selectedLabelTextStyle: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 13,
                  ),
                  unselectedLabelTextStyle:
                      AppTypography.bodySecondary().copyWith(fontSize: 13),
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
                        padding: const EdgeInsets.only(
                            bottom: 20, left: 12, right: 12),
                        child: isExtended
                            ? OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  side: const BorderSide(
                                      color: AppColors.slateBorder),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => settings.toggleLanguage(),
                                icon: const Icon(Icons.language_rounded,
                                    size: 18),
                                label: Text(
                                  isAr ? 'English' : 'العربية',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: isAr ? 'English' : 'العربية',
                                icon: const Icon(Icons.language_rounded,
                                    color: AppColors.navy),
                                onPressed: () => settings.toggleLanguage(),
                              ),
                      ),
                    ),
                  ),
                  destinations: railDestinations,
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.slateBorder,
                ),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: AppColors.slateBorder, width: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedLabelStyle: AppTypography.label()
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 10.5),
              unselectedLabelStyle: AppTypography.label()
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 10),
              selectedItemColor: AppColors.navy,
              unselectedItemColor: const Color(0xFF64748B),
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: bottomItems,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 4: نشاطي / My Activity (Unified Multi-Service Hub)
  // ===========================================================================
  Widget _buildUnifiedActivityTab({
    required BuildContext context,
    required WorksiteProvider worksite,
    required RidesProvider rides,
    required ParcelsProvider parcels,
    required BoardProvider board,
    required AuthProvider auth,
    required bool isAr,
  }) {
    final uid = worksite.currentUserId ??
        (auth.user.id.isNotEmpty ? auth.user.id : null);

    // 1. Trips (Booked & Published Rides + Ride Route Ads)
    final tripRideMap = <String, ({RideModel ride, bool isPublished})>{};
    for (final r in rides.myPublishedRides) {
      tripRideMap[r.id] = (ride: r, isPublished: true);
    }
    for (final r in rides.bookedRides) {
      tripRideMap.putIfAbsent(r.id, () => (ride: r, isPublished: false));
    }
    final activeTripRides = tripRideMap.values
        .where((e) => e.ride.status != 'completed' && e.ride.status != 'cancelled')
        .toList();
    final completedTripRides = tripRideMap.values
        .where((e) => e.ride.status == 'completed' || e.ride.status == 'cancelled')
        .toList();

    final myRideAds = [
      ...board.myAds.where(
        (a) => a.type == BoardAdType.rideRequest || a.type == BoardAdType.rideOffer,
      ),
      ...board.mySentOffers.where(
        (a) =>
            (a.type == BoardAdType.rideRequest || a.type == BoardAdType.rideOffer) &&
            !board.myAds.any((m) => m.id == a.id),
      ),
    ];
    final activeRideAds = myRideAds
        .where((a) =>
            a.status != BoardAdStatus.completed &&
            a.status != BoardAdStatus.expired &&
            a.status != BoardAdStatus.cancelled)
        .toList();
    final completedRideAds = myRideAds
        .where((a) =>
            a.status == BoardAdStatus.completed ||
            a.status == BoardAdStatus.expired ||
            a.status == BoardAdStatus.cancelled)
        .toList();

    // 2. Parcels (Tracked Parcels with OTP + Parcel Route Ads)
    final activeParcels = parcels.parcels
        .where((p) => p.status != ParcelStatusStep.delivered)
        .toList();
    final completedParcels = parcels.parcels
        .where((p) => p.status == ParcelStatusStep.delivered)
        .toList();

    final myParcelAds = [
      ...board.myAds.where((a) => a.type == BoardAdType.parcelRequest),
      ...board.mySentOffers.where(
        (a) =>
            a.type == BoardAdType.parcelRequest &&
            !board.myAds.any((m) => m.id == a.id),
      ),
    ];
    final activeParcelAds = myParcelAds
        .where((a) =>
            a.status != BoardAdStatus.completed &&
            a.status != BoardAdStatus.expired &&
            a.status != BoardAdStatus.cancelled)
        .toList();
    final completedParcelAds = myParcelAds
        .where((a) =>
            a.status == BoardAdStatus.completed ||
            a.status == BoardAdStatus.expired ||
            a.status == BoardAdStatus.cancelled)
        .toList();

    // 3. Supply & Tasks (WorkRequests)
    final ownedSupply = uid == null
        ? const <WorkRequest>[]
        : worksite.allLoadedRequests
            .where((r) => r.requesterId == uid || r.assignedProviderId == uid)
            .toList();
    final activeSupply = ownedSupply
        .where((r) => !WorkRequestStatusMachine.isTerminal(r.status))
        .toList();
    final completedSupply = ownedSupply
        .where((r) => WorkRequestStatusMachine.isTerminal(r.status))
        .toList();

    // Assemble cards for current filter & segment
    final activeCards = <Widget>[];
    final completedCards = <Widget>[];

    if (_activityServiceFilter == 0 || _activityServiceFilter == 1) {
      for (final entry in activeTripRides) {
        activeCards.add(
          _buildTripActivityCard(
            context: context,
            ride: entry.ride,
            isPublished: entry.isPublished,
            isAr: isAr,
          ),
        );
      }
      for (final ad in activeRideAds) {
        activeCards.add(
          _buildRouteAdActivityCard(context: context, ad: ad, isAr: isAr),
        );
      }
      for (final entry in completedTripRides) {
        completedCards.add(
          _buildTripActivityCard(
            context: context,
            ride: entry.ride,
            isPublished: entry.isPublished,
            isAr: isAr,
          ),
        );
      }
      for (final ad in completedRideAds) {
        completedCards.add(
          _buildRouteAdActivityCard(context: context, ad: ad, isAr: isAr),
        );
      }
    }

    if (_activityServiceFilter == 0 || _activityServiceFilter == 2) {
      for (final p in activeParcels) {
        activeCards.add(
          _buildParcelActivityCard(context: context, parcel: p, isAr: isAr),
        );
      }
      for (final ad in activeParcelAds) {
        activeCards.add(
          _buildRouteAdActivityCard(context: context, ad: ad, isAr: isAr),
        );
      }
      for (final p in completedParcels) {
        completedCards.add(
          _buildParcelActivityCard(context: context, parcel: p, isAr: isAr),
        );
      }
      for (final ad in completedParcelAds) {
        completedCards.add(
          _buildRouteAdActivityCard(context: context, ad: ad, isAr: isAr),
        );
      }
    }

    if (_activityServiceFilter == 0 || _activityServiceFilter == 3) {
      for (final req in activeSupply) {
        activeCards.add(
          _buildSupplyActivityCard(
            context: context,
            worksite: worksite,
            req: req,
            uid: uid,
            isAr: isAr,
          ),
        );
      }
      for (final req in completedSupply) {
        completedCards.add(
          _buildSupplyActivityCard(
            context: context,
            worksite: worksite,
            req: req,
            uid: uid,
            isAr: isAr,
          ),
        );
      }
    }

    final totalActiveCount = activeTripRides.length +
        activeRideAds.length +
        activeParcels.length +
        activeParcelAds.length +
        activeSupply.length;
    final totalCompletedCount = completedTripRides.length +
        completedRideAds.length +
        completedParcels.length +
        completedParcelAds.length +
        completedSupply.length;

    final shownCards = _isActiveOrders ? activeCards : completedCards;
    final unreadCount = worksite.unreadNotificationsCount;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
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
                isAr ? 'نشاطي' : 'My Activity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'الإشعارات' : 'Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsCenterScreen(),
                ),
              );
            },
            icon: _buildIconWithBadge(
              unreadCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.navy,
              badgeCount: unreadCount,
            ),
          ),
          IconButton(
            tooltip: isAr ? 'تحديث' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navy),
            onPressed: worksite.isLoading
                ? null
                : () async {
                    await Future.wait([
                      rides.loadRides(),
                      parcels.loadParcels(),
                      board.loadBoardAds(),
                      worksite.loadRequests(),
                      worksite.loadNotifications(),
                    ]);
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segment Switch + 4 Service Filter Pills
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.space16, 10, AppDimens.space16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                key: const ValueKey('activity_segment_active'),
                                onTap: () =>
                                    setState(() => _isActiveOrders = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _isActiveOrders
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isActiveOrders
                                        ? [
                                            BoxShadow(
                                              color: AppColors.navy
                                                  .withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr
                                          ? 'النشطة والجارية ($totalActiveCount)'
                                          : 'Active ($totalActiveCount)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySecondary(
                                        color: _isActiveOrders
                                            ? AppColors.navy
                                            : AppColors.textSecondary,
                                      ).copyWith(
                                        fontWeight: _isActiveOrders
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                key: const ValueKey(
                                    'activity_segment_completed'),
                                onTap: () =>
                                    setState(() => _isActiveOrders = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: !_isActiveOrders
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isActiveOrders
                                        ? [
                                            BoxShadow(
                                              color: AppColors.navy
                                                  .withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAr
                                          ? 'المكتملة والسابقة ($totalCompletedCount)'
                                          : 'Completed ($totalCompletedCount)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySecondary(
                                        color: !_isActiveOrders
                                            ? AppColors.navy
                                            : AppColors.textSecondary,
                                      ).copyWith(
                                        fontWeight: !_isActiveOrders
                                            ? FontWeight.w800
                                            : FontWeight.w600,
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
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildActivityFilterPill(
                              key: const ValueKey('activity_filter_all'),
                              index: 0,
                              label: isAr ? 'الكل' : 'All',
                              icon: Icons.apps_rounded,
                              accent: AppColors.navy,
                            ),
                            const SizedBox(width: 8),
                            _buildActivityFilterPill(
                              key: const ValueKey('activity_filter_trips'),
                              index: 1,
                              label: isAr ? 'الرحلات' : 'Trips',
                              icon: Icons.directions_car_outlined,
                              accent: AppColors.cobalt,
                            ),
                            const SizedBox(width: 8),
                            _buildActivityFilterPill(
                              key: const ValueKey('activity_filter_parcels'),
                              index: 2,
                              label: isAr ? 'الطرود' : 'Parcels',
                              icon: Icons.inventory_2_outlined,
                              accent: AppColors.indigo,
                            ),
                            const SizedBox(width: 8),
                            _buildActivityFilterPill(
                              key: const ValueKey('activity_filter_supply'),
                              index: 3,
                              label: isAr ? 'التوريد' : 'Supply',
                              icon: Icons.fact_check_outlined,
                              accent: AppColors.emerald,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.slateBorder),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${_isActiveOrders}_$_activityServiceFilter',
                      ),
                      child: RefreshIndicator(
                        color: AppColors.cobalt,
                        onRefresh: () async {
                          await Future.wait([
                            rides.loadRides(),
                            parcels.loadParcels(),
                            board.loadBoardAds(),
                            worksite.loadRequests(),
                            worksite.loadNotifications(),
                          ]);
                        },
                        child: shownCards.isEmpty
                            ? _buildEmptyActivityState(context, isAr)
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.all(AppDimens.space16),
                                itemCount: shownCards.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, idx) => shownCards[idx],
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
    );
  }

  Widget _buildActivityFilterPill({
    required Key key,
    required int index,
    required String label,
    required IconData icon,
    required Color accent,
  }) {
    final selected = _activityServiceFilter == index;
    return MashwarPressable(
      key: key,
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _activityServiceFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : AppColors.slateBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : accent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label(
                color: selected ? Colors.white : AppColors.navy,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState(BuildContext context, bool isAr) {
    return LayoutBuilder(
      builder: (context, emptyConstraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.space24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  (emptyConstraints.maxHeight - 48).clamp(0.0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: MashwarSectionCard(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  borderRadius: 18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MashwarTrustEmblem(
                        type: MashwarTrustType.liveCorridor,
                        size: 46,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isActiveOrders
                            ? (isAr
                                ? 'لا توجد أنشطة جارية في هذا القسم'
                                : 'No Active Items in This Category')
                            : (isAr
                                ? 'لا يوجد سجل مكتمل بعد'
                                : 'No Completed History Yet'),
                        textAlign: TextAlign.center,
                        style: AppTypography.title().copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'انشر رحلة بمقاعد شاغرة، أرسل طرداً مع مسافر، أو أنشئ طلب توريد جديد.'
                            : 'Publish a shared trip, send a parcel on route, or create a smart supply request.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary(),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cobalt,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PublishRideScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_road_rounded, size: 16),
                            label: Text(
                              isAr ? 'انشر رحلة' : 'Publish Trip',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SendParcelScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.inventory_2_outlined,
                                size: 16),
                            label: Text(
                              isAr ? 'أرسل طرداً' : 'Send Parcel',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CreateWorkRequestScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_task_rounded, size: 16),
                            label: Text(
                              isAr ? 'طلب توريد' : 'Supply Request',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripActivityCard({
    required BuildContext context,
    required RideModel ride,
    required bool isPublished,
    required bool isAr,
  }) {
    return MashwarHoverCard(
      key: ValueKey('activity_trip_${ride.id}'),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.slateBorder,
      hoverBorderColor: AppColors.cobalt,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActiveTripScreen(ride: ride)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarServicePillarIcon(
                pillar: MashwarServicePillar.sharedTrips,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cobaltSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPublished
                            ? (isAr ? 'رحلتي المنشورة' : 'Published Trip')
                            : (isAr ? 'مقعد محجوز' : 'Booked Seat'),
                        style: AppTypography.label(color: AppColors.cobalt)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    MashwarBadge(
                      type: BadgeType.confirmed,
                      customLabel: ride.acceptsParcels
                          ? (isAr
                              ? '${ride.remainingSeats} مقاعد · يقبل طرود'
                              : '${ride.remainingSeats} seats · Parcels')
                          : (isAr
                              ? '${ride.remainingSeats} مقاعد'
                              : '${ride.remainingSeats} seats'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MashwarRouteTimeline(
            from: context.trCity(ride.fromCity),
            to: context.trCity(ride.toCity),
            trailingTop: '${ride.departureDate} · ${ride.departureTime}',
            compact: true,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MashwarUserAvatar(
                    avatarUrl: null,
                    fullName: ride.driverName,
                    size: 28,
                    borderWidth: 1.4,
                    borderColor: AppColors.gold,
                    autoCommunityPortrait: true,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${ride.driverName} · ${ride.pricePerSeat} ${isAr ? "ر.ق" : "QAR"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            driverName: ride.driverName,
                            driverCar: ride.driverCar,
                            tripRoute: '${ride.fromCity} ← ${ride.toCity}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15),
                    label: Text(isAr ? 'محادثة' : 'Chat'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cobalt,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ActiveTripScreen(ride: ride)),
                      );
                    },
                    child: Text(isAr ? 'متابعة الرحلة' : 'Track Trip'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParcelActivityCard({
    required BuildContext context,
    required ParcelModel parcel,
    required bool isAr,
  }) {
    final deliveryOtp = parcel.deliveryOtp ?? '';
    return MashwarHoverCard(
      key: ValueKey('activity_parcel_${parcel.id}'),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.slateBorder,
      hoverBorderColor: AppColors.indigo,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ParcelTrackingScreen(parcel: parcel),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarServicePillarIcon(
                pillar: MashwarServicePillar.routeParcels,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.indigoSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        parcel.hasAssignedTraveler
                            ? (isAr
                                ? 'طرد مع مسافر'
                                : 'Matched Route Parcel')
                            : (isAr
                                ? 'طلب طرد مفتوح'
                                : 'Open Parcel Request'),
                        style: AppTypography.label(color: AppColors.indigo)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    MashwarBadge(
                      type: parcel.status == ParcelStatusStep.delivered
                          ? BadgeType.verified
                          : BadgeType.confirmed,
                      customLabel: parcel.sizeLabel(isAr),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            parcel.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title().copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.trRoute(parcel.route)}${parcel.hasAssignedTraveler ? " · ${parcel.driverName}" : ""}',
            style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: parcel.pickupOtp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم نسخ كود الاستلام: ${parcel.pickupOtp}'
                            : 'Pickup OTP copied: ${parcel.pickupOtp}',
                      ),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: AppColors.goldDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAr
                            ? 'كود الاستلام: ${parcel.pickupOtp}'
                            : 'Pickup OTP: ${parcel.pickupOtp}',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              if (deliveryOtp.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: deliveryOtp));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr
                              ? 'تم نسخ كود التسليم: $deliveryOtp'
                              : 'Delivery OTP copied: $deliveryOtp',
                        ),
                        backgroundColor: AppColors.teal,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAr
                              ? 'كود التسليم: $deliveryOtp'
                              : 'Delivery OTP: $deliveryOtp',
                          style: AppTypography.label(color: AppColors.emerald)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '${parcel.fee} ${isAr ? "ر.ق" : "QAR"}',
                style: AppTypography.body(color: AppColors.indigo)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ParcelTrackingScreen(parcel: parcel),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_rounded, size: 16),
                label: Text(isAr ? 'تتبع الطرد و OTP' : 'Track & OTP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteAdActivityCard({
    required BuildContext context,
    required BoardAdModel ad,
    required bool isAr,
  }) {
    final isParcelAd = ad.type == BoardAdType.parcelRequest;
    final accent = isParcelAd ? AppColors.indigo : AppColors.cobalt;
    return MashwarHoverCard(
      key: ValueKey('activity_ad_${ad.id}'),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.slateBorder,
      hoverBorderColor: accent,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isParcelAd
                      ? AppColors.indigoSurface
                      : AppColors.cobaltSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ad.displaySubTag(isAr),
                  style: AppTypography.label(color: accent)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${ad.myOfferPrice ?? ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
                style: AppTypography.body(color: accent)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MashwarRouteTimeline(
            from: context.trCity(ad.fromCity),
            to: context.trCity(ad.toCity),
            trailingTop: ad.timeText,
            compact: true,
          ),
          const SizedBox(height: 6),
          Text(
            ad.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyActivityCard({
    required BuildContext context,
    required WorksiteProvider worksite,
    required WorkRequest req,
    required String? uid,
    required bool isAr,
  }) {
    final isMyReq = req.requesterId == uid;
    final isTerminal = WorkRequestStatusMachine.isTerminal(req.status);
    final areaLabel =
        AppStrings.translateCity(req.municipality, isArabic: isAr);
    final showHandoverReady = req.status ==
            WorkRequestStatus.deliveredPendingConfirmation ||
        (isMyReq &&
            (req.status == WorkRequestStatus.accepted ||
                req.status == WorkRequestStatus.inProgress ||
                req.status == WorkRequestStatus.pickedUp ||
                req.status == WorkRequestStatus.inTransit));

    return MashwarHoverCard(
      key: ValueKey('activity_card_${req.id}'),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.slateBorder,
      hoverBorderColor: AppColors.emerald,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkRequestDetailsScreen(requestId: req.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MashwarCategoryIcon(
                category: req.supplyCategory,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isMyReq
                            ? AppColors.emeraldSurface
                            : AppColors.cobaltSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isMyReq
                            ? (isAr ? 'طلب توريد خاص بي' : 'My Supply Request')
                            : (isAr ? 'مهمة مسندة لي' : 'Assigned Supply Job'),
                        style: AppTypography.label(
                          color: isMyReq ? AppColors.emerald : AppColors.cobalt,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    MashwarBadge(
                      type: req.status == WorkRequestStatus.completed
                          ? BadgeType.verified
                          : (req.status == WorkRequestStatus.disputed
                              ? BadgeType.rejected
                              : BadgeType.confirmed),
                      customLabel: req.status.label(isArabic: isAr),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req.title,
            style: AppTypography.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          MashwarRouteTimeline(
            from: req.pickupLocation,
            to: '${req.dropoffWorksite} · $areaLabel',
            compact: true,
          ),
          if (!isTerminal) ...[
            const SizedBox(height: 10),
            MashwarWorksiteStatusStepper(
              status: req.status,
              isAr: isAr,
              compact: true,
            ),
          ],
          if (showHandoverReady) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: req.status ==
                        WorkRequestStatus.deliveredPendingConfirmation
                    ? AppColors.goldSurface
                    : AppColors.emeraldSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: req.status ==
                          WorkRequestStatus.deliveredPendingConfirmation
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : AppColors.emerald.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    size: 16,
                    color: req.status ==
                            WorkRequestStatus.deliveredPendingConfirmation
                        ? AppColors.warning
                        : AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.status ==
                              WorkRequestStatus.deliveredPendingConfirmation
                          ? (isAr
                              ? (isMyReq
                                  ? 'وصل المزود — افتح التفاصيل لمشاركة رمز التسليم (6 خانات)'
                                  : 'جاهز للإغلاق — أدخل رمز التسليم المكون من 6 خانات')
                              : (isMyReq
                                  ? 'Handover ready — open details to share 6-char code'
                                  : 'Handover ready — enter 6-char code to complete'))
                          : (isAr
                              ? 'رمز التسليم السري نشط في تفاصيل الطلب'
                              : '6-char handover code active in request details'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                req.effectiveTotalMinor.format(isArabic: isAr),
                style: AppTypography.body(color: AppColors.emerald)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (isMyReq)
                    OutlinedButton.icon(
                      key: ValueKey('activity_reorder_${req.id}'),
                      onPressed: () {
                        final draft = worksite.buildReorderDraft(req);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateWorkRequestScreen(
                              initialDraft: draft,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(isAr ? 'إعادة طلب' : 'Quick Reorder'),
                    ),
                  ElevatedButton(
                    key: ValueKey('activity_details_${req.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkRequestDetailsScreen(requestId: req.id),
                        ),
                      );
                    },
                    child: Text(isAr ? 'التفاصيل' : 'Details'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: حسابي / Account (Clean International Account Hub)
  // ===========================================================================
  Widget _buildInternationalAccountTab({
    required BuildContext context,
    required WorksiteProvider worksite,
    required RidesProvider rides,
    required ParcelsProvider parcels,
    required BoardProvider board,
    required AuthProvider auth,
    required SettingsProvider settings,
  }) {
    final isAr = settings.isArabic;
    final user = auth.user;
    final prov = worksite.providerProfile;
    final uid = worksite.currentUserId ?? user.id;
    final unreadCount = worksite.unreadNotificationsCount;

    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : ((user.email != null && user.email!.isNotEmpty)
            ? user.email!
            : (isAr ? 'عضو مشوار' : 'MASHWAR Member'));

    final realRating =
        (prov != null && prov.rating > 0) ? prov.rating : user.rating;
    final myReqCount = uid.isEmpty
        ? 0
        : worksite.allLoadedRequests
            .where((r) => r.requesterId == uid)
            .length;
    final publishedTripsCount = rides.myPublishedRides.length;
    final parcelsCount = parcels.parcels.length;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'حسابي' : 'Account', style: AppTypography.title()),
        actions: [
          IconButton(
            tooltip: isAr ? 'الإشعارات' : 'Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsCenterScreen(),
                ),
              );
            },
            icon: _buildIconWithBadge(
              unreadCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.navy,
              badgeCount: unreadCount,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.navy),
            tooltip: isAr ? 'الإعدادات' : 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 280),
                offsetY: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Identity & Multi-Service Profile Summary Card
                    MashwarSectionCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 18,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              MashwarUserAvatar(
                                key: const ValueKey('account_tab_avatar_btn'),
                                avatarUrl: user.avatarUrl,
                                fullName: displayName,
                                size: 64,
                                borderWidth: 2.4,
                                borderColor: AppColors.gold,
                                showCameraBadge: true,
                                onTap: () =>
                                    pickAndSaveCurrentUserAvatar(context),
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
                                            displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.title()
                                                .copyWith(fontSize: 18),
                                          ),
                                        ),
                                        if (worksite.isApprovedProvider ||
                                            user.isVerified) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified_rounded,
                                              color: AppColors.emerald,
                                              size: 18),
                                        ],
                                      ],
                                    ),
                                    if (user.email != null &&
                                        user.email!.isNotEmpty)
                                      Text(
                                        user.email!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySecondary(),
                                      ),
                                    if (user.phone.isNotEmpty)
                                      Text(user.phone,
                                          style: AppTypography.label()),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.cobalt,
                                  side: BorderSide(
                                    color: AppColors.cobalt
                                        .withValues(alpha: 0.35),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const UserProfileScreen()),
                                  );
                                },
                                child: Text(
                                  isAr ? 'الملف' : 'Profile',
                                  style: AppTypography.label(
                                          color: AppColors.cobalt)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: [
                              _buildAccountTrustChip(
                                MashwarTrustType.qatarIdCrest,
                                prov != null
                                    ? prov.approvalStatus.label(isArabic: isAr)
                                    : (user.idVerificationStatus ==
                                            IdVerificationStatus.verified
                                        ? (isAr
                                            ? 'هوية موثّقة'
                                            : 'Identity Verified')
                                        : (isAr
                                            ? 'عضوية نشطة'
                                            : 'Active Member')),
                              ),
                              _buildAccountTrustChip(
                                MashwarTrustType.verifiedReceipt,
                                isAr ? 'فواتير موثّقة' : 'Verified Invoices',
                              ),
                              _buildAccountTrustChip(
                                MashwarTrustType.handoverShield,
                                isAr ? 'تأكيد OTP وتسليم' : 'OTP Handover',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatColumn(
                                  '$publishedTripsCount',
                                  isAr ? 'رحلاتي' : 'Trips',
                                ),
                              ),
                              _buildStatDivider(),
                              Expanded(
                                child: _buildStatColumn(
                                  '$parcelsCount',
                                  isAr ? 'طرودي' : 'Parcels',
                                ),
                              ),
                              _buildStatDivider(),
                              Expanded(
                                child: _buildStatColumn(
                                  '$myReqCount',
                                  isAr ? 'التوريد' : 'Supply',
                                ),
                              ),
                              _buildStatDivider(),
                              Expanded(
                                child: _buildStatColumn(
                                  realRating > 0
                                      ? '${realRating.toStringAsFixed(1)} ★'
                                      : '—',
                                  isAr ? 'التقييم' : 'Rating',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Clean International Multi-Service Account Hub Menu
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusCard),
                        side: const BorderSide(color: AppColors.slateBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildMenuItem(
                            key: const ValueKey('account_identity_tile'),
                            icon: Icons.badge_outlined,
                            iconBg: AppColors.cobaltSurface,
                            iconColor: AppColors.cobalt,
                            title: isAr
                                ? 'توثيق الهوية والبيانات الشخصية'
                                : 'Identity Verification & Personal Info',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const IdVerificationScreen(
                                    isOnboarding: false,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            key: const ValueKey('account_driver_rides_tile'),
                            icon: Icons.directions_car_outlined,
                            iconBg: AppColors.cobaltSurface,
                            iconColor: AppColors.cobalt,
                            title: isAr
                                ? 'رحلاتي المنشورة'
                                : 'My Published Trips',
                            trailingText: publishedTripsCount > 0
                                ? '$publishedTripsCount'
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DriverRidesScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            key: const ValueKey('account_board_ads_tile'),
                            icon: Icons.campaign_outlined,
                            iconBg: AppColors.indigoSurface,
                            iconColor: AppColors.indigo,
                            title: isAr
                                ? 'طلبات السفر والطرود'
                                : 'Trip & Parcel Requests',
                            trailingText: board.myAds.isNotEmpty
                                ? '${board.myAds.length}'
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MyBoardAdsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            key: const ValueKey('account_provider_profile_tile'),
                            icon: Icons.verified_user_outlined,
                            iconBg: AppColors.emeraldSurface,
                            iconColor: AppColors.emerald,
                            title: isAr
                                ? 'ملف المزود والمواقع المحفوظة'
                                : 'Provider Profile & QID Verification',
                            badge: prov != null
                                ? MashwarBadge(
                                    type: prov.approvalStatus ==
                                            ProviderApprovalStatus.approved
                                        ? BadgeType.verified
                                        : (prov.approvalStatus ==
                                                ProviderApprovalStatus.rejected
                                            ? BadgeType.rejected
                                            : BadgeType.pending),
                                    customLabel: prov.approvalStatus
                                        .label(isArabic: isAr),
                                  )
                                : null,
                            trailingText: prov == null &&
                                    worksite.savedWorksites.isNotEmpty
                                ? '${worksite.savedWorksites.length}'
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ProviderProfileScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            key: const ValueKey('account_notifications_tile'),
                            icon: Icons.notifications_active_outlined,
                            iconBg: AppColors.goldSurface,
                            iconColor: AppColors.warning,
                            title: isAr ? 'الإشعارات' : 'Notifications',
                            badge: unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.cobalt,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsCenterScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            key: const ValueKey('account_help_support_tile'),
                            icon: Icons.support_agent_rounded,
                            iconBg: AppColors.emeraldSurface,
                            iconColor: AppColors.emerald,
                            title: isAr ? 'المساعدة والدعم' : 'Help & Support',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const HelpSupportScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            key: const ValueKey('account_settings_tile'),
                            icon: Icons.settings_outlined,
                            iconBg: AppColors.slateBg,
                            iconColor: AppColors.navy,
                            title: isAr
                                ? 'الإعدادات واللغة'
                                : 'Settings & Language',
                            trailingText: isAr ? 'العربية' : 'English',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                          _buildMenuItem(
                            icon: Icons.gavel_outlined,
                            iconBg: AppColors.slateBg,
                            iconColor: AppColors.navy,
                            title: isAr
                                ? 'الشروط القانونية والخصوصية'
                                : 'Legal Terms & Privacy',
                            onTap: () =>
                                _showPilotLegalDisclaimersSheet(context, isAr),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Platform Scope Disclosure Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Text(
                        AppEnvironment.pilotScopeDisclaimer(isArabic: isAr),
                        style: AppTypography.bodySmall(
                            color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 22),

                    MashwarButton(
                      key: const ValueKey('mvp_logout_btn'),
                      text: isAr ? 'تسجيل الخروج' : 'Log Out',
                      variant: MashwarButtonVariant.danger,
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        await auth.logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title(color: AppColors.navy)
              .copyWith(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.label(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 28, color: AppColors.slateBorder);
  }

  Widget _buildMenuItem({
    Key? key,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Widget? badge,
    String? trailingText,
  }) {
    return ListTile(
      key: key,
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: AppTypography.body().copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            badge,
            const SizedBox(width: 6),
          ],
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: AppTypography.label(color: AppColors.cobalt)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTrustChip(MashwarTrustType type, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarTrustEmblem(type: type, size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.navy).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPilotLegalDisclaimersSheet(BuildContext context, bool isAr) {
    final notices = AppEnvironment.allLegalDisclaimers(isArabic: isAr);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isAr
                        ? 'الشروط القانونية والإفصاحات التنظيمية'
                        : 'Platform Scope & Legal Disclosures',
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...notices.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Text(
                          n,
                          style: AppTypography.bodySmall(color: AppColors.navy),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MashwarButton(
                    text: isAr
                        ? 'عرض سياسة الخصوصية والشروط الكاملة'
                        : 'Open Full Legal & Privacy Terms',
                    variant: MashwarButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalComplianceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
