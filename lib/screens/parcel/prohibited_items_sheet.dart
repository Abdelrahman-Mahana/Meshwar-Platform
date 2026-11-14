import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';

class ProhibitedItemsSheet extends StatelessWidget {
  const ProhibitedItemsSheet({super.key});

  static const List<String> prohibitedItemsAr = [
    'المخدرات والمواد المخدرة',
    'الأسلحة والمتفجرات',
    'المواد القابلة للاشتعال',
    'الأدوية الخاضعة للرقابة',
    'النقد والمجوهرات',
    'الأغذية سريعة التلف',
    'الكائنات الحية',
    'أي شيء مخالف للقانون',
  ];

  static const List<String> prohibitedItemsEn = [
    'Narcotics & illegal substances',
    'Weapons & explosives',
    'Flammable liquids & materials',
    'Controlled medications',
    'Cash, gold & jewelry',
    'Perishable foods',
    'Live animals & pets',
    'Anything prohibited by Egyptian law',
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final items = isAr ? prohibitedItemsAr : prohibitedItemsEn;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          Text(isAr ? 'قائمة الممنوعات' : 'Prohibited Items List', style: AppTypography.title()),
          const SizedBox(height: 6),
          Text(
            isAr ? 'لا نقبل نقل هذه المواد في الطرود بأي حال:' : 'The following items are strictly prohibited from shipment:',
            style: AppTypography.bodySecondary(),
          ),
          const SizedBox(height: AppDimens.space16),

          // Items container
          Material(
            color: const Color(0xFFF8F9FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E5EA)),
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.block_rounded, color: AppColors.danger, size: 20),
                  title: Text(items[index], style: AppTypography.body().copyWith(fontSize: 14)),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          MashwarButton(
            text: isAr ? 'فهمت وموافق' : 'I Understand & Agree',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      ),
    );
  }
}
