import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/models/worksite_models.dart';
import '../../state/auth_provider.dart';
import '../../state/worksite_provider.dart';

/// Provider / Business Profile Setup, 11-digit Qatar ID (`QID`) Verification,
/// Real Approval Badge (`pending`/`approved`/`rejected`/`suspended`),
/// Saved Worksites Management, and Real Completed Jobs & Performance Stats.
class ProviderProfileScreen extends StatefulWidget {
  final bool focusSavedWorksites;

  const ProviderProfileScreen({
    super.key,
    this.focusSavedWorksites = false,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  static final RegExp _qidRegex = RegExp(r'^[0-9]{11}$');

  static const List<String> _municipalitiesAr = [
    'الدوحة',
    'لوسيل',
    'المنطقة الصناعية',
    'الريان',
    'الوكرة',
    'الخور',
    'مسيعيد',
  ];

  static const List<(String, String, String)> _specialties = [
    ('electrical', 'كهرباء', 'Electrical'),
    ('plumbing', 'سباكة', 'Plumbing'),
    ('hardware', 'عدد ومسامير', 'Hardware'),
    ('safety_ppe', 'سلامة PPE', 'Safety PPE'),
    ('tools', 'معدات', 'Tools'),
    ('civil_materials', 'مواد بناء', 'Civil Materials'),
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleTypeController;
  late final TextEditingController _vehiclePlateController;

  late final TextEditingController _qidController;
  late final TextEditingController _qidFrontUrlController;
  late final TextEditingController _qidBackUrlController;

  final Set<String> _selectedMunicipalities = {'الدوحة', 'لوسيل'};
  final Set<String> _selectedSpecialties = {'electrical', 'hardware'};
  bool _isAvailable = true;

  String? _localMessage;
  bool _localMessageIsError = false;
  WorksiteProvider? _fallbackWorksiteProvider;

  WorksiteProvider _resolveWorksite(BuildContext context) {
    final provided = context.watch<WorksiteProvider?>();
    if (provided != null) return provided;
    final auth = context.read<AuthProvider?>();
    return _fallbackWorksiteProvider ??= WorksiteProvider(
      initialUserId: auth?.user.id,
      initialUserName: auth?.user.fullName,
    );
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider?>();
    final existing = context.read<WorksiteProvider?>()?.providerProfile;

    _nameController = TextEditingController(
      text: existing?.fullName ?? auth?.user.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: existing?.phone ?? auth?.user.phone ?? '',
    );
    _vehicleTypeController = TextEditingController(
      text: existing?.vehicleType ?? 'بيك أب غمارة',
    );
    _vehiclePlateController = TextEditingController(
      text: existing?.vehiclePlate ?? '',
    );
    _qidController = TextEditingController(
      text: existing?.qidNumber ?? auth?.user.nationalId ?? '',
    );
    _qidFrontUrlController = TextEditingController(
      text: existing?.qidFrontUrl ??
          'https://storage.mashwar.qa/kyc/qid_front.jpg',
    );
    _qidBackUrlController = TextEditingController(
      text:
          existing?.qidBackUrl ?? 'https://storage.mashwar.qa/kyc/qid_back.jpg',
    );
    if (existing != null) {
      if (existing.serviceMunicipalities.isNotEmpty) {
        _selectedMunicipalities
          ..clear()
          ..addAll(existing.serviceMunicipalities);
      }
      if (existing.supplySpecialties.isNotEmpty) {
        _selectedSpecialties
          ..clear()
          ..addAll(existing.supplySpecialties);
      }
      _isAvailable = existing.isAvailable;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<WorksiteProvider?>();
      final uid = provider?.currentUserId ?? auth?.user.id ?? '';
      if (provider != null && uid.isNotEmpty) {
        final loaded = await provider.loadProviderProfile(uid);
        await provider.loadSavedWorksites(uid);
        if (mounted && loaded != null) {
          setState(() {
            _nameController.text = loaded.fullName;
            _phoneController.text = loaded.phone;
            if (loaded.vehicleType != null) {
              _vehicleTypeController.text = loaded.vehicleType!;
            }
            if (loaded.vehiclePlate != null) {
              _vehiclePlateController.text = loaded.vehiclePlate!;
            }
            if (loaded.qidNumber != null) {
              _qidController.text = loaded.qidNumber!;
            }
            if (loaded.serviceMunicipalities.isNotEmpty) {
              _selectedMunicipalities
                ..clear()
                ..addAll(loaded.serviceMunicipalities);
            }
            if (loaded.supplySpecialties.isNotEmpty) {
              _selectedSpecialties
                ..clear()
                ..addAll(loaded.supplySpecialties);
            }
            _isAvailable = loaded.isAvailable;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    _qidController.dispose();
    _qidFrontUrlController.dispose();
    _qidBackUrlController.dispose();
    _fallbackWorksiteProvider?.dispose();
    super.dispose();
  }

  BadgeType _badgeTypeForApproval(ProviderApprovalStatus? status) {
    switch (status) {
      case ProviderApprovalStatus.approved:
        return BadgeType.verified;
      case ProviderApprovalStatus.pending:
        return BadgeType.pending;
      case ProviderApprovalStatus.rejected:
        return BadgeType.rejected;
      case ProviderApprovalStatus.suspended:
        return BadgeType.suspended;
      case null:
        return BadgeType.newBadge;
    }
  }

  Future<void> _handleSaveProfile(
    WorksiteProvider provider,
    AuthProvider? auth,
    bool isAr,
  ) async {
    final uid = provider.currentUserId ?? auth?.user.id ?? '';
    if (uid.trim().isEmpty) {
      setState(() {
        _localMessage = isAr
            ? 'يرجى تسجيل الدخول لحفظ ملف المزود.'
            : 'Please sign in before saving your provider profile.';
        _localMessageIsError = true;
      });
      return;
    }

    final now = DateTime.now().toUtc();
    final existing = provider.providerProfile;
    final draft = ProviderProfile(
      id: uid,
      userId: uid,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleType: _vehicleTypeController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim(),
      serviceMunicipalities: _selectedMunicipalities.toList(),
      supplySpecialties: _selectedSpecialties.toList(),
      approvalStatus: existing?.approvalStatus ?? ProviderApprovalStatus.pending,
      rating: existing?.rating ?? 0.0,
      completedJobsCount: existing?.completedJobsCount ?? 0,
      isAvailable: _isAvailable,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final saved = await provider.saveProviderProfile(draft);
    if (!mounted) return;
    if (saved != null) {
      setState(() {
        _localMessage = isAr
            ? 'تم حفظ بيانات ملف المزود بنجاح.'
            : 'Provider profile saved successfully.';
        _localMessageIsError = false;
      });
    } else {
      setState(() {
        _localMessage = provider.localizedError(isArabic: isAr);
        _localMessageIsError = true;
      });
    }
  }

  Future<void> _handleSubmitQid(
    WorksiteProvider provider,
    AuthProvider? auth,
    bool isAr,
  ) async {
    final qid = _qidController.text.trim();
    if (!_qidRegex.hasMatch(qid)) {
      setState(() {
        _localMessage = isAr
            ? 'البطاقة الشخصية القطرية (QID) يجب أن تتكون من 11 رقماً بالضبط.'
            : 'Qatar ID (QID) must be exactly 11 numeric digits.';
        _localMessageIsError = true;
      });
      return;
    }

    final uid = provider.currentUserId ?? auth?.user.id;
    final res = await provider.submitVerification(
      userId: uid,
      qidNumber: qid,
      qidFrontUrl: _qidFrontUrlController.text.trim(),
      qidBackUrl: _qidBackUrlController.text.trim(),
      vehicleType: _vehicleTypeController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim(),
      serviceMunicipalities: _selectedMunicipalities.toList(),
      supplySpecialties: _selectedSpecialties.toList(),
    );
    if (!mounted) return;
    if (res != null) {
      setState(() {
        _localMessage = isAr
            ? 'تم إرسال طلب توثيق البطاقة القطرية (QID) للمراجعة.'
            : 'Qatar ID (QID) verification submitted for admin review.';
        _localMessageIsError = false;
      });
    } else {
      setState(() {
        _localMessage = provider.localizedError(isArabic: isAr);
        _localMessageIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final provider = _resolveWorksite(context);
    final auth = context.watch<AuthProvider?>();
    final profile = provider.providerProfile;
    final uid = provider.currentUserId ?? auth?.user.id ?? '';

    final completedJobs = provider.allLoadedRequests
        .where(
          (r) =>
              uid.isNotEmpty &&
              r.assignedProviderId == uid &&
              r.status == WorkRequestStatus.completed,
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          isAr
              ? 'ملف المزود ومواقع العمل'
              : 'Provider Verification & Worksites',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Real Status & Performance Summary Card
                  _buildStatusAndStatsCard(profile, isAr),
                  const SizedBox(height: 16),

                  if (_localMessage != null) ...[
                    Container(
                      key: const ValueKey('provider_feedback_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _localMessageIsError
                            ? AppColors.dangerBg
                            : AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _localMessageIsError
                              ? AppColors.danger
                              : AppColors.teal,
                        ),
                      ),
                      child: Text(
                        _localMessage!,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.focusSavedWorksites) ...[
                    _buildSavedWorksitesSection(context, provider, uid, isAr),
                    const SizedBox(height: 20),
                  ],

                  // Provider / Business Profile Form
                  _buildProfileSetupSection(provider, auth, isAr),
                  const SizedBox(height: 20),

                  // 11-Digit QID Verification Form
                  _buildQidVerificationSection(provider, auth, isAr),
                  const SizedBox(height: 20),

                  if (!widget.focusSavedWorksites) ...[
                    _buildSavedWorksitesSection(context, provider, uid, isAr),
                    const SizedBox(height: 20),
                  ],

                  // Completed Jobs History
                  _buildCompletedJobsSection(completedJobs, isAr),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAndStatsCard(ProviderProfile? profile, bool isAr) {
    final statusLabel = profile != null
        ? profile.approvalStatus.label(isArabic: isAr)
        : (isAr ? 'غير مسجل كمزود بعد' : 'Not Submitted Yet');
    final completedCount = profile?.completedJobsCount ?? 0;
    final hasRating = profile != null && profile.rating > 0;

    return Container(
      key: const ValueKey('provider_status_summary_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? 'حالة اعتماد المزود (QID)'
                        : 'Provider QID Approval Status',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : (isAr ? 'ملف مزود التوريد' : 'Supply Provider Profile'),
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                ],
              ),
              MashwarBadge(
                key: const ValueKey('provider_approval_badge'),
                type: _badgeTypeForApproval(profile?.approvalStatus),
                customLabel: statusLabel,
              ),
            ],
          ),
          if (profile?.rejectionReason != null &&
              profile!.rejectionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isAr
                    ? 'سبب الرفض: ${profile.rejectionReason}'
                    : 'Rejection reason: ${profile.rejectionReason}',
                style: AppTypography.label(color: AppColors.danger)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderDisabled),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$completedCount',
                      style: AppTypography.title(color: AppColors.navy)
                          .copyWith(fontSize: 18),
                    ),
                    Text(
                      isAr ? 'مهام مكتملة' : 'Completed Jobs',
                      style: AppTypography.label(),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1, height: 28, color: AppColors.borderDisabled),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      hasRating
                          ? '${profile.rating.toStringAsFixed(1)} ★'
                          : '—',
                      style: AppTypography.title(color: AppColors.teal)
                          .copyWith(fontSize: 18),
                    ),
                    Text(
                      isAr ? 'التقييم الفعلي' : 'Verified Rating',
                      style: AppTypography.label(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetupSection(
    WorksiteProvider provider,
    AuthProvider? auth,
    bool isAr,
  ) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderDisabled),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
            isAr
                ? '1. بيانات المنشأة / مزود التوريد والمركبة'
                : '1. Provider / Business & Vehicle Details',
            style: AppTypography.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('provider_name_input'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isAr
                  ? 'الاسم الكامل أو اسم المؤسسة *'
                  : 'Full Name or Business Name *',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('provider_phone_input'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم الجوال القطري *' : 'Qatar Mobile Number *',
              hintText: '55234567',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vehicleTypeController,
                  decoration: InputDecoration(
                    labelText: isAr ? 'نوع المركبة' : 'Vehicle Type',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _vehiclePlateController,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رقم اللوحة' : 'Plate Number',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isAr ? 'مناطق الخدمة في قطر' : 'Service Areas in Qatar',
            style: AppTypography.label(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _municipalitiesAr.map((area) {
              final sel = _selectedMunicipalities.contains(area);
              return FilterChip(
                label: Text(AppStrings.translateCity(area, isArabic: isAr)),
                selected: sel,
                selectedColor: AppColors.tealSurface,
                checkmarkColor: AppColors.teal,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedMunicipalities.add(area);
                    } else if (_selectedMunicipalities.length > 1) {
                      _selectedMunicipalities.remove(area);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? 'تخصصات التوريد' : 'Supply Specialties',
            style: AppTypography.label(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _specialties.map((sp) {
              final sel = _selectedSpecialties.contains(sp.$1);
              return FilterChip(
                label: Text(isAr ? sp.$2 : sp.$3),
                selected: sel,
                selectedColor: AppColors.sand,
                checkmarkColor: AppColors.navy,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedSpecialties.add(sp.$1);
                    } else if (_selectedSpecialties.length > 1) {
                      _selectedSpecialties.remove(sp.$1);
                    }
                  });
                },
              );
            }).toList(),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AppColors.teal,
            title: Text(
              isAr
                  ? 'متاح لاستقبال طلبات التوريد'
                  : 'Available for Worksite Supply Jobs',
              style: AppTypography.bodySecondary(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
          const SizedBox(height: 8),
          MashwarButton(
            key: const ValueKey('save_provider_profile_btn'),
            text: isAr ? 'حفظ ملف المزود' : 'Save Provider Profile',
            variant: MashwarButtonVariant.secondary,
            isLoading: provider.isSubmitting,
            onPressed: () => _handleSaveProfile(provider, auth, isAr),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQidVerificationSection(
    WorksiteProvider provider,
    AuthProvider? auth,
    bool isAr,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr
                ? '2. توثيق البطاقة الشخصية القطرية (QID - 11 رقماً)'
                : '2. Qatar ID (11-Digit QID) Verification',
            style: AppTypography.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'يُراجع فريق العمليات بيانات QID لاعتماد حسابك كمزود توريد مؤهل لتقديم العروض.'
                : 'Operations staff review your 11-digit QID before enabling offer submissions.',
            style: AppTypography.bodySmall(),
          ),
          const SizedBox(height: 14),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const ValueKey('provider_qid_input'),
              controller: _qidController,
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: isAr
                    ? 'الرقم الشخصي القطري (11 رقماً) *'
                    : '11-Digit Qatar ID Number *',
                hintText: '29163401122',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('provider_qid_front_input'),
            controller: _qidFrontUrlController,
            decoration: InputDecoration(
              labelText: isAr
                  ? 'رابط صورة وجه البطاقة القطرية *'
                  : 'QID Front Photo URL *',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('provider_qid_back_input'),
            controller: _qidBackUrlController,
            decoration: InputDecoration(
              labelText: isAr
                  ? 'رابط صورة ظهر البطاقة القطرية *'
                  : 'QID Back Photo URL *',
            ),
          ),
          const SizedBox(height: 16),
          MashwarButton(
            key: const ValueKey('submit_qid_verification_btn'),
            text: isAr
                ? 'إرسال طلب توثيق QID للمراجعة'
                : 'Submit QID Verification',
            isLoading: provider.isSubmitting,
            onPressed: () => _handleSubmitQid(provider, auth, isAr),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedWorksitesSection(
    BuildContext context,
    WorksiteProvider provider,
    String uid,
    bool isAr,
  ) {
    final sites = provider.savedWorksites;

    return Container(
      key: const ValueKey('saved_worksites_section'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                isAr ? 'مواقع العمل المحفوظة' : 'Saved Worksites',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
              OutlinedButton.icon(
                key: const ValueKey('add_saved_worksite_btn'),
                onPressed: () =>
                    _showAddWorksiteModal(context, provider, uid, isAr),
                icon: const Icon(Icons.add_location_alt_outlined, size: 17),
                label: Text(isAr ? 'إضافة موقع' : 'Add Worksite'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sites.isEmpty)
            Text(
              isAr
                  ? 'لم تقم بحفظ أي مواقع عمل بعد. أضف مشاريعك المتكررة للطلب بضغطة واحدة.'
                  : 'No saved worksites yet. Save active project sites for 1-tap request creation.',
              style: AppTypography.bodySecondary(),
            )
          else
            ...sites.map(
              (site) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      children: [
                        Text(
                          site.label,
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (site.isDefault)
                          MashwarBadge(
                            type: BadgeType.confirmed,
                            customLabel: isAr ? 'افتراضي' : 'Default',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.translateCity(site.municipality, isArabic: isAr)} · ${site.zoneOrStreet}',
                      style: AppTypography.bodySmall(color: AppColors.navy),
                    ),
                    Text(
                      '${site.siteContactName} · ${site.siteContactPhone}',
                      style: AppTypography.label(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobsSection(
    List<WorkRequest> completedJobs,
    bool isAr,
  ) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderDisabled),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'سجل مهام التوريد المكتملة (${completedJobs.length})'
                  : 'Completed Supply Jobs (${completedJobs.length})',
              style: AppTypography.title().copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (completedJobs.isEmpty)
              Text(
                isAr
                    ? 'لا توجد مهام مكتملة مسجلة في هذه الجلسة بعد.'
                    : 'No completed supply jobs recorded yet.',
                style: AppTypography.bodySecondary(),
              )
            else
              ...completedJobs.map(
                (job) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_rounded,
                      color: AppColors.teal),
                  title: Text(
                    job.title,
                    style: AppTypography.body(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle:
                      Text('${job.pickupLocation} → ${job.dropoffWorksite}'),
                  trailing: Text(
                    job.effectiveTotalMinor.format(isArabic: isAr),
                    style: AppTypography.label(color: AppColors.teal)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddWorksiteModal(
    BuildContext context,
    WorksiteProvider provider,
    String uid,
    bool isAr,
  ) {
    final labelCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final contactNameCtrl = TextEditingController();
    final contactPhoneCtrl = TextEditingController();
    String selectedArea = 'لوسيل';
    String? modalErr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isAr ? 'إضافة موقع عمل محفوظ' : 'Add Saved Worksite',
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    if (modalErr != null) ...[
                      Text(modalErr!,
                          style: AppTypography.label(color: AppColors.danger)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      key: const ValueKey('worksite_label_input'),
                      controller: labelCtrl,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'اسم المشروع / الموقع *'
                            : 'Project / Site Label *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedArea,
                      items: _municipalitiesAr
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(AppStrings.translateCity(m,
                                  isArabic: isAr)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => selectedArea = v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('worksite_street_input'),
                      controller: streetCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'المنطقة والشارع *' : 'Zone & Street *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('worksite_contact_name_input'),
                      controller: contactNameCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'اسم مسؤول الموقع *' : 'Site Contact Name *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('worksite_contact_phone_input'),
                      controller: contactPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'جوال مسؤول الموقع *'
                            : 'Site Contact Phone *',
                      ),
                    ),
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_save_worksite_btn'),
                      text: isAr ? 'حفظ موقع العمل' : 'Save Worksite',
                      onPressed: () async {
                        if (labelCtrl.text.trim().isEmpty ||
                            streetCtrl.text.trim().isEmpty ||
                            contactNameCtrl.text.trim().isEmpty ||
                            contactPhoneCtrl.text.trim().isEmpty) {
                          setModalState(() {
                            modalErr = isAr
                                ? 'يرجى تعبئة جميع الحقول المطلوبة.'
                                : 'Please complete all required fields.';
                          });
                          return;
                        }
                        final now = DateTime.now().toUtc();
                        final ownerId = uid.isNotEmpty ? uid : 'local_owner';
                        final saved = await provider.addSavedWorksite(
                          SavedWorksite(
                            id: '',
                            ownerUserId: ownerId,
                            label: labelCtrl.text.trim(),
                            municipality: selectedArea,
                            zoneOrStreet: streetCtrl.text.trim(),
                            siteContactName: contactNameCtrl.text.trim(),
                            siteContactPhone: contactPhoneCtrl.text.trim(),
                            isDefault: provider.savedWorksites.isEmpty,
                            createdAt: now,
                            updatedAt: now,
                          ),
                        );
                        if (!sheetCtx.mounted) return;
                        if (saved != null) {
                          Navigator.of(sheetCtx).pop();
                        } else {
                          setModalState(() {
                            modalErr = provider.localizedError(isArabic: isAr);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
