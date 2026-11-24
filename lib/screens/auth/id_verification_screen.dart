import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/models/user_model.dart';
import '../../data/services/media_upload_service.dart';
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
  late final TextEditingController _idController;

  MediaUploadResult? _frontUpload;
  MediaUploadResult? _backUpload;
  MediaUploadResult? _selfieUpload;
  String? _uploadingDocSlot;
  String? _uploadError;

  bool _isSubmitting = false;
  String? _idError;
  String? _detectedBirthDate;
  String? _detectedGovNameAr;
  String? _detectedGovNameEn;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider?>();
    final existingQid = auth?.user.nationalId ?? '';
    _idController = TextEditingController(text: existingQid);
    if (existingQid.isNotEmpty) {
      _analyzeNationalId(existingQid);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

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

    final nat =
        nationalities[countryCode] ?? ['مقيم في دولة قطر', 'Qatar Resident'];
    setState(() {
      _detectedBirthDate = year;
      _detectedGovNameAr = nat[0];
      _detectedGovNameEn = nat[1];
      _idError = null;
    });
  }

  Future<void> _handleUploadDoc(String docType, bool isAr) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user.id.trim().isNotEmpty ? auth.user.id.trim() : 'pending_user';

    setState(() {
      _uploadingDocSlot = docType;
      _uploadError = null;
    });

    try {
      final res =
          await MediaUploadService.instance.pickAndUploadProviderVerificationDoc(
        uid: uid,
        docType: docType,
        source: ImageSource.gallery,
        allowDevMocks: auth.isDevMockAuthEnabled,
      );
      if (!mounted) return;
      setState(() {
        _uploadingDocSlot = null;
        if (res != null) {
          if (docType == 'qid_front') {
            _frontUpload = res;
          } else if (docType == 'qid_back') {
            _backUpload = res;
          } else {
            _selfieUpload = res;
          }
        }
      });
    } on MediaUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingDocSlot = null;
        _uploadError = e.localizedMessage(isArabic: isAr);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingDocSlot = null;
        _uploadError = isAr
            ? 'تعذّر رفع صورة الهوية: $e'
            : 'Failed to upload ID image: $e';
      });
    }
  }

  Future<void> _handleSubmit() async {
    final isAr = context.read<SettingsProvider>().isArabic;
    final auth = context.read<AuthProvider>();
    final idText = _idController.text.trim();
    if (idText.length != 11 || !RegExp(r'^[23][0-9]{10}$').hasMatch(idText)) {
      setState(() {
        _idError = isAr
            ? 'يرجى إدخال الرقم الشخصي القطري (QID) المكون من 11 رقم ويبدأ بـ 2 أو 3'
            : 'Please enter a valid 11-digit Qatar ID (QID) starting with 2 or 3';
      });
      return;
    }

    final frontUrl = _frontUpload?.downloadUrl ?? auth.user.idFrontImage ?? '';
    final backUrl = _backUpload?.downloadUrl ?? auth.user.idBackImage ?? '';
    final selfieUrl = _selfieUpload?.downloadUrl ?? auth.user.selfieImage;

    if (frontUrl.isEmpty || backUrl.isEmpty) {
      setState(() {
        _uploadError = isAr
            ? 'يرجى رفع صورة واضحة لوجه وظهر البطاقة الشخصية القطرية (QID) قبل الإرسال.'
            : 'Please upload clear photos of the front and back of your Qatar ID (QID) before submitting.';
      });
      return;
    }

    setState(() {
      _idError = null;
      _uploadError = null;
      _isSubmitting = true;
    });

    final ok = await auth.submitIdVerification(
      nationalId: idText,
      frontPhoto: frontUrl,
      backPhoto: backUrl,
      selfiePhoto: selfieUrl,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (ok) {
      _showSuccessDialog();
    } else {
      setState(() {
        _uploadError = auth.localizedError(isArabic: isAr) ??
            (isAr
                ? 'تعذّر إرسال وثائق الهوية للمراجعة.'
                : 'Unable to submit ID verification documents.');
      });
    }
  }

  void _showSuccessDialog() {
    final isArabic = context.read<SettingsProvider>().isArabic;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.tealSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.teal, size: 28),
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
              ? 'تم رفع البطاقة الشخصية القطرية (QID) بنجاح، وتتم مراجعة البيانات بواسطة فريق الأمان في مشوار خلال 24 ساعة.'
              : 'Your Qatar ID (QID) documents have been uploaded and submitted for safety team review within 24 hours.',
          style: AppTypography.bodySecondary(),
        ),
        actions: [
          MashwarButton(
            text: isArabic ? 'متابعة إلى مشوار' : 'Continue to MASHWAR',
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.isOnboarding) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const LocationPermissionScreen()),
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

    final isAlreadyVerified =
        user.idVerificationStatus == IdVerificationStatus.verified;
    final hasFront =
        _frontUpload != null || (user.idFrontImage?.isNotEmpty ?? false);
    final hasBack =
        _backUpload != null || (user.idBackImage?.isNotEmpty ?? false);
    final hasSelfie =
        _selfieUpload != null || (user.selfieImage?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr
              ? 'توثيق البطاقة الشخصية القطرية (QID)'
              : 'Qatar ID (QID) Verification',
          style: AppTypography.title(),
        ),
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.navy),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16, vertical: 12),
              child: MashwarFadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MashwarSectionCard(
                      backgroundColor: isAlreadyVerified
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                      borderColor: isAlreadyVerified
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFE5E5EA),
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isAlreadyVerified
                                  ? AppColors.teal
                                  : const Color(0xFFF3F3F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isAlreadyVerified
                                  ? Icons.verified_user_rounded
                                  : Icons.shield_outlined,
                              color: isAlreadyVerified
                                  ? Colors.white
                                  : AppColors.navy,
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
                                      ? (isAr
                                          ? 'حساب موثق بالبطاقة القطرية'
                                          : 'QID Verified Account')
                                      : (isAr
                                          ? 'توثيق الهوية القطرية (QID)'
                                          : 'Qatar ID (QID) Identity Verification'),
                                  style: AppTypography.title(
                                    color: isAlreadyVerified
                                        ? const Color(0xFF15803D)
                                        : AppColors.navy,
                                  ).copyWith(fontSize: 15),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isAlreadyVerified
                                      ? (isAr
                                          ? 'تم التحقق من بياناتك وبطاقتك القطرية ومطابقتها.'
                                          : 'Your Qatar ID has been verified.')
                                      : (isAr
                                          ? 'ارفع صور البطاقة الشخصية القطرية (QID) بصيغة صورة صالحة (حتى 10 ميجابايت).'
                                          : 'Upload clear Qatar ID (QID) photos (valid image up to 10 MB).'),
                                  style: AppTypography.bodySecondary()
                                      .copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),
                    Text(
                      isAr
                          ? 'الرقم الشخصي القطري - QID (11 رقم)'
                          : 'Qatar Personal ID - QID (11 digits)',
                      style: AppTypography.label()
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const ValueKey('id_verif_qid_input'),
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
                        prefixIcon: const Icon(Icons.badge_outlined,
                            color: AppColors.navy, size: 20),
                        errorText: _idError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E5EA), width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E5EA), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.teal, width: 1.5),
                        ),
                      ),
                    ),
                    if (_detectedBirthDate != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFE5E5EA), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.navy, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'سنة الميلاد: $_detectedBirthDate · الجنسية: $_detectedGovNameAr'
                                    : 'Birth Year: $_detectedBirthDate · Nationality: $_detectedGovNameEn',
                                style: AppTypography.label(color: AppColors.navy)
                                    .copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.space24),
                    Text(
                      isAr
                          ? 'صور البطاقة الشخصية القطرية (QID)'
                          : 'Qatar ID (QID) Card Photos',
                      style: AppTypography.body()
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    if (_uploadError != null) ...[
                      Container(
                        key: const ValueKey('id_verif_upload_error'),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          _uploadError!,
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    _buildDocumentCard(
                      uploadBtnKey: 'id_verif_upload_qid_front_btn',
                      pillKey: 'id_verif_pill_qid_front',
                      title: isAr
                          ? 'وجه البطاقة الشخصية (QID)'
                          : 'Front of Qatar ID',
                      subtitle: isAr
                          ? 'صورة واضحة بالاسم والصورة والرقم الشخصي'
                          : 'Clear photo showing name, photo & QID number',
                      hasPhoto: hasFront,
                      isUploading: _uploadingDocSlot == 'qid_front',
                      uploadResult: _frontUpload,
                      icon: Icons.credit_card_rounded,
                      onTap: () => _handleUploadDoc('qid_front', isAr),
                      isArabic: isAr,
                    ),
                    const SizedBox(height: AppDimens.space12),
                    _buildDocumentCard(
                      uploadBtnKey: 'id_verif_upload_qid_back_btn',
                      pillKey: 'id_verif_pill_qid_back',
                      title:
                          isAr ? 'ظهر البطاقة الشخصية' : 'Back of National ID',
                      subtitle: isAr
                          ? 'صورة واضحة لظهر البطاقة مع كود الباركود'
                          : 'Clear photo showing barcode & details',
                      hasPhoto: hasBack,
                      isUploading: _uploadingDocSlot == 'qid_back',
                      uploadResult: _backUpload,
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => _handleUploadDoc('qid_back', isAr),
                      isArabic: isAr,
                    ),
                    const SizedBox(height: AppDimens.space12),
                    _buildDocumentCard(
                      uploadBtnKey: 'id_verif_upload_selfie_btn',
                      pillKey: 'id_verif_pill_selfie',
                      title: isAr
                          ? 'صورة شخصية (سيلفي للتحقق)'
                          : 'Verification Selfie',
                      subtitle: isAr
                          ? 'صورة سريعة للوجه لمطابقتها مع صورة البطاقة'
                          : 'Quick selfie for facial matching against ID',
                      hasPhoto: hasSelfie,
                      isUploading: _uploadingDocSlot == 'selfie',
                      uploadResult: _selfieUpload,
                      icon: Icons.face_rounded,
                      onTap: () => _handleUploadDoc('selfie', isAr),
                      isArabic: isAr,
                    ),
                    const SizedBox(height: AppDimens.space24),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE5E5EA), width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: AppColors.teal, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'بياناتك مشفرة ومحمية بالكامل بموجب قانون حماية خصوصية البيانات الشخصية القطري رقم 13 لسنة 2016. لا يتم مشاركة بطاقتك مع أي طرف ثالث.'
                                  : 'Your data is strictly encrypted and protected under Qatar Personal Data Privacy Protection Law No. 13 of 2016. Never shared with third parties.',
                              style:
                                  AppTypography.label(color: AppColors.textSecondary)
                                      .copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space32),
                    MashwarButton(
                      key: const ValueKey('id_verif_submit_btn'),
                      text: _isSubmitting
                          ? (isAr ? 'جاري التحقق والرفع...' : 'Submitting...')
                          : (isAr
                              ? 'إرسال وثائق الهوية'
                              : 'Submit ID Documents'),
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                    if (widget.isOnboarding) ...[
                      const SizedBox(height: AppDimens.space12),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const LocationPermissionScreen()),
                            );
                          },
                          child: Text(
                            isAr
                                ? 'تخطي التوثيق الآن والإكمال لاحقاً'
                                : 'Skip for now, complete later',
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
    required String uploadBtnKey,
    required String pillKey,
    required String title,
    required String subtitle,
    required bool hasPhoto,
    required bool isUploading,
    required MediaUploadResult? uploadResult,
    required IconData icon,
    required VoidCallback onTap,
    required bool isArabic,
  }) {
    return MashwarSectionCard(
      backgroundColor: Colors.white,
      borderColor: hasPhoto ? const Color(0xFFBBF7D0) : const Color(0xFFE5E5EA),
      padding: const EdgeInsets.all(AppDimens.space12),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasPhoto
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFF3F3F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: uploadResult != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          uploadResult.bytes,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.teal,
                            size: 22,
                          ),
                        ),
                      )
                    : Icon(
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
                            style: AppTypography.body().copyWith(
                                fontWeight: FontWeight.w700, fontSize: 14),
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
                    Text(
                      subtitle,
                      style: AppTypography.label(color: AppColors.textSecondary)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: ValueKey(uploadBtnKey),
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.teal,
                        ),
                      )
                    : Icon(
                        hasPhoto
                            ? Icons.refresh_rounded
                            : Icons.cloud_upload_outlined,
                        color: AppColors.teal,
                        size: 20,
                      ),
                tooltip: hasPhoto
                    ? (isArabic ? 'استبدال الصورة' : 'Replace image')
                    : (isArabic ? 'رفع صورة' : 'Upload image'),
                onPressed: _uploadingDocSlot != null ? null : onTap,
              ),
            ],
          ),
          if (uploadResult != null) ...[
            const SizedBox(height: 8),
            Container(
              key: ValueKey(pillKey),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${uploadResult.fileName} · ${uploadResult.formattedSize}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
