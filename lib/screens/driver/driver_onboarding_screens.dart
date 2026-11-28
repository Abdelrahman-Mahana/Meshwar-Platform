import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../safety/safety_screens.dart';
import 'publish_ride_screen.dart';

// Page 37: اربح من مقاعدك الشاغرة (Driver Onboarding Landing)
class DriverOnboardingScreen extends StatelessWidget {
  const DriverOnboardingScreen({super.key});

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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.space16,
                      ),
                      child: MashwarFadeSlideIn(
                        duration: const Duration(milliseconds: 260),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                children: [
                                  MashwarAssetArt(
                                    assetPath:
                                        'assets/images/hero_qatar_services.jpg',
                                    width: double.infinity,
                                    height: 165,
                                    borderRadius: BorderRadius.circular(18),
                                    fallbackIcon: Icons.handshake_rounded,
                                    fallbackBg: AppColors.cobaltSurface,
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            AppColors.navy
                                                .withValues(alpha: 0.55),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimens.space20),

                            Text(
                              isAr
                                  ? 'اربح من طريقك ومقاعدك وخدماتك اليومية'
                                  : 'Earn from routes, errands & empty seats',
                              textAlign: TextAlign.center,
                              style: AppTypography.largeTitle(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'نفّذ طلبات الشراء بالفاتورة، توريد مواقع العمل، توصيل الطرود أو شارك مقاعدك بتسوية مباشرة وموثّقة بـ OTP.'
                                  : 'Fulfill shopping errands, worksite supplies, daily commutes or empty seats with direct OTP-verified settlement.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySecondary(),
                            ),
                            const SizedBox(height: AppDimens.space20),

                            Container(
                              padding: const EdgeInsets.all(AppDimens.space20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusCard,
                                ),
                                border: Border.all(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildStepRow(
                                    '1',
                                    isAr
                                        ? 'وثّق بطاقتك القطرية QID ورخصتك'
                                        : 'Verify Qatar ID & Driver License',
                                  ),
                                  const Divider(
                                    height: 24,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildStepRow(
                                    '2',
                                    isAr
                                        ? 'فعّل استقبال الطلبات أو انشر خط سيرك'
                                        : 'Accept service requests or post your route',
                                  ),
                                  const Divider(
                                    height: 24,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildStepRow(
                                    '3',
                                    isAr
                                        ? 'نفّذ الخدمة واستلم أتعابك مباشرة فور مطابقة كود OTP'
                                        : 'Fulfill safely & settle directly upon OTP confirmation',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            Text(
                              isAr
                                  ? 'تستغرق المراجعة حتى 24 ساعة.'
                                  : 'Verification review takes up to 24 hours.',
                              textAlign: TextAlign.center,
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),

                  MashwarButton(
                    key: const ValueKey('driver_onboarding_start_btn'),
                    text: isAr ? 'ابدأ التوثيق' : 'Start Verification',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DriverVerificationStepsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isAr ? 'ليس الآن' : 'Not now',
                      style: AppTypography.bodySecondary(color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.cobaltSurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// Page 38: قائمة الخطوات: توثيق السائق (Driver Verification 5 Steps)
class DriverVerificationStepsScreen extends StatefulWidget {
  const DriverVerificationStepsScreen({super.key});

  @override
  State<DriverVerificationStepsScreen> createState() =>
      _DriverVerificationStepsScreenState();
}

class _DriverVerificationStepsScreenState
    extends State<DriverVerificationStepsScreen> {
  int _completedSteps = 2;
  bool _isCameraMode = false;
  bool _isReady = false;

  void _triggerCapture() {
    setState(() => _isCameraMode = true);
  }

  void _confirmCapture() {
    setState(() {
      _isCameraMode = false;
      _completedSteps = 5;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    if (_isCameraMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => setState(() => _isCameraMode = false),
                ),
                title: Text(
                  isAr ? 'رخصة السيارة' : 'Vehicle License',
                  style: AppTypography.title(color: Colors.white),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        isAr
                            ? 'صوّر وجه الرخصة داخل الإطار'
                            : 'Fit document inside frame',
                        style: AppTypography.bodySecondary(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAr
                      ? 'تأكد من وضوح الصورة وتجنب الانعكاسات'
                      : 'Ensure clear lighting without glare',
                  style: AppTypography.label(color: Colors.white70),
                ),
              ),
              const Spacer(),
              GestureDetector(
                key: const ValueKey('driver_verif_shutter_btn'),
                onTap: _confirmCapture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'توثيق السائق' : 'Driver Verification',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isAr
                                        ? '$_completedSteps من 5 خطوات'
                                        : '$_completedSteps of 5 steps completed',
                                    style: AppTypography.title()
                                        .copyWith(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isReady)
                                  MashwarBadge(
                                    type: BadgeType.verified,
                                    customLabel: isAr ? 'جاهز للإرسال' : 'Ready',
                                  )
                                else
                                  MashwarBadge(
                                    type: BadgeType.pending,
                                    customLabel:
                                        isAr ? 'مطلوب إكمال' : 'In Progress',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAr
                                  ? 'سنراجع بياناتك خلال 24 ساعة بعد الإرسال'
                                  : 'We review your documents within 24 hours',
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppDimens.space20),

                            Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusCard,
                                ),
                                side: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  _buildStepTile(
                                    isAr
                                        ? 'البطاقة الشخصية القطرية (QID)'
                                        : 'Qatar ID (QID)',
                                    isDone: true,
                                    isAr: isAr,
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildStepTile(
                                    isAr ? 'رخصة القيادة' : 'Driving License',
                                    isDone: true,
                                    isAr: isAr,
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildStepTile(
                                    isAr ? 'رخصة السيارة' : 'Car License',
                                    isDone: _completedSteps >= 3,
                                    isAr: isAr,
                                    onTap: _triggerCapture,
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildStepTile(
                                    isAr
                                        ? 'صور ومواصفات السيارة'
                                        : 'Car Photos & Specs',
                                    isDone: _completedSteps >= 4,
                                    isAr: isAr,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const DriverCarDetailsScreen(),
                                        ),
                                      );
                                      if (mounted && _completedSteps < 4) {
                                        setState(() => _completedSteps = 4);
                                      }
                                    },
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildStepTile(
                                    isAr
                                        ? 'سيلفي للتحقق'
                                        : 'Verification Selfie',
                                    isDone: _completedSteps >= 5,
                                    isAr: isAr,
                                    onTap: _triggerCapture,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    if (_isReady) ...[
                      MashwarButton(
                        key: const ValueKey('driver_verif_submit_btn'),
                        text: isAr ? 'إرسال للمراجعة' : 'Submit for Review',
                        onPressed: () {
                          final auth = Provider.of<AuthProvider?>(
                            context,
                            listen: false,
                          );
                          if (auth != null) {
                            final currentOcc =
                                auth.user.occupation?.trim() ?? '';
                            if (!currentOcc.contains('كابتن') &&
                                !currentOcc.contains('Driver')) {
                              auth.updateProfile(
                                occupation: currentOcc.isNotEmpty
                                    ? '$currentOcc · سائق قيد المراجعة'
                                    : (isAr
                                        ? 'سائق قيد المراجعة'
                                        : 'Driver Under Review'),
                              );
                            }
                          }
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const DriverStatusScreen(
                                statusType: DriverStatusType.underReview,
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      MashwarButton(
                        key: const ValueKey('driver_verif_continue_btn'),
                        text: isAr
                            ? 'كمّل: رخصة السيارة'
                            : 'Continue: Car License',
                        onPressed: _triggerCapture,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTile(
    String title, {
    required bool isDone,
    required bool isAr,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        isDone
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isDone ? AppColors.teal : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarBadge(
            type: isDone ? BadgeType.verified : BadgeType.pending,
            customLabel:
                isDone ? (isAr ? 'تم' : 'Done') : (isAr ? 'مطلوب' : 'Required'),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// Page 39: بيانات السيارة (Car Details Specifications)
class DriverCarDetailsScreen extends StatefulWidget {
  const DriverCarDetailsScreen({super.key});

  @override
  State<DriverCarDetailsScreen> createState() => _DriverCarDetailsScreenState();
}

class _DriverCarDetailsScreenState extends State<DriverCarDetailsScreen> {
  static const String _otherModelKey = 'other_model';
  static const String _otherColorKey = 'other_color';

  static const List<(String key, String ar, String en)> _modelPresets = [
    ('تويوتا كامري 2024', 'تويوتا كامري 2024', 'Toyota Camry 2024'),
    ('تويوتا لاندكروزر', 'تويوتا لاندكروزر', 'Toyota Land Cruiser'),
    ('نيسان باترول', 'نيسان باترول', 'Nissan Patrol'),
    (_otherModelKey, 'أخرى (طراز مخصص)', 'Other (Custom Model)'),
  ];

  static const List<(String key, String ar, String en)> _colorPresets = [
    ('أبيض لؤلؤي', 'أبيض لؤلؤي', 'Pearl White'),
    ('فضي', 'فضي', 'Silver'),
    ('أسود', 'أسود', 'Black'),
    (_otherColorKey, 'أخرى (لون مخصص)', 'Other (Custom Color)'),
  ];

  final TextEditingController _modelController =
      TextEditingController(text: 'تويوتا كامري 2024');
  final TextEditingController _colorController =
      TextEditingController(text: 'أبيض لؤلؤي');
  final TextEditingController _plateController =
      TextEditingController(text: 'قطر 482910');

  String _selectedModelPreset = 'تويوتا كامري 2024';
  String _selectedColorPreset = 'أبيض لؤلؤي';
  int _seatsCount = 3;
  String? _plateError;
  String? _modelError;

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _save(bool isAr) {
    final model = _modelController.text.trim();
    final color = _colorController.text.trim();
    final plate = _plateController.text.trim();

    if (model.length < 2 || color.length < 2) {
      setState(() {
        _modelError = isAr
            ? 'أدخل الطراز واللون بشكل صحيح'
            : 'Enter valid model and color';
      });
      return;
    }
    if (plate.length < 4) {
      setState(() {
        _modelError = null;
        _plateError = isAr ? 'رقم اللوحة غير صحيح' : 'Invalid plate number';
      });
      return;
    }

    setState(() {
      _modelError = null;
      _plateError = null;
    });

    final summary = '$model · $color · $plate · $_seatsCount مقاعد';
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    auth?.updateProfile(
      tripVibe: summary,
      occupation: '$model ($plate)',
    );

    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(milliseconds: 120));
        await prefs.setString('mashwar_vehicle_model', model);
        await prefs.setString('mashwar_vehicle_color', color);
        await prefs.setInt('mashwar_vehicle_seats', _seatsCount);
      } catch (_) {}
    }());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم حفظ بيانات السيارة بنجاح' : 'Car specifications saved',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
    Navigator.of(context).pop(summary);
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'بيانات السيارة' : 'Car Specifications',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusCard,
                        ),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isAr ? 'النوع والموديل' : 'Make & Model',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _modelPresets.map((preset) {
                              final isOther = preset.$1 == _otherModelKey;
                              return MashwarChip(
                                key: isOther
                                    ? const ValueKey(
                                        'driver_car_model_other_chip',
                                      )
                                    : null,
                                label: isAr ? preset.$2 : preset.$3,
                                isSelected: _selectedModelPreset == preset.$1,
                                onTap: () {
                                  setState(() {
                                    _selectedModelPreset = preset.$1;
                                    if (isOther) {
                                      _modelController.clear();
                                    } else {
                                      _modelController.text = preset.$1;
                                    }
                                    _modelError = null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            key: const ValueKey('driver_car_model_input'),
                            controller: _modelController,
                            style: AppTypography.body(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.slateBg,
                              hintText: isAr
                                  ? 'أدخل الطراز وسنة الصنع'
                                  : 'Enter make, model & year',
                              errorText: _modelError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.space16),

                          Text(
                            isAr ? 'اللون' : 'Color',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _colorPresets.map((preset) {
                              final isOther = preset.$1 == _otherColorKey;
                              return MashwarChip(
                                key: isOther
                                    ? const ValueKey(
                                        'driver_car_color_other_chip',
                                      )
                                    : null,
                                label: isAr ? preset.$2 : preset.$3,
                                isSelected: _selectedColorPreset == preset.$1,
                                onTap: () {
                                  setState(() {
                                    _selectedColorPreset = preset.$1;
                                    if (isOther) {
                                      _colorController.clear();
                                    } else {
                                      _colorController.text = preset.$1;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            key: const ValueKey('driver_car_color_input'),
                            controller: _colorController,
                            style: AppTypography.body(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.slateBg,
                              hintText: isAr
                                  ? 'أدخل لون المركبة'
                                  : 'Enter vehicle color',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.space16),

                          Text(
                            isAr ? 'رقم اللوحة' : 'License Plate',
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const ValueKey('driver_car_plate_input'),
                            controller: _plateController,
                            style: AppTypography.body(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.slateBg,
                              errorText: _plateError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.slateBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusCard,
                        ),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? 'عدد المقاعد للركاب' : 'Passenger Seats',
                              style: AppTypography.body(),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _seatsCount > 1
                                    ? () => setState(() => _seatsCount--)
                                    : null,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                '$_seatsCount',
                                style: AppTypography.title(),
                              ),
                              IconButton(
                                onPressed: _seatsCount < 6
                                    ? () => setState(() => _seatsCount++)
                                    : null,
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'بدون مقعد السائق.'
                          : 'Excluding driver seat.',
                      style: AppTypography.label(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    MashwarButton(
                      key: const ValueKey('driver_car_save_btn'),
                      text: isAr ? 'حفظ' : 'Save',
                      onPressed: () => _save(isAr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Page 40: 5 حالات لحساب السائق (Driver Verification Status Variants)
enum DriverStatusType {
  underReview,
  approved,
  rejected,
  suspended,
  expired,
}

class DriverStatusScreen extends StatelessWidget {
  final DriverStatusType statusType;
  const DriverStatusScreen({
    super.key,
    this.statusType = DriverStatusType.approved,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;
    Color bgColor;
    String? reason;
    String primaryBtnText;
    VoidCallback onPrimary;

    switch (statusType) {
      case DriverStatusType.underReview:
        title = isAr ? 'نراجع بياناتك حالياً' : 'Reviewing your data';
        subtitle = isAr
            ? 'تكتمل المراجعة خلال 24 ساعة، وسنبلّغك بالنتيجة.'
            : 'Completed within 24 hours, you will receive an alert.';
        icon = Icons.hourglass_top_rounded;
        iconColor = AppColors.navy;
        bgColor = AppColors.cobaltSurface;
        primaryBtnText = isAr ? 'حسناً' : 'Got it';
        onPrimary = () => Navigator.of(context).pop();
        break;
      case DriverStatusType.approved:
        title = isAr ? 'تم توثيقك بنجاح' : 'You are Verified!';
        subtitle = isAr
            ? 'يمكنك الآن نشر رحلاتك واستقبال الركاب والطرود.'
            : 'You can publish rides and accept passengers now.';
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.teal;
        bgColor = AppColors.tealSurface;
        primaryBtnText = isAr ? 'انشر أول رحلة' : 'Publish First Ride';
        onPrimary = () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PublishRideScreen()),
          );
        };
        break;
      case DriverStatusType.rejected:
        title = isAr
            ? 'لم نتمكن من توثيق حسابك'
            : 'Could not verify account';
        subtitle = isAr
            ? 'عدّل البيانات وأعد الإرسال.'
            : 'Please update your documents and resubmit.';
        reason = isAr
            ? 'السبب: صورة الرخصة غير واضحة'
            : 'Reason: Driving license photo was blurry';
        icon = Icons.cancel_rounded;
        iconColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        primaryBtnText = isAr ? 'عدّل وأعد الإرسال' : 'Edit & Resubmit';
        onPrimary = () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DriverVerificationStepsScreen(),
            ),
          );
        };
        break;
      case DriverStatusType.suspended:
        title = isAr ? 'حسابك موقوف مؤقتاً' : 'Account Temporarily Suspended';
        subtitle = isAr
            ? 'يراجعها فريق الدعم لحل البلاغات.'
            : 'Our safety team is currently investigating open reports.';
        reason = isAr
            ? 'السبب: بلاغات قيد المراجعة'
            : 'Reason: Open reports under review';
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        primaryBtnText = isAr ? 'تواصل مع الدعم' : 'Contact Support';
        onPrimary = () async {
          final messenger = ScaffoldMessenger.maybeOf(context);
          final uri = Uri(scheme: 'tel', path: '+97444009999');
          final ok = await launchMashwarExternalUri(uri);
          if (!ok) {
            messenger?.showSnackBar(
              SnackBar(
                content: Text(
                  isAr
                      ? 'تواصل مع دعم مشوار على +974 4400 9999'
                      : 'Contact MASHWAR support at +974 4400 9999',
                ),
                backgroundColor: AppColors.navy,
              ),
            );
          }
        };
        break;
      case DriverStatusType.expired:
        title = isAr ? 'انتهت صلاحية رخصتك' : 'License Expired';
        subtitle = isAr
            ? 'ارفع رخصة سارية لتتمكن من نشر الرحلات.'
            : 'Please upload a renewed valid license to continue offering rides.';
        reason = isAr
            ? 'انتهت في: 1 أكتوبر 2026'
            : 'Expired on: Oct 1, 2026';
        icon = Icons.event_busy_rounded;
        iconColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        primaryBtnText = isAr ? 'ارفع الرخصة' : 'Upload License';
        onPrimary = () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DriverVerificationStepsScreen(),
            ),
          );
        };
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(0.0, 2000.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.space24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: MashwarFadeSlideIn(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: iconColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(icon, color: iconColor, size: 40),
                            ),
                          ),
                          const SizedBox(height: AppDimens.space20),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTypography.largeTitle(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySecondary(),
                          ),
                          if (reason != null) ...[
                            const SizedBox(height: AppDimens.space16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                reason,
                                textAlign: TextAlign.center,
                                style: AppTypography.label(
                                  color: AppColors.danger,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppDimens.space24),
                          MashwarButton(
                            text: primaryBtnText,
                            onPressed: onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
