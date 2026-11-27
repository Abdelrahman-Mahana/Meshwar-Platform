import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';

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
    'أي شيء مخالف لقوانين دولة قطر',
  ];

  static const List<String> prohibitedItemsEn = [
    'Narcotics & illegal substances',
    'Weapons & explosives',
    'Flammable liquids & materials',
    'Controlled medications',
    'Cash, gold & jewelry',
    'Perishable foods',
    'Live animals & pets',
    'Anything prohibited by Qatari law',
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final items = isAr ? prohibitedItemsAr : prohibitedItemsEn;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MashwarSheetHeader(
                    title: isAr ? 'قائمة الممنوعات' : 'Prohibited Items List',
                    subtitle: isAr
                        ? 'لا نقبل نقل هذه المواد في الطرود بأي حال:'
                        : 'The following items are strictly prohibited from shipment:',
                    leadingIcon: Icons.gpp_bad_outlined,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  Material(
                    color: AppColors.slateBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      side: const BorderSide(
                        color: AppColors.slateBorder,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.slateBorder,
                      ),
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.block_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          title: Text(
                            items[index],
                            style: AppTypography.body().copyWith(fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimens.space24),

                  MashwarButton(
                    key: const ValueKey('prohibited_items_agree_btn'),
                    text: isAr ? 'فهمت وموافق' : 'I Understand & Agree',
                    onPressed: () => Navigator.of(context).maybePop(true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
