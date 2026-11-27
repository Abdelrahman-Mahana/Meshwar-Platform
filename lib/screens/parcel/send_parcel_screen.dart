import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/board_ad_model.dart';
import '../../data/models/parcel_model.dart';
import '../../data/models/ride_model.dart';
import '../../state/board_provider.dart';
import '../../state/parcels_provider.dart';
import '../../state/rides_provider.dart';
import '../home/city_search_modal.dart';
import 'parcel_tracking_screen.dart';
import 'prohibited_items_sheet.dart';

class SendParcelScreen extends StatefulWidget {
  const SendParcelScreen({
    super.key,
    this.ride, // OPTIONAL! When null, user selects route/traveler or posts standalone parcel request
    this.initialFromCity,
    this.initialToCity,
  });

  final RideModel? ride;
  final String? initialFromCity;
  final String? initialToCity;

  @override
  State<SendParcelScreen> createState() => _SendParcelScreenState();
}

class _SendParcelScreenState extends State<SendParcelScreen> {
  int _currentStep = 1; // 1..3
  double _swapTurns = 0.0;

  // Step 1: Route & Traveler Selection
  late String _fromCity;
  late String _toCity;
  RideModel? _selectedRide;
  late final TextEditingController _proposedFeeController;
  String? _step1Error;

  // Step 2: Parcel Details
  ParcelSize _selectedSize = ParcelSize.small;
  bool _isCustomSize = false;
  final TextEditingController _customSizeController = TextEditingController();
  final TextEditingController _descController =
      TextEditingController(text: 'أوراق ومستندات مغلفة');
  final TextEditingController _weightController =
      TextEditingController(text: '2.0');
  final TextEditingController _valController =
      TextEditingController(text: '250');
  String? _customSizeError;
  String? _descError;
  String? _weightError;
  String? _valueError;

  // Step 3: Recipient & OTP Security
  final TextEditingController _receiverNameController =
      TextEditingController(text: 'نورة الكواري');
  final TextEditingController _receiverPhoneController =
      TextEditingController(text: '+974 66123456');
  bool _agreedProhibited = true;
  String? _receiverNameError;
  String? _receiverPhoneError;

  @override
  void initState() {
    super.initState();
    _selectedRide = widget.ride;
    _fromCity = widget.ride?.fromCity ??
        (widget.initialFromCity?.trim().isNotEmpty == true
            ? widget.initialFromCity!.trim()
            : 'الدوحة');
    _toCity = widget.ride?.toCity ??
        (widget.initialToCity?.trim().isNotEmpty == true
            ? widget.initialToCity!.trim()
            : 'لوسيل');
    _proposedFeeController = TextEditingController(
      text: '${widget.ride?.parcelPrice ?? 25}',
    );
  }

  @override
  void dispose() {
    _proposedFeeController.dispose();
    _customSizeController.dispose();
    _descController.dispose();
    _weightController.dispose();
    _valController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  static String? _validateInternationalPhone(String raw, bool isAr) {
    final compact = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    if (compact.isEmpty) {
      return isAr ? 'يرجى إدخال رقم هاتف المستلم' : 'Enter recipient phone';
    }
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(compact)) {
      return isAr
          ? 'أدخل رقماً دولياً صحيحاً (8 إلى 15 رقماً، ويقبل الرمز +)'
          : 'Enter a valid phone number (8–15 digits, optional +)';
    }
    return null;
  }

  Future<void> _pickCity({required bool isFrom, required bool isAr}) async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CitySearchModal(
          title: isFrom
              ? (isAr ? 'مدينة استلام الطرد' : 'Parcel Pickup City')
              : (isAr ? 'مدينة تسليم الطرد' : 'Parcel Dropoff City'),
          initialValue: isFrom ? _fromCity : _toCity,
        ),
      ),
    );
    if (picked != null && picked.trim().isNotEmpty && mounted) {
      setState(() {
        if (isFrom) {
          _fromCity = picked.trim();
        } else {
          _toCity = picked.trim();
        }
        if (widget.ride == null) {
          _selectedRide = null;
        }
        _step1Error = null;
      });
    }
  }

  void _swapCities() {
    if (widget.ride != null) return;
    setState(() {
      _swapTurns += 0.5;
      final tmp = _fromCity;
      _fromCity = _toCity;
      _toCity = tmp;
      _selectedRide = null;
      _step1Error = null;
    });
  }

  bool _validateStep1(bool isAr) {
    final effFrom = (_selectedRide?.fromCity ?? _fromCity).trim();
    final effTo = (_selectedRide?.toCity ?? _toCity).trim();
    if (effFrom.isEmpty || effTo.isEmpty || effFrom == effTo) {
      setState(() {
        _step1Error = isAr
            ? 'يرجى اختيار نقطة استلام ووجهة مختلفتين للمسار'
            : 'Please choose distinct pickup and destination cities';
      });
      return false;
    }
    if (_selectedRide == null) {
      final fee = int.tryParse(_proposedFeeController.text.trim());
      if (fee == null || fee < 5 || fee > 5000) {
        setState(() {
          _step1Error = isAr
              ? 'يرجى تحديد رسوم توصيل مقترحة بين 5 و 5000'
              : 'Enter a proposed delivery fee between 5 and 5000';
        });
        return false;
      }
    }
    setState(() => _step1Error = null);
    return true;
  }

  bool _validateStep2(bool isAr) {
    final desc = _descController.text.trim();
    final customSize = _customSizeController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final value = int.tryParse(_valController.text.trim()) ?? 0;

    setState(() {
      _customSizeError = _isCustomSize && customSize.length < 2
          ? (isAr
              ? 'يرجى توضيح الحجم أو الأبعاد المخصصة للطرد'
              : 'Please specify the custom package dimensions or type')
          : null;
      _descError = desc.isEmpty
          ? (isAr
              ? 'يرجى كتابة وصف الطرد أو الغرض'
              : 'Please describe the parcel contents')
          : null;
      _weightError = (weight < 0.1 || weight > 25.0)
          ? (isAr
              ? 'الوزن المسموح بين 0.1 و 25 كجم'
              : 'Allowed weight is 0.1 to 25 kg')
          : null;
      _valueError = (value <= 0 || value > 50000)
          ? (isAr
              ? 'أدخل قيمة تقديرية صحيحة (1 - 50,000)'
              : 'Enter a valid declared value (1 - 50,000)')
          : null;
    });

    return _customSizeError == null &&
        _descError == null &&
        _weightError == null &&
        _valueError == null;
  }

  void _handleNextOrSubmit(bool isAr) {
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

    // Step 3 Validation & Final Submission
    if (!_validateStep1(isAr)) {
      setState(() => _currentStep = 1);
      return;
    }
    if (!_validateStep2(isAr)) {
      setState(() => _currentStep = 2);
      return;
    }

    final receiverName = _receiverNameController.text.trim();
    final receiverPhone = _receiverPhoneController.text.trim();
    final phoneErr = _validateInternationalPhone(receiverPhone, isAr);

    setState(() {
      _receiverNameError = receiverName.length < 2
          ? (isAr ? 'يرجى إدخال اسم المستلم كاملاً' : 'Enter recipient name')
          : null;
      _receiverPhoneError = phoneErr;
    });

    if (_receiverNameError != null || _receiverPhoneError != null) {
      return;
    }

    if (!_agreedProhibited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى التأكيد على خلو الطرد من المواد المحظورة'
                : 'Please confirm no prohibited items are included',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final effFrom = (_selectedRide?.fromCity ?? _fromCity).trim();
    final effTo = (_selectedRide?.toCity ?? _toCity).trim();
    final rawDesc = _descController.text.trim();
    final customSizeText = _customSizeController.text.trim();
    final desc = _isCustomSize && customSizeText.isNotEmpty
        ? (isAr
            ? '[$customSizeText] $rawDesc'
            : '[Custom: $customSizeText] $rawDesc')
        : rawDesc;
    final weight = double.tryParse(_weightController.text.trim()) ?? 1.0;
    final value = int.tryParse(_valController.text.trim()) ?? 100;
    final resolvedFee = _selectedRide != null
        ? _selectedRide!.parcelPrice
        : (int.tryParse(_proposedFeeController.text.trim()) ?? 25);

    final parcels = context.read<ParcelsProvider>();
    final createdParcel = parcels.sendParcel(
      ride: _selectedRide,
      driverName: _selectedRide?.driverName ?? '',
      driverId: _selectedRide?.driverId,
      fromCity: effFrom,
      toCity: effTo,
      route: _selectedRide != null
          ? '$effFrom ← $effTo · ${_selectedRide!.departureTime}'
          : '$effFrom ← $effTo',
      description: desc,
      size: _selectedSize,
      weightKg: weight,
      estimatedValue: value,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      fee: resolvedFee,
    );

    // If posted as an open standalone route parcel request, mirror to BoardProvider
    // so travelers heading to that destination see it immediately!
    if (_selectedRide == null) {
      final board = Provider.of<BoardProvider?>(context, listen: false);
      board?.postAd(
        type: BoardAdType.parcelRequest,
        fromCity: effFrom,
        toCity: effTo,
        timeText: isAr
            ? 'أقرب مسافر متاح · ${weight.toStringAsFixed(1)} كجم'
            : 'Next traveler · ${weight.toStringAsFixed(1)} kg',
        description: isAr
            ? 'طرد على الطريق ($desc) · تسليم محمي بكود OTP'
            : 'Route parcel ($desc) · OTP-verified handover',
        priceOrBudget: resolvedFee,
        maxParcelSize: _selectedSize.name,
        serviceSubTagAr: 'طرد على الطريق',
        serviceSubTagEn: 'Route Parcel',
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ParcelTrackingScreen(parcel: createdParcel),
      ),
    );
  }

  List<RideModel> _matchingTravelers(BuildContext context) {
    final ridesProvider = Provider.of<RidesProvider?>(context);
    if (ridesProvider == null) return const [];
    final f = _fromCity.trim().toLowerCase();
    final t = _toCity.trim().toLowerCase();

    return ridesProvider.allRides.where((r) {
      if (!r.acceptsParcels || r.status == 'cancelled') return false;
      final matchFrom = f.isEmpty ||
          r.fromCity.toLowerCase().contains(f) ||
          (r.stopoverCity?.toLowerCase().contains(f) ?? false);
      final matchTo = t.isEmpty ||
          r.toCity.toLowerCase().contains(t) ||
          (r.stopoverCity?.toLowerCase().contains(t) ?? false);
      return matchFrom && matchTo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final stepTitles = isAr
        ? [
            '1. المسار والمسافر',
            '2. تفاصيل الطرد أو الغرض',
            '3. بيانات المستلم وكود الأمان OTP',
          ]
        : [
            '1. Route & Traveler',
            '2. Parcel Details',
            '3. Recipient & OTP Security',
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
              pillar: MashwarServicePillar.routeParcels,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAr ? 'أرسل طرداً على الطريق' : 'Send Parcel on Route',
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
            constraints: const BoxConstraints(maxWidth: 760),
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
                      child: _buildCurrentStepContent(context, isAr),
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
                              ? const ValueKey('send_parcel_submit_btn')
                              : ValueKey('send_parcel_next_$_currentStep'),
                          text: _currentStep == 3
                              ? (isAr
                                  ? 'تأكيد وإصدار كود الأمان OTP'
                                  : 'Confirm & Generate OTP')
                              : (isAr ? 'التالي' : 'Next Step'),
                          onPressed: () => _handleNextOrSubmit(isAr),
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

  Widget _buildCurrentStepContent(BuildContext context, bool isAr) {
    switch (_currentStep) {
      case 1:
        return _buildStep1RouteAndTraveler(context, isAr);
      case 2:
        return _buildStep2ParcelDetails(isAr);
      case 3:
      default:
        return _buildStep3RecipientAndOtp(context, isAr);
    }
  }

  Widget _buildStep1RouteAndTraveler(BuildContext context, bool isAr) {
    final matchingRides =
        widget.ride != null ? <RideModel>[] : _matchingTravelers(context);

    return Column(
      key: const ValueKey('parcel_step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_step1Error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Pre-selected Traveler Card (when navigated from a specific trip)
        if (_selectedRide != null) ...[
          MashwarSectionCard(
            borderColor: AppColors.indigo.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MashwarServicePillarIcon(
                      pillar: MashwarServicePillar.routeParcels,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'شحن مباشر مع المسافر ${_selectedRide!.driverName}'
                                : 'Direct Delivery with ${_selectedRide!.driverName}',
                            style: AppTypography.title().copyWith(fontSize: 15.5),
                          ),
                          Text(
                            '${_selectedRide!.driverCar} · ★ ${_selectedRide!.driverRating}',
                            style: AppTypography.bodySecondary()
                                .copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigoSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selectedRide!.parcelPrice} ${isAr ? "ر.ق" : "QAR"}',
                        style: AppTypography.title(color: AppColors.indigo)
                            .copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: MashwarRouteTimeline(
                    from:
                        '${context.trCity(_selectedRide!.fromCity)} · ${_selectedRide!.pickupPoint}',
                    to: '${context.trCity(_selectedRide!.toCity)} · ${_selectedRide!.dropoffPoint}',
                    trailingTop: _selectedRide!.departureTime,
                    compact: true,
                  ),
                ),
                if (widget.ride == null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedRide = null),
                      icon: const Icon(Icons.swap_calls_rounded, size: 16),
                      label: Text(
                        isAr
                            ? 'تغيير المسافر أو إرسال كطلب مفتوح'
                            : 'Change Traveler or Send Open Request',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          // Route Picker Card when no ride was pre-passed
          MashwarSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'حدّد مسار الطرد' : 'Select Parcel Route',
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
                            _RouteSelectorRow(
                              dotColor: AppColors.emerald,
                              label: isAr ? 'من (نقطة الاستلام)' : 'Pickup City',
                              value: context.trCity(_fromCity),
                              onTap: () =>
                                  _pickCity(isFrom: true, isAr: isAr),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                height: 1,
                                color: AppColors.slateBorder,
                              ),
                            ),
                            _RouteSelectorRow(
                              dotColor: AppColors.indigo,
                              isSquare: true,
                              label: isAr ? 'إلى (نقطة التسليم)' : 'Dropoff City',
                              value: context.trCity(_toCity),
                              onTap: () =>
                                  _pickCity(isFrom: false, isAr: isAr),
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
                              color: AppColors.indigo,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MashwarTextField(
                  controller: _proposedFeeController,
                  label: isAr
                      ? 'مكافأة التوصيل المقترحة للمسافر (ر.ق)'
                      : 'Proposed Delivery Fee for Traveler (QAR)',
                  hint: '25',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Open Route Request Option + Available Parcel-Friendly Travelers
          Text(
            isAr
                ? 'المسافرون المتاحون على هذا الطريق (${matchingRides.length})'
                : 'Parcel-Friendly Travelers on Route (${matchingRides.length})',
            style: AppTypography.title().copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          MashwarHoverCard(
            backgroundColor: AppColors.indigoSurface,
            borderColor: AppColors.indigo,
            padding: const EdgeInsets.all(14),
            onTap: () => setState(() => _selectedRide = null),
            child: Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: AppColors.indigo,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'نشر كطلب مفتوح للمسافرين في هذا الاتجاه'
                            : 'Post as Open Route Request',
                        style: AppTypography.body().copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'يظهر لكل مسافر متجه إلى ${context.trCity(_toCity)} ليستلم الطرد في طريقه'
                            : 'Visible to any verified traveler heading to ${context.trCity(_toCity)}',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.indigo,
                  size: 20,
                ),
              ],
            ),
          ),
          if (matchingRides.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final traveler in matchingRides.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MashwarHoverCard(
                  borderColor: AppColors.slateBorder,
                  hoverBorderColor: AppColors.indigo,
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    setState(() {
                      _selectedRide = traveler;
                      _fromCity = traveler.fromCity;
                      _toCity = traveler.toCity;
                      _step1Error = null;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.cobaltSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          traveler.driverName.isNotEmpty
                              ? traveler.driverName[0]
                              : 'T',
                          style: AppTypography.title(color: AppColors.cobalt)
                              .copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              traveler.driverName,
                              style: AppTypography.body()
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${context.trRoute("${traveler.fromCity} ← ${traveler.toCity}")} · ${traveler.departureTime}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSurface,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          isAr
                              ? 'اختر (${traveler.parcelPrice} ر.ق)'
                              : 'Select (${traveler.parcelPrice} QAR)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildStep2ParcelDetails(bool isAr) {
    final sizeOptions = <({
      ParcelSize size,
      String title,
      String hint,
      IconData icon,
    })>[
      (
        size: ParcelSize.envelope,
        title: isAr ? 'ظرف مستندات' : 'Envelope',
        hint: isAr ? 'أوراق، مفاتيح (حتى 0.5 كجم)' : 'Docs, keys (up to 0.5 kg)',
        icon: Icons.mail_outline_rounded,
      ),
      (
        size: ParcelSize.small,
        title: isAr ? 'حقيبة صغيرة' : 'Small Bag',
        hint: isAr ? 'علبة، ملابس (1 - 5 كجم)' : 'Small bag (1 - 5 kg)',
        icon: Icons.shopping_bag_outlined,
      ),
      (
        size: ParcelSize.medium,
        title: isAr ? 'صندوق متوسط' : 'Medium Box',
        hint: isAr ? 'كرتون متوسط (5 - 12 كجم)' : 'Carton (5 - 12 kg)',
        icon: Icons.inventory_2_outlined,
      ),
      (
        size: ParcelSize.large,
        title: isAr ? 'طرد كبير' : 'Large Parcel',
        hint: isAr ? 'شنطة سفر بالصندوق (حتى 25 كجم)' : 'Trunk item (up to 25 kg)',
        icon: Icons.luggage_outlined,
      ),
    ];

    final quickContents = isAr
        ? [
            'أوراق ومستندات مغلفة',
            'ملابس وأغراض شخصية',
            'جهاز إلكتروني مبطن',
            'قطع غيار أو مستلزمات',
          ]
        : [
            'Sealed official documents',
            'Personal clothes & bag',
            'Packaged electronics',
            'Light spare parts',
          ];

    return Column(
      key: const ValueKey('parcel_step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'اختر حجم الطرد أو الغرض' : 'Select Package Size',
                style: AppTypography.title().copyWith(fontSize: 15.5),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final halfW = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...sizeOptions.map((opt) {
                        final isSel = !_isCustomSize && _selectedSize == opt.size;
                        return SizedBox(
                          width: halfW,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() {
                              _isCustomSize = false;
                              _selectedSize = opt.size;
                              _customSizeError = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.indigoSurface
                                    : AppColors.slateBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.indigo
                                      : AppColors.slateBorder,
                                  width: isSel ? 1.6 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(
                                        opt.icon,
                                        size: 20,
                                        color: isSel
                                            ? AppColors.indigo
                                            : AppColors.navy,
                                      ),
                                      if (isSel)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: AppColors.indigo,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    opt.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body().copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    opt.hint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color: AppColors.textSecondary,
                                    ).copyWith(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: InkWell(
                          key: const ValueKey('parcel_size_other'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() {
                            _isCustomSize = true;
                            _selectedSize = ParcelSize.large;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _isCustomSize
                                  ? AppColors.indigoSurface
                                  : AppColors.slateBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isCustomSize
                                    ? AppColors.indigo
                                    : AppColors.slateBorder,
                                width: _isCustomSize ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: _isCustomSize
                                      ? AppColors.indigo
                                      : AppColors.navy,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAr
                                            ? 'أخرى (مقاس أو شكل مخصص)'
                                            : 'Other (Custom Size / Shape)',
                                        style: AppTypography.body().copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        isAr
                                            ? 'مثل: أنبوب طويل، لوحة فنية، طرد بتغليف خاص...'
                                            : 'e.g. Long tube, framed item, special packaging...',
                                        style: AppTypography.label(
                                          color: AppColors.textSecondary,
                                        ).copyWith(fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isCustomSize)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: AppColors.indigo,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_isCustomSize) ...[
                const SizedBox(height: 12),
                MashwarTextField(
                  key: const ValueKey('parcel_custom_size_input'),
                  controller: _customSizeController,
                  label: isAr
                      ? 'حدد الأبعاد أو طبيعة التغليف *'
                      : 'Specify Custom Dimensions / Type *',
                  hint: isAr
                      ? 'مثال: صندوق 60×40 سم أو أنبوب طول 1 متر'
                      : 'e.g. 60x40cm box or 1m rolled tube',
                  errorText: _customSizeError,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'وصف المحتوى والوزن' : 'Contents & Weight',
                style: AppTypography.title().copyWith(fontSize: 15.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...quickContents.map((preset) {
                    final sel = _descController.text.trim() == preset;
                    return ActionChip(
                      label: Text(preset),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.navy,
                        fontFamily: 'Cairo',
                      ),
                      backgroundColor: sel ? AppColors.indigo : AppColors.slateBg,
                      side: BorderSide(
                        color: sel ? AppColors.indigo : AppColors.slateBorder,
                      ),
                      onPressed: () => setState(() {
                        _descController.text = preset;
                        _descError = null;
                      }),
                    );
                  }),
                  ActionChip(
                    key: const ValueKey('parcel_content_other'),
                    avatar: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.indigo,
                    ),
                    label: Text(isAr ? 'أخرى (وصف مخصص)' : 'Other (Custom)'),
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.indigo,
                      fontFamily: 'Cairo',
                    ),
                    backgroundColor: AppColors.indigoSurface,
                    side: BorderSide(
                      color: AppColors.indigo.withValues(alpha: 0.35),
                    ),
                    onPressed: () => setState(() {
                      _descController.clear();
                      _descError = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MashwarTextField(
                controller: _descController,
                label: isAr ? 'وصف الطرد أو الغرض' : 'Parcel Description',
                hint: isAr
                    ? 'مثال: ظرف مستندات، حقيبة شخصية...'
                    : 'e.g. Sealed documents, small bag...',
                errorText: _descError,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MashwarTextField(
                      controller: _weightController,
                      label: isAr ? 'الوزن (0.1 - 25 كجم)' : 'Weight (0.1 - 25 kg)',
                      hint: '2.0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      errorText: _weightError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MashwarTextField(
                      controller: _valController,
                      label:
                          isAr ? 'القيمة المصرّح بها (ر.ق)' : 'Declared Value (QAR)',
                      hint: '250',
                      keyboardType: TextInputType.number,
                      errorText: _valueError,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3RecipientAndOtp(BuildContext context, bool isAr) {
    final effFrom = (_selectedRide?.fromCity ?? _fromCity).trim();
    final effTo = (_selectedRide?.toCity ?? _toCity).trim();
    final resolvedFee = _selectedRide != null
        ? _selectedRide!.parcelPrice
        : (int.tryParse(_proposedFeeController.text.trim()) ?? 25);

    return Column(
      key: const ValueKey('parcel_step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MashwarSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'بيانات مستلم الطرد' : 'Recipient Information',
                style: AppTypography.title().copyWith(fontSize: 15.5),
              ),
              const SizedBox(height: 12),
              MashwarTextField(
                controller: _receiverNameController,
                label: isAr ? 'اسم المستلم بالكامل' : 'Recipient Full Name',
                hint: isAr ? 'الاسم الثنائي أو الثلاثي' : 'Full Name',
                errorText: _receiverNameError,
              ),
              const SizedBox(height: 12),
              MashwarTextField(
                controller: _receiverPhoneController,
                label: isAr
                    ? 'رقم جوال المستلم (يقبل الأرقام الدولية +)'
                    : 'Recipient Phone (International + supported)',
                hint: '+974 66123456',
                keyboardType: TextInputType.phone,
                errorText: _receiverPhoneError,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dual OTP Security Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.emeraldSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.emerald,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'تأمين مزدوج بكود الاستلام والتسليم (OTP)'
                          : 'Dual-OTP Handover Protection',
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'يُصدر النظام فوراً كود استلام (عند تسليمك الطرد للمسافر) وكود تسليم نهائي للمستلم لضمان وصول الأمانة بأمان تام.'
                          : 'Generates a 4-digit Pickup OTP for traveler handover and a Delivery OTP for final recipient confirmation.',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ).copyWith(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Safety Terms Confirmation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.navy,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isAr
                                ? 'إقرار سلامة محتويات الطرد'
                                : 'Parcel Safety Declaration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body()
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final agreed = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ProhibitedItemsSheet(),
                      );
                      if (agreed == true && mounted) {
                        setState(() => _agreedProhibited = true);
                      }
                    },
                    child: Text(
                      isAr ? 'قائمة الممنوعات' : 'Prohibited Items',
                      style: AppTypography.label(color: AppColors.indigo)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _agreedProhibited,
                    activeColor: AppColors.emerald,
                    onChanged: (val) =>
                        setState(() => _agreedProhibited = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'أقر بأن الطرد مكشوف للمسافر عند الاستلام ولا يحتوي على مواد ممنوعة أو خطرة'
                          : 'I confirm the parcel contains no prohibited or hazardous items',
                      style: AppTypography.label(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Shipment Summary Strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trRoute('$effFrom ← $effTo'),
                      style: AppTypography.body()
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _selectedRide != null
                          ? (isAr
                              ? 'مع المسافر: ${_selectedRide!.driverName}'
                              : 'Traveler: ${_selectedRide!.driverName}')
                          : (isAr
                              ? 'طلب طرد مفتوح على المسار'
                              : 'Open Route Parcel Request'),
                      style: AppTypography.label(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$resolvedFee ${isAr ? "ر.ق" : "QAR"}',
                style: AppTypography.title(color: AppColors.indigo)
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteSelectorRow extends StatelessWidget {
  const _RouteSelectorRow({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.onTap,
    this.isSquare = false,
  });

  final Color dotColor;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isSquare;

  @override
  Widget build(BuildContext context) {
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
                    value,
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
}
