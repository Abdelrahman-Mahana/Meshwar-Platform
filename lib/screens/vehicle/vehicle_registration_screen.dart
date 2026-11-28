import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  static const String _otherModelKey = 'other_model';
  static const String _otherColorKey = 'other_color';

  static const List<(String key, String ar, String en)> _modelPresets = [
    ('تويوتا كامري 2024', 'تويوتا كامري 2024', 'Toyota Camry 2024'),
    ('تويوتا لاندكروزر', 'تويوتا لاندكروزر', 'Toyota Land Cruiser'),
    ('نيسان باترول', 'نيسان باترول', 'Nissan Patrol'),
    ('لكزس ES', 'لكزس ES', 'Lexus ES'),
    (_otherModelKey, 'أخرى (طراز مخصص)', 'Other (Custom Model)'),
  ];

  static const List<(String key, String ar, String en)> _colorPresets = [
    ('أبيض لؤلؤي', 'أبيض لؤلؤي', 'Pearl White'),
    ('فضي', 'فضي', 'Silver'),
    ('أسود', 'أسود', 'Black'),
    ('رمادي', 'رمادي', 'Slate Grey'),
    (_otherColorKey, 'أخرى (لون مخصص)', 'Other (Custom Color)'),
  ];

  static bool get _isLiveMode =>
      AppEnvironment.isFirebaseRuntimeActive && !AppEnvironment.useDevMocks;

  final TextEditingController _modelController = TextEditingController(
    text: _isLiveMode ? '' : 'تويوتا كامري 2024',
  );
  final TextEditingController _colorController = TextEditingController(
    text: _isLiveMode ? '' : 'أبيض لؤلؤي',
  );
  final TextEditingController _plateLettersController = TextEditingController(
    text: _isLiveMode ? '' : 'قطر',
  );
  final TextEditingController _plateNumbersController = TextEditingController(
    text: _isLiveMode ? '' : '482910',
  );

  String _selectedModelPreset = 'تويوتا كامري 2024';
  String _selectedColorPreset = 'أبيض لؤلؤي';
  int _seatsCount = 3;
  bool _hasAC = true;
  bool _largeTrunk = true;
  bool _drivingLicenseUploaded = !_isLiveMode;
  bool _carLicenseUploaded = !_isLiveMode;
  bool _isSaving = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateSavedVehicle();
    });
  }

  Future<void> _hydrateSavedVehicle() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    final savedVibe = auth?.user.tripVibe?.trim() ?? '';
    if (savedVibe.contains('·')) {
      final parts = savedVibe.split('·').map((s) => s.trim()).toList();
      if (parts.length >= 3) {
        _applyHydratedValues(
          model: parts[0],
          color: parts[1],
          plateCombined: parts[2],
        );
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      if (!mounted) return;
      final savedModel = prefs.getString('mashwar_vehicle_model');
      final savedColor = prefs.getString('mashwar_vehicle_color');
      final savedLetters = prefs.getString('mashwar_vehicle_plate_letters');
      final savedNumbers = prefs.getString('mashwar_vehicle_plate_numbers');
      final savedSeats = prefs.getInt('mashwar_vehicle_seats');
      final savedAc = prefs.getBool('mashwar_vehicle_ac');
      final savedTrunk = prefs.getBool('mashwar_vehicle_trunk');

      if (savedModel != null && savedModel.trim().isNotEmpty) {
        setState(() {
          _modelController.text = savedModel.trim();
          _selectedModelPreset =
              _modelPresets.any((p) => p.$1 == savedModel.trim())
                  ? savedModel.trim()
                  : _otherModelKey;
          if (savedColor != null && savedColor.trim().isNotEmpty) {
            _colorController.text = savedColor.trim();
            _selectedColorPreset =
                _colorPresets.any((p) => p.$1 == savedColor.trim())
                    ? savedColor.trim()
                    : _otherColorKey;
          }
          if (savedLetters != null && savedLetters.trim().isNotEmpty) {
            _plateLettersController.text = savedLetters.trim();
          }
          if (savedNumbers != null && savedNumbers.trim().isNotEmpty) {
            _plateNumbersController.text = savedNumbers.trim();
          }
          if (savedSeats != null) _seatsCount = savedSeats.clamp(1, 6);
          if (savedAc != null) _hasAC = savedAc;
          if (savedTrunk != null) _largeTrunk = savedTrunk;
        });
      }
    } catch (_) {
      // Unmocked SharedPreferences in headless test environment; keep defaults.
    }
  }

  void _applyHydratedValues({
    required String model,
    required String color,
    required String plateCombined,
  }) {
    if (!mounted) return;
    setState(() {
      if (model.isNotEmpty) {
        _modelController.text = model;
        _selectedModelPreset = _modelPresets.any((p) => p.$1 == model)
            ? model
            : _otherModelKey;
      }
      if (color.isNotEmpty) {
        _colorController.text = color;
        _selectedColorPreset = _colorPresets.any((p) => p.$1 == color)
            ? color
            : _otherColorKey;
      }
      final plateTokens = plateCombined.split(' ');
      if (plateTokens.length >= 2) {
        _plateLettersController.text = plateTokens.first;
        _plateNumbersController.text = plateTokens.sublist(1).join();
      }
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _plateLettersController.dispose();
    _plateNumbersController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_isSaving) return;
    final settings = Provider.of<SettingsProvider?>(context, listen: false);
    final isAr = settings?.isArabic ?? context.isArabic;

    final model = _modelController.text.trim();
    final color = _colorController.text.trim();
    final plateLetters = _plateLettersController.text.trim().isNotEmpty
        ? _plateLettersController.text.trim()
        : 'قطر';
    final plateNumbers = _plateNumbersController.text.trim();

    if (model.length < 2) {
      setState(() {
        _validationError = isAr
            ? 'يرجى إدخال الماركة والطراز'
            : 'Please enter vehicle make & model';
      });
      return;
    }
    if (color.length < 2) {
      setState(() {
        _validationError =
            isAr ? 'يرجى إدخال لون المركبة' : 'Please enter vehicle color';
      });
      return;
    }
    if (plateNumbers.length < 3) {
      setState(() {
        _validationError = isAr
            ? 'يرجى إدخال رقم لوحة المركبة بشكل صحيح'
            : 'Please enter a valid Qatar plate number';
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isSaving = true;
    });

    final vehicleSummary =
        '$model · $color · $plateLetters $plateNumbers · $_seatsCount مقاعد';

    final auth = Provider.of<AuthProvider?>(context, listen: false);
    if (auth != null) {
      final existingOcc = auth.user.occupation?.trim() ?? '';
      final cleanBaseOcc = existingOcc.contains(' — ')
          ? existingOcc.split(' — ').first.trim()
          : existingOcc;
      final updatedOccupation = cleanBaseOcc.isNotEmpty
          ? '$cleanBaseOcc — $model ($plateLetters $plateNumbers)'
          : '$model ($plateLetters $plateNumbers)';

      auth.updateProfile(
        tripVibe: vehicleSummary,
        occupation: updatedOccupation,
      );
    }

    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(milliseconds: 120));
        await prefs.setString('mashwar_vehicle_model', model);
        await prefs.setString('mashwar_vehicle_color', color);
        await prefs.setString('mashwar_vehicle_plate_letters', plateLetters);
        await prefs.setString('mashwar_vehicle_plate_numbers', plateNumbers);
        await prefs.setInt('mashwar_vehicle_seats', _seatsCount);
        await prefs.setBool('mashwar_vehicle_ac', _hasAC);
        await prefs.setBool('mashwar_vehicle_trunk', _largeTrunk);
      } catch (_) {}
    }());

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم حفظ بيانات المركبة والرخص بنجاح'
              : 'Vehicle and licenses saved successfully',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(vehicleSummary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'بيانات سيارتي ورخص القيادة' : 'Vehicle & Driver Licenses',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Approval Card
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.teal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppDimens.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isAr
                                            ? 'مركبة معتمدة للرحلات'
                                            : 'Approved Vehicle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.title()
                                            .copyWith(fontSize: 15),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    MashwarBadge(
                                      type: BadgeType.verified,
                                      customLabel: isAr ? 'معتمدة' : 'Verified',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isAr
                                      ? 'سيارتك مفعّلة لعرض المقاعد الشاغرة وتوصيل الطرود.'
                                      : 'Your vehicle is active for carpool & parcel delivery.',
                                  style: AppTypography.label(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_validationError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _validationError!,
                                style: AppTypography.label(
                                  color: AppColors.danger,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.space20),

                    // Car Details Section
                    Text(
                      isAr ? 'مواصفات المركبة' : 'Vehicle Specifications',
                      style: AppTypography.title().copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppDimens.space12),

                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'اختر الطراز أو حدّد أخرى (طراز مخصص)'
                                : 'Select Model or Other (Custom)',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _modelPresets.map((preset) {
                              final isOther = preset.$1 == _otherModelKey;
                              final isSel = _selectedModelPreset == preset.$1;
                              return MashwarChip(
                                key: isOther
                                    ? const ValueKey('vehicle_model_other_chip')
                                    : null,
                                label: isAr ? preset.$2 : preset.$3,
                                isSelected: isSel,
                                onTap: () {
                                  setState(() {
                                    _selectedModelPreset = preset.$1;
                                    if (isOther) {
                                      _modelController.clear();
                                    } else {
                                      _modelController.text = preset.$1;
                                    }
                                    _validationError = null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          _buildInputTile(
                            fieldKey: const ValueKey('vehicle_model_input'),
                            label: isAr
                                ? 'الماركة والموديل وسنة الصنع'
                                : 'Make, Model & Year',
                            controller: _modelController,
                            hint: isAr
                                ? 'مثال: تويوتا كورولا 2024 أو طراز مخصص'
                                : 'e.g. Honda Accord 2024',
                            onChanged: (val) {
                              setState(() {
                                _selectedModelPreset = _modelPresets
                                        .any((p) => p.$1 == val.trim())
                                    ? val.trim()
                                    : _otherModelKey;
                                _validationError = null;
                              });
                            },
                          ),
                          const SizedBox(height: AppDimens.space16),

                          Text(
                            isAr
                                ? 'اختر اللون أو حدّد أخرى (لون مخصص)'
                                : 'Select Color or Other (Custom)',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _colorPresets.map((preset) {
                              final isOther = preset.$1 == _otherColorKey;
                              final isSel = _selectedColorPreset == preset.$1;
                              return MashwarChip(
                                key: isOther
                                    ? const ValueKey('vehicle_color_other_chip')
                                    : null,
                                label: isAr ? preset.$2 : preset.$3,
                                isSelected: isSel,
                                onTap: () {
                                  setState(() {
                                    _selectedColorPreset = preset.$1;
                                    if (isOther) {
                                      _colorController.clear();
                                    } else {
                                      _colorController.text = preset.$1;
                                    }
                                    _validationError = null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          _buildInputTile(
                            fieldKey: const ValueKey('vehicle_color_input'),
                            label: isAr ? 'لون السيارة' : 'Color',
                            controller: _colorController,
                            hint: isAr
                                ? 'مثال: أبيض لؤلؤي، كحلي، أو لون مخصص'
                                : 'e.g. Pearl White, Navy Blue',
                            onChanged: (val) {
                              setState(() {
                                _selectedColorPreset = _colorPresets
                                        .any((p) => p.$1 == val.trim())
                                    ? val.trim()
                                    : _otherColorKey;
                                _validationError = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Executive Qatar License Plate Card
                    Text(
                      isAr ? 'لوحة المركبة القطرية' : 'Qatar License Plate',
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.navy, width: 1.4),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'QATAR',
                                  style: AppTypography.label(color: Colors.white)
                                      .copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'قـطـر',
                                  style: AppTypography.label(color: Colors.white)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  key: const ValueKey(
                                    'vehicle_plate_letters_input',
                                  ),
                                  controller: _plateLettersController,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.title(
                                    color: AppColors.navy,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'قطر',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1.5,
                                height: 38,
                                color: AppColors.slateBorder,
                              ),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  key: const ValueKey(
                                    'vehicle_plate_numbers_input',
                                  ),
                                  controller: _plateNumbersController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: AppTypography.largeTitle().copyWith(
                                    fontSize: 22,
                                    letterSpacing: 3,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '482910',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.space20),

                    // Capacities & Features
                    Text(
                      isAr ? 'المقاعد والراحة' : 'Comfort & Capacity',
                      style: AppTypography.title().copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppDimens.space12),

                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        side: const BorderSide(color: AppColors.slateBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'عدد المقاعد المتاحة للركاب'
                                  : 'Available Seats',
                              style: AppTypography.body()
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [1, 2, 3, 4, 6].map((count) {
                                final isSel = _seatsCount == count;
                                return Material(
                                  color: isSel
                                      ? AppColors.navy
                                      : AppColors.slateBg,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    key: ValueKey('vehicle_seats_$count'),
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => setState(
                                      () => _seatsCount = count,
                                    ),
                                    child: Container(
                                      width: 44,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel
                                              ? AppColors.navy
                                              : AppColors.slateBorder,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          count == 6 ? '5+' : '$count',
                                          style: AppTypography.body(
                                            color: isSel
                                                ? Colors.white
                                                : AppColors.navy,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(
                              height: 24,
                              color: AppColors.slateBorder,
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeTrackColor: AppColors.teal,
                              value: _hasAC,
                              onChanged: (val) => setState(() => _hasAC = val),
                              title: Text(
                                isAr
                                    ? 'تكييف هواء يعمل بكفاءة'
                                    : 'Air Conditioning (A/C)',
                                style: AppTypography.body(),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.slateBorder,
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeTrackColor: AppColors.teal,
                              value: _largeTrunk,
                              onChanged: (val) =>
                                  setState(() => _largeTrunk = val),
                              title: Text(
                                isAr
                                    ? 'مساحة شنطة كافية للطرود والحقائب'
                                    : 'Large Trunk for Parcels & Luggage',
                                style: AppTypography.body(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.space20),

                    // Licenses Upload
                    Text(
                      isAr ? 'الرخص الرسمية' : 'Official Licenses',
                      style: AppTypography.title().copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppDimens.space12),

                    _buildLicenseTile(
                      title: isAr
                          ? 'رخصة القيادة سارية'
                          : 'Valid Driving License',
                      isUploaded: _drivingLicenseUploaded,
                      onTap: () => setState(
                        () =>
                            _drivingLicenseUploaded = !_drivingLicenseUploaded,
                      ),
                      isAr: isAr,
                    ),
                    const SizedBox(height: AppDimens.space12),
                    _buildLicenseTile(
                      title: isAr
                          ? 'رخصة تسيير المركبة (استمارة)'
                          : 'Vehicle Registration License',
                      isUploaded: _carLicenseUploaded,
                      onTap: () => setState(
                        () => _carLicenseUploaded = !_carLicenseUploaded,
                      ),
                      isAr: isAr,
                    ),

                    const SizedBox(height: AppDimens.space24),

                    MashwarButton(
                      key: const ValueKey('vehicle_save_btn'),
                      text: _isSaving
                          ? (isAr ? 'جاري الحفظ...' : 'Saving...')
                          : (isAr ? 'حفظ بيانات السيارة' : 'Save Vehicle Data'),
                      isLoading: _isSaving,
                      onPressed: _saveVehicle,
                    ),

                    const SizedBox(height: AppDimens.space24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputTile({
    Key? fieldKey,
    required String label,
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(color: AppColors.navy)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          onChanged: onChanged,
          style: AppTypography.body(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySecondary(),
            filled: true,
            fillColor: AppColors.slateBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: AppColors.slateBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: AppColors.slateBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(
                color: AppColors.navy,
                width: AppDimens.borderWidthFocused,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseTile({
    required String title,
    required bool isUploaded,
    required VoidCallback onTap,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: isUploaded
              ? AppColors.teal.withValues(alpha: 0.35)
              : AppColors.slateBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isUploaded ? AppColors.tealSurface : AppColors.slateBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUploaded
                  ? Icons.verified_rounded
                  : Icons.file_upload_outlined,
              color: isUploaded ? AppColors.teal : AppColors.navy,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body()
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          MashwarBadge(
            type: isUploaded ? BadgeType.verified : BadgeType.pending,
            customLabel: isUploaded
                ? (isAr ? 'موثقة' : 'Verified')
                : (isAr ? 'مطلوب الرفع' : 'Required'),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.navy,
              size: 20,
            ),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
