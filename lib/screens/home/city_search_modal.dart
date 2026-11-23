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
  final TextEditingController _customPointController = TextEditingController(text: 'مترو مشيرب، بوابة الدخول الرئيسية');

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
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
              AppStrings.translateCity(loc.name, isArabic: false).toLowerCase().contains(q);
        }).toList();

        // Query Google Maps & Qatar Catalog for matches
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

  @override
  void dispose() {
    _searchController.dispose();
    _customPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_showCustomMeetingPoint) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
            onPressed: () => setState(() => _showCustomMeetingPoint = false),
          ),
          title: Text(isAr ? 'نقطة التقاء مخصصة' : 'Custom Meeting Point', style: AppTypography.title()),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'اكتب بالتفصيل نقطة الانطلاق أو النزول التي تناسبك' : 'Type detailed pickup or dropoff point that suits you',
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: AppDimens.space16),
                MashwarTextField(
                  controller: _customPointController,
                  label: isAr ? 'نقطة الالتقاء' : 'Meeting Spot',
                  hint: isAr ? 'مثال: محطة المترو، محطة وقود، مجمع تجاري' : 'e.g. Metro station, WOQOD station, Mall gate',
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
      backgroundColor: const Color(0xFFFCFCFD),
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
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
              child: MashwarTextField(
                controller: _searchController,
                hint: isAr ? 'ابحث عن بلدية أو منطقة' : 'Search municipality or district',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterList('');
                        },
                      )
                    : null,
                onChanged: _filterList,
              ),
            ),

            // Smart Qatar Metro, Expressway & Logistics Hub Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLandmarkChip(isAr ? 'محطة وقود وقود (WOQOD)' : 'WOQOD Petrol Station', Icons.local_gas_station_outlined),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(isAr ? 'محطة مترو الدوحة (الريل)' : 'Doha Metro (Qatar Rail)', Icons.directions_subway_outlined),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(isAr ? 'مطار حمد الدولي' : 'Hamad Int\'l Airport', Icons.flight_takeoff_rounded),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(isAr ? 'بوابة المدينة التعليمية' : 'Education City Gate', Icons.school_outlined),
                    const SizedBox(width: 8),
                    _buildLandmarkChip(isAr ? 'شارع 10 · الصناعية' : 'Industrial Area St 10', Icons.precision_manufacturing_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Use Current Location Option (Page 16)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
              ),
              title: Text(
                isAr ? 'استخدم موقعي الحالي' : 'Use Current Location',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isAr ? 'الدوحة (بالقرب منك)' : 'Doha (Near you)',
                style: AppTypography.label(color: AppColors.teal),
              ),
              onTap: () {
                Navigator.of(context).pop('الدوحة');
              },
            ),
            const Divider(height: 1, color: AppColors.borderDisabled),

            // Custom Meeting Point Option (Page 16)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_location_alt_outlined, color: AppColors.navy, size: 20),
              ),
              title: Text(
                isAr ? 'نقطة التقاء مخصصة' : 'Custom Meeting Point',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isAr ? 'حدد شارعاً أو معلماً مميزاً أو محطة مترو' : 'Specify landmark, street, or metro station',
                style: AppTypography.label(),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
              onTap: () {
                setState(() => _showCustomMeetingPoint = true);
              },
            ),
            const Divider(height: 1, color: AppColors.borderDisabled),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              child: Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  _searchController.text.isEmpty
                      ? (isAr ? 'البلديات والمناطق في قطر' : 'Qatar Municipalities & Districts')
                      : (isAr ? 'نتائج البحث' : 'Search Results'),
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
              ),
            ),

            // Autocomplete Results List
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderDisabled),
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  final localizedName = context.trCity(item.name);
                  final localizedRegion = context.trCity(item.region);
                  final localizedType = context.tr(item.typeLabel);

                  return ListTile(
                    leading: Icon(
                      item.isRecent ? Icons.history_rounded : Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(
                      localizedName,
                      style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '$localizedRegion · $localizedType',
                      style: AppTypography.label(color: AppColors.textSecondary),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(item.name);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandmarkChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: AppColors.teal),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy)),
      backgroundColor: const Color(0xFFF3F3F4),
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        Navigator.of(context).pop(label);
      },
    );
  }
}
