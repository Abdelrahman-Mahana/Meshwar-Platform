import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/auth_provider.dart';
import '../../state/board_provider.dart';
import '../../state/rides_provider.dart';
import '../home/city_search_modal.dart';
import '../home/date_time_picker_sheet.dart';

class PublishRideScreen extends StatefulWidget {
  const PublishRideScreen({super.key});

  @override
  State<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen> {
  int _currentStep = 1; // 1..3
  bool _isPublished = false;
  double _swapTurns = 0.0;

  // Step 1: Route & Schedule
  String _fromCity = 'الدوحة';
  String _toCity = 'الخور';
  String? _stopover;
  String _date = 'غداً · صباحاً 7:30 ص';
  String _flexibility = '± 15 د';
  bool _isCustomFlex = false;
  final TextEditingController _customFlexController = TextEditingController();
  String? _step1Error;

  // Step 2: Empty Seats & Parcels Along Route
  int _seatsCount = 3; // 1..6
  final TextEditingController _priceController =
      TextEditingController(text: '35');
  String? _priceError;

  bool _acceptParcels = true;
  String _maxParcelSize = 'small'; // 'envelope', 'small', 'medium', 'other'
  final TextEditingController _customParcelSizeController =
      TextEditingController();
  final TextEditingController _parcelFeeController =
      TextEditingController(text: '25');
  String? _parcelFeeError;

  // Step 3: Preferences & Notes
  bool _instantBooking = true;
  bool _ladiesOnly = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _customFlexController.dispose();
    _customParcelSizeController.dispose();
    _priceController.dispose();
    _parcelFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectCity({
    required bool isFrom,
    bool isStopover = false,
  }) async {
    final isAr = context.isArabic;
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CitySearchModal(
          title: isStopover
              ? (isAr ? 'محطة توقف في الطريق' : 'Stopover City')
              : isFrom
                  ? (isAr ? 'نقطة الانطلاق' : 'Departure City')
                  : (isAr ? 'وجهة السفر' : 'Destination City'),
          initialValue: isStopover
              ? _stopover
              : (isFrom ? _fromCity : _toCity),
        ),
      ),
    );
    if (selected != null && selected.trim().isNotEmpty && mounted) {
      setState(() {
        if (isStopover) {
          _stopover = selected.trim();
        } else if (isFrom) {
          _fromCity = selected.trim();
        } else {
          _toCity = selected.trim();
        }
        _step1Error = null;
      });
    }
  }

  void _swapCities() {
    setState(() {
      _swapTurns += 0.5;
      final tmp = _fromCity;
      _fromCity = _toCity;
      _toCity = tmp;
      _step1Error = null;
    });
  }

  Future<void> _selectDateTime() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DateTimePickerSheet(
        selectedDay: 'غداً',
        selectedTime: 'صباحاً 5-12',
        onApply: (day, time) {
          if (mounted) {
            setState(() {
              _date = '$day · $time';
            });
          }
        },
      ),
    );
  }

  bool _validateStep1(bool isAr) {
    if (_fromCity.trim().isEmpty ||
        _toCity.trim().isEmpty ||
        _fromCity.trim() == _toCity.trim()) {
      setState(() {
        _step1Error = isAr
            ? 'يرجى تحديد نقطة انطلاق ووجهة مختلفتين للمسار'
            : 'Origin and destination must be different';
      });
      return false;
    }
    setState(() => _step1Error = null);
    return true;
  }

  bool _validateStep2(bool isAr) {
    final parsedSeatPrice = int.tryParse(_priceController.text.trim());
    if (parsedSeatPrice == null ||
        parsedSeatPrice < 5 ||
        parsedSeatPrice > 2000) {
      setState(() {
        _priceError = isAr
            ? 'أدخل مساهمة مقعد مرنة بين 5 و 2000'
            : 'Enter a seat contribution between 5 and 2000';
      });
      return false;
    }
    if (_acceptParcels) {
      final parsedParcelFee = int.tryParse(_parcelFeeController.text.trim());
      if (parsedParcelFee == null ||
          parsedParcelFee < 5 ||
          parsedParcelFee > 2000) {
        setState(() {
          _priceError = null;
          _parcelFeeError = isAr
              ? 'أدخل رسوم توصيل الطرد بين 5 و 2000'
              : 'Enter a parcel fee between 5 and 2000';
        });
        return false;
      }
    }
    setState(() {
      _priceError = null;
      _parcelFeeError = null;
    });
    return true;
  }

  void _nextOrPublish(bool isAr) {
    if (_currentStep == 1) {
      if (_validateStep1(isAr)) {
        setState(() => _currentStep = 2);
      }
      return;
    }
    if (_currentStep == 2) {
      if (_validateStep2(isAr)) {
        setState(() => _currentStep = 3);
      }
      return;
    }

    if (!_validateStep1(isAr)) {
      setState(() => _currentStep = 1);
      return;
    }
    if (!_validateStep2(isAr)) {
      setState(() => _currentStep = 2);
      return;
    }

    final auth = context.read<AuthProvider>();
    final rides = context.read<RidesProvider>();
    final board = Provider.of<BoardProvider?>(context, listen: false);

    final seatPrice = int.tryParse(_priceController.text.trim()) ?? 35;
    final parcelFee =
        _acceptParcels ? (int.tryParse(_parcelFeeController.text.trim()) ?? 25) : 0;
    final parts = _date.split('·');
    final datePart = parts.isNotEmpty ? parts.first.trim() : _date;
    final timePart = parts.length > 1 ? parts.last.trim() : '7:30 ص';
    final extraNoteParts = <String>[
      if (_isCustomFlex && _customFlexController.text.trim().isNotEmpty)
        isAr
            ? 'مرونة الانطلاق: ${_customFlexController.text.trim()}'
            : 'Flexibility: ${_customFlexController.text.trim()}',
      if (_acceptParcels &&
          _maxParcelSize == 'other' &&
          _customParcelSizeController.text.trim().isNotEmpty)
        isAr
            ? 'حجم الطرد المسموح: ${_customParcelSizeController.text.trim()}'
            : 'Custom Parcel Size: ${_customParcelSizeController.text.trim()}',
      if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
    ];
    final cleanNotes = extraNoteParts.join(' · ');
    final safeParcelSizeCode =
        _maxParcelSize == 'other' ? 'medium' : _maxParcelSize;

    rides.publishRide(
      driverId: auth.user.id.isNotEmpty ? auth.user.id : null,
      driverName: auth.user.fullName,
      driverCar: auth.driverFormattedCar,
      driverPhone: auth.user.phone,
      fromCity: _fromCity,
      toCity: _toCity,
      stopoverCity: _stopover,
      pickupPoint: isAr ? 'نقطة تجمع $_fromCity' : '$_fromCity Main Hub',
      dropoffPoint: isAr ? 'مركز $_toCity' : '$_toCity Dropoff',
      departureTime: timePart,
      departureDate: datePart,
      availableSeats: _seatsCount,
      pricePerSeat: seatPrice,
      acceptsParcels: _acceptParcels,
      parcelPrice: parcelFee,
      maxParcelSize: _acceptParcels ? safeParcelSizeCode : null,
      notes: cleanNotes.isNotEmpty ? cleanNotes : null,
      isLadiesOnly: _ladiesOnly,
      isInstantBooking: _instantBooking,
    );

    board?.postAd(
      type: BoardAdType.rideOffer,
      fromCity: _fromCity,
      toCity: _toCity,
      stopoverCity: _stopover,
      timeText: isAr
          ? '$_date · $_seatsCount مقاعد شاغرة'
          : '$_date · $_seatsCount empty seats',
      description: _acceptParcels
          ? (isAr
              ? 'مسافر بمقاعد شاغرة ويقبل توصيل طرود خفيفة في طريقه ($parcelFee ر.ق للطرد)'
              : 'Traveler with empty seats & accepts parcels along route ($parcelFee QAR)')
          : (isAr
              ? 'رحلة تشاركية مباشرة · $_seatsCount مقاعد متاحة'
              : 'Direct shared trip · $_seatsCount seats available'),
      priceOrBudget: seatPrice,
      authorName: auth.user.fullName.trim().length >= 2
          ? auth.user.fullName
          : null,
      authorId: auth.user.id.isNotEmpty ? auth.user.id : null,
      maxParcelSize: _acceptParcels ? safeParcelSizeCode : null,
      seatsNeeded: _seatsCount,
      notes: cleanNotes.isNotEmpty ? cleanNotes : null,
      isLadiesOnly: _ladiesOnly,
      isProviderOffer: true,
      serviceSubTagAr:
          _acceptParcels ? 'مقاعد + طرود بالطريق' : '$_seatsCount مقاعد شاغرة',
      serviceSubTagEn:
          _acceptParcels ? 'Seats + Parcels' : '$_seatsCount Empty Seats',
    );

    setState(() => _isPublished = true);
  }

  String _parcelSizeLabel(String code, bool isAr) {
    switch (code) {
      case 'envelope':
        return isAr ? 'ظرف مستندات' : 'Document Envelope';
      case 'medium':
        return isAr ? 'صندوق متوسط' : 'Medium Box';
      case 'other':
        final custom = _customParcelSizeController.text.trim();
        if (custom.isNotEmpty) return custom;
        return isAr ? 'حجم مخصص' : 'Custom Size';
      case 'small':
      default:
        return isAr ? 'حقيبة صغيرة' : 'Small Bag';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_isPublished) {
      return _buildPublishedView(context, isAr);
    }

    final stepTitles = isAr
        ? [
            '1. المسار والموعد',
            '2. المقاعد والطرود على الطريق',
            '3. التفضيلات والنشر',
          ]
        : [
            '1. Route & Schedule',
            '2. Seats & Route Parcels',
            '3. Preferences & Publish',
          ];

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            const MashwarServicePillarIcon(
              pillar: MashwarServicePillar.sharedTrips,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAr ? 'انشر رحلتك للمسافرين والطرود' : 'Publish Traveler Trip',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title().copyWith(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: MashwarWizardStepHeader(
                    currentStep: _currentStep,
                    stepTitles: stepTitles,
                    isAr: isAr,
                  ),
                ),
                const Divider(height: 1, color: AppColors.slateBorder),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildStepBody(isAr),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.slateBorder)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      if (_currentStep > 1) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.slateBorder),
                            minimumSize: const Size(88, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => setState(() => _currentStep--),
                          child: Text(
                            isAr ? 'السابق' : 'Back',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: MashwarButton(
                          key: _currentStep == 3
                              ? const ValueKey('publish_trip_submit_btn')
                              : ValueKey('publish_trip_next_$_currentStep'),
                          text: _currentStep == 3
                              ? (isAr ? 'انشر الرحلة الآن' : 'Publish Trip Now')
                              : (isAr ? 'التالي' : 'Next Step'),
                          onPressed: () => _nextOrPublish(isAr),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(bool isAr) {
    switch (_currentStep) {
      case 1:
        return _buildStep1RouteAndTime(isAr);
      case 2:
        return _buildStep2SeatsAndParcels(isAr);
      case 3:
      default:
        return _buildStep3PreferencesAndSummary(isAr);
    }
  }

  Widget _buildStep1RouteAndTime(bool isAr) {
    final quickTimes = isAr
        ? [
            'اليوم · مساءً 6:00 م',
            'غداً · صباحاً 7:30 ص',
            'غداً · عصراً 4:30 م',
            'الجمعة · صباحاً 8:00 ص',
          ]
        : [
            'Today · 6:00 PM',
            'Tomorrow · 7:30 AM',
            'Tomorrow · 4:30 PM',
            'Friday · 8:00 AM',
          ];

    return Column(
      key: const ValueKey('publish_step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_step1Error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _step1Error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'خط سير الرحلة' : 'Trip Corridor',
                style: AppTypography.title().copyWith(fontSize: 15.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildCityTapTile(
                            dotColor: AppColors.emerald,
                            label: isAr ? 'من (نقطة الانطلاق)' : 'Origin City',
                            city: context.trCity(_fromCity),
                            onTap: () => _selectCity(isFrom: true),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: AppColors.slateBorder,
                            ),
                          ),
                          _buildCityTapTile(
                            dotColor: AppColors.cobalt,
                            isSquare: true,
                            label: isAr ? 'إلى (الوجهة)' : 'Destination City',
                            city: context.trCity(_toCity),
                            onTap: () => _selectCity(isFrom: false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _swapCities,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: AnimatedRotation(
                          turns: _swapTurns,
                          duration: const Duration(milliseconds: 240),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: AppColors.cobalt,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cobalt,
                        side: BorderSide(
                          color: AppColors.cobalt.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          _selectCity(isFrom: false, isStopover: true),
                      icon: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 17,
                      ),
                      label: Text(
                        _stopover != null
                            ? (isAr
                                ? 'محطة: ${context.trCity(_stopover!)}'
                                : 'Stopover: ${context.trCity(_stopover!)}')
                            : (isAr
                                ? '+ محطة مرور اختيارية'
                                : '+ Optional Stopover'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  if (_stopover != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _stopover = null),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'موعد التحرك والمرونة' : 'Departure Schedule',
                style: AppTypography.title().copyWith(fontSize: 15.5),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.cobalt,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _date,
                          style: AppTypography.body()
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        isAr ? 'تغيير' : 'Edit',
                        style: AppTypography.label(color: AppColors.cobalt)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickTimes.map((preset) {
                  final sel = _date == preset;
                  return ActionChip(
                    label: Text(preset),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.navy,
                      fontFamily: 'Cairo',
                    ),
                    backgroundColor: sel ? AppColors.cobalt : AppColors.slateBg,
                    side: BorderSide(
                      color: sel ? AppColors.cobalt : AppColors.slateBorder,
                    ),
                    onPressed: () => setState(() => _date = preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                isAr ? 'مرونة وقت الانطلاق' : 'Departure Flexibility',
                style: AppTypography.label(color: AppColors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final flex in [
                    isAr ? 'في الموعد' : 'Exact',
                    '± 15 د',
                    '± 30 د',
                  ])
                    MashwarChip(
                      label: flex,
                      isSelected: !_isCustomFlex && _flexibility == flex,
                      onTap: () => setState(() {
                        _isCustomFlex = false;
                        _flexibility = flex;
                      }),
                    ),
                  MashwarChip(
                    key: const ValueKey('publish_flex_other'),
                    label: isAr ? 'أخرى (تحديد)' : 'Other',
                    isSelected: _isCustomFlex,
                    onTap: () => setState(() {
                      _isCustomFlex = true;
                      _flexibility = isAr ? 'مرونة مخصصة' : 'Custom';
                    }),
                  ),
                ],
              ),
              if (_isCustomFlex) ...[
                const SizedBox(height: 10),
                MashwarTextField(
                  key: const ValueKey('publish_custom_flex_input'),
                  controller: _customFlexController,
                  label: isAr
                      ? 'حدد مرونة وقت الانطلاق'
                      : 'Specify Departure Flexibility',
                  hint: isAr
                      ? 'مثال: مرن خلال ساعة أو بعد صلاة العصر'
                      : 'e.g. Flexible within 1 hour',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2SeatsAndParcels(bool isAr) {
    final parcelSizePills = <({String code, String label, IconData icon})>[
      (
        code: 'envelope',
        label: isAr ? 'ظرف مستندات' : 'Document Envelope',
        icon: Icons.mail_outline_rounded,
      ),
      (
        code: 'small',
        label: isAr ? 'حقيبة صغيرة' : 'Small Bag',
        icon: Icons.shopping_bag_outlined,
      ),
      (
        code: 'medium',
        label: isAr ? 'صندوق متوسط' : 'Medium Box',
        icon: Icons.inventory_2_outlined,
      ),
      (
        code: 'other',
        label: isAr ? 'أخرى (حجم مخصص)' : 'Other (Custom)',
        icon: Icons.tune_rounded,
      ),
    ];

    return Column(
      key: const ValueKey('publish_step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_seat_outlined,
                    color: AppColors.cobalt,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'المقاعد الشاغرة ومساهمة المقعد'
                          : 'Empty Seats & Seat Contribution',
                      style: AppTypography.title().copyWith(fontSize: 15.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isAr ? 'عدد المقاعد المتاحة (1 إلى 6)' : 'Available Seats (1–6)',
                style: AppTypography.label(color: AppColors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(6, (idx) {
                  final seatVal = idx + 1;
                  final sel = _seatsCount == seatVal;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: idx < 5 ? 6 : 0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _seatsCount = seatVal),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.cobalt : AppColors.slateBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  sel ? AppColors.cobalt : AppColors.slateBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$seatVal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : AppColors.navy,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              MashwarTextField(
                controller: _priceController,
                label: isAr
                    ? 'مساهمة المقعد الواحد (5 - 2000 ر.ق)'
                    : 'Seat Contribution (5 - 2000 QAR)',
                hint: '35',
                keyboardType: TextInputType.number,
                errorText: _priceError,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['15', '25', '35', '50', '75', '120'].map((val) {
                  final sel = _priceController.text.trim() == val;
                  return ActionChip(
                    label: Text('$val ${isAr ? "ر.ق" : "QAR"}'),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.navy,
                      fontFamily: 'Cairo',
                    ),
                    backgroundColor: sel ? AppColors.cobalt : AppColors.slateBg,
                    side: BorderSide(
                      color: sel ? AppColors.cobalt : AppColors.slateBorder,
                    ),
                    onPressed: () => setState(() {
                      _priceController.text = val;
                      _priceError = null;
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prominent Elevated Parcel-Along-Route Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _acceptParcels
                  ? AppColors.indigo.withValues(alpha: 0.45)
                  : AppColors.slateBorder,
              width: _acceptParcels ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withValues(
                  alpha: _acceptParcels ? 0.06 : 0.02,
                ),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const MashwarServicePillarIcon(
                    pillar: MashwarServicePillar.routeParcels,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'وصّل طرداً أو طلباً خفيفاً في طريقك'
                              : 'Carry Parcels / Items Along Your Route',
                          style: AppTypography.title().copyWith(fontSize: 15),
                        ),
                        Text(
                          isAr
                              ? 'استفد من مساحة سيارتك بتوصيل أمانة مفحوصة ومؤمّنة بكود OTP'
                              : 'Earn extra along your drive with OTP-verified light parcels',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    key: const ValueKey('publish_accepts_parcels_switch'),
                    activeTrackColor: AppColors.indigo,
                    value: _acceptParcels,
                    onChanged: (val) => setState(() => _acceptParcels = val),
                  ),
                ],
              ),
              if (_acceptParcels) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.slateBorder),
                ),
                Text(
                  isAr
                      ? 'أقصى حجم طرد يمكنك استيعابه'
                      : 'Maximum Package Size Accepted',
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: parcelSizePills.map((item) {
                    final sel = _maxParcelSize == item.code;
                    return InkWell(
                      key: ValueKey('publish_parcel_size_${item.code}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _maxParcelSize = item.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              sel ? AppColors.indigo : AppColors.indigoSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? AppColors.indigo
                                : AppColors.indigo.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 15,
                              color: sel ? Colors.white : AppColors.indigo,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: sel ? Colors.white : AppColors.indigo,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_maxParcelSize == 'other') ...[
                  const SizedBox(height: 10),
                  MashwarTextField(
                    key: const ValueKey('publish_custom_parcel_size_input'),
                    controller: _customParcelSizeController,
                    label: isAr
                        ? 'حدد نوع أو حجم الطرود المسموحة في سيارتك'
                        : 'Specify Custom Package Size Accepted',
                    hint: isAr
                        ? 'مثال: شنطة سفر كبيرة أو معدات طولها 1.5م'
                        : 'e.g. Large suitcase or 1.5m gear in trunk',
                  ),
                ],
                const SizedBox(height: 14),
                MashwarTextField(
                  controller: _parcelFeeController,
                  label: isAr
                      ? 'رسوم توصيل الطرد على طريقك (ر.ق)'
                      : 'Parcel Delivery Fee Along Route (QAR)',
                  hint: '25',
                  keyboardType: TextInputType.number,
                  errorText: _parcelFeeError,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['15', '25', '40', '60'].map((fee) {
                    final sel = _parcelFeeController.text.trim() == fee;
                    return ActionChip(
                      label: Text('$fee ${isAr ? "ر.ق" : "QAR"}'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.indigo,
                        fontFamily: 'Cairo',
                      ),
                      backgroundColor:
                          sel ? AppColors.indigo : AppColors.indigoSurface,
                      side: BorderSide(
                        color: AppColors.indigo.withValues(alpha: 0.3),
                      ),
                      onPressed: () => setState(() {
                        _parcelFeeController.text = fee;
                        _parcelFeeError = null;
                      }),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3PreferencesAndSummary(bool isAr) {
    final seatPrice = _priceController.text.trim();
    final parcelFee = _parcelFeeController.text.trim();

    return Column(
      key: const ValueKey('publish_step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'تفضيلات الحجز وملاحظات المسار' : 'Booking Preferences',
                style: AppTypography.title().copyWith(fontSize: 15.5),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.cobalt,
                value: _instantBooking,
                onChanged: (val) => setState(() => _instantBooking = val),
                title: Text(
                  isAr ? 'حجز فوري تلقائي' : 'Instant Booking',
                  style: AppTypography.body()
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isAr
                      ? 'تأكيد المقاعد والطرود تلقائياً دون انتظار مراجعة يدوية'
                      : 'Confirm bookings automatically without manual wait',
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
              ),
              const Divider(height: 12, color: AppColors.slateBorder),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.ladiesPink,
                value: _ladiesOnly,
                onChanged: (val) => setState(() => _ladiesOnly = val),
                title: Text(
                  isAr ? 'مخصص للسيدات فقط' : 'Ladies Only',
                  style: AppTypography.body()
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isAr
                      ? 'حصر حجز المقاعد على المسافرات الموثقات'
                      : 'Restrict passenger seat bookings to verified women',
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              MashwarTextField(
                controller: _notesController,
                label: isAr
                    ? 'ملاحظات إضافية للركاب أو مرسلي الطرود (اختياري)'
                    : 'Trip & Parcel Notes (Optional)',
                hint: isAr
                    ? 'مثال: التحرك من محطة المترو، مساحة كافية لحقيبة متوسطة...'
                    : 'e.g. Pickup near metro gate, trunk space available...',
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cobalt.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: AppColors.cobalt,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'ملخص رحلتك الجاهزة للنشر' : 'Live Trip Summary',
                    style: AppTypography.title().copyWith(fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                isAr ? 'المسار' : 'Route',
                '${context.trRoute("$_fromCity ← $_toCity")}${_stopover != null ? " (${context.trCity(_stopover!)})" : ""}',
              ),
              const Divider(height: 16, color: AppColors.slateBorder),
              _buildSummaryRow(
                isAr ? 'الموعد' : 'Schedule',
                '$_date ($_flexibility)',
              ),
              const Divider(height: 16, color: AppColors.slateBorder),
              _buildSummaryRow(
                isAr ? 'المقاعد الشاغرة' : 'Empty Seats',
                isAr
                    ? '$_seatsCount مقاعد · $seatPrice ر.ق للمقعد'
                    : '$_seatsCount seats · $seatPrice QAR / seat',
              ),
              const Divider(height: 16, color: AppColors.slateBorder),
              _buildSummaryRow(
                isAr ? 'الطرود على الطريق' : 'Route Parcels',
                _acceptParcels
                    ? (isAr
                        ? 'متاح (${_parcelSizeLabel(_maxParcelSize, isAr)} · $parcelFee ر.ق)'
                        : 'Accepted (${_parcelSizeLabel(_maxParcelSize, isAr)} · $parcelFee QAR)')
                    : (isAr ? 'مقاعد فقط' : 'Seats only'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublishedView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: MashwarFadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.emeraldSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.emerald,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isAr ? 'تم نشر رحلتك بنجاح!' : 'Trip Published Live!',
                        style: AppTypography.largeTitle().copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'رحلتك (${context.trRoute("$_fromCity ← $_toCity")}) متاحة الآن لحجز المقاعد${_acceptParcels ? " وإرسال الطرود على طريقك" : ""}.'
                            : 'Your trip (${context.trRoute("$_fromCity ← $_toCity")}) is now visible for seat bookings${_acceptParcels ? " and route parcels" : ""}.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary(),
                      ),
                      const SizedBox(height: 24),
                      MashwarButton(
                        text: isAr ? 'مشاركة رابط الرحلة' : 'Share Trip Link',
                        variant: MashwarButtonVariant.secondary,
                        icon: const Icon(
                          Icons.share_outlined,
                          color: AppColors.navy,
                          size: 18,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAr
                                    ? 'تم نسخ رابط الرحلة للمشاركة'
                                    : 'Trip link copied to clipboard',
                              ),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      MashwarButton(
                        text: isAr ? 'العودة للرحلات والطرود' : 'Done',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityTapTile({
    required Color dotColor,
    required String label,
    required String city,
    required VoidCallback onTap,
    bool isSquare = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: dotColor,
                shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isSquare ? BorderRadius.circular(3) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.label(color: AppColors.textSecondary)
                        .copyWith(fontSize: 10.5),
                  ),
                  Text(
                    city,
                    style: AppTypography.body().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySecondary()),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }
}
