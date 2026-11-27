import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/board_ad_model.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';
import '../../state/board_provider.dart';
import '../home/city_search_modal.dart';
import 'board_extra_screens.dart';

class PostAdScreen extends StatefulWidget {
  final bool initialIsOffer;
  final BoardAdType? initialCategory;
  final int? initialIntent;
  final int? initialPresetIndex;

  const PostAdScreen({
    super.key,
    this.initialIsOffer = false,
    this.initialCategory,
    this.initialIntent,
    this.initialPresetIndex,
  });

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  late BoardAdType _selectedCategory;
  int _intentIndex = 0; // 0 = Request, 1 = Offer / Traveler
  int _visualStep = 1; // 1..3 visual progress indicator
  bool _isSubmitted = false;
  bool _didApplyInitialPreset = false;
  String? _formError;
  double _swapTurns = 0.0;

  // Form Controllers
  final TextEditingController _fromController =
      TextEditingController(text: 'الدوحة');
  final TextEditingController _toController =
      TextEditingController(text: 'الخور');
  final TextEditingController _timeController =
      TextEditingController(text: 'الجمعة بعد الظهر');
  final TextEditingController _seatsController =
      TextEditingController(text: '3');
  final TextEditingController _priceController =
      TextEditingController(text: '35');
  final TextEditingController _parcelDescController =
      TextEditingController(text: 'أوراق ومستندات رسمية');
  final TextEditingController _weightController =
      TextEditingController(text: '2');
  final TextEditingController _errandDescController = TextEditingController();
  final TextEditingController _goodsDescController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _itemBudgetController =
      TextEditingController(text: '150');
  final TextEditingController _customServiceController =
      TextEditingController();
  bool _isOtherCategory = false;
  bool _ladiesOnly = false;
  bool _acceptsParcels = true;
  bool _hasEscrowProtection = true;
  bool _requiresReceiptProof = false;
  int? _activePresetIndex;
  String? _subTagAr;
  String? _subTagEn;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      _intentIndex = widget.initialIntent ??
          (widget.initialCategory == BoardAdType.rideOffer ? 1 : 0);
    } else if (widget.initialIntent != null) {
      _intentIndex = widget.initialIntent!;
      _selectedCategory = _intentIndex == 1
          ? BoardAdType.rideOffer
          : BoardAdType.rideRequest;
    } else if (widget.initialIsOffer) {
      _selectedCategory = BoardAdType.rideOffer;
      _intentIndex = 1;
    } else {
      _selectedCategory = BoardAdType.rideRequest;
      _intentIndex = 0;
    }
    if (_selectedCategory == BoardAdType.parcelRequest ||
        _selectedCategory == BoardAdType.goodsDelivery) {
      _requiresReceiptProof = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didApplyInitialPreset && widget.initialPresetIndex != null) {
      _didApplyInitialPreset = true;
      _applyQuickPreset(widget.initialPresetIndex!, context.isArabic);
    }
  }

  void _applyQuickPreset(int index, bool isAr) {
    setState(() {
      _activePresetIndex = index;
      _isOtherCategory = false;
      _visualStep = 3;
      _formError = null;
      if (index == 0) {
        _intentIndex = 0;
        _selectedCategory = BoardAdType.goodsDelivery;
        _fromController.text = 'المنطقة الصناعية';
        _toController.text = 'لوسيل';
        _timeController.text = isAr ? 'الآن / فوري' : 'Now / Instant';
        _priceController.text = '45';
        _itemBudgetController.text = '180';
        _goodsDescController.text = isAr
            ? 'قواطع كهربائية ووصلات عاجلة لموقع مشروع هندسي من شارع 10'
            : 'Urgent electrical breakers & tools from Street 10 Industrial';
        _notesController.text = isAr
            ? 'مطلوب تصوير الفاتورة الأصلية من المحل واعتمادها قبل التحرك للموقع'
            : 'Requires original store receipt approval photo before dispatch';
        _requiresReceiptProof = true;
        _hasEscrowProtection = true;
        _ladiesOnly = false;
        _subTagAr = 'توريد موقع هندسي';
        _subTagEn = 'Site Supply';
      } else if (index == 1) {
        _intentIndex = 0;
        _selectedCategory = BoardAdType.localTrip;
        _fromController.text = 'أم صلال';
        _toController.text = 'الدوحة';
        _timeController.text = isAr ? 'صباحاً 7:15 ص' : 'Morning 7:15 AM';
        _priceController.text = '40';
        _seatsController.text = '2';
        _notesController.text = isAr
            ? 'توصيل أطفال صباحي للحضانة بسيارة عائلية موثقة'
            : 'Morning nursery drop-off with verified family car';
        _requiresReceiptProof = false;
        _hasEscrowProtection = true;
        _ladiesOnly = true;
        _subTagAr = 'توصيل حضانة ويومي';
        _subTagEn = 'Nursery & Daily';
      } else if (index == 2) {
        _intentIndex = 0;
        _selectedCategory = BoardAdType.errandService;
        _fromController.text = 'الدوحة';
        _toController.text = 'الخور';
        _timeController.text = isAr ? 'اليوم قبل الظهر' : 'Today Noon';
        _priceController.text = '50';
        _errandDescController.text = isAr
            ? 'جلب شهادة / مستند رسمي مختوم مع مسافر متجه للخور'
            : 'Collect stamped official document with traveler heading to Al Khor';
        _notesController.text = isAr
            ? 'تسليم يداً بيد بكود 4 أرقام OTP'
            : 'Delivered hand-to-hand with 4-digit OTP protection';
        _requiresReceiptProof = false;
        _hasEscrowProtection = true;
        _ladiesOnly = false;
        _subTagAr = 'جلب مستند مع مسافر';
        _subTagEn = 'Doc Fetch';
      } else if (index == 3) {
        _intentIndex = 0;
        _selectedCategory = BoardAdType.parcelRequest;
        _fromController.text = 'الدوحة';
        _toController.text = 'الريان';
        _timeController.text = isAr ? 'خلال ساعتين' : 'Within 2 hours';
        _priceController.text = '30';
        _itemBudgetController.text = '95';
        _parcelDescController.text = isAr
            ? 'شراء مستلزمات من المتجر وتوصيلها للريان'
            : 'Buy store items and deliver to Al Rayyan';
        _notesController.text = isAr
            ? 'الفاتورة محمية في ضمان مشوار حتى التسليم'
            : 'Purchases & fee held in MASHWAR Escrow until OTP confirmation';
        _requiresReceiptProof = true;
        _hasEscrowProtection = true;
        _ladiesOnly = false;
        _subTagAr = 'شراء وتوصيل بفاتورة';
        _subTagEn = 'Shop with Receipt';
      } else if (index == 4) {
        _intentIndex = 1;
        _selectedCategory = BoardAdType.rideOffer;
        _fromController.text = 'الخور';
        _toController.text = 'الدوحة';
        _timeController.text = isAr ? 'غداً صباحاً' : 'Tomorrow morning';
        _priceController.text = '35';
        _seatsController.text = '3';
        _acceptsParcels = true;
        _requiresReceiptProof = false;
        _hasEscrowProtection = true;
        _ladiesOnly = false;
        _notesController.text = isAr
            ? 'معي 3 مقاعد شاغرة بسيارتي الخاصة وأقبل أمانات بالطريق'
            : '3 empty seats available & can carry parcels along route';
        _subTagAr = '3 مقاعد شاغرة';
        _subTagEn = '3 Empty Seats';
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _parcelDescController.dispose();
    _weightController.dispose();
    _errandDescController.dispose();
    _goodsDescController.dispose();
    _notesController.dispose();
    _itemBudgetController.dispose();
    _customServiceController.dispose();
    super.dispose();
  }

  Future<void> _pickCity(TextEditingController controller, String title) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CitySearchModal(
          title: title,
          initialValue: controller.text.trim(),
        ),
      ),
    );
    if (selected != null && selected.trim().isNotEmpty && mounted) {
      setState(() {
        controller.text = selected;
        _visualStep = 2;
        _formError = null;
      });
    }
  }

  void _swapCities() {
    setState(() {
      _swapTurns += 0.5;
      _visualStep = 2;
      final tmp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tmp;
    });
  }

  void _adjustPrice(int delta) {
    final current = int.tryParse(_priceController.text.trim()) ?? 80;
    final next = (current + delta).clamp(5, 5000);
    setState(() {
      _visualStep = 3;
      _priceController.text = '$next';
    });
  }

  void _adjustSeats(int delta) {
    final current = int.tryParse(_seatsController.text.trim()) ?? 1;
    final next = (current + delta).clamp(1, 8);
    setState(() {
      _visualStep = 3;
      _seatsController.text = '$next';
    });
  }

  void _submit(bool isAr) {
    final fromCity = _fromController.text.trim();
    final toCity = _toController.text.trim();
    final timeText = _timeController.text.trim();
    final price = int.tryParse(_priceController.text.trim());

    if (_isOtherCategory && _customServiceController.text.trim().length < 2) {
      setState(() {
        _formError = isAr
            ? 'يرجى كتابة نوع الخدمة أو الطلب المخصص في حقل "أخرى"'
            : 'Please specify your custom service in the "Other" field';
      });
      return;
    }

    if (fromCity.isEmpty ||
        toCity.isEmpty ||
        timeText.isEmpty ||
        price == null ||
        price <= 0) {
      setState(() {
        _formError = isAr
            ? 'برجاء استكمال نقطة الانطلاق والوجهة والموعد والسعر بشكل صحيح'
            : 'Please fill in departure, destination, schedule, and a valid price';
      });
      return;
    }

    final board = context.read<BoardProvider>();
    final type = _selectedCategory;
    final seats = int.tryParse(_seatsController.text.trim()) ?? 1;
    final itemCost = _requiresReceiptProof
        ? int.tryParse(_itemBudgetController.text.trim())
        : null;

    String computedTimeText = timeText;
    String computedDesc;

    if (type == BoardAdType.parcelRequest) {
      computedTimeText = isAr
          ? '$timeText · ${_weightController.text.trim()} كجم'
          : '$timeText · ${_weightController.text.trim()} kg';
      computedDesc = isAr
          ? 'طلب/طرد: ${_parcelDescController.text.trim()} · المكافأة: $price ر.ق'
          : 'Parcel/Item: ${_parcelDescController.text.trim()} · Reward: $price QAR';
    } else if (type == BoardAdType.rideOffer) {
      computedTimeText = isAr
          ? '$timeText · $seats مقاعد شاغرة'
          : '$timeText · $seats empty seats';
      computedDesc = _acceptsParcels
          ? (isAr
              ? 'متاح مقاعد شاغرة وتوصيل أمانات أو طرود على الطريق'
              : 'Accepts seats & parcels along route')
          : (isAr
              ? 'رحلة سفر تشاركي مباشرة · السعر للمقعد $price ر.ق'
              : 'Direct ride · $price QAR per seat');
    } else if (type == BoardAdType.localTrip) {
      computedTimeText = isAr
          ? '$timeText · مشوار يومي وحضانات'
          : '$timeText · Daily / Nursery ride';
      computedDesc = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (isAr
              ? 'طلب توصيل ومشوار محلي موثق · الأجرة المقترحة: $price ر.ق'
              : 'Verified local/school commute · Proposed fare: $price QAR');
    } else if (type == BoardAdType.errandService) {
      final customSrv = _customServiceController.text.trim();
      computedTimeText = _isOtherCategory && customSrv.isNotEmpty
          ? '$timeText · $customSrv'
          : (isAr
              ? '$timeText · إنجاز معاملة أو جلب أوراق'
              : '$timeText · Doc & Errand');
      final errandText = _errandDescController.text.trim().isNotEmpty
          ? _errandDescController.text.trim()
          : (_isOtherCategory && customSrv.isNotEmpty
              ? customSrv
              : (isAr
                  ? 'جلب أوراق ومستندات رسمية بالطريق'
                  : 'Official documents & items along route'));
      computedDesc = isAr
          ? '${_isOtherCategory && customSrv.isNotEmpty ? "[$customSrv] " : ""}$errandText · أتعاب الخدمة: $price ر.ق'
          : '${_isOtherCategory && customSrv.isNotEmpty ? "[$customSrv] " : ""}$errandText · Service fee: $price QAR';
    } else if (type == BoardAdType.goodsDelivery) {
      computedTimeText = isAr
          ? '$timeText · توريد مواقع وبضائع'
          : '$timeText · Worksite & Cargo';
      final goodsText = _goodsDescController.text.trim().isNotEmpty
          ? _goodsDescController.text.trim()
          : (isAr
              ? 'توريد مستلزمات ومعدات لموقع العمل أو المحل'
              : 'Worksite supplies & store goods');
      computedDesc = isAr
          ? '$goodsText · الأجرة: $price ر.ق'
          : '$goodsText · Fare: $price QAR';
    } else {
      computedTimeText = isAr
          ? '$timeText · ${seats == 1 ? "مقعد واحد" : "$seats مقاعد"}'
          : '$timeText · $seats seat(s)';
      computedDesc = isAr
          ? 'طلب سفر تشاركي · الميزانية: حتى $price ر.ق للمقعد'
          : 'Ride request · Budget: up to $price QAR per seat';
    }

    board.postAd(
      type: type,
      fromCity: fromCity,
      toCity: toCity,
      timeText: computedTimeText,
      description: computedDesc,
      priceOrBudget: price,
      seatsNeeded:
          (type == BoardAdType.rideRequest || type == BoardAdType.rideOffer)
              ? seats
              : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isLadiesOnly: _ladiesOnly,
      serviceSubTagAr: _isOtherCategory &&
              _customServiceController.text.trim().isNotEmpty
          ? _customServiceController.text.trim()
          : _subTagAr,
      serviceSubTagEn: _isOtherCategory &&
              _customServiceController.text.trim().isNotEmpty
          ? _customServiceController.text.trim()
          : _subTagEn,
      hasEscrowProtection: _hasEscrowProtection,
      requiresReceiptProof: _requiresReceiptProof,
      estimatedItemCost: itemCost,
      isProviderOffer: _intentIndex == 1 || type == BoardAdType.rideOffer,
    );

    setState(() {
      _formError = null;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_isSubmitted) {
      return _buildSuccessScreen(isAr);
    }

    final quickPresets = isAr
        ? [
            'توريد لموقع هندسي',
            'توصيل أطفال للحضانة',
            'جلب مستند مع مسافر',
            'شراء من محل بفاتورة',
            '3 مقاعد شاغرة',
          ]
        : [
            'Engineer Site Supply',
            'Nursery Daily Ride',
            'On-Route Doc Fetch',
            'Shop with Receipt',
            '3 Empty Car Seats',
          ];

    final wizardTitles = isAr
        ? ['1. نوع الخدمة', '2. المسار والموعد', '3. التفاصيل والنشر']
        : ['1. Service Type', '2. Route & Time', '3. Details & Publish'];

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'انشر إعلان على اللوحة' : 'Post Ad on Board',
          style: AppTypography.title().copyWith(fontSize: 17.5),
        ),
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
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: MashwarWizardStepHeader(
                    currentStep: _visualStep,
                    stepTitles: wizardTitles,
                    isAr: isAr,
                  ),
                ),
                const Divider(height: 1, color: AppColors.slateBorder),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick 1-Tap Templates
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: AppColors.cobalt,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'قوالب سريعة جاهزة (تعبئة بنقرة واحدة)'
                                    : 'Quick 1-Tap Service Templates',
                                style: AppTypography.label(
                                  color: AppColors.cobalt,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(quickPresets.length, (i) {
                              final isSel = _activePresetIndex == i;
                              return Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _applyQuickPreset(i, isAr),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSel ? AppColors.cobalt : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.cobalt
                                            : AppColors.slateBorder,
                                      ),
                                    ),
                                    child: Text(
                                      quickPresets[i],
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isSel ? Colors.white : AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Step 1 Section: Intent & Category
                        Text(
                          isAr
                              ? '1. ما الذي ترغب في نشره؟'
                              : '1. What would you like to post?',
                          style: AppTypography.title().copyWith(fontSize: 15.5),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildIntentTab(
                                  index: 0,
                                  label: isAr
                                      ? 'أنا أطلب خدمة / مشوار'
                                      : 'I Need a Service',
                                  icon: Icons.person_search_rounded,
                                  onTap: () {
                                    setState(() {
                                      _intentIndex = 0;
                                      _visualStep = 1;
                                      if (_selectedCategory ==
                                          BoardAdType.rideOffer) {
                                        _selectedCategory =
                                            BoardAdType.rideRequest;
                                      }
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: _buildIntentTab(
                                  index: 1,
                                  label: isAr
                                      ? 'أنا مسافر / أقدم خدمة'
                                      : 'I Offer a Service',
                                  icon: Icons.handshake_outlined,
                                  onTap: () {
                                    setState(() {
                                      _intentIndex = 1;
                                      _visualStep = 1;
                                      _selectedCategory = BoardAdType.rideOffer;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCategoryGrid(isAr),
                        const SizedBox(height: 20),

                        if (_formError != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formError!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Step 2 Section: Route & Schedule
                        Text(
                          isAr
                              ? '2. المسار والموعد المفضل'
                              : '2. Route & Schedule',
                          style: AppTypography.title().copyWith(fontSize: 15.5),
                        ),
                        const SizedBox(height: 8),
                        _buildConnectedRouteCard(isAr),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildScheduleChip(
                                isAr ? 'الآن / فوري' : 'Now / Instant',
                              ),
                              const SizedBox(width: 8),
                              _buildScheduleChip(
                                isAr ? 'اليوم مساءً' : 'Tonight',
                              ),
                              const SizedBox(width: 8),
                              _buildScheduleChip(
                                isAr ? 'غداً صباحاً' : 'Tomorrow morning',
                              ),
                              const SizedBox(width: 8),
                              _buildScheduleChip(
                                isAr ? 'الجمعة بعد الظهر' : 'Friday afternoon',
                              ),
                              const SizedBox(width: 8),
                              _buildScheduleChip(
                                isAr ? 'خلال الأسبوع' : 'This week',
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                key: const ValueKey('post_ad_schedule_other'),
                                label: Text(
                                  isAr ? 'أخرى (موعد مخصص)' : 'Other (Custom)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cobalt,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                backgroundColor: AppColors.cobaltSurface,
                                side: BorderSide(
                                  color: AppColors.cobalt.withValues(alpha: 0.35),
                                ),
                                onPressed: () => setState(() {
                                  _timeController.clear();
                                  _visualStep = 2;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        MashwarTextField(
                          controller: _timeController,
                          hint: isAr
                              ? 'حدد اليوم والساعة المناسبة لك'
                              : 'Specify day and preferred time',
                          prefixIcon: const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.cobalt,
                            size: 20,
                          ),
                          onChanged: (_) {
                            if (_visualStep != 2) {
                              setState(() => _visualStep = 2);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Step 3 Section: Details, Budget & Verification
                        Text(
                          isAr
                              ? '3. التفاصيل والميزانية المقترحة'
                              : '3. Details & Proposed Budget',
                          style: AppTypography.title().copyWith(fontSize: 15.5),
                        ),
                        const SizedBox(height: 10),
                        _buildDynamicFields(isAr),
                        const SizedBox(height: 16),
                        _buildPriceSection(isAr),
                        const SizedBox(height: 16),

                        // Verification & Receipt Protection Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: AppColors.emerald,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'توثيق التسليم وإثبات الفاتورة'
                                          : 'OTP Handover & Receipt Verification',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() {
                                  _visualStep = 3;
                                  _hasEscrowProtection = !_hasEscrowProtection;
                                }),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _hasEscrowProtection,
                                      activeColor: AppColors.emerald,
                                      onChanged: (v) => setState(() {
                                        _visualStep = 3;
                                        _hasEscrowProtection = v ?? true;
                                      }),
                                    ),
                                    Expanded(
                                      child: Text(
                                        isAr
                                            ? 'توثيق الاستلام والتسليم بكود الأمان OTP'
                                            : 'Confirm handover with 4-digit OTP protection',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() {
                                  _visualStep = 3;
                                  _requiresReceiptProof =
                                      !_requiresReceiptProof;
                                }),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _requiresReceiptProof,
                                      activeColor: AppColors.cobalt,
                                      onChanged: (v) => setState(() {
                                        _visualStep = 3;
                                        _requiresReceiptProof = v ?? false;
                                      }),
                                    ),
                                    Expanded(
                                      child: Text(
                                        isAr
                                            ? 'يشترط إرفاق صورة الفاتورة الأصلية + الغرض (للمشتريات والتوريد)'
                                            : 'Require store receipt & item photo before dispatch',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_requiresReceiptProof) ...[
                                const SizedBox(height: 6),
                                MashwarTextField(
                                  controller: _itemBudgetController,
                                  label: isAr
                                      ? 'السقف التقديري لفاتورة الشراء (ر.ق)'
                                      : 'Estimated Store Receipt Cap (QAR)',
                                  hint: '150',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        MashwarTextField(
                          controller: _notesController,
                          label: isAr
                              ? 'ملاحظات إضافية (اختياري)'
                              : 'Additional Notes (Optional)',
                          hint: _getNotesHint(isAr),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.slateBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: MashwarButton(
              text: isAr ? 'نشر الطلب أو العرض الآن' : 'Publish Request / Offer',
              icon: const Icon(Icons.send_rounded, size: 18),
              onPressed: () => _submit(isAr),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntentTab({
    required int index,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _intentIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.cobalt : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                  color: isSelected ? AppColors.navy : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isAr) {
    final List<Map<String, dynamic>> items;

    if (_intentIndex == 0) {
      items = [
        {
          'type': BoardAdType.rideRequest,
          'title': isAr ? 'طلب سفر ومقعد' : 'Need a Ride',
          'subtitle': isAr
              ? 'حجز مقعد مع مسافر متجه لنفس الوجهة'
              : 'Book a seat with a traveler',
          'icon': Icons.person_search_rounded,
          'pillar': MashwarServicePillar.sharedTrips,
          'color': AppColors.cobalt,
        },
        {
          'type': BoardAdType.parcelRequest,
          'title': isAr ? 'شراء من محل وشحن أمانات' : 'Shop & Parcel',
          'subtitle': isAr
              ? 'توصيل طرد أو طلبات على الطريق بكود OTP'
              : 'Route parcel & OTP delivery',
          'icon': Icons.inventory_2_outlined,
          'pillar': MashwarServicePillar.routeParcels,
          'color': AppColors.indigo,
        },
        {
          'type': BoardAdType.goodsDelivery,
          'title': isAr ? 'لوجستيات وتوريد' : 'Site & Store Supply',
          'subtitle': isAr
              ? 'توريد لمواقع العمل أو مستلزمات محلات بفاتورة'
              : 'Site parts & store stock with receipt',
          'icon': Icons.inventory_outlined,
          'pillar': MashwarServicePillar.smartSupply,
          'color': AppColors.emerald,
        },
        {
          'type': BoardAdType.errandService,
          'title': isAr ? 'إنجاز معاملات رسمية' : 'Docs & Errands',
          'subtitle': isAr
              ? 'جلب مستند أو شراء غرض مع مسافر بالطريق'
              : 'Collect papers or items along route',
          'icon': Icons.description_outlined,
          'pillar': MashwarServicePillar.routeParcels,
          'color': AppColors.indigo,
        },
        {
          'type': BoardAdType.localTrip,
          'title': isAr ? 'مشاوير وحضانات يومية' : 'Nursery & Daily',
          'subtitle': isAr
              ? 'توصيل مدارس أو تنقل يومي منتظم'
              : 'Daily school & district commute',
          'icon': Icons.family_restroom_rounded,
          'pillar': MashwarServicePillar.sharedTrips,
          'color': AppColors.teal,
        },
        {
          'type': BoardAdType.errandService,
          'isOther': true,
          'title': isAr ? 'أخرى (طلب خدمة مخصصة)' : 'Other (Custom Service)',
          'subtitle': isAr
              ? 'اكتب أي خدمة أو مشوار مختلف غير مدرج أعلاه'
              : 'Specify any custom errand or service freely',
          'icon': Icons.add_circle_outline_rounded,
          'pillar': MashwarServicePillar.smartSupply,
          'color': AppColors.navy,
        },
      ];
    } else {
      items = [
        {
          'type': BoardAdType.rideOffer,
          'title': isAr ? 'عرض سفر تشاركي' : 'Offer Seats',
          'subtitle': isAr
              ? 'مسافر ومعي مقاعد شاغرة في سيارتي'
              : 'Empty seats in my private car',
          'icon': Icons.directions_car_outlined,
          'pillar': MashwarServicePillar.sharedTrips,
          'color': AppColors.cobalt,
        },
        {
          'type': BoardAdType.parcelRequest,
          'title': isAr ? 'استقبال أمانات في الطريق' : 'Carry Parcels',
          'subtitle': isAr
              ? 'مسافر ومستعد لتوصيل طرود وأمانات بكود OTP'
              : 'Traveler ready to carry parcels',
          'icon': Icons.inventory_2_outlined,
          'pillar': MashwarServicePillar.routeParcels,
          'color': AppColors.indigo,
        },
        {
          'type': BoardAdType.goodsDelivery,
          'title': isAr ? 'عرض توريد مواقع وبضائع' : 'Supply & Freight',
          'subtitle': isAr
              ? 'مركبة مجهزة لتوريد المواقع والمحلات بالفاتورة'
              : 'Vehicle ready for site/store supply',
          'icon': Icons.local_shipping_outlined,
          'pillar': MashwarServicePillar.smartSupply,
          'color': AppColors.emerald,
        },
        {
          'type': BoardAdType.errandService,
          'title': isAr ? 'جلب طلبات وأوراق بالطريق' : 'Errand & Shopping',
          'subtitle': isAr
              ? 'متحرك بطريقي ومستعد لشراء طلبات أو جلب أوراق'
              : 'Traveler ready to buy or fetch docs',
          'icon': Icons.description_outlined,
          'pillar': MashwarServicePillar.routeParcels,
          'color': AppColors.indigo,
        },
        {
          'type': BoardAdType.localTrip,
          'title': isAr ? 'عرض مشاوير وحضانات' : 'Offer Daily Rides',
          'subtitle': isAr
              ? 'مسافر موثق لتوصيل المدارس والمشاوير اليومية'
              : 'Verified daily & school rides',
          'icon': Icons.family_restroom_rounded,
          'pillar': MashwarServicePillar.sharedTrips,
          'color': AppColors.teal,
        },
        {
          'type': BoardAdType.errandService,
          'isOther': true,
          'title': isAr ? 'أخرى (تقديم خدمة مخصصة)' : 'Other (Custom Offer)',
          'subtitle': isAr
              ? 'اعرض أي خدمة مساندة أو توصيل خاص غير مدرج'
              : 'Offer any custom assistance or delivery',
          'icon': Icons.add_circle_outline_rounded,
          'pillar': MashwarServicePillar.smartSupply,
          'color': AppColors.navy,
        },
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.map((item) {
                final type = item['type'] as BoardAdType;
                final isOtherCard = item['isOther'] == true;
                final isSelected = isOtherCard
                    ? _isOtherCategory
                    : (!_isOtherCategory && _selectedCategory == type);
                final accentColor = item['color'] as Color;
                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    key: isOtherCard
                        ? const ValueKey('post_ad_category_other')
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = type;
                        _isOtherCategory = isOtherCard;
                        _visualStep = 2;
                        _formError = null;
                        if (type == BoardAdType.goodsDelivery ||
                            type == BoardAdType.parcelRequest) {
                          _requiresReceiptProof = true;
                        }
                      });
                    },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accentColor : AppColors.slateBorder,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MashwarServicePillarIcon(
                            pillar: item['pillar'] as MashwarServicePillar,
                            size: 36,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? accentColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
        if (_isOtherCategory) ...[
          const SizedBox(height: 12),
          MashwarTextField(
            key: const ValueKey('post_ad_custom_service_input'),
            controller: _customServiceController,
            label: isAr
                ? 'اكتب نوع الخدمة أو الطلب المخصص *'
                : 'Specify Your Custom Service / Request *',
            hint: isAr
                ? 'مثال: صيانة فورية، نقل أثاث خفيف، تصوير عقار، توصيل هدية...'
                : 'e.g. Quick maintenance, gift delivery, custom pickup...',
            onChanged: (_) {
              if (_formError != null) setState(() => _formError = null);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildConnectedRouteCard(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slateBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Stack(
            alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.emeraldSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 36,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: AppColors.slateBorder,
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.cobaltSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.cobalt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                isAr
                                    ? 'نقطة الانطلاق (من وين؟)'
                                    : 'Pickup / Departure',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _pickCity(
                                _fromController,
                                isAr ? 'نقطة الانطلاق' : 'Departure Point',
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_city_rounded,
                                      size: 13,
                                      color: AppColors.cobalt,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isAr ? 'المدن' : 'Cities',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.cobalt,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _fromController,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontFamily: 'Cairo',
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: isAr
                                ? 'اكتب المنطقة، المدينة أو العنوان'
                                : 'Area, city or address',
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1, color: AppColors.slateBorder),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                isAr
                                    ? 'وجهة الوصول (إلى أين؟)'
                                    : 'Destination / Drop-off',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _pickCity(
                                _toController,
                                isAr ? 'الوجهة' : 'Destination Point',
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_city_rounded,
                                      size: 13,
                                      color: AppColors.cobalt,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isAr ? 'المدن' : 'Cities',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.cobalt,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _toController,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontFamily: 'Cairo',
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: isAr
                                ? 'المنطقة، المدينة أو العنوان'
                                : 'Area, city or address',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              Positioned(
                left: isAr ? 0 : null,
                right: isAr ? null : 0,
                child: Material(
                  color: AppColors.slateBg,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.slateBorder),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _swapCities,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedRotation(
                        turns: _swapTurns,
                        duration: const Duration(milliseconds: 240),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          size: 20,
                          color: AppColors.cobalt,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _fromController,
          builder: (_, fromVal, __) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: _toController,
              builder: (_, toVal, __) {
                final from = fromVal.text.trim();
                final to = toVal.text.trim();
                if (from.isEmpty || to.isEmpty || from == to) {
                  return const SizedBox.shrink();
                }
                return FutureBuilder<RouteDetails>(
                  future:
                      AppRepositories.instance.maps.getRouteDetails(from, to),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final details = snapshot.data!;
                    final hours = details.durationMinutes ~/ 60;
                    final mins = details.durationMinutes % 60;
                    final timeStr = hours > 0
                        ? (isAr ? '$hours س و $mins د' : '${hours}h ${mins}m')
                        : (isAr ? '$mins دقيقة' : '${mins}m');
                    return Padding(
                      padding:
                          const EdgeInsets.only(top: 8, right: 2, left: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cobaltSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.cobalt.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alt_route_rounded,
                              color: AppColors.cobalt,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'المسافة التقديرية للمسار: ${details.distanceKm.round()} كم · ~$timeStr'
                                    : 'Estimated Route: ${details.distanceKm.round()} km · ~$timeStr',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildScheduleChip(String text) {
    final isSelected = _timeController.text.trim() == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _visualStep = 2;
          _timeController.text = text;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobalt : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cobalt : AppColors.slateBorder,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFields(bool isAr) {
    if (_selectedCategory == BoardAdType.parcelRequest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'مواصفات الأمانة أو الطرد' : 'Parcel Specifications',
            style: AppTypography.title().copyWith(fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          MashwarTextField(
            controller: _parcelDescController,
            label: isAr ? 'وصف الأمانة' : 'Parcel Contents',
            hint: isAr
                ? 'مثال: ملف أوراق رسمية، حقيبة، جهاز إلكتروني'
                : 'e.g. Official documents folder, gift bag',
          ),
          const SizedBox(height: 10),
          MashwarTextField(
            controller: _weightController,
            label: isAr ? 'الوزن التقريبي (كجم)' : 'Approximate Weight (kg)',
            hint: '2',
            keyboardType: TextInputType.number,
          ),
        ],
      );
    }

    if (_selectedCategory == BoardAdType.errandService) {
      final quickErrands = isAr
          ? [
              'شراء قطع غيار ومستلزمات',
              'شراء طلبات وإحضارها على الطريق',
              'تخليص شهادات وأوراق رسمية',
              'وصفة طبية وأدوية ضرورية',
            ]
          : [
              'Buy parts & supplies',
              'Shop items along route',
              'Official certificates & papers',
              'Pharmacy prescription',
            ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr
                ? 'تفاصيل المعاملة والأوراق الرسمية'
                : 'Official Errand Details',
            style: AppTypography.title().copyWith(fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickErrands.map((chipText) {
              final isSelected = _errandDescController.text.trim() == chipText;
              return ActionChip(
                label: Text(chipText),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor:
                    isSelected ? AppColors.indigo : Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.indigo : AppColors.slateBorder,
                ),
                onPressed: () {
                  setState(() {
                    _visualStep = 3;
                    _errandDescController.text = chipText;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          MashwarTextField(
            controller: _errandDescController,
            label: isAr
                ? 'نوع المعاملة أو طلب الشراء'
                : 'Errand / Shopping Description',
            hint: isAr
                ? 'مثال: استلام شهادة مختومة أو شراء غرض من متجر'
                : 'e.g. Collect stamped document or store item',
          ),
        ],
      );
    }

    if (_selectedCategory == BoardAdType.goodsDelivery) {
      final quickGoods = isAr
          ? [
              'بضائع ومستلزمات محلات',
              'كراتين وأجهزة تجارية',
              'طلبيات وخامات ورش ومصانع',
            ]
          : [
              'Store stock & supplies',
              'Cartons & electronics',
              'Workshop orders & materials',
            ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تفاصيل البضاعة والتوريد' : 'Commercial Cargo Details',
            style: AppTypography.title().copyWith(fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickGoods.map((chipText) {
              final isSelected = _goodsDescController.text.trim() == chipText;
              return ActionChip(
                label: Text(chipText),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor:
                    isSelected ? AppColors.emerald : Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.emerald : AppColors.slateBorder,
                ),
                onPressed: () {
                  setState(() {
                    _visualStep = 3;
                    _goodsDescController.text = chipText;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          MashwarTextField(
            controller: _goodsDescController,
            label: isAr ? 'وصف المستلزمات والكمية' : 'Goods & Quantity',
            hint: isAr
                ? 'مثال: 5 كراتين مستلزمات، أدوات كهربائية...'
                : 'e.g. 5 stock boxes, electrical tools...',
          ),
        ],
      );
    }

    // Rides & Local Trips
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedCategory == BoardAdType.rideOffer
                    ? (isAr ? 'عدد المقاعد الشاغرة' : 'Available Seats')
                    : (isAr ? 'عدد المقاعد المطلوبة' : 'Seats Needed'),
                style: AppTypography.title().copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                    onPressed: () => _adjustSeats(-1),
                    icon: const Icon(Icons.remove_rounded, color: AppColors.navy),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _seatsController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                    onPressed: () => _adjustSeats(1),
                    icon: const Icon(Icons.add_rounded, color: AppColors.navy),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _ladiesOnly,
                activeColor: AppColors.ladiesPink,
                onChanged: (val) => setState(() => _ladiesOnly = val ?? false),
              ),
              Expanded(
                child: Text(
                  isAr ? 'مخصص للسيدات فقط' : 'Ladies Only Ride',
                  style: AppTypography.body()
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (_selectedCategory == BoardAdType.rideOffer) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptsParcels,
                  activeColor: AppColors.indigo,
                  onChanged: (val) =>
                      setState(() => _acceptsParcels = val ?? true),
                ),
                Expanded(
                  child: Text(
                    isAr
                        ? 'أقبل توصيل أمانات وطرود خفيفة على طريقي'
                        : 'Accept light parcels along my route',
                    style: AppTypography.body()
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSection(bool isAr) {
    final label = _selectedCategory == BoardAdType.parcelRequest
        ? (isAr ? 'مكافأة توصيل الطرد (ر.ق)' : 'Offered Parcel Reward (QAR)')
        : _selectedCategory == BoardAdType.rideOffer
            ? (isAr ? 'سعر المقعد الواحد (ر.ق)' : 'Price per Seat (QAR)')
            : (isAr
                ? 'الميزانية أو الأتعاب المقترحة (ر.ق)'
                : 'Proposed Budget / Fee (QAR)');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => _adjustPrice(-5),
                icon: const Icon(Icons.remove_rounded),
                color: AppColors.navy,
              ),
              const SizedBox(width: 12),
              Container(
                width: 112,
                alignment: Alignment.center,
                child: TextField(
                  controller: _priceController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: isAr ? 'ر.ق' : 'QAR',
                    suffixStyle: AppTypography.body(color: AppColors.cobalt)
                        .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _adjustPrice(5),
                icon: const Icon(Icons.add_rounded),
                color: AppColors.navy,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: ['20', '35', '50', '75', '100', '150'].map((preset) {
              final isSelected = _priceController.text.trim() == preset;
              return ActionChip(
                label: Text(isAr ? '$preset ر.ق' : '$preset QAR'),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor:
                    isSelected ? AppColors.cobalt : AppColors.slateBg,
                side: BorderSide(
                  color: isSelected ? AppColors.cobalt : AppColors.slateBorder,
                ),
                onPressed: () {
                  setState(() {
                    _visualStep = 3;
                    _priceController.text = preset;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getNotesHint(bool isAr) {
    return isAr
        ? 'مثال: نقطة الالتقاء، تفاصيل إضافية للمسافر أو المنفذ...'
        : 'e.g. Meeting spot, handling instructions...';
  }

  Widget _buildSuccessScreen(bool isAr) {
    final routeText = context.trRoute(
      '${_fromController.text.trim()} ← ${_toController.text.trim()}',
    );
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isAr
                          ? 'تم نشر إعلانك بنجاح!'
                          : 'Published Successfully!',
                      style: AppTypography.largeTitle().copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'طلبك أو عرضك على مسار ($routeText) متاح الآن للمسافرين والمنفذين.'
                          : 'Your listing on ($routeText) is now live for travelers and providers.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: 22),
                    MashwarButton(
                      text: isAr
                          ? 'عرض إعلاناتي وعروضي'
                          : 'View My Listings & Offers',
                      variant: MashwarButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MyBoardAdsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    MashwarButton(
                      text: isAr ? 'تم' : 'Done',
                      onPressed: () => Navigator.of(context).pop(),
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
