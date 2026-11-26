import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/board_ad_model.dart';
import '../../data/models/ride_model.dart';
import '../../state/board_provider.dart';
import '../../state/rides_provider.dart';
import '../board/board_extra_screens.dart';
import '../board/make_offer_sheet.dart';
import '../board/post_ad_screen.dart';
import '../chat/chat_screen.dart';
import '../driver/publish_ride_screen.dart';
import '../home/city_search_modal.dart';
import '../parcel/send_parcel_screen.dart';
import '../ride_details/ride_details_screen.dart';

class TripsAndParcelsHubScreen extends StatefulWidget {
  const TripsAndParcelsHubScreen({
    super.key,
    this.embeddedInTab = false,
    this.initialTabIndex = 0, // 0 = Available Traveler Trips, 1 = Passenger & Parcel Route Requests
    this.initialAcceptsParcelsOnly = false,
    this.initialRequestFilter = 0, // 0 = All, 1 = Ride Requests, 2 = Parcel & Errand Requests
  });

  final bool embeddedInTab;
  final int initialTabIndex;
  final bool initialAcceptsParcelsOnly;
  final int initialRequestFilter;

  @override
  State<TripsAndParcelsHubScreen> createState() =>
      _TripsAndParcelsHubScreenState();
}

class _TripsAndParcelsHubScreenState extends State<TripsAndParcelsHubScreen> {
  late int _tabIndex;
  late int _requestFilter;
  double _swapTurns = 0.0;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex.clamp(0, 1);
    _requestFilter = widget.initialRequestFilter.clamp(0, 2);

    if (widget.initialAcceptsParcelsOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RidesProvider>().setFilterAcceptsParcels(true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant TripsAndParcelsHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabIndex = widget.initialTabIndex.clamp(0, 1);
    }
    if (widget.initialRequestFilter != oldWidget.initialRequestFilter) {
      _requestFilter = widget.initialRequestFilter.clamp(0, 2);
    }
    if (widget.initialAcceptsParcelsOnly !=
        oldWidget.initialAcceptsParcelsOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<RidesProvider>()
            .setFilterAcceptsParcels(widget.initialAcceptsParcelsOnly);
      });
    }
  }

  Future<void> _selectCity({
    required bool isFrom,
    required RidesProvider rides,
    required BoardProvider board,
    required bool isAr,
  }) async {
    final currentVal = isFrom
        ? (rides.fromCity.isNotEmpty ? rides.fromCity : board.fromFilter)
        : (rides.toCity.isNotEmpty ? rides.toCity : board.toFilter);

    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CitySearchModal(
          title: isFrom
              ? (isAr ? 'من أين تنطلق؟' : 'Departure City')
              : (isAr ? 'إلى أين تتجه؟' : 'Destination City'),
          initialValue: currentVal.isNotEmpty ? currentVal : null,
        ),
      ),
    );

    if (picked != null && picked.trim().isNotEmpty && mounted) {
      if (isFrom) {
        rides.setRoute(from: picked.trim());
        board.setRouteFilter(from: picked.trim());
      } else {
        rides.setRoute(to: picked.trim());
        board.setRouteFilter(to: picked.trim());
      }
    }
  }

  void _swapRoute(RidesProvider rides, BoardProvider board) {
    final currentFrom =
        rides.fromCity.isNotEmpty ? rides.fromCity : board.fromFilter;
    final currentTo = rides.toCity.isNotEmpty ? rides.toCity : board.toFilter;
    setState(() => _swapTurns += 0.5);
    rides.searchCorridor(from: currentTo, to: currentFrom);
    board.setRouteFilter(from: currentTo, to: currentFrom);
  }

  void _clearRoute(RidesProvider rides, BoardProvider board) {
    rides.clearRoute();
    board.clearRouteFilter();
  }

  void _openComposerSheet(BuildContext context, bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimens.radiusBottomSheet),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MashwarSheetHeader(
                      title: isAr
                          ? 'ماذا تريد أن تنشر اليوم؟'
                          : 'What would you like to post?',
                      subtitle: isAr
                          ? 'اختر نوع الرحلة أو الطلب ليظهر فوراً للمسافرين على نفس الخط'
                          : 'Choose how you want to connect along your route',
                      onClose: () => Navigator.of(sheetCtx).pop(),
                    ),
                    const SizedBox(height: 16),
                    _ComposerOptionTile(
                      pillar: MashwarServicePillar.sharedTrips,
                      accentColor: AppColors.cobalt,
                      surfaceColor: AppColors.cobaltSurface,
                      title: isAr
                          ? 'مسافر ولديك مقاعد شاغرة (انشر رحلتك)'
                          : 'Traveling with Empty Seats (Publish Trip)',
                      subtitle: isAr
                          ? 'شارك مقاعد سيارتك أو استقبل طروداً خفيفة في طريقك'
                          : 'Share empty car seats and optionally carry light parcels',
                      onTap: () {
                        final nav = Navigator.of(context);
                        Navigator.of(sheetCtx).pop();
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => const PublishRideScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ComposerOptionTile(
                      pillar: MashwarServicePillar.sharedTrips,
                      accentColor: AppColors.navy,
                      surfaceColor: AppColors.slateBg,
                      badgeIcon: Icons.person_pin_circle_outlined,
                      title: isAr
                          ? 'تبحث عن سفر لوجهة معينة (انشر طلب رحلة)'
                          : 'Looking for a Ride (Post Ride Request)',
                      subtitle: isAr
                          ? 'انشر وجهتك وموعدك ليصلك عرض مباشر من مسافر في نفس الطريق'
                          : 'Post your route and schedule so travelers heading there can offer a seat',
                      onTap: () {
                        final nav = Navigator.of(context);
                        Navigator.of(sheetCtx).pop();
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => const PostAdScreen(
                              initialCategory: BoardAdType.rideRequest,
                              initialIntent: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ComposerOptionTile(
                      pillar: MashwarServicePillar.routeParcels,
                      accentColor: AppColors.indigo,
                      surfaceColor: AppColors.indigoSurface,
                      title: isAr
                          ? 'أرسل طرداً أو غرضاً على الطريق'
                          : 'Send a Parcel or Item Along the Route',
                      subtitle: isAr
                          ? 'اختر مسافراً متجهاً الآن أو انشر طلب طرد محمي بكود الأمان OTP'
                          : 'Pick an active traveler or post an OTP-protected parcel request',
                      onTap: () {
                        final rides = context.read<RidesProvider>();
                        final nav = Navigator.of(context);
                        Navigator.of(sheetCtx).pop();
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => SendParcelScreen(
                              initialFromCity: rides.fromCity.isNotEmpty
                                  ? rides.fromCity
                                  : null,
                              initialToCity:
                                  rides.toCity.isNotEmpty ? rides.toCity : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<BoardAdModel> _filterBoardRequests(List<BoardAdModel> source) {
    Iterable<BoardAdModel> items = source;
    if (_requestFilter == 1) {
      items = items.where(
        (ad) =>
            ad.type == BoardAdType.rideRequest ||
            ad.type == BoardAdType.localTrip,
      );
    } else if (_requestFilter == 2) {
      items = items.where(
        (ad) =>
            ad.type == BoardAdType.parcelRequest ||
            ad.type == BoardAdType.errandService ||
            ad.type == BoardAdType.goodsDelivery,
      );
    } else {
      items = items.where((ad) => !ad.isOfferCard);
    }
    return items.toList();
  }

  @override
  Widget build(BuildContext context) {
    final rides = context.watch<RidesProvider>();
    final board = context.watch<BoardProvider>();
    final isAr = context.isArabic;

    final availableTrips = rides.filteredRides;
    final routeRequests = _filterBoardRequests(board.filteredAds);

    final activeFrom =
        rides.fromCity.isNotEmpty ? rides.fromCity : board.fromFilter;
    final activeTo = rides.toCity.isNotEmpty ? rides.toCity : board.toFilter;
    final hasRoute = activeFrom.isNotEmpty || activeTo.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !widget.embeddedInTab,
        leading: widget.embeddedInTab
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navy,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
        titleSpacing: widget.embeddedInTab ? 16 : 0,
        title: LayoutBuilder(
          builder: (context, titleConstraints) {
            final showPillarIcon = titleConstraints.maxWidth >= 110;
            final showSubtitle = titleConstraints.maxWidth >= 160;
            return Row(
              children: [
                if (showPillarIcon) ...[
                  const MashwarServicePillarIcon(
                    pillar: MashwarServicePillar.sharedTrips,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الرحلات والطرود' : 'Trips & Parcels',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title().copyWith(fontSize: 16.5),
                      ),
                      if (showSubtitle)
                        Text(
                          isAr
                              ? 'مقاعد شاغرة وطلبات طريق مباشرة بين المدن'
                              : 'Shared seats & parcels along active routes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.label(color: AppColors.textSecondary)
                                  .copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: FilledButton.icon(
                key: const ValueKey('hub_open_composer_btn'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 430 ? 10 : 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openComposerSheet(context, isAr),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  MediaQuery.sizeOf(context).width < 430
                      ? (isAr ? 'انشر' : 'Post')
                      : (isAr
                          ? '+ انشر رحلتك أو طلبك'
                          : '+ Post Trip or Request'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
            final isWide = constraints.maxWidth >= 860;
            final hPad = isWide ? AppDimens.space24 : AppDimens.space16;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1180 : 740),
                child: Column(
                  children: [
                    // Top Route Filter & Segment Control Header
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.slateBorder),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Interactive Route Filter Bar
                          _buildRouteFilterBar(
                            rides: rides,
                            board: board,
                            activeFrom: activeFrom,
                            activeTo: activeTo,
                            hasRoute: hasRoute,
                            isAr: isAr,
                          ),
                          const SizedBox(height: 10),

                          // Quick Contextual Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildParcelsFilterChip(rides, isAr),
                                const SizedBox(width: 8),
                                if (_tabIndex == 0) ...[
                                  MashwarChip(
                                    label: isAr ? 'الأقرب وقتاً' : 'Earliest',
                                    isSelected:
                                        rides.sortBy == SortOption.closestTime,
                                    onTap: () => rides
                                        .setSortOption(SortOption.closestTime),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr ? 'الأقل تكلفة' : 'Lowest Cost',
                                    isSelected:
                                        rides.sortBy == SortOption.cheapest,
                                    onTap: () => rides
                                        .setSortOption(SortOption.cheapest),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr ? 'سيدات فقط' : 'Ladies Only',
                                    isSelected: rides.filterLadiesOnly,
                                    onTap: rides.toggleFilterLadiesOnly,
                                  ),
                                ] else ...[
                                  MashwarChip(
                                    label: isAr ? 'كل الطلبات' : 'All Requests',
                                    isSelected: _requestFilter == 0,
                                    onTap: () =>
                                        setState(() => _requestFilter = 0),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr
                                        ? 'طلبات مقاعد وسفر'
                                        : 'Ride Requests',
                                    isSelected: _requestFilter == 1,
                                    onTap: () =>
                                        setState(() => _requestFilter = 1),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr
                                        ? 'طرود ومهام على الطريق'
                                        : 'Parcels & Errands',
                                    isSelected: _requestFilter == 2,
                                    onTap: () =>
                                        setState(() => _requestFilter = 2),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Smooth 2-Segment Switcher
                          _buildSegmentedSwitcher(
                            isAr: isAr,
                            tripsCount: availableTrips.length,
                            requestsCount: routeRequests.length,
                          ),
                        ],
                      ),
                    ),

                    // Feed Body
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.cobalt,
                        onRefresh: () async {
                          await Future.wait([
                            rides.loadRides(),
                            board.loadBoardAds(),
                          ]);
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _tabIndex == 0
                              ? _buildTripsFeed(
                                  key: const ValueKey('hub_trips_feed_view'),
                                  trips: availableTrips,
                                  rides: rides,
                                  board: board,
                                  hasRoute: hasRoute,
                                  isAr: isAr,
                                  isWide: isWide,
                                  hPad: hPad,
                                )
                              : _buildRequestsFeed(
                                  key: const ValueKey('hub_requests_feed_view'),
                                  requests: routeRequests,
                                  rides: rides,
                                  board: board,
                                  hasRoute: hasRoute,
                                  isAr: isAr,
                                  isWide: isWide,
                                  hPad: hPad,
                                ),
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

  Widget _buildRouteFilterBar({
    required RidesProvider rides,
    required BoardProvider board,
    required String activeFrom,
    required String activeTo,
    required bool hasRoute,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasRoute
              ? AppColors.cobalt.withValues(alpha: 0.35)
              : AppColors.slateBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectCity(
                isFrom: true,
                rides: rides,
                board: board,
                isAr: isAr,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr ? 'من أين' : 'From',
                            style: AppTypography.label(
                              color: AppColors.textSecondary,
                            ).copyWith(fontSize: 10),
                          ),
                          Text(
                            activeFrom.isNotEmpty
                                ? context.trCity(activeFrom)
                                : (isAr ? 'كل نقاط الانطلاق' : 'Any origin'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body().copyWith(
                              fontSize: 13,
                              fontWeight: activeFrom.isNotEmpty
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: activeFrom.isNotEmpty
                                  ? AppColors.navy
                                  : AppColors.textSecondary,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _swapRoute(rides, board),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: AnimatedRotation(
                  turns: _swapTurns,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: AppColors.cobalt,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectCity(
                isFrom: false,
                rides: rides,
                board: board,
                isAr: isAr,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.cobalt,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr ? 'إلى أين' : 'To',
                            style: AppTypography.label(
                              color: AppColors.textSecondary,
                            ).copyWith(fontSize: 10),
                          ),
                          Text(
                            activeTo.isNotEmpty
                                ? context.trCity(activeTo)
                                : (isAr ? 'كل الوجهات' : 'Any destination'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body().copyWith(
                              fontSize: 13,
                              fontWeight: activeTo.isNotEmpty
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: activeTo.isNotEmpty
                                  ? AppColors.navy
                                  : AppColors.textSecondary,
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
          if (hasRoute) ...[
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: isAr ? 'مسح المسار' : 'Clear route',
              onPressed: () => _clearRoute(rides, board),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParcelsFilterChip(RidesProvider rides, bool isAr) {
    final selected = rides.filterAcceptsParcels;
    return InkWell(
      key: const ValueKey('hub_filter_parcels_chip'),
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        rides.toggleFilterAcceptsParcels();
        if (_tabIndex == 1 && !selected) {
          setState(() => _requestFilter = 2);
        } else if (_tabIndex == 1 && selected && _requestFilter == 2) {
          setState(() => _requestFilter = 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : AppColors.indigoSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.indigo
                : AppColors.indigo.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 14,
              color: selected ? Colors.white : AppColors.indigo,
            ),
            const SizedBox(width: 6),
            Text(
              isAr ? 'يقبل طرود في طريقه' : 'Accepts Parcels on Route',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.indigo,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher({
    required bool isAr,
    required int tripsCount,
    required int requestsCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTabButton(
              key: const ValueKey('hub_tab_trips'),
              isSelected: _tabIndex == 0,
              accentColor: AppColors.cobalt,
              icon: Icons.directions_car_outlined,
              label: isAr
                  ? 'مسافرون بمقاعد شاغرة'
                  : 'Available Traveler Trips',
              count: tripsCount,
              onTap: () => setState(() => _tabIndex = 0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegmentTabButton(
              key: const ValueKey('hub_tab_requests'),
              isSelected: _tabIndex == 1,
              accentColor: AppColors.emerald,
              icon: Icons.alt_route_rounded,
              label: isAr
                  ? 'طلبات مسافرين وطرود'
                  : 'Route & Parcel Requests',
              count: requestsCount,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsFeed({
    required Key key,
    required List<RideModel> trips,
    required RidesProvider rides,
    required BoardProvider board,
    required bool hasRoute,
    required bool isAr,
    required bool isWide,
    required double hPad,
  }) {
    if (trips.isEmpty) {
      return ListView(
        key: key,
        padding: EdgeInsets.all(hPad),
        children: [
          const SizedBox(height: 32),
          _buildEmptyStateCard(
            pillar: MashwarServicePillar.sharedTrips,
            title: isAr
                ? 'لا توجد رحلات مطابقة لهذا المسار حالياً'
                : 'No matching traveler trips right now',
            subtitle: isAr
                ? 'انشر طلب رحلة أو طرد على هذا المسار ليصلك عرض فور تحرك مسافر بنفس الاتجاه.'
                : 'Post a route or parcel request so travelers heading this way can send you an offer.',
            primaryLabel:
                isAr ? 'اطلب مقعداً أو طرداً على المسار' : 'Post Route Request',
            onPrimary: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PostAdScreen(
                    initialCategory: BoardAdType.rideRequest,
                    initialIntent: 0,
                  ),
                ),
              );
            },
            secondaryLabel: hasRoute
                ? (isAr ? 'عرض كل المسارات' : 'Show All Routes')
                : null,
            onSecondary:
                hasRoute ? () => _clearRoute(rides, board) : null,
          ),
        ],
      );
    }

    if (!isWide) {
      return ListView.builder(
        key: key,
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 88),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildTripCard(context, trips[index], isAr, index),
          );
        },
      );
    }

    final rowCount = (trips.length / 2).ceil();
    return ListView.builder(
      key: key,
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 88),
      itemCount: rowCount,
      itemBuilder: (context, rowIdx) {
        final first = rowIdx * 2;
        final second = first + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTripCard(context, trips[first], isAr, first),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: second < trips.length
                    ? _buildTripCard(context, trips[second], isAr, second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    RideModel ride,
    bool isAr,
    int index,
  ) {
    return MashwarFadeSlideIn(
      duration: Duration(milliseconds: 220 + (index.clamp(0, 4) * 25)),
      offsetY: 10,
      child: MashwarHoverCard(
        borderColor: AppColors.slateBorder,
        hoverBorderColor: AppColors.cobalt,
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Departure time, Date, and Seat Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ride.departureTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      Text(
                        context.trDate(ride.departureDate),
                        style: AppTypography.label(
                          color: AppColors.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (ride.isInstantBooking)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cobaltSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAr ? 'حجز فوري' : 'Instant',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cobalt,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cobaltSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.cobalt.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${ride.pricePerSeat}',
                        style: AppTypography.title(color: AppColors.cobalt)
                            .copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAr ? 'ر.ق / مقعد' : 'QAR / seat',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route Timeline Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MashwarRouteTimeline(
                    from:
                        '${context.trCity(ride.fromCity)} · ${ride.pickupPoint}',
                    to: '${context.trCity(ride.toCity)} · ${ride.dropoffPoint}',
                    compact: true,
                  ),
                  if (ride.stopoverCity != null &&
                      ride.stopoverCity!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.linear_scale_rounded,
                          size: 14,
                          color: AppColors.cobalt,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'يمر عبر: ${context.trCity(ride.stopoverCity!)}'
                                : 'Via: ${context.trCity(ride.stopoverCity!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(color: AppColors.cobalt)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Traveler Info + Remaining Seats + Parcel Capability Badges
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cobaltSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cobalt.withValues(alpha: 0.25),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ride.driverName.isNotEmpty ? ride.driverName[0] : 'M',
                    style: AppTypography.title(color: AppColors.cobalt)
                        .copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body()
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (ride.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.emerald,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${ride.driverRating}',
                            style: AppTypography.label()
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '· ${ride.driverCar}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: isAr ? 'محادثة المسافر' : 'Chat Traveler',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          driverName: ride.driverName,
                          driverCar: ride.driverCar,
                          tripRoute: context
                              .trRoute('${ride.fromCity} ← ${ride.toCity}'),
                        ),
                      ),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.slateBg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status & Parcel Badges Row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ride.remainingSeats > 0
                        ? AppColors.emeraldSurface
                        : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (ride.remainingSeats > 0
                              ? AppColors.emerald
                              : AppColors.danger)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_seat_outlined,
                        size: 13,
                        color: ride.remainingSeats > 0
                            ? AppColors.emerald
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ride.remainingSeats > 0
                              ? (isAr
                                  ? '${ride.remainingSeats} مقاعد شاغرة'
                                  : '${ride.remainingSeats} empty seats')
                              : (isAr ? 'مكتمل المقاعد' : 'Seats Full'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ride.remainingSeats > 0
                                ? AppColors.emerald
                                : AppColors.danger,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ride.acceptsParcels)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigoSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.indigo.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 13,
                          color: AppColors.indigo,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isAr
                                ? 'يقبل توصيل طرود (${ride.parcelPrice} ر.ق)'
                                : 'Accepts Parcels (${ride.parcelPrice} QAR)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.indigo,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (ride.isLadiesOnly)
                  const MashwarBadge(type: BadgeType.ladiesOnly),
              ],
            ),
            const SizedBox(height: 14),

            // Dual Action Row: Book Seat + Send Parcel With Traveler
            LayoutBuilder(
              builder: (context, actionConstraints) {
                final stackButtons =
                    actionConstraints.maxWidth < 290 && ride.acceptsParcels;

                final bookBtn = FilledButton.icon(
                  key: ValueKey('hub_book_seat_${ride.id}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RideDetailsScreen(ride: ride),
                      ),
                    );
                  },
                  icon: const Icon(Icons.airline_seat_recline_normal_rounded,
                      size: 16),
                  label: Text(
                    isAr ? 'حجز مقعد' : 'Book Seat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                );

                if (!ride.acceptsParcels) {
                  return SizedBox(width: double.infinity, child: bookBtn);
                }

                final parcelBtn = OutlinedButton.icon(
                  key: ValueKey('hub_send_parcel_${ride.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.indigo,
                    backgroundColor: AppColors.indigoSurface,
                    side: BorderSide(
                      color: AppColors.indigo.withValues(alpha: 0.35),
                    ),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SendParcelScreen(ride: ride),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(
                    isAr ? 'أرسل طرداً معه' : 'Send Parcel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                );

                if (stackButtons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      bookBtn,
                      const SizedBox(height: 8),
                      parcelBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: bookBtn),
                    const SizedBox(width: 10),
                    Expanded(child: parcelBtn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsFeed({
    required Key key,
    required List<BoardAdModel> requests,
    required RidesProvider rides,
    required BoardProvider board,
    required bool hasRoute,
    required bool isAr,
    required bool isWide,
    required double hPad,
  }) {
    if (requests.isEmpty) {
      return ListView(
        key: key,
        padding: EdgeInsets.all(hPad),
        children: [
          const SizedBox(height: 32),
          _buildEmptyStateCard(
            pillar: MashwarServicePillar.routeParcels,
            title: isAr
                ? 'لا توجد طلبات مسجلة على هذا الخط حالياً'
                : 'No open route requests right now',
            subtitle: isAr
                ? 'كن أول من ينشر طلب سفر أو توصيل طرد على هذا المسار.'
                : 'Be the first to post a ride or parcel request on this route.',
            primaryLabel: isAr ? 'أرسل طرداً على الطريق' : 'Send Route Parcel',
            onPrimary: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SendParcelScreen()),
              );
            },
            secondaryLabel: (hasRoute || _requestFilter != 0)
                ? (isAr ? 'عرض كافة الطلبات' : 'Show All Requests')
                : null,
            onSecondary: (hasRoute || _requestFilter != 0)
                ? () {
                    setState(() => _requestFilter = 0);
                    _clearRoute(rides, board);
                  }
                : null,
          ),
        ],
      );
    }

    if (!isWide) {
      return ListView.builder(
        key: key,
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 88),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildRequestCard(context, requests[index], isAr, index),
          );
        },
      );
    }

    final rowCount = (requests.length / 2).ceil();
    return ListView.builder(
      key: key,
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 88),
      itemCount: rowCount,
      itemBuilder: (context, rowIdx) {
        final first = rowIdx * 2;
        final second = first + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRequestCard(context, requests[first], isAr, first),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: second < requests.length
                    ? _buildRequestCard(context, requests[second], isAr, second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    BoardAdModel ad,
    bool isAr,
    int index,
  ) {
    final isParcelOrErrand = ad.type == BoardAdType.parcelRequest ||
        ad.type == BoardAdType.errandService ||
        ad.type == BoardAdType.goodsDelivery;
    final accent = isParcelOrErrand ? AppColors.indigo : AppColors.cobalt;
    final surface =
        isParcelOrErrand ? AppColors.indigoSurface : AppColors.cobaltSurface;
    final isOwnAd = ad.id.startsWith('my_ad_');
    final isOfferSent = ad.status == BoardAdStatus.offerSent;

    void openOfferFlow() {
      if (isOwnAd) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BoardAdOffersScreen(ad: ad)),
        );
      } else {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MakeOfferSheet(ad: ad),
        );
      }
    }

    return MashwarFadeSlideIn(
      duration: Duration(milliseconds: 220 + (index.clamp(0, 4) * 25)),
      offsetY: 10,
      child: MashwarHoverCard(
        borderColor:
            isOfferSent ? AppColors.emerald : AppColors.slateBorder,
        hoverBorderColor: accent,
        padding: const EdgeInsets.all(16),
        onTap: openOfferFlow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Requester Info + Service Type Tag
            Row(
              children: [
                MashwarServicePillarIcon(
                  pillar: isParcelOrErrand
                      ? MashwarServicePillar.routeParcels
                      : MashwarServicePillar.sharedTrips,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ad.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body()
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (ad.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.emerald,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${context.trDate(ad.timeAgo)} · ★ ${ad.authorRating}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    ad.displaySubTag(isAr),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route & Preferred Time
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MashwarRouteTimeline(
                    from: context.trCity(ad.fromCity),
                    to: context.trCity(ad.toCity),
                    trailingBottom: ad.isLadiesOnly
                        ? const MashwarBadge(type: BadgeType.ladiesOnly)
                        : null,
                    compact: true,
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.slateBorder),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          ad.timeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Text(
              ad.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySecondary().copyWith(fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Footer: Offered Reward + Traveler Offer Button & Chat
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.priceTagLabel(isAr),
                      style: AppTypography.label(color: AppColors.textSecondary)
                          .copyWith(fontSize: 10.5),
                    ),
                    Text(
                      '${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                if (!isOwnAd)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: isAr ? 'محادثة مباشرة' : 'Direct Chat',
                    onPressed: () {
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
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('hub_make_offer_${ad.id}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isOfferSent ? AppColors.emerald : accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: openOfferFlow,
                    child: Text(
                      isOwnAd
                          ? (isAr ? 'مراجعة العروض' : 'View Offers')
                          : isOfferSent
                              ? (isAr
                                  ? 'تم إرسال عرضك (${ad.myOfferPrice ?? ad.priceOrBudget} ر.ق)'
                                  : 'Offer Sent (${ad.myOfferPrice ?? ad.priceOrBudget} QAR)')
                              : (isAr
                                  ? 'أنا في هذا الطريق · أرسل عرضاً'
                                  : 'On My Route · Send Offer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required MashwarServicePillar pillar,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarServicePillarIcon(pillar: pillar, size: 56),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.title().copyWith(fontSize: 16.5),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPrimary,
            child: Text(
              primaryLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentTabButton extends StatelessWidget {
  const _SegmentTabButton({
    super.key,
    required this.isSelected,
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final bool isSelected;
  final Color accentColor;
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.navy : AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? accentColor : AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerOptionTile extends StatelessWidget {
  const _ComposerOptionTile({
    required this.pillar,
    required this.accentColor,
    required this.surfaceColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeIcon,
  });

  final MashwarServicePillar pillar;
  final Color accentColor;
  final Color surfaceColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    return MashwarHoverCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.slateBorder,
      hoverBorderColor: accentColor,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          if (badgeIcon != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: accentColor.withValues(alpha: 0.22)),
              ),
              child: Icon(badgeIcon, color: accentColor, size: 22),
            )
          else
            MashwarServicePillarIcon(pillar: pillar, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary,
                  ).copyWith(fontSize: 11.5, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: accentColor,
          ),
        ],
      ),
    );
  }
}
