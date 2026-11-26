import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/worksite_models.dart';
import '../../state/auth_provider.dart';
import '../../state/worksite_provider.dart';
import 'create_work_request_screen.dart';
import 'work_request_details_screen.dart';

/// Worksite Supply Open & Active Requests Feed (`Tab 2: Requests / الطلبات`).
///
/// Provides instant search, supply category chips, role perspective pills,
/// sort options, Qatar municipality/area, status/urgency, and QAR budget filters;
/// interactive request cards; shimmer loading skeleton; error retry; pull-to-refresh;
/// and empty state.
class WorkRequestsFeedScreen extends StatefulWidget {
  final bool embeddedInTab;
  final String? initialArea;

  const WorkRequestsFeedScreen({
    super.key,
    this.embeddedInTab = false,
    this.initialArea,
  });

  @override
  State<WorkRequestsFeedScreen> createState() => _WorkRequestsFeedScreenState();
}

class _WorkRequestsFeedScreenState extends State<WorkRequestsFeedScreen> {
  static const List<String> _areaFilterOptions = [
    '',
    'الدوحة',
    'لوسيل',
    'المنطقة الصناعية',
    'الوكرة',
    'الخور',
    'الريان',
    'مسيعيد',
  ];

  static const List<int?> _budgetQarOptions = [
    null,
    250,
    400,
    600,
  ];

  static final RegExp _refPhotoPattern = RegExp(
    r'RefPhoto:\s*(\S+)',
    caseSensitive: false,
  );

  bool _urgentOnly = false;
  bool _openMarketOnly = false;
  bool _attemptedInitialLoad = false;
  late final TextEditingController _searchController;
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
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _attemptedInitialLoad) return;
      _attemptedInitialLoad = true;
      final provider = context.read<WorksiteProvider?>();
      if (provider != null) {
        if (provider.searchQuery.isNotEmpty &&
            _searchController.text != provider.searchQuery) {
          _searchController.text = provider.searchQuery;
        }
        if (widget.initialArea != null && widget.initialArea!.isNotEmpty) {
          provider.applyFilters(area: widget.initialArea);
        }
        if (provider.allLoadedRequests.isEmpty &&
            !provider.isLoading &&
            !provider.hasError) {
          provider.loadRequests();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fallbackWorksiteProvider?.dispose();
    super.dispose();
  }

  bool _isUrgent(WorkRequest req) {
    if (req.scheduledBy == null) return false;
    final diff = req.scheduledBy!.difference(DateTime.now().toUtc());
    return diff.inHours <= 6;
  }

  bool _isActiveStatus(WorkRequestStatus status) {
    return status != WorkRequestStatus.completed &&
        status != WorkRequestStatus.cancelled &&
        status != WorkRequestStatus.disputed;
  }

  bool _hasAttachments(WorkRequest req) {
    if (req.receiptImageUrl != null && req.receiptImageUrl!.trim().isNotEmpty) {
      return true;
    }
    if (req.paymentProofUrl != null && req.paymentProofUrl!.trim().isNotEmpty) {
      return true;
    }
    if (req.itemNotes != null && _refPhotoPattern.hasMatch(req.itemNotes!)) {
      return true;
    }
    return false;
  }

  bool _hasInvoice(WorkRequest req) =>
      req.receiptImageUrl != null && req.receiptImageUrl!.trim().isNotEmpty;

  Color _statusColor(WorkRequestStatus status) {
    switch (status) {
      case WorkRequestStatus.open:
        return AppColors.teal;
      case WorkRequestStatus.offerReceived:
      case WorkRequestStatus.offerSelected:
        return AppColors.warning;
      case WorkRequestStatus.accepted:
      case WorkRequestStatus.inProgress:
      case WorkRequestStatus.pickedUp:
      case WorkRequestStatus.inTransit:
      case WorkRequestStatus.deliveredPendingConfirmation:
        return AppColors.info;
      case WorkRequestStatus.completed:
        return AppColors.teal;
      case WorkRequestStatus.cancelled:
      case WorkRequestStatus.disputed:
        return AppColors.danger;
    }
  }

  String _formatDeadline(WorkRequest req, bool isAr) {
    if (req.scheduledBy == null) {
      return isAr ? 'مرن / حسب الاتفاق' : 'Flexible schedule';
    }
    final local = req.scheduledBy!.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return isAr
        ? '${local.day}/${local.month} · $hh:$mm'
        : '${local.month}/${local.day} · $hh:$mm';
  }

  String _sortLabel(WorksiteSortOption option, bool isAr) {
    switch (option) {
      case WorksiteSortOption.newest:
        return isAr ? 'الأحدث' : 'Newest';
      case WorksiteSortOption.highestBudget:
        return isAr ? 'الأعلى ميزانية' : 'Highest Budget';
      case WorksiteSortOption.soonestDeadline:
        return isAr ? 'الأقرب موعداً' : 'Soonest';
      case WorksiteSortOption.fewestOffers:
        return isAr ? 'الأقل عروضاً' : 'Fewest Offers';
    }
  }

  void _resetAllFilters(WorksiteProvider provider) {
    setState(() {
      _urgentOnly = false;
      _openMarketOnly = false;
      _searchController.clear();
    });
    provider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final provider = _resolveWorksite(context);
    final auth = context.watch<AuthProvider?>();
    final currentUid = provider.currentUserId ??
        ((auth != null && auth.user.id.trim().isNotEmpty)
            ? auth.user.id.trim()
            : null);

    var displayed = provider.requests;
    if (_openMarketOnly) {
      displayed = displayed.where((req) {
        final openForOffers = req.status == WorkRequestStatus.open ||
            req.status == WorkRequestStatus.offerReceived;
        if (!openForOffers) return false;
        if (currentUid == null) return true;
        return req.requesterId != currentUid &&
            req.assignedProviderId != currentUid;
      }).toList();
    }
    if (_urgentOnly) {
      displayed = displayed.where(_isUrgent).toList();
    }

    final hasAnyFilter = provider.hasActiveFilters ||
        _urgentOnly ||
        _openMarketOnly ||
        _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !widget.embeddedInTab,
        leading: widget.embeddedInTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.navy, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MashwarPinIcon(size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isAr ? 'طلبات التوريد والمهام' : 'Supply & Task Requests',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title().copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('feed_refresh_btn'),
            tooltip: isAr ? 'تحديث' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navy),
            onPressed: provider.isLoading ? null : () => provider.loadRequests(),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: TextButton.icon(
              key: const ValueKey('feed_create_btn'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateWorkRequestScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              label: Text(
                isAr ? 'طلب جديد' : 'New Request',
                style: AppTypography.label(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFiltersBar(context, provider, isAr, hasAnyFilter),
                const Divider(height: 1, color: AppColors.borderDisabled),
                Expanded(
                  child: _buildFeedBody(
                    context,
                    provider,
                    displayed,
                    isAr,
                    hasAnyFilter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(
    BuildContext context,
    WorksiteProvider provider,
    bool isAr,
    bool hasAnyFilter,
  ) {
    final activeArea = provider.filterArea ?? '';
    final activeStatus = provider.filterStatus;
    final activeMaxBudget = provider.filterMaxBudgetMinor;
    final activeCategory = provider.filterCategory ?? '';
    final activeSort = provider.sortBy;

    final perspectiveAllSelected = !_openMarketOnly &&
        !provider.filterOnlyMine &&
        !provider.filterAssignedToMe;
    final perspectiveOpenMarketSelected = _openMarketOnly &&
        !provider.filterOnlyMine &&
        !provider.filterAssignedToMe;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
          AppDimens.space16, 8, AppDimens.space16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 0: Instant Search + Sort dropdown menu
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('feed_search_input'),
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.slateBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    hintText: isAr
                        ? 'ابحث بالعنوان أو المواد أو المتجر أو المنطقة...'
                        : 'Search title, materials, store, or area...',
                    hintStyle: AppTypography.label(
                            color: AppColors.textSecondary)
                        .copyWith(fontSize: 12),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.navy,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 38, minHeight: 36),
                    suffixIcon: (_searchController.text.isNotEmpty ||
                            provider.searchQuery.isNotEmpty)
                        ? IconButton(
                            key: const ValueKey('feed_search_clear_btn'),
                            tooltip: isAr ? 'مسح البحث' : 'Clear search',
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() => _searchController.clear());
                              provider.applyFilters(clearSearchQuery: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.slateBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.slateBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.teal, width: 1.4),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    if (val.trim().isEmpty) {
                      provider.applyFilters(clearSearchQuery: true);
                    } else {
                      provider.applyFilters(searchQuery: val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<WorksiteSortOption>(
                key: const ValueKey('feed_sort_btn'),
                tooltip: isAr ? 'ترتيب الطلبات' : 'Sort requests',
                initialValue: activeSort,
                onSelected: (option) => provider.applyFilters(sortBy: option),
                itemBuilder: (ctx) => WorksiteSortOption.values
                    .map(
                      (option) => PopupMenuItem<WorksiteSortOption>(
                        key: ValueKey('feed_sort_option_${option.name}'),
                        value: option,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activeSort == option
                                  ? Icons.check_circle_rounded
                                  : Icons.sort_rounded,
                              size: 17,
                              color: activeSort == option
                                  ? AppColors.teal
                                  : AppColors.navy,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _sortLabel(option, isAr),
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(
                                fontWeight: activeSort == option
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: activeSort != WorksiteSortOption.newest
                        ? AppColors.tealSurface
                        : AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeSort != WorksiteSortOption.newest
                          ? AppColors.teal
                          : AppColors.slateBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 17,
                        color: activeSort != WorksiteSortOption.newest
                            ? AppColors.teal
                            : AppColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabel(activeSort, isAr),
                        style: AppTypography.label(
                          color: activeSort != WorksiteSortOption.newest
                              ? AppColors.teal
                              : AppColors.navy,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 1: Perspective pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactFilterPill(
                  key: const ValueKey('feed_perspective_all'),
                  label: isAr ? 'الكل' : 'All',
                  selected: perspectiveAllSelected,
                  accentColor: AppColors.navy,
                  onTap: () {
                    setState(() => _openMarketOnly = false);
                    provider.applyFilters(
                      onlyMine: false,
                      assignedToMe: false,
                    );
                  },
                ),
                const SizedBox(width: 6),
                _buildCompactFilterPill(
                  key: const ValueKey('feed_perspective_open_market'),
                  label: isAr ? 'متاح لتقديم عرض' : 'Open to Bid',
                  selected: perspectiveOpenMarketSelected,
                  accentColor: AppColors.teal,
                  onTap: () {
                    setState(() => _openMarketOnly = true);
                    provider.applyFilters(
                      onlyMine: false,
                      assignedToMe: false,
                    );
                  },
                ),
                const SizedBox(width: 6),
                _buildCompactFilterPill(
                  key: const ValueKey('feed_perspective_mine'),
                  label: isAr ? 'طلباتي' : 'My Requests',
                  selected: provider.filterOnlyMine,
                  accentColor: AppColors.navy,
                  onTap: () {
                    setState(() => _openMarketOnly = false);
                    provider.applyFilters(
                      onlyMine: true,
                      assignedToMe: false,
                    );
                  },
                ),
                const SizedBox(width: 6),
                _buildCompactFilterPill(
                  key: const ValueKey('feed_perspective_assigned'),
                  label: isAr ? 'مهامي كمزود' : 'Assigned Jobs',
                  selected: provider.filterAssignedToMe,
                  accentColor: AppColors.indigo,
                  onTap: () {
                    setState(() => _openMarketOnly = false);
                    provider.applyFilters(
                      onlyMine: false,
                      assignedToMe: true,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Row 2: Supply Category chips with MashwarCategoryIcon
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _buildCompactFilterPill(
                    key: const ValueKey('feed_category_chip_all'),
                    label: isAr ? 'كل الفئات' : 'All Categories',
                    selected: activeCategory.isEmpty,
                    accentColor: AppColors.navy,
                    onTap: () => provider.applyFilters(clearCategory: true),
                  ),
                ),
                ...mashwarWorksiteCategories.map((meta) {
                  final selected = activeCategory == meta.id;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: InkWell(
                      key: ValueKey('feed_category_chip_${meta.id}'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (selected) {
                          provider.applyFilters(clearCategory: true);
                        } else {
                          provider.applyFilters(category: meta.id);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            5, 3, 10, 3),
                        decoration: BoxDecoration(
                          color: selected ? meta.accentColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? meta.accentColor
                                : AppColors.borderDisabled,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MashwarCategoryIcon(
                              category: meta.id,
                              size: 20,
                              showSurface: true,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              meta.title(isArabic: isAr),
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Row 3: Qatar Area filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _areaFilterOptions.map((area) {
                final selected = activeArea == area;
                final label = area.isEmpty
                    ? (isAr ? 'كل المناطق' : 'All Areas')
                    : AppStrings.translateCity(area, isArabic: isAr);
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    key: ValueKey(
                        'feed_area_chip_${area.isEmpty ? 'all' : area}'),
                    visualDensity: VisualDensity.compact,
                    label: Text(label),
                    selected: selected,
                    selectedColor: AppColors.navy,
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      fontFamily: 'Cairo',
                    ),
                    onSelected: (_) {
                      if (area.isEmpty) {
                        provider.applyFilters(clearArea: true);
                      } else {
                        provider.applyFilters(area: area);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Row 4: Status, Urgency, Max Budget & Clear Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactFilterPill(
                  key: const ValueKey('feed_status_all'),
                  label: isAr ? 'كل الحالات' : 'All Statuses',
                  selected: activeStatus == null,
                  onTap: () => provider.applyFilters(clearStatus: true),
                ),
                const SizedBox(width: 6),
                _buildCompactFilterPill(
                  key: const ValueKey('feed_status_open'),
                  label: WorkRequestStatus.open.label(isArabic: isAr),
                  selected: activeStatus == WorkRequestStatus.open,
                  onTap: () =>
                      provider.applyFilters(status: WorkRequestStatus.open),
                ),
                const SizedBox(width: 6),
                _buildCompactFilterPill(
                  key: const ValueKey('feed_status_offers'),
                  label: WorkRequestStatus.offerReceived.label(isArabic: isAr),
                  selected: activeStatus == WorkRequestStatus.offerReceived,
                  onTap: () => provider.applyFilters(
                      status: WorkRequestStatus.offerReceived),
                ),
                const SizedBox(width: 6),
                _buildCompactFilterPill(
                  key: const ValueKey('feed_urgent_toggle'),
                  label: isAr ? 'عاجل فقط' : 'Urgent Only',
                  selected: _urgentOnly,
                  accentColor: AppColors.cobalt,
                  onTap: () => setState(() => _urgentOnly = !_urgentOnly),
                ),
                const SizedBox(width: 10),
                ..._budgetQarOptions.where((b) => b != null).map((qar) {
                  final minor = qar! * 100;
                  final selected = activeMaxBudget == minor;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: _buildCompactFilterPill(
                      key: ValueKey('feed_budget_$qar'),
                      label: isAr ? '≤ $qar ر.ق' : '≤ $qar QAR',
                      selected: selected,
                      accentColor: AppColors.teal,
                      onTap: () {
                        if (selected) {
                          provider.applyFilters(clearMaxBudget: true);
                        } else {
                          provider.applyFilters(maxBudgetMinor: minor);
                        }
                      },
                    ),
                  );
                }),
                if (hasAnyFilter)
                  TextButton(
                    key: const ValueKey('feed_clear_filters_btn'),
                    onPressed: () => _resetAllFilters(provider),
                    child: Text(
                      isAr ? 'مسح الفلاتر' : 'Clear Filters',
                      style: AppTypography.label(color: AppColors.cobalt)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterPill({
    Key? key,
    required String label,
    required bool selected,
    Color accentColor = AppColors.navy,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accentColor : AppColors.borderDisabled,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.navy,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildSupplyShowcaseBanner({
    required BuildContext context,
    required int totalCount,
    required bool isAr,
    required bool isWide,
  }) {
    return Container(
      key: const ValueKey('supply_feed_showcase_banner'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: isWide ? 148 : 108,
            child: AspectRatio(
              aspectRatio: 1376 / 768,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/mvp_hero_lusail_supply.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.navy,
                    child: const Center(
                      child: Icon(
                        Icons.handyman_rounded,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr
                      ? '$totalCount طلبات توريد ومهام نشطة'
                      : '$totalCount Active Supply & Errand Requests',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(color: AppColors.gold)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  isAr
                      ? 'شراء وتوريد بفاتورة أصلية موثّقة ورمز تسليم من 6 خانات'
                      : 'Verified Receipt Purchasing & 6-Char Handover Code',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(color: Colors.white).copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBody(
    BuildContext context,
    WorksiteProvider provider,
    List<WorkRequest> displayed,
    bool isAr,
    bool hasAnyFilter,
  ) {
    // 1. Loading skeleton
    if (provider.isLoading && displayed.isEmpty) {
      return ListView.separated(
        key: const ValueKey('feed_loading_skeleton'),
        padding: const EdgeInsets.all(AppDimens.space16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, idx) => _buildSkeletonCard(idx),
      );
    }

    // 2. Error state with Retry
    if (provider.hasError && displayed.isEmpty) {
      final errText = provider.localizedError(isArabic: isAr) ??
          (isAr
              ? 'تعذّر تحميل الطلبات حالياً.'
              : 'Unable to load requests right now.');
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              key: const ValueKey('feed_error_state'),
              padding: const EdgeInsets.all(AppDimens.space24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: AppColors.danger, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'تعذّر تحميل الطلبات' : 'Failed to Load Requests',
                    textAlign: TextAlign.center,
                    style: AppTypography.title().copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    errText,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: 16),
                  MashwarButton(
                    key: const ValueKey('feed_retry_btn'),
                    text: isAr ? 'إعادة المحاولة' : 'Retry',
                    onPressed: () => provider.retryLastLoad(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Empty state
    if (displayed.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              key: const ValueKey('feed_empty_state'),
              padding: const EdgeInsets.all(AppDimens.space24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderDisabled),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      color: AppColors.navy, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? 'لا توجد طلبات توريد مطابقة'
                        : 'No Matching Supply Requests',
                    textAlign: TextAlign.center,
                    style: AppTypography.title().copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasAnyFilter
                        ? (isAr
                            ? 'جرّب تعديل أو مسح الفلاتر المختارة لعرض طلبات إضافية.'
                            : 'Try adjusting or clearing active filters to see more requests.')
                        : (isAr
                            ? 'انشر أول طلب توريد لموقع عملك وسيظهر للمزودين المعتمدين في قطر.'
                            : 'Publish a worksite supply request to reach approved providers across Qatar.'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: 16),
                  if (hasAnyFilter)
                    MashwarButton(
                      text: isAr ? 'مسح الفلاتر' : 'Clear Filters',
                      variant: MashwarButtonVariant.secondary,
                      onPressed: () => _resetAllFilters(provider),
                    )
                  else
                    MashwarButton(
                      text: isAr ? 'إنشاء طلب توريد' : 'Create a Request',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateWorkRequestScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 4. Populated responsive list with pull-to-refresh
    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: () => provider.loadRequests(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTwoColumn = constraints.maxWidth >= 820;
          if (!isTwoColumn) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimens.space16),
              itemCount: displayed.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSupplyShowcaseBanner(
                    context: context,
                    totalCount: displayed.length,
                    isAr: isAr,
                    isWide: false,
                  );
                }
                return _buildRequestCard(context, displayed[index - 1], isAr);
              },
            );
          }

          final rowCount = (displayed.length / 2).ceil();
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.space16),
            itemCount: rowCount + 1,
            itemBuilder: (context, itemIdx) {
              if (itemIdx == 0) {
                return _buildSupplyShowcaseBanner(
                  context: context,
                  totalCount: displayed.length,
                  isAr: isAr,
                  isWide: true,
                );
              }
              final rowIdx = itemIdx - 1;
              final i1 = rowIdx * 2;
              final i2 = i1 + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRequestCard(context, displayed[i1], isAr),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i2 < displayed.length
                          ? _buildRequestCard(context, displayed[i2], isAr)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WorkRequest req,
    bool isAr,
  ) {
    final sColor = _statusColor(req.status);
    final areaLabel =
        AppStrings.translateCity(req.municipality, isArabic: isAr);
    final catMeta = mashwarCategoryMetaFor(req.supplyCategory);
    final urgent = _isUrgent(req) && _isActiveStatus(req.status);
    final hasInvoice = _hasInvoice(req);
    final hasAttachments = _hasAttachments(req);

    return MashwarHoverCard(
      key: ValueKey('feed_request_card_${req.id}'),
      borderRadius: BorderRadius.circular(16),
      borderColor: urgent
          ? AppColors.cobalt.withValues(alpha: 0.35)
          : AppColors.borderDisabled,
      hoverBorderColor: urgent ? AppColors.cobalt : AppColors.navy,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkRequestDetailsScreen(requestId: req.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      req.status.label(isArabic: isAr),
                      style: AppTypography.label(color: sColor)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (urgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cobaltSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.cobalt.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const MashwarLivePulseDot(
                            color: AppColors.cobalt,
                            size: 6.5,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'عاجل' : 'Urgent',
                            style:
                                AppTypography.label(color: AppColors.cobalt)
                                    .copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Text(
                  req.effectiveTotalMinor.format(isArabic: isAr),
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MashwarCategoryIcon(
                category: req.supplyCategory,
                size: 38,
                showSurface: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title().copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catMeta.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: catMeta.accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        catMeta.title(isArabic: isAr),
                        style:
                            AppTypography.label(color: catMeta.accentColor)
                                .copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slateBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: MashwarRouteTimeline(
              from: req.pickupLocation,
              to: '${req.dropoffWorksite} · $areaLabel',
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MashwarUserAvatar(
                    avatarUrl: null,
                    fullName: req.requesterName.isNotEmpty
                        ? req.requesterName
                        : 'عضو مشوار',
                    size: 22,
                    borderWidth: 1.2,
                    borderColor: AppColors.gold,
                    autoCommunityPortrait: true,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      req.requesterName.isNotEmpty
                          ? req.requesterName
                          : (isAr ? 'طالب الخدمة' : 'Requester'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeadline(req, isAr),
                    style: AppTypography.label(),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer_outlined,
                      size: 14, color: AppColors.cobalt),
                  const SizedBox(width: 4),
                  Text(
                    isAr
                        ? '${req.offerCount} عروض'
                        : '${req.offerCount} offers',
                    style: AppTypography.label(color: AppColors.cobalt)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                '· ${req.paymentMethod.label(isArabic: isAr)}',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
              if (hasInvoice)
                _buildAttachmentPill(
                  icon: Icons.receipt_long_rounded,
                  label: isAr ? 'فاتورة مرفقة' : 'Invoice',
                  color: AppColors.escrowGreen,
                  bgColor: AppColors.escrowSurface,
                )
              else if (hasAttachments)
                _buildAttachmentPill(
                  icon: Icons.attach_file_rounded,
                  label: isAr ? 'مرفقات' : 'Attachments',
                  color: AppColors.info,
                  bgColor: AppColors.infoBg,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.label(color: color).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(int idx) {
    return Container(
      key: ValueKey('skeleton_item_$idx'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              MashwarShimmerBox(width: 96, height: 22, borderRadius: 10),
              MashwarShimmerBox(width: 78, height: 24, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              MashwarShimmerBox(width: 38, height: 38, borderRadius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MashwarShimmerBox(width: 210, height: 16, borderRadius: 6),
                    SizedBox(height: 6),
                    MashwarShimmerBox(width: 110, height: 14, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const MashwarShimmerBox(height: 48, borderRadius: 10),
          const SizedBox(height: 10),
          Row(
            children: const [
              MashwarShimmerBox(width: 84, height: 14, borderRadius: 6),
              SizedBox(width: 10),
              MashwarShimmerBox(width: 64, height: 14, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}
