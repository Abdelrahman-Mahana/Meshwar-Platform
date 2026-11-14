import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../home/city_search_modal.dart';
import 'board_extra_screens.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  BoardAdType _selectedCategory = BoardAdType.rideRequest;
  bool _isSubmitted = false;
  String? _formError;

  // Form Controllers
  final TextEditingController _fromController = TextEditingController(text: 'طنطا');
  final TextEditingController _toController = TextEditingController(text: 'القاهرة');
  final TextEditingController _timeController = TextEditingController(text: 'الجمعة بعد الظهر');
  final TextEditingController _seatsController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(text: '80');
  final TextEditingController _parcelDescController = TextEditingController(text: 'أوراق ومستندات');
  final TextEditingController _weightController = TextEditingController(text: '2');
  final TextEditingController _notesController = TextEditingController();
  bool _ladiesOnly = false;
  bool _acceptsParcels = true;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _parcelDescController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCity(TextEditingController controller, String title) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CitySearchModal(
          title: title,
          initialValue: controller.text.trim(),
        ),
      ),
    );
    if (selected != null && selected.trim().isNotEmpty) {
      setState(() {
        controller.text = selected;
        _formError = null;
      });
    }
  }

  void _swapCities() {
    setState(() {
      final tmp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tmp;
    });
  }

  void _submit(bool isAr) {
    final fromCity = _fromController.text.trim();
    final toCity = _toController.text.trim();
    final timeText = _timeController.text.trim();
    final price = int.tryParse(_priceController.text.trim());

    if (fromCity.isEmpty || toCity.isEmpty || timeText.isEmpty || price == null || price <= 0) {
      setState(() {
        _formError = isAr
            ? 'برجاء إدخال نقطة الانطلاق والوجهة والموعد والسعر بشكل صحيح'
            : 'Please fill in departure, destination, schedule, and a valid price';
      });
      return;
    }

    final board = context.read<BoardProvider>();
    final type = _selectedCategory;
    final seats = int.tryParse(_seatsController.text.trim()) ?? 1;

    String computedTimeText = timeText;
    String computedDesc;
    if (type == BoardAdType.parcelRequest) {
      computedTimeText = isAr
          ? '$timeText · ${_weightController.text.trim()} كجم'
          : '$timeText · ${_weightController.text.trim()} kg';
      computedDesc = isAr
          ? 'طرد: ${_parcelDescController.text.trim()} · المكافأة: $price ج'
          : 'Parcel: ${_parcelDescController.text.trim()} · Reward: $price EGP';
    } else if (type == BoardAdType.rideOffer) {
      computedTimeText = isAr
          ? '$timeText · $seats كراسي فاضية'
          : '$timeText · $seats empty seats';
      computedDesc = _acceptsParcels
          ? (isAr ? 'متاح توصيل طرود صغيرة ومتوسطة على الطريق' : 'Accepts small & medium parcels along the route')
          : (isAr ? 'رحلة ركاب مباشرة · السعر للكرسي $price ج' : 'Direct passenger ride · $price EGP per seat');
    } else {
      computedTimeText = isAr
          ? '$timeText · ${seats == 1 ? "كرسي واحد" : "$seats كراسي"}'
          : '$timeText · $seats seat(s)';
      computedDesc = isAr
          ? 'الميزانية المقترحة: حتى $price ج للكرسي'
          : 'Offered budget: up to $price EGP per seat';
    }

    board.postAd(
      type: type,
      fromCity: fromCity,
      toCity: toCity,
      timeText: computedTimeText,
      description: computedDesc,
      priceOrBudget: price,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      isLadiesOnly: _ladiesOnly,
    );

    setState(() {
      _formError = null;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_isSubmitted) {
      return _buildSuccessScreen(isAr);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'انشر إعلان على اللوحة' : 'Post Ad on Board', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                isAr ? 'اختر نوع الإعلان' : 'Select Ad Category',
                style: AppTypography.title().copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),

              // 3-Way Choice Cards (Page 23): طلب مشوار | طلب طرد | عرض رحلة
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: isAr ? 'طلب مشوار' : 'Need a Ride',
                      subtitle: isAr ? 'راكب بيدور على سائق' : 'Looking for a seat',
                      icon: Icons.person_search_outlined,
                      isSelected: _selectedCategory == BoardAdType.rideRequest,
                      onTap: () => setState(() => _selectedCategory = BoardAdType.rideRequest),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceCard(
                      title: isAr ? 'طلب طرد' : 'Send Parcel',
                      subtitle: isAr ? 'أمانة مع مسافر' : 'Send package',
                      icon: Icons.inventory_2_outlined,
                      isSelected: _selectedCategory == BoardAdType.parcelRequest,
                      onTap: () => setState(() => _selectedCategory = BoardAdType.parcelRequest),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceCard(
                      title: isAr ? 'عرض رحلة' : 'Offer Ride',
                      subtitle: isAr ? 'عندي كراسي فاضية' : 'Empty car seats',
                      icon: Icons.directions_car_outlined,
                      isSelected: _selectedCategory == BoardAdType.rideOffer,
                      onTap: () => setState(() => _selectedCategory = BoardAdType.rideOffer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_formError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _formError!,
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Route fields with Swap & City Search helper
              Stack(
                alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                children: [
                  Column(
                    children: [
                      MashwarTextField(
                        controller: _fromController,
                        label: isAr ? 'منين؟ (نقطة الانطلاق)' : 'From where?',
                        hint: isAr ? 'المحافظة أو المدينة' : 'Governorate or city',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.location_searching_rounded, size: 18, color: AppColors.teal),
                          tooltip: isAr ? 'اختر من القائمة' : 'Pick city',
                          onPressed: () => _pickCity(_fromController, isAr ? 'نقطة الانطلاق' : 'Departure City'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MashwarTextField(
                        controller: _toController,
                        label: isAr ? 'على فين؟ (الوجهة)' : 'To where?',
                        hint: isAr ? 'المحافظة أو المدينة' : 'Governorate or city',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.teal),
                          tooltip: isAr ? 'اختر من القائمة' : 'Pick city',
                          onPressed: () => _pickCity(_toController, isAr ? 'الوجهة' : 'Destination City'),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(side: BorderSide(color: Color(0xFFE5E5EA))),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _swapCities,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.swap_vert_rounded, size: 20, color: AppColors.teal),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MashwarTextField(
                controller: _timeController,
                label: isAr ? 'الموعد المناسب' : 'Preferred Schedule',
                hint: isAr ? 'مثال: بكرة الصبح، الجمعة 4 م' : 'e.g. Tomorrow morning, Fri 4 PM',
              ),
              const SizedBox(height: 12),

              if (_selectedCategory == BoardAdType.parcelRequest) ...[
                MashwarTextField(
                  controller: _parcelDescController,
                  label: isAr ? 'وصف الطرد' : 'Parcel Description',
                  hint: isAr ? 'مثال: دوسيه أوراق، شنطة هدايا' : 'e.g. Documents folder, gift bag',
                ),
                const SizedBox(height: 12),
                MashwarTextField(
                  controller: _weightController,
                  label: isAr ? 'الوزن التقريبي (كجم)' : 'Estimated Weight (kg)',
                  hint: '2',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ] else ...[
                MashwarTextField(
                  controller: _seatsController,
                  label: _selectedCategory == BoardAdType.rideOffer
                      ? (isAr ? 'عدد الكراسي الفاضية' : 'Available Empty Seats')
                      : (isAr ? 'عدد الكراسي المطلوبة' : 'Number of Seats Needed'),
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _ladiesOnly,
                      activeColor: AppColors.teal,
                      onChanged: (val) => setState(() => _ladiesOnly = val ?? false),
                    ),
                    Expanded(
                      child: Text(isAr ? 'رحلة للسيدات فقط' : 'Ladies Only Ride', style: AppTypography.body()),
                    ),
                  ],
                ),
                if (_selectedCategory == BoardAdType.rideOffer)
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptsParcels,
                        activeColor: AppColors.teal,
                        onChanged: (val) => setState(() => _acceptsParcels = val ?? true),
                      ),
                      Expanded(
                        child: Text(
                          isAr ? 'أقبل توصيل طرود صغيرة على طريقي' : 'Accept small parcels along my route',
                          style: AppTypography.body(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],

              MashwarTextField(
                controller: _priceController,
                label: _selectedCategory == BoardAdType.parcelRequest
                    ? (isAr ? 'المكافأة المعروضة للتوصيل (ج)' : 'Offered Delivery Reward (EGP)')
                    : _selectedCategory == BoardAdType.rideOffer
                        ? (isAr ? 'سعر الكرسي الواحد (ج)' : 'Price per Seat (EGP)')
                        : (isAr ? 'ميزانيتك المقترحة للكرسي (ج)' : 'Offered Budget per Seat (EGP)'),
                hint: '80',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              MashwarTextField(
                controller: _notesController,
                label: isAr ? 'ملاحظات إضافية (اختياري)' : 'Additional Notes (Optional)',
                hint: isAr ? 'مثال: مكان التجمع عند محطة القطار، شنطة صغيرة...' : 'e.g. Pickup near train station, small bag...',
              ),

              const SizedBox(height: 28),

              MashwarButton(
                text: isAr ? 'نشر على اللوحة' : 'Publish to Board',
                onPressed: () => _submit(isAr),
              ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealSurface : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE5E5EA),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppColors.navy : AppColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body().copyWith(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // Page 23: Success + Share on WhatsApp + View My Ads
  Widget _buildSuccessScreen(bool isAr) {
    final routeText = '${_fromController.text.trim()} ← ${_toController.text.trim()}';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'تم نشر إعلانك على اللوحة' : 'Ad Published to Board',
                    style: AppTypography.largeTitle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'إعلانك ($routeText) ظاهر الآن لكل المسافرين في نطاقك، وهيجيلك إشعار فور وصول أي عرض.'
                        : 'Your ad ($routeText) is now live on the Board. You will be notified as soon as offers arrive.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: 24),

                  // WhatsApp Share Action (Page 23)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusButton)),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: Text(
                      isAr ? 'شارك الإعلان على واتساب' : 'Share Ad on WhatsApp',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr ? 'تم نسخ رابط الإعلان للمشاركة على واتساب' : 'Ad link copied for WhatsApp sharing',
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 3),

                  MashwarButton(
                    text: isAr ? 'عرض إعلاناتي في اللوحة' : 'View My Board Ads',
                    variant: MashwarButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  MashwarButton(
                    text: isAr ? 'الرجوع للوحة' : 'Back to Board',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
