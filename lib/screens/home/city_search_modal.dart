import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../data/mock_data.dart';
import '../../data/models/location_item.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';
import '../../data/services/google_maps_service.dart';

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
  final Map<String, LocationSearchResult> _geoMetaByName = {};
  bool _showCustomMeetingPoint = false;
  int _searchSeq = 0;

  final TextEditingController _customPointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seedLocalGeoMeta();
    if (widget.initialValue != null && widget.initialValue!.trim().isNotEmpty) {
      _searchController.text = widget.initialValue!;
      _filterList(widget.initialValue!);
    }
  }

  void _seedLocalGeoMeta() {
    for (final loc in MockData.locations) {
      final entry = GoogleMapsService.resolveHubEntry(loc.name);
      if (entry != null) {
        _geoMetaByName[loc.name] = LocationSearchResult(
          placeId: 'qa_${entry.id}',
          mainText: loc.name,
          secondaryText: entry.govAr,
          latitude: entry.lat,
          longitude: entry.lng,
          googleMapsPlaceUrl: GoogleMapsService.buildPlaceSearchUrl(
            entry.nameEn,
            lat: entry.lat,
            lng: entry.lng,
          ),
        );
      }
    }
  }

  bool _isSamePlace(LocationItem item, LocationSearchResult candidate) {
    final itemLower = item.name.trim().toLowerCase();
    final candLower = candidate.mainText.trim().toLowerCase();
    if (itemLower == candLower) return true;
    final itemEn =
        AppStrings.translateCity(item.name, isArabic: false).toLowerCase();
    if (itemEn == candLower) return true;
    final itemHub = GoogleMapsService.resolveHubEntry(item.name);
    final candHub = GoogleMapsService.resolveHubEntry(candidate.mainText);
    if (itemHub != null && candHub != null && itemHub.id == candHub.id) {
      return true;
    }
    return false;
  }

  void _filterList(String query) {
    final q = query.trim().toLowerCase();
    final seq = ++_searchSeq;

    if (q.isEmpty) {
      setState(() {
        _filtered = MockData.locations;
      });
      return;
    }

    final localMatches = MockData.locations.where((loc) {
      return loc.name.toLowerCase().contains(q) ||
          loc.region.toLowerCase().contains(q) ||
          AppStrings.translateCity(loc.name, isArabic: false)
              .toLowerCase()
              .contains(q) ||
          AppStrings.translateCity(loc.region, isArabic: false)
              .toLowerCase()
              .contains(q);
    }).toList();

    // Instant synchronous bilingual geo-catalog matches
    final syncCatalogMatches = GoogleMapsService.searchCatalogSync(query);
    final mergedSync = <LocationItem>[...localMatches];
    for (final r in syncCatalogMatches) {
      _geoMetaByName[r.mainText] = r;
      if (!mergedSync.any((m) => _isSamePlace(m, r))) {
        mergedSync.add(
          LocationItem(
            name: r.mainText,
            region: r.secondaryText,
            typeLabel: 'منطقة',
          ),
        );
      }
    }

    setState(() {
      _filtered = mergedSync;
    });

    // Async search via AppRepositories.instance.maps.searchLocations (Google Places API New + catalog)
    AppRepositories.instance.maps.searchLocations(query).then((results) {
      if (!mounted || seq != _searchSeq) return;
      final mergedAsync = <LocationItem>[...mergedSync];
      bool addedAny = false;
      for (final r in results) {
        _geoMetaByName[r.mainText] = r;
        if (!mergedAsync.any((m) => _isSamePlace(m, r))) {
          mergedAsync.add(
            LocationItem(
              name: r.mainText,
              region: r.secondaryText,
              typeLabel: 'مدينة',
            ),
          );
          addedAny = true;
        }
      }
      if (addedAny && mounted) {
        setState(() {
          _filtered = mergedAsync;
        });
      }
    }).catchError((_) {});
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
            ),
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
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
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
                          color: AppColors.cobalt,
                          width: 1.5,
                        ),
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
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                              IconButton(
                                key: const ValueKey('city_preview_typed_gmaps_btn'),
                                tooltip: isAr
                                    ? 'معاينة على الخريطة داخل التطبيق'
                                    : 'Preview on In-App Map',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.map_rounded,
                                  color: AppColors.teal,
                                  size: 19,
                                ),
                                onPressed: () async {
                                  final picked = await openMashwarMapPicker(
                                    context,
                                    initialLocation: typedQuery,
                                    enableGps: true,
                                    pickMode: MashwarMapPickMode.origin,
                                    titleAr: typedQuery,
                                    titleEn: typedQuery,
                                  );
                                  if (picked != null && mounted) {
                                    Navigator.of(context).pop(
                                      picked.localizedLabel(isArabic: isAr),
                                    );
                                  }
                                },
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
                    const SizedBox(width: 8),
                    ActionChip(
                      key: const ValueKey('city_other_custom_chip'),
                      avatar: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 16,
                        color: AppColors.teal,
                      ),
                      label: Text(
                        isAr ? 'أخرى (مكان مخصص)' : 'Other (Custom)',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      backgroundColor: AppColors.tealSurface,
                      side: BorderSide(
                        color: AppColors.teal.withValues(alpha: 0.4),
                      ),
                      onPressed: () =>
                          setState(() => _showCustomMeetingPoint = true),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.slateBorder),

            // Quick Live GPS, Pick on Map & Custom Meeting Point
            Material(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    key: const ValueKey('city_use_current_location_tile'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.cobalt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      isAr ? 'استخدم موقعي الحالي' : 'Use Current Location',
                      style: AppTypography.body()
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isAr
                          ? 'تحديد موقعك المباشر عبر GPS على خريطة مشوار'
                          : 'Locate your live GPS position on MASHWAR Map',
                      style: AppTypography.label(color: AppColors.emerald),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.navy,
                    ),
                    onTap: () async {
                      final picked = await openMashwarMapPicker(
                        context,
                        initialLocation: _searchController.text.trim().isNotEmpty
                            ? _searchController.text.trim()
                            : null,
                        enableGps: true,
                        pickMode: MashwarMapPickMode.origin,
                        titleAr: 'تحديد موقعي الحالي',
                        titleEn: 'Use My Current Location',
                      );
                      if (picked != null && mounted) {
                        Navigator.of(context).pop(
                          picked.localizedLabel(isArabic: isAr),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.slateBorder),
                  ListTile(
                    key: const ValueKey('city_pick_on_map_tile'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.tealSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pin_drop_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      isAr ? 'اختر على الخريطة' : 'Pick on Map',
                      style: AppTypography.body()
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isAr
                          ? 'اضغط أو اسحب الدبوس لتحديد أي نقطة بدقة'
                          : 'Tap or drag the pin to select any spot',
                      style: AppTypography.label(color: AppColors.tealDark),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.navy,
                    ),
                    onTap: () async {
                      final picked = await openMashwarMapPicker(
                        context,
                        initialLocation: _searchController.text.trim().isNotEmpty
                            ? _searchController.text.trim()
                            : null,
                        enableGps: true,
                        pickMode: MashwarMapPickMode.destination,
                        titleAr: 'اختر الموقع على الخريطة',
                        titleEn: 'Pick Location on Map',
                      );
                      if (picked != null && mounted) {
                        Navigator.of(context).pop(
                          picked.localizedLabel(isArabic: isAr),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.slateBorder),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_location_alt_outlined,
                        color: AppColors.emerald,
                        size: 18,
                      ),
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
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.navy,
                    ),
                    onTap: () => setState(() => _showCustomMeetingPoint = true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.slateBorder),

            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      typedQuery.isEmpty
                          ? (isAr
                              ? 'المدن والمحاور السريعة'
                              : 'Suggested Cities & Hubs')
                          : (isAr
                              ? 'نتائج البحث الجغرافي (${_filtered.length})'
                              : 'Matching Locations (${_filtered.length})'),
                      style: AppTypography.label(color: AppColors.textSecondary)
                          .copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pin_drop_outlined,
                        size: 13,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'دليل قطر والخليج' : 'Qatar & GCC Directory',
                        style: AppTypography.label(color: AppColors.teal)
                            .copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
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
                          height: 1,
                          color: AppColors.slateBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          final meta = _geoMetaByName[item.name];
                          final coords = (meta?.latitude != null &&
                                  meta?.longitude != null)
                              ? (lat: meta!.latitude!, lng: meta.longitude!)
                              : GoogleMapsService.resolveCoordinates(item.name);
                          final localizedName = context.trCity(item.name);
                          final localizedRegion = context.trCity(item.region);
                          final localizedType = context.tr(item.typeLabel);

                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: coords != null
                                    ? AppColors.tealSurface
                                    : AppColors.slateBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.isRecent
                                    ? Icons.history_rounded
                                    : (coords != null
                                        ? Icons.pin_drop_rounded
                                        : Icons.location_on_outlined),
                                color: coords != null
                                    ? AppColors.teal
                                    : AppColors.cobalt,
                                size: 19,
                              ),
                            ),
                            title: Text(
                              localizedName,
                              style: AppTypography.body()
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '$localizedRegion · $localizedType',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: IconButton(
                              key: ValueKey('city_preview_gmaps_$index'),
                              tooltip: isAr
                                  ? 'معاينة وتعديل على الخريطة'
                                  : 'Preview & Pick on Map',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.map_rounded,
                                size: 19,
                                color: AppColors.teal,
                              ),
                              onPressed: () async {
                                final picked = await openMashwarMapPicker(
                                  context,
                                  initialLocation: item.name,
                                  lat: coords?.lat,
                                  lng: coords?.lng,
                                  enableGps: true,
                                  pickMode: MashwarMapPickMode.origin,
                                  titleAr: localizedName,
                                  titleEn: localizedName,
                                );
                                if (picked != null && mounted) {
                                  Navigator.of(context).pop(
                                    picked.localizedLabel(isArabic: isAr),
                                  );
                                }
                              },
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
