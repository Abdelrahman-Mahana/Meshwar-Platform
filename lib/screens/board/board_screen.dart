import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../chat/chat_screen.dart';
import 'board_extra_screens.dart';
import 'make_offer_sheet.dart';
import 'post_ad_screen.dart';
import '../escrow/service_escrow_screen.dart';

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
                      ? (isAr ? 'كل المناطق (قطر بالكامل)' : 'All Areas (All Qatar)')
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

  List<_CategoryFilterOption> _categoryOptions(bool isAr) => [
        _CategoryFilterOption(
          type: BoardAdType.all,
          label: isAr ? 'كل الخدمات' : 'All Services',
          icon: Icons.apps_rounded,
          accentColor: AppColors.navy,
        ),
        _CategoryFilterOption(
          type: BoardAdType.goodsDelivery,
          label: isAr ? 'توريد مواقع وبضائع' : 'Site Supply & Cargo',
          assetPath: 'assets/images/service_site_supply.jpg',
          icon: Icons.engineering_rounded,
          accentColor: AppColors.qatarMaroon,
        ),
        _CategoryFilterOption(
          type: BoardAdType.parcelRequest,
          label: isAr ? 'شراء بفاتورة وطرود' : 'Shop & Parcels',
          assetPath: 'assets/images/service_parcel.jpg',
          icon: Icons.shopping_bag_rounded,
          accentColor: AppColors.teal,
        ),
        _CategoryFilterOption(
          type: BoardAdType.errandService,
          label: isAr ? 'جلب أوراق ومصالح' : 'Docs & Errands',
          assetPath: 'assets/images/service_errand.jpg',
          icon: Icons.description_rounded,
          accentColor: const Color(0xFF6A1B9A),
        ),
        _CategoryFilterOption(
          type: BoardAdType.localTrip,
          label: isAr ? 'حضانات ومشاوير يومية' : 'Nursery & Daily',
          icon: Icons.family_restroom_rounded,
          accentColor: const Color(0xFFD97706),
        ),
        _CategoryFilterOption(
          type: BoardAdType.rideOffer,
          label: isAr ? 'سفر ومقاعد شاغرة' : 'Shared Seats',
          assetPath: 'assets/images/service_ride.jpg',
          icon: Icons.directions_car_rounded,
          accentColor: AppColors.navy,
        ),
        _CategoryFilterOption(
          type: BoardAdType.rideRequest,
          label: isAr ? 'طلب سفر' : 'Travel Requests',
          icon: Icons.person_search_rounded,
          accentColor: AppColors.warning,
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
        .where((a) => a.status != BoardAdStatus.completed && a.status != BoardAdStatus.expired)
        .length;
    final sentOffersCount = board.mySentOffers.length;
    final categories = _categoryOptions(isAr);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MashwarPinIcon(size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isAr ? 'اللوحة' : 'Board',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title(),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'مباشر' : 'LIVE',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              isAr ? 'سوق المشاوير والخدمات اليومية' : 'Marketplace for rides & services',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
      // Keep single Icons.add_rounded + exact 'انشر إعلان' label for widget tests
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          );
        },
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: AppColors.gold),
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
                    // Animated Collapsible Search Bar
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _isSearchOpen
                          ? Container(
                              color: Colors.white,
                              padding: EdgeInsets.fromLTRB(horizontalPad, 6, horizontalPad, 8),
                              child: TextField(
                                controller: _searchController,
                                onChanged: board.setSearchQuery,
                                decoration: InputDecoration(
                                  hintText: isAr
                                      ? 'ابحث بالمنطقة أو المدينة (مثال: الدوحة، الخور، لوسيل)...'
                                      : 'Search by city or route...',
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
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Illustrated Category Strip + Segmented Intent Bar
                    Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Live Requester <-> Provider Matchmaking Strip
                          Padding(
                            padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const MashwarLivePulseDot(color: AppColors.teal, size: 7.5),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'توصيل فوري بين صاحب الخدمة والمنفّذ في كل بلديات قطر'
                                          : 'Direct matchmaking between requesters & Qatar captains',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${ads.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.teal,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isWide)
                            Padding(
                              padding: EdgeInsets.fromLTRB(horizontalPad, 10, horizontalPad, 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categories
                                    .map((opt) => _buildVisualCategoryPill(board, opt))
                                    .toList(),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 8),
                              child: Row(
                                children: [
                                  for (int i = 0; i < categories.length; i++) ...[
                                    _buildVisualCategoryPill(board, categories[i]),
                                    if (i < categories.length - 1) const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),

                          // Segmented Intent Bar + Radius & Sent Offers Strip
                          Padding(
                            padding: EdgeInsets.fromLTRB(horizontalPad, 2, horizontalPad, 10),
                            child: isWide
                                ? SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _buildIntentSegmentedControl(isAr, fillWidth: false),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildEscrowOnlyFilterChip(isAr),
                                            const SizedBox(width: 8),
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
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildIntentSegmentedControl(isAr),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _buildEscrowOnlyFilterChip(isAr),
                                          _buildRadiusButton(context, board, isAr),
                                          if (sentOffersCount > 0)
                                            _buildSentOffersLink(context, sentOffersCount, isAr),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEDF2F7)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Ads Feed (2-column pairs on wide viewports, single list on mobile)
                    Expanded(
                      child: ads.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(AppDimens.space24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: MashwarAssetArt(
                                        assetPath: 'assets/images/service_ride.jpg',
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.contain,
                                        borderRadius: BorderRadius.circular(14),
                                        fallbackIcon: Icons.dashboard_customize_outlined,
                                      ),
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
                                      onPressed: () {
                                        setState(() => _intentFilter = 0);
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
                                        Expanded(child: _buildAdCard(context, ads[firstIdx], isAr, firstIdx)),
                                        const SizedBox(width: AppDimens.space16),
                                        Expanded(
                                          child: secondIdx < ads.length
                                              ? _buildAdCard(context, ads[secondIdx], isAr, secondIdx)
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
                                    return _buildAdCard(context, ads[index], isAr, index);
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

  Widget _buildVisualCategoryPill(BoardProvider board, _CategoryFilterOption opt) {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (opt.assetPath != null)
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: MashwarAssetArt(
                  assetPath: opt.assetPath!,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(5),
                  fallbackIcon: opt.icon,
                  fallbackColor: opt.accentColor,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.16)
                      : opt.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  opt.icon,
                  size: 14,
                  color: isSelected ? AppColors.gold : opt.accentColor,
                ),
              ),
            const SizedBox(width: 7),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
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
      (1, isAr ? 'طلبات الخدمة' : 'Requests'),
      (2, isAr ? 'عروض المنفّذين' : 'Offers'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
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
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                seg.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.navy : AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          );
          return fillWidth ? Expanded(child: tile) : Flexible(fit: FlexFit.loose, child: tile);
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _escrowOnly ? AppColors.escrowGreen : AppColors.escrowSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _escrowOnly ? AppColors.escrowGreen : AppColors.escrowGreen.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 13,
              color: _escrowOnly ? Colors.white : AppColors.escrowGreen,
            ),
            const SizedBox(width: 4),
            Text(
              isAr ? 'مضمون بـ Escrow' : 'Escrow Safe',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _escrowOnly ? Colors.white : AppColors.escrowGreen,
                fontFamily: 'Cairo',
              ),
            ),
          ],
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
                    ? (isAr ? 'معروض في كل المناطق' : 'Displayed across all areas')
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

  Widget _buildAdCard(BuildContext context, BoardAdModel ad, bool isAr, int index) {
    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (ad.type) {
      case BoardAdType.parcelRequest:
        typeColor = AppColors.teal;
        typeLabel = ad.displaySubTag(isAr);
        typeIcon = Icons.shopping_bag_outlined;
        break;
      case BoardAdType.rideRequest:
        typeColor = AppColors.warning;
        typeLabel = ad.displaySubTag(isAr);
        typeIcon = Icons.person_search_outlined;
        break;
      case BoardAdType.rideOffer:
        typeColor = AppColors.navy;
        typeLabel = ad.displaySubTag(isAr);
        typeIcon = Icons.directions_car_outlined;
        break;
      case BoardAdType.localTrip:
        typeColor = const Color(0xFFD97706);
        typeLabel = ad.displaySubTag(isAr);
        typeIcon = Icons.family_restroom_rounded;
        break;
      case BoardAdType.errandService:
        typeColor = const Color(0xFF6A1B9A);
        typeLabel = ad.displaySubTag(isAr);
        typeIcon = Icons.description_outlined;
        break;
      case BoardAdType.goodsDelivery:
        typeColor = AppColors.qatarMaroon;
        typeLabel = ad.displaySubTag(isAr);
        typeIcon = Icons.engineering_rounded;
        break;
      case BoardAdType.all:
        typeColor = AppColors.navy;
        typeLabel = ad.displaySubTag(isAr);
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
      buttonText = isAr ? 'عرضك (${ad.myOfferPrice ?? ad.priceOrBudget} ر.ق)' : 'Your Offer (${ad.myOfferPrice ?? ad.priceOrBudget} QAR)';
    } else if (ad.isOfferCard) {
      buttonText = isAr ? 'احجز بالضمان' : 'Book Safe';
    } else {
      buttonText = isAr ? 'نفّذ بالضمان' : 'Fulfill Safe';
    }

    return MashwarFadeSlideIn(
      duration: Duration(milliseconds: 220 + (index.clamp(0, 4) * 30)),
      offsetY: 10,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space16),
        child: MashwarPressable(
          borderRadius: BorderRadius.circular(18),
          onTap: handleOpenAd,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isOfferSent ? AppColors.teal : const Color(0xFFE5E5EA),
                width: isOfferSent ? 1.4 : 0.9,
              ),
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
                // Header: Author, rating, relative time, Escrow & type badge
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
                            color: typeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 19),
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
                                  constraints: const BoxConstraints(maxWidth: 130),
                                  child: Text(
                                    ad.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body().copyWith(fontWeight: FontWeight.w800),
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
                        if (ad.hasEscrowProtection) MashwarEscrowBadge(isAr: isAr, compact: true),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            typeLabel,
                            style: AppTypography.label(color: typeColor).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Visual Route Box + Timing
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.6),
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
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 7),
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
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Description / details
                Text(ad.description, style: AppTypography.bodySecondary()),

                if (ad.requiresReceiptProof) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      ad.estimatedItemCost != null
                          ? (isAr
                              ? 'يشترط تصوير الفاتورة الأصلية (سقف المشتريات: ${ad.estimatedItemCost} ر.ق بالضمان)'
                              : 'Original receipt photo required (Escrow item cap: ${ad.estimatedItemCost} QAR)')
                          : (isAr ? 'يشترط تصوير الفاتورة الأصلية قبل التحرك' : 'Live receipt photo required'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A5B00),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Footer: Suggested price + Escrow/Chat & Action Button
                LayoutBuilder(
                  builder: (context, footerConstraints) {
                    final priceWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ad.priceTagLabel(isAr),
                          style: AppTypography.label(color: AppColors.textSecondary),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${ad.suggestedPrice}',
                              style: AppTypography.title().copyWith(color: AppColors.navy, fontSize: 20),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isAr ? 'ر.ق' : 'QAR',
                              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w800),
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
                          tooltip: isAr ? 'نظام الضمان وحماية الطرفين' : 'Bilateral Escrow Shield',
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.escrowSurface,
                              border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_outlined, size: 17, color: AppColors.escrowGreen),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ServiceEscrowScreen(ad: ad)),
                            );
                          },
                        ),
                        if (!isMyOwnAd)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: isAr ? 'محادثة صاحب الإعلان' : 'Chat with author',
                            icon: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.navy),
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
                              backgroundColor: isOfferSent ? AppColors.teal : AppColors.navy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

                    if (footerConstraints.maxWidth < 365) {
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

class _CategoryFilterOption {
  const _CategoryFilterOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.assetPath,
  });

  final BoardAdType type;
  final String label;
  final IconData icon;
  final Color accentColor;
  final String? assetPath;
}
