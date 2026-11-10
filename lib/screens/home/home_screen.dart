import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/alerts_provider.dart';
import '../search/search_results_screen.dart';
import '../booking/booking_confirmation_screen.dart';
import '../alerts/my_alerts_screen.dart';
import '../driver/driver_onboarding_screens.dart';
import 'city_search_modal.dart';
import 'date_time_picker_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rides = context.watch<RidesProvider>();
    final alerts = context.watch<AlertsProvider>();
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top User Greeting & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'أهلاً' : 'Hello',
                        style: AppTypography.bodySecondary(),
                      ),
                      // Real user full name from database - preserved as requested
                      Text(
                        auth.user.fullName.split(' ').first,
                        style: AppTypography.title(),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.user.fullName.isNotEmpty ? auth.user.fullName[0] : 'ع',
                        style: AppTypography.title(color: AppColors.navy),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),

              // Mode Switcher: كراسي vs طرود (Uber/inDrive segmented style)
              Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModePill(
                        context,
                        title: isAr ? 'كراسي' : 'Seats',
                        isSelected: rides.rideMode == RideMode.seats,
                        onTap: () => rides.setRideMode(RideMode.seats),
                      ),
                      _buildModePill(
                        context,
                        title: isAr ? 'طرود' : 'Parcels',
                        isSelected: rides.rideMode == RideMode.parcels,
                        onTap: () => rides.setRideMode(RideMode.parcels),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // Active Alert Match Banner (Page 15)
              if (auth.user.hasActiveAlerts) ...[
                AlertBanner(
                  message: isAr
                      ? 'لقينا رحلة مطابقة لتنبيهك: كفر الشيخ ← القاهرة\n7:30 ص'
                      : 'Found a matching ride for your alert: Kafr El-Sheikh → Cairo\n7:30 AM',
                  type: AlertBannerType.info,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                    );
                  },
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              // Upcoming Booking Card (Page 15)
              if (rides.activeBooking != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    border: Border.all(color: AppColors.borderDisabled),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'رحلتك القادمة' : 'Your Upcoming Ride', style: AppTypography.label()),
                          const MashwarBadge(type: BadgeType.confirmed),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.trRoute('${rides.activeBooking!.fromCity} ← ${rides.activeBooking!.toCity}'),
                        style: AppTypography.title(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.trDate(rides.activeBooking!.departureDate)}، ${rides.activeBooking!.departureTime} · ${rides.activeBooking!.driverName}',
                        style: AppTypography.bodySecondary(),
                      ),
                      const SizedBox(height: 12),
                      MashwarButton(
                        text: isAr ? 'عرض الحجز' : 'View Booking',
                        variant: MashwarButtonVariant.secondary,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingConfirmationScreen(ride: rides.activeBooking!),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              // Main Search Card (Page 9)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From
                    _buildRouteField(
                      label: isAr ? 'من' : 'From',
                      value: context.trCity(rides.fromCity),
                      onTap: () async {
                        final selected = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => CitySearchModal(
                              title: isAr ? 'نقطة الانطلاق' : 'Departure Point',
                              initialValue: rides.fromCity,
                            ),
                          ),
                        );
                        if (selected != null) {
                          rides.setRoute(from: selected);
                        }
                      },
                    ),
                    const SizedBox(height: AppDimens.space12),

                    // To
                    _buildRouteField(
                      label: isAr ? 'إلى' : 'To',
                      value: context.trCity(rides.toCity),
                      onTap: () async {
                        final selected = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => CitySearchModal(
                              title: isAr ? 'الوجهة' : 'Destination',
                              initialValue: rides.toCity,
                            ),
                          ),
                        );
                        if (selected != null) {
                          rides.setRoute(to: selected);
                        }
                      },
                    ),
                    const SizedBox(height: AppDimens.space12),

                    // Date & Seats Row
                    Row(
                      children: [
                        // Date Picker (flex 3)
                        Expanded(
                          flex: 3,
                          child: _buildRouteField(
                            label: isAr ? 'التاريخ' : 'Date',
                            value: context.trDate(rides.date),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DateTimePickerSheet(
                                  selectedDay: rides.date,
                                  selectedTime: rides.timeSlot,
                                  onApply: (day, time) {
                                    rides.setDate(day);
                                    rides.setTimeSlot(time);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        // Seats Counter (flex 1)
                        Expanded(
                          flex: 1,
                          child: _buildRouteField(
                            label: rides.rideMode == RideMode.seats ? (isAr ? 'الكراسي' : 'Seats') : (isAr ? 'الطرود' : 'Parcels'),
                            value: '${rides.seatsCount}',
                            onTap: () {
                              _showSeatsPicker(context, rides);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Search Button
                    MashwarButton(
                      text: rides.rideMode == RideMode.seats ? (isAr ? 'ابحث عن رحلة' : 'Search for a ride') : (isAr ? 'ابحث عن مسافر لطردك' : 'Find traveler for parcel'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space24),

              // Popular Routes (محاور شائعة)
              Text(isAr ? 'محاور شائعة' : 'Popular Routes', style: AppTypography.title().copyWith(fontSize: 18)),
              const SizedBox(height: AppDimens.space12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPopularChip(context, rides, isAr ? 'القاهرة ← الإسكندرية' : 'Cairo → Alexandria', 'القاهرة', 'الإسكندرية'),
                  _buildPopularChip(context, rides, isAr ? 'القاهرة ← طنطا' : 'Cairo → Tanta', 'القاهرة', 'طنطا'),
                  _buildPopularChip(context, rides, isAr ? 'الإسكندرية ← المنصورة' : 'Alexandria → Mansoura', 'الإسكندرية', 'المنصورة'),
                ],
              ),
              const SizedBox(height: AppDimens.space24),

              // Driver Promotion Banner (Page 15)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'عندك عربية؟' : 'Have a car?', style: AppTypography.title().copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? 'انشر رحلتك واكسب من الكراسي الفاضية' : 'Publish your ride and earn from empty seats',
                            style: AppTypography.bodySecondary(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MashwarButton(
                      width: 80,
                      height: 40,
                      text: isAr ? 'ابدأ' : 'Start',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DriverOnboardingScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space24),

              // Active Route Alerts Preview (Page 15 & 20)
              if (alerts.alerts.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'تنبيهاتي' : 'My Alerts', style: AppTypography.title().copyWith(fontSize: 18)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
                        );
                      },
                      child: Text(isAr ? 'عرض الكل' : 'View All', style: AppTypography.bodySecondary(color: AppColors.navy)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...alerts.alerts.take(2).map((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.borderDisabled),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.trRoute('${alert.fromCity} ← ${alert.toCity}'),
                              style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${context.trDate(alert.dateRange)} · ${context.tr(alert.category)}',
                              style: AppTypography.label(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Switch(
                          value: alert.isActive,
                          activeThumbColor: AppColors.teal,
                          onChanged: (_) => alerts.toggleAlert(alert.id),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: AppDimens.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        ),
        child: Text(
          title,
          style: AppTypography.bodySecondary(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildRouteField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontFamily: 'Cairo')),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy, fontFamily: 'Cairo')),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularChip(
    BuildContext context,
    RidesProvider rides,
    String label,
    String from,
    String to,
  ) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFFF3F3F4),
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy, fontFamily: 'Cairo'),
      onPressed: () {
        rides.setRoute(from: from, to: to);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
        );
      },
    );
  }

  void _showSeatsPicker(BuildContext context, RidesProvider rides) {
    final isAr = context.isArabic;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rides.rideMode == RideMode.seats ? (isAr ? 'عدد المقاعد' : 'Number of Seats') : (isAr ? 'عدد الطرود' : 'Number of Parcels'),
                  style: AppTypography.title(),
                ),
                const SizedBox(height: AppDimens.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [1, 2, 3, 4].map((count) {
                    final isSelected = rides.seatsCount == count;
                    return GestureDetector(
                      onTap: () {
                        rides.setSeatsCount(count);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.navy : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.navy : AppColors.borderDisabled,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: AppTypography.title(
                              color: isSelected ? Colors.white : AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimens.space16),
              ],
            ),
          ),
        );
      },
    );
  }
}
