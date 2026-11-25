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

/// Flagship International 3-Service Home Screen for MASHWAR
/// Built on MASHWAR's original luxury palette (Navy · Gold · Teal · Warm Sand)
/// with 3 prominent top interactive service icons and full-frame, zero-crop,
/// zero-repetition 16:9 editorial photography.
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
      backgroundColor: const Color(0xFFFAF8F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 860;
            final isDesktopThreeCol = constraints.maxWidth >= 960;
            final isUltraCompact = constraints.maxWidth < 360;
            final hPad = isWide
                ? AppDimens.space32
                : (isUltraCompact ? 14.0 : AppDimens.space20);

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
                    constraints: BoxConstraints(maxWidth: isWide ? 1160 : 740),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (admin != null &&
                            admin.broadcastBanner.isEnabled) ...[
                          _buildBroadcastBanner(admin, isAr),
                          const SizedBox(height: 12),
                        ],

                        // 1. Clean Top Brand Header (Navy · Gold · Teal)
                        _buildTopBrandHeader(
                          context: context,
                          auth: auth,
                          worksite: worksite,
                          firstName: firstName,
                          unreadCount: unreadCount,
                          isAr: isAr,
                          isUltraCompact: isUltraCompact,
                        ),
                        const SizedBox(height: 16),

                        // Dev-Only All-Cases Showcase Toggle
                        if (AppEnvironment.current.isDevelopment ||
                            AppEnvironment.useDevMocks) ...[
                          _buildDemoShowcaseBanner(context, worksite, isAr),
                          const SizedBox(height: 16),
                        ],

                        // 2. Signature Opening Block: "مشوارك أو طلبك"
                        //    3 Prominent Service Icon Tiles + Full-Frame 16:9 Editorial Visual + Route Bar
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 260),
                          offsetY: 10,
                          child: _buildSignatureHeroSection(
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
                        const SizedBox(height: 28),

                        // 3. Core 3 Services Editorial Gallery (Unique Full-Size 16:9 Media per Card)
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 300),
                          offsetY: 12,
                          child: _buildThreeServicesShowcase(
                            context: context,
                            activeSite: activeSite,
                            isAr: isAr,
                            isDesktopThreeCol: isDesktopThreeCol,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. "How MASHWAR Works in 3 Steps" (Navy · Gold · Teal)
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 320),
                          offsetY: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  isAr
                                      ? 'كيف يعمل مشوار في 3 خطوات'
                                      : 'How MASHWAR Works in 3 Steps',
                                  style: AppTypography.title()
                                      .copyWith(fontSize: 17.5),
                                ),
                              ),
                              MashwarThreeStepsBanner(
                                isAr: isAr,
                                compact: isUltraCompact,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 5. Live Available Travelers (Seats + Parcel Space)
                        _buildAvailableTravelersSection(
                          context: context,
                          topTrips: topTrips,
                          isLoading: rides.isLoading,
                          isAr: isAr,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 24),

                        // 6. Quick Supply Categories Strip
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
                        const SizedBox(height: 24),

                        // 8. Active Supply & Route Requests
                        _buildRecentSupplyRequestsSection(
                          context: context,
                          worksite: worksite,
                          recentToShow: recentToShow,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 22),

                        // 9. Clean Collapsible Interactive Corridor Map
                        _buildCollapsibleCorridorMapCard(
                          context: context,
                          rides: rides,
                          corridorFrom: corridorFrom,
                          previewHub: previewHub,
                          isAr: isAr,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 20),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning ? AppColors.gold : AppColors.navy,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 18,
            color: isWarning ? AppColors.navy : AppColors.gold,
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isUltraCompact ? 10 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              spacing: isUltraCompact ? 8 : 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BrandLogo(
                  fontSize: isUltraCompact ? 20 : 25,
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
                        style:
                            AppTypography.body(color: AppColors.navy).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: isUltraCompact ? 12.5 : 14.5,
                        ),
                      ),
                    ),
                    if (auth.user.isVerified || worksite.isApprovedProvider) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.teal,
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                        color: AppColors.sand,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.warmBorder),
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
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
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
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      auth.user.fullName.isNotEmpty
                          ? auth.user.fullName[0]
                          : 'م',
                      style: AppTypography.title(color: Colors.white)
                          .copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// First Signature Hero Module:
  /// - Headline ("إلى أين مشوارك أو طلبك اليوم؟")
  /// - 3 Prominent Interactive Service Icon Tiles right at the top
  /// - Full-Size Uncropped 16:9 Editorial Photograph (unique per mode, never repeated below!)
  /// - Clean Route Picker (`من أين` <-> `إلى أين`) + Navy/Gold CTA Button
  Widget _buildSignatureHeroSection({
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
    // Dedicated 16:9 Hero visuals — ZERO overlap with the 3 service cards below!
    final heroMeta = switch (_selectedHeroMode) {
      0 => (
          asset: 'assets/images/home_hero_mobility.jpg',
          caption: isAr
              ? 'مقاعد مريحة مع مسافرين موثّقين على نفس مسارك'
              : 'Comfortable shared seats with verified travelers on your route',
          cta: isAr ? 'ابحث عن الرحلات والمقاعد' : 'Search Available Trips',
          ctaIcon: Icons.directions_car_filled_rounded,
          tag: isAr ? 'سفر مشترك' : 'Shared Mobility',
        ),
      1 => (
          asset: 'assets/images/hero_banner.jpg',
          caption: isAr
              ? 'أرسل طردك أو مستنداتك مع مسافر متجه لنفس الوجهة بكود OTP'
              : 'Send parcels & documents with a verified traveler using dual OTP',
          cta: isAr ? 'ابدأ إرسال طرد على الطريق' : 'Send Parcel on Route',
          ctaIcon: Icons.inventory_2_rounded,
          tag: isAr ? 'طرود موثّقة' : 'Route Parcels',
        ),
      _ => (
          asset: 'assets/images/mvp_hero_lusail_supply.jpg',
          caption: isAr
              ? 'شراء وتوريد احتياجاتك ومهامك بفاتورة معتمدة وتسليم سريع'
              : 'Verified shopping, site supply & errands with receipt protection',
          cta: isAr ? 'ابدأ طلب توريد ومهام' : 'Start Supply Request',
          ctaIcon: Icons.add_task_rounded,
          tag: isAr ? 'توريد ومهام' : 'Smart Supply',
        ),
    };

    final modes = <({
      int index,
      Key key,
      MashwarServicePillar pillar,
      String title,
      String subtitle,
      Color activeBorder,
      Color activeSurface,
    })>[
      (
        index: 0,
        key: const ValueKey('home_hero_mode_trips'),
        pillar: MashwarServicePillar.sharedTrips,
        title: isAr ? 'رحلة ومقاعد' : 'Shared Trips',
        subtitle: isAr ? 'مقاعد شاغرة' : 'Empty seats',
        activeBorder: AppColors.navy,
        activeSurface: AppColors.navySurface,
      ),
      (
        index: 1,
        key: const ValueKey('home_hero_mode_parcels'),
        pillar: MashwarServicePillar.routeParcels,
        title: isAr ? 'إرسال طرد' : 'Send Parcel',
        subtitle: isAr ? 'على الطريق' : 'On the way',
        activeBorder: AppColors.gold,
        activeSurface: AppColors.goldSurface,
      ),
      (
        index: 2,
        key: const ValueKey('home_hero_mode_supply'),
        pillar: MashwarServicePillar.smartSupply,
        title: isAr ? 'توريد ومهام' : 'Supply & Tasks',
        subtitle: isAr ? 'شراء وتوصيل' : 'Smart supply',
        activeBorder: AppColors.teal,
        activeSurface: AppColors.tealSurface,
      ),
    ];

    final fromDisplay = rides.fromCity.trim().isNotEmpty
        ? context.trCity(rides.fromCity)
        : (isAr ? 'من أين؟ (نقطة الانطلاق)' : 'From where? (Origin)');
    final toDisplay = rides.toCity.trim().isNotEmpty
        ? context.trCity(rides.toCity)
        : (isAr ? 'إلى أين؟ (الوجهة)' : 'Where to? (Destination)');

    // Full-Size Uncropped 16:9 Hero Visual Showcase (zero dark veil covering the photo)
    final heroVisual = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warmBorder),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Stack(
              key: ValueKey(heroMeta.asset),
              fit: StackFit.expand,
              children: [
                Image.asset(
                  heroMeta.asset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.navy,
                    child: const Center(
                      child: Icon(
                        Icons.route_rounded,
                        color: AppColors.gold,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                // Light bottom-only edge fade ONLY under the compact caption pill so 90% of photo stays crystal clear
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 62,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.navy.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          heroMeta.tag,
                          style: AppTypography.label(color: Colors.white)
                              .copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 10,
                  start: 12,
                  end: 12,
                  child: Text(
                    heroMeta.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 3 Prominent Interactive Icon Tiles right at the top ("أيقونة مشوارك أو طلبك")
    final threeIconSelector = Row(
      key: const ValueKey('home_hero_three_icons_bar'),
      children: [
        for (var i = 0; i < modes.length; i++) ...[
          if (i > 0) SizedBox(width: isUltraCompact ? 6 : 10),
          Expanded(
            child: MashwarPressable(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _selectedHeroMode = modes[i].index),
              child: AnimatedContainer(
                key: modes[i].key,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isUltraCompact ? 6 : 10,
                  vertical: isUltraCompact ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: _selectedHeroMode == modes[i].index
                      ? modes[i].activeSurface
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedHeroMode == modes[i].index
                        ? modes[i].activeBorder
                        : AppColors.warmBorder,
                    width: _selectedHeroMode == modes[i].index ? 1.8 : 1.0,
                  ),
                  boxShadow: _selectedHeroMode == modes[i].index
                      ? [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MashwarHeroServiceMedallion(
                      pillar: modes[i].pillar,
                      isSelected: _selectedHeroMode == modes[i].index,
                      size: isUltraCompact ? 40 : 46,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      modes[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isUltraCompact ? 10.5 : 12.5,
                      ),
                    ),
                    if (!isUltraCompact) ...[
                      const SizedBox(height: 2),
                      Text(
                        modes[i].subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 10.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );

    // Clean Route Search Bar (`من أين` <-> `إلى أين` + Instant Action Button)
    final routeControls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                color: AppColors.navy,
              ),
              label: Text(
                isAr ? 'مسح المسار' : 'Clear route',
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          )
        else
          const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            key: const ValueKey('home_hero_action_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedHeroMode == 1
                  ? AppColors.gold
                  : (_selectedHeroMode == 2 ? AppColors.teal : AppColors.navy),
              foregroundColor:
                  _selectedHeroMode == 1 ? AppColors.navy : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _triggerHeroAction(
              context: context,
              rides: rides,
              board: board,
              activeSite: activeSite,
            ),
            icon: Icon(
              heroMeta.ctaIcon,
              size: 19,
              color: _selectedHeroMode == 1 ? AppColors.navy : AppColors.gold,
            ),
            label: Text(
              heroMeta.cta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'Cairo',
                color: _selectedHeroMode == 1 ? AppColors.navy : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );

    final heroTopMetaBar = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MashwarLivePulseDot(
                color: AppColors.teal,
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
                  style: AppTypography.label(color: AppColors.navy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          key: const ValueKey('home_saved_worksite_chip'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSavedWorksitePicker(context, worksite, isAr),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bookmark_rounded,
                  size: 15,
                  color: AppColors.goldDeep,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    activeSite != null
                        ? activeSite.label
                        : (isAr ? 'المواقع المحفوظة' : 'Saved Locations'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.navy,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final heroHeading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr
              ? 'إلى أين مشوارك أو طلبك اليوم؟'
              : 'Where does your journey take you today?',
          style: AppTypography.largeTitle(color: AppColors.navy).copyWith(
            fontSize: isUltraCompact ? 20 : (isWide ? 27 : 23),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAr
              ? 'اختر خدمتك من الأيقونات الثلاث: شارك مقعداً في رحلة، أرسل طرداً مع مسافر، أو اطلب توريد ومهام موثّقة.'
              : 'Choose from 3 integrated services: share seats on a route, send parcels with travelers, or request verified supply.',
          style: AppTypography.bodySecondary().copyWith(
            fontSize: isUltraCompact ? 12.5 : 13.5,
            height: 1.45,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isUltraCompact ? 14 : (isWide ? 24 : 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroTopMetaBar,
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heroHeading,
                      const SizedBox(height: 16),
                      threeIconSelector,
                      const SizedBox(height: 16),
                      routeControls,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 10,
                  child: heroVisual,
                ),
              ],
            )
          else ...[
            heroHeading,
            const SizedBox(height: 16),
            threeIconSelector,
            const SizedBox(height: 16),
            heroVisual,
            const SizedBox(height: 16),
            routeControls,
          ],
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
      color: AppColors.sand,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasValue
                  ? dotColor.withValues(alpha: 0.65)
                  : AppColors.warmBorder,
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
      color: AppColors.navy,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.gold, width: 1.4),
      ),
      elevation: 3,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
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
              color: AppColors.gold,
            ),
          ),
        ),
      ),
    );
  }

  /// 3 Core Services Editorial Showcase:
  /// Each service has a 100% UNIQUE, FULL-SIZE 16:9 visual — NEVER cropped into a thin strip
  /// and NEVER repeated from the hero above!
  Widget _buildThreeServicesShowcase({
    required BuildContext context,
    required SavedWorksite? activeSite,
    required bool isAr,
    required bool isDesktopThreeCol,
  }) {
    final cards = <Widget>[
      // Pillar 1: Shared Trips & Empty Seats (Unique 16:9 Lifestyle Photo)
      _buildServicePillarCard(
        pillar: MashwarServicePillar.sharedTrips,
        stepTag: isAr ? '01 · سفر ومقاعد' : '01 · Shared Trips',
        imageAsset: 'assets/images/pillar_shared_trips.jpg',
        useStudioContainFrame: false,
        primaryBg: AppColors.navy,
        primaryFg: Colors.white,
        primaryIconColor: AppColors.gold,
        secondaryBg: AppColors.sand,
        secondaryBorder: AppColors.navy.withValues(alpha: 0.28),
        secondaryAccent: AppColors.navy,
        title: isAr ? 'سفر ومقاعد تشاركية' : 'Shared Trips & Empty Seats',
        benefit: isAr
            ? 'انشر مقاعد سيارتك الشاغرة لتقاسم تكاليف الطريق أو احجز مقعداً مريحاً مع مسافر موثّق.'
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

      // Pillar 2: Parcels & Items on the Way (Unique Full-Size Studio Product Frame — 0% Cropping!)
      _buildServicePillarCard(
        pillar: MashwarServicePillar.routeParcels,
        stepTag: isAr ? '02 · طرود مع مسافر' : '02 · Route Parcels',
        imageAsset: 'assets/images/service_parcel.jpg',
        useStudioContainFrame: true,
        primaryBg: AppColors.gold,
        primaryFg: AppColors.navy,
        primaryIconColor: AppColors.navy,
        secondaryBg: AppColors.goldSurface,
        secondaryBorder: AppColors.gold.withValues(alpha: 0.55),
        secondaryAccent: AppColors.goldDeep,
        title: isAr ? 'طرود وأغراض مع مسافر' : 'Parcels & Items on the Way',
        benefit: isAr
            ? 'أرسل الطرود والمستندات والأغراض الشخصية بسرعة مع مسافر في نفس الوجهة بتأكيد كود OTP.'
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

      // Pillar 3: Smart Shopping, Supply & Tasks (Unique 16:9 Editorial Studio Photo)
      _buildServicePillarCard(
        pillar: MashwarServicePillar.smartSupply,
        stepTag: isAr ? '03 · توريد ومهام' : '03 · Smart Supply',
        imageAsset: 'assets/images/pillar_smart_supply.jpg',
        useStudioContainFrame: false,
        primaryBg: AppColors.teal,
        primaryFg: Colors.white,
        primaryIconColor: Colors.white,
        secondaryBg: AppColors.tealSurface,
        secondaryBorder: AppColors.teal.withValues(alpha: 0.40),
        secondaryAccent: AppColors.teal,
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
              style: AppTypography.title().copyWith(fontSize: 19),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.goldSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                isAr ? 'ثنائي الاتجاه: اطلب أو نفّذ' : 'Request or Earn on Route',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w800),
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
    required String stepTag,
    required String imageAsset,
    required bool useStudioContainFrame,
    required Color primaryBg,
    required Color primaryFg,
    required Color primaryIconColor,
    required Color secondaryBg,
    required Color secondaryBorder,
    required Color secondaryAccent,
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
      borderRadius: BorderRadius.circular(22),
      borderColor: AppColors.warmBorder,
      hoverBorderColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full-Size 16:9 Uncropped Media Area — ZERO dark mud covering the subject!
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (useStudioContainFrame)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.warmBorder),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            primaryIcon,
                            size: 46,
                            color: AppColors.goldDeep,
                          ),
                        ),
                      ),
                    )
                  else
                    Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.navy,
                        child: Center(
                          child: Icon(
                            primaryIcon,
                            size: 46,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  // Crisp Top-Start Pillar Pill (never obscures the main subject!)
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        stepTag,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Clean Pure-White Editorial Body Below Full-Size Image
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MashwarServicePillarIcon(
                      pillar: pillar,
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title(color: AppColors.navy)
                            .copyWith(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
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
                  style: AppTypography.bodySecondary().copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    key: primaryKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBg,
                      foregroundColor: primaryFg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon, size: 17, color: primaryIconColor),
                    label: Text(
                      primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        fontFamily: 'Cairo',
                        color: primaryFg,
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
                      backgroundColor: secondaryBg,
                      side: BorderSide(color: secondaryBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 16, color: secondaryAccent),
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
    Widget buildTripCard(RideModel ride) {
      return MashwarHoverCard(
        key: ValueKey('home_live_trip_${ride.id}'),
        borderRadius: BorderRadius.circular(18),
        borderColor: AppColors.warmBorder,
        hoverBorderColor: AppColors.gold,
        padding: const EdgeInsets.all(13),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    ride.driverName.isNotEmpty ? ride.driverName[0] : 'M',
                    style: AppTypography.label(color: AppColors.gold)
                        .copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ride.driverName} · ${ride.driverRating.toStringAsFixed(1)} ★',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (ride.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAr
                        ? '${ride.remainingSeats} مقاعد شاغرة'
                        : '${ride.remainingSeats} empty seats',
                    style: AppTypography.label(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (ride.acceptsParcels)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAr ? 'يقبل طرود' : 'Accepts Parcels',
                      style: AppTypography.label(color: AppColors.teal)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            MashwarRouteTimeline(
              from: context.trCity(ride.fromCity),
              to: context.trCity(ride.toCity),
              trailingTop: '${ride.departureDate} · ${ride.departureTime}',
              compact: true,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Text(
                    isAr
                        ? '${ride.pricePerSeat} ر.ق / مقعد${ride.acceptsParcels ? " · طرد ${ride.parcelPrice} ر.ق" : ""}'
                        : '${ride.pricePerSeat} QAR / seat${ride.acceptsParcels ? " · Parcel ${ride.parcelPrice} QAR" : ""}',
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
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
                          horizontal: 13,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RideDetailsScreen(ride: ride),
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
                          foregroundColor: AppColors.navy,
                          backgroundColor: AppColors.goldSurface,
                          side: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.65),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SendParcelScreen(ride: ride),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: AppColors.goldDeep,
                        ),
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
      );
    }

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
                style: AppTypography.title().copyWith(fontSize: 18),
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
                style: AppTypography.label(color: AppColors.teal)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
          ...topTrips.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: buildTripCard(ride),
            ),
          ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarCategoryIcon(
                category: 'general_site_supply',
                size: 40,
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
                      style: AppTypography.title().copyWith(fontSize: 16),
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
          const SizedBox(height: 14),
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
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
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
      backgroundColor: hasActivity ? AppColors.goldSurface : Colors.white,
      borderColor: hasActivity
          ? AppColors.gold.withValues(alpha: 0.55)
          : AppColors.warmBorder,
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
              color: hasActivity ? AppColors.navy : AppColors.sand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasActivity
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
              size: 18,
              color: hasActivity ? AppColors.gold : AppColors.textSecondary,
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
                    style: AppTypography.bodySmall(color: AppColors.goldDeep)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w800),
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
                style: AppTypography.title().copyWith(fontSize: 18),
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
                style: AppTypography.label(color: AppColors.teal)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                borderRadius: BorderRadius.circular(18),
                borderColor: AppColors.warmBorder,
                hoverBorderColor: AppColors.teal,
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
                              MashwarBadge(
                                type: req.status == WorkRequestStatus.completed
                                    ? BadgeType.verified
                                    : BadgeType.confirmed,
                                customLabel: req.status.label(isArabic: isAr),
                              ),
                              Text(
                                req.effectiveTotalMinor.format(isArabic: isAr),
                                style: AppTypography.body(color: AppColors.teal)
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
                            foregroundColor: AppColors.teal,
                            backgroundColor: AppColors.tealSurface,
                            side: const BorderSide(color: AppColors.teal),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
                            style: AppTypography.label(color: AppColors.teal)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
      padding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      borderColor: AppColors.warmBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MashwarTrustEmblem(
                type: MashwarTrustType.liveCorridor,
                size: 38,
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
                      style: AppTypography.label(color: AppColors.teal)
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
                  color: AppColors.navy,
                ),
                label: Text(
                  _isMapExpanded
                      ? (isAr ? 'تصغير' : 'Compact')
                      : (isAr ? 'توسيع' : 'Expand'),
                  style: AppTypography.label(color: AppColors.navy)
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
              border: Border.all(color: AppColors.warmBorder),
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
                AppColors.gold,
                isAr ? 'مسارات الرحلات والطرود' : 'Trips & Parcels Routes',
              ),
              _buildLegendDot(
                AppColors.teal,
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
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navy : AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.warmBorder,
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(color: AppColors.textSecondary)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
          ),
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
        foregroundColor: isActive ? AppColors.teal : AppColors.navy,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isActive ? AppColors.teal : AppColors.gold,
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
          color: isActive ? AppColors.teal : AppColors.navy,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
    );

    return Container(
      key: const ValueKey('home_demo_showcase_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.tealSurface : AppColors.goldSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.4)
              : AppColors.gold.withValues(alpha: 0.45),
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
                color: isActive ? AppColors.teal : AppColors.goldDeep,
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
                  isAr ? 'اختيار الموقع المحفوظ' : 'Select Saved Location',
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
                      leading: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.goldDeep,
                      ),
                      title: Text(site.label),
                      subtitle: Text(
                        '${AppStrings.translateCity(site.municipality, isArabic: isAr)} · ${site.zoneOrStreet}',
                      ),
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
