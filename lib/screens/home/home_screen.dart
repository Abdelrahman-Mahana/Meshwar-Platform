import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
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
import '../parcel/send_parcel_screen.dart';
import '../ride_details/ride_details_screen.dart';
import '../trips/trips_and_parcels_hub_screen.dart';
import '../worksite/create_work_request_screen.dart';
import '../worksite/provider_profile_screen.dart';
import '../worksite/work_request_details_screen.dart';
import '../worksite/work_requests_feed_screen.dart';
import 'city_search_modal.dart';

/// Unified International 3-Service Home Screen for MASHWAR:
/// 1. Shared Trips & Empty Seats (`سفر ومقاعد تشاركية`)
/// 2. Parcels & Items on the Way (`طرود وأغراض مع مسافر`)
/// 3. Smart Shopping, Supply & Tasks (`شراء وتوريد ومهام خاصة`)
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
            final isUltraCompact = constraints.maxWidth < 360;
            final hPad = isWide
                ? AppDimens.space32
                : (isUltraCompact ? 14.0 : AppDimens.space20);

            return RefreshIndicator(
              color: AppColors.cobalt,
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
                    constraints: BoxConstraints(maxWidth: isWide ? 1140 : 740),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (admin != null &&
                            admin.broadcastBanner.isEnabled) ...[
                          _buildBroadcastBanner(admin, isAr),
                          const SizedBox(height: 12),
                        ],

                        // 1. Clean International Top Brand Header
                        _buildTopBrandHeader(
                          context: context,
                          auth: auth,
                          worksite: worksite,
                          firstName: firstName,
                          unreadCount: unreadCount,
                          isAr: isAr,
                          isUltraCompact: isUltraCompact,
                        ),
                        const SizedBox(height: 14),

                        // Dev-Only All-Cases Showcase Toggle
                        if (AppEnvironment.current.isDevelopment ||
                            AppEnvironment.useDevMocks) ...[
                          _buildDemoShowcaseBanner(context, worksite, isAr),
                          const SizedBox(height: 14),
                        ],

                        // 2. Hero Route & Service Search Card
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 280),
                          offsetY: 10,
                          child: _buildHeroSearchCard(
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

                        // 3. Three Core Services Showcase (Bidirectional Dual CTAs)
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 320),
                          offsetY: 12,
                          child: _buildThreeServicesShowcase(
                            context: context,
                            activeSite: activeSite,
                            isAr: isAr,
                            isDesktopThreeCol: isDesktopThreeCol,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 4. "How MASHWAR Works in 3 Steps"
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 340),
                          offsetY: 10,
                          child: MashwarThreeStepsBanner(
                            isAr: isAr,
                            compact: isUltraCompact,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 5. Live Available Travelers (Seats + Parcel Space)
                        _buildAvailableTravelersSection(
                          context: context,
                          topTrips: topTrips,
                          isLoading: rides.isLoading,
                          isAr: isAr,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 20),

                        // 6. Quick Supply Categories Strip (1-Tap Supply Shortcuts)
                        _buildQuickSupplyCategoriesCard(
                          context: context,
                          activeSite: activeSite,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 18),

                        // 7. Real Notifications Summary Strip
                        _buildNotificationsSummaryStrip(
                          context: context,
                          unreadNotifications: unreadNotifications,
                          unreadCount: unreadCount,
                          openOffersCount: openOffersCount,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 20),

                        // 8. Active Supply & Route Requests
                        _buildRecentSupplyRequestsSection(
                          context: context,
                          worksite: worksite,
                          recentToShow: recentToShow,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 18),

                        // 9. Clean Collapsible Interactive Corridor Map
                        _buildCollapsibleCorridorMapCard(
                          context: context,
                          rides: rides,
                          corridorFrom: corridorFrom,
                          previewHub: previewHub,
                          isAr: isAr,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 16),
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
        color: isWarning ? AppColors.goldSurface : AppColors.navy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? AppColors.gold : AppColors.cobalt,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 18,
            color: isWarning ? AppColors.navy : Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr
                  ? admin.broadcastBanner.messageAr
                  : admin.broadcastBanner.messageEn,
              style: TextStyle(
                color: isWarning ? AppColors.navy : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
    required String firstName,
    required int unreadCount,
    required bool isAr,
    required bool isUltraCompact,
  }) {
    final greetingText = auth.user.fullName.trim().isNotEmpty
        ? (isAr ? 'أهلاً بك، $firstName' : 'Welcome, $firstName')
        : (isAr ? 'أهلاً بك في مشوار' : 'Welcome to MASHWAR');

    return Row(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      greetingText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isUltraCompact ? 13.5 : 15,
                      ),
                    ),
                  ),
                  if (auth.user.isVerified || worksite.isApprovedProvider) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.emerald,
                    ),
                  ],
                ],
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
                      color: Colors.white,
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
                          color: AppColors.cobalt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.4),
                        ),
                        constraints: const BoxConstraints(minWidth: 17),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
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
              child: Container(
                width: isUltraCompact ? 38 : 42,
                height: isUltraCompact ? 38 : 42,
                decoration: BoxDecoration(
                  color: AppColors.cobaltSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cobalt.withValues(alpha: 0.35),
                    width: 1.8,
                  ),
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

  Widget _buildHeroSearchCard({
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
    final heroAsset = _selectedHeroMode == 0
        ? 'assets/images/service_ride.jpg'
        : (_selectedHeroMode == 1
            ? 'assets/images/service_parcel.jpg'
            : 'assets/images/mvp_hero_lusail_supply.jpg');

    final modes = <({int index, String label, IconData icon, Color accent})>[
      (
        index: 0,
        label: isAr ? 'رحلة ومقاعد' : 'Shared Trips',
        icon: Icons.directions_car_outlined,
        accent: AppColors.cobalt,
      ),
      (
        index: 1,
        label: isAr ? 'إرسال طرد' : 'Send Parcel',
        icon: Icons.inventory_2_outlined,
        accent: AppColors.indigo,
      ),
      (
        index: 2,
        label: isAr ? 'توريد ومهام' : 'Supply & Tasks',
        icon: Icons.fact_check_outlined,
        accent: AppColors.emerald,
      ),
    ];

    final heroButtonLabel = _selectedHeroMode == 0
        ? (isAr ? 'ابحث عن الرحلات والمقاعد' : 'Search Available Trips')
        : (_selectedHeroMode == 1
            ? (isAr ? 'ابدأ إرسال طرد على الطريق' : 'Send Parcel on Route')
            : (isAr ? 'ابدأ طلب توريد ومهام' : 'Start Supply Request'));

    final fromDisplay = rides.fromCity.trim().isNotEmpty
        ? context.trCity(rides.fromCity)
        : (isAr ? 'من أين؟ (اختر مدينة الانطلاق)' : 'From where? (Origin)');
    final toDisplay = rides.toCity.trim().isNotEmpty
        ? context.trCity(rides.toCity)
        : (isAr ? 'إلى أين؟ (اختر الوجهة)' : 'Where to? (Destination)');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slateBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Vivid Photography Header with Clean International Navy/Cobalt Scrim
          Stack(
            children: [
              Positioned.fill(
                child: MashwarAssetArt(
                  assetPath: heroAsset,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.route_rounded,
                  fallbackBg: AppColors.navy,
                  fallbackColor: AppColors.cobalt,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        const Color(0xFF0F172A).withValues(alpha: 0.93),
                        AppColors.navy.withValues(alpha: 0.86),
                        const Color(0xFF1E3A8A).withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isUltraCompact ? 16 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MashwarLivePulseDot(
                                color: AppColors.emerald,
                                size: 7.5,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isAr
                                      ? '$activeTripsCount رحلة متاحة · $activeSupplyCount طلب نشط'
                                      : '$activeTripsCount Trips · $activeSupplyCount Open Requests',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTypography.label(color: Colors.white)
                                          .copyWith(
                                    fontWeight: FontWeight.w800,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 15,
                                  color: AppColors.cobalt,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    activeSite != null
                                        ? activeSite.label
                                        : (isAr
                                            ? 'المواقع المحفوظة'
                                            : 'Saved Locations'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.cobalt,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr
                          ? 'إلى أين مشوارك أو طلبك اليوم؟'
                          : 'Where does your journey take you today?',
                      style: AppTypography.largeTitle(
                        color: Colors.white,
                      ).copyWith(
                        fontSize: isUltraCompact ? 20 : 25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'تنقّل بمقاعد تشاركية مريحة، أرسل طردك مع مسافر في نفس الطريق، أو اطلب توريد احتياجاتك بفاتورة موثّقة.'
                          : 'Share seats on intercity & daily routes, send parcels with verified travelers, or coordinate smart supply.',
                      style: AppTypography.bodySecondary(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interactive 3-Service Mode Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: modes.map((mode) {
                        final selected = _selectedHeroMode == mode.index;
                        final modeKey = mode.index == 0
                            ? const ValueKey('home_hero_mode_trips')
                            : (mode.index == 1
                                ? const ValueKey('home_hero_mode_parcels')
                                : const ValueKey('home_hero_mode_supply'));
                        return InkWell(
                          key: modeKey,
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setState(() => _selectedHeroMode = mode.index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.26),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mode.icon,
                                  size: 16,
                                  color: selected ? mode.accent : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  mode.label,
                                  style: AppTypography.label(
                                    color: selected
                                        ? AppColors.navy
                                        : Colors.white,
                                  ).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
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
              ),
            ],
          ),

          // Route Search Bar (`من أين -> إلى أين` + Swap + Instant Action Button)
          Padding(
            padding: EdgeInsets.all(isUltraCompact ? 14 : 18),
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
                          dotColor: AppColors.emerald,
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
                          dotColor: AppColors.cobalt,
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
                        width: 240,
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
                            dotColor: AppColors.emerald,
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
                            dotColor: AppColors.cobalt,
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
                        icon: const Icon(Icons.close_rounded,
                            size: 15, color: AppColors.cobalt),
                        label: Text(
                          isAr ? 'مسح المسار' : 'Clear route',
                          style: AppTypography.label(color: AppColors.cobalt)
                              .copyWith(fontWeight: FontWeight.w800),
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

  Widget _buildRouteFieldTile({
    required Key key,
    required String label,
    required String value,
    required bool hasValue,
    required Color dotColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.slateBg,
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
                  ? dotColor.withValues(alpha: 0.45)
                  : AppColors.slateBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
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
                      ).copyWith(fontSize: 10.5),
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
                            hasValue ? FontWeight.w800 : FontWeight.w600,
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
        side: BorderSide(color: AppColors.slateBorder),
      ),
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      child: InkWell(
        key: const ValueKey('home_route_swap_btn'),
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() => _swapTurns += 0.5);
          rides.swapLocations();
          board.setRouteFilter(from: rides.fromCity, to: rides.toCity);
        },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: AnimatedRotation(
            turns: _swapTurns,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: const Icon(
              Icons.swap_vert_rounded,
              size: 19,
              color: AppColors.cobalt,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreeServicesShowcase({
    required BuildContext context,
    required SavedWorksite? activeSite,
    required bool isAr,
    required bool isDesktopThreeCol,
  }) {
    final cards = <Widget>[
      // Pillar 1: Shared Trips & Empty Seats
      _buildServicePillarCard(
        pillar: MashwarServicePillar.sharedTrips,
        imageAsset: 'assets/images/service_ride.jpg',
        accent: AppColors.cobalt,
        title: isAr ? 'سفر ومقاعد تشاركية' : 'Shared Trips & Empty Seats',
        benefit: isAr
            ? 'شارك مقاعد سيارتك الشاغرة لتغطية تكاليف الطريق أو احجز مقعداً مع مسافر موثّق.'
            : 'Share empty seats along your route or book a comfortable ride with verified travelers.',
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

      // Pillar 2: Parcels & Items on the Way
      _buildServicePillarCard(
        pillar: MashwarServicePillar.routeParcels,
        imageAsset: 'assets/images/service_parcel.jpg',
        accent: AppColors.indigo,
        title: isAr ? 'طرود وأغراض مع مسافر' : 'Parcels & Items on the Way',
        benefit: isAr
            ? 'أرسل الطرود والمستندات بسرعة مع مسافر متجه لنفس الوجهة بتأكيد كود OTP.'
            : 'Send documents and packages faster with travelers already heading that way.',
        primaryKey: const ValueKey('home_send_parcel_cta'),
        primaryLabel: isAr ? 'أرسل طرداً مع مسافر' : 'Send Parcel with Traveler',
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

      // Pillar 3: Smart Shopping, Supply & Tasks
      _buildServicePillarCard(
        pillar: MashwarServicePillar.smartSupply,
        imageAsset: 'assets/images/cat_tools_ppe.jpg',
        accent: AppColors.emerald,
        title: isAr ? 'شراء وتوريد ومهام خاصة' : 'Smart Shopping & Supply',
        benefit: isAr
            ? 'اطلب شراء وتوريد المواد والمعدات لموقعك بفاتورة موثّقة ورمز تسليم من 6 خانات.'
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
            Text(
              isAr ? 'خدمات مشوار الأساسية' : 'Core MASHWAR Services',
              style: AppTypography.title().copyWith(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cobaltSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAr ? 'ثنائي الاتجاه: اطلب أو نفّذ' : 'Request or Earn on Route',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.cobalt)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isDesktopThreeCol)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
              const SizedBox(width: 14),
              Expanded(child: cards[2]),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cards[0],
              const SizedBox(height: 14),
              cards[1],
              const SizedBox(height: 14),
              cards[2],
            ],
          ),
      ],
    );
  }

  Widget _buildServicePillarCard({
    required MashwarServicePillar pillar,
    required String imageAsset,
    required Color accent,
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
      borderColor: AppColors.slateBorder,
      hoverBorderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MashwarAssetArt(
                  assetPath: imageAsset,
                  fit: BoxFit.cover,
                  fallbackIcon: primaryIcon,
                  fallbackBg: AppColors.navy,
                  fallbackColor: accent,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.navy.withValues(alpha: 0.25),
                        AppColors.navy.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: MashwarServicePillarIcon(
                    pillar: pillar,
                    size: 40,
                  ),
                ),
                PositionedDirectional(
                  bottom: 10,
                  start: 14,
                  end: 14,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title(color: Colors.white).copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  benefit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySecondary().copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    key: primaryKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
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
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    key: secondaryKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      backgroundColor: AppColors.slateBg,
                      side: BorderSide(color: accent.withValues(alpha: 0.32)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 16, color: accent),
                    label: Text(
                      secondaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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
              child: Text(
                isAr
                    ? 'مسافرون متاحون الآن (مقاعد ومساحة طرود)'
                    : 'Available Travelers (Seats & Parcel Space)',
                style: AppTypography.title().copyWith(fontSize: 17.5),
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
                style: AppTypography.label(color: AppColors.cobalt)
                    .copyWith(fontWeight: FontWeight.w800),
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
            child: Column(
              children: [
                Text(
                  isAr
                      ? 'لا توجد رحلات مطابقة لهذا المسار حالياً — يمكنك نشر رحلتك أو طلب مقعد/طرد على الطريق.'
                      : 'No matching trips for this corridor right now — publish your trip or post a route request.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
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
                    isAr
                        ? 'استعرض طلبات المسار'
                        : 'Browse Route Requests',
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
                borderColor: AppColors.slateBorder,
                hoverBorderColor: AppColors.cobalt,
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
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.cobaltSurface,
                              child: Text(
                                ride.driverName.isNotEmpty
                                    ? ride.driverName[0]
                                    : 'M',
                                style: AppTypography.label(
                                        color: AppColors.cobalt)
                                    .copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${ride.driverName} · ${ride.driverRating.toStringAsFixed(1)} ★',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body(color: AppColors.navy)
                                    .copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            if (ride.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  size: 15, color: AppColors.emerald),
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
                                color: AppColors.cobaltSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isAr
                                    ? '${ride.remainingSeats} مقاعد شاغرة'
                                    : '${ride.remainingSeats} empty seats',
                                style:
                                    AppTypography.label(color: AppColors.cobalt)
                                        .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (ride.acceptsParcels)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isAr ? 'يقبل طرود' : 'Accepts Parcels',
                                  style: AppTypography.label(
                                          color: AppColors.emerald)
                                      .copyWith(fontWeight: FontWeight.w800),
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
                        Text(
                          isAr
                              ? '${ride.pricePerSeat} ر.ق / مقعد${ride.acceptsParcels ? " · طرد ${ride.parcelPrice} ر.ق" : ""}'
                              : '${ride.pricePerSeat} QAR / seat${ride.acceptsParcels ? " · Parcel ${ride.parcelPrice} QAR" : ""}',
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ElevatedButton(
                              key: ValueKey('home_book_trip_${ride.id}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cobalt,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            if (ride.acceptsParcels)
                              OutlinedButton.icon(
                                key: ValueKey('home_trip_parcel_${ride.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.indigo,
                                  side: BorderSide(
                                    color:
                                        AppColors.indigo.withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
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
                                icon: const Icon(Icons.inventory_2_outlined,
                                    size: 14),
                                label: Text(
                                  isAr ? 'أرسل طرداً' : 'Send Parcel',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
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

  Widget _buildQuickSupplyCategoriesCard({
    required BuildContext context,
    required SavedWorksite? activeSite,
    required bool isAr,
  }) {
    final quickCategories = <(String, String)>[
      ('electrical', isAr ? 'كهرباء وكابلات' : 'Electrical'),
      ('plumbing', isAr ? 'سباكة ومواسير' : 'Plumbing'),
      ('hardware', isAr ? 'عدد ومسامير' : 'Hardware'),
      ('safety_ppe', isAr ? 'سلامة مهنية PPE' : 'Safety PPE'),
      ('civil_materials', isAr ? 'مواد بناء' : 'Civil Materials'),
      ('tools', isAr ? 'معدات وأدوات' : 'Power Tools'),
    ];

    return Container(
      key: const ValueKey('home_worksite_supply_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarCategoryIcon(
                category: 'general_site_supply',
                size: 38,
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
                      style: AppTypography.title().copyWith(fontSize: 15.5),
                    ),
                    Text(
                      isAr
                          ? 'اختر فئة المواد لفتح نموذج الطلب المباشر بنقرة واحدة'
                          : 'Tap any category to open a pre-selected supply request',
                      style: AppTypography.bodySmall(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCategories.map((cat) {
              final meta = mashwarCategoryMetaFor(cat.$1);
              return MashwarPressable(
                borderRadius: BorderRadius.circular(14),
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: meta.accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MashwarCategoryIcon(
                        category: cat.$1,
                        size: 24,
                        showSurface: true,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        cat.$2,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
      backgroundColor: hasActivity ? AppColors.cobaltSurface : Colors.white,
      borderColor: hasActivity
          ? AppColors.cobalt.withValues(alpha: 0.35)
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: hasActivity
                  ? AppColors.cobalt.withValues(alpha: 0.14)
                  : AppColors.slateBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasActivity
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
              size: 18,
              color: hasActivity ? AppColors.cobalt : AppColors.textSecondary,
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
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                if (unreadCount > 0)
                  Text(
                    isAr
                        ? '$unreadCount تنبيهات غير مقروءة · اضغط للعرض'
                        : '$unreadCount unread alert(s) · Tap to open',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: AppColors.cobalt)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.navy,
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
              child: Text(
                isAr
                    ? 'طلبات التوريد والمهام النشطة'
                    : 'Active Supply & Errand Requests',
                style: AppTypography.title().copyWith(fontSize: 17.5),
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
                style: AppTypography.label(color: AppColors.emerald)
                    .copyWith(fontWeight: FontWeight.w800),
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
            child: Text(
              isAr
                  ? 'لا توجد طلبات توريد مسجلة بعد. ابدأ بإنشاء طلبك الأول أعلاه.'
                  : 'No supply requests yet. Create your first request above.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(),
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
                borderRadius: BorderRadius.circular(16),
                borderColor: AppColors.slateBorder,
                hoverBorderColor: AppColors.emerald,
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
                                style: AppTypography.body(
                                        color: AppColors.emerald)
                                    .copyWith(fontWeight: FontWeight.w800),
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
                      style: AppTypography.title().copyWith(fontSize: 15.5),
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
                            foregroundColor: AppColors.emerald,
                            side: const BorderSide(color: AppColors.emerald),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          icon: const Icon(Icons.replay_rounded, size: 15),
                          label: Text(
                            isAr ? 'إعادة طلب سريعة' : 'Quick Reorder',
                            style:
                                AppTypography.label(color: AppColors.emerald)
                                    .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
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
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w800),
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
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${AppStrings.translateCity(corridorFrom, isArabic: isAr)} → ${AppStrings.translateCity(previewHub, isArabic: isAr)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.cobalt)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                key: const ValueKey('home_toggle_map_btn'),
                onPressed: () =>
                    setState(() => _isMapExpanded = !_isMapExpanded),
                icon: Icon(
                  _isMapExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  size: 18,
                  color: AppColors.cobalt,
                ),
                label: Text(
                  _isMapExpanded
                      ? (isAr ? 'تصغير' : 'Compact')
                      : (isAr ? 'توسيع' : 'Expand'),
                  style: AppTypography.label(color: AppColors.cobalt)
                      .copyWith(fontWeight: FontWeight.w800),
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
          // Cobalt / Emerald International Legend
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildLegendDot(
                AppColors.cobalt,
                isAr ? 'مسارات الرحلات والطرود' : 'Trips & Parcels Routes',
              ),
              _buildLegendDot(
                AppColors.emerald,
                isAr ? 'نقاط التوريد والتسليم' : 'Supply & Handover Hubs',
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
                    color: isSelected ? AppColors.cobalt : AppColors.slateBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.cobalt
                          : AppColors.slateBorder,
                    ),
                  ),
                  child: Text(
                    AppStrings.translateCity(area, isArabic: isAr),
                    style: AppTypography.label(
                      color: isSelected ? Colors.white : AppColors.navy,
                    ).copyWith(fontWeight: FontWeight.w700),
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.label(color: AppColors.textSecondary)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDemoShowcaseBanner(
    BuildContext context,
    WorksiteProvider worksite,
    bool isAr,
  ) {
    final isActive = worksite.isDemoShowcaseMode;
    final button = OutlinedButton.icon(
      key: const ValueKey('home_demo_all_cases_btn'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? AppColors.emerald : AppColors.cobalt,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isActive ? AppColors.emerald : AppColors.cobalt,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        if (isActive) {
          worksite.exitDemoShowcase();
        } else {
          worksite.activateDemoShowcase();
        }
      },
      icon: Icon(
        isActive ? Icons.close_rounded : Icons.layers_outlined,
        size: 15,
      ),
      label: Text(
        isActive
            ? (isAr ? 'إيقاف العرض التجريبي' : 'Exit Demo Showcase')
            : (isAr
                ? 'عرض جميع الحالات التجريبية (14)'
                : 'Load All Demo Cases (14)'),
        style: AppTypography.label(
          color: isActive ? AppColors.emerald : AppColors.cobalt,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
    );

    return Container(
      key: const ValueKey('home_demo_showcase_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.emeraldSurface : AppColors.cobaltSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.emerald.withValues(alpha: 0.35)
              : AppColors.cobalt.withValues(alpha: 0.28),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideRow = constraints.maxWidth >= 560;
          final headline = Row(
            children: [
              Icon(
                isActive ? Icons.auto_awesome_rounded : Icons.science_outlined,
                size: 18,
                color: isActive ? AppColors.emerald : AppColors.cobalt,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isActive
                      ? (isAr
                          ? 'وضع استعراض جميع الحالات نشط (14 حالة · 11 مرحلة · 5 رموز تسليم)'
                          : 'All-Cases Showcase Active (14 cases · 11 statuses · 5 handover codes)')
                      : (isAr
                          ? 'وضع التطوير: استعرض جميع حالات مشوار الـ 14 والرموز التجريبية'
                          : 'Dev Mode: Preview all 14 MASHWAR cases, offers & handover codes'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );

          if (isWideRow) {
            return Row(
              children: [
                Expanded(child: headline),
                const SizedBox(width: 10),
                button,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headline,
              const SizedBox(height: 8),
              button,
            ],
          );
        },
      ),
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
                  isAr
                      ? 'اختيار الموقع المحفوظ'
                      : 'Select Saved Location',
                  style: AppTypography.title().copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (sites.isEmpty)
                  Text(
                    isAr
                        ? 'لا توجد مواقع محفوظة بعد. أضف مواقعك لتعبئة الطلبات تلقائياً.'
                        : 'No saved locations yet. Add your frequent spots for 1-tap prefill.',
                    style: AppTypography.bodySecondary(),
                  )
                else
                  ...sites.map(
                    (site) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_rounded,
                          color: AppColors.cobalt),
                      title: Text(site.label),
                      subtitle: Text(
                          '${AppStrings.translateCity(site.municipality, isArabic: isAr)} · ${site.zoneOrStreet}'),
                      onTap: () {
                        setState(() => _selectedSavedWorksiteId = site.id);
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                MashwarButton(
                  text: isAr
                      ? 'إضافة / إدارة المواقع المحفوظة'
                      : 'Add / Manage Saved Locations',
                  variant: MashwarButtonVariant.secondary,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
