import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/board_provider.dart';
import '../home/city_search_modal.dart';
import 'board_extra_screens.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';

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
  int _intentIndex = 0; // 0 = أنا أطلب خدمة (Requests), 1 = أنا أقدم خدمة / مسافر (Offers)
  bool _isSubmitted = false;
  bool _didApplyInitialPreset = false;
  String? _formError;

  // Form Controllers
  final TextEditingController _fromController = TextEditingController(text: 'الدوحة');
  final TextEditingController _toController = TextEditingController(text: 'الخور');
  final TextEditingController _timeController = TextEditingController(text: 'الجمعة بعد الظهر');
  final TextEditingController _seatsController = TextEditingController(text: '3');
  final TextEditingController _priceController = TextEditingController(text: '35');
  final TextEditingController _parcelDescController = TextEditingController(text: 'أوراق ومستندات رسمية');
  final TextEditingController _weightController = TextEditingController(text: '2');
  final TextEditingController _errandDescController = TextEditingController();
  final TextEditingController _goodsDescController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _itemBudgetController = TextEditingController(text: '150');
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
      _intentIndex = widget.initialIntent ?? (widget.initialCategory == BoardAdType.rideOffer ? 1 : 0);
    } else if (widget.initialIntent != null) {
      _intentIndex = widget.initialIntent!;
      _selectedCategory = _intentIndex == 1 ? BoardAdType.rideOffer : BoardAdType.rideRequest;
    } else if (widget.initialIsOffer) {
      _selectedCategory = BoardAdType.rideOffer;
      _intentIndex = 1;
    } else {
      _selectedCategory = BoardAdType.rideRequest;
      _intentIndex = 0;
    }
    if (_selectedCategory == BoardAdType.parcelRequest || _selectedCategory == BoardAdType.goodsDelivery) {
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
      _formError = null;
      if (index == 0) {
        // Engineer Site Supply
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
        // Nursery & Daily Commute
        _intentIndex = 0;
        _selectedCategory = BoardAdType.localTrip;
        _fromController.text = 'أم صلال';
        _toController.text = 'الدوحة';
        _timeController.text = isAr ? 'صباحاً 7:15 ص' : 'Morning 7:15 AM';
        _priceController.text = '40';
        _seatsController.text = '2';
        _notesController.text = isAr
            ? 'توصيل أطفال صباحي للحضانة بالدفنة بسيارة عائلية موثقة بالـ QID'
            : 'Morning nursery drop-off in Al Dafna with QID-verified family car';
        _requiresReceiptProof = false;
        _hasEscrowProtection = true;
        _ladiesOnly = true;
        _subTagAr = 'توصيل حضانة ويومي';
        _subTagEn = 'Nursery & Daily';
      } else if (index == 2) {
        // Cross-City Document Fetch
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
            ? 'بدل السفر من الخور مخصوص — التسليم بكود 4 أرقام OTP'
            : 'Delivered hand-to-hand with 4-digit OTP protection';
        _requiresReceiptProof = false;
        _hasEscrowProtection = true;
        _ladiesOnly = false;
        _subTagAr = 'جلب مستند مع مسافر';
        _subTagEn = 'Doc Fetch';
      } else if (index == 3) {
        // Buy & Deliver from Store
        _intentIndex = 0;
        _selectedCategory = BoardAdType.parcelRequest;
        _fromController.text = 'الدوحة';
        _toController.text = 'الريان';
        _timeController.text = isAr ? 'خلال ساعتين' : 'Within 2 hours';
        _priceController.text = '30';
        _itemBudgetController.text = '95';
        _parcelDescController.text = isAr
            ? 'شراء مستلزمات صيدلية أو محل من فيلاجيو وتوصيلها للريان'
            : 'Buy store/pharmacy items from Villaggio and deliver to Al Rayyan';
        _notesController.text = isAr
            ? 'المشتريات والفاتورة محفوظة في ضمان مشوار Escrow حتى التسليم'
            : 'Purchases & fee held in MASHWAR Escrow until OTP confirmation';
        _requiresReceiptProof = true;
        _hasEscrowProtection = true;
        _ladiesOnly = false;
        _subTagAr = 'شراء وتوصيل بفاتورة';
        _subTagEn = 'Shop with Receipt';
      } else if (index == 4) {
        // Shared Intercity 3 Empty Seats
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
            ? 'معي 3 مقاعد شاغرة بسيارتي الخاصة على طريق الشمال وأقبل أمانات بالطريق'
            : '3 empty seats available on North Road & can bring docs along route';
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
    if (selected != null && selected.trim().isNotEmpty) {
      setState(() {
        controller.text = selected;
        _formError = null;
      });
    }
  }

  void _swapCities() {
    setState(() {
      final tmp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tmp;
    });
  }

  void _adjustPrice(int delta) {
    final current = int.tryParse(_priceController.text.trim()) ?? 80;
    final next = (current + delta).clamp(10, 5000);
    setState(() {
      _priceController.text = '$next';
    });
  }

  void _adjustSeats(int delta) {
    final current = int.tryParse(_seatsController.text.trim()) ?? 1;
    final next = (current + delta).clamp(1, 8);
    setState(() {
      _seatsController.text = '$next';
    });
  }

  void _submit(bool isAr) {
    final fromCity = _fromController.text.trim();
    final toCity = _toController.text.trim();
    final timeText = _timeController.text.trim();
    final price = int.tryParse(_priceController.text.trim());

    if (fromCity.isEmpty || toCity.isEmpty || timeText.isEmpty || price == null || price <= 0) {
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
    final itemCost = _requiresReceiptProof ? int.tryParse(_itemBudgetController.text.trim()) : null;

    String computedTimeText = timeText;
    String computedDesc;

    if (type == BoardAdType.parcelRequest) {
      computedTimeText = isAr
          ? '$timeText · ${_weightController.text.trim()} كجم'
          : '$timeText · ${_weightController.text.trim()} kg';
      computedDesc = isAr
          ? 'طلب/طرد: ${_parcelDescController.text.trim()} · المكافأة: $price ر.ق'
          : 'Shop/Parcel: ${_parcelDescController.text.trim()} · Reward: $price QAR';
    } else if (type == BoardAdType.rideOffer) {
      computedTimeText = isAr
          ? '$timeText · $seats مقاعد شاغرة'
          : '$timeText · $seats empty seats';
      computedDesc = _acceptsParcels
          ? (isAr ? 'متاح مقاعد شاغرة وتوصيل أمانات أو أوراق على الطريق' : 'Accepts seats & parcels along route')
          : (isAr ? 'رحلة سفر تشاركي مباشرة · السعر للمقعد $price ر.ق' : 'Direct ride · $price QAR per seat');
    } else if (type == BoardAdType.localTrip) {
      computedTimeText = isAr ? '$timeText · مشوار يومي وحضانات' : '$timeText · Daily / Nursery ride';
      computedDesc = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (isAr
              ? 'طلب توصيل ومشوار محلي موثق بالـ QID · الأجرة المقترحة: $price ر.ق'
              : 'QID-verified local/school commute · Proposed fare: $price QAR');
    } else if (type == BoardAdType.errandService) {
      computedTimeText = isAr ? '$timeText · إنجاز معاملة أو جلب أوراق' : '$timeText · Doc & Errand';
      final errandText = _errandDescController.text.trim().isNotEmpty
          ? _errandDescController.text.trim()
          : (isAr ? 'جلب أوراق ومستندات رسمية بالطريق' : 'Official documents & items along route');
      computedDesc = isAr
          ? '$errandText · أتعاب الخدمة: $price ر.ق'
          : '$errandText · Service fee: $price QAR';
    } else if (type == BoardAdType.goodsDelivery) {
      computedTimeText = isAr ? '$timeText · توريد مواقع وبضائع' : '$timeText · Worksite & Cargo';
      final goodsText = _goodsDescController.text.trim().isNotEmpty
          ? _goodsDescController.text.trim()
          : (isAr ? 'توريد مستلزمات ومعدات لموقع العمل أو المحل' : 'Worksite supplies & store goods');
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
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      isLadiesOnly: _ladiesOnly,
      serviceSubTagAr: _subTagAr,
      serviceSubTagEn: _subTagEn,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'انشر إعلان على اللوحة' : 'Post Ad on Board',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick 1-Tap Real-Life Qatari Service Templates
                  Text(
                    isAr ? 'قوالب سريعة جاهزة (تعبئة بنقرة واحدة)' : 'Quick 1-Tap Service Templates',
                    style: AppTypography.label(color: AppColors.qatarMaroon).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(quickPresets.length, (i) {
                        final isSel = _activePresetIndex == i;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _applyQuickPreset(i, isAr),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.qatarMaroon : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSel ? AppColors.qatarMaroon : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                quickPresets[i],
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : AppColors.navy,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section Title: Category Selection
                  Text(
                    isAr ? '١. ما الذي ترغب في نشره؟' : '1. What would you like to post?',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Master Intent Segmented Switch
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
                            label: isAr ? 'أنا أطلب خدمة / مشوار' : 'I Need a Service',
                            icon: Icons.person_search_rounded,
                            onTap: () {
                              setState(() {
                                _intentIndex = 0;
                                if (_selectedCategory == BoardAdType.rideOffer) {
                                  _selectedCategory = BoardAdType.rideRequest;
                                }
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildIntentTab(
                            index: 1,
                            label: isAr ? 'أنا مسافر / أقدم خدمة' : 'I Offer a Service',
                            icon: Icons.handshake_rounded,
                            onTap: () {
                              setState(() {
                                _intentIndex = 1;
                                _selectedCategory = BoardAdType.rideOffer;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Cards Grid (2-Columns Layout)
                  _buildCategoryGrid(isAr),

                  const SizedBox(height: 20),

                  // Error Box if validation fails
                  if (_formError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formError!,
                              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section Title: Route & Location
                  Text(
                    isAr ? '٢. خط السير والموقع' : '2. Route & Location',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Connected Route Card
                  _buildConnectedRouteCard(isAr),

                  const SizedBox(height: 20),

                  // Section Title: Timing & Schedule
                  Text(
                    isAr ? '٣. الموعد والتوقيت المفضل' : '3. Schedule & Timing',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Quick Schedule Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildScheduleChip(isAr ? 'الآن / فوري' : 'Now / Instant'),
                        const SizedBox(width: 8),
                        _buildScheduleChip(isAr ? 'اليوم مساءً' : 'Tonight'),
                        const SizedBox(width: 8),
                        _buildScheduleChip(isAr ? 'غداً صباحاً' : 'Tomorrow morning'),
                        const SizedBox(width: 8),
                        _buildScheduleChip(isAr ? 'الجمعة بعد الظهر' : 'Friday afternoon'),
                        const SizedBox(width: 8),
                        _buildScheduleChip(isAr ? 'خلال الأسبوع' : 'This week'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  MashwarTextField(
                    controller: _timeController,
                    hint: isAr ? 'حدد اليوم والساعة المناسبة لك' : 'Specify day and preferred time',
                    prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.teal, size: 20),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Dynamic Category-Specific Fields
                  _buildDynamicFields(isAr),

                  const SizedBox(height: 20),

                  // Section Title: Proposed Budget / Fare
                  Text(
                    isAr ? '٤. المقابل المادي / الميزانية المقترحة' : '4. Proposed Budget & Fare',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Price Card with Quick Stepper & Presets
                  _buildPriceSection(isAr),

                  const SizedBox(height: 16),

                  // Bilateral Anti-Fraud & Escrow Toggle Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppColors.escrowGreen, size: 19),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr ? 'حماية الضمان المزدوج وإثبات الفاتورة (Escrow)' : 'Bilateral Escrow & Receipt Protection',
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
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _hasEscrowProtection = !_hasEscrowProtection),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _hasEscrowProtection,
                                activeColor: AppColors.escrowGreen,
                                onChanged: (v) => setState(() => _hasEscrowProtection = v ?? true),
                              ),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'حجز المبلغ في ضمان مشوار حتى إدخال كود OTP'
                                      : 'Hold payment in MASHWAR Escrow until OTP handover',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _requiresReceiptProof = !_requiresReceiptProof),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _requiresReceiptProof,
                                activeColor: AppColors.qatarMaroon,
                                onChanged: (v) => setState(() => _requiresReceiptProof = v ?? false),
                              ),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'يشترط تصوير الفاتورة الأصلية + الغرض (للمشتريات وتوريد المواقع)'
                                      : 'Require live store receipt & item photo before dispatch',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_requiresReceiptProof) ...[
                          const SizedBox(height: 6),
                          MashwarTextField(
                            controller: _itemBudgetController,
                            label: isAr ? 'السقف التقديري لفاتورة الشراء (ر.ق)' : 'Estimated Store Receipt Cap (QAR)',
                            hint: '150',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Additional Notes
                  Text(
                    isAr ? '٥. تفاصيل وملاحظات إضافية (اختياري)' : '5. Additional Details (Optional)',
                    style: AppTypography.title().copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  MashwarTextField(
                    controller: _notesController,
                    hint: _getNotesHint(isAr),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Guarantee Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.escrowSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.escrowGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'حماية وأمان المعاملات في مشوار' : 'MASHWAR Bilateral Escrow Security',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.escrowGreen),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isAr
                                    ? '• حق الطالب وحق المنفّذ محفوظ بالضمان المالي وتوثيق البطاقة القطرية QID.\n• تسليم الطلبات والمشتريات والمستندات مؤمّن بصورة الفاتورة وكود 4 أرقام OTP.'
                                    : '• Phone numbers stay private inside encrypted chat.\n• Payments, purchases & handovers are protected by Escrow & 4-digit OTP.',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.navy, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Reassuring Zero-Upfront-Charge Escrow Preview Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.qatarMaroon, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'النشر مجاني 100% · يُحجز المبلغ في ضمان مشوار عبر فوراً Fawran أو QPay فقط عند قبولك للعرض.'
                                : 'Posting is 100% free · Funds lock in MASHWAR Escrow via Fawran / QPay only when you accept an offer.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: MashwarButton(
              text: isAr ? 'نشر الإعلان على اللوحة بالضمان' : 'Publish Protected Ad Free',
              icon: const Icon(Icons.campaign_rounded),
              onPressed: () => _submit(isAr),
            ),
          ),
        ),
      ),
    );
  }

  // Master Intent Tab Widget
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
              color: isSelected ? AppColors.navy : const Color(0xFF64748B),
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

  // 2-Columns Responsive Category Cards Grid
  Widget _buildCategoryGrid(bool isAr) {
    final List<Map<String, dynamic>> items;

    if (_intentIndex == 0) {
      // Requests (طلبات ومصالح)
      items = [
        {
          'type': BoardAdType.goodsDelivery,
          'title': isAr ? 'لوجستيات وتوريد' : 'Site & Store Supply',
          'subtitle': isAr ? 'توريد لمواقع الهندسة أو مستلزمات محلات بفاتورة' : 'Engineer site parts & shop stock',
          'icon': Icons.engineering_rounded,
          'asset': 'assets/images/service_site_supply.jpg',
          'color': AppColors.qatarMaroon,
        },
        {
          'type': BoardAdType.errandService,
          'title': isAr ? 'إنجاز معاملات رسمية' : 'Docs & Errands',
          'subtitle': isAr ? 'جلب ورقة أو شراء طلبات مع مسافر بالطريق' : 'Buying items, errands or papers',
          'icon': Icons.description_rounded,
          'asset': 'assets/images/service_errand.jpg',
          'color': const Color(0xFFD97706),
        },
        {
          'type': BoardAdType.localTrip,
          'title': isAr ? 'مشاوير وحضانات يومية' : 'Nursery & Daily',
          'subtitle': isAr ? 'توصيل مدارس أو مناطق قليلة المواصلات' : 'School/nursery & remote commute',
          'icon': Icons.family_restroom_rounded,
          'color': AppColors.teal,
        },
        {
          'type': BoardAdType.parcelRequest,
          'title': isAr ? 'شراء من محل وشحن أمانات' : 'Shop & Parcel',
          'subtitle': isAr ? 'شراء وتوصيل طلبات أو طرود بكود OTP' : 'Store purchase & OTP delivery',
          'icon': Icons.inventory_2_rounded,
          'asset': 'assets/images/service_parcel.jpg',
          'color': const Color(0xFF10B981),
        },
        {
          'type': BoardAdType.rideRequest,
          'title': isAr ? 'طلب سفر ومقعد' : 'Need a Ride',
          'subtitle': isAr ? 'حجز مقعد مع مسافر متجه لنفس المدينة' : 'Book a seat with a traveler',
          'icon': Icons.person_search_rounded,
          'asset': 'assets/images/service_ride.jpg',
          'color': const Color(0xFF0284C7),
        },
      ];
    } else {
      // Offers (عروض ومنفّذين)
      items = [
        {
          'type': BoardAdType.rideOffer,
          'title': isAr ? 'عرض سفر تشاركي' : 'Offer Seats',
          'subtitle': isAr ? 'مسافر ومعي مقاعد شاغرة في سيارتي' : 'Empty seats in my private car',
          'icon': Icons.directions_car_rounded,
          'asset': 'assets/images/service_ride.jpg',
          'color': AppColors.navy,
        },
        {
          'type': BoardAdType.errandService,
          'title': isAr ? 'جلب طلبات وأوراق بالطريق' : 'Errand & Shopping',
          'subtitle': isAr ? 'متحرك بطريقي ومستعد لشراء طلبات أو جلب أوراق' : 'Traveler ready to buy or fetch docs',
          'icon': Icons.description_rounded,
          'asset': 'assets/images/service_errand.jpg',
          'color': const Color(0xFFD97706),
        },
        {
          'type': BoardAdType.goodsDelivery,
          'title': isAr ? 'عرض توريد مواقع وبضائع' : 'Worksite Freight',
          'subtitle': isAr ? 'مركبة مجهزة لتوريد المواقع والمحلات بالفاتورة' : 'Vehicle ready for site/store logistics',
          'icon': Icons.engineering_rounded,
          'asset': 'assets/images/service_site_supply.jpg',
          'color': AppColors.qatarMaroon,
        },
        {
          'type': BoardAdType.localTrip,
          'title': isAr ? 'عرض مشاوير وحضانات' : 'Offer Daily Rides',
          'subtitle': isAr ? 'سائق موثق لتوصيل المدارس والأسر والمناطق البعيدة' : 'QID-verified daily & school rides',
          'icon': Icons.family_restroom_rounded,
          'color': AppColors.teal,
        },
        {
          'type': BoardAdType.parcelRequest,
          'title': isAr ? 'استقبال أمانات في الطريق' : 'Accept Parcels',
          'subtitle': isAr ? 'مسافر ومستعد لتوصيل طرود وأمانات بكود OTP' : 'Traveler ready to take parcels',
          'icon': Icons.inventory_2_rounded,
          'asset': 'assets/images/service_parcel.jpg',
          'color': const Color(0xFF10B981),
        },
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final type = item['type'] as BoardAdType;
            final isSelected = _selectedCategory == type;
            return SizedBox(
              width: cardWidth,
              child: _buildCategoryCard(
                type: type,
                title: item['title'] as String,
                subtitle: item['subtitle'] as String,
                icon: item['icon'] as IconData,
                assetPath: item['asset'] as String?,
                accentColor: item['color'] as Color,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = type;
                    if (type == BoardAdType.goodsDelivery || type == BoardAdType.parcelRequest) {
                      _requiresReceiptProof = true;
                    }
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Individual Category Card
  Widget _buildCategoryCard({
    required BoardAdType type,
    required String title,
    required String subtitle,
    required IconData icon,
    String? assetPath,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (assetPath != null)
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: MashwarAssetArt(
                      assetPath: assetPath,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.circular(8),
                      fallbackIcon: icon,
                      fallbackColor: accentColor,
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Colors.white : accentColor,
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? accentColor : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title().copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.navy : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(
                color: isSelected ? const Color(0xFF334155) : AppColors.textSecondary,
              ).copyWith(fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // Connected Route Card (Departure 🟢 -> Destination 📍)
  Widget _buildConnectedRouteCard(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Stack(
            alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual Route Connector
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Inputs Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Departure Row (Authentic Qatari dialect: من وين؟)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isAr ? 'نقطة الانطلاق (من وين؟)' : 'Pickup / Departure',
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
                          onTap: () => _pickCity(_fromController, isAr ? 'نقطة الانطلاق' : 'Departure Point'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_city_rounded, size: 13, color: AppColors.teal),
                                const SizedBox(width: 3),
                                Text(
                                  isAr ? 'المدن' : 'Cities',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal,
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: isAr ? 'اكتب المنطقة، المدينة أو العنوان' : 'Area, city or address',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    ),

                    // Destination Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isAr ? 'وجهة الوصول (إلى أين؟)' : 'Destination / Drop-off',
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
                          onTap: () => _pickCity(_toController, isAr ? 'الوجهة' : 'Destination Point'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_city_rounded, size: 13, color: AppColors.teal),
                                const SizedBox(width: 3),
                                Text(
                                  isAr ? 'المدن' : 'Cities',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal,
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: isAr ? 'المنطقة، المدينة أو العنوان' : 'Area, city or address',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing spacing so text doesn't overlap the floating swap button
              const SizedBox(width: 32),
            ],
          ),

          // Floating Circular Swap Button
          Positioned(
            left: isAr ? 0 : null,
            right: isAr ? null : 0,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              ),
              elevation: 2,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _swapCities,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    // Dynamic Google Maps Route Estimate
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
              future: AppRepositories.instance.maps.getRouteDetails(from, to),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final details = snapshot.data!;
                final hours = details.durationMinutes ~/ 60;
                final mins = details.durationMinutes % 60;
                final timeStr = hours > 0
                    ? (isAr ? '$hours س و $mins د' : '${hours}h ${mins}m')
                    : (isAr ? '$mins دقيقة' : '${mins}m');
                return Padding(
                  padding: const EdgeInsets.only(top: 8, right: 4, left: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route_rounded, color: AppColors.teal, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'المسافة المقدرة عبر خرائط جوجل: ${details.distanceKm.round()} كم · زمن السفر: $timeStr تقريباً'
                                : 'Google Maps Est: ${details.distanceKm.round()} km · Travel Time: ~$timeStr',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600,
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

  // Quick Schedule Chip
  Widget _buildScheduleChip(String text) {
    final isSelected = _timeController.text.trim() == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeController.text = text;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.navy : const Color(0xFFCBD5E1)),
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

  // Category-Specific Dynamic Form Fields
  Widget _buildDynamicFields(bool isAr) {
    if (_selectedCategory == BoardAdType.parcelRequest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'مواصفات الأمانة أو الطرد' : 'Parcel Specifications',
            style: AppTypography.title().copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          MashwarTextField(
            controller: _parcelDescController,
            label: isAr ? 'وصف الأمانة' : 'Parcel Contents',
            hint: isAr ? 'مثال: دوسيه أوراق رسمية، شنطة هدايا، جهاز إلكتروني' : 'e.g. Official documents folder, gift bag',
          ),
          const SizedBox(height: 10),
          MashwarTextField(
            controller: _weightController,
            label: isAr ? 'الوزن التقريبي (كجم)' : 'Approximate Weight (kg)',
            hint: '2',
            keyboardType: TextInputType.number,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(isAr ? 'كجم' : 'kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            ),
          ),
        ],
      );
    }

    if (_selectedCategory == BoardAdType.errandService) {
      final quickErrands = isAr
          ? [
              'شراء قطع غيار ومستلزمات',
              'شراء طلبات وإحضارها من الدوحة',
              'تخليص شهادات وأوراق رسمية',
              'وصفة طبية وأدوية ضرورية',
            ]
          : [
              'Buy parts & supplies',
              'Shop items from Doha',
              'Official certificates & papers',
              'Pharmacy prescription',
            ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تفاصيل المعاملة والأوراق الرسمية' : 'Official Errand Details',
            style: AppTypography.title().copyWith(fontSize: 15),
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
                backgroundColor: isSelected ? AppColors.navy : const Color(0xFFF1F5F9),
                side: BorderSide(color: isSelected ? AppColors.navy : const Color(0xFFCBD5E1)),
                onPressed: () {
                  setState(() {
                    _errandDescController.text = chipText;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          MashwarTextField(
            controller: _errandDescController,
            label: isAr ? 'نوع المعاملة أو طلب الشراء' : 'Errand / Shopping Description',
            hint: isAr
                ? 'مثال: شراء قطع غيار من المنطقة الصناعية، أو استلام شهادة من المدينة التعليمية'
                : 'e.g. Buying parts from Industrial Area, or certificate from Education City',
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
            style: AppTypography.title().copyWith(fontSize: 15),
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
                backgroundColor: isSelected ? AppColors.navy : const Color(0xFFF1F5F9),
                side: BorderSide(color: isSelected ? AppColors.navy : const Color(0xFFCBD5E1)),
                onPressed: () {
                  setState(() {
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
            hint: isAr ? 'مثال: 5 كراتين مستلزمات لمحل ملابس، أدوات كهربائية' : 'e.g. 5 stock boxes for retail shop',
          ),
        ],
      );
    }

    if (_selectedCategory == BoardAdType.localTrip) {
      final quickTrips = isAr
          ? [
              'مشوار فوري (لا تتوفر مواصلات بالمنطقة)',
              'تنقّل بين المناطق والضواحي',
              'مشوار طوارئ أو مستشفى',
            ]
          : [
              'Instant trip (no local transit)',
              'Inter-area / district commute',
              'Hospital or clinic trip',
            ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'نوع المشوار المحلي وسبب الانتقال' : 'Local Mobility Context',
            style: AppTypography.title().copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickTrips.map((chipText) {
              final isSelected = _notesController.text.trim() == chipText;
              return ActionChip(
                label: Text(chipText),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor: isSelected ? AppColors.navy : const Color(0xFFF1F5F9),
                side: BorderSide(color: isSelected ? AppColors.navy : const Color(0xFFCBD5E1)),
                onPressed: () {
                  setState(() {
                    _notesController.text = chipText;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isAr ? 'عدد الركاب' : 'Number of Passengers',
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
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () => _adjustSeats(-1),
                      icon: const Icon(Icons.remove_rounded, color: AppColors.navy),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _seatsController.text,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy),
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () => _adjustSeats(1),
                      icon: const Icon(Icons.add_rounded, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _ladiesOnly,
                  activeColor: AppColors.teal,
                  onChanged: (val) => setState(() => _ladiesOnly = val ?? false),
                ),
                Expanded(
                  child: Text(
                    isAr ? 'مشوار مخصص للسيدات فقط 🌸' : 'Ladies Only Ride 🌸',
                    style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Rides & Mobility (rideOffer, rideRequest)
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
            // Compact Stepper controls
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    onPressed: () => _adjustSeats(-1),
                    icon: const Icon(Icons.remove_rounded, color: AppColors.navy),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _seatsController.text,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy),
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    onPressed: () => _adjustSeats(1),
                    icon: const Icon(Icons.add_rounded, color: AppColors.navy),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Quick Seat Selection Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            {'label': isAr ? '1 مقعد' : '1 seat', 'val': '1'},
            {'label': isAr ? '2 مقاعد' : '2 seats', 'val': '2'},
            {'label': isAr ? '3 مقاعد (شائع)' : '3 seats (common)', 'val': '3'},
            {'label': isAr ? '4 مقاعد' : '4 seats', 'val': '4'},
          ].map((item) {
            final isSelected = _seatsController.text.trim() == item['val'];
            return ActionChip(
              label: Text(item['label']!),
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              backgroundColor: isSelected ? AppColors.navy : const Color(0xFFF1F5F9),
              side: BorderSide(color: isSelected ? AppColors.navy : const Color(0xFFCBD5E1)),
              onPressed: () {
                setState(() {
                  _seatsController.text = item['val']!;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),

        // Ladies Only Checkbox
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _ladiesOnly,
                activeColor: AppColors.teal,
                onChanged: (val) => setState(() => _ladiesOnly = val ?? false),
              ),
              Expanded(
                child: Text(
                  isAr ? 'رحلة مخصصة للسيدات فقط 🌸' : 'Ladies Only Ride 🌸',
                  style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptsParcels,
                  activeColor: AppColors.teal,
                  onChanged: (val) => setState(() => _acceptsParcels = val ?? true),
                ),
                Expanded(
                  child: Text(
                    isAr ? 'أقبل توصيل أمانات وطرود خفيفة على طريقي 📦' : 'Accept small parcels along my route 📦',
                    style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Price & Budget Section with Quick Stepper and Preset Chips
  Widget _buildPriceSection(bool isAr) {
    String label;
    if (_selectedCategory == BoardAdType.parcelRequest) {
      label = isAr ? 'أجرة / مكافأة شحن الأمانة (ر.ق)' : 'Offered Parcel Reward (QAR)';
    } else if (_selectedCategory == BoardAdType.rideOffer) {
      label = isAr ? 'سعر المقعد الواحد بالسيارة (ر.ق)' : 'Price per Seat (QAR)';
    } else if (_selectedCategory == BoardAdType.localTrip) {
      label = isAr ? 'أجرة الانتقال المقترحة (ر.ق)' : 'Proposed Local Fare (QAR)';
    } else if (_selectedCategory == BoardAdType.errandService) {
      label = isAr ? 'أتعاب إنجاز المعاملة أو إحضار الأوراق (ر.ق)' : 'Errand Service Fee (QAR)';
    } else if (_selectedCategory == BoardAdType.goodsDelivery) {
      label = isAr ? 'أجرة نقل وتوريد البضاعة (ر.ق)' : 'Cargo Transport Fee (QAR)';
    } else {
      label = isAr ? 'ميزانيتك المقترحة للمقعد (ر.ق)' : 'Offered Budget per Seat (QAR)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy)),
          const SizedBox(height: 10),

          // Stepper + Big Price Display
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
                width: 108,
                alignment: Alignment.center,
                child: TextField(
                  controller: _priceController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.navy),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: isAr ? 'ر.ق' : 'QAR',
                    suffixStyle: AppTypography.body(color: AppColors.teal).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
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

          // Quick preset chips
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
                backgroundColor: isSelected ? AppColors.navy : const Color(0xFFF1F5F9),
                side: BorderSide(color: isSelected ? AppColors.navy : const Color(0xFFE2E8F0)),
                onPressed: () {
                  setState(() {
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
    switch (_selectedCategory) {
      case BoardAdType.errandService:
        return isAr
            ? 'مثال: الأوراق جاهزة للاستلام من مركز الخدمات الحكومية بالدفنة، يرجى التواصل فور الاستلام...'
            : 'e.g. Papers ready for pickup at Al Dafna Services Complex...';
      case BoardAdType.goodsDelivery:
        return isAr
            ? 'مثال: البضاعة في كراتين محكمة، التسليم عند المحل التجاري في المنطقة الصناعية...'
            : 'e.g. Stock packaged in sealed cartons, deliver to store in Industrial Area...';
      case BoardAdType.parcelRequest:
        return isAr
            ? 'مثال: ظرف أوراق مغلق بإحكام، التسليم برمز التحقق (OTP) للمستلم...'
            : 'e.g. Sealed documents envelope, deliver via OTP...';
      case BoardAdType.localTrip:
        return isAr
            ? 'مثال: المشوار مباشر من الوكرة إلى مؤسسة حمد الطبية...'
            : 'e.g. Direct trip from Al Wakrah to Hamad Medical City...';
      default:
        return isAr
            ? 'مثال: التجمع عند محطة الوقود بمدخل المدينة، حقيبة سفر متوسطة...'
            : 'e.g. Pickup near station entrance, medium suitcase...';
    }
  }

  // Success Screen
  Widget _buildSuccessScreen(bool isAr) {
    final routeText = context.trRoute('${_fromController.text.trim()} ← ${_toController.text.trim()}');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isAr ? 'تم نشر إعلانك على اللوحة بنجاح!' : 'Ad Published Successfully!',
                    style: AppTypography.largeTitle().copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'إعلانك ($routeText) ظاهر الآن لكل المستخدمين والمسافرين، وستتلقى إشعاراً فورياً عند وصول أي عرض.'
                        : 'Your ad ($routeText) is now live on the Board. You will be notified instantly when offers arrive.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary().copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // WhatsApp Share Action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusButton)),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: Text(
                      isAr ? 'شارك الإعلان على واتساب' : 'Share Ad on WhatsApp',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr ? 'تم نسخ رابط الإعلان للمشاركة على واتساب' : 'Ad link copied for WhatsApp sharing',
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 3),

                  MashwarButton(
                    text: isAr ? 'عرض إعلاناتي في اللوحة' : 'View My Board Ads',
                    variant: MashwarButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  MashwarButton(
                    text: isAr ? 'الرجوع للوحة' : 'Back to Board',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
