import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import 'email_input_screen.dart';
import 'otp_verification_screen.dart';

/// Market-leading, minimalist Phone Number input screen (Uber / inDrive standard).
/// Responsive layout:
/// - Wide / Desktop (>= 840px): 2-column split canvas (Left: Security & Trust showcase, Right: Phone entry card)
/// - Mobile (< 840px): Full-height balanced vertical distribution with Step Progress, Network tags & Security Guarantee
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '01012345678');
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _isFocused = false;

  static String normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
      result = result.replaceAll(easternDigits[i], '$i');
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(bool isAr) async {
    final phone = _phoneController.text.trim();
    final validationError = AuthProvider.validateEgyptianPhone(phone);
    if (validationError != null) {
      setState(() {
        _errorText = isAr ? validationError : 'Phone must be 11 digits starting with 010, 011, 012, or 015';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAr = context.isArabic;
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            if (isWide) {
              return _buildWideSplitLayout(context, auth, isAr, hasError, constraints);
            }
            return _buildMobileLayout(context, auth, isAr, hasError, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildWideSplitLayout(
    BuildContext context,
    AuthProvider auth,
    bool isAr,
    bool hasError,
    BoxConstraints constraints,
  ) {
    return Row(
      children: [
        // Left Showcase Panel
        Expanded(
          flex: 6,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, Color(0xFF14385A)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 80).clamp(0.0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandLogo(fontSize: 44, isLight: true),
                        const SizedBox(height: 18),
                        Text(
                          isAr ? 'سفر موثق وآمن برقم موبايلك' : 'Verified & Secure Intercity Travel',
                          style: AppTypography.title(color: Colors.white).copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'رقم هاتفك هو مفتاح أمانك لحجز المقاعد، تأكيد شحن الطرود، ومشاركة تفاصيل الرحلة.'
                              : 'Your phone number secures your ride bookings, parcel OTP delivery, and live trip tracking.',
                          style: AppTypography.body(color: Colors.white70).copyWith(fontSize: 15),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Security Highlights
                    Column(
                      children: [
                        _buildWideTrustCard(
                          icon: Icons.cell_tower_rounded,
                          title: isAr ? 'دعم كامل لشبكات مصر' : 'All Egyptian Networks Supported',
                          subtitle: isAr
                              ? 'فودافون، أورنج، اتصالات، وي. رسائل فورية خلال ثوانٍ معدودة.'
                              : 'Vodafone, Orange, Etisalat, WE. Instant SMS delivery.',
                        ),
                        const SizedBox(height: 14),
                        _buildWideTrustCard(
                          icon: Icons.shield_outlined,
                          title: isAr ? 'حماية تامة لخصوصيتك' : '100% Privacy Protected',
                          subtitle: isAr
                              ? 'لن نشارك رقمك للعامة، ويظهر فقط للطرف الآخر عند تأكيد الحجز.'
                              : 'Your number is never public. Shared only after confirmed bookings.',
                        ),
                        const SizedBox(height: 14),
                        _buildWideTrustCard(
                          icon: Icons.support_agent_rounded,
                          title: isAr ? 'دعم فني ومتابعة 24/7' : '24/7 Dedicated Support',
                          subtitle: isAr
                              ? 'فريق خدمة عملاء مشوار متواجد على مدار الساعة لخدمتك.'
                              : 'Our dedicated customer operations team is always active.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Metrics Strip
                    Row(
                      children: [
                        _buildShowcaseMetric('27', isAr ? 'محافظة' : 'Governorates'),
                        const SizedBox(width: 32),
                        _buildShowcaseMetric('100%', isAr ? 'توثيق' : 'Verified'),
                        const SizedBox(width: 32),
                        _buildShowcaseMetric('24/7', isAr ? 'دعم' : 'Support'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Phone Input Form Area
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64).clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Step Indicator Badge
                            _buildStepBadge(isAr: isAr, currentStep: 1, totalSteps: 2),
                            const SizedBox(height: 14),

                            // Title
                            Text(
                              isAr ? 'أدخل رقم موبايلك' : 'Enter your mobile number',
                              style: AppTypography.largeTitle().copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              isAr ? 'هنبعتلك كود تأكيد عبر رسالة SMS' : 'We will send you a verification code via SMS',
                              style: AppTypography.bodySecondary(),
                            ),
                            const SizedBox(height: 22),

                            // Input Label
                            Text(
                              isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
                              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),

                            // Phone input field card
                            _buildPhoneInputField(hasError: hasError, isAr: isAr),
                            const SizedBox(height: 10),

                            // Helper / Error
                            _buildHelperOrError(hasError: hasError, isAr: isAr),
                            const SizedBox(height: 16),

                            // Operator chips
                            _buildOperatorChips(isAr),
                            const SizedBox(height: 28),

                            // Submit Button
                            MashwarButton(
                              text: isAr ? 'إرسال الكود' : 'Send Code',
                              isLoading: auth.isLoading,
                              onPressed: () => _handleSubmit(isAr),
                            ),
                            const SizedBox(height: 14),

                            // Switch to email
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.navy),
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const EmailInputScreen()),
                                  );
                                },
                                label: Text(
                                  isAr ? 'المتابعة بالبريد الإلكتروني بدلاً من ذلك' : 'Continue with email instead',
                                  style: AppTypography.body(color: AppColors.navy).copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AuthProvider auth,
    bool isAr,
    bool hasError,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical: AppDimens.space16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - (AppDimens.space16 * 2)).clamp(0.0, double.infinity),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Step Progress Indicator
            _buildStepBadge(isAr: isAr, currentStep: 1, totalSteps: 2),
            const SizedBox(height: 16),

            // Title & Subtitle
            Text(
              isAr ? 'أدخل رقم موبايلك' : 'Enter your mobile number',
              style: AppTypography.largeTitle().copyWith(fontSize: 26),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? 'هنبعتلك كود تأكيد عبر رسالة SMS' : 'We will send you a verification code via SMS',
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 20),

            // Input Label
            Text(
              isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            // Phone Input Card
            _buildPhoneInputField(hasError: hasError, isAr: isAr),
            const SizedBox(height: 8),

            // Helper text / Error text
            _buildHelperOrError(hasError: hasError, isAr: isAr),
            const SizedBox(height: 14),

            // Egyptian Operator Chips
            _buildOperatorChips(isAr),
            const SizedBox(height: 20),

            // Trust & Security Reassurance Card (Fills middle naturally with useful value)
            _buildSecurityReassuranceCard(isAr),
            const SizedBox(height: 24),

            // Bottom Actions: Submit Button
            MashwarButton(
              text: isAr ? 'إرسال الكود' : 'Send Code',
              isLoading: auth.isLoading,
              onPressed: () => _handleSubmit(isAr),
            ),
            const SizedBox(height: 12),

            // Switch to Email
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.navy),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const EmailInputScreen()),
                  );
                },
                label: Text(
                  isAr ? 'المتابعة بالبريد الإلكتروني بدلاً من ذلك' : 'Continue with email instead',
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge({required bool isAr, required int currentStep, required int totalSteps}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isAr ? 'الخطوة $currentStep من $totalSteps' : 'Step $currentStep of $totalSteps',
            style: AppTypography.label(color: AppColors.navy).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5E5EA),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navy),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField({required bool hasError, required bool isAr}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.danger
              : (_isFocused ? AppColors.navy : const Color(0xFFE5E5EA)),
          width: hasError ? 1.4 : (_isFocused ? 1.8 : 0.8),
        ),
        boxShadow: _isFocused && !hasError
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Egyptian Flag & Country Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇪🇬', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '+20',
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            height: 22,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFE5E5EA),
          ),

          // Phone input field
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _phoneController,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '01XXXXXXXXX',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                ],
                onChanged: (val) {
                  final normalized = normalizeDigits(val);
                  if (normalized != val) {
                    _phoneController.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(offset: normalized.length),
                    );
                  }
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
            ),
          ),

          // Clear button
          if (_phoneController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 20),
              onPressed: () {
                setState(() {
                  _phoneController.clear();
                  _errorText = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHelperOrError({required bool hasError, required bool isAr}) {
    if (hasError) {
      return Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _errorText!,
              style: AppTypography.label(color: AppColors.danger).copyWith(fontSize: 12),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isAr
                ? 'رقم مصري يبدأ بـ 010 أو 011 أو 012 أو 015'
                : 'Egyptian phone starting with 010, 011, 012, or 015',
            style: AppTypography.label(color: const Color(0xFF64748B)).copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorChips(bool isAr) {
    final operators = isAr
        ? ['فودافون (010)', 'أورنج (012)', 'اتصالات (011)', 'وي (015)']
        : ['Vodafone (010)', 'Orange (012)', 'Etisalat (011)', 'WE (015)'];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: operators.map((op) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.6),
          ),
          child: Text(
            op,
            style: AppTypography.label(color: const Color(0xFF64748B)).copyWith(fontSize: 10),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSecurityReassuranceCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.shield_outlined, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                isAr ? 'ضمانات الأمان والخصوصية في مشوار' : 'Safety & Privacy Guarantees',
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildReassurancePoint(
            isAr
                ? 'كود التحقق مجاني ويصلك برسالة SMS فورية خلال ثوانٍ.'
                : 'Verification code is free and sent instantly via SMS.',
          ),
          const SizedBox(height: 4),
          _buildReassurancePoint(
            isAr
                ? 'رقمك محمي ولن يظهر للعامة، ويشارك فقط عند تأكيد الحجز.'
                : 'Your number is private and never shared publicly.',
          ),
          const SizedBox(height: 4),
          _buildReassurancePoint(
            isAr
                ? 'دعم فني مباشر ومتاح 24/7 لمساعدتك في أي وقت.'
                : '24/7 active customer support ready to assist you.',
          ),
        ],
      ),
    );
  }

  Widget _buildReassurancePoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.label(color: const Color(0xFF475569)).copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildWideTrustCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(color: Colors.white).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.label(color: Colors.white70).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.title(color: AppColors.gold).copyWith(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: AppTypography.label(color: Colors.white70),
        ),
      ],
    );
  }
}
