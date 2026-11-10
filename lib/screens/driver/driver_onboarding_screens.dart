import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/settings_provider.dart';
import 'publish_ride_screen.dart';

// Page 37: اكسب من كراسيك الفاضية (Driver Onboarding Landing)
class DriverOnboardingScreen extends StatelessWidget {
  const DriverOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Icon Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.goldSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.navy, size: 40),
                ),
              ),
              const SizedBox(height: AppDimens.space20),

              // Title & Subtitle (Page 37)
              Text(
                isAr ? 'اكسب من كراسيك الفاضية' : 'Earn from your empty seats',
                textAlign: TextAlign.center,
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'انشر رحلاتك بين المحافظات وخد ركاب وطرود في طريقك.'
                    : 'Publish intercity trips and take riders and parcels along your way.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: AppDimens.space32),

              // 3 Steps Card (Page 37)
              Container(
                padding: const EdgeInsets.all(AppDimens.space20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  children: [
                    _buildStepRow('1', isAr ? 'وثّق هويتك ورخصتك' : 'Verify ID & Driver License'),
                    const Divider(height: 24, color: AppColors.sand),
                    _buildStepRow('2', isAr ? 'انشر رحلتك وحدد سعرك' : 'Post trip & set price'),
                    const Divider(height: 24, color: AppColors.sand),
                    _buildStepRow('3', isAr ? 'استقبل الحجوزات والطرود' : 'Accept bookings & parcels'),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                isAr ? 'المراجعة بتاخد لحد 24 ساعة.' : 'Verification review takes up to 24 hours.',
                textAlign: TextAlign.center,
                style: AppTypography.label(color: AppColors.textSecondary),
              ),

              const Spacer(flex: 2),

              // CTA Buttons (Page 37)
              MashwarButton(
                text: isAr ? 'ابدأ التوثيق' : 'Start Verification',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DriverVerificationStepsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isAr ? 'مش دلوقتي' : 'Not now',
                  style: AppTypography.bodySecondary(color: AppColors.navy),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
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
            color: AppColors.sand,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: AppTypography.body().copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// Page 38: قائمة الخطوات: توثيق السائق (Driver Verification 5 Steps)
class DriverVerificationStepsScreen extends StatefulWidget {
  const DriverVerificationStepsScreen({super.key});

  @override
  State<DriverVerificationStepsScreen> createState() => _DriverVerificationStepsScreenState();
}

class _DriverVerificationStepsScreenState extends State<DriverVerificationStepsScreen> {
  int _completedSteps = 2; // e.g. 2 of 5 completed
  bool _isCameraMode = false;
  bool _isUploading = false;
  bool _isReady = false;

  void _triggerCapture() async {
    setState(() => _isCameraMode = true);
  }

  void _confirmCapture() async {
    setState(() {
      _isCameraMode = false;
      _isUploading = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _completedSteps = 5;
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

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
                title: Text(isAr ? 'رخصة السيارة' : 'Vehicle License', style: const TextStyle(color: Colors.white)),
              ),
              const Spacer(),
              // Camera target frame (Page 38)
              Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isAr ? 'صوّر وجه الرخصة داخل الإطار' : 'Fit document inside frame',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isAr ? 'تأكد من وضوح الصورة وتجنب الانعكاسات' : 'Ensure clear lighting without glare',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const Spacer(),
              // Shutter button (Page 38)
              GestureDetector(
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

    if (_isUploading) {
      return Scaffold(
        backgroundColor: AppColors.sand,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space32),
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.teal),
                const SizedBox(height: AppDimens.space20),
                Text(isAr ? 'جاري رفع الصورة' : 'Uploading Document...', style: AppTypography.title()),
                const SizedBox(height: 6),
                Text(isAr ? '65% · لا تقفل الشاشة' : '65% · Please keep app open', style: AppTypography.label(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isUploading = false),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'توثيق السائق' : 'Driver Verification', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress subtitle (Page 38)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? '$_completedSteps من 5 خطوات' : '$_completedSteps of 5 steps completed',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  if (_isReady)
                    MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'جاهز للإرسال' : 'Ready')
                  else
                    MashwarBadge(type: BadgeType.pending, customLabel: isAr ? 'مطلوب إكمال' : 'In Progress'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isAr ? 'هنراجع بياناتك خلال 24 ساعة بعد الإرسال' : 'We review your documents within 24 hours',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.space20),

              // Steps List (Page 38)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  children: [
                    _buildStepTile(
                      isAr ? 'بطاقة الرقم القومي' : 'Egyptian National ID',
                      isDone: true,
                      isAr: isAr,
                    ),
                    const Divider(height: 1),
                    _buildStepTile(
                      isAr ? 'رخصة القيادة' : 'Driving License',
                      isDone: true,
                      isAr: isAr,
                    ),
                    const Divider(height: 1),
                    _buildStepTile(
                      isAr ? 'رخصة السيارة' : 'Car License',
                      isDone: _completedSteps >= 3,
                      isAr: isAr,
                      onTap: _triggerCapture,
                    ),
                    const Divider(height: 1),
                    _buildStepTile(
                      isAr ? 'صور السيارة' : 'Car Photos',
                      isDone: _completedSteps >= 4,
                      isAr: isAr,
                      onTap: _triggerCapture,
                    ),
                    const Divider(height: 1),
                    _buildStepTile(
                      isAr ? 'سيلفي للتحقق' : 'Verification Selfie',
                      isDone: _completedSteps >= 5,
                      isAr: isAr,
                      onTap: _triggerCapture,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Action (Page 38)
              if (_isReady) ...[
                MashwarButton(
                  text: isAr ? 'إرسال للمراجعة' : 'Submit for Review',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DriverStatusScreen(statusType: DriverStatusType.underReview)),
                    );
                  },
                ),
              ] else ...[
                MashwarButton(
                  text: isAr ? 'كمّل: رخصة السيارة' : 'Continue: Car License',
                  onPressed: _triggerCapture,
                ),
              ],
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTile(String title, {required bool isDone, required bool isAr, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: isDone ? AppColors.teal : AppColors.textSecondary,
      ),
      title: Text(title, style: AppTypography.body().copyWith(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarBadge(
            type: isDone ? BadgeType.verified : BadgeType.pending,
            customLabel: isDone ? (isAr ? 'تم' : 'Done') : (isAr ? 'مطلوب' : 'Required'),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
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
  final TextEditingController _modelController = TextEditingController(text: 'هيونداي إلنترا 2019');
  final TextEditingController _colorController = TextEditingController(text: 'أبيض');
  final TextEditingController _plateController = TextEditingController(text: 'أ ب ج 1234');
  int _seatsCount = 3;
  String? _plateError;

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _save(bool isAr) {
    final plate = _plateController.text.trim();
    if (plate.length < 5) {
      setState(() {
        _plateError = isAr ? 'رقم اللوحة غير صحيح' : 'Invalid plate number';
      });
      return;
    }
    setState(() => _plateError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم حفظ بيانات السيارة بنجاح' : 'Car specifications saved'),
        backgroundColor: AppColors.teal,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'بيانات السيارة' : 'Car Specifications', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isAr ? 'النوع والموديل' : 'Make & Model', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              Text(isAr ? 'اللون' : 'Color', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _colorController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              Text(isAr ? 'رقم اللوحة' : 'License Plate', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _plateController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _plateError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: AppDimens.space20),

              // Seats Counter (Page 39)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'عدد الكراسي للركاب' : 'Passenger Seats', style: AppTypography.body()),
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
              ),
              const SizedBox(height: 6),
              Text(
                isAr ? 'من غير السائق. الحد الأقصى 4 كراسي.' : 'Excluding driver. Maximum 4 seats.',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),

              const Spacer(),
              MashwarButton(
                text: isAr ? 'حفظ' : 'Save',
                onPressed: () => _save(isAr),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 40: 5 حالات لحساب السائق (Driver Verification Status Variants)
enum DriverStatusType {
  underReview, // قيد المراجعة: بنراجع بياناتك
  approved,    // مقبول: تم توثيقك
  rejected,    // مرفوض: ما قدرناش نوثق حسابك
  suspended,   // موقوف: حسابك موقوف مؤقتاً
  expired,     // رخصة منتهية: رخصتك انتهت
}

class DriverStatusScreen extends StatelessWidget {
  final DriverStatusType statusType;
  const DriverStatusScreen({super.key, this.statusType = DriverStatusType.approved});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

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
        title = isAr ? 'بنراجع بياناتك' : 'Reviewing your data';
        subtitle = isAr ? 'بنخلص خلال 24 ساعة، وهنبلغك بالنتيجة.' : 'Completed within 24 hours, you will receive an alert.';
        icon = Icons.hourglass_top_rounded;
        iconColor = AppColors.navy;
        bgColor = AppColors.sand;
        primaryBtnText = isAr ? 'تمام' : 'Got it';
        onPrimary = () => Navigator.of(context).pop();
        break;
      case DriverStatusType.approved:
        title = isAr ? 'تم توثيقك' : 'You are Verified!';
        subtitle = isAr ? 'تقدر تنشر رحلاتك وتستقبل ركاب وطرود دلوقتي.' : 'You can publish rides and accept passengers now.';
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
        title = isAr ? 'ما قدرناش نوثّق حسابك' : 'Could not verify account';
        subtitle = isAr ? 'عدّل البيانات وأعد الإرسال.' : 'Please update your documents and resubmit.';
        reason = isAr ? 'السبب: صورة الرخصة مش واضحة' : 'Reason: Driving license photo was blurry';
        icon = Icons.cancel_rounded;
        iconColor = AppColors.coral;
        bgColor = AppColors.dangerBg;
        primaryBtnText = isAr ? 'عدّل وأعد الإرسال' : 'Edit & Resubmit';
        onPrimary = () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DriverVerificationStepsScreen()),
          );
        };
        break;
      case DriverStatusType.suspended:
        title = isAr ? 'حسابك موقوف مؤقتاً' : 'Account Temporarily Suspended';
        subtitle = isAr ? 'بيراجعها فريق الدعم لحل البلاغات.' : 'Our safety team is currently investigating open reports.';
        reason = isAr ? 'السبب: بلاغات متكررة من ركاب' : 'Reason: Multiple reports from passengers';
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.coral;
        bgColor = AppColors.dangerBg;
        primaryBtnText = isAr ? 'تواصل مع الدعم' : 'Contact Support';
        onPrimary = () => Navigator.of(context).pop();
        break;
      case DriverStatusType.expired:
        title = isAr ? 'رخصتك انتهت' : 'License Expired';
        subtitle = isAr ? 'ارفع رخصة جديدة عشان تقدر تنشر رحلات.' : 'Please upload a renewed valid license to continue offering rides.';
        reason = isAr ? 'انتهت في: 1 أكتوبر 2026' : 'Expired on: Oct 1, 2026';
        icon = Icons.event_busy_rounded;
        iconColor = AppColors.coral;
        bgColor = AppColors.dangerBg;
        primaryBtnText = isAr ? 'ارفع الرخصة' : 'Upload License';
        onPrimary = () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DriverVerificationStepsScreen()),
          );
        };
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 44),
                ),
              ),
              const SizedBox(height: AppDimens.space20),
              Text(title, textAlign: TextAlign.center, style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: AppTypography.bodySecondary()),

              if (reason != null) ...[
                const SizedBox(height: AppDimens.space20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDisabled),
                  ),
                  child: Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral, fontSize: 13),
                  ),
                ),
              ],

              const Spacer(flex: 2),
              MashwarButton(
                text: primaryBtnText,
                onPressed: onPrimary,
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}
