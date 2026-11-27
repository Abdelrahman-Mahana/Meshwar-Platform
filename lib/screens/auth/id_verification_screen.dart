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
  final TextEditingController _frontUrlFallbackController =
      TextEditingController();
  final TextEditingController _backUrlFallbackController =
      TextEditingController();
  final TextEditingController _selfieUrlFallbackController =
      TextEditingController();

  MediaUploadResult? _frontUpload;
  MediaUploadResult? _backUpload;
  MediaUploadResult? _selfieUpload;
  String? _uploadingDocSlot;
  String? _uploadError;
  bool _showUrlFallback = false;

  bool _isSubmitting = false;
  String? _idError;
  String? _detectedBirthDate;
  String? _detectedGovNameAr;
  String? _detectedGovNameEn;

  static String _normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
      result = result.replaceAll(easternDigits[i], '$i');
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool _isValidHttpsOrStorageUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

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
    _frontUrlFallbackController.dispose();
    _backUrlFallbackController.dispose();
    _selfieUrlFallbackController.dispose();
    super.dispose();
  }

  void _analyzeNationalId(String rawInput) {
    final id = _normalizeDigits(rawInput);
    if (id != rawInput) {
      _idController.value = TextEditingValue(
        text: id,
        selection: TextSelection.collapsed(offset: id.length),
      );
    }

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
    final uid =
        auth.user.id.trim().isNotEmpty ? auth.user.id.trim() : 'pending_user';

    setState(() {
      _uploadingDocSlot = docType;
      _uploadError = null;
    });

    try {
      final res = await MediaUploadService.instance
          .pickAndUploadProviderVerificationDoc(
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
        _showUrlFallback = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingDocSlot = null;
        _uploadError = isAr
            ? 'تعذّر رفع صورة الهوية: $e'
            : 'Failed to upload ID image: $e';
        _showUrlFallback = true;
      });
    }
  }

  String _resolveFrontUrl(UserModel user) {
    if (_frontUpload != null) return _frontUpload!.downloadUrl;
    final manual = _frontUrlFallbackController.text.trim();
    if (manual.isNotEmpty) return manual;
    return user.idFrontImage ?? '';
  }

  String _resolveBackUrl(UserModel user) {
    if (_backUpload != null) return _backUpload!.downloadUrl;
    final manual = _backUrlFallbackController.text.trim();
    if (manual.isNotEmpty) return manual;
    return user.idBackImage ?? '';
  }

  String? _resolveSelfieUrl(UserModel user) {
    if (_selfieUpload != null) return _selfieUpload!.downloadUrl;
    final manual = _selfieUrlFallbackController.text.trim();
    if (manual.isNotEmpty) return manual;
    return user.selfieImage;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final isAr = context.read<SettingsProvider>().isArabic;
    final auth = context.read<AuthProvider>();
    final idText = _normalizeDigits(_idController.text.trim());
    if (idText.length != 11 || !RegExp(r'^[23][0-9]{10}$').hasMatch(idText)) {
      setState(() {
        _idError = isAr
            ? 'يرجى إدخال الرقم الشخصي القطري (QID) المكون من 11 رقم ويبدأ بـ 2 أو 3'
            : 'Please enter a valid 11-digit Qatar ID (QID) starting with 2 or 3';
      });
      return;
    }

    final frontUrl = _resolveFrontUrl(auth.user);
    final backUrl = _resolveBackUrl(auth.user);
    final selfieUrl = _resolveSelfieUrl(auth.user);

    if (frontUrl.isEmpty || backUrl.isEmpty) {
      setState(() {
        _uploadError = isAr
            ? 'يرجى رفع صورة واضحة لوجه وظهر البطاقة الشخصية القطرية (QID) قبل الإرسال.'
            : 'Please upload clear photos of the front and back of your Qatar ID (QID) before submitting.';
      });
      return;
    }

    if (!_isValidHttpsOrStorageUrl(frontUrl) ||
        !_isValidHttpsOrStorageUrl(backUrl) ||
        (selfieUrl != null &&
            selfieUrl.isNotEmpty &&
            !_isValidHttpsOrStorageUrl(selfieUrl))) {
      setState(() {
        _uploadError = isAr
            ? 'يرجى التأكد من صحة رابط صورة الوثيقة (يبدأ بـ https://).'
            : 'Please provide a valid document image URL starting with https://.';
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: AppColors.slateBorder,
            width: AppDimens.borderWidth,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.tealSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.teal,
                size: 26,
              ),
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
            key: const ValueKey('id_verif_success_continue_btn'),
            text: widget.isOnboarding
                ? (isArabic ? 'متابعة إلى مشوار' : 'Continue to MASHWAR')
                : (isArabic ? 'العودة إلى حسابي' : 'Back to Account'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              if (widget.isOnboarding) {
                Navigator.of(context).pushReplacement(
                  MashwarPageRoute(
                    builder: (_) => const LocationPermissionScreen(),
                  ),
                );
              } else {
                final messenger = ScaffoldMessenger.maybeOf(context);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'تم تحديث حالة التوثيق إلى قيد المراجعة بنجاح'
                          : 'Verification status updated to Under Review',
                    ),
                    backgroundColor: AppColors.teal,
                  ),
                );
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
    final status = user.idVerificationStatus;

    final isVerified = status == IdVerificationStatus.verified;
    final isUnderReview = status == IdVerificationStatus.underReview;
    final isRejected = status == IdVerificationStatus.rejected;

    final hasFront = _frontUpload != null ||
        _frontUrlFallbackController.text.trim().isNotEmpty ||
        (user.idFrontImage?.isNotEmpty ?? false);
    final hasBack = _backUpload != null ||
        _backUrlFallbackController.text.trim().isNotEmpty ||
        (user.idBackImage?.isNotEmpty ?? false);
    final hasSelfie = _selfieUpload != null ||
        _selfieUrlFallbackController.text.trim().isNotEmpty ||
        (user.selfieImage?.isNotEmpty ?? false);

    Color statusCardBg = Colors.white;
    Color statusCardBorder = AppColors.slateBorder;
    Color statusIconBg = AppColors.slateBg;
    Color statusIconFg = AppColors.navy;
    IconData statusIcon = Icons.shield_outlined;
    String statusTitle = isAr
        ? 'توثيق الهوية القطرية (QID)'
        : 'Qatar ID (QID) Identity Verification';
    String statusSubtitle = isAr
        ? 'ارفع صور البطاقة الشخصية القطرية (QID) بصيغة صورة صالحة (حتى 10 ميجابايت).'
        : 'Upload clear Qatar ID (QID) photos (valid image up to 10 MB).';

    if (isVerified) {
      statusCardBg = AppColors.tealSurface;
      statusCardBorder = AppColors.teal.withValues(alpha: 0.35);
      statusIconBg = AppColors.teal;
      statusIconFg = Colors.white;
      statusIcon = Icons.verified_user_rounded;
      statusTitle =
          isAr ? 'حساب موثق بالبطاقة القطرية' : 'QID Verified Account';
      statusSubtitle = isAr
          ? 'تم التحقق من بياناتك وبطاقتك القطرية ومطابقتها.'
          : 'Your Qatar ID has been verified.';
    } else if (isUnderReview) {
      statusCardBg = AppColors.goldSurface;
      statusCardBorder = AppColors.gold.withValues(alpha: 0.45);
      statusIconBg = AppColors.navy;
      statusIconFg = Colors.white;
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = isAr
          ? 'وثائق الهوية قيد المراجعة'
          : 'ID Documents Under Review';
      statusSubtitle = isAr
          ? 'استلم فريق الأمان وثائقك وسيتم تأكيد التوثيق خلال 24 ساعة. يمكنك تحديث الصور أدناه عند الحاجة.'
          : 'Our safety team received your QID documents. You may update photos below if needed.';
    } else if (isRejected) {
      statusCardBg = AppColors.dangerBg;
      statusCardBorder = AppColors.danger.withValues(alpha: 0.35);
      statusIconBg = AppColors.danger;
      statusIconFg = Colors.white;
      statusIcon = Icons.error_outline_rounded;
      statusTitle = isAr
          ? 'يرجى إعادة رفع صور أوضح للهوية'
          : 'Please Re-upload Clearer ID Photos';
      statusSubtitle = isAr
          ? 'تعذرت قراءة البيانات في النسخة السابقة. يرجى رفع صور واضحة بدون انعكاس ضوئي.'
          : 'Previous photos were unclear. Please upload sharp photos without glare.';
    }

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        title: Text(
          isAr
              ? 'توثيق البطاقة الشخصية القطرية (QID)'
              : 'Qatar ID (QID) Verification',
          style: AppTypography.title().copyWith(fontSize: 17),
        ),
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navy,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space16,
              ),
              child: MashwarFadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: statusCardBg,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(
                          color: statusCardBorder,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusIconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusIconFg,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppDimens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusTitle,
                                  style: AppTypography.title().copyWith(
                                    fontSize: 15.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  statusSubtitle,
                                  style: AppTypography.bodySmall(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space20),

                    // QID Input Section Card
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(
                          color: AppColors.slateBorder,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'الرقم الشخصي القطري - QID (11 رقم)'
                                : 'Qatar Personal ID - QID (11 digits)',
                            style: AppTypography.label(color: AppColors.navy),
                          ),
                          const SizedBox(height: 8),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextField(
                              key: const ValueKey('id_verif_qid_input'),
                              controller: _idController,
                              keyboardType: TextInputType.number,
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9٠-٩۰-۹]'),
                                ),
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
                                fillColor: Colors.white,
                                counterText: '',
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.navy,
                                  size: 20,
                                ),
                                errorText: _idError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusField,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusField,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusField,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.navy,
                                    width: AppDimens.borderWidthFocused,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_detectedBirthDate != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.slateBg,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusSmall,
                                ),
                                border: Border.all(
                                  color: AppColors.slateBorder,
                                  width: AppDimens.borderWidth,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    color: AppColors.teal,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'سنة الميلاد: $_detectedBirthDate · الجنسية: $_detectedGovNameAr'
                                          : 'Birth Year: $_detectedBirthDate · Nationality: $_detectedGovNameEn',
                                      style: AppTypography.label(
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isAr
                                ? 'صور البطاقة الشخصية القطرية (QID)'
                                : 'Qatar ID (QID) Card Photos',
                            style: AppTypography.title().copyWith(fontSize: 16),
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('id_verif_toggle_url_fallback_btn'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            setState(
                              () => _showUrlFallback = !_showUrlFallback,
                            );
                          },
                          icon: Icon(
                            _showUrlFallback
                                ? Icons.expand_less_rounded
                                : Icons.link_rounded,
                            size: 16,
                            color: AppColors.navy,
                          ),
                          label: Text(
                            isAr ? 'رابط بديل' : 'URL Fallback',
                            style: AppTypography.label(color: AppColors.navy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space10),

                    if (_uploadError != null) ...[
                      Container(
                        key: const ValueKey('id_verif_upload_error'),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusAlert),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.35),
                            width: AppDimens.borderWidth,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _uploadError!,
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ],
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

                    if (_showUrlFallback) ...[
                      const SizedBox(height: AppDimens.space14),
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusCard),
                          border: Border.all(
                            color: AppColors.slateBorder,
                            width: AppDimens.borderWidth,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'إدخال روابط الصور يدوياً (عند تعذر الرفع المباشر)'
                                  : 'Manual Document Image URLs (Upload Fallback)',
                              style: AppTypography.label(color: AppColors.navy),
                            ),
                            const SizedBox(height: 10),
                            _buildUrlFallbackField(
                              fieldKey: 'id_verif_front_url_input',
                              controller: _frontUrlFallbackController,
                              label: isAr
                                  ? 'رابط صورة وجه البطاقة (https://...)'
                                  : 'Front ID image URL (https://...)',
                            ),
                            const SizedBox(height: 8),
                            _buildUrlFallbackField(
                              fieldKey: 'id_verif_back_url_input',
                              controller: _backUrlFallbackController,
                              label: isAr
                                  ? 'رابط صورة ظهر البطاقة (https://...)'
                                  : 'Back ID image URL (https://...)',
                            ),
                            const SizedBox(height: 8),
                            _buildUrlFallbackField(
                              fieldKey: 'id_verif_selfie_url_input',
                              controller: _selfieUrlFallbackController,
                              label: isAr
                                  ? 'رابط صورة السيلفي (اختياري)'
                                  : 'Selfie image URL (optional)',
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.space20),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusAlert),
                        border: Border.all(
                          color: AppColors.slateBorder,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.teal,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'بياناتك مشفرة ومحمية بالكامل بموجب قانون حماية خصوصية البيانات الشخصية القطري رقم 13 لسنة 2016. لا يتم مشاركة بطاقتك مع أي طرف ثالث.'
                                  : 'Your data is strictly encrypted and protected under Qatar Personal Data Privacy Protection Law No. 13 of 2016. Never shared with third parties.',
                              style: AppTypography.bodySmall(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),
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
                      const SizedBox(height: AppDimens.space10),
                      MashwarButton(
                        variant: MashwarButtonVariant.secondary,
                        text: isAr
                            ? 'تخطي التوثيق الآن والإكمال لاحقاً'
                            : 'Skip for now, complete later',
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MashwarPageRoute(
                              builder: (_) => const LocationPermissionScreen(),
                            ),
                          );
                        },
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

  Widget _buildUrlFallbackField({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        key: ValueKey(fieldKey),
        controller: controller,
        keyboardType: TextInputType.url,
        style: AppTypography.bodySmall(color: AppColors.navy),
        onChanged: (_) => setState(() => _uploadError = null),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodySmall(),
          isDense: true,
          filled: true,
          fillColor: AppColors.slateBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            borderSide: const BorderSide(
              color: AppColors.slateBorder,
              width: AppDimens.borderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            borderSide: const BorderSide(
              color: AppColors.slateBorder,
              width: AppDimens.borderWidth,
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
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: hasPhoto
              ? AppColors.teal.withValues(alpha: 0.4)
              : AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasPhoto ? AppColors.tealSurface : AppColors.slateBg,
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
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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
                      style: AppTypography.bodySmall(),
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
                          color: AppColors.navy,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: AppColors.slateBorder,
                            width: AppDimens.borderWidth,
                          ),
                        ),
                        child: Icon(
                          hasPhoto
                              ? Icons.refresh_rounded
                              : Icons.cloud_upload_outlined,
                          color: AppColors.navy,
                          size: 18,
                        ),
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
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Text(
                '${uploadResult.fileName} · ${uploadResult.formattedSize}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.navy),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
