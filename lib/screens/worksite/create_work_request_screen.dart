import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/worksite_models.dart';
import '../../data/services/media_upload_service.dart';
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

class _WorksiteQuickTemplate {
  final String id;
  final String category;
  final String shortLabelAr;
  final String shortLabelEn;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;
  final String unit;
  final String qty;
  final String pickupAr;
  final String pickupEn;
  final String estimatedItemsQar;
  final String maxCapQar;
  final String deliveryFeeQar;

  const _WorksiteQuickTemplate({
    required this.id,
    required this.category,
    required this.shortLabelAr,
    required this.shortLabelEn,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
    required this.unit,
    required this.qty,
    required this.pickupAr,
    required this.pickupEn,
    required this.estimatedItemsQar,
    required this.maxCapQar,
    required this.deliveryFeeQar,
  });
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

  static const List<_WorksiteQuickTemplate> _quickTemplates = [
    _WorksiteQuickTemplate(
      id: 'electrical_breakers',
      category: 'electrical',
      shortLabelAr: 'قواطع وكابلات 32A',
      shortLabelEn: '32A Breakers & Cable',
      titleAr: 'قواطع كهربائية 32A وكابلات نحاس 4مم',
      titleEn: '12x 32A Circuit Breakers & 4mm Copper Cable',
      descAr:
          '12 قاطع كهربائي 32A معتمد (كهرماء) + لفة كابل نحاس 4مم مقاوم للحرارة للموقع.',
      descEn:
          '12x Kahramaa-approved 32A MCB breakers + 1x 4mm heat-resistant copper cable coil.',
      unit: 'set',
      qty: '12',
      pickupAr: 'المنطقة الصناعية - شارع 10، مستودع مستلزمات الكهرباء',
      pickupEn: 'Industrial Area - St 10 Electrical Supply Depot',
      estimatedItemsQar: '420',
      maxCapQar: '480',
      deliveryFeeQar: '55',
    ),
    _WorksiteQuickTemplate(
      id: 'plumbing_ppr',
      category: 'plumbing',
      shortLabelAr: 'محابس نحاس وPPR',
      shortLabelEn: 'Brass Valves & PPR',
      titleAr: 'محابس نحاس 32مم ومواسير PPR PN20',
      titleEn: 'Brass Ball Valves 32mm & PPR PN20 Pipes',
      descAr:
          '8 محابس نحاس أصلية مقاس 32مم + 10 مواسير PPR PN20 مع وصلات لحام ومادة غراء.',
      descEn:
          '8x heavy-duty 32mm brass shutoff valves + 10x PPR PN20 pipes with elbow fittings.',
      unit: 'pcs',
      qty: '18',
      pickupAr: 'طريق سلوى - مجمع مواد السباكة والصحية',
      pickupEn: 'Salwa Road - Plumbing & Sanitary Materials Hub',
      estimatedItemsQar: '340',
      maxCapQar: '400',
      deliveryFeeQar: '50',
    ),
    _WorksiteQuickTemplate(
      id: 'hilti_anchors',
      category: 'tools',
      shortLabelAr: 'مثبتات هيلتي وريش',
      shortLabelEn: 'Hilti Anchors & Bits',
      titleAr: 'مثبتات هيلتي M12 وريش تخريم SDS-Plus',
      titleEn: 'Hilti M12 Concrete Anchors & SDS-Plus Bits',
      descAr:
          'علبتان مسامير تثبيت خرسانية Hilti M12 + طقم ريش تخريم SDS-Plus مقاسات 10-16مم.',
      descEn:
          '2 boxes Hilti M12 heavy-duty wedge anchors + SDS-Plus masonry drill bit set (10-16mm).',
      unit: 'carton',
      qty: '2',
      pickupAr: 'المنطقة الصناعية - شارع 18، مركز المعدات والعدد',
      pickupEn: 'Industrial Area - St 18 Hilti & Tools Center',
      estimatedItemsQar: '290',
      maxCapQar: '330',
      deliveryFeeQar: '45',
    ),
    _WorksiteQuickTemplate(
      id: 'safety_ppe',
      category: 'safety_ppe',
      shortLabelAr: 'طقم سلامة PPE',
      shortLabelEn: 'Safety PPE Kit',
      titleAr: 'طقم سلامة مهنية PPE (خوذات وسترات وأحذية)',
      titleEn: 'Worksite Safety PPE Kit (Helmets, Vests & Gloves)',
      descAr:
          '10 خوذات سلامة معيار EN397 + 10 سترات عاكسة عالية الوضوح + قفازات ونظارات حماية.',
      descEn:
          '10x EN397 safety helmets + 10x hi-vis reflective vests + protective gloves & goggles.',
      unit: 'set',
      qty: '10',
      pickupAr: 'طريق سلوى - معرض تجهيزات السلامة المهنية',
      pickupEn: 'Salwa Road - Industrial Safety & PPE Warehouse',
      estimatedItemsQar: '520',
      maxCapQar: '580',
      deliveryFeeQar: '60',
    ),
  ];

  static const String _otherAreaValue = '__other_area__';

  static const List<(String, String, String)> _units = [
    ('pcs', 'قطعة', 'pcs'),
    ('carton', 'كرتون', 'carton'),
    ('roll', 'لفة', 'roll'),
    ('set', 'طقم', 'set'),
    ('bag', 'كيس', 'bag'),
    ('meter', 'متر', 'meter'),
    ('other', 'أخرى (حدد الوحدة)', 'Other (Specify)'),
  ];

  int _currentStep = 0; // 0, 1, 2
  String? _selectedTemplateId;

  // Step 1 controllers & state
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _referencePhotoController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _customUnitController;
  String _selectedCategory = 'general_site_supply';
  String _selectedUnit = 'pcs';

  // Step 2 controllers & state
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  late final TextEditingController _siteContactNameController;
  late final TextEditingController _siteContactPhoneController;
  late final TextEditingController _customAreaController;
  String _selectedArea = 'لوسيل';
  String? _selectedSavedWorksiteId;

  // Step 3 controllers & state
  late final TextEditingController _estimatedItemsQarController;
  late final TextEditingController _maxCapQarController;
  late final TextEditingController _deliveryFeeQarController;
  late final TextEditingController _instructionsController;
  int _deadlinePresetIndex = 0; // 0: +2h, 1: +4h, 2: tomorrow 8am, 3: +24h, 4: custom
  DateTime? _customDeadlineLocal;
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _requiresPurchaseReceipt = true;

  String? _stepValidationError;
  bool _isUploadingReferencePhoto = false;
  MediaUploadResult? _uploadedReferencePhoto;
  String? _referenceUploadError;
  late final String _draftUploadSessionId =
      'draft_${DateTime.now().toUtc().millisecondsSinceEpoch}';
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
    _customCategoryController = TextEditingController();
    _customUnitController = TextEditingController();
    _customAreaController = TextEditingController();

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
    _customCategoryController.dispose();
    _customUnitController.dispose();
    _customAreaController.dispose();
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
    if (_deadlinePresetIndex == 4 && _customDeadlineLocal != null) {
      return _customDeadlineLocal!.toUtc();
    }
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

  String _formatCustomDeadline(DateTime dt, bool isAr) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return isAr
        ? '${dt.day}/${dt.month} · $hh:$mm'
        : '${dt.month}/${dt.day} · $hh:$mm';
  }

  String _deadlineLabel(bool isAr, int index) {
    switch (index) {
      case 0:
        return isAr ? 'عاجل (خلال ساعتين)' : 'Urgent (Within 2 hrs)';
      case 1:
        return isAr ? 'اليوم (خلال 4 ساعات)' : 'Today (Within 4 hrs)';
      case 2:
        return isAr ? 'غداً 8:00 صباحاً' : 'Tomorrow 8:00 AM';
      case 4:
        if (_customDeadlineLocal != null) {
          return _formatCustomDeadline(_customDeadlineLocal!, isAr);
        }
        return isAr ? 'موعد مخصص' : 'Custom Date & Time';
      case 3:
      default:
        return isAr ? 'خلال 24 ساعة' : 'Within 24 hours';
    }
  }

  Future<void> _pickCustomDeadline(BuildContext context, bool isAr) async {
    final nowLocal = DateTime.now();
    final initial = _customDeadlineLocal ?? nowLocal.add(const Duration(hours: 6));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(nowLocal) ? nowLocal : initial,
      firstDate: DateTime(nowLocal.year, nowLocal.month, nowLocal.day),
      lastDate: nowLocal.add(const Duration(days: 60)),
      helpText: isAr ? 'اختر يوم التسليم المطلوب' : 'Select Delivery Date',
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: isAr ? 'اختر وقت التسليم' : 'Select Delivery Time',
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      _customDeadlineLocal = combined;
      _deadlinePresetIndex = 4;
      _stepValidationError = null;
    });
  }

  void _applyQuickTemplate(_WorksiteQuickTemplate tpl, bool isAr) {
    setState(() {
      _selectedTemplateId = tpl.id;
      _selectedCategory = tpl.category;
      _titleController.text = isAr ? tpl.titleAr : tpl.titleEn;
      _descriptionController.text = isAr ? tpl.descAr : tpl.descEn;
      _selectedUnit = tpl.unit;
      _quantityController.text = tpl.qty;
      _pickupController.text = isAr ? tpl.pickupAr : tpl.pickupEn;
      _estimatedItemsQarController.text = tpl.estimatedItemsQar;
      _maxCapQarController.text = tpl.maxCapQar;
      _deliveryFeeQarController.text = tpl.deliveryFeeQar;
      _stepValidationError = null;
    });
  }

  MoneyMinor? _tryParseQar(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    try {
      return MoneyMinor.fromDecimalString(clean);
    } catch (_) {
      return null;
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

      if (_selectedCategory == 'other' &&
          _customCategoryController.text.trim().length < 2) {
        return isAr
            ? 'يرجى كتابة نوع الخدمة أو الفئة المخصصة.'
            : 'Please specify your custom service or supply category.';
      }
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
      if (_selectedUnit == 'other' &&
          _customUnitController.text.trim().isEmpty) {
        return isAr
            ? 'يرجى تحديد الوحدة المخصصة (مثل: صندوق، طن، لتر).'
            : 'Please specify the custom unit (e.g., box, ton, liter).';
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
      if (_selectedArea == _otherAreaValue &&
          _customAreaController.text.trim().length < 2) {
        return isAr
            ? 'يرجى كتابة اسم المنطقة أو الموقع المخصص.'
            : 'Please specify the custom area / municipality.';
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
    final resolvedUnit = _selectedUnit == 'other' &&
            _customUnitController.text.trim().isNotEmpty
        ? _customUnitController.text.trim()
        : unitTuple.$3;
    final customCat = _customCategoryController.text.trim();
    final resolvedMunicipality = _selectedArea == _otherAreaValue &&
            _customAreaController.text.trim().isNotEmpty
        ? _customAreaController.text.trim()
        : _selectedArea;
    final photoUrl = _referencePhotoController.text.trim();
    final extraNotes = _instructionsController.text.trim();

    final combinedNotesParts = <String>[
      if (_selectedCategory == 'other' && customCat.isNotEmpty)
        'CustomCategory: $customCat',
      'Qty: $qty $resolvedUnit',
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
      municipality: resolvedMunicipality,
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
          isAr ? 'إنشاء طلب توريد موقع' : 'Create Supply Request',
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.03, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey<int>(_currentStep),
                            child: _currentStep == 0
                                ? _buildStep1(isAr)
                                : (_currentStep == 1
                                    ? _buildStep2(context, provider, isAr)
                                    : _buildStep3(isAr)),
                          ),
                        ),
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
        // 1-Tap Quick Templates Strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded,
                      size: 17, color: AppColors.qatarMaroon),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'قوالب تعبئة فورية لمواقع قطر (ضغطة واحدة)'
                          : '1-Tap Qatar Construction Templates',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickTemplates.map((tpl) {
                    final selected = _selectedTemplateId == tpl.id;
                    final meta = mashwarCategoryMetaFor(tpl.category);
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: MashwarHoverCard(
                        key: ValueKey('create_quick_template_${tpl.id}'),
                        borderRadius: BorderRadius.circular(12),
                        backgroundColor:
                            selected ? meta.surfaceColor : Colors.white,
                        borderColor: selected
                            ? meta.accentColor
                            : AppColors.borderDisabled,
                        hoverBorderColor: meta.accentColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        onTap: () => _applyQuickTemplate(tpl, isAr),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MashwarCategoryIcon(
                              category: tpl.category,
                              size: 28,
                              showSurface: true,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isAr ? tpl.shortLabelAr : tpl.shortLabelEn,
                                  style: AppTypography.label(
                                          color: AppColors.navy)
                                      .copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                                Text(
                                  isAr
                                      ? '${tpl.estimatedItemsQar}+${tpl.deliveryFeeQar} ر.ق'
                                      : '${tpl.estimatedItemsQar}+${tpl.deliveryFeeQar} QAR',
                                  style: AppTypography.label(
                                          color: AppColors.teal)
                                      .copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(isAr ? 'فئة التوريد' : 'Supply Category'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final colCount = constraints.maxWidth >= 560 ? 3 : 2;
            const spacing = 8.0;
            final cardWidth =
                (constraints.maxWidth - (spacing * (colCount - 1))) / colCount;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: mashwarWorksiteCategories.map((meta) {
                final selected = _selectedCategory == meta.id;
                return SizedBox(
                  width: cardWidth,
                  child: MashwarHoverCard(
                    key: ValueKey('create_category_${meta.id}'),
                    borderRadius: BorderRadius.circular(14),
                    backgroundColor:
                        selected ? meta.surfaceColor : Colors.white,
                    borderColor: selected
                        ? meta.accentColor
                        : AppColors.borderDisabled,
                    hoverBorderColor: meta.accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    onTap: () => setState(() => _selectedCategory = meta.id),
                    child: Row(
                      children: [
                        MashwarCategoryIcon(
                          category: meta.id,
                          size: 32,
                          showSurface: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meta.title(isArabic: isAr),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 11.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: meta.accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (_selectedCategory == 'other') ...[
          const SizedBox(height: 12),
          _buildFieldLabel(isAr
              ? 'حدد نوع الخدمة أو التوريد المخصص *'
              : 'Specify Custom Service / Category *'),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('create_custom_category_input'),
            controller: _customCategoryController,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'مثال: صيانة تكييف، مستلزمات زراعية، قطع غيار مولدات...'
                  : 'e.g. HVAC spares, landscape materials, generator parts...',
              prefixIcon: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.cobalt,
              ),
            ),
            onChanged: (_) {
              if (_stepValidationError != null) {
                setState(() => _stepValidationError = null);
              }
            },
          ),
        ],
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
                    onChanged: (_) {
                      if (_stepValidationError != null) {
                        setState(() => _stepValidationError = null);
                      }
                    },
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
                    key: const ValueKey('create_step1_unit_dropdown'),
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
        if (_selectedUnit == 'other') ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('create_custom_unit_input'),
            controller: _customUnitController,
            decoration: InputDecoration(
              labelText: isAr ? 'اكتب الوحدة المخصصة *' : 'Custom Unit *',
              hintText: isAr
                  ? 'مثال: لتر، طن، صندوق خشبي، عبوة...'
                  : 'e.g. liter, ton, crate, pack...',
            ),
            onChanged: (_) {
              if (_stepValidationError != null) {
                setState(() => _stepValidationError = null);
              }
            },
          ),
        ],
        const SizedBox(height: 16),

        _buildFieldLabel(isAr
            ? 'صورة مرجعية للعينة / القطعة (اختياري · حتى 10MB)'
            : 'Reference Item Photo (Optional · Max 10 MB)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('upload_reference_photo_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.teal),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onPressed: _isUploadingReferencePhoto
                    ? null
                    : () => _handlePickReferencePhoto(
                          ImageSource.gallery,
                          isAr,
                        ),
                icon: _isUploadingReferencePhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.teal,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined,
                        size: 18, color: AppColors.teal),
                label: Text(
                  _isUploadingReferencePhoto
                      ? (isAr ? 'جاري رفع الصورة...' : 'Uploading photo...')
                      : (isAr ? 'رفع صورة مرجعية' : 'Upload Reference Photo'),
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('capture_reference_photo_btn'),
              tooltip: isAr ? 'التقاط بالكاميرا' : 'Take Photo',
              icon: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.navy),
              onPressed: _isUploadingReferencePhoto
                  ? null
                  : () => _handlePickReferencePhoto(ImageSource.camera, isAr),
            ),
          ],
        ),
        if (_uploadedReferencePhoto != null) ...[
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('reference_photo_uploaded_pill'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.tealSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _uploadedReferencePhoto!.bytes,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.white,
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.teal, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uploadedReferencePhoto!.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${_uploadedReferencePhoto!.formattedSize} · ${_uploadedReferencePhoto!.mimeType}',
                        style: AppTypography.label(
                                color: AppColors.textSecondary)
                            .copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.navy),
                  tooltip: isAr ? 'إزالة الصورة' : 'Remove photo',
                  onPressed: () {
                    setState(() {
                      _uploadedReferencePhoto = null;
                      _referencePhotoController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        if (_referenceUploadError != null) ...[
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('reference_photo_upload_error'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: Text(
              _referenceUploadError!,
              style: AppTypography.label(color: AppColors.danger)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('create_step1_photo'),
          controller: _referencePhotoController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: isAr
                ? 'أو الصق رابط الصورة المرجعية (https://...)'
                : 'Or paste uploaded reference URL (https://...)',
            prefixIcon: const Icon(Icons.photo_camera_back_outlined,
                color: AppColors.navy),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePickReferencePhoto(
    ImageSource source,
    bool isAr,
  ) async {
    final auth = context.read<AuthProvider?>();
    setState(() {
      _isUploadingReferencePhoto = true;
      _referenceUploadError = null;
    });
    try {
      final uploaded =
          await MediaUploadService.instance.pickAndUploadWorkRequestReference(
        requestId: widget.initialDraft?.sourceRequestId ?? _draftUploadSessionId,
        source: source,
        allowDevMocks: auth?.isDevMockAuthEnabled ?? false,
      );
      if (!mounted) return;
      setState(() {
        _isUploadingReferencePhoto = false;
        if (uploaded != null) {
          _uploadedReferencePhoto = uploaded;
          _referencePhotoController.text = uploaded.downloadUrl;
          _stepValidationError = null;
        }
      });
    } on MediaUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingReferencePhoto = false;
        _referenceUploadError = e.localizedMessage(isArabic: isAr);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingReferencePhoto = false;
        _referenceUploadError = isAr
            ? 'تعذّر رفع الصورة المرجعية: $e'
            : 'Failed to upload reference image: $e';
      });
    }
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
          items: [
            ..._qatarAreasAr.map(
              (area) => DropdownMenuItem<String>(
                value: area,
                child: Text(
                  AppStrings.translateCity(area, isArabic: isAr),
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: _otherAreaValue,
              child: Text(
                isAr ? 'أخرى (حدد المنطقة بنفسك)' : 'Other (Specify Area)',
                style: const TextStyle(
                  color: AppColors.cobalt,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _selectedArea = v);
          },
        ),
        if (_selectedArea == _otherAreaValue) ...[
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('create_custom_area_input'),
            controller: _customAreaController,
            decoration: InputDecoration(
              labelText: isAr
                  ? 'اكتب اسم المنطقة أو المشروع *'
                  : 'Specify Custom Area / Project *',
              hintText: isAr
                  ? 'مثال: ميناء حمد، سيلين، طريق الشمال...'
                  : 'e.g. Hamad Port, Sealine, Al Shamal Road...',
              prefixIcon: const Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.cobalt,
              ),
            ),
            onChanged: (_) {
              if (_stepValidationError != null) {
                setState(() => _stepValidationError = null);
              }
            },
          ),
        ],
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
    final previewItems = _tryParseQar(_estimatedItemsQarController.text);
    final previewCap = _tryParseQar(_maxCapQarController.text);
    final previewFee = _tryParseQar(_deliveryFeeQarController.text);
    final effectiveItems = previewItems ?? const MoneyMinor.zero();
    final effectiveCap = previewCap ?? effectiveItems;
    final effectiveFee = previewFee ?? const MoneyMinor.zero();
    final totalPreview = effectiveItems + effectiveFee;
    final maxTotalWithCap = effectiveCap + effectiveFee;
    final capBufferMinor = effectiveCap.minorUnits - effectiveItems.minorUnits;
    final hasValidCap = capBufferMinor >= 0;

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
          children: [
            ...List.generate(4, (idx) {
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
            ChoiceChip(
              key: const ValueKey('deadline_chip_custom'),
              avatar: Icon(
                Icons.event_available_rounded,
                size: 16,
                color: _deadlinePresetIndex == 4
                    ? Colors.white
                    : AppColors.teal,
              ),
              label: Text(
                _deadlinePresetIndex == 4 && _customDeadlineLocal != null
                    ? _formatCustomDeadline(_customDeadlineLocal!, isAr)
                    : (isAr ? 'تحديد تاريخ ووقت' : 'Custom Date & Time'),
              ),
              selected: _deadlinePresetIndex == 4,
              selectedColor: AppColors.teal,
              backgroundColor: AppColors.tealSurface,
              labelStyle: TextStyle(
                color:
                    _deadlinePresetIndex == 4 ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
              onSelected: (_) => _pickCustomDeadline(context, isAr),
            ),
          ],
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
                    onChanged: (_) => setState(() {}),
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
        const SizedBox(height: 14),

        // Live QAR Cost Breakdown & Receipt Cap Summary Card
        Container(
          key: const ValueKey('create_live_cost_summary'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasValidCap
                  ? AppColors.gold.withValues(alpha: 0.45)
                  : AppColors.danger.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: hasValidCap ? AppColors.navy : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'ملخص التكلفة وسقف الفاتورة المباشر'
                          : 'Live QAR Cost & Receipt Cap Breakdown',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCostLine(
                isAr ? 'تقدير المشتريات' : 'Estimated Items',
                effectiveItems.format(isArabic: isAr),
              ),
              const SizedBox(height: 4),
              _buildCostLine(
                isAr ? 'هامش سقف الفاتورة' : 'Receipt Cap Buffer',
                hasValidCap
                    ? '+${MoneyMinor(capBufferMinor).format(isArabic: isAr)}'
                    : (isAr
                        ? 'أقل من التكلفة التقديرية'
                        : 'Below estimated cost'),
                valueColor: hasValidCap ? AppColors.teal : AppColors.danger,
              ),
              const SizedBox(height: 4),
              _buildCostLine(
                isAr ? 'سقف الفاتورة المعتمد' : 'Max Receipt Cap',
                effectiveCap.format(isArabic: isAr),
              ),
              const SizedBox(height: 4),
              _buildCostLine(
                isAr ? 'رسوم التوصيل والتوريد' : 'Delivery Fee Budget',
                effectiveFee.format(isArabic: isAr),
              ),
              const Divider(height: 14, color: AppColors.borderDisabled),
              _buildCostLine(
                isAr ? 'الإجمالي التقديري' : 'Est. Total Outlay',
                totalPreview.format(isArabic: isAr),
                valueColor: AppColors.teal,
                bold: true,
              ),
              const SizedBox(height: 3),
              _buildCostLine(
                isAr ? 'الحد الأقصى مع السقف' : 'Worst-Case Total (w/ Cap)',
                maxTotalWithCap.format(isArabic: isAr),
                valueColor: AppColors.navy,
                bold: true,
              ),
            ],
          ),
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

  Widget _buildCostLine(
    String label,
    String value, {
    Color valueColor = AppColors.navy,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.label(color: AppColors.textSecondary).copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 12.5 : 11.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.label(color: valueColor).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: bold ? 13 : 12,
          ),
        ),
      ],
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
