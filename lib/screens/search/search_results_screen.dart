import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../../state/alerts_provider.dart';
import '../chat/chat_screen.dart';
import '../ride_details/ride_details_screen.dart';
import 'search_filters_sheet.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.trRoute('${rides.fromCity} ← ${rides.toCity}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title().copyWith(fontSize: 18),
            ),
            Text(
              '${context.trDate(rides.date)} · ${rides.rideMode == RideMode.seats ? (isAr ? "${rides.seatsCount} ${rides.seatsCount == 1 ? "مقعد" : "مقاعد"}" : "${rides.seatsCount} ${rides.seatsCount == 1 ? "Seat" : "Seats"}") : (isAr ? "طرد واحد" : "1 Parcel")}',
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
              showModalBottomSheet(
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
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 680),
                child: Column(
                  children: [
                    // Quick Filter Chips Bar (Page 10) + Result Count on wide screens
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  MashwarChip(
                                    label: isAr ? 'الأقرب وقتاً' : 'Earliest',
                                    isSelected: rides.sortBy == SortOption.closestTime,
                                    onTap: () => rides.setSortOption(SortOption.closestTime),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr ? 'الأرخص' : 'Cheapest',
                                    isSelected: rides.sortBy == SortOption.cheapest,
                                    onTap: () => rides.setSortOption(SortOption.cheapest),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr ? 'تقبل طرود' : 'Accepts Parcels',
                                    isSelected: rides.filterAcceptsParcels,
                                    onTap: () => rides.toggleFilterAcceptsParcels(),
                                  ),
                                  const SizedBox(width: 8),
                                  MashwarChip(
                                    label: isAr ? 'للسيدات فقط' : 'Ladies Only',
                                    isSelected: rides.filterLadiesOnly,
                                    onTap: () => rides.toggleFilterLadiesOnly(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isWide && results.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderDisabled),
                              ),
                              child: Text(
                                isAr ? '${results.length} رحلة متاحة' : '${results.length} rides found',
                                style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Live Qatar Route Corridor Mini-Map Preview + Metrics
                    if (rides.fromCity.isNotEmpty && rides.toCity.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppDimens.space20, 0, AppDimens.space20, 8),
                        child: Container(
                          height: 112,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                                  future: AppRepositories.instance.maps.getRouteDetails(rides.fromCity, rides.toCity),
                                  builder: (context, snapshot) {
                                    final details = snapshot.data;
                                    final distLabel = details != null
                                        ? '${details.distanceKm.round()} ${isAr ? "كم" : "km"}'
                                        : (isAr ? 'مسار مباشر' : 'Direct route');
                                    final mins = details?.durationMinutes ?? 40;
                                    final hours = mins ~/ 60;
                                    final rem = mins % 60;
                                    final timeStr = hours > 0
                                        ? (isAr ? '$hours س و $rem د' : '${hours}h ${rem}m')
                                        : (isAr ? '$rem د' : '${rem}m');
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.94),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.alt_route_rounded, color: AppColors.teal, size: 14),
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

                    // Offline Banner State (Page 18)
                    if (_isOffline) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space12),
                        child: AlertBanner(
                          message: isAr
                              ? 'أنت في وضع غير متصل. النتائج المعروضة من آخر تحديث'
                              : 'You are offline. Results shown are from last update',
                          type: AlertBannerType.offline,
                        ),
                      ),
                    ],

                    // Content Area: Results, Empty, or Error
                    Expanded(
                      child: _hasError
                          ? _buildErrorState(isAr)
                          : results.isEmpty
                              ? _buildEmptyState(context, rides, alerts, isAr)
                              : _buildResultsList(context, results, isAr, isWide: isWide),
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

  Widget _buildResultsList(BuildContext context, List<RideModel> ridesList, bool isAr, {bool isWide = false}) {
    if (!isWide) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space12),
        itemCount: ridesList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.space16),
            child: _buildDriverCard(context, ridesList[index], isAr),
          );
        },
      );
    }

    final pairCount = (ridesList.length / 2).ceil();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space12),
      itemCount: pairCount,
      itemBuilder: (context, rowIndex) {
        final first = rowIndex * 2;
        final second = first + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDriverCard(context, ridesList[first], isAr)),
              const SizedBox(width: AppDimens.space16),
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
      duration: const Duration(milliseconds: 260),
      offsetY: 10,
      child: MashwarPressable(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space20),
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
              // Top row: Departure time badge, Route title, and Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ride.departureTime,
                            style: const TextStyle(
                              fontSize: 13,
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
                            style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${ride.pricePerSeat}',
                          style: AppTypography.largeTitle().copyWith(fontSize: 19, color: AppColors.navy),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isAr ? 'ر.ق' : 'QAR',
                          style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Visual Route Timeline for Pickup & Dropoff
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MashwarRouteTimeline(
                  from: ride.pickupPoint,
                  to: ride.dropoffPoint,
                  compact: true,
                ),
              ),

              const SizedBox(height: 14),

              // Driver Info, Rating & 1-Tap Chat
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navy.withValues(alpha: 0.12), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        ride.driverName.isNotEmpty ? ride.driverName[0] : 'ك',
                        style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 17),
                      ),
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
                                style: AppTypography.body().copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (ride.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 15, color: AppColors.teal),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 15, color: AppColors.gold),
                            const SizedBox(width: 2),
                            Text('${ride.driverRating}', style: AppTypography.label()),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '· ${ride.driverCar}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: isAr ? 'محادثة السائق' : 'Chat Driver',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppColors.navy),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            driverName: ride.driverName,
                            driverCar: ride.driverCar,
                            tripRoute: context.trRoute('${ride.fromCity} ← ${ride.toCity}'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status Badge & Parcel Tag (Wrap prevents tight-width overflow on 320px screens)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (ride.remainingSeats == 0)
                    MashwarBadge(type: BadgeType.rejected, customLabel: isAr ? 'مكتمل' : 'Full')
                  else if (ride.isLadiesOnly)
                    MashwarBadge(type: BadgeType.ladiesOnly, customLabel: isAr ? 'سيدات فقط' : 'Ladies Only')
                  else
                    MashwarBadge(
                      type: BadgeType.verified,
                      customLabel: isAr ? 'متاح (${ride.remainingSeats})' : 'Available (${ride.remainingSeats})',
                    ),
                  if (ride.acceptsParcels)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.35), width: 0.8),
                      ),
                      child: Text(
                        isAr ? 'يقبل طرود' : 'Parcels OK',
                        style: AppTypography.label(color: AppColors.teal).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Page 18: Empty State + Route Alert Creation
  Widget _buildEmptyState(BuildContext context, RidesProvider rides, AlertsProvider alerts, bool isAr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.space24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MashwarAssetArt(
                  assetPath: 'assets/images/service_ride.jpg',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(16),
                  fallbackIcon: Icons.directions_car_outlined,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                isAr ? 'لا توجد رحلات مطابقة حالياً' : 'No matching rides right now',
                style: AppTypography.title(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'أنشئ تنبيه وسنبلّغك فور توفر رحلة على مسار\n${rides.fromCity} ← ${rides.toCity}'
                    : 'Create an alert and we will notify you when a ride is available on\n${context.trCity(rides.fromCity)} → ${context.trCity(rides.toCity)}',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: AppDimens.space24),

              MashwarButton(
                text: isAr ? 'نبّهني عند توفر رحلة' : 'Alert me when rides are added',
                onPressed: () {
                  alerts.addAlert(
                    fromCity: rides.fromCity,
                    toCity: rides.toCity,
                    dateRange: rides.date,
                    category: rides.rideMode == RideMode.seats ? (isAr ? 'مقاعد' : 'Seats') : (isAr ? 'طرود' : 'Parcels'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم إنشاء التنبيه بنجاح' : 'Alert created successfully'),
                      backgroundColor: AppColors.teal,
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
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(isAr ? 'حدث خطأ أثناء تحميل النتائج' : 'Error loading search results', style: AppTypography.title()),
              const SizedBox(height: 8),
              Text(isAr ? 'يرجى التحقق من اتصال الإنترنت' : 'Please check your internet connection', style: AppTypography.bodySecondary()),
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
