import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../chat/chat_screen.dart';
import 'board_extra_screens.dart';
import 'make_offer_sheet.dart';
import 'post_ad_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRadiusPickerSheet(BuildContext context, BoardProvider board, bool isAr) {
    final options = [25, 50, 100, 500];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  isAr ? 'نطاق عرض الإعلانات' : 'Board Display Radius',
                  style: AppTypography.title(),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'اختر المسافة لعرض رحلات وطلبات المسافرين القريبين من خط سيرك'
                      : 'Choose the distance to view rides and requests near your route',
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 16),
                ...options.map((km) {
                  final isSelected = board.radiusKm == km;
                  final label = km >= 500
                      ? (isAr ? 'كل المحافظات (مصر بالكامل)' : 'All Governorates (All Egypt)')
                      : (isAr ? 'في نطاق $km كم من موقعك' : 'Within $km km from your location');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.teal : const Color(0xFFE5E5EA),
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        leading: Icon(
                          Icons.radar_rounded,
                          color: isSelected ? AppColors.teal : AppColors.navy,
                        ),
                        title: Text(
                          label,
                          style: AppTypography.body().copyWith(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
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

  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardProvider>();
    final ads = board.filteredAds;
    final isAr = context.isArabic;
    final activeMyAdsCount = board.myAds
        .where((a) => a.status != BoardAdStatus.completed && a.status != BoardAdStatus.expired)
        .length;
    final sentOffersCount = board.mySentOffers.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? 'اللوحة' : 'Board', style: AppTypography.title()),
            Text(
              isAr ? 'رحلات وطلبات الناس على طريقك' : 'Rides & requests along your route',
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppColors.navy,
            ),
            tooltip: isAr ? 'بحث بالمدينة أو المسار' : 'Search by city or route',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_outlined, size: 16, color: AppColors.teal),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'إعلاناتي' : 'My Ads',
                        style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (activeMyAdsCount + sentOffersCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${activeMyAdsCount + sentOffersCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          );
        },
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isAr ? 'انشر إعلان' : 'Post Ad',
          style: AppTypography.button(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final horizontalPad = isWide ? AppDimens.space32 : AppDimens.space20;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 720),
                child: Column(
                  children: [
                    // Search input bar when toggled
                    if (_isSearchOpen)
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPad, 6, horizontalPad, 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: board.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: isAr ? 'ابحث بالمحافظة أو المدينة (مثال: القاهرة، طنطا)...' : 'Search by city or route...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.navy),
                            suffixIcon: board.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      board.setSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF3F3F4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                            ),
                          ),
                        ),
                      ),

                    // Responsive Toolbar: Filter Pills + Radius & Sent Offers
                    if (isWide)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  MashwarChip(
                                    label: isAr ? 'الكل' : 'All',
                                    isSelected: board.selectedType == BoardAdType.all,
                                    onTap: () => board.setSelectedType(BoardAdType.all),
                                  ),
                                  MashwarChip(
                                    label: isAr ? 'سفر بين المحافظات' : 'Inter-city Rides',
                                    isSelected: board.selectedType == BoardAdType.rideOffer,
                                    onTap: () => board.setSelectedType(BoardAdType.rideOffer),
                                  ),
                                  MashwarChip(
                                    label: isAr ? 'انتقال ومشاوير محلية' : 'Local Mobility',
                                    isSelected: board.selectedType == BoardAdType.localTrip,
                                    onTap: () => board.setSelectedType(BoardAdType.localTrip),
                                  ),
                                  MashwarChip(
                                    label: isAr ? 'قضاء مصالح وخدمات' : 'Errands & Services',
                                    isSelected: board.selectedType == BoardAdType.errandService,
                                    onTap: () => board.setSelectedType(BoardAdType.errandService),
                                  ),
                                  MashwarChip(
                                    label: isAr ? 'لوجستيات وتوريدات' : 'Logistics & Supplies',
                                    isSelected: board.selectedType == BoardAdType.goodsDelivery,
                                    onTap: () => board.setSelectedType(BoardAdType.goodsDelivery),
                                  ),
                                  MashwarChip(
                                    label: isAr ? 'شحن وتوصيل أمانات' : 'Parcels & Cargo',
                                    isSelected: board.selectedType == BoardAdType.parcelRequest,
                                    onTap: () => board.setSelectedType(BoardAdType.parcelRequest),
                                  ),
                                  MashwarChip(
                                    label: isAr ? 'طلب سفر ونقل' : 'Travel Requests',
                                    isSelected: board.selectedType == BoardAdType.rideRequest,
                                    onTap: () => board.setSelectedType(BoardAdType.rideRequest),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildRadiusButton(context, board, isAr),
                                if (sentOffersCount > 0) ...[
                                  const SizedBox(width: 12),
                                  _buildSentOffersLink(context, sentOffersCount, isAr),
                                ],
                              ],
                            ),
                          ],
                        ),
                      )
                    else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 10),
                        child: Row(
                          children: [
                            MashwarChip(
                              label: isAr ? 'الكل' : 'All',
                              isSelected: board.selectedType == BoardAdType.all,
                              onTap: () => board.setSelectedType(BoardAdType.all),
                            ),
                            const SizedBox(width: 8),
                            MashwarChip(
                              label: isAr ? 'سفر بين المحافظات' : 'Inter-city Rides',
                              isSelected: board.selectedType == BoardAdType.rideOffer,
                              onTap: () => board.setSelectedType(BoardAdType.rideOffer),
                            ),
                            const SizedBox(width: 8),
                            MashwarChip(
                              label: isAr ? 'انتقال ومشاوير محلية' : 'Local Mobility',
                              isSelected: board.selectedType == BoardAdType.localTrip,
                              onTap: () => board.setSelectedType(BoardAdType.localTrip),
                            ),
                            const SizedBox(width: 8),
                            MashwarChip(
                              label: isAr ? 'قضاء مصالح وخدمات' : 'Errands & Services',
                              isSelected: board.selectedType == BoardAdType.errandService,
                              onTap: () => board.setSelectedType(BoardAdType.errandService),
                            ),
                            const SizedBox(width: 8),
                            MashwarChip(
                              label: isAr ? 'لوجستيات وتوريدات' : 'Logistics & Supplies',
                              isSelected: board.selectedType == BoardAdType.goodsDelivery,
                              onTap: () => board.setSelectedType(BoardAdType.goodsDelivery),
                            ),
                            const SizedBox(width: 8),
                            MashwarChip(
                              label: isAr ? 'شحن وتوصيل أمانات' : 'Parcels & Cargo',
                              isSelected: board.selectedType == BoardAdType.parcelRequest,
                              onTap: () => board.setSelectedType(BoardAdType.parcelRequest),
                            ),
                            const SizedBox(width: 8),
                            MashwarChip(
                              label: isAr ? 'طلب سفر ونقل' : 'Travel Requests',
                              isSelected: board.selectedType == BoardAdType.rideRequest,
                              onTap: () => board.setSelectedType(BoardAdType.rideRequest),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: _buildRadiusButton(context, board, isAr)),
                            if (sentOffersCount > 0) _buildSentOffersLink(context, sentOffersCount, isAr),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Ads Feed (2-column pairs on wide viewports, single list on mobile)
                    Expanded(
                      child: ads.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppDimens.space24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.dashboard_customize_outlined, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAr ? 'مفيش إعلانات مطابقة حالياً في هذا القسم' : 'No matching ads currently in this category',
                                      style: AppTypography.bodySecondary(),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        board.setSelectedType(BoardAdType.all);
                                        _searchController.clear();
                                        board.setSearchQuery('');
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: Text(isAr ? 'عرض كل الإعلانات' : 'Show All Ads'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : isWide
                              ? ListView.builder(
                                  padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 96),
                                  itemCount: (ads.length / 2).ceil(),
                                  itemBuilder: (context, rowIndex) {
                                    final firstIdx = rowIndex * 2;
                                    final secondIdx = firstIdx + 1;
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildAdCard(context, ads[firstIdx], isAr)),
                                        const SizedBox(width: AppDimens.space16),
                                        Expanded(
                                          child: secondIdx < ads.length
                                              ? _buildAdCard(context, ads[secondIdx], isAr)
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 96),
                                  itemCount: ads.length,
                                  itemBuilder: (context, index) {
                                    return _buildAdCard(context, ads[index], isAr);
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

  Widget _buildRadiusButton(BuildContext context, BoardProvider board, bool isAr) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showRadiusPickerSheet(context, board, isAr),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, size: 16, color: AppColors.teal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                board.radiusKm >= 500
                    ? (isAr ? 'معروض في كل المحافظات' : 'Displayed across all governorates')
                    : (isAr
                        ? 'معروض في نطاق ${board.radiusKm} كم من موقعك'
                        : 'Displayed within ${board.radiusKm} km from your location'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildSentOffersLink(BuildContext context, int sentOffersCount, bool isAr) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyBoardAdsScreen(initialTab: 1)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          isAr ? 'عروضي المرسلة ($sentOffersCount)' : 'Sent Offers ($sentOffersCount)',
          style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, BoardAdModel ad, bool isAr) {
    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (ad.type) {
      case BoardAdType.parcelRequest:
        typeColor = AppColors.teal;
        typeLabel = isAr ? 'شحن طرد' : 'Parcel Request';
        typeIcon = Icons.inventory_2_outlined;
        break;
      case BoardAdType.rideRequest:
        typeColor = AppColors.warning;
        typeLabel = isAr ? 'طلب سفر تشاركي' : 'Ride Request';
        typeIcon = Icons.person_search_outlined;
        break;
      case BoardAdType.rideOffer:
        typeColor = AppColors.navy;
        typeLabel = isAr ? 'عرض سفر (كراسي)' : 'Ride Offer';
        typeIcon = Icons.directions_car_outlined;
        break;
      case BoardAdType.localTrip:
        typeColor = const Color(0xFFE65100);
        typeLabel = isAr ? 'مشوار محلي وتوصيلة' : 'Local Ride';
        typeIcon = Icons.two_wheeler_outlined;
        break;
      case BoardAdType.errandService:
        typeColor = const Color(0xFF6A1B9A);
        typeLabel = isAr ? 'قضاء مصلحة وأوراق' : 'Inter-city Errand';
        typeIcon = Icons.description_outlined;
        break;
      case BoardAdType.goodsDelivery:
        typeColor = const Color(0xFF00695C);
        typeLabel = isAr ? 'نقل بضاعة لمحل' : 'Goods Delivery';
        typeIcon = Icons.local_shipping_outlined;
        break;
      case BoardAdType.all:
        typeColor = AppColors.navy;
        typeLabel = isAr ? 'مشوار أو خدمة' : 'Service';
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
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MakeOfferSheet(ad: ad),
        );
      }
    }

    String buttonText;
    if (isMyOwnAd) {
      buttonText = isAr ? 'عرض العروض' : 'View Offers';
    } else if (isOfferSent) {
      buttonText = isAr ? 'عرضك (${ad.myOfferPrice ?? ad.priceOrBudget} ج)' : 'Your Offer (${ad.myOfferPrice ?? ad.priceOrBudget})';
    } else if (ad.type == BoardAdType.rideOffer) {
      buttonText = isAr ? 'احجز كرسي / تفاوض' : 'Book Seat / Offer';
    } else if (ad.type == BoardAdType.localTrip) {
      buttonText = isAr ? 'أقدر أوصلك' : 'I can take it';
    } else if (ad.type == BoardAdType.errandService) {
      buttonText = isAr ? 'أقضي المصلحة' : 'I can do errand';
    } else if (ad.type == BoardAdType.goodsDelivery) {
      buttonText = isAr ? 'أنقل البضاعة' : 'I can transport';
    } else if (ad.type == BoardAdType.parcelRequest) {
      buttonText = isAr ? 'أقدر أوصّلها' : 'I can deliver it';
    } else {
      buttonText = isAr ? 'قدّم عرض' : 'Make Offer';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: isOfferSent ? AppColors.teal : const Color(0xFFE5E5EA),
          width: isOfferSent ? 1.2 : 0.8,
        ),
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
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          onTap: handleOpenAd,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Author, rating, relative time, and type badge
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 130),
                                  child: Text(
                                    ad.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (ad.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.teal),
                                ],
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                                Text('${ad.authorRating}', style: AppTypography.label()),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    ' · ${context.trDate(ad.timeAgo)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMyOwnAd) ...[
                          MashwarBadge(
                            type: BadgeType.verified,
                            customLabel: isAr ? 'إعلانك' : 'Your Ad',
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            typeLabel,
                            style: AppTypography.label(color: typeColor).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Route + Ladies Only badge if applicable
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.trRoute(ad.route),
                        style: AppTypography.title().copyWith(fontSize: 16),
                      ),
                    ),
                    if (ad.isLadiesOnly)
                      const MashwarBadge(type: BadgeType.ladiesOnly),
                  ],
                ),
                const SizedBox(height: 4),

                // Schedule / timeText row
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.teal),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        ad.timeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description / details
                Text(ad.description, style: AppTypography.bodySecondary()),

                const SizedBox(height: 14),

                // Footer: Suggested price + Chat & Action Button (Page 21)
                LayoutBuilder(
                  builder: (context, footerConstraints) {
                    final priceWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ad.type == BoardAdType.rideOffer
                              ? (isAr ? 'سعر الكرسي' : 'Seat Price')
                              : (isAr ? 'السعر المقترح' : 'Suggested Price'),
                          style: AppTypography.label(color: AppColors.textSecondary),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${ad.suggestedPrice}',
                              style: AppTypography.title().copyWith(color: AppColors.navy),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isAr ? 'ج' : 'EGP',
                              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    );

                    final actionsRow = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isMyOwnAd)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: isAr ? 'محادثة صاحب الإعلان' : 'Chat with author',
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.navy),
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
                              backgroundColor: isOfferSent ? AppColors.teal : AppColors.navy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              elevation: 0,
                            ),
                            onPressed: handleOpenAd,
                            child: Text(
                              buttonText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.button(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );

                    if (footerConstraints.maxWidth < 305) {
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
      ),
    );
  }
}
