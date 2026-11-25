import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';
import '../../state/alerts_provider.dart';
import '../../state/rides_provider.dart';
import '../chat/chat_screen.dart';
import '../parcel/send_parcel_screen.dart';
import '../ride_details/ride_details_screen.dart';
import 'search_filters_sheet.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final bool _isOffline = false;
  final bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final rides = context.watch<RidesProvider>();
    final alerts = context.watch<AlertsProvider>();
    final results = rides.filteredRides;
    final isAr = context.isArabic;

    final hasCorridor =
        rides.fromCity.trim().isNotEmpty && rides.toCity.trim().isNotEmpty;
    final routeTitle = hasCorridor
        ? context.trRoute('${rides.fromCity} ← ${rides.toCity}')
        : (rides.fromCity.trim().isNotEmpty
            ? '${isAr ? "من" : "From"} ${context.trCity(rides.fromCity)}'
            : (rides.toCity.trim().isNotEmpty
                ? '${isAr ? "إلى" : "To"} ${context.trCity(rides.toCity)}'
                : (isAr ? 'كل المسارات المتاحة' : 'All Available Routes')));

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title().copyWith(fontSize: 17),
            ),
            Text(
              '${context.trDate(rides.date)} · ${rides.rideMode == RideMode.seats ? (isAr ? "${rides.seatsCount} ${rides.seatsCount == 1 ? "مقعد" : "مقاعد"}" : "${rides.seatsCount} ${rides.seatsCount == 1 ? "Seat" : "Seats"}") : (isAr ? "توصيل طرد" : "Parcel on Route")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.navy),
            tooltip: isAr ? 'فلترة' : 'Filters',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SearchFiltersSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final hPad = isWide ? AppDimens.space20 : AppDimens.space16;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 700),
                child: Column(
                  children: [
                    // Quick Filter Chips Bar
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  MashwarChip(
                                    label: isAr ? 'الأقرب وقتاً' : 'Earliest',
                                    isSelected:
                                        rides.sortBy == SortOption.closestTime,
                                    onTap: () => rides
                                        .setSortOption(SortOption.closestTime),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr ? 'الأرخص' : 'Lowest Cost',
                                    isSelected:
                                        rides.sortBy == SortOption.cheapest,
                                    onTap: () => rides
                                        .setSortOption(SortOption.cheapest),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr
                                        ? 'تقبل طرود'
                                        : 'Accepts Parcels',
                                    isSelected: rides.filterAcceptsParcels,
                                    onTap: rides.toggleFilterAcceptsParcels,
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label:
                                        isAr ? 'للسيدات فقط' : 'Ladies Only',
                                    isSelected: rides.filterLadiesOnly,
                                    onTap: rides.toggleFilterLadiesOnly,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isWide && results.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cobaltSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.cobalt.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                isAr
                                    ? '${results.length} رحلة متاحة'
                                    : '${results.length} trips found',
                                style: AppTypography.label(
                                  color: AppColors.cobalt,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.slateBorder),

                    // Corridor Map Preview when origin & destination are set
                    if (hasCorridor)
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 6),
                        child: Container(
                          height: 136,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              QatarLiveMapCanvas(
                                style: QatarMapStyle.routeFocused,
                                activeFromCity: rides.fromCity,
                                activeToCity: rides.toCity,
                                showWaterLabels: false,
                                borderRadius: 15,
                              ),
                              PositionedDirectional(
                                top: 8,
                                start: 8,
                                child: FutureBuilder<RouteDetails>(
                                  future: AppRepositories.instance.maps
                                      .getRouteDetails(
                                    rides.fromCity,
                                    rides.toCity,
                                  ),
                                  builder: (context, snapshot) {
                                    final details = snapshot.data;
                                    final distLabel = details != null
                                        ? '${details.distanceKm.round()} ${isAr ? "كم" : "km"}'
                                        : (isAr
                                            ? 'مسار مباشر'
                                            : 'Direct corridor');
                                    final mins = details?.durationMinutes ?? 40;
                                    final hours = mins ~/ 60;
                                    final rem = mins % 60;
                                    final timeStr = hours > 0
                                        ? (isAr
                                            ? '$hours س و $rem د'
                                            : '${hours}h ${rem}m')
                                        : (isAr ? '$rem د' : '${rem}m');
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.94),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.cobalt
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.alt_route_rounded,
                                            color: AppColors.cobalt,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '$distLabel · ~$timeStr',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_isOffline)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: 8,
                        ),
                        child: AlertBanner(
                          message: isAr
                              ? 'أنت في وضع غير متصل. النتائج المعروضة من آخر تحديث'
                              : 'You are offline. Showing cached results',
                          type: AlertBannerType.offline,
                        ),
                      ),

                    Expanded(
                      child: _hasError
                          ? _buildErrorState(isAr)
                          : results.isEmpty
                              ? _buildEmptyState(context, rides, alerts, isAr)
                              : _buildResultsList(
                                  context,
                                  results,
                                  isAr,
                                  isWide: isWide,
                                  hPad: hPad,
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

  Widget _buildResultsList(
    BuildContext context,
    List<RideModel> ridesList,
    bool isAr, {
    required bool isWide,
    required double hPad,
  }) {
    if (!isWide) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
        itemCount: ridesList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildDriverCard(context, ridesList[index], isAr),
          );
        },
      );
    }

    final pairCount = (ridesList.length / 2).ceil();
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
      itemCount: pairCount,
      itemBuilder: (context, rowIndex) {
        final first = rowIndex * 2;
        final second = first + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDriverCard(context, ridesList[first], isAr),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: second < ridesList.length
                    ? _buildDriverCard(context, ridesList[second], isAr)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriverCard(BuildContext context, RideModel ride, bool isAr) {
    return MashwarFadeSlideIn(
      duration: const Duration(milliseconds: 240),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.trRoute('${ride.fromCity} ← ${ride.toCity}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body()
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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
                      const SizedBox(width: 2),
                      Text(
                        isAr ? 'ر.ق' : 'QAR',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: MashwarRouteTimeline(
                from: ride.pickupPoint,
                to: ride.dropoffPoint,
                compact: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.cobaltSurface,
                    shape: BoxShape.circle,
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
                              size: 14,
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
                          Text('${ride.driverRating}', style: AppTypography.label()),
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
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.slateBorder),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (ride.remainingSeats == 0)
                  MashwarBadge(
                    type: BadgeType.rejected,
                    customLabel: isAr ? 'مكتمل' : 'Full',
                  )
                else if (ride.isLadiesOnly)
                  MashwarBadge(
                    type: BadgeType.ladiesOnly,
                    customLabel: isAr ? 'سيدات فقط' : 'Ladies Only',
                  )
                else
                  MashwarBadge(
                    type: BadgeType.verified,
                    customLabel: isAr
                        ? 'متاح (${ride.remainingSeats})'
                        : 'Available (${ride.remainingSeats})',
                  ),
                if (ride.acceptsParcels)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SendParcelScreen(ride: ride),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigoSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.indigo.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: AppColors.indigo,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isAr
                                  ? 'يقبل توصيل طرود (${ride.parcelPrice} ر.ق)'
                                  : 'Parcels OK (${ride.parcelPrice} QAR)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(color: AppColors.indigo)
                                  .copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildEmptyState(
    BuildContext context,
    RidesProvider rides,
    AlertsProvider alerts,
    bool isAr,
  ) {
    final fromLabel =
        rides.fromCity.isNotEmpty ? context.trCity(rides.fromCity) : '';
    final toLabel = rides.toCity.isNotEmpty ? context.trCity(rides.toCity) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.space24),
              const MashwarServicePillarIcon(
                pillar: MashwarServicePillar.sharedTrips,
                size: 64,
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                isAr
                    ? 'لا توجد رحلات مطابقة حالياً'
                    : 'No matching rides right now',
                style: AppTypography.title(),
              ),
              const SizedBox(height: 8),
              Text(
                fromLabel.isNotEmpty && toLabel.isNotEmpty
                    ? (isAr
                        ? 'فعّل التنبيه الفوري وسنبلغك بمجرد نشر رحلة على مسار $fromLabel ← $toLabel'
                        : 'Create a route alert to get notified when a trip opens on $fromLabel → $toLabel')
                    : (isAr
                        ? 'جرّب توسيع الفلاتر أو إنشاء تنبيه للمسار المطلوب'
                        : 'Try clearing filters or setting a route alert'),
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: AppDimens.space24),
              MashwarButton(
                text: isAr
                    ? 'نبّهني عند توفر رحلة'
                    : 'Alert me when rides are added',
                onPressed: () {
                  alerts.addAlert(
                    fromCity:
                        rides.fromCity.isNotEmpty ? rides.fromCity : 'الدوحة',
                    toCity: rides.toCity.isNotEmpty ? rides.toCity : 'لوسيل',
                    dateRange: rides.date,
                    category: rides.rideMode == RideMode.seats
                        ? (isAr ? 'مقاعد' : 'Seats')
                        : (isAr ? 'طرود' : 'Parcels'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم تفعيل تنبيه المسار بنجاح'
                            : 'Route alert activated',
                      ),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isAr) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'حدث خطأ أثناء تحميل النتائج'
                    : 'Error loading search results',
                style: AppTypography.title(),
              ),
              const SizedBox(height: 16),
              MashwarButton(
                text: isAr ? 'إعادة المحاولة' : 'Retry',
                onPressed: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
