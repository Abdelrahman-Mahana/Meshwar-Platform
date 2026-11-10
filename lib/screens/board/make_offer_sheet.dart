import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';

class MakeOfferSheet extends StatefulWidget {
  const MakeOfferSheet({super.key, required this.ad});

  final BoardAdModel ad;

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  bool _isMakingOffer = false;
  late TextEditingController _priceController;
  final TextEditingController _noteController = TextEditingController(text: 'أقدر أعدّي عليك في طريقي');

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '${widget.ad.priceOrBudget}');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardProvider>();
    final isAr = context.isArabic;
    final isOfferSent = widget.ad.status == BoardAdStatus.offerSent;
    final isExpired = widget.ad.status == BoardAdStatus.expired;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      ),
      padding: const EdgeInsets.all(AppDimens.space24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            if (isExpired) ...[
              // Expired state (Page 22)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.close_rounded, size: 54, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(isAr ? 'الإعلان ده خلص' : 'This ad has expired', style: AppTypography.largeTitle()),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? 'صاحب الإعلان اختار عرض تاني أو الموعد عدّى.' : 'Author chose another offer or time has passed.',
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: 24),
                    MashwarButton(
                      text: isAr ? 'شوف إعلانات تانية' : 'Browse other ads',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ] else if (isOfferSent) ...[
              // Offer Sent State (Page 22)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal),
                ),
                child: Text(
                  isAr ? 'عرضك اتبعت. هنبلغك لما ${widget.ad.authorName} تردّ' : 'Your offer was sent. We will notify you when ${widget.ad.authorName} replies',
                  style: AppTypography.body().copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailsCard(isAr),
              const SizedBox(height: 24),
              MashwarButton(
                text: isAr ? 'سحب العرض' : 'Withdraw Offer',
                variant: MashwarButtonVariant.secondary,
                onPressed: () {
                  board.withdrawOffer(widget.ad.id);
                  Navigator.of(context).pop();
                },
              ),
            ] else if (_isMakingOffer) ...[
              // Offer Input Mode (Page 22)
              Text(isAr ? 'قدّم عرضك' : 'Make Your Offer', style: AppTypography.title()),
              const SizedBox(height: 16),
              MashwarTextField(
                controller: _priceController,
                label: isAr ? 'سعرك للكرسي / الطرد' : 'Your price for seat / parcel',
                hint: isAr ? '80 ج' : '80 EGP',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              // Quick inDrive-style Price Increment Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickPriceChip(
                      isAr ? 'المطلوب (${widget.ad.priceOrBudget} ج)' : 'Requested (${widget.ad.priceOrBudget})',
                      widget.ad.priceOrBudget,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickPriceChip('+10 ${isAr ? "ج" : "EGP"}', widget.ad.priceOrBudget + 10),
                    const SizedBox(width: 8),
                    _buildQuickPriceChip('+20 ${isAr ? "ج" : "EGP"}', widget.ad.priceOrBudget + 20),
                    const SizedBox(width: 8),
                    _buildQuickPriceChip('+30 ${isAr ? "ج" : "EGP"}', widget.ad.priceOrBudget + 30),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Fair Price Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF15803D)),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? 'نطاق السعر العادل لهذا المسار: 60 - 90 ج' : 'Fair corridor price range: 60 - 90 EGP',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(isAr ? 'رحلتك' : 'Your Trip', style: AppTypography.label()),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusField),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Text(
                  context.trRoute('كفر الشيخ ← القاهرة · الجمعة 7:30 ص'),
                  style: AppTypography.body(),
                ),
              ),
              const SizedBox(height: 16),
              MashwarTextField(
                controller: _noteController,
                label: isAr ? 'ملاحظة (اختياري)' : 'Note (Optional)',
                hint: isAr ? 'أقدر أعدّي عليك في الطريق' : 'I can pick you up on the way',
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'السعر لازم يفضل في حدود مشاركة التكلفة.' : 'Price must remain within fair cost-sharing limits.',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              MashwarButton(
                text: isAr ? 'إرسال العرض' : 'Send Offer',
                onPressed: () {
                  final price = int.tryParse(_priceController.text) ?? widget.ad.priceOrBudget;
                  board.submitOffer(adId: widget.ad.id, offerPrice: price);
                  setState(() => _isMakingOffer = false);
                },
              ),
            ] else ...[
              // Ad details overview before offer (Page 22)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.ad.authorName.isNotEmpty ? widget.ad.authorName[0] : 'س',
                            style: AppTypography.title(color: AppColors.navy),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.ad.authorName, style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
                          Text('★ ${widget.ad.authorRating} · ${context.trDate(widget.ad.timeAgo)}', style: AppTypography.label(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  MashwarBadge(
                    type: BadgeType.newBadge,
                    customLabel: widget.ad.type == BoardAdType.parcelRequest ? (isAr ? 'طرد' : 'Parcel') : (isAr ? 'مشوار' : 'Ride'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailsCard(isAr),
              const SizedBox(height: 24),

              MashwarButton(
                text: isAr ? 'أقدر أوصّلها' : 'I can deliver it',
                onPressed: () => setState(() => _isMakingOffer = true),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.trRoute(widget.ad.route), style: AppTypography.title().copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(widget.ad.description, style: AppTypography.bodySecondary()),
          const Divider(height: 20, color: AppColors.borderDisabled),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isAr ? 'الميزانية المعروضة' : 'Offered Budget', style: AppTypography.label(color: AppColors.textSecondary)),
              Text('${widget.ad.priceOrBudget} ${isAr ? "ج" : "EGP"}', style: AppTypography.title().copyWith(color: AppColors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPriceChip(String label, int value) {
    final isSelected = int.tryParse(_priceController.text) == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priceController.text = '$value';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE5E5EA),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
