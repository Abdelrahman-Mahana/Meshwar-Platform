import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../home/city_search_modal.dart';
import '../home/date_time_picker_sheet.dart';

class PublishRideScreen extends StatefulWidget {
  const PublishRideScreen({super.key});

  @override
  State<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen> {
  int _currentStep = 1; // 1 to 4
  bool _isPublished = false;

  // Step 1: Route & Schedule
  String _fromCity = 'الدوحة';
  String _toCity = 'الخور';
  String? _stopover;
  String _date = 'الجمعة 6 نوفمبر · 7:30 ص';
  String _flexibility = '± 15 د'; // 'في الموعد', '± 15 د', '± 30 د'
  String? _step1Error;

  // Step 2: Distance & Pricing
  final int _distanceKm = 52;
  final int _suggestedPrice = 35;
  int _seatsCount = 3;
  final TextEditingController _priceController = TextEditingController(text: '35');
  String? _priceError;

  // Step 3: Parcels & Preferences
  bool _acceptParcels = true;
  final TextEditingController _smallParcelPrice = TextEditingController(text: '25');
  final TextEditingController _medParcelPrice = TextEditingController(text: '40');
  final TextEditingController _largeParcelPrice = TextEditingController(text: '60');
  bool _instantBooking = false;
  bool _ladiesOnly = false;

  @override
  void dispose() {
    _priceController.dispose();
    _smallParcelPrice.dispose();
    _medParcelPrice.dispose();
    _largeParcelPrice.dispose();
    super.dispose();
  }

  Future<void> _selectCity({required bool isFrom}) async {
    final isAr = context.read<SettingsProvider>().isArabic;
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CitySearchModal(
          title: isFrom
              ? (isAr ? 'نقطة الانطلاق' : 'Departure City')
              : (isAr ? 'نقطة الوصول' : 'Destination City'),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromCity = selected;
        } else {
          _toCity = selected;
        }
        _step1Error = null;
      });
    }
  }

  Future<void> _selectDateTime() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DateTimePickerSheet(
        selectedDay: 'الجمعة 6',
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

  void _nextStep(bool isAr) {
    if (_currentStep == 1) {
      if (_fromCity == _toCity) {
        setState(() => _step1Error = isAr ? 'ما قدرناش نحسب المسار. غيّر النقطتين وجرّب تاني' : 'Invalid route. Points must differ');
        return;
      }
      setState(() {
        _step1Error = null;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      final parsedPrice = int.tryParse(_priceController.text.trim());
      if (parsedPrice == null) {
        setState(() => _priceError = isAr ? 'يرجى إدخال سعر صحيح' : 'Please enter a valid price');
        return;
      }
      if (parsedPrice > 80) {
        setState(() => _priceError = isAr ? 'السعر أعلى من الحد المسموح (80 ر.ق)' : 'Price exceeds allowed ceiling (80 QAR)');
        return;
      }
      if (parsedPrice < 20) {
        setState(() => _priceError = isAr ? 'السعر أقل من الحد الأدنى (20 ر.ق)' : 'Price below minimum (20 QAR)');
        return;
      }
      setState(() {
        _priceError = null;
        _currentStep = 3;
      });
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      final auth = context.read<AuthProvider>();
      final rides = context.read<RidesProvider>();
      final price = int.tryParse(_priceController.text) ?? 35;
      final pPrice = int.tryParse(_smallParcelPrice.text) ?? 25;
      final parts = _date.split('·');
      final datePart = parts.isNotEmpty ? parts.first.trim() : _date;
      final timePart = parts.length > 1 ? parts.last.trim() : '7:30 ص';

      rides.publishRide(
        driverName: auth.user.fullName,
        driverCar: auth.driverFormattedCar,
        driverPhone: auth.user.phone,
        fromCity: _fromCity,
        toCity: _toCity,
        pickupPoint: 'مدخل $_fromCity الرئيسي',
        dropoffPoint: 'محطة $_toCity المركزية',
        departureTime: timePart,
        departureDate: datePart,
        availableSeats: _seatsCount,
        pricePerSeat: price,
        acceptsParcels: _acceptParcels,
        parcelPrice: pPrice,
        isLadiesOnly: _ladiesOnly,
        isInstantBooking: _instantBooking,
      );
      setState(() => _isPublished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    if (_isPublished) {
      // Page 44: تم النشر
      return Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.space24),
                child: MashwarFadeSlideIn(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2.5),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: AppDimens.space20),
                      Text(
                        isAr ? 'تم نشر رحلتك' : 'Trip Published!',
                        style: AppTypography.largeTitle(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'سنبلّغك فور إتمام الحجز. شارك الرحلة لسرعة حجز المقاعد.'
                            : 'We will notify you when passengers book. Share to fill seats faster.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary(),
                      ),
                      const Spacer(flex: 3),

                      MashwarButton(
                        text: isAr ? 'شارك على واتساب' : 'Share on WhatsApp',
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isAr ? 'تم تجهيز رابط الرحلة للمشاركة' : 'Trip link prepared for sharing'),
                              backgroundColor: AppColors.teal,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          isAr ? 'رحلاتي' : 'My Rides',
                          style: AppTypography.body().copyWith(color: AppColors.navy, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: AppDimens.space16),
                    ],
                  ),
                ),
              ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          children: [
            Text(isAr ? 'رحلة جديدة' : 'Post New Ride', style: AppTypography.title()),
            Text(
              isAr ? 'الخطوة $_currentStep من 4' : 'Step $_currentStep of 4',
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStepContent(isAr),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MashwarButton(
                    text: _currentStep == 4
                        ? (isAr ? 'انشر الرحلة' : 'Publish Ride')
                        : (isAr ? 'التالي' : 'Next Step'),
                    onPressed: () => _nextStep(isAr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isAr) {
    switch (_currentStep) {
      case 1:
        // Page 41: الخطوة 1 من 4
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step1Error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_step1Error!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildSectionCard(
              title: isAr ? 'خط السير' : 'Route',
              children: [
                _buildRouteRow(isAr ? 'من' : 'From', _fromCity, onTap: () => _selectCity(isFrom: true)),
                const Divider(height: 20),
                _buildRouteRow(isAr ? 'إلى' : 'To', _toCity, onTap: () => _selectCity(isFrom: false)),
                const Divider(height: 20),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _stopover = _stopover == null ? 'لوسيل' : null);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.teal),
                  label: Text(
                    _stopover != null
                        ? (isAr ? 'محطة: $_stopover (إزالة)' : 'Stopover: $_stopover (Remove)')
                        : (isAr ? '+ أضف محطة في الطريق (اختياري)' : '+ Add Stopover Point (Optional)'),
                    style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.space20),

            _buildSectionCard(
              title: isAr ? 'موعد الانطلاق' : 'Departure Schedule',
              children: [
                InkWell(
                  onTap: _selectDateTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.navy),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.teal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isAr ? 'مرونة الوقت' : 'Time Flexibility', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final flex in ['بالظبط', '± 15 د', '± 30 د']) ...[
                      Expanded(
                        child: MashwarChip(
                          label: flex,
                          isSelected: _flexibility == flex,
                          onTap: () => setState(() => _flexibility = flex),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ],
        );


      case 2:
        // Page 42: الخطوة 2 من 4
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: isAr ? 'المسافة والتكلفة التقديرية' : 'Estimated Cost & Distance',
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'المسافة' : 'Distance', style: AppTypography.bodySecondary()),
                    Text('$_distanceKm ${isAr ? "كم" : "km"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'السعر المقترح' : 'Suggested Price', style: AppTypography.bodySecondary()),
                    Text('$_suggestedPrice ${isAr ? "ر.ق" : "QAR"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.teal)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    isAr
                        ? 'يمكنك تعديل السعر من 20 إلى 80 ر.ق لمشاركة تكلفة الوقود.'
                        : 'You can adjust price between 20 and 80 QAR to share fuel costs.',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.space20),

            _buildSectionCard(
              title: isAr ? 'تحديد المقاعد والسعر' : 'Seats & Seat Price',
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'عدد المقاعد' : 'Seats Count', style: AppTypography.body()),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _seatsCount > 1 ? () => setState(() => _seatsCount--) : null,
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.navy),
                        ),
                        Text('$_seatsCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          onPressed: _seatsCount < 4 ? () => setState(() => _seatsCount++) : null,
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(isAr ? 'سعر المقعد (ر.ق)' : 'Price per Seat (QAR)', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: isAr ? 'ر.ق نقداً' : 'QAR',
                    errorText: _priceError,
                    filled: true,
                    fillColor: AppColors.sand,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        );

      case 3:
        // Page 43: الخطوة 3 من 4
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: isAr ? 'خدمة نقل الطرود' : 'Parcel Delivery Option',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.teal,
                  value: _acceptParcels,
                  onChanged: (val) => setState(() => _acceptParcels = val),
                  title: Text(isAr ? 'أقبل طرود' : 'Accept Parcels'),
                  subtitle: Text(isAr ? 'صغير ومتوسط وكبير في الصندوق الخلفي' : 'Small, medium and large in trunk'),
                ),
                if (_acceptParcels) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _smallParcelPrice,
                          decoration: InputDecoration(labelText: isAr ? 'صغير (ر.ق)' : 'Small (QAR)', filled: true, fillColor: AppColors.sand),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _medParcelPrice,
                          decoration: InputDecoration(labelText: isAr ? 'متوسط (ر.ق)' : 'Medium (QAR)', filled: true, fillColor: AppColors.sand),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _largeParcelPrice,
                          decoration: InputDecoration(labelText: isAr ? 'كبير (ر.ق)' : 'Large (QAR)', filled: true, fillColor: AppColors.sand),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppDimens.space20),

            _buildSectionCard(
              title: isAr ? 'تفضيلات الحجز' : 'Booking Preferences',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.teal,
                  value: _instantBooking,
                  onChanged: (val) => setState(() => _instantBooking = val),
                  title: Text(isAr ? 'حجز تلقائي' : 'Instant Booking'),
                  subtitle: Text(isAr ? 'بدون موافقة يدوية على كل طلب' : 'Book without manual review'),
                ),
                const Divider(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.teal,
                  value: _ladiesOnly,
                  onChanged: (val) => setState(() => _ladiesOnly = val),
                  title: Text(isAr ? 'للسيدات فقط' : 'Ladies Only'),
                  subtitle: Text(isAr ? 'تظهر هذه الرحلة للسيدات فقط' : 'Ride only visible to female riders'),
                ),
              ],
            ),
          ],
        );

      case 4:
      default:
        // Page 44: الخطوة 4 من 4 (مراجعة الرحلة)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: isAr ? 'مراجعة بيانات الرحلة' : 'Review Trip Details',
              children: [
                _buildReviewRow(
                  isAr ? 'المسار' : 'Route',
                  isAr ? '$_fromCity ← $_toCity' : '$_fromCity → $_toCity',
                ),
                const Divider(height: 16),
                _buildReviewRow(isAr ? 'الموعد' : 'Date & Time', '$_date ($_flexibility)'),
                const Divider(height: 16),
                _buildReviewRow(isAr ? 'المقاعد' : 'Seats', '$_seatsCount × ${_priceController.text} ${isAr ? "ر.ق" : "QAR"}'),
                const Divider(height: 16),
                _buildReviewRow(
                  isAr ? 'الطرود' : 'Parcels',
                  _acceptParcels ? (isAr ? 'تقبل، من ${_smallParcelPrice.text} ر.ق' : 'Accepted, from ${_smallParcelPrice.text} QAR') : (isAr ? 'لا تقبل' : 'None'),
                ),
                const Divider(height: 16),
                _buildReviewRow(isAr ? 'الحجز' : 'Booking', _instantBooking ? (isAr ? 'فوري' : 'Instant') : (isAr ? 'بموافقتك' : 'Manual Approval')),
              ],
            ),

            const SizedBox(height: AppDimens.space16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Text(
                isAr
                    ? 'الدفع نقداً من الركاب عند الركوب. التعديل متاح قبل أول حجز.'
                    : 'Cash on pickup directly to driver. Edit available prior to first booking.',
                style: AppTypography.label(color: AppColors.navy),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return MashwarFadeSlideIn(
      offsetY: 10,
      child: MashwarSectionCard(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppTypography.title().copyWith(fontSize: 16))),
              ],
            ),
            const SizedBox(height: AppDimens.space16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRouteRow(String label, String city, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary()),
          Text(city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySecondary()),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
      ],
    );
  }
}
