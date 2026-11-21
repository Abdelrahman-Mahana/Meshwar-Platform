import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/parcel_model.dart';
import '../../data/models/ride_model.dart';
import '../../state/auth_provider.dart';
import '../../state/parcels_provider.dart';
import 'parcel_tracking_screen.dart';
import 'prohibited_items_sheet.dart';

class SendParcelScreen extends StatefulWidget {
  const SendParcelScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  State<SendParcelScreen> createState() => _SendParcelScreenState();
}

class _SendParcelScreenState extends State<SendParcelScreen> {
  final TextEditingController _descController = TextEditingController(text: 'هدوم في كيس');
  final TextEditingController _weightController = TextEditingController(text: '5');
  final TextEditingController _valController = TextEditingController(text: '300');
  final TextEditingController _receiverNameController = TextEditingController(text: 'سارة أحمد');
  final TextEditingController _receiverPhoneController = TextEditingController(text: '01155512345');
  ParcelSize _selectedSize = ParcelSize.small;
  bool _agreedProhibited = true;
  String? _descError;
  String? _weightError;
  String? _valueError;
  String? _receiverNameError;
  String? _receiverPhoneError;

  @override
  void dispose() {
    _descController.dispose();
    _weightController.dispose();
    _valController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  void _validateAndSubmit(bool isAr) {
    final desc = _descController.text.trim();
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final value = int.tryParse(_valController.text) ?? 0;
    final receiverName = _receiverNameController.text.trim();
    final receiverPhone = _receiverPhoneController.text.trim();

    final phoneError = AuthProvider.validateEgyptianPhone(receiverPhone);

    setState(() {
      _descError = desc.isEmpty ? (isAr ? 'يرجى كتابة وصف أو محتوى الطرد' : 'Please enter parcel description') : null;
      _weightError = weight <= 0
          ? (isAr ? 'يرجى إدخال وزن الطرد' : 'Please enter weight')
          : weight > 15
              ? (isAr ? 'الوزن الأقصى 15 كجم' : 'Maximum weight is 15 kg')
              : null;
      _valueError = value <= 0
          ? (isAr ? 'يرجى إدخال القيمة التقديرية' : 'Please enter estimated value')
          : value > 2000
              ? (isAr ? 'القيمة القصوى المصرّح بها 2000 ج' : 'Maximum allowed value is 2000 EGP')
              : null;
      _receiverNameError = receiverName.length < 2
          ? (isAr ? 'يرجى إدخال اسم المستلم' : 'Please enter receiver name')
          : null;
      _receiverPhoneError = phoneError != null
          ? (isAr ? phoneError : 'Phone must be 11 digits starting with 010, 011, 012, or 015')
          : null;
    });

    if (_descError != null ||
        _weightError != null ||
        _valueError != null ||
        _receiverNameError != null ||
        _receiverPhoneError != null) {
      return;
    }

    if (!_agreedProhibited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يجب الإقرار بعدم وجود مواد ممنوعة' : 'You must confirm no prohibited items are included')),
      );
      return;
    }

    final parcels = context.read<ParcelsProvider>();
    parcels.sendParcel(
      driverName: widget.ride.driverName,
      route: '${widget.ride.fromCity} ← ${widget.ride.toCity} · ${widget.ride.departureTime}',
      description: desc,
      size: _selectedSize,
      weightKg: weight,
      estimatedValue: value,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      fee: widget.ride.parcelPrice,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ParcelTrackingScreen(parcel: parcels.currentTrackingParcel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'إرسال طرد' : 'Send Parcel', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            if (isWide) {
              return _buildWideLayout(context, isAr);
            }
            return _buildMobileLayout(context, isAr);
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, bool isAr) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Route, Driver, Safety & Insurance
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRoutePreviewCard(context, isAr),
                      const SizedBox(height: AppDimens.space20),
                      _buildSafetyAgreementCard(context, isAr),
                      const SizedBox(height: AppDimens.space20),
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: AppColors.teal, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isAr ? 'ضمان مشوار لتوصيل الطرود' : 'MASHWAR Parcel Guarantee',
                                  style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'لا يُسلّم الطرد للمستلم النهائي إلا بعد مطابقة كود الاستلام السري (OTP). طردك مؤمن حتى 2000 ج.م.'
                                  : 'Parcels are only handed over upon matching the secret OTP. Insured up to 2000 EGP.',
                              style: AppTypography.bodySecondary().copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space24),

              // Right Column: Parcel Form & CTA
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.space24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSizeSelector(isAr),
                        const SizedBox(height: AppDimens.space20),
                        _buildParcelContentFields(isAr),
                        const SizedBox(height: AppDimens.space20),
                        _buildReceiverFields(isAr),
                        const SizedBox(height: AppDimens.space24),
                        MashwarButton(
                          text: isAr ? 'تأكيد إرسال الطرد' : 'Confirm Parcel Shipment',
                          onPressed: () => _validateAndSubmit(isAr),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isAr) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoutePreviewCard(context, isAr),
              const SizedBox(height: AppDimens.space20),
              _buildSizeSelector(isAr),
              const SizedBox(height: AppDimens.space20),
              _buildParcelContentFields(isAr),
              const SizedBox(height: AppDimens.space20),
              _buildReceiverFields(isAr),
              const SizedBox(height: AppDimens.space20),
              _buildSafetyAgreementCard(context, isAr),
              const SizedBox(height: AppDimens.space24),
              MashwarButton(
                text: isAr ? 'تأكيد إرسال الطرد' : 'Confirm Parcel Shipment',
                onPressed: () => _validateAndSubmit(isAr),
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePreviewCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.navy, size: 28),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}'),
                  style: AppTypography.title().copyWith(fontSize: 16),
                ),
                Text(
                  isAr ? 'مع الكابتن ${widget.ride.driverName}' : 'With Captain ${widget.ride.driverName}',
                  style: AppTypography.bodySecondary(),
                ),
              ],
            ),
          ),
          Text(
            '${widget.ride.parcelPrice} ${isAr ? "ج" : "EGP"}',
            style: AppTypography.title().copyWith(color: AppColors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAr ? 'حجم الطرد' : 'Parcel Size', style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MashwarChip(
                label: isAr ? 'ظرف' : 'Envelope',
                isSelected: _selectedSize == ParcelSize.envelope,
                onTap: () => setState(() => _selectedSize = ParcelSize.envelope),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MashwarChip(
                label: isAr ? 'صغير' : 'Small',
                isSelected: _selectedSize == ParcelSize.small,
                onTap: () => setState(() => _selectedSize = ParcelSize.small),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MashwarChip(
                label: isAr ? 'متوسط' : 'Medium',
                isSelected: _selectedSize == ParcelSize.medium,
                onTap: () => setState(() => _selectedSize = ParcelSize.medium),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MashwarChip(
                label: isAr ? 'كبير' : 'Large',
                isSelected: _selectedSize == ParcelSize.large,
                onTap: () => setState(() => _selectedSize = ParcelSize.large),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParcelContentFields(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MashwarTextField(
          controller: _descController,
          label: isAr ? 'محتوى الطرد' : 'Parcel Content',
          hint: isAr ? 'مثال: أوراق رسمية، ملابس، كتاب' : 'e.g. Official papers, clothes, book',
          errorText: _descError,
        ),
        const SizedBox(height: AppDimens.space16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MashwarTextField(
                controller: _weightController,
                label: isAr ? 'الوزن التقريبي (كجم)' : 'Weight (kg)',
                hint: '5',
                keyboardType: TextInputType.number,
                errorText: _weightError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MashwarTextField(
                controller: _valController,
                label: isAr ? 'القيمة التقديرية (ج)' : 'Value (EGP)',
                hint: '300',
                keyboardType: TextInputType.number,
                errorText: _valueError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiverFields(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAr ? 'بيانات مستلم الطرد' : 'Receiver Info', style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        MashwarTextField(
          controller: _receiverNameController,
          label: isAr ? 'اسم المستلم' : 'Receiver Name',
          hint: isAr ? 'الاسم بالكامل' : 'Full Name',
          errorText: _receiverNameError,
        ),
        const SizedBox(height: AppDimens.space12),
        MashwarTextField(
          controller: _receiverPhoneController,
          label: isAr ? 'رقم موبايل المستلم' : 'Receiver Phone',
          hint: '01XXXXXXXXX',
          keyboardType: TextInputType.phone,
          errorText: _receiverPhoneError,
        ),
      ],
    );
  }

  Widget _buildSafetyAgreementCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.navy, size: 20),
                  const SizedBox(width: 8),
                  Text(isAr ? 'شروط أمان الطرود' : 'Parcel Safety Terms', style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ProhibitedItemsSheet(),
                  );
                },
                child: Text(isAr ? 'قائمة الممنوعات' : 'Prohibited Items', style: AppTypography.label(color: AppColors.teal)),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _agreedProhibited,
                activeColor: AppColors.teal,
                onChanged: (val) => setState(() => _agreedProhibited = val ?? false),
              ),
              Expanded(
                child: Text(
                  isAr ? 'أقر بأن الطرد لا يحتوي على أي مواد ممنوعة أو قابلة للاشتعال' : 'I confirm parcel contains no prohibited or flammable goods',
                  style: AppTypography.label(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
