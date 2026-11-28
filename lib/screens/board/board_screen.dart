import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../chat/chat_screen.dart';
import '../escrow/service_escrow_screen.dart';
import 'board_extra_screens.dart';
import 'make_offer_sheet.dart';
import 'post_ad_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({
    super.key,
    this.initialType,
    this.initialIntentFilter = 0,
  });

  final BoardAdType? initialType;
  final int initialIntentFilter;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isSearchOpen = false;
  int _intentFilter = 0; // 0 = All, 1 = Requests, 2 = Offers
  bool _escrowOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _intentFilter = widget.initialIntentFilter;
    if (widget.initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BoardProvider>().setSelectedType(widget.initialType!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRadiusPickerSheet(
    BuildContext context,
    BoardProvider board,
    bool isAr,
  ) {
    const options = [25, 50, 100, 500];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
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
                  isAr ? 'نطاق عرض الإعلانات' : 'Display Radius',
                  style: AppTypography.title(color: AppColors.navy).copyWith(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'اختر المسافة لعرض رحلات وطلبات المسافرين القريبين من مسارك'
                      : 'Choose the radius to view trips and requests near your route',
                  style: AppTypography.bodySecondary(
                    color: AppColors.textSecondary,
                  ).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((km) {
                  final isSelected = board.radiusKm == km;
                  final label = km >= 500
                      ? (isAr ? 'كل المسارات والمدن' : 'All Cities & Corridors')
                      : (isAr
                          ? 'في نطاق $km كم من موقعك'
                          : 'Within $km km from your location');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.slateBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        leading: Icon(
                          Icons.radar_rounded,
                          color: isSelected
                              ? AppColors.navy
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          label,
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(
                            fontSize: 14.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.teal,
                              )
                            : null,
                        onTap: () {
                          board.setRadiusKm(km);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_CategoryFilterOption> _categoryOptions(bool isAr) => [
        _CategoryFilterOption(
          type: BoardAdType.all,
          label: isAr ? 'الكل' : 'All',
          icon: Icons.apps_rounded,
          accentColor: AppColors.navy,
        ),
        _CategoryFilterOption(
          type: BoardAdType.rideOffer,
          label: isAr ? 'سفر ومقاعد شاغرة' : 'Shared Seats',
          icon: Icons.directions_car_outlined,
          accentColor: AppColors.navy,
        ),
        _CategoryFilterOption(
          type: BoardAdType.rideRequest,
          label: isAr ? 'طلبات سفر' : 'Ride Requests',
          icon: Icons.person_search_rounded,
          accentColor: AppColors.navy,
        ),
        _CategoryFilterOption(
          type: BoardAdType.parcelRequest,
          label: isAr ? 'طرود على الطريق' : 'Route Parcels',
          icon: Icons.inventory_2_outlined,
          accentColor: AppColors.teal,
        ),
        _CategoryFilterOption(
          type: BoardAdType.goodsDelivery,
          label: isAr ? 'توريد ومستلزمات' : 'Smart Supply',
          icon: Icons.local_shipping_outlined,
          accentColor: AppColors.teal,
        ),
        _CategoryFilterOption(
          type: BoardAdType.errandService,
          label: isAr ? 'مهام ومستندات' : 'Docs & Errands',
          icon: Icons.description_outlined,
          accentColor: AppColors.navy,
        ),
        _CategoryFilterOption(
          type: BoardAdType.localTrip,
          label: isAr ? 'مشاوير يومية' : 'Daily Rides',
          icon: Icons.family_restroom_rounded,
          accentColor: AppColors.teal,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardProvider>();
    final isAr = context.isArabic;
    final baseAds = board.filteredAds;
    final intentFiltered = _intentFilter == 0
        ? baseAds
        : _intentFilter == 1
            ? baseAds.where((ad) => !ad.isOfferCard).toList()
            : baseAds.where((ad) => ad.isOfferCard).toList();
    final ads = _escrowOnly
        ? intentFiltered.where((ad) => ad.hasEscrowProtection).toList()
        : intentFiltered;

    final activeMyAdsCount = board.myAds
        .where(
          (a) =>
              a.status != BoardAdStatus.completed &&
              a.status != BoardAdStatus.expired,
        )
        .length;
    final sentOffersCount = board.mySentOffers.length;
    final categories = _categoryOptions(isAr);

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const MashwarServicePillarIcon(
              pillar: MashwarServicePillar.routeParcels,
              size: 32,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isAr ? 'لوحة المسارات والطلبات' : 'Route & Service Board',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title(color: AppColors.navy)
                              .copyWith(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr ? 'مباشر' : 'LIVE',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealDark,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isAr
                        ? 'مقاعد تشاركية وطرود على الطريق وتوريد'
                        : 'Shared trips, route parcels & supply',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySecondary(
                      color: AppColors.textSecondary,
                    ).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppColors.navy,
            ),
            tooltip:
                isAr ? 'بحث بالمدينة أو المسار' : 'Search by city or route',
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  board.setSearchQuery('');
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.campaign_outlined,
                        size: 16,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'إعلاناتي' : 'My Ads',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (activeMyAdsCount + sentOffersCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${activeMyAdsCount + sentOffersCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Preserves single Icons.add_rounded + exact 'انشر إعلان' label for widget tests
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          );
        },
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isAr ? 'انشر إعلان' : 'Post Ad',
          style: AppTypography.button(color: Colors.white).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final horizontalPad =
                isWide ? AppDimens.space32 : AppDimens.space16;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 720),
                child: Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _isSearchOpen
                          ? Container(
                              color: Colors.white,
                              padding: EdgeInsets.fromLTRB(
                                horizontalPad,
                                6,
                                horizontalPad,
                                8,
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: board.setSearchQuery,
                                decoration: InputDecoration(
                                  hintText: isAr
                                      ? 'ابحث بالمدينة أو المسار...'
                                      : 'Search by city or route...',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: AppColors.navy,
                                  ),
                                  suffixIcon: board.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            board.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: AppColors.slateBg,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.slateBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.slateBorder,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isWide)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPad,
                                10,
                                horizontalPad,
                                8,
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categories
                                    .map(
                                      (opt) =>
                                          _buildVisualCategoryPill(board, opt),
                                    )
                                    .toList(),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.fromLTRB(
                                horizontalPad,
                                8,
                                horizontalPad,
                                8,
                              ),
                              child: Row(
                                children: [
                                  for (int i = 0; i < categories.length; i++) ...[
                                    _buildVisualCategoryPill(
                                      board,
                                      categories[i],
                                    ),
                                    if (i < categories.length - 1)
                                      const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),

                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPad,
                              2,
                              horizontalPad,
                              10,
                            ),
                            child: isWide
                                ? Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _buildIntentSegmentedControl(
                                        isAr,
                                        fillWidth: false,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildEscrowOnlyFilterChip(isAr),
                                          const SizedBox(width: 8),
                                          _buildRadiusButton(
                                            context,
                                            board,
                                            isAr,
                                          ),
                                          if (sentOffersCount > 0) ...[
                                            const SizedBox(width: 12),
                                            _buildSentOffersLink(
                                              context,
                                              sentOffersCount,
                                              isAr,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildIntentSegmentedControl(isAr),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _buildEscrowOnlyFilterChip(isAr),
                                          _buildRadiusButton(
                                            context,
                                            board,
                                            isAr,
                                          ),
                                          if (sentOffersCount > 0)
                                            _buildSentOffersLink(
                                              context,
                                              sentOffersCount,
                                              isAr,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                          const Divider(height: 1, color: AppColors.slateBorder),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: ads.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.all(AppDimens.space24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const MashwarServicePillarIcon(
                                      pillar: MashwarServicePillar.routeParcels,
                                      size: 58,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isAr
                                          ? 'لا توجد إعلانات مطابقة حالياً في هذا القسم'
                                          : 'No matching ads currently in this category',
                                      style: AppTypography.bodySecondary(),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.navy,
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: AppColors.slateBorder,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() => _intentFilter = 0);
                                        board.setSelectedType(BoardAdType.all);
                                        board.clearRouteFilter();
                                        _searchController.clear();
                                        board.setSearchQuery('');
                                      },
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isAr
                                            ? 'عرض كل الإعلانات'
                                            : 'Show All Ads',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : isWide
                              ? ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPad,
                                    4,
                                    horizontalPad,
                                    96,
                                  ),
                                  itemCount: (ads.length / 2).ceil(),
                                  itemBuilder: (context, rowIndex) {
                                    final firstIdx = rowIndex * 2;
                                    final secondIdx = firstIdx + 1;
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildAdCard(
                                            context,
                                            ads[firstIdx],
                                            isAr,
                                            firstIdx,
                                          ),
                                        ),
                                        const SizedBox(width: AppDimens.space16),
                                        Expanded(
                                          child: secondIdx < ads.length
                                              ? _buildAdCard(
                                                  context,
                                                  ads[secondIdx],
                                                  isAr,
                                                  secondIdx,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPad,
                                    4,
                                    horizontalPad,
                                    96,
                                  ),
                                  itemCount: ads.length,
                                  itemBuilder: (context, index) {
                                    return _buildAdCard(
                                      context,
                                      ads[index],
                                      isAr,
                                      index,
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

  Widget _buildVisualCategoryPill(
    BoardProvider board,
    _CategoryFilterOption opt,
  ) {
    final isSelected = board.selectedType == opt.type;
    return MashwarPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (_intentFilter != 0) {
          setState(() => _intentFilter = 0);
        }
        board.setSelectedType(opt.type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.slateBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              opt.icon,
              size: 15,
              color: isSelected ? Colors.white : opt.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.navy,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentSegmentedControl(bool isAr, {bool fillWidth = true}) {
    final segments = [
      (0, isAr ? 'الكل' : 'All'),
      (1, isAr ? 'الطلبات' : 'Requests'),
      (2, isAr ? 'عروض المسافرين' : 'Traveler Offers'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
        children: segments.map((seg) {
          final isSelected = _intentFilter == seg.$1;
          final tile = InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => setState(() => _intentFilter = seg.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: EdgeInsets.symmetric(
                horizontal: fillWidth ? 8 : 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                seg.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.navy : AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          );
          return fillWidth
              ? Expanded(child: tile)
              : Flexible(fit: FlexFit.loose, child: tile);
        }).toList(),
      ),
    );
  }

  Widget _buildEscrowOnlyFilterChip(bool isAr) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _escrowOnly = !_escrowOnly),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _escrowOnly ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _escrowOnly ? AppColors.teal : AppColors.slateBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 13,
              color: _escrowOnly ? Colors.white : AppColors.teal,
            ),
            const SizedBox(width: 4),
            Text(
              isAr ? 'مضمون بـ OTP' : 'OTP Verified',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _escrowOnly ? Colors.white : AppColors.navy,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusButton(
    BuildContext context,
    BoardProvider board,
    bool isAr,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showRadiusPickerSheet(context, board, isAr),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.radar_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                board.radiusKm >= 500
                    ? (isAr ? 'كل المسارات' : 'All corridors')
                    : (isAr
                        ? 'نطاق ${board.radiusKm} كم'
                        : 'Within ${board.radiusKm} km'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.textSecondary)
                    .copyWith(
                  fontSize: 12,
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
    );
  }

  Widget _buildSentOffersLink(
    BuildContext context,
    int sentOffersCount,
    bool isAr,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MyBoardAdsScreen(initialTab: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          isAr
              ? 'عروضي المرسلة ($sentOffersCount)'
              : 'Sent Offers ($sentOffersCount)',
          style: AppTypography.label(color: AppColors.navy).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAdCard(
    BuildContext context,
    BoardAdModel ad,
    bool isAr,
    int index,
  ) {
    IconData typeIcon;

    switch (ad.type) {
      case BoardAdType.parcelRequest:
        typeIcon = Icons.inventory_2_outlined;
        break;
      case BoardAdType.rideRequest:
        typeIcon = Icons.person_search_outlined;
        break;
      case BoardAdType.rideOffer:
        typeIcon = Icons.directions_car_outlined;
        break;
      case BoardAdType.localTrip:
        typeIcon = Icons.family_restroom_rounded;
        break;
      case BoardAdType.errandService:
        typeIcon = Icons.description_outlined;
        break;
      case BoardAdType.goodsDelivery:
        typeIcon = Icons.local_shipping_outlined;
        break;
      case BoardAdType.all:
        typeIcon = Icons.campaign_outlined;
        break;
    }

    final isMyOwnAd = ad.id.startsWith('my_ad_');
    final isOfferSent = ad.status == BoardAdStatus.offerSent;

    void handleOpenAd() {
      if (isMyOwnAd) {
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

    final buttonText = isMyOwnAd
        ? (isAr ? 'عرض العروض' : 'View Offers')
        : isOfferSent
            ? (isAr
                ? 'عرضك (${ad.myOfferPrice ?? ad.priceOrBudget} ر.ق)'
                : 'Your Offer (${ad.myOfferPrice ?? ad.priceOrBudget} QAR)')
            : ad.isOfferCard
                ? (isAr ? 'احجز الآن' : 'Book Now')
                : (isAr ? 'قدّم عرضاً' : 'Send Offer');

    return MashwarFadeSlideIn(
      duration: Duration(milliseconds: 220 + (index.clamp(0, 4) * 30)),
      offsetY: 10,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space16),
        child: MashwarHoverCard(
          backgroundColor: Colors.white,
          borderColor: isOfferSent ? AppColors.teal : AppColors.slateBorder,
          hoverBorderColor: AppColors.navy,
          padding: const EdgeInsets.all(AppDimens.space16),
          onTap: handleOpenAd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child:
                            Icon(typeIcon, color: AppColors.navy, size: 19),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  ad.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(
                                    color: AppColors.navy,
                                  ).copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (ad.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppColors.teal,
                                ),
                              ],
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.gold,
                              ),
                              Text(
                                '${ad.authorRating}',
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 110),
                                child: Text(
                                  ' · ${context.trDate(ad.timeAgo)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label(
                                    color: AppColors.textSecondary,
                                  ).copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isMyOwnAd)
                        MashwarBadge(
                          type: BadgeType.verified,
                          customLabel: isAr ? 'إعلانك' : 'Your Ad',
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Text(
                          ad.displaySubTag(isAr),
                          style: AppTypography.label(color: AppColors.navy)
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
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(14),
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
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            ad.timeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(
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
              const SizedBox(height: 10),

              Text(
                ad.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySecondary(
                  color: AppColors.textSecondary,
                ).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, footerConstraints) {
                  final priceWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.priceTagLabel(isAr),
                        style: AppTypography.label(
                          color: AppColors.textSecondary,
                        ).copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${ad.suggestedPrice}',
                            style: AppTypography.title(color: AppColors.navy)
                                .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isAr ? 'ر.ق' : 'QAR',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  final actionsRow = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isAr ? 'التسوية المباشرة و OTP' : 'Direct Settlement & OTP',
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.slateBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 17,
                            color: AppColors.teal,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ServiceEscrowScreen(ad: ad),
                            ),
                          );
                        },
                      ),
                      if (!isMyOwnAd)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: isAr ? 'محادثة مباشرة' : 'Chat',
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.slateBorder),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 17,
                              color: AppColors.navy,
                            ),
                          ),
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
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isOfferSent ? AppColors.teal : AppColors.navy,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                          onPressed: handleOpenAd,
                          child: Text(
                            buttonText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.button(color: Colors.white)
                                .copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  if (footerConstraints.maxWidth < 340) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        priceWidget,
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: actionsRow,
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      priceWidget,
                      const SizedBox(width: 8),
                      Flexible(child: actionsRow),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterOption {
  const _CategoryFilterOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final BoardAdType type;
  final String label;
  final IconData icon;
  final Color accentColor;
}
