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
  String? _weightError;
  String? _valueError;

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
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final value = int.tryParse(_valController.text) ?? 0;

    setState(() {
      _weightError = weight > 15 ? (isAr ? 'الوزن الأقصى 15 كجم' : 'Maximum weight is 15 kg') : null;
      _valueError = value > 2000 ? (isAr ? 'القيمة القصوى المصرّح بها 2000 ج' : 'Maximum allowed value is 2000 EGP') : null;
    });

    if (_weightError != null || _valueError != null) return;

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
      description: _descController.text.trim(),
      size: _selectedSize,
      weightKg: weight,
      estimatedValue: value,
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: _receiverPhoneController.text.trim(),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route and driver preview
              Container(
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
              ),
              const SizedBox(height: AppDimens.space20),

              // Size Category Chips
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
              const SizedBox(height: AppDimens.space20),

              // Description
              MashwarTextField(
                controller: _descController,
                label: isAr ? 'محتوى الطرد' : 'Parcel Content',
                hint: isAr ? 'مثال: أوراق رسمية، ملابس، كتاب' : 'e.g. Official papers, clothes, book',
              ),
              const SizedBox(height: AppDimens.space16),

              // Weight & Value Row
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
              const SizedBox(height: AppDimens.space20),

              // Receiver info section
              Text(isAr ? 'بيانات مستلم الطرد' : 'Receiver Info', style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              MashwarTextField(
                controller: _receiverNameController,
                label: isAr ? 'اسم المستلم' : 'Receiver Name',
                hint: isAr ? 'الاسم بالكامل' : 'Full Name',
              ),
              const SizedBox(height: AppDimens.space12),
              MashwarTextField(
                controller: _receiverPhoneController,
                label: isAr ? 'رقم موبايل المستلم' : 'Receiver Phone',
                hint: '01XXXXXXXXX',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppDimens.space20),

              // Prohibited items banner + Checkbox
              Container(
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
              ),

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
}
