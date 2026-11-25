import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';
import '../../data/mock_data.dart';
import '../../data/models/location_item.dart';
import '../../data/repositories/app_repositories.dart';

class CitySearchModal extends StatefulWidget {
  const CitySearchModal({
    super.key,
    required this.title,
    this.initialValue,
  });

  final String title;
  final String? initialValue;

  @override
  State<CitySearchModal> createState() => _CitySearchModalState();
}

class _CitySearchModalState extends State<CitySearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationItem> _filtered = MockData.locations;
  bool _showCustomMeetingPoint = false;
  final TextEditingController _customPointController =
      TextEditingController(text: 'مترو مشيرب، بوابة الدخول الرئيسية');

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.trim().isNotEmpty) {
      _searchController.text = widget.initialValue!;
      _filterList(widget.initialValue!);
    }
  }

  void _filterList(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = MockData.locations;
      } else {
        final localMatches = MockData.locations.where((loc) {
          return loc.name.toLowerCase().contains(q) ||
              loc.region.toLowerCase().contains(q) ||
              AppStrings.translateCity(loc.name, isArabic: false)
                  .toLowerCase()
                  .contains(q);
        }).toList();

        AppRepositories.instance.maps.searchLocations(query).then((results) {
          if (!mounted) return;
          final extraItems = <LocationItem>[];
          for (final r in results) {
            if (!localMatches.any((m) => m.name == r.mainText)) {
              extraItems.add(LocationItem(
                name: r.mainText,
                region: r.secondaryText,
                typeLabel: 'مدينة',
              ));
            }
          }
          if (extraItems.isNotEmpty && mounted) {
            setState(() {
              _filtered = [...localMatches, ...extraItems];
            });
          }
        }).catchError((_) {});

        _filtered = localMatches;
      }
    });
  }

  void _confirmTypedDestination() {
    final typed = _searchController.text.trim();
    if (typed.isNotEmpty) {
      Navigator.of(context).pop(typed);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final typedQuery = _searchController.text.trim();

    if (_showCustomMeetingPoint) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.navy),
            onPressed: () => setState(() => _showCustomMeetingPoint = false),
          ),
          title: Text(
            isAr ? 'نقطة التقاء مخصصة' : 'Custom Meeting Point',
            style: AppTypography.title(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'اكتب بالتفصيل نقطة الانطلاق أو الوصول التي تناسبك'
                      : 'Type the exact pickup or dropoff point that suits you',
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: AppDimens.space16),
                MashwarTextField(
                  controller: _customPointController,
                  label: isAr ? 'نقطة الالتقاء أو العنوان' : 'Meeting Spot',
                  hint: isAr
                      ? 'مثال: محطة المترو، المطار، بوابة المجمع'
                      : 'e.g. Metro station, Airport terminal, Mall gate',
                ),
                const Spacer(),
                MashwarButton(
                  text: isAr ? 'تأكيد المكان' : 'Confirm Spot',
                  onPressed: () {
                    final custom = _customPointController.text.trim();
                    if (custom.isNotEmpty) {
                      Navigator.of(context).pop(custom);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(context.tr(widget.title), style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Any-City Direct Input
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space16,
                8,
                AppDimens.space16,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('city_search_input'),
                    controller: _searchController,
                    textInputAction: TextInputAction.done,
                    onChanged: _filterList,
                    onSubmitted: (_) => _confirmTypedDestination(),
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.slateBg,
                      hintText: isAr
                          ? 'اكتب أي مدينة، مطار، أو وجهة للتأكيد الفوري...'
                          : 'Type any city, airport, or destination...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.cobalt,
                      ),
                      suffixIcon: typedQuery.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: isAr ? 'مسح' : 'Clear',
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterList('');
                                  },
                                ),
                                IconButton(
                                  key: const ValueKey('city_search_submit_icon'),
                                  tooltip: isAr ? 'تأكيد' : 'Confirm',
                                  icon: const Icon(
                                    Icons.arrow_circle_right_rounded,
                                    color: AppColors.cobalt,
                                    size: 22,
                                  ),
                                  onPressed: _confirmTypedDestination,
                                ),
                              ],
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.slateBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.slateBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.cobalt, width: 1.5),
                      ),
                    ),
                  ),
                  if (typedQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Material(
                      color: AppColors.cobaltSurface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: const ValueKey('city_confirm_custom_btn'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: _confirmTypedDestination,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cobalt.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.cobalt,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr
                                          ? 'استخدم "$typedQuery" كوجهة مباشرة'
                                          : 'Use "$typedQuery" directly',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body(
                                        color: AppColors.navy,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      isAr
                                          ? 'تأكيد فوري لأي مدينة أو نقطة التقاء بنقرة واحدة'
                                          : '1-tap confirm custom city or destination',
                                      style: AppTypography.label(
                                        color: AppColors.cobalt,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.cobalt,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Quick Transit, Airport & Hub Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLandmarkChip(
                      isAr
                          ? 'محطة وقود وقود (WOQOD)'
                          : 'WOQOD Petrol Station',
                      Icons.local_gas_station_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(
                      isAr
                          ? 'محطة مترو الدوحة (الريل)'
                          : 'Doha Metro (Qatar Rail)',
                      Icons.directions_subway_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(
                      isAr ? 'مطار حمد الدولي' : 'Hamad Int\'l Airport',
                      Icons.flight_takeoff_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(
                      isAr ? 'بوابة المدينة التعليمية' : 'Education City Gate',
                      Icons.school_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(
                      isAr ? 'شارع 10 · الصناعية' : 'Industrial Area St 10',
                      Icons.precision_manufacturing_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.slateBorder),

            // Quick Current Location & Custom Meeting Point
            Material(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.cobalt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 18),
                    ),
                    title: Text(
                      isAr ? 'استخدم موقعي الحالي' : 'Use Current Location',
                      style: AppTypography.body()
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isAr
                          ? 'تحديد أقرب نقطة انطلاق تلقائياً'
                          : 'Select nearest pickup hub',
                      style: AppTypography.label(color: AppColors.emerald),
                    ),
                    onTap: () => Navigator.of(context).pop('الدوحة'),
                  ),
                  const Divider(height: 1, color: AppColors.slateBorder),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_location_alt_outlined,
                          color: AppColors.emerald, size: 18),
                    ),
                    title: Text(
                      isAr ? 'نقطة التقاء مخصصة' : 'Custom Meeting Point',
                      style: AppTypography.body()
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isAr
                          ? 'حدد شارعاً أو معلماً مميزاً أو بوابة'
                          : 'Specify landmark, street, or gate',
                      style: AppTypography.label(),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.navy),
                    onTap: () => setState(() => _showCustomMeetingPoint = true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.slateBorder),

            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  typedQuery.isEmpty
                      ? (isAr
                          ? 'المدن والمحاور السريعة'
                          : 'Suggested Cities & Hubs')
                      : (isAr ? 'نتائج البحث' : 'Matching Locations'),
                  style: AppTypography.label(color: AppColors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // Autocomplete Results List
            Expanded(
              child: _filtered.isEmpty && typedQuery.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.space24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public_rounded,
                              size: 40,
                              color: AppColors.cobalt,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isAr
                                  ? 'اضغط لتأكيد "$typedQuery" كوجهة مخصصة'
                                  : 'Tap below to confirm "$typedQuery"',
                              textAlign: TextAlign.center,
                              style: AppTypography.body(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            MashwarButton(
                              text: isAr
                                  ? 'تأكيد "$typedQuery"'
                                  : 'Confirm "$typedQuery"',
                              onPressed: _confirmTypedDestination,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.white,
                      child: ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.slateBorder),
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          final localizedName = context.trCity(item.name);
                          final localizedRegion = context.trCity(item.region);
                          final localizedType = context.tr(item.typeLabel);

                          return ListTile(
                            leading: Icon(
                              item.isRecent
                                  ? Icons.history_rounded
                                  : Icons.location_on_outlined,
                              color: AppColors.cobalt,
                            ),
                            title: Text(
                              localizedName,
                              style: AppTypography.body()
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '$localizedRegion · $localizedType',
                              style: AppTypography.label(
                                  color: AppColors.textSecondary),
                            ),
                            onTap: () => Navigator.of(context).pop(item.name),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandmarkChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: AppColors.cobalt),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
      backgroundColor: AppColors.slateBg,
      side: const BorderSide(color: AppColors.slateBorder, width: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => Navigator.of(context).pop(label),
    );
  }
}
