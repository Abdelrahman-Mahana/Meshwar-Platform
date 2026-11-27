import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/worksite_models.dart';
import '../../state/admin_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/board_provider.dart';
import '../../state/parcels_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/worksite_provider.dart';
import '../account/account_extra_screens.dart';
import '../driver/publish_ride_screen.dart';
import '../escrow/service_escrow_screen.dart';
import '../parcel/send_parcel_screen.dart';
import '../ride_details/ride_details_screen.dart';
import '../trips/trips_and_parcels_hub_screen.dart';
import '../worksite/create_work_request_screen.dart';
import '../worksite/provider_profile_screen.dart';
import '../worksite/work_request_details_screen.dart';
import '../worksite/work_requests_feed_screen.dart';
import 'city_search_modal.dart';

/// Flagship 3-Service Home Screen for MASHWAR in the official brand palette
/// (`Navy #0F2A43` · `Teal #1B7F79` · `Gold #F5A524` · `Sand #FAF7F0`):
/// - Top 3-Icon Studio Service Launcher (`رحلة ومقاعد` · `طرد مع مسافر` · `شراء وتوريد`)
///   + Smart Origin/Destination Route Search
/// - Full-frame, natural-aspect, non-repeating photography (`0` duplicate images,
///   `0` dark overlay cropping)
/// - Bidirectional 3 Core Services, 3-Step Visual Journey, Live Travelers,
///   Quick Supply Categories, Active Requests & Interactive Corridor Map.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedHeroMode = 0; // 0 = Trips, 1 = Parcels, 2 = Supply & Tasks
  double _swapTurns = 0.0;
  bool _isMapExpanded = false;

  String? _selectedSavedWorksiteId;
  String? _previewHubCity;
  bool _didAttemptInitialLoad = false;
  WorksiteProvider? _lastInitializedWorksite;

  WorksiteProvider? _fallbackWorksiteProvider;
  RidesProvider? _fallbackRidesProvider;
  BoardProvider? _fallbackBoardProvider;
  ParcelsProvider? _fallbackParcelsProvider;

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

  BoardProvider _resolveBoard(BuildContext context) {
    final provided = context.watch<BoardProvider?>();
    if (provided != null) return provided;
    return _fallbackBoardProvider ??= BoardProvider();
  }

  ParcelsProvider _resolveParcels(BuildContext context) {
    final provided = context.watch<ParcelsProvider?>();
    if (provided != null) return provided;
    return _fallbackParcelsProvider ??= ParcelsProvider();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAttemptInitialLoad) return;
      _didAttemptInitialLoad = true;

      final auth = context.read<AuthProvider?>();
      final rides = context.read<RidesProvider?>() ?? _fallbackRidesProvider;
      final board = context.read<BoardProvider?>() ?? _fallbackBoardProvider;
      final parcels =
          context.read<ParcelsProvider?>() ?? _fallbackParcelsProvider;
      final ws = context.read<WorksiteProvider?>() ?? _fallbackWorksiteProvider;

      rides?.loadRides();
      board?.loadBoardAds();
      parcels?.loadParcels();

      if (ws != null) {
        _lastInitializedWorksite = ws;
        if (ws.allLoadedRequests.isEmpty && !ws.isLoading && !ws.hasError) {
          ws.loadRequests();
        }
        if (ws.notifications.isEmpty) {
          ws.loadNotifications();
        }
        final uid = ws.currentUserId ?? auth?.user.id ?? '';
        if (uid.isNotEmpty && ws.savedWorksites.isEmpty) {
          ws.loadSavedWorksites(uid);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = Provider.of<WorksiteProvider?>(context, listen: false);
    if (ws != null && ws != _lastInitializedWorksite) {
      _lastInitializedWorksite = ws;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ws.allLoadedRequests.isEmpty && !ws.isLoading && !ws.hasError) {
          ws.loadRequests();
        }
      });
    }
  }

  @override
  void dispose() {
    _fallbackWorksiteProvider?.dispose();
    _fallbackRidesProvider?.dispose();
    _fallbackBoardProvider?.dispose();
    _fallbackParcelsProvider?.dispose();
    super.dispose();
  }

  Future<void> _pickHeroCity({
    required BuildContext context,
    required RidesProvider rides,
    required BoardProvider board,
    required bool isFrom,
    required bool isAr,
  }) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CitySearchModal(
          title: isFrom
              ? (isAr ? 'نقطة الانطلاق' : 'Origin City')
              : (isAr ? 'الوجهة المطلوبة' : 'Destination City'),
          initialValue: isFrom ? rides.fromCity : rides.toCity,
        ),
      ),
    );
    if (selected != null && mounted) {
      if (isFrom) {
        rides.setRoute(from: selected);
        board.setRouteFilter(from: selected);
      } else {
        rides.setRoute(to: selected);
        board.setRouteFilter(to: selected);
      }
    }
  }

  void _triggerHeroAction({
    required BuildContext context,
    required RidesProvider rides,
    required BoardProvider board,
    required SavedWorksite? activeSite,
  }) {
    final from = rides.fromCity.trim();
    final to = rides.toCity.trim();
    if (_selectedHeroMode == 0) {
      rides.searchCorridor(from: from, to: to);
      board.setRouteFilter(from: from, to: to);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TripsAndParcelsHubScreen(initialTabIndex: 0),
        ),
      );
    } else if (_selectedHeroMode == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SendParcelScreen(
            initialFromCity: from.isNotEmpty ? from : null,
            initialToCity: to.isNotEmpty ? to : null,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateWorkRequestScreen(
            initialSavedWorksite: activeSite,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final worksite = _resolveWorksite(context, auth);
    final rides = _resolveRides(context);
    final board = _resolveBoard(context);
    final parcels = _resolveParcels(context);
    final admin = context.watch<AdminProvider?>();
    final isAr = context.isArabic;

    final savedSites = worksite.savedWorksites;
    SavedWorksite? activeSite;
    if (savedSites.isNotEmpty) {
      activeSite = savedSites.firstWhere(
        (s) => s.id == _selectedSavedWorksiteId,
        orElse: () => savedSites.firstWhere(
          (s) => s.isDefault,
          orElse: () => savedSites.first,
        ),
      );
    }

    final uid = worksite.currentUserId ??
        (auth.user.id.isNotEmpty ? auth.user.id : null);
    final allLoaded = worksite.allLoadedRequests;
    final activeSupplyCount = allLoaded
        .where((r) => !WorkRequestStatusMachine.isTerminal(r.status))
        .length;
    final myRecent = uid == null
        ? const <WorkRequest>[]
        : allLoaded
            .where((r) => r.requesterId == uid || r.assignedProviderId == uid)
            .toList();
    final recentToShow =
        (myRecent.isNotEmpty ? myRecent : allLoaded).take(3).toList();
    final topTrips = rides.filteredRides.take(3).toList();

    final unreadNotifications =
        worksite.notifications.where((n) => !n.isRead).toList();
    final unreadCount = worksite.unreadNotificationsCount;
    final openOffersCount = uid == null
        ? 0
        : allLoaded
            .where((r) =>
                r.requesterId == uid &&
                r.status == WorkRequestStatus.offerReceived)
            .fold<int>(0, (sum, r) => sum + r.offerCount);

    final firstName = auth.user.fullName.trim().isNotEmpty
        ? auth.user.fullName.trim().split(' ').first
        : (isAr ? 'بك' : 'Member');

    final corridorFrom = rides.fromCity.trim().isNotEmpty
        ? rides.fromCity.trim()
        : (activeSite?.municipality ?? 'الدوحة');
    final previewHub = _previewHubCity ??
        (rides.toCity.trim().isNotEmpty ? rides.toCity.trim() : 'لوسيل');

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final isDesktopThreeCol = constraints.maxWidth >= 960;
            final isMedium = constraints.maxWidth >= 680;
            final isUltraCompact = constraints.maxWidth < 360;
            final hPad = isWide
                ? AppDimens.space32
                : (isUltraCompact ? 12.0 : AppDimens.space20);

            return RefreshIndicator(
              color: AppColors.navy,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await Future.wait([
                  rides.loadRides(),
                  board.loadBoardAds(),
                  parcels.loadParcels(),
                  worksite.loadRequests(),
                  worksite.loadNotifications(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: AppDimens.space16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: isWide ? 1160 : 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (admin != null &&
                            admin.broadcastBanner.isEnabled) ...[
                          _buildBroadcastBanner(admin, isAr),
                          const SizedBox(height: 12),
                        ],

                        // 1. Top Classic MASHWAR Brand Header
                        _buildTopBrandHeader(
                          context: context,
                          auth: auth,
                          worksite: worksite,
                          activeSite: activeSite,
                          firstName: firstName,
                          unreadCount: unreadCount,
                          isAr: isAr,
                          isUltraCompact: isUltraCompact,
                        ),
                        const SizedBox(height: 14),

                        // 2. FIRST FOCAL SECTION: "إلى أين مشوارك أو طلبك اليوم؟"
                        //    3 Full-Frame 3D Studio Service Icons + Smart Route Search
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 260),
                          offsetY: 10,
                          child: _buildHeroThreeIconsLauncherCard(
                            context: context,
                            rides: rides,
                            board: board,
                            worksite: worksite,
                            activeSite: activeSite,
                            activeTripsCount: rides.allRides.length,
                            activeSupplyCount: activeSupplyCount,
                            isAr: isAr,
                            isWide: isWide,
                            isUltraCompact: isUltraCompact,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 3. Full-Size 16:9 Traveler & Corridor Panorama Banner
                        //    (`home_hero_mobility.jpg` — used ONCE, 100% uncropped)
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 300),
                          offsetY: 12,
                          child: _buildFullSizeMobilityPanoramaCard(
                            context: context,
                            isAr: isAr,
                            isMedium: isMedium,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. Three Core Services Showcase (3 Unique 16:9 Photos,
                        //    Full Aspect Ratio, Zero Cropping, Zero Overlay Text)
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 330),
                          offsetY: 12,
                          child: _buildThreeServicesShowcase(
                            context: context,
                            activeSite: activeSite,
                            isAr: isAr,
                            isDesktopThreeCol: isDesktopThreeCol,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 5. "How MASHWAR Works in 3 Steps" + Bilateral Trust Card
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 350),
                          offsetY: 10,
                          child: _buildHowItWorksAndTrustSection(
                            context: context,
                            isAr: isAr,
                            isMedium: isMedium,
                            isUltraCompact: isUltraCompact,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 6. Live Available Travelers (Seats + Parcel Space)
                        _buildAvailableTravelersSection(
                          context: context,
                          topTrips: topTrips,
                          isLoading: rides.isLoading,
                          isAr: isAr,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 22),

                        // 7. Quick Supply Categories Card with Full 4:3 Photo
                        //    (`cat_tools_ppe.jpg` — used ONCE, 100% uncropped)
                        _buildQuickSupplyCategoriesCard(
                          context: context,
                          activeSite: activeSite,
                          isAr: isAr,
                          isMedium: isMedium,
                        ),
                        const SizedBox(height: 18),

                        // 8. Real Notifications Summary Strip
                        _buildNotificationsSummaryStrip(
                          context: context,
                          unreadNotifications: unreadNotifications,
                          unreadCount: unreadCount,
                          openOffersCount: openOffersCount,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 22),

                        // 9. Active Supply & Route Requests
                        _buildRecentSupplyRequestsSection(
                          context: context,
                          worksite: worksite,
                          recentToShow: recentToShow,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 20),

                        // 10. Clean Collapsible Interactive Corridor Map
                        _buildCollapsibleCorridorMapCard(
                          context: context,
                          rides: rides,
                          corridorFrom: corridorFrom,
                          previewHub: previewHub,
                          isAr: isAr,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBroadcastBanner(AdminProvider admin, bool isAr) {
    final isWarning = admin.broadcastBanner.severity == 'warning';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.goldSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? AppColors.gold.withValues(alpha: 0.45)
              : AppColors.slateBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 18,
            color: isWarning ? AppColors.goldDark : AppColors.navy,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr
                  ? admin.broadcastBanner.messageAr
                  : admin.broadcastBanner.messageEn,
              style: AppTypography.body(color: AppColors.navy).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBrandHeader({
    required BuildContext context,
    required AuthProvider auth,
    required WorksiteProvider worksite,
    required SavedWorksite? activeSite,
    required String firstName,
    required int unreadCount,
    required bool isAr,
    required bool isUltraCompact,
  }) {
    final greetingText = auth.user.fullName.trim().isNotEmpty
        ? (isAr ? 'أهلاً بك، $firstName' : 'Welcome, $firstName')
        : (isAr ? 'أهلاً بك في مشوار' : 'Welcome to MASHWAR');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isUltraCompact ? 12 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BrandLogo(
                  fontSize: isUltraCompact ? 22 : 25,
                  showEnglish: !isUltraCompact,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          greetingText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.body(color: AppColors.navy).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isUltraCompact ? 12 : 13,
                          ),
                        ),
                      ),
                      if (auth.user.isVerified ||
                          worksite.isApprovedProvider) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: AppColors.teal,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('home_notifications_bell_btn'),
                tooltip: isAr ? 'الإشعارات' : 'Notifications',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsCenterScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.slateBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Icon(
                        unreadCount > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: AppColors.navy,
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      PositionedDirectional(
                        top: -3,
                        end: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.4),
                          ),
                          constraints: const BoxConstraints(minWidth: 17),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                key: const ValueKey('home_profile_avatar_btn'),
                customBorder: const CircleBorder(),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UserProfileScreen(),
                    ),
                  );
                },
                child: MashwarUserAvatar(
                  avatarUrl: auth.user.avatarUrl,
                  fullName: auth.user.fullName.isNotEmpty
                      ? auth.user.fullName
                      : 'م',
                  size: isUltraCompact ? 38 : 42,
                  borderWidth: 1.5,
                  borderColor: AppColors.slateBorder,
                  backgroundColor: AppColors.navy,
                  initialColor: Colors.white,
                  showVerifiedBadge:
                      auth.user.isVerified || worksite.isApprovedProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 2 — First Focal Section:
  /// "إلى أين مشوارك أو طلبك اليوم؟" featuring 3 large, uncropped studio icons
  /// (`service_ride.jpg`, `service_parcel.jpg`, `service_errand.jpg` via `BoxFit.contain`)
  /// + integrated Origin/Destination smart route search bar.
  Widget _buildHeroThreeIconsLauncherCard({
    required BuildContext context,
    required RidesProvider rides,
    required BoardProvider board,
    required WorksiteProvider worksite,
    required SavedWorksite? activeSite,
    required int activeTripsCount,
    required int activeSupplyCount,
    required bool isAr,
    required bool isWide,
    required bool isUltraCompact,
  }) {
    final launcherModes = <({
      int index,
      Key key,
      String title,
      String badge,
      String studioAsset,
      IconData fallbackIcon,
    })>[
      (
        index: 0,
        key: const ValueKey('home_hero_mode_trips'),
        title: isAr ? 'رحلة ومقاعد' : 'Shared Trips',
        badge: isAr ? 'مقاعد شاغرة' : 'Empty Seats',
        studioAsset: 'assets/images/service_ride.jpg',
        fallbackIcon: Icons.directions_car_filled_rounded,
      ),
      (
        index: 1,
        key: const ValueKey('home_hero_mode_parcels'),
        title: isAr ? 'طرد مع مسافر' : 'Send Parcel',
        badge: isAr ? 'في نفس الطريق' : 'On the Way',
        studioAsset: 'assets/images/service_parcel.jpg',
        fallbackIcon: Icons.inventory_2_rounded,
      ),
      (
        index: 2,
        key: const ValueKey('home_hero_mode_supply'),
        title: isAr ? 'شراء وتوريد' : 'Supply & Tasks',
        badge: isAr ? 'بفاتورة موثّقة' : 'With Receipt',
        studioAsset: 'assets/images/service_errand.jpg',
        fallbackIcon: Icons.shopping_bag_rounded,
      ),
    ];

    final heroButtonLabel = _selectedHeroMode == 0
        ? (isAr ? 'ابحث عن الرحلات والمقاعد' : 'Search Available Trips')
        : (_selectedHeroMode == 1
            ? (isAr ? 'ابدأ إرسال طرد على الطريق' : 'Send Parcel on Route')
            : (isAr ? 'ابدأ طلب شراء أو توريد' : 'Start Supply Request'));

    final fromDisplay = rides.fromCity.trim().isNotEmpty
        ? context.trCity(rides.fromCity)
        : (isAr ? 'من أين؟ (نقطة الانطلاق)' : 'From where? (Origin)');
    final toDisplay = rides.toCity.trim().isNotEmpty
        ? context.trCity(rides.toCity)
        : (isAr ? 'إلى أين؟ (الوجهة المطلوبة)' : 'Where to? (Destination)');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slateBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isUltraCompact ? 14 : (isWide ? 24 : 18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Status & Saved Location Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MashwarLivePulseDot(
                      color: AppColors.teal,
                      size: 7.0,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isAr
                            ? '$activeTripsCount رحلة متاحة · $activeSupplyCount طلب نشط'
                            : '$activeTripsCount Trips · $activeSupplyCount Open Requests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: AppColors.tealDark)
                            .copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                key: const ValueKey('home_saved_worksite_chip'),
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    _showSavedWorksitePicker(context, worksite, isAr),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bookmark_border_rounded,
                        size: 15,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activeSite != null
                              ? activeSite.label
                              : (isAr ? 'المواقع المحفوظة' : 'Saved Spots'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Headline & Concise 1-Line Subtitle
          Text(
            isAr
                ? 'إلى أين مشوارك أو طلبك اليوم؟'
                : 'Where does your journey take you today?',
            style: AppTypography.largeTitle(color: AppColors.navy).copyWith(
              fontSize: isUltraCompact ? 18.5 : (isWide ? 23 : 20.5),
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'اختر الخدمة وحدّد مسارك للوصول الفوري إلى المسافرين والمزودين'
                : 'Select a service and enter your route to connect right away',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySecondary(color: AppColors.textSecondary)
                .copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // THE 3 STUDIO ICON TILES (100% Uncropped 1:1 Studio Art via BoxFit.contain)
          Row(
            key: const ValueKey('home_hero_three_icons_row'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < launcherModes.length; i++) ...[
                Expanded(
                  child: _buildHeroStudioIconTile(
                    mode: launcherModes[i],
                    selected: _selectedHeroMode == launcherModes[i].index,
                    isWide: isWide,
                    isUltraCompact: isUltraCompact,
                    onTap: () => setState(
                      () => _selectedHeroMode = launcherModes[i].index,
                    ),
                  ),
                ),
                if (i < launcherModes.length - 1)
                  SizedBox(width: isUltraCompact ? 6 : (isWide ? 14 : 10)),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Integrated Warm-Sand Route Search Container (`من أين -> إلى أين`)
          Container(
            padding: EdgeInsets.all(isUltraCompact ? 10 : 14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide)
                  Row(
                    children: [
                      Expanded(
                        child: _buildRouteFieldTile(
                          key: const ValueKey('home_hero_from_field'),
                          label: isAr ? 'من أين' : 'Origin',
                          value: fromDisplay,
                          hasValue: rides.fromCity.trim().isNotEmpty,
                          dotColor: AppColors.teal,
                          onTap: () => _pickHeroCity(
                            context: context,
                            rides: rides,
                            board: board,
                            isFrom: true,
                            isAr: isAr,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSwapButton(rides, board, isAr),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRouteFieldTile(
                          key: const ValueKey('home_hero_to_field'),
                          label: isAr ? 'إلى أين' : 'Destination',
                          value: toDisplay,
                          hasValue: rides.toCity.trim().isNotEmpty,
                          dotColor: AppColors.gold,
                          onTap: () => _pickHeroCity(
                            context: context,
                            rides: rides,
                            board: board,
                            isFrom: false,
                            isAr: isAr,
                          ),
                        ),
                      ),
                      if (rides.hasCorridorQuery) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          key: const ValueKey('home_hero_clear_route_btn'),
                          tooltip: isAr ? 'مسح المسار' : 'Clear route',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            rides.clearRoute();
                            board.clearRouteFilter();
                          },
                        ),
                      ],
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 245,
                        child: MashwarButton(
                          key: const ValueKey('home_hero_action_btn'),
                          text: heroButtonLabel,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _triggerHeroAction(
                            context: context,
                            rides: rides,
                            board: board,
                            activeSite: activeSite,
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Stack(
                    alignment: AlignmentDirectional.centerEnd,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRouteFieldTile(
                            key: const ValueKey('home_hero_from_field'),
                            label: isAr ? 'من أين' : 'Origin',
                            value: fromDisplay,
                            hasValue: rides.fromCity.trim().isNotEmpty,
                            dotColor: AppColors.teal,
                            onTap: () => _pickHeroCity(
                              context: context,
                              rides: rides,
                              board: board,
                              isFrom: true,
                              isAr: isAr,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRouteFieldTile(
                            key: const ValueKey('home_hero_to_field'),
                            label: isAr ? 'إلى أين' : 'Destination',
                            value: toDisplay,
                            hasValue: rides.toCity.trim().isNotEmpty,
                            dotColor: AppColors.gold,
                            onTap: () => _pickHeroCity(
                              context: context,
                              rides: rides,
                              board: board,
                              isFrom: false,
                              isAr: isAr,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: _buildSwapButton(rides, board, isAr),
                      ),
                    ],
                  ),
                  if (rides.hasCorridorQuery)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        key: const ValueKey('home_hero_clear_route_btn'),
                        onPressed: () {
                          rides.clearRoute();
                          board.clearRouteFilter();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        label: Text(
                          isAr ? 'مسح المسار' : 'Clear route',
                          style:
                              AppTypography.label(color: AppColors.textSecondary)
                                  .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  MashwarButton(
                    key: const ValueKey('home_hero_action_btn'),
                    text: heroButtonLabel,
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    onPressed: () => _triggerHeroAction(
                      context: context,
                      rides: rides,
                      board: board,
                      activeSite: activeSite,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStudioIconTile({
    required ({
      int index,
      Key key,
      String title,
      String badge,
      String studioAsset,
      IconData fallbackIcon,
    }) mode,
    required bool selected,
    required bool isWide,
    required bool isUltraCompact,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: mode.key,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 6 : 10,
            vertical: isUltraCompact ? 8 : 11,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.slateBg : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.slateBorder,
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pure-white studio stage holding the full 1:1 3D icon with ZERO crop
              Container(
                width: double.infinity,
                height: isWide ? 92 : (isUltraCompact ? 60 : 74),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected
                        ? AppColors.slateBorder
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        mode.studioAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => Icon(
                          mode.fallbackIcon,
                          size: 32,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (selected)
                      PositionedDirectional(
                        top: 2,
                        end: 2,
                        child: Container(
                          width: 19,
                          height: 19,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mode.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isUltraCompact ? 11.5 : (isWide ? 14.5 : 13.5),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.tealSurface : AppColors.slateBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mode.badge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    color: selected
                        ? AppColors.tealDark
                        : AppColors.textSecondary,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isUltraCompact ? 10.0 : 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteFieldTile({
    required Key key,
    required String label,
    required String value,
    required bool hasValue,
    required Color dotColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasValue
                  ? AppColors.navy.withValues(alpha: 0.25)
                  : AppColors.slateBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(
                        color: AppColors.textSecondary,
                      ).copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        color: hasValue
                            ? AppColors.navy
                            : AppColors.textSecondary,
                      ).copyWith(
                        fontWeight:
                            hasValue ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
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

  Widget _buildSwapButton(
    RidesProvider rides,
    BoardProvider board,
    bool isAr,
  ) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.slateBorder, width: 1.0),
      ),
      elevation: 1,
      shadowColor: AppColors.navy.withValues(alpha: 0.08),
      child: InkWell(
        key: const ValueKey('home_route_swap_btn'),
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() => _swapTurns += 0.5);
          rides.swapLocations();
          board.setRouteFilter(from: rides.fromCity, to: rides.toCity);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedRotation(
            turns: _swapTurns,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: const Icon(
              Icons.swap_vert_rounded,
              size: 18,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }

  /// Section 3 — Full-Size `16:9` Mobility & Traveler Earnings Panorama Card:
  /// Renders `assets/images/home_hero_mobility.jpg` (`1376x768`) at its exact
  /// native `1376 / 768` ratio with ZERO dark overlay or cropping.
  Widget _buildFullSizeMobilityPanoramaCard({
    required BuildContext context,
    required bool isAr,
    required bool isMedium,
  }) {
    final fullImage = AspectRatio(
      aspectRatio: 1376 / 768,
      child: Image.asset(
        'assets/images/home_hero_mobility.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.slateBg,
          child: const Center(
            child: Icon(
              Icons.directions_car_rounded,
              color: AppColors.navy,
              size: 40,
            ),
          ),
        ),
      ),
    );

    final copyPanel = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isAr ? 'مسافر بسيارتك الخاصة؟' : 'Driving Along Your Route?',
              style: AppTypography.label(color: AppColors.tealDark).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'شارك مقاعدك الفارغة أو وصّل طرداً خفيفاً معك في نفس الطريق'
                : 'Share Your Empty Seats or Carry a Verified Parcel Along the Way',
            style: AppTypography.title(color: AppColors.navy).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'انشر وجهتك في أقل من دقيقة واستقبل حجوزات المقاعد والطرود الموثّقة.'
                : 'Publish your departure in under a minute and offset travel costs safely.',
            style: AppTypography.bodySecondary(color: AppColors.textSecondary)
                .copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PublishRideScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_road_rounded,
                  size: 17,
                  color: Colors.white,
                ),
                label: Text(
                  isAr ? 'انشر رحلتك الآن' : 'Publish Your Trip',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.slateBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const TripsAndParcelsHubScreen(initialTabIndex: 1),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.campaign_outlined,
                  size: 17,
                  color: AppColors.navy,
                ),
                label: Text(
                  isAr ? 'طلبات المسافرين والطرود' : 'Route Requests',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slateBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: isMedium
          ? Row(
              children: [
                Expanded(flex: 6, child: copyPanel),
                Expanded(flex: 5, child: fullImage),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fullImage,
                copyPanel,
              ],
            ),
    );
  }

  /// Section 4 — 3 Core Services Showcase:
  /// Each card uses a 100% unique `1376x768` (`16:9`) photograph rendered at
  /// its exact native aspect ratio (`1376 / 768`) with ZERO dark overlay.
  Widget _buildThreeServicesShowcase({
    required BuildContext context,
    required SavedWorksite? activeSite,
    required bool isAr,
    required bool isDesktopThreeCol,
  }) {
    final cards = <Widget>[
      // Pillar 1: Shared Trips & Empty Seats (`pillar_shared_trips.jpg` — unique!)
      _buildServicePillarCard(
        pillar: MashwarServicePillar.sharedTrips,
        imageAsset: 'assets/images/pillar_shared_trips.jpg',
        badgeLabel: isAr ? 'مقاعد تشاركية' : 'Shared Seats',
        badgeBg: AppColors.slateBg,
        badgeFg: AppColors.navy,
        title: isAr ? 'سفر ومقاعد تشاركية' : 'Shared Trips & Empty Seats',
        benefit: isAr
            ? 'شارك مقاعد سيارتك الشاغرة أو احجز مقعداً مريحاً مع مسافر موثّق.'
            : 'Share empty seats along your route or book a seat with verified travelers.',
        primaryKey: const ValueKey('home_publish_trip_cta'),
        primaryLabel: isAr
            ? 'انشر رحلتك (مقاعد شاغرة)'
            : 'Publish Trip (Empty Seats)',
        primaryIcon: Icons.add_road_rounded,
        onPrimary: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PublishRideScreen()),
          );
        },
        secondaryKey: const ValueKey('home_find_trip_cta'),
        secondaryLabel:
            isAr ? 'اطلب أو ابحث عن مقعد' : 'Find or Request a Seat',
        secondaryIcon: Icons.airline_seat_recline_normal_rounded,
        onSecondary: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const TripsAndParcelsHubScreen(initialTabIndex: 0),
            ),
          );
        },
      ),

      // Pillar 2: Parcels & Items on the Way (`pillar_route_parcels.jpg` — unique!)
      _buildServicePillarCard(
        pillar: MashwarServicePillar.routeParcels,
        imageAsset: 'assets/images/pillar_route_parcels.jpg',
        badgeLabel: isAr ? 'تأكيد بكود OTP' : 'Dual OTP Safe',
        badgeBg: AppColors.tealSurface,
        badgeFg: AppColors.tealDark,
        title: isAr ? 'طرود وأغراض مع مسافر' : 'Parcels & Items on the Way',
        benefit: isAr
            ? 'أرسل الطرود والمستندات بسرعة مع مسافر متجه لنفس الوجهة بتأكيد OTP.'
            : 'Send documents and packages faster with travelers heading your way.',
        primaryKey: const ValueKey('home_send_parcel_cta'),
        primaryLabel:
            isAr ? 'أرسل طرداً مع مسافر' : 'Send Parcel with Traveler',
        primaryIcon: Icons.local_shipping_outlined,
        onPrimary: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SendParcelScreen()),
          );
        },
        secondaryKey: const ValueKey('home_browse_parcels_cta'),
        secondaryLabel:
            isAr ? 'طلبات الطرود في طريقك' : 'Parcel Requests on Route',
        secondaryIcon: Icons.inventory_2_outlined,
        onSecondary: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TripsAndParcelsHubScreen(
                initialTabIndex: 1,
                initialRequestFilter: 2,
              ),
            ),
          );
        },
      ),

      // Pillar 3: Smart Shopping, Supply & Tasks (`pillar_smart_supply.jpg` — unique!)
      _buildServicePillarCard(
        pillar: MashwarServicePillar.smartSupply,
        imageAsset: 'assets/images/pillar_smart_supply.jpg',
        badgeLabel: isAr ? 'فاتورة موثّقة' : 'Verified Receipt',
        badgeBg: AppColors.tealSurface,
        badgeFg: AppColors.tealDark,
        title: isAr ? 'شراء وتوريد ومهام خاصة' : 'Smart Shopping & Supply',
        benefit: isAr
            ? 'اطلب شراء وتوريد المواد والطلبات الخاصة بفاتورة موثّقة ورمز تسليم.'
            : 'Coordinate hardware, site materials, and custom errands with verified receipts.',
        primaryKey: const ValueKey('home_create_request_cta'),
        primaryLabel: isAr ? 'إنشاء طلب توريد' : 'Create a Request',
        primaryIcon: Icons.add_task_rounded,
        onPrimary: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateWorkRequestScreen(
                initialSavedWorksite: activeSite,
              ),
            ),
          );
        },
        secondaryKey: const ValueKey('home_browse_requests_cta'),
        secondaryLabel:
            isAr ? 'تصفح الطلبات المتاحة' : 'Browse Available Requests',
        secondaryIcon: Icons.fact_check_outlined,
        onSecondary: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WorkRequestsFeedScreen(),
            ),
          );
        },
      ),
    ];

    return Column(
      key: const ValueKey('home_three_services_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isAr ? 'خدمات مشوار الأساسية' : 'Core MASHWAR Services',
                    style: AppTypography.title(color: AppColors.navy).copyWith(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Text(
                isAr
                    ? 'اطلب أو نفّذ في طريقك'
                    : 'Request or Earn on Route',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.textSecondary)
                    .copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isDesktopThreeCol)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cards[0],
              const SizedBox(height: 16),
              cards[1],
              const SizedBox(height: 16),
              cards[2],
            ],
          ),
      ],
    );
  }

  Widget _buildServicePillarCard({
    required MashwarServicePillar pillar,
    required String imageAsset,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeFg,
    required String title,
    required String benefit,
    required Key primaryKey,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onPrimary,
    required Key secondaryKey,
    required String secondaryLabel,
    required IconData secondaryIcon,
    required VoidCallback onSecondary,
  }) {
    return MashwarHoverCard(
      borderRadius: BorderRadius.circular(20),
      backgroundColor: Colors.white,
      borderColor: AppColors.slateBorder,
      hoverBorderColor: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full-size 16:9 (`1376x768`) natural photograph — ZERO dark overlay, ZERO cropping!
          AspectRatio(
            aspectRatio: 1376 / 768,
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.slateBg,
                child: Center(
                  child: Icon(primaryIcon, size: 38, color: AppColors.navy),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MashwarServicePillarIcon(
                      pillar: pillar,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title(color: AppColors.navy)
                            .copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.label(color: badgeFg).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  benefit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySecondary(
                    color: AppColors.textSecondary,
                  ).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    key: primaryKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon, size: 17, color: Colors.white),
                    label: Text(
                      primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    key: secondaryKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.slateBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 16, color: AppColors.navy),
                    label: Text(
                      secondaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: AppColors.navy,
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
    );
  }

  /// Section 5 — "How MASHWAR Works in 3 Steps" + Bilateral Escrow/OTP Shield
  /// (`escrow_trust_shield.jpg` rendered at 1:1 `BoxFit.contain`, used ONCE).
  Widget _buildHowItWorksAndTrustSection({
    required BuildContext context,
    required bool isAr,
    required bool isMedium,
    required bool isUltraCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MashwarThreeStepsBanner(
          isAr: isAr,
          compact: isUltraCompact,
        ),
        const SizedBox(height: 14),
        MashwarHoverCard(
          borderRadius: BorderRadius.circular(18),
          backgroundColor: Colors.white,
          borderColor: AppColors.slateBorder,
          hoverBorderColor: AppColors.teal,
          padding: const EdgeInsets.all(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ServiceEscrowScreen(),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: isMedium ? 74 : 60,
                height: isMedium ? 74 : 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Image.asset(
                  'assets/images/escrow_trust_shield.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.teal,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'حماية مزدوجة بكود الأمان OTP واعتماد الفواتير'
                          : 'Bilateral OTP Handover & Verified Receipt Protection',
                      style: AppTypography.body(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'توثيق الهوية، تأكيد الاستلام والتسليم بكود سري، واعتماد الفواتير.'
                          : 'Verified profiles, dual pickup/delivery OTP codes, and transparent receipts.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary(
                        color: AppColors.textSecondary,
                      ).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableTravelersSection({
    required BuildContext context,
    required List<RideModel> topTrips,
    required bool isLoading,
    required bool isAr,
    required bool isWide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'مسافرون متاحون الآن (مقاعد ومساحة طرود)'
                          : 'Available Travelers (Seats & Parcel Space)',
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const TripsAndParcelsHubScreen(initialTabIndex: 0),
                  ),
                );
              },
              child: Text(
                isAr ? 'كل الرحلات' : 'See All Trips',
                style: AppTypography.label(color: AppColors.navy).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading && topTrips.isEmpty)
          const MashwarShimmerBox(height: 110, borderRadius: 16)
        else if (topTrips.isEmpty)
          MashwarSectionCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: Colors.white,
            borderColor: AppColors.slateBorder,
            child: Column(
              children: [
                Text(
                  isAr
                      ? 'لا توجد رحلات مطابقة لهذا المسار حالياً — يمكنك نشر رحلتك أو طلب مقعد/طرد على الطريق.'
                      : 'No matching trips for this corridor right now — publish your trip or post a route request.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(
                    color: AppColors.textSecondary,
                  ).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.slateBorder),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const TripsAndParcelsHubScreen(initialTabIndex: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.campaign_outlined, size: 17),
                  label: Text(
                    isAr ? 'استعرض طلبات المسار' : 'Browse Route Requests',
                  ),
                ),
              ],
            ),
          )
        else
          ...topTrips.map((ride) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MashwarHoverCard(
                key: ValueKey('home_live_trip_${ride.id}'),
                borderRadius: BorderRadius.circular(18),
                backgroundColor: Colors.white,
                borderColor: AppColors.slateBorder,
                hoverBorderColor: AppColors.navy,
                padding: const EdgeInsets.all(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RideDetailsScreen(ride: ride),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MashwarUserAvatar(
                              avatarUrl: null,
                              fullName: ride.driverName,
                              size: 36,
                              borderWidth: 1.2,
                              borderColor: AppColors.slateBorder,
                              autoCommunityPortrait: true,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${ride.driverName} · ${ride.driverRating.toStringAsFixed(1)} ★',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body(color: AppColors.navy)
                                    .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (ride.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: AppColors.teal,
                              ),
                            ],
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.slateBg,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppColors.slateBorder),
                              ),
                              child: Text(
                                isAr
                                    ? '${ride.remainingSeats} مقاعد شاغرة'
                                    : '${ride.remainingSeats} empty seats',
                                style: AppTypography.label(
                                        color: AppColors.navy)
                                    .copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (ride.acceptsParcels)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.tealSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAr ? 'يقبل طرود' : 'Accepts Parcels',
                                  style: AppTypography.label(
                                          color: AppColors.tealDark)
                                      .copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MashwarRouteTimeline(
                      from: context.trCity(ride.fromCity),
                      to: context.trCity(ride.toCity),
                      trailingTop:
                          '${ride.departureDate} · ${ride.departureTime}',
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          isAr
                              ? '${ride.pricePerSeat} ر.ق / مقعد${ride.acceptsParcels ? " · طرد ${ride.parcelPrice} ر.ق" : ""}'
                              : '${ride.pricePerSeat} QAR / seat${ride.acceptsParcels ? " · Parcel ${ride.parcelPrice} QAR" : ""}',
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ElevatedButton(
                              key: ValueKey('home_book_trip_${ride.id}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RideDetailsScreen(ride: ride),
                                  ),
                                );
                              },
                              child: Text(
                                isAr ? 'حجز مقعد' : 'Book Seat',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            if (ride.acceptsParcels)
                              OutlinedButton.icon(
                                key: ValueKey('home_trip_parcel_${ride.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: AppColors.slateBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SendParcelScreen(ride: ride),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: AppColors.navy,
                                ),
                                label: Text(
                                  isAr ? 'أرسل طرداً' : 'Send Parcel',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Section 7 — Quick Supply & Hardware Categories Card:
  /// Features `assets/images/cat_tools_ppe.jpg` (`1200x896` — used ONCE!) at its
  /// exact native `1200 / 896` (`4:3`) aspect ratio with ZERO cropping.
  Widget _buildQuickSupplyCategoriesCard({
    required BuildContext context,
    required SavedWorksite? activeSite,
    required bool isAr,
    required bool isMedium,
  }) {
    final quickCategories = <(String, String)>[
      ('electrical', isAr ? 'كهرباء وكابلات' : 'Electrical'),
      ('plumbing', isAr ? 'سباكة ومواسير' : 'Plumbing'),
      ('hardware', isAr ? 'عدد ومسامير' : 'Hardware'),
      ('safety_ppe', isAr ? 'سلامة مهنية PPE' : 'Safety PPE'),
      ('civil_materials', isAr ? 'مواد بناء' : 'Civil Materials'),
      ('tools', isAr ? 'معدات وأدوات' : 'Power Tools'),
      ('other', isAr ? 'أخرى (طلب مخصص)' : 'Other (Custom)'),
    ];

    final categoryContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarCategoryIcon(
                category: 'general_site_supply',
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'فئات التوريد السريع للمشاريع والمهام'
                          : 'Quick Supply & Hardware Categories',
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isAr
                          ? 'اختر فئة المواد لفتح الطلب المباشر بنقرة واحدة'
                          : 'Tap a category to open a pre-selected request',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary(
                        color: AppColors.textSecondary,
                      ).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCategories.map((cat) {
              return MashwarPressable(
                key: ValueKey('home_quick_category_${cat.$1}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateWorkRequestScreen(
                        initialSavedWorksite: activeSite,
                        initialSupplyCategory: cat.$1,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MashwarCategoryIcon(
                        category: cat.$1,
                        size: 22,
                        showSurface: true,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        cat.$2,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    final uncroppedPhoto = AspectRatio(
      aspectRatio: 1200 / 896,
      child: Image.asset(
        'assets/images/cat_tools_ppe.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.slateBg,
          child: const Center(
            child: Icon(
              Icons.handyman_rounded,
              color: AppColors.navy,
              size: 36,
            ),
          ),
        ),
      ),
    );

    return Container(
      key: const ValueKey('home_worksite_supply_card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slateBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: isMedium
          ? Row(
              children: [
                Expanded(flex: 7, child: categoryContent),
                Expanded(flex: 4, child: uncroppedPhoto),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                uncroppedPhoto,
                categoryContent,
              ],
            ),
    );
  }

  Widget _buildNotificationsSummaryStrip({
    required BuildContext context,
    required List<WorksiteNotificationItem> unreadNotifications,
    required int unreadCount,
    required int openOffersCount,
    required bool isAr,
  }) {
    final hasActivity = unreadCount > 0 || openOffersCount > 0;
    return MashwarHoverCard(
      key: const ValueKey('home_notifications_summary'),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.white,
      borderColor: hasActivity
          ? AppColors.teal.withValues(alpha: 0.35)
          : AppColors.slateBorder,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NotificationsCenterScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasActivity ? AppColors.tealSurface : AppColors.slateBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasActivity
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
              size: 18,
              color: hasActivity ? AppColors.tealDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadNotifications.isNotEmpty
                      ? unreadNotifications.first.localizedTitle(isArabic: isAr)
                      : (openOffersCount > 0
                          ? (isAr
                              ? 'لديك $openOffersCount عروض جديدة بانتظار المراجعة على طلباتك.'
                              : 'You have $openOffersCount new offer(s) awaiting review.')
                          : (isAr
                              ? 'ملخص التنبيهات: كل التحديثات مقروءة حالياً.'
                              : 'Notifications summary: You are all caught up.')),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    isAr
                        ? '$unreadCount تنبيهات غير مقروءة · اضغط للعرض'
                        : '$unreadCount unread alert(s) · Tap to open',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.tealDark)
                        .copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSupplyRequestsSection({
    required BuildContext context,
    required WorksiteProvider worksite,
    required List<WorkRequest> recentToShow,
    required bool isAr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'طلبات التوريد والمهام النشطة'
                          : 'Active Supply & Errand Requests',
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkRequestsFeedScreen(),
                  ),
                );
              },
              child: Text(
                isAr ? 'عرض الكل' : 'View All',
                style: AppTypography.label(color: AppColors.navy).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (worksite.isLoading && recentToShow.isEmpty)
          Column(
            children: List.generate(
              2,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: MashwarShimmerBox(height: 92, borderRadius: 16),
              ),
            ),
          )
        else if (recentToShow.isEmpty)
          MashwarSectionCard(
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            borderColor: AppColors.slateBorder,
            child: Text(
              isAr
                  ? 'لا توجد طلبات توريد مسجلة بعد. ابدأ بإنشاء طلبك الأول أعلاه.'
                  : 'No supply requests yet. Create your first request above.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(
                color: AppColors.textSecondary,
              ).copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          ...recentToShow.map((req) {
            final areaLabel =
                AppStrings.translateCity(req.municipality, isArabic: isAr);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MashwarHoverCard(
                key: ValueKey('home_recent_req_${req.id}'),
                borderRadius: BorderRadius.circular(18),
                backgroundColor: Colors.white,
                borderColor: AppColors.slateBorder,
                hoverBorderColor: AppColors.navy,
                padding: const EdgeInsets.all(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkRequestDetailsScreen(requestId: req.id),
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
                              MashwarBadge(
                                type: req.status == WorkRequestStatus.completed
                                    ? BadgeType.verified
                                    : BadgeType.confirmed,
                                customLabel:
                                    req.status.label(isArabic: isAr),
                              ),
                              Text(
                                req.effectiveTotalMinor.format(isArabic: isAr),
                                style: AppTypography.body(color: AppColors.navy)
                                    .copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      req.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    MashwarRouteTimeline(
                      from: req.pickupLocation,
                      to: '${req.dropoffWorksite} ($areaLabel)',
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          key: ValueKey('home_quick_reorder_${req.id}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            backgroundColor: Colors.white,
                            side:
                                const BorderSide(color: AppColors.slateBorder),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
                          icon: const Icon(
                            Icons.replay_rounded,
                            size: 15,
                            color: AppColors.navy,
                          ),
                          label: Text(
                            isAr ? 'إعادة طلب سريعة' : 'Quick Reorder',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WorkRequestDetailsScreen(
                                  requestId: req.id,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isAr ? 'عرض التفاصيل' : 'View Details',
                            style: AppTypography.label(
                              color: AppColors.textSecondary,
                            ).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCollapsibleCorridorMapCard({
    required BuildContext context,
    required RidesProvider rides,
    required String corridorFrom,
    required String previewHub,
    required bool isAr,
    required bool isWide,
  }) {
    const hubChips = [
      'الدوحة',
      'لوسيل',
      'الخور',
      'الوكرة',
      'الريان',
      'المنطقة الصناعية',
    ];

    return MashwarSectionCard(
      key: const ValueKey('home_corridor_map_card'),
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      borderColor: AppColors.slateBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarTrustEmblem(
                type: MashwarTrustType.liveCorridor,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'خريطة المسارات التفاعلية للرحلات والطرود والتوريد'
                          : 'Interactive Route & Supply Corridor Map',
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${AppStrings.translateCity(corridorFrom, isArabic: isAr)} → ${AppStrings.translateCity(previewHub, isArabic: isAr)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.tealDark)
                          .copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('home_toggle_map_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.slateBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () =>
                    setState(() => _isMapExpanded = !_isMapExpanded),
                icon: Icon(
                  _isMapExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  size: 16,
                  color: AppColors.navy,
                ),
                label: Text(
                  _isMapExpanded
                      ? (isAr ? 'تصغير' : 'Compact')
                      : (isAr ? 'توسيع' : 'Expand'),
                  style: AppTypography.label(color: AppColors.navy).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: _isMapExpanded
                ? (isWide ? 310 : 250)
                : (isWide ? 205 : 165),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: QatarLiveMapCanvas(
              style: QatarMapStyle.light,
              showCarTrails: false,
              activeFromCity: corridorFrom,
              activeToCity: previewHub,
              borderRadius: 15.0,
              onHubTap: (city) {
                setState(() => _previewHubCity = city);
              },
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildLegendDot(
                AppColors.teal,
                isAr ? 'نقطة الانطلاق والمسار' : 'Origin & Active Route',
              ),
              _buildLegendDot(
                AppColors.gold,
                isAr ? 'نقطة الوصول والتسليم' : 'Destination & Handover Hub',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: hubChips.map((area) {
              final isSelected = previewHub == area;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _previewHubCity = area),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navy : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.navy : AppColors.slateBorder,
                    ),
                  ),
                  child: Text(
                    AppStrings.translateCity(area, isArabic: isAr),
                    style: AppTypography.label(
                      color: isSelected ? Colors.white : AppColors.navy,
                    ).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(color: AppColors.textSecondary)
                .copyWith(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showSavedWorksitePicker(
    BuildContext context,
    WorksiteProvider worksite,
    bool isAr,
  ) {
    final sites = worksite.savedWorksites;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isAr ? 'اختيار الموقع المحفوظ' : 'Select Saved Location',
                  style: AppTypography.title(color: AppColors.navy).copyWith(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (sites.isEmpty)
                  Text(
                    isAr
                        ? 'لا توجد مواقع محفوظة بعد. أضف مواقعك لتعبئة الطلبات تلقائياً.'
                        : 'No saved locations yet. Add your frequent spots for 1-tap prefill.',
                    style: AppTypography.bodySecondary(
                      color: AppColors.textSecondary,
                    ).copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  ...sites.map(
                    (site) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.teal,
                      ),
                      title: Text(
                        site.label,
                        style: AppTypography.body(color: AppColors.navy)
                            .copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${AppStrings.translateCity(site.municipality, isArabic: isAr)} · ${site.zoneOrStreet}',
                        style: AppTypography.bodySecondary(
                          color: AppColors.textSecondary,
                        ).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedSavedWorksiteId = site.id);
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.slateBorder),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderProfileScreen(
                          focusSavedWorksites: true,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    isAr
                        ? 'إضافة / إدارة المواقع المحفوظة'
                        : 'Add / Manage Saved Locations',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
