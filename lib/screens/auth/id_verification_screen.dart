import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../permissions/location_permission_screen.dart';

class IdVerificationScreen extends StatefulWidget {
  final bool isOnboarding;

  const IdVerificationScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  final TextEditingController _idController = TextEditingController(text: '29663401842');
  
  bool _hasFrontPhoto = true;
  bool _hasBackPhoto = true;
  bool _hasSelfie = true;
  bool _isSubmitting = false;
  String? _idError;
  String? _detectedBirthDate;
  String? _detectedGovNameAr;
  String? _detectedGovNameEn;

  @override
  void initState() {
    super.initState();
    _analyzeNationalId(_idController.text);
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  // Qatar Personal ID (QID) decoder: 11 digits
  // Digit 1: Century (2: 1900-1999, 3: 2000-2099)
  // Digits 2-3: Birth Year
  // Digits 4-6: ISO-3166 Nationality Code (634 Qatar, 818 Egypt, 682 Saudi Arabia, etc.)
  // Digits 7-11: Serial sequence
  void _analyzeNationalId(String id) {
    if (id.length != 11 || !RegExp(r'^[0-9]{11}$').hasMatch(id)) {
      setState(() {
        _detectedBirthDate = null;
        _detectedGovNameAr = null;
        _detectedGovNameEn = null;
      });
      return;
    }

    final centuryDigit = int.tryParse(id.substring(0, 1)) ?? 0;
    if (centuryDigit != 2 && centuryDigit != 3) {
      setState(() {
        _detectedBirthDate = null;
        _detectedGovNameAr = null;
        _detectedGovNameEn = null;
      });
      return;
    }

    final yearPrefix = centuryDigit == 2 ? '19' : '20';
    final year = '$yearPrefix${id.substring(1, 3)}';
    final countryCode = id.substring(3, 6);

    const Map<String, List<String>> nationalities = {
      '634': ['دولة قطر', 'Qatar'],
      '682': ['المملكة العربية السعودية', 'Saudi Arabia'],
      '784': ['الإمارات العربية المتحدة', 'UAE'],
      '414': ['دولة الكويت', 'Kuwait'],
      '512': ['سلطنة عُمان', 'Oman'],
      '048': ['مملكة البحرين', 'Bahrain'],
      '818': ['مصر', 'Egypt'],
      '400': ['الأردن', 'Jordan'],
      '422': ['لبنان', 'Lebanon'],
      '356': ['الهند', 'India'],
      '608': ['الفلبين', 'Philippines'],
      '586': ['باكستان', 'Pakistan'],
    };

    final nat = nationalities[countryCode] ?? ['مقيم في دولة قطر', 'Qatar Resident'];
    setState(() {
      _detectedBirthDate = year;
      _detectedGovNameAr = nat[0];
      _detectedGovNameEn = nat[1];
      _idError = null;
    });
  }

  void _handleSubmit() async {
    final isAr = context.read<SettingsProvider>().isArabic;
    final idText = _idController.text.trim();
    if (idText.length != 11 || !RegExp(r'^[23][0-9]{10}$').hasMatch(idText)) {
      setState(() {
        _idError = isAr
            ? 'يرجى إدخال الرقم الشخصي القطري (QID) المكون من 11 رقم ويبدأ بـ 2 أو 3'
            : 'Please enter a valid 11-digit Qatar ID (QID) starting with 2 or 3';
      });
      return;
    }

    if (!_hasFrontPhoto || !_hasBackPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى التقاط أو رفع صورة واضحة لوجه وظهر البطاقة الشخصية'
                : 'Please take or upload clear photos of the front and back of your ID card',
          ),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() {
      _idError = null;
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      final auth = context.read<AuthProvider>();
      auth.submitIdVerification(
        nationalId: idText,
        frontPhoto: 'front_id_scanned.jpg',
        backPhoto: 'back_id_scanned.jpg',
        selfiePhoto: _hasSelfie ? 'selfie_scanned.jpg' : null,
      );

      setState(() {
        _isSubmitting = false;
      });

      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final isArabic = context.read<SettingsProvider>().isArabic;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.tealSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? 'تم إرسال وثائق الهوية' : 'ID Submitted',
                style: AppTypography.title(),
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'تم استلام البطاقة الشخصية القطرية (QID) بنجاح، وتتم مراجعة البيانات بواسطة فريق الأمان في مشوار خلال 24 ساعة. يمكنك استخدام التطبيق الآن!'
              : 'Your Qatar ID (QID) documents have been submitted. Our safety team will review them within 24 hours. You can start exploring MASHWAR now!',
          style: AppTypography.bodySecondary(),
        ),
        actions: [
          MashwarButton(
            text: isArabic ? 'متابعة إلى مشوار' : 'Continue to MASHWAR',
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.isOnboarding) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final user = auth.user;

    final isAlreadyVerified = user.idVerificationStatus == IdVerificationStatus.verified;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'توثيق البطاقة الشخصية القطرية (QID)' : 'Qatar ID (QID) Verification',
          style: AppTypography.title(),
        ),
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 12),
              child: MashwarFadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security status card
                    MashwarSectionCard(
                      backgroundColor: isAlreadyVerified ? const Color(0xFFF0FDF4) : Colors.white,
                      borderColor: isAlreadyVerified ? const Color(0xFFBBF7D0) : const Color(0xFFE5E5EA),
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAlreadyVerified ? AppColors.teal : const Color(0xFFF3F3F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAlreadyVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                        color: isAlreadyVerified ? Colors.white : AppColors.navy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAlreadyVerified
                                ? (isAr ? 'حساب موثق بالبطاقة القطرية' : 'QID Verified Account')
                                : (isAr ? 'توثيق الهوية إلزامي للأمان' : 'Mandatory Safety ID Verification'),
                            style: AppTypography.title(
                              color: isAlreadyVerified ? const Color(0xFF15803D) : AppColors.navy,
                            ).copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isAlreadyVerified
                                ? (isAr ? 'تم التحقق من بياناتك وبطاقتك القطرية ومطابقتها.' : 'Your Qatar ID has been verified.')
                                : (isAr
                                    ? 'لحماية الركاب والطرود، يجب على جميع المشتركين رفع البطاقة الشخصية القطرية (QID).'
                                    : 'To protect riders and parcels, all users must verify their Qatar ID (QID).'),
                            style: AppTypography.bodySecondary().copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // 11-digit Qatar Personal ID (QID) Input
              Text(
                isAr ? 'الرقم الشخصي القطري - QID (11 رقم)' : 'Qatar Personal ID - QID (11 digits)',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: _analyzeNationalId,
                style: AppTypography.body().copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
                decoration: InputDecoration(
                  hintText: '29663401842',
                  filled: true,
                  fillColor: const Color(0xFFF3F3F4),
                  counterText: '',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.navy, size: 20),
                  errorText: _idError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                  ),
                ),
              ),

              if (_detectedBirthDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.navy, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'سنة الميلاد: $_detectedBirthDate · الجنسية: $_detectedGovNameAr'
                              : 'Birth Year: $_detectedBirthDate · Nationality: $_detectedGovNameEn',
                          style: AppTypography.label(color: AppColors.navy).copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimens.space24),

              // Upload Cards: Front and Back of Qatar ID
              Text(
                isAr ? 'صور البطاقة الشخصية القطرية (QID)' : 'Qatar ID (QID) Card Photos',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppDimens.space12),

              // Front of ID
              _buildDocumentCard(
                title: isAr ? 'وجه البطاقة الشخصية (QID)' : 'Front of Qatar ID',
                subtitle: isAr ? 'صورة واضحة بالاسم والصورة والرقم الشخصي' : 'Clear photo showing name, photo & QID number',
                hasPhoto: _hasFrontPhoto,
                icon: Icons.credit_card_rounded,
                onTap: () {
                  setState(() => _hasFrontPhoto = !_hasFrontPhoto);
                },
                isArabic: isAr,
              ),

              const SizedBox(height: AppDimens.space12),

              // Back of ID
              _buildDocumentCard(
                title: isAr ? 'ظهر البطاقة الشخصية' : 'Back of National ID',
                subtitle: isAr ? 'صورة واضحة لظهر البطاقة مع كود الباركود' : 'Clear photo showing barcode & details',
                hasPhoto: _hasBackPhoto,
                icon: Icons.qr_code_scanner_rounded,
                onTap: () {
                  setState(() => _hasBackPhoto = !_hasBackPhoto);
                },
                isArabic: isAr,
              ),

              const SizedBox(height: AppDimens.space12),

              // Selfie Check
              _buildDocumentCard(
                title: isAr ? 'صورة شخصية (سيلفي للتحقق)' : 'Verification Selfie',
                subtitle: isAr ? 'صورة سريعة للوجه لمطابقتها مع صورة البطاقة' : 'Quick selfie for facial matching against ID',
                hasPhoto: _hasSelfie,
                icon: Icons.face_rounded,
                onTap: () {
                  setState(() => _hasSelfie = !_hasSelfie);
                },
                isArabic: isAr,
              ),

              const SizedBox(height: AppDimens.space24),

              // Qatar Privacy Law Notice
              Container(
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.teal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'بياناتك مشفرة ومحمية بالكامل بموجب قانون حماية خصوصية البيانات الشخصية القطري رقم 13 لسنة 2016. لا يتم مشاركة بطاقتك مع أي طرف ثالث.'
                            : 'Your data is strictly encrypted and protected under Qatar Personal Data Privacy Protection Law No. 13 of 2016. Never shared with third parties.',
                        style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space32),

              // Submit Action
              MashwarButton(
                text: _isSubmitting
                    ? (isAr ? 'جاري التحقق والرفع...' : 'Submitting...')
                    : (isAr ? 'إرسال وثائق الهوية' : 'Submit ID Documents'),
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),

              if (widget.isOnboarding) ...[
                const SizedBox(height: AppDimens.space12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
                      );
                    },
                    child: Text(
                      isAr ? 'تخطي التوثيق الآن والإكمال لاحقاً' : 'Skip for now, complete later',
                      style: AppTypography.bodySecondary().copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required bool hasPhoto,
    required IconData icon,
    required VoidCallback onTap,
    required bool isArabic,
  }) {
    return MashwarSectionCard(
      backgroundColor: Colors.white,
      borderColor: hasPhoto ? const Color(0xFFBBF7D0) : const Color(0xFFE5E5EA),
      padding: const EdgeInsets.all(AppDimens.space12),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasPhoto ? const Color(0xFFF0FDF4) : const Color(0xFFF3F3F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasPhoto ? Icons.check_circle_rounded : icon,
              color: hasPhoto ? AppColors.teal : AppColors.navy,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body().copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (hasPhoto)
                      MashwarBadge(
                        type: BadgeType.verified,
                        customLabel: isArabic ? 'تم الرفع' : 'Uploaded',
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              hasPhoto ? Icons.refresh_rounded : Icons.camera_alt_outlined,
              color: AppColors.teal,
              size: 20,
            ),
            tooltip: hasPhoto
                ? (isArabic ? 'إعادة التقاط' : 'Retake')
                : (isArabic ? 'التقاط' : 'Capture'),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
