import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/models/worksite_models.dart';
import '../../state/auth_provider.dart';
import '../../state/worksite_provider.dart';
import 'create_work_request_screen.dart';
import 'work_request_details_screen.dart';

/// Worksite Supply Open & Active Requests Feed (`Tab 2: Requests / الطلبات`).
///
/// Provides Qatar municipality/area, status/urgency, and QAR budget filters;
/// honest request cards; loading skeleton; error retry; and empty state.
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

  bool _urgentOnly = false;
  bool _attemptedInitialLoad = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _attemptedInitialLoad) return;
      _attemptedInitialLoad = true;
      final provider = context.read<WorksiteProvider?>();
      if (provider != null) {
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
    _fallbackWorksiteProvider?.dispose();
    super.dispose();
  }

  bool _isUrgent(WorkRequest req) {
    if (req.scheduledBy == null) return false;
    final diff = req.scheduledBy!.difference(DateTime.now().toUtc());
    return diff.inHours <= 6;
  }

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

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final provider = _resolveWorksite(context);

    final baseList = provider.requests;
    final displayed = _urgentOnly
        ? baseList.where(_isUrgent).toList()
        : baseList;
    final hasAnyFilter = provider.hasActiveFilters || _urgentOnly;

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
                isAr ? 'طلبات توريد المواقع' : 'Worksite Supply Requests',
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
          AppDimens.space16, 10, AppDimens.space16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Qatar Area filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _areaFilterOptions.map((area) {
                final selected = activeArea == area;
                final label = area.isEmpty
                    ? (isAr ? 'كل مناطق قطر' : 'All Qatar Areas')
                    : AppStrings.translateCity(area, isArabic: isAr);
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    key: ValueKey(
                        'feed_area_chip_${area.isEmpty ? 'all' : area}'),
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
          const SizedBox(height: 8),

          // Row 2: Status, Urgency & Max Budget filters
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
                  accentColor: AppColors.qatarMaroon,
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
                    onPressed: () {
                      setState(() => _urgentOnly = false);
                      provider.clearFilters();
                    },
                    child: Text(
                      isAr ? 'مسح الفلاتر' : 'Clear Filters',
                      style: AppTypography.label(color: AppColors.qatarMaroon)
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
                      onPressed: () {
                        setState(() => _urgentOnly = false);
                        provider.clearFilters();
                      },
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

    // 4. Populated responsive list
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 820;
        if (!isTwoColumn) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.space16),
            itemCount: displayed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildRequestCard(context, displayed[index], isAr),
          );
        }

        final rowCount = (displayed.length / 2).ceil();
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimens.space16),
          itemCount: rowCount,
          itemBuilder: (context, rowIdx) {
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

    return MashwarPressable(
      key: ValueKey('feed_request_card_${req.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkRequestDetailsScreen(requestId: req.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDisabled),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4)),
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
            Text(
              req.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title().copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
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
                        size: 14, color: AppColors.qatarMaroon),
                    const SizedBox(width: 4),
                    Text(
                      isAr
                          ? '${req.offerCount} عروض'
                          : '${req.offerCount} offers',
                      style: AppTypography.label(color: AppColors.qatarMaroon)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  '· ${req.paymentMethod.label(isArabic: isAr)}',
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
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
            children: [
              Container(
                width: 90,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 72,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 220,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
