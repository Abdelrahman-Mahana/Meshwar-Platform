import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/models/worksite_models.dart';
import '../../state/auth_provider.dart';
import '../../state/worksite_provider.dart';
import 'provider_profile_screen.dart';
import 'work_request_details_screen.dart';

/// 3-step validated Worksite Supply Request creation screen (P0 + Quick Reorder prefill).
///
/// Step 1: Title, Supply Category, Item Description, Quantity & Unit, Reference Photo URL/Selector.
/// Step 2: Pickup Store/Location & Qatar Area + Delivery Worksite & Saved Worksites Picker.
/// Step 3: Delivery Deadline, QAR Budget (`MoneyMinor`), Pilot Payment (`COD` / `Manual Bank Transfer`),
///         Additional Instructions, Review Summary & Publish.
class CreateWorkRequestScreen extends StatefulWidget {
  final WorkRequestReorderDraft? initialDraft;
  final SavedWorksite? initialSavedWorksite;
  final String? initialSupplyCategory;

  const CreateWorkRequestScreen({
    super.key,
    this.initialDraft,
    this.initialSavedWorksite,
    this.initialSupplyCategory,
  });

  @override
  State<CreateWorkRequestScreen> createState() =>
      _CreateWorkRequestScreenState();
}

class _CreateWorkRequestScreenState extends State<CreateWorkRequestScreen> {
  static const List<String> _qatarAreasAr = [
    'الدوحة',
    'لوسيل',
    'المنطقة الصناعية',
    'الريان',
    'الوكرة',
    'الخور',
    'أم صلال',
    'الضعاين',
    'مسيعيد',
    'دخان',
    'رأس لفان',
  ];

  static const List<(String, String, String, IconData)> _supplyCategories = [
    ('general_site_supply', 'توريد موقع عام', 'General Site Supply', Icons.inventory_2_outlined),
    ('electrical', 'كهرباء وكابلات', 'Electrical & Cables', Icons.electrical_services_rounded),
    ('plumbing', 'سباكة ومواسير', 'Plumbing & Pipes', Icons.plumbing_rounded),
    ('hardware', 'عدد ومسامير', 'Hardware & Fasteners', Icons.handyman_outlined),
    ('safety_ppe', 'سلامة مهنية PPE', 'Safety & PPE', Icons.health_and_safety_outlined),
    ('tools', 'معدات وأدوات', 'Power & Hand Tools', Icons.build_circle_outlined),
    ('civil_materials', 'مواد بناء وتشطيب', 'Civil & Finishing', Icons.foundation_rounded),
  ];

  static const List<(String, String, String)> _units = [
    ('pcs', 'قطعة', 'pcs'),
    ('carton', 'كرتون', 'carton'),
    ('roll', 'لفة', 'roll'),
    ('set', 'طقم', 'set'),
    ('bag', 'كيس', 'bag'),
    ('meter', 'متر', 'meter'),
  ];

  int _currentStep = 0; // 0, 1, 2

  // Step 1 controllers & state
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _referencePhotoController;
  String _selectedCategory = 'general_site_supply';
  String _selectedUnit = 'pcs';

  // Step 2 controllers & state
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  late final TextEditingController _siteContactNameController;
  late final TextEditingController _siteContactPhoneController;
  String _selectedArea = 'لوسيل';
  String? _selectedSavedWorksiteId;

  // Step 3 controllers & state
  late final TextEditingController _estimatedItemsQarController;
  late final TextEditingController _maxCapQarController;
  late final TextEditingController _deliveryFeeQarController;
  late final TextEditingController _instructionsController;
  int _deadlinePresetIndex = 0; // 0: +2h, 1: +4h, 2: tomorrow 8am, 3: +24h
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _requiresPurchaseReceipt = true;

  String? _stepValidationError;
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
    final draft = widget.initialDraft;
    final site = widget.initialSavedWorksite;

    _selectedCategory = draft?.supplyCategory ??
        widget.initialSupplyCategory ??
        'general_site_supply';

    _titleController = TextEditingController(text: draft?.title ?? '');
    _descriptionController =
        TextEditingController(text: draft?.description ?? '');
    _quantityController = TextEditingController(text: '1');
    _referencePhotoController = TextEditingController();

    _pickupController =
        TextEditingController(text: draft?.pickupLocation ?? '');
    _dropoffController = TextEditingController(
      text: draft?.dropoffWorksite ??
          (site != null ? '${site.label} - ${site.zoneOrStreet}' : ''),
    );
    _siteContactNameController = TextEditingController(
      text: draft?.siteContactName ?? site?.siteContactName ?? '',
    );
    _siteContactPhoneController = TextEditingController(
      text: draft?.siteContactPhone ?? site?.siteContactPhone ?? '',
    );

    if (draft != null && draft.municipality.trim().isNotEmpty) {
      _selectedArea = _qatarAreasAr.contains(draft.municipality.trim())
          ? draft.municipality.trim()
          : _qatarAreasAr.first;
    } else if (site != null && site.municipality.trim().isNotEmpty) {
      _selectedArea = _qatarAreasAr.contains(site.municipality.trim())
          ? site.municipality.trim()
          : _qatarAreasAr.first;
    }
    _selectedSavedWorksiteId = draft?.savedWorksiteId ?? site?.id;

    _estimatedItemsQarController = TextEditingController(
      text: draft != null
          ? draft.estimatedItemsCostMinor
              .toDecimalString(alwaysShowDecimals: false)
          : '',
    );
    _maxCapQarController = TextEditingController(
      text: draft != null
          ? draft.maxItemsCapMinor.toDecimalString(alwaysShowDecimals: false)
          : '',
    );
    _deliveryFeeQarController = TextEditingController(
      text: draft != null
          ? draft.deliveryFeeBudgetMinor
              .toDecimalString(alwaysShowDecimals: false)
          : '',
    );
    _instructionsController =
        TextEditingController(text: draft?.itemNotes ?? '');
    if (draft != null) {
      _paymentMethod = draft.paymentMethod;
      _requiresPurchaseReceipt = draft.requiresPurchaseReceipt;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<WorksiteProvider?>();
      final uid = provider?.currentUserId ??
          context.read<AuthProvider?>()?.user.id ??
          '';
      if (provider != null &&
          uid.isNotEmpty &&
          provider.savedWorksites.isEmpty) {
        provider.loadSavedWorksites(uid);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _referencePhotoController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _siteContactNameController.dispose();
    _siteContactPhoneController.dispose();
    _estimatedItemsQarController.dispose();
    _maxCapQarController.dispose();
    _deliveryFeeQarController.dispose();
    _instructionsController.dispose();
    _fallbackWorksiteProvider?.dispose();
    super.dispose();
  }

  DateTime _computeDeadlineUtc() {
    final now = DateTime.now().toUtc();
    switch (_deadlinePresetIndex) {
      case 0:
        return now.add(const Duration(hours: 2));
      case 1:
        return now.add(const Duration(hours: 4));
      case 2:
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0);
      case 3:
      default:
        return now.add(const Duration(hours: 24));
    }
  }

  String _deadlineLabel(bool isAr, int index) {
    switch (index) {
      case 0:
        return isAr ? 'عاجل (خلال ساعتين)' : 'Urgent (Within 2 hrs)';
      case 1:
        return isAr ? 'اليوم (خلال 4 ساعات)' : 'Today (Within 4 hrs)';
      case 2:
        return isAr ? 'غداً 8:00 صباحاً' : 'Tomorrow 8:00 AM';
      case 3:
      default:
        return isAr ? 'خلال 24 ساعة' : 'Within 24 hours';
    }
  }

  bool _isSafeUrl(String raw) {
    return raw.startsWith('https://') ||
        raw.startsWith('http://') ||
        raw.startsWith('gs://');
  }

  String? _validateStep(int step, bool isAr) {
    if (step == 0) {
      final title = _titleController.text.trim();
      final desc = _descriptionController.text.trim();
      final qtyRaw = _quantityController.text.trim();
      final photoUrl = _referencePhotoController.text.trim();

      if (title.length < 3 || title.length > 160) {
        return isAr
            ? 'يرجى إدخال عنوان واضح للطلب (3 إلى 160 حرفاً).'
            : 'Please enter a clear request title (3 to 160 characters).';
      }
      if (desc.length < 5) {
        return isAr
            ? 'يرجى إدخال وصف المواد والمواصفات المطلوبة (5 أحرف على الأقل).'
            : 'Please enter item specifications and description (at least 5 characters).';
      }
      final qty = int.tryParse(qtyRaw);
      if (qty == null || qty <= 0) {
        return isAr
            ? 'يرجى إدخال كمية صحيحة أكبر من صفر.'
            : 'Please enter a valid positive quantity.';
      }
      if (photoUrl.isNotEmpty && !_isSafeUrl(photoUrl)) {
        return isAr
            ? 'رابط الصورة المرجعية يجب أن يبدأ بـ https://'
            : 'Reference photo URL must start with https://';
      }
      return null;
    }

    if (step == 1) {
      final pickup = _pickupController.text.trim();
      final dropoff = _dropoffController.text.trim();
      final phone = _siteContactPhoneController.text.trim();

      if (pickup.length < 3) {
        return isAr
            ? 'يرجى تحديد متجر أو نقطة الاستلام.'
            : 'Please enter the pickup store or location.';
      }
      if (_selectedArea.trim().isEmpty) {
        return isAr
            ? 'يرجى اختيار المنطقة / البلدية في قطر.'
            : 'Please select the Qatar area / municipality.';
      }
      if (dropoff.length < 3) {
        return isAr
            ? 'يرجى إدخال عنوان موقع العمل للتسليم.'
            : 'Please enter the delivery worksite address.';
      }
      if (phone.isNotEmpty &&
          !RegExp(r'^(?:\+?974)?[3567][0-9]{7}$').hasMatch(phone)) {
        return isAr
            ? 'رقم جوال مسؤول الموقع يجب أن يكون رقماً قطرياً صحيحاً (8 أرقام).'
            : 'Site contact phone must be a valid 8-digit Qatar mobile number.';
      }
      return null;
    }

    if (step == 2) {
      MoneyMinor? estMinor;
      MoneyMinor? capMinor;
      MoneyMinor? feeMinor;

      try {
        estMinor =
            MoneyMinor.fromDecimalString(_estimatedItemsQarController.text);
      } catch (_) {
        estMinor = null;
      }
      if (estMinor == null || estMinor.minorUnits <= 0) {
        return isAr
            ? 'يرجى إدخال التكلفة التقديرية للمشتريات بالريال القطري (أكبر من 0).'
            : 'Please enter a valid positive estimated items cost in QAR.';
      }

      final capText = _maxCapQarController.text.trim();
      if (capText.isNotEmpty) {
        try {
          capMinor = MoneyMinor.fromDecimalString(capText);
        } catch (_) {
          return isAr
              ? 'يرجى إدخال حد أقصى صحيح للفاتورة بالريال القطري.'
              : 'Please enter a valid max receipt cap in QAR.';
        }
        if (capMinor.minorUnits < estMinor.minorUnits) {
          return isAr
              ? 'الحد الأقصى للفاتورة يجب أن يكون مساوياً أو أكبر من التكلفة التقديرية.'
              : 'Max receipt cap must be greater than or equal to estimated items cost.';
        }
      }

      try {
        feeMinor = MoneyMinor.fromDecimalString(_deliveryFeeQarController.text);
      } catch (_) {
        feeMinor = null;
      }
      if (feeMinor == null || feeMinor.minorUnits <= 0) {
        return isAr
            ? 'يرجى إدخال ميزانية رسوم التوصيل والتوريد بالريال القطري (أكبر من 0).'
            : 'Please enter a valid positive delivery fee budget in QAR.';
      }
      return null;
    }

    return null;
  }

  void _handleNext(bool isAr) {
    final err = _validateStep(_currentStep, isAr);
    if (err != null) {
      setState(() => _stepValidationError = err);
      return;
    }
    setState(() {
      _stepValidationError = null;
      if (_currentStep == 1 && _maxCapQarController.text.trim().isEmpty) {
        final est = _estimatedItemsQarController.text.trim();
        if (est.isNotEmpty) {
          _maxCapQarController.text = est;
        }
      }
      _currentStep++;
    });
  }

  Future<void> _handlePublish(
    BuildContext context,
    WorksiteProvider provider,
    bool isAr,
  ) async {
    for (var s = 0; s <= 2; s++) {
      final err = _validateStep(s, isAr);
      if (err != null) {
        setState(() {
          _currentStep = s;
          _stepValidationError = err;
        });
        return;
      }
    }

    setState(() => _stepValidationError = null);

    final estMinor =
        MoneyMinor.fromDecimalString(_estimatedItemsQarController.text.trim());
    final capText = _maxCapQarController.text.trim();
    final capMinor = capText.isNotEmpty
        ? MoneyMinor.fromDecimalString(capText)
        : estMinor;
    final feeMinor =
        MoneyMinor.fromDecimalString(_deliveryFeeQarController.text.trim());

    final qty = _quantityController.text.trim();
    final unitTuple = _units.firstWhere(
      (u) => u.$1 == _selectedUnit,
      orElse: () => _units.first,
    );
    final photoUrl = _referencePhotoController.text.trim();
    final extraNotes = _instructionsController.text.trim();

    final combinedNotesParts = <String>[
      'Qty: $qty ${unitTuple.$3}',
      if (photoUrl.isNotEmpty) 'RefPhoto: $photoUrl',
      if (extraNotes.isNotEmpty) extraNotes,
    ];

    final auth = context.read<AuthProvider?>();
    final fallbackUid = provider.currentUserId ??
        ((auth != null && auth.user.id.trim().isNotEmpty)
            ? auth.user.id.trim()
            : null);
    final fallbackName = provider.currentUserName.isNotEmpty
        ? provider.currentUserName
        : (auth?.user.fullName ?? '');

    final created = await provider.createRequest(
      requesterId: fallbackUid,
      requesterName: fallbackName,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      supplyCategory: _selectedCategory,
      pickupLocation: _pickupController.text.trim(),
      dropoffWorksite: _dropoffController.text.trim(),
      municipality: _selectedArea,
      estimatedItemsCostMinor: estMinor,
      maxItemsCapMinor: capMinor,
      deliveryFeeBudgetMinor: feeMinor,
      paymentMethod: _paymentMethod,
      savedWorksiteId: _selectedSavedWorksiteId,
      siteContactName: _siteContactNameController.text.trim().isNotEmpty
          ? _siteContactNameController.text.trim()
          : null,
      siteContactPhone: _siteContactPhoneController.text.trim().isNotEmpty
          ? _siteContactPhoneController.text.trim()
          : null,
      itemNotes: combinedNotesParts.join(' | '),
      requiresPurchaseReceipt: _requiresPurchaseReceipt,
      scheduledBy: _computeDeadlineUtc(),
      sourceRequestId: widget.initialDraft?.sourceRequestId,
    );

    if (!context.mounted) return;
    if (created != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkRequestDetailsScreen(requestId: created.id),
        ),
      );
    }
  }

  void _applySavedWorksite(SavedWorksite site) {
    setState(() {
      _selectedSavedWorksiteId = site.id;
      if (_qatarAreasAr.contains(site.municipality.trim())) {
        _selectedArea = site.municipality.trim();
      }
      _dropoffController.text = '${site.label} - ${site.zoneOrStreet}';
      _siteContactNameController.text = site.siteContactName;
      _siteContactPhoneController.text = site.siteContactPhone;
      if (site.gateInstructions != null &&
          site.gateInstructions!.trim().isNotEmpty &&
          _instructionsController.text.trim().isEmpty) {
        _instructionsController.text = site.gateInstructions!.trim();
      }
      _stepValidationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final provider = _resolveWorksite(context);
    final providerErr = provider.localizedError(isArabic: isAr);

    final stepTitles = [
      isAr ? 'تفاصيل المواد والكمية' : 'Items & Quantity',
      isAr ? 'الاستلام وموقع العمل' : 'Pickup & Worksite',
      isAr ? 'الميزانية والدفع والمراجعة' : 'Budget, Payment & Review',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _stepValidationError = null;
                _currentStep--;
              });
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          isAr ? 'إنشاء طلب توريد موقع' : 'Create Worksite Request',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                // Step progress header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.space20, 10, AppDimens.space20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: List.generate(3, (idx) {
                          final active = idx <= _currentStep;
                          final current = idx == _currentStep;
                          return Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsetsDirectional.only(
                                  end: idx < 2 ? 6 : 0),
                              decoration: BoxDecoration(
                                color: current
                                    ? AppColors.navy
                                    : (active
                                        ? AppColors.teal
                                        : AppColors.borderDisabled),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            stepTitles[_currentStep],
                            style: AppTypography.body(color: AppColors.navy)
                                .copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              isAr
                                  ? 'الخطوة ${_currentStep + 1} من 3'
                                  : 'Step ${_currentStep + 1} of 3',
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderDisabled),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.initialDraft != null) ...[
                          Container(
                            key: const ValueKey('reorder_prefill_banner'),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.teal.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.replay_rounded,
                                    color: AppColors.teal, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAr
                                        ? 'إعادة طلب سريعة: تم تعبئة المواد والموقع والميزانية من طلبك السابق بدون أي عروض أو حالات سابقة.'
                                        : 'Quick Reorder: Items, worksite, and QAR budget were prefilled cleanly from your previous request.',
                                    style: AppTypography.label(
                                            color: AppColors.navy)
                                        .copyWith(height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_stepValidationError != null) ...[
                          _buildErrorBanner(_stepValidationError!),
                          const SizedBox(height: 14),
                        ] else if (provider.hasError && providerErr != null) ...[
                          _buildErrorBanner(providerErr),
                          const SizedBox(height: 14),
                        ],
                        if (_currentStep == 0) _buildStep1(isAr),
                        if (_currentStep == 1) _buildStep2(context, provider, isAr),
                        if (_currentStep == 2) _buildStep3(isAr),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: AppColors.borderDisabled)),
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          flex: 2,
                          child: MashwarButton(
                            key: const ValueKey('create_back_btn'),
                            text: isAr ? 'السابق' : 'Back',
                            variant: MashwarButtonVariant.secondary,
                            onPressed: () {
                              setState(() {
                                _stepValidationError = null;
                                _currentStep--;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 3,
                        child: _currentStep < 2
                            ? MashwarButton(
                                key: const ValueKey('create_next_btn'),
                                text: isAr ? 'التالي' : 'Next Step',
                                onPressed: () => _handleNext(isAr),
                              )
                            : MashwarButton(
                                key: const ValueKey('create_publish_btn'),
                                text: isAr
                                    ? 'نشر طلب التوريد'
                                    : 'Publish Supply Request',
                                isLoading: provider.isSubmitting,
                                onPressed: () =>
                                    _handlePublish(context, provider, isAr),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      key: const ValueKey('create_request_error_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel(
            isAr ? 'فئة التوريد' : 'Supply Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _supplyCategories.map((cat) {
            final selected = _selectedCategory == cat.$1;
            return ChoiceChip(
              label: Text(isAr ? cat.$2 : cat.$3),
              avatar: Icon(
                cat.$4,
                size: 16,
                color: selected ? Colors.white : AppColors.navy,
              ),
              selected: selected,
              selectedColor: AppColors.navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
              onSelected: (_) => setState(() => _selectedCategory = cat.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        _buildFieldLabel(isAr
            ? 'عنوان طلب التوريد *'
            : 'Supply Request Title *'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step1_title'),
          controller: _titleController,
          decoration: InputDecoration(
            hintText: isAr
                ? 'مثال: قواطع كهربائية 32A ووصلات نحاسية'
                : 'e.g. 12x 32A Circuit Breakers & Copper Fittings',
          ),
          onChanged: (_) {
            if (_stepValidationError != null) {
              setState(() => _stepValidationError = null);
            }
          },
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(isAr
            ? 'وصف المواد والمواصفات الفنية *'
            : 'Item Description & Specifications *'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step1_desc'),
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isAr
                ? 'اذكر الماركة أو المقاس أو رقم القطعة المطلوب بدقة...'
                : 'Specify brand, dimensions, part numbers, or quality requirements...',
          ),
          onChanged: (_) {
            if (_stepValidationError != null) {
              setState(() => _stepValidationError = null);
            }
          },
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isAr ? 'الكمية *' : 'Quantity *'),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('create_step1_qty'),
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: '1'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isAr ? 'الوحدة' : 'Unit'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    isExpanded: true,
                    items: _units
                        .map(
                          (u) => DropdownMenuItem<String>(
                            value: u.$1,
                            child: Text(isAr ? u.$2 : u.$3),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedUnit = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(isAr
            ? 'رابط صورة مرجعية للعينة / القطعة (اختياري)'
            : 'Reference Item Photo URL (Optional)'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step1_photo'),
          controller: _referencePhotoController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://...',
            prefixIcon:
                const Icon(Icons.photo_camera_back_outlined, color: AppColors.navy),
            suffixIcon: IconButton(
              tooltip: isAr ? 'إرفاق نموذج صورة' : 'Attach sample reference URL',
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.teal),
              onPressed: () {
                setState(() {
                  _referencePhotoController.text =
                      'https://storage.mashwar.qa/reference/site_item_spec.jpg';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context,
    WorksiteProvider provider,
    bool isAr,
  ) {
    final savedSites = provider.savedWorksites;
    final pickupPresets = isAr
        ? const [
            'المنطقة الصناعية - شارع 10',
            'طريق سلوى - مجمع مواد البناء',
            'المنطقة الصناعية - شارع 18',
          ]
        : const [
            'Industrial Area - Street 10',
            'Salwa Road - Building Materials Hub',
            'Industrial Area - Street 18',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Saved Worksites Picker
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.factory_outlined,
                          size: 18, color: AppColors.qatarMaroon),
                      const SizedBox(width: 6),
                      Text(
                        isAr
                            ? 'مواقع العمل المحفوظة'
                            : 'Saved Worksites',
                        style: AppTypography.body(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProviderProfileScreen(focusSavedWorksites: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt_outlined,
                        size: 15, color: AppColors.teal),
                    label: Text(
                      isAr ? 'إدارة المواقع' : 'Manage Sites',
                      style: AppTypography.label(color: AppColors.teal)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (savedSites.isEmpty)
                Text(
                  isAr
                      ? 'لا توجد مواقع محفوظة بعد. يمكنك إدخال العنوان أدناه أو حفظ مواقعك المتكررة من ملفك.'
                      : 'No saved worksites yet. Enter the delivery address below or save frequent sites in your profile.',
                  style: AppTypography.bodySmall(),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: savedSites.map((site) {
                    final isSelected = _selectedSavedWorksiteId == site.id;
                    return ChoiceChip(
                      key: ValueKey('saved_site_chip_${site.id}'),
                      label: Text(
                        '${site.label} (${AppStrings.translateCity(site.municipality, isArabic: isAr)})',
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.teal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                      onSelected: (_) => _applySavedWorksite(site),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        _buildFieldLabel(isAr
            ? 'متجر أو نقطة الاستلام (المورّد) *'
            : 'Pickup Store / Supplier Location *'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step2_pickup'),
          controller: _pickupController,
          decoration: InputDecoration(
            hintText: isAr
                ? 'مثال: المنطقة الصناعية - شارع 10، مستودع الكهرباء'
                : 'e.g. Industrial Area - St 10 Electrical Supply',
            prefixIcon: const Icon(Icons.storefront_outlined,
                color: AppColors.teal),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: pickupPresets
              .map(
                (preset) => InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _pickupController.text = preset),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDisabled),
                    ),
                    child: Text(
                      preset,
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontSize: 11),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(isAr
            ? 'المنطقة / البلدية في قطر *'
            : 'Qatar Area / Municipality *'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const ValueKey('create_step2_area'),
          initialValue: _selectedArea,
          isExpanded: true,
          items: _qatarAreasAr
              .map(
                (area) => DropdownMenuItem<String>(
                  value: area,
                  child: Text(
                    AppStrings.translateCity(area, isArabic: isAr),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedArea = v);
          },
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(isAr
            ? 'عنوان موقع العمل للتسليم *'
            : 'Delivery Worksite Address *'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step2_dropoff'),
          controller: _dropoffController,
          decoration: InputDecoration(
            hintText: isAr
                ? 'مثال: مشروع مارينا لوسيل - بوابة المقاولين رقم 3'
                : 'e.g. Lusail Marina Plot 42 - Contractors Gate 3',
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: AppColors.qatarMaroon),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isAr
                      ? 'مسؤول الاستلام بالموقع'
                      : 'Site Contact Name'),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('create_step2_contact_name'),
                    controller: _siteContactNameController,
                    decoration: InputDecoration(
                      hintText: isAr ? 'م. فهد' : 'Eng. Fahad',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isAr
                      ? 'جوال الموقع (+974)'
                      : 'Site Phone (+974)'),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('create_step2_contact_phone'),
                    controller: _siteContactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '55112233',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3(bool isAr) {
    MoneyMinor? previewItems;
    MoneyMinor? previewFee;
    try {
      previewItems = MoneyMinor.fromDecimalString(
          _estimatedItemsQarController.text.trim());
    } catch (_) {}
    try {
      previewFee =
          MoneyMinor.fromDecimalString(_deliveryFeeQarController.text.trim());
    } catch (_) {}
    final totalPreview =
        (previewItems ?? const MoneyMinor.zero()) +
            (previewFee ?? const MoneyMinor.zero());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel(isAr
            ? 'الموعد النهائي المطلوب للتسليم *'
            : 'Requested Delivery Deadline *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(4, (idx) {
            final selected = _deadlinePresetIndex == idx;
            return ChoiceChip(
              key: ValueKey('deadline_chip_$idx'),
              label: Text(_deadlineLabel(isAr, idx)),
              selected: selected,
              selectedColor: AppColors.navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
              onSelected: (_) => setState(() => _deadlinePresetIndex = idx),
            );
          }),
        ),
        const SizedBox(height: 18),

        _buildFieldLabel(isAr
            ? 'التكلفة التقديرية للمشتريات (QAR) *'
            : 'Estimated Items Cost (QAR) *'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step3_items_qar'),
          controller: _estimatedItemsQarController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '180',
            suffixText: isAr ? 'ر.ق' : 'QAR',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isAr
                      ? 'سقف الفاتورة الأقصى (QAR)'
                      : 'Max Receipt Cap (QAR)'),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('create_step3_cap_qar'),
                    controller: _maxCapQarController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '220',
                      suffixText: isAr ? 'ر.ق' : 'QAR',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isAr
                      ? 'ميزانية التوصيل (QAR) *'
                      : 'Delivery Fee Budget (QAR) *'),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('create_step3_fee_qar'),
                    controller: _deliveryFeeQarController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '45',
                      suffixText: isAr ? 'ر.ق' : 'QAR',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: AppColors.teal,
          title: Text(
            isAr
                ? 'إلزام المنفّذ بإرفاق صورة فاتورة الشراء الأصلية'
                : 'Require original store purchase receipt photo',
            style: AppTypography.bodySecondary(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          value: _requiresPurchaseReceipt,
          onChanged: (v) => setState(() => _requiresPurchaseReceipt = v),
        ),
        const SizedBox(height: 12),

        _buildFieldLabel(isAr
            ? 'طريقة السداد (المرحلة التجريبية قطر)'
            : 'Pilot Payment Method (Qatar)'),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          method: PaymentMethod.cashOnDelivery,
          icon: Icons.payments_outlined,
          title: PaymentMethod.cashOnDelivery.label(isArabic: isAr),
          subtitle: isAr
              ? 'تسوية نقدية مباشرة عند التسليم والتحقق من الفاتورة بالموقع.'
              : 'Settle in QAR cash upon delivery and receipt check at worksite.',
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          method: PaymentMethod.bankTransferManual,
          icon: Icons.receipt_long_outlined,
          title: PaymentMethod.bankTransferManual.label(isArabic: isAr),
          subtitle: isAr
              ? 'تحويل بنكي يدوي / فوراً مع إرفاق إيصال التحويل للتوثيق.'
              : 'Manual bank transfer / Fawran with uploaded transfer proof.',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.slateBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Text(
            AppEnvironment.paymentsEscrowNotice(isArabic: isAr),
            style: AppTypography.bodySmall(),
          ),
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(isAr
            ? 'تعليمات إضافية للمنفّذ / تصريح البوابة'
            : 'Additional Instructions / Gate Access'),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('create_step3_notes'),
          controller: _instructionsController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: isAr
                ? 'مثال: الاتصال قبل الوصول بـ 10 دقائق لتجهيز تصريح الدخول...'
                : 'e.g. Call site supervisor 10 mins prior for gate pass...',
          ),
        ),
        const SizedBox(height: 18),

        // Review Summary Card
        Container(
          key: const ValueKey('create_step3_review_card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined,
                      color: AppColors.teal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr ? 'ملخص المراجعة قبل النشر' : 'Review Before Publishing',
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18, color: AppColors.borderDisabled),
              _buildSummaryRow(
                isAr ? 'الطلب' : 'Item',
                '${_titleController.text.trim()} (${_quantityController.text.trim()} $_selectedUnit)',
              ),
              const SizedBox(height: 6),
              _buildSummaryRow(
                isAr ? 'المسار' : 'Route',
                '${_pickupController.text.trim()} → ${_dropoffController.text.trim()} (${AppStrings.translateCity(_selectedArea, isArabic: isAr)})',
              ),
              const SizedBox(height: 6),
              _buildSummaryRow(
                isAr ? 'الموعد المطلوب' : 'Deadline',
                _deadlineLabel(isAr, _deadlinePresetIndex),
              ),
              const SizedBox(height: 6),
              _buildSummaryRow(
                isAr ? 'السداد' : 'Payment',
                _paymentMethod.label(isArabic: isAr),
              ),
              const Divider(height: 18, color: AppColors.borderDisabled),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    isAr
                        ? 'الإجمالي التقديري (مشتريات + توصيل)'
                        : 'Estimated Total (Items + Delivery)',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                  Text(
                    totalPreview.format(isArabic: isAr),
                    style: AppTypography.title(color: AppColors.teal)
                        .copyWith(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _paymentMethod == method;
    return InkWell(
      key: ValueKey('payment_method_${method.value}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.borderDisabled,
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppColors.teal : AppColors.navy, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall()),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.teal : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AppTypography.label(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySecondary(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTypography.label(color: AppColors.navy)
          .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
    );
  }
}
