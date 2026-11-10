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

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  BoardAdType? _selectedCategory;
  bool _isSubmitted = false;

  // Form Controllers
  final TextEditingController _fromController = TextEditingController(text: 'طنطا');
  final TextEditingController _toController = TextEditingController(text: 'القاهرة');
  final TextEditingController _timeController = TextEditingController(text: 'الجمعة بعد الظهر');
  final TextEditingController _seatsController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(text: '80');
  final TextEditingController _parcelDescController = TextEditingController(text: 'أوراق ومستندات');
  final TextEditingController _weightController = TextEditingController(text: '2');
  bool _ladiesOnly = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _parcelDescController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit(bool isAr) {
    final board = context.read<BoardProvider>();
    final type = _selectedCategory ?? BoardAdType.rideRequest;

    board.postAd(
      type: type,
      fromCity: _fromController.text.trim(),
      toCity: _toController.text.trim(),
      timeText: _timeController.text.trim(),
      description: type == BoardAdType.parcelRequest
          ? (isAr ? 'طرد ${_parcelDescController.text.trim()} · ${_weightController.text} كجم' : 'Parcel: ${_parcelDescController.text.trim()} · ${_weightController.text} kg')
          : (isAr ? 'كرسي واحد · الميزانية: حتى ${_priceController.text} ج' : '1 Seat · Budget: Up to ${_priceController.text} EGP'),
      priceOrBudget: int.tryParse(_priceController.text) ?? 80,
      isLadiesOnly: _ladiesOnly,
    );

    setState(() => _isSubmitted = true);
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
        title: Text(isAr ? 'انشر طلبك على اللوحة' : 'Post Request on Board', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'عايز إيه؟' : 'What do you need?',
                style: AppTypography.title().copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),

              // 3-Way Choice Cards (Page 23)
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: isAr ? 'عايز مشوار' : 'Need a Ride',
                      subtitle: isAr ? 'أنا راكب بدور على عربية' : 'Passenger looking for a ride',
                      icon: Icons.person_search_outlined,
                      isSelected: _selectedCategory == BoardAdType.rideRequest || _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = BoardAdType.rideRequest),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceCard(
                      title: isAr ? 'عايز أبعت طرد' : 'Send a Parcel',
                      subtitle: isAr ? 'معايا أمانة بدور على مسافر' : 'Looking for a traveler for package',
                      icon: Icons.inventory_2_outlined,
                      isSelected: _selectedCategory == BoardAdType.parcelRequest,
                      onTap: () => setState(() => _selectedCategory = BoardAdType.parcelRequest),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              MashwarTextField(
                controller: _fromController,
                label: isAr ? 'منين؟' : 'From where?',
                hint: isAr ? 'المحافظة أو المدينة' : 'Governorate or city',
              ),
              const SizedBox(height: 12),
              MashwarTextField(
                controller: _toController,
                label: isAr ? 'على فين؟' : 'To where?',
                hint: isAr ? 'المحافظة أو المدينة' : 'Governorate or city',
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
                  label: isAr ? 'عدد الكراسي' : 'Number of Seats',
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _ladiesOnly,
                      activeColor: AppColors.teal,
                      onChanged: (val) => setState(() => _ladiesOnly = val ?? false),
                    ),
                    Text(isAr ? 'رحلة للسيدات فقط' : 'Ladies Only Ride', style: AppTypography.body()),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              MashwarTextField(
                controller: _priceController,
                label: isAr ? 'ميزانيتك المقترحة (ج)' : 'Offered Budget (EGP)',
                hint: '80',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              MashwarButton(
                text: isAr ? 'نشر على اللوحة' : 'Publish to Board',
                onPressed: () => _submit(isAr),
              ),
              const SizedBox(height: 24),
            ],
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
        padding: const EdgeInsets.all(AppDimens.space12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE5E5EA),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppColors.navy : AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.label(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // Page 23: Success + Share on WhatsApp
  Widget _buildSuccessScreen(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
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
              Text(isAr ? 'تم نشر طلبك على اللوحة' : 'Request Published to Board', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'أي حد مسافر على نفس طريقك هيشوف طلبك ويقدر يقدملك عرض.'
                    : 'Anyone traveling along your route can see your request and make an offer.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 32),

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
                  isAr ? 'شارك الطلب على واتساب' : 'Share request on WhatsApp',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تم نسخ رابط الطلب للمشاركة على واتساب' : 'Request link copied for WhatsApp sharing')),
                  );
                },
              ),
              const Spacer(flex: 4),

              MashwarButton(
                text: isAr ? 'الرجوع للوحة' : 'Back to Board',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
