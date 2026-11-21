import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/settings_provider.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final TextEditingController _modelController = TextEditingController(text: 'هيونداي إلنترا 2022');
  final TextEditingController _colorController = TextEditingController(text: 'أبيض لؤلؤي');
  final TextEditingController _plateLettersController = TextEditingController(text: 'س ق ر');
  final TextEditingController _plateNumbersController = TextEditingController(text: '1942');
  
  int _seatsCount = 3;
  bool _hasAC = true;
  bool _largeTrunk = true;
  bool _drivingLicenseUploaded = true;
  bool _carLicenseUploaded = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _plateLettersController.dispose();
    _plateNumbersController.dispose();
    super.dispose();
  }

  void _saveVehicle() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isSaving = false);
      final isAr = context.read<SettingsProvider>().isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم حفظ بيانات المركبة والرخص بنجاح' : 'Vehicle and licenses saved successfully',
          ),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'بيانات سيارتي ورخص القيادة' : 'Vehicle & Driver Licenses',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: MashwarFadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Approval Badge
                    MashwarSectionCard(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 24),
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
                                        isAr ? 'مركبة معتمدة للرحلات' : 'Approved Vehicle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.title().copyWith(fontSize: 15),
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
                                  isAr ? 'سيارتك مفعلة ويمكنك عرض مقاعد أو توصيل طرود.' : 'Your vehicle is active for carpool & parcel delivery.',
                                  style: AppTypography.label(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: AppDimens.space24),

              // Car Details Section
              Text(
                isAr ? 'مواصفات المركبة' : 'Vehicle Specifications',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppDimens.space12),

              // Make & Model
              _buildInputTile(
                label: isAr ? 'الماركة والموديل وسنة الصنع' : 'Make, Model & Year',
                controller: _modelController,
                hint: 'مثال: تويوتا كورولا 2021',
              ),
              const SizedBox(height: AppDimens.space12),

              // Color
              _buildInputTile(
                label: isAr ? 'لون السيارة' : 'Color',
                controller: _colorController,
                hint: 'مثال: أبيض، فضي، أسود',
              ),
              const SizedBox(height: AppDimens.space16),

              // Egyptian License Plate Layout
              Text(
                isAr ? 'اللوحة المعدنية (الحروف والأرقام)' : 'Egyptian License Plate',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppDimens.space8),
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.navy, width: 2),
                ),
                child: Column(
                  children: [
                    // Top Egyptian Blue Band
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('EGYPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                          Text('مـصـر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _plateLettersController,
                            textAlign: TextAlign.center,
                            style: AppTypography.largeTitle().copyWith(fontSize: 22, letterSpacing: 6),
                            decoration: const InputDecoration(
                              hintText: 'س ق ر',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Container(width: 2, height: 40, color: AppColors.navy),
                        Expanded(
                          child: TextField(
                            controller: _plateNumbersController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: AppTypography.largeTitle().copyWith(fontSize: 22, letterSpacing: 4),
                            decoration: const InputDecoration(
                              hintText: '1942',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // Capacities & Features
              Text(
                isAr ? 'المقاعد والراحة' : 'Comfort & Capacity',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppDimens.space12),

              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isAr ? 'عدد المقاعد المتاحة للركاب' : 'Available Seats',
                            style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [2, 3, 4].map((count) {
                            final isSel = _seatsCount == count;
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(start: 6),
                              child: Material(
                                color: isSel ? AppColors.navy : AppColors.chipInactiveBg,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _seatsCount = count),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel ? AppColors.navy : AppColors.borderDisabled,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: AppTypography.body(
                                          color: isSel ? Colors.white : AppColors.navy,
                                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F1F4)),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.teal,
                      value: _hasAC,
                      onChanged: (val) => setState(() => _hasAC = val),
                      title: Text(isAr ? 'تكييف هواء يعمل بكفاءة' : 'Air Conditioning (A/C)', style: AppTypography.body()),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F1F4)),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.teal,
                      value: _largeTrunk,
                      onChanged: (val) => setState(() => _largeTrunk = val),
                      title: Text(isAr ? 'مساحة شنطة كافية للطرود والحقائب' : 'Large Trunk for Parcels & Luggage', style: AppTypography.body()),
                    ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // Licenses Upload
              Text(
                isAr ? 'الرخص الرسمية' : 'Official Licenses',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppDimens.space12),

              _buildLicenseTile(
                title: isAr ? 'رخصة القيادة سارية' : 'Valid Driving License',
                isUploaded: _drivingLicenseUploaded,
                onTap: () => setState(() => _drivingLicenseUploaded = !_drivingLicenseUploaded),
                isAr: isAr,
              ),
              const SizedBox(height: AppDimens.space12),
              _buildLicenseTile(
                title: isAr ? 'رخصة تسيير المركبة' : 'Vehicle Registration License',
                isUploaded: _carLicenseUploaded,
                onTap: () => setState(() => _carLicenseUploaded = !_carLicenseUploaded),
                isAr: isAr,
              ),

              const SizedBox(height: AppDimens.space32),

              // Save Action
              MashwarButton(
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
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F3F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
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
    return MashwarSectionCard(
      padding: const EdgeInsets.all(AppDimens.space16),
      borderRadius: 12,
      borderColor: isUploaded ? AppColors.teal.withValues(alpha: 0.35) : const Color(0xFFE5E5EA),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFF3F3F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUploaded ? Icons.verified_rounded : Icons.file_upload_outlined,
              color: isUploaded ? AppColors.teal : AppColors.navy,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          MashwarBadge(
            type: isUploaded ? BadgeType.verified : BadgeType.pending,
            customLabel: isUploaded ? (isAr ? 'موثقة' : 'Verified') : (isAr ? 'مطلوب الرفع' : 'Required'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal, size: 20),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
