import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../../state/alerts_provider.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
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
              style: AppTypography.title().copyWith(fontSize: 18),
            ),
            Text(
              '${context.trDate(rides.date)} · ${rides.rideMode == RideMode.seats ? (isAr ? "كرسي واحد" : "1 Seat") : (isAr ? "طرد واحد" : "1 Parcel")}',
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
        child: Column(
          children: [
            // Quick Filter Chips Bar (Page 10)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
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

            // Offline Banner State (Page 18)
            if (_isOffline) ...[
              Padding(
                padding: const EdgeInsets.all(AppDimens.space16),
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
                      : _buildResultsList(context, results, isAr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<RideModel> ridesList, bool isAr) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.space16),
      itemCount: ridesList.length,
      itemBuilder: (context, index) {
        final ride = ridesList[index];
        return _buildDriverCard(context, ride, isAr);
      },
    );
  }

  Widget _buildDriverCard(BuildContext context, RideModel ride, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Departure time, Route, and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          ride.departureTime,
                          style: AppTypography.title().copyWith(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.trRoute('${ride.fromCity} ← ${ride.toCity}'),
                          style: AppTypography.bodySecondary(),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${ride.pricePerSeat}',
                          style: AppTypography.largeTitle().copyWith(fontSize: 22, color: AppColors.navy),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isAr ? 'ج' : 'EGP',
                          style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space12),

                // Meeting & Dropoff Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.pickupPoint,
                        style: AppTypography.bodySecondary().copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.dropoffPoint,
                        style: AppTypography.bodySecondary().copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Driver Info, Rating & Badges
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ride.driverName.isNotEmpty ? ride.driverName[0] : 'ك',
                          style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Raw driver name from database
                              Text(
                                ride.driverName,
                                style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              if (ride.isVerified)
                                const Icon(Icons.verified_rounded, size: 16, color: AppColors.teal),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                              const SizedBox(width: 2),
                              Text('${ride.driverRating}', style: AppTypography.label()),
                              const SizedBox(width: 6),
                              Text('· ${ride.driverCar}', style: AppTypography.label(color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Badge & Parcel Tag
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (ride.remainingSeats == 0)
                          MashwarBadge(type: BadgeType.rejected, customLabel: isAr ? 'مكتمل' : 'Full')
                        else if (ride.isLadiesOnly)
                          MashwarBadge(type: BadgeType.newBadge, customLabel: isAr ? 'سيدات فقط' : 'Ladies Only')
                        else
                          MashwarBadge(
                            type: BadgeType.verified,
                            customLabel: isAr ? 'متاح (${ride.remainingSeats})' : 'Available (${ride.remainingSeats})',
                          ),
                        if (ride.acceptsParcels) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                            ),
                            child: Text(
                              isAr ? 'يقبل طرود' : 'Parcels OK',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page 18: Empty State + Route Alert Creation
  Widget _buildEmptyState(BuildContext context, RidesProvider rides, AlertsProvider alerts, bool isAr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.space32),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_outlined, size: 40, color: AppColors.borderDisabled),
          ),
          const SizedBox(height: AppDimens.space16),
          Text(
            isAr ? 'مفيش رحلات مطابقة دلوقتي' : 'No matching rides right now',
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
            text: isAr ? 'نبّهني لما تنزل رحلة' : 'Alert me when rides are added',
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
    );
  }

  Widget _buildErrorState(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(isAr ? 'حصل خطأ في تحميل النتائج' : 'Error loading search results', style: AppTypography.title()),
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
    );
  }
}
