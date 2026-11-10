import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import 'make_offer_sheet.dart';
import 'post_ad_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardProvider>();
    final ads = board.filteredAds;
    final isAr = context.isArabic;

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
            Text(isAr ? 'رحلات وطلبات الناس على طريقك' : 'Rides & requests along your route', style: AppTypography.label(color: AppColors.textSecondary)),
          ],
        ),
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
        label: Text(isAr ? '+ انشر إعلان' : '+ Post Ad', style: AppTypography.button(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Pills (Page 21)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
              child: Row(
                children: [
                  MashwarChip(
                    label: isAr ? 'الكل' : 'All',
                    isSelected: board.selectedType == BoardAdType.all,
                    onTap: () => board.setSelectedType(BoardAdType.all),
                  ),
                  const SizedBox(width: 8),
                  MashwarChip(
                    label: isAr ? 'رحلات' : 'Rides',
                    isSelected: board.selectedType == BoardAdType.rideOffer,
                    onTap: () => board.setSelectedType(BoardAdType.rideOffer),
                  ),
                  const SizedBox(width: 8),
                  MashwarChip(
                    label: isAr ? 'طلب مشوار' : 'Ride Request',
                    isSelected: board.selectedType == BoardAdType.rideRequest,
                    onTap: () => board.setSelectedType(BoardAdType.rideRequest),
                  ),
                  const SizedBox(width: 8),
                  MashwarChip(
                    label: isAr ? 'طلب طرد' : 'Parcel Request',
                    isSelected: board.selectedType == BoardAdType.parcelRequest,
                    onTap: () => board.setSelectedType(BoardAdType.parcelRequest),
                  ),
                ],
              ),
            ),

            // 50km radius note (Page 21)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? 'معروض في نطاق 50 كم من موقعك' : 'Displayed within 50 km from your location',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Ads Feed
            Expanded(
              child: ads.isEmpty
                  ? Center(
                      child: Text(
                        isAr ? 'مفيش إعلانات حالياً في هذا القسم' : 'No ads currently in this category',
                        style: AppTypography.bodySecondary(),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
                      itemCount: ads.length,
                      itemBuilder: (context, index) {
                        final ad = ads[index];
                        return _buildAdCard(context, ad, isAr);
                      },
                    ),
            ),
          ],
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
        typeLabel = isAr ? 'طلب طرد' : 'Parcel Request';
        typeIcon = Icons.inventory_2_outlined;
        break;
      case BoardAdType.rideRequest:
        typeColor = AppColors.warning;
        typeLabel = isAr ? 'طلب مشوار' : 'Ride Request';
        typeIcon = Icons.person_search_outlined;
        break;
      case BoardAdType.rideOffer:
        typeColor = AppColors.navy;
        typeLabel = isAr ? 'عرض توصيل' : 'Ride Offer';
        typeIcon = Icons.directions_car_outlined;
        break;
      case BoardAdType.all:
        typeColor = AppColors.navy;
        typeLabel = isAr ? 'إعلان' : 'Ad';
        typeIcon = Icons.campaign_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      padding: const EdgeInsets.all(AppDimens.space16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Author, rating, relative time, and type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Raw author name from DB
                      Text(ad.authorName, style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                          Text('${ad.authorRating}', style: AppTypography.label()),
                          Text(' · ${context.trDate(ad.timeAgo)}', style: AppTypography.label(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
          const SizedBox(height: 12),

          // Route
          Text(
            context.trRoute(ad.route),
            style: AppTypography.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          // Description / details (stored)
          Text(ad.description, style: AppTypography.bodySecondary()),

          const SizedBox(height: 14),

          // Footer: Suggested price + Action Button (Page 21)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'السعر المقترح' : 'Suggested Price', style: AppTypography.label(color: AppColors.textSecondary)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${ad.suggestedPrice}',
                        style: AppTypography.title().copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(width: 2),
                      Text(isAr ? 'ج' : 'EGP', style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => MakeOfferSheet(ad: ad),
                  );
                },
                child: Text(
                  ad.type == BoardAdType.parcelRequest
                      ? (isAr ? 'أقدر أوصّلها' : 'I can deliver it')
                      : (isAr ? 'قدّم عرض' : 'Make Offer'),
                  style: AppTypography.button(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
