import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_handover_qr_panel.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/worksite_models.dart';
import '../../data/services/media_upload_service.dart';
import '../../state/auth_provider.dart';
import '../../state/worksite_provider.dart';
import '../chat/chat_screen.dart';
import 'create_work_request_screen.dart';
import 'provider_profile_screen.dart';

/// Complete Worksite Request Details, Offers, Fulfillment, Handover Verification,
/// Manual Transfer Proof, Audit Timeline, Rating, Dispute, and Quick Reorder screen.
class WorkRequestDetailsScreen extends StatefulWidget {
  @visibleForTesting
  static Future<bool> Function(Uri uri, {LaunchMode mode})? debugUrlLauncher;

  final String requestId;

  const WorkRequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<WorkRequestDetailsScreen> createState() =>
      _WorkRequestDetailsScreenState();
}

class _WorkRequestDetailsScreenState extends State<WorkRequestDetailsScreen> {
  WorksiteProvider? _fallbackWorksiteProvider;
  WorksiteProvider? _lastSyncedProvider;
  String? _lastLoadedRequestId;
  bool _hasSubmittedRating = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<WorksiteProvider?>();
    if (provider != null &&
        (!identical(provider, _lastSyncedProvider) ||
            _lastLoadedRequestId != widget.requestId)) {
      _lastSyncedProvider = provider;
      _lastLoadedRequestId = widget.requestId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        provider.selectAndLoadRequest(widget.requestId);
        final uid = provider.currentUserId;
        if (uid != null &&
            uid.isNotEmpty &&
            provider.providerProfile?.userId != uid) {
          provider.loadProviderProfile(uid);
        }
      });
    }
  }

  @override
  void dispose() {
    _fallbackWorksiteProvider?.dispose();
    super.dispose();
  }

  static final RegExp _refPhotoPattern = RegExp(
    r'RefPhoto:\s*(\S+)',
    caseSensitive: false,
  );

  List<String> _extractReferenceImageUrls(WorkRequest req) {
    final rawNotes = req.itemNotes;
    if (rawNotes == null || rawNotes.trim().isEmpty) return const [];
    final urls = <String>[];
    for (final match in _refPhotoPattern.allMatches(rawNotes)) {
      final candidate = match.group(1)?.trim();
      if (candidate != null &&
          candidate.isNotEmpty &&
          !urls.contains(candidate)) {
        urls.add(candidate);
      }
    }
    return urls;
  }

  WorkRequestStatus? _nextProviderStage(WorkRequestStatus current) {
    switch (current) {
      case WorkRequestStatus.accepted:
        return WorkRequestStatus.inProgress;
      case WorkRequestStatus.inProgress:
        return WorkRequestStatus.pickedUp;
      case WorkRequestStatus.pickedUp:
        return WorkRequestStatus.inTransit;
      case WorkRequestStatus.inTransit:
        return WorkRequestStatus.deliveredPendingConfirmation;
      default:
        return null;
    }
  }

  String _nextStageCtaLabel(WorkRequestStatus next, bool isAr) {
    switch (next) {
      case WorkRequestStatus.inProgress:
        return isAr
            ? 'بدء التنفيذ والتوجه للمتجر'
            : 'Start Fulfillment (In Progress)';
      case WorkRequestStatus.pickedUp:
        return isAr
            ? 'تأكيد الشراء والاستلام من المتجر'
            : 'Confirm Store Pickup & Receipt';
      case WorkRequestStatus.inTransit:
        return isAr
            ? 'بدء التحرك إلى موقع العمل'
            : 'Mark In Transit to Worksite';
      case WorkRequestStatus.deliveredPendingConfirmation:
        return isAr
            ? 'الوصول للموقع وطلب رمز التسليم'
            : 'Mark Arrived (Pending Confirmation)';
      default:
        return next.label(isArabic: isAr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final provider = _resolveWorksite(context);
    final auth = context.watch<AuthProvider?>();

    final req = provider.selectedRequest?.id == widget.requestId
        ? provider.selectedRequest
        : null;
    final currentUid = provider.currentUserId ??
        ((auth != null && auth.user.id.isNotEmpty) ? auth.user.id : null);

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy, size: 19),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          isAr ? 'تفاصيل طلب التوريد' : 'Request Details',
          style: AppTypography.title().copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'تحديث' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navy),
            onPressed: provider.isLoading
                ? null
                : () => provider.selectAndLoadRequest(widget.requestId),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: _buildBody(context, provider, req, currentUid, isAr),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest? req,
    String? currentUid,
    bool isAr,
  ) {
    if (provider.isLoading && req == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }

    if (req == null) {
      final errMsg = provider.localizedError(isArabic: isAr) ??
          (isAr ? 'تعذر العثور على الطلب.' : 'Worksite request not found.');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 44, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(errMsg,
                  textAlign: TextAlign.center, style: AppTypography.body()),
              const SizedBox(height: 16),
              MashwarButton(
                text: isAr ? 'إعادة المحاولة' : 'Retry',
                onPressed: () => provider.retryLastLoad(),
              ),
            ],
          ),
        ),
      );
    }

    final isRequester = currentUid != null && currentUid == req.requesterId;
    final isAssignedProvider =
        currentUid != null && currentUid == req.assignedProviderId;
    final canSubmitOfferStage = req.status == WorkRequestStatus.open ||
        req.status == WorkRequestStatus.offerReceived;
    final nextStage = _nextProviderStage(req.status);
    final disputable = {
      WorkRequestStatus.accepted,
      WorkRequestStatus.inProgress,
      WorkRequestStatus.pickedUp,
      WorkRequestStatus.inTransit,
      WorkRequestStatus.deliveredPendingConfirmation,
    }.contains(req.status);

    final inlineError = provider.localizedError(isArabic: isAr);

    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: () => provider.selectAndLoadRequest(widget.requestId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.hasError && inlineError != null) ...[
              Container(
                key: const ValueKey('details_error_banner'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inlineError,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: provider.clearError,
                    ),
                  ],
                ),
              ),
            ],

            // 1. Summary & Route Card
            _buildOverviewCard(context, provider, req, isRequester, isAr),
            const SizedBox(height: 14),

            // 2. Requester Handover Secret Code Card (ONLY visible to owner during active fulfillment)
            if (isRequester && provider.activeHandoverCode != null) ...[
              _buildRequesterHandoverCard(
                  context, provider.activeHandoverCode!, isAr),
              const SizedBox(height: 14),
            ],

            // 3. Requester Manual Bank Transfer Proof Upload
            if (isRequester &&
                req.paymentMethod == PaymentMethod.bankTransferManual) ...[
              _buildBankTransferProofCard(context, provider, req, isAr),
              const SizedBox(height: 14),
            ],

            // 4. Contextual Action Strip (Chat, Quick Reorder, Cancel, Dispute, Rating)
            _buildContextualActionsCard(
              context,
              provider,
              req,
              isRequester: isRequester,
              isAssignedProvider: isAssignedProvider,
              disputable: disputable,
              isAr: isAr,
            ),
            const SizedBox(height: 14),

            // 5. Provider Fulfillment Controls + 6-char Handover Verification Modal Trigger
            if (isAssignedProvider) ...[
              _buildAssignedProviderControls(
                context,
                provider,
                req,
                nextStage: nextStage,
                isAr: isAr,
              ),
              const SizedBox(height: 14),
            ],

            // 6. Provider Offer Submission Gate (when viewing an open request not owned by current user)
            if (!isRequester && !isAssignedProvider && canSubmitOfferStage) ...[
              _buildProviderOfferGateCard(context, provider, req, isAr),
              const SizedBox(height: 14),
            ],

            // 7. Offers Comparison List
            _buildOffersSection(
              context,
              provider,
              req,
              isRequester: isRequester,
              currentUid: currentUid,
              isAr: isAr,
            ),
            const SizedBox(height: 14),

            // 8. Request Events Audit Timeline
            _buildTimelineSection(provider.selectedEvents, isAr),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isRequester,
    bool isAr,
  ) {
    final areaLabel =
        AppStrings.translateCity(req.municipality, isArabic: isAr);
    final catMeta = mashwarCategoryMetaFor(req.supplyCategory);
    final referenceImageUrls = _extractReferenceImageUrls(req);
    final receiptUrl = req.receiptImageUrl?.trim();
    final paymentProofUrl = req.paymentProofUrl?.trim();
    final hasAnyAttachment = referenceImageUrls.isNotEmpty ||
        (receiptUrl != null && receiptUrl.isNotEmpty) ||
        (paymentProofUrl != null && paymentProofUrl.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MashwarWorksiteStatusStepper(status: req.status, isAr: isAr),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MashwarBadge(
                    type: req.status == WorkRequestStatus.completed
                        ? BadgeType.verified
                        : (req.status == WorkRequestStatus.cancelled ||
                                req.status == WorkRequestStatus.disputed
                            ? BadgeType.rejected
                            : BadgeType.confirmed),
                    customLabel: req.status.label(isArabic: isAr),
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(5, 3, 10, 3),
                    decoration: BoxDecoration(
                      color: AppColors.slateBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MashwarCategoryIcon(
                          category: req.supplyCategory,
                          size: 20,
                          showSurface: true,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          catMeta.title(isArabic: isAr),
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${req.id}',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    key: const ValueKey('details_copy_id_btn'),
                    tooltip: isAr ? 'نسخ رقم الطلب' : 'Copy Request ID',
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: req.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr ? 'تم نسخ رقم الطلب' : 'Request ID copied',
                          ),
                          backgroundColor: AppColors.teal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req.title,
            style: AppTypography.title().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            req.description,
            style: AppTypography.bodySecondary(color: AppColors.textPrimary),
          ),
          if (req.itemNotes != null && req.itemNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Text(
                req.itemNotes!,
                style: AppTypography.bodySmall(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (req.status == WorkRequestStatus.cancelled &&
              req.cancellationReason != null &&
              req.cancellationReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoTag(
              Icons.cancel_outlined,
              isAr
                  ? 'سبب الإلغاء: ${req.cancellationReason}'
                  : 'Cancellation reason: ${req.cancellationReason}',
              color: AppColors.danger,
            ),
          ],
          if (req.status == WorkRequestStatus.disputed &&
              req.disputeReason != null &&
              req.disputeReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoTag(
              Icons.report_problem_outlined,
              isAr
                  ? 'سبب النزاع: ${req.disputeReason}'
                  : 'Dispute reason: ${req.disputeReason}',
              color: AppColors.warning,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: MashwarRouteTimeline(
              from: req.pickupLocation,
              to: '${req.dropoffWorksite} ($areaLabel)',
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.slateBorder),
          const SizedBox(height: 12),

          // Financial Breakdown in QAR minor units
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: isAr ? 'المشتريات التقديرية' : 'Est. Items',
                value: req.estimatedItemsCostMinor.format(isArabic: isAr),
              ),
              _buildMetricChip(
                label: isAr ? 'سقف الفاتورة' : 'Max Receipt Cap',
                value: req.maxItemsCapMinor.format(isArabic: isAr),
              ),
              _buildMetricChip(
                label: req.agreedFeeMinor != null
                    ? (isAr ? 'رسوم التوريد المتفق عليها' : 'Agreed Fee')
                    : (isAr ? 'ميزانية التوصيل' : 'Fee Budget'),
                value: (req.agreedFeeMinor ?? req.deliveryFeeBudgetMinor)
                    .format(isArabic: isAr),
              ),
              _buildMetricChip(
                label: isAr ? 'الإجمالي الفعلي/التقديري' : 'Total QAR',
                value: req.effectiveTotalMinor.format(isArabic: isAr),
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _buildInfoTag(
                Icons.payments_outlined,
                '${req.paymentMethod.label(isArabic: isAr)} · ${req.paymentSettlementStatus.label(isArabic: isAr)}',
              ),
              if (req.assignedProviderName != null &&
                  req.assignedProviderName!.isNotEmpty)
                _buildInfoTag(
                  Icons.verified_rounded,
                  isAr
                      ? 'المنفّذ: ${req.assignedProviderName}'
                      : 'Provider: ${req.assignedProviderName}',
                  color: AppColors.teal,
                ),
              if (receiptUrl != null && receiptUrl.isNotEmpty)
                _buildInfoTag(
                  Icons.receipt_long_rounded,
                  isAr
                      ? 'الفاتورة مرفقة: $receiptUrl'
                      : 'Invoice attached: $receiptUrl',
                  color: AppColors.teal,
                ),
            ],
          ),
          if (hasAnyAttachment) ...[
            const SizedBox(height: 14),
            Text(
              isAr
                  ? 'المرفقات والفواتير وإيصالات التحويل'
                  : 'Reference Photos, Store Invoices & Transfer Proofs',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < referenceImageUrls.length; i++)
                  MashwarAttachmentThumbnail(
                    key: ValueKey('details_ref_photo_thumb_$i'),
                    url: referenceImageUrls[i],
                    label: isAr
                        ? 'صورة مرجعية ${referenceImageUrls.length > 1 ? i + 1 : ""}'
                            .trim()
                        : 'Reference ${referenceImageUrls.length > 1 ? i + 1 : ""}'
                            .trim(),
                    onTap: () => MashwarImagePreviewDialog.show(
                      context,
                      url: referenceImageUrls[i],
                      title: isAr ? 'صورة مرجعية للمواد' : 'Item Reference Photo',
                    ),
                  ),
                if (receiptUrl != null && receiptUrl.isNotEmpty)
                  MashwarAttachmentThumbnail(
                    key: const ValueKey('details_receipt_thumb'),
                    url: receiptUrl,
                    label: isAr ? 'فاتورة الشراء' : 'Store Invoice',
                    isInvoice: true,
                    onTap: () => MashwarImagePreviewDialog.show(
                      context,
                      url: receiptUrl,
                      title: isAr ? 'فاتورة الشراء الأصلية' : 'Store Invoice',
                    ),
                  ),
                if (paymentProofUrl != null && paymentProofUrl.isNotEmpty)
                  MashwarAttachmentThumbnail(
                    key: const ValueKey('details_payment_proof_thumb'),
                    url: paymentProofUrl,
                    label: isAr ? 'إيصال التحويل' : 'Transfer Proof',
                    onTap: () => MashwarImagePreviewDialog.show(
                      context,
                      url: paymentProofUrl,
                      title: isAr
                          ? 'إيصال التحويل البنكي'
                          : 'Bank Transfer Proof',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? AppColors.tealSurface : AppColors.slateBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.teal.withValues(alpha: 0.35)
              : AppColors.slateBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTypography.label(color: AppColors.textSecondary)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.body(
              color: highlight ? AppColors.teal : AppColors.navy,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text,
      {Color color = AppColors.navy}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color == AppColors.navy
            ? AppColors.slateBg
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: color == AppColors.navy
            ? Border.all(color: AppColors.slateBorder)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: color)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequesterHandoverCard(
    BuildContext context,
    String handoverCode,
    bool isAr,
  ) {
    return MashwarHandoverQrCard(
      cardKey: const ValueKey('requester_handover_code_card'),
      codeValueKey: const ValueKey('requester_handover_code_value'),
      qrKey: const ValueKey('requester_handover_qr_code'),
      contingencyButtonKey: const ValueKey('requester_handover_contingency_btn'),
      referenceId: widget.requestId,
      title: isAr
          ? 'رمز QR وكود تأكيد التسليم السري (6 خانات)'
          : 'Secret Handover QR & Verification Code (6-Char)',
      subtitle: isAr
          ? 'اعرض رمز QR للمنفّذ للمسح أو سلّمه الكود يدوياً فقط بعد فحص واستلام المواد والفاتورة في موقع العمل (صالح 24 ساعة ويُستخدم مرة واحدة).'
          : 'Let the provider scan this QR or share the 6-char code ONLY after inspecting the items and receipt on-site (24h expiry, single-use).',
      code: handoverCode,
      qrPayload: 'MASHWAR|SUPPLY|${widget.requestId}|$handoverCode',
      isAr: isAr,
      accentColor: AppColors.navy,
      surfaceColor: AppColors.sand,
      borderColor: AppColors.slateBorder,
      onEmergencyFallbackLogged: (record) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم توثيق تسليم الطوارئ (${record.fallbackRef}) باسم ${record.backupContactName}'
                  : 'Emergency fallback logged (${record.fallbackRef}) for ${record.backupContactName}',
            ),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildBankTransferProofCard(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isAr,
  ) {
    final isUnpaid =
        req.paymentSettlementStatus == PaymentSettlementStatus.unpaid;

    return Container(
      key: const ValueKey('bank_transfer_proof_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'توثيق إيصال التحويل البنكي اليدوي'
                      : 'Manual Bank Transfer Proof',
                  style: AppTypography.title().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MashwarBadge(
                type: req.paymentSettlementStatus ==
                        PaymentSettlementStatus.verifiedSettled
                    ? BadgeType.verified
                    : BadgeType.pending,
                customLabel:
                    req.paymentSettlementStatus.label(isArabic: isAr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (req.paymentProofUrl != null && req.paymentProofUrl!.isNotEmpty)
            Text(
              isAr
                  ? 'الإيصال المرفوع: ${req.paymentProofUrl} ${req.paymentReference != null ? "(مرجع: ${req.paymentReference})" : ""}'
                  : 'Submitted proof: ${req.paymentProofUrl} ${req.paymentReference != null ? "(Ref: ${req.paymentReference})" : ""}',
              style: AppTypography.bodySmall(color: AppColors.teal)
                  .copyWith(fontWeight: FontWeight.w700),
            )
          else
            Text(
              isAr
                  ? 'ارفع رابط إيصال التحويل البنكي / فوراً ورقم المرجع لتوثيق السداد.'
                  : 'Upload your manual bank / Fawran transfer receipt URL and reference number.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          if (isUnpaid) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('upload_transfer_proof_btn'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  _showTransferProofModal(context, provider, req, isAr),
              icon: const Icon(Icons.upload_file_rounded,
                  size: 18, color: AppColors.navy),
              label: Text(
                isAr ? 'رفع إيصال التحويل' : 'Submit Transfer Proof',
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextualActionsCard(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req, {
    required bool isRequester,
    required bool isAssignedProvider,
    required bool disputable,
    required bool isAr,
  }) {
    final counterpartyName = isRequester
        ? (req.assignedProviderName ??
            (isAr ? 'مراسلة المزود' : 'Assigned Provider'))
        : (req.requesterName.isNotEmpty
            ? req.requesterName
            : (isAr ? 'صاحب الطلب' : 'Requester'));

    final calmSecondaryStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.navy,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final calmDangerStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.danger,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Contextual ChatScreen button
          OutlinedButton.icon(
            key: const ValueKey('details_open_chat_btn'),
            style: calmSecondaryStyle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    driverName: counterpartyName,
                    driverCar: req.title,
                    tripRoute:
                        '${req.pickupLocation} ← ${req.dropoffWorksite}',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                size: 16, color: AppColors.navy),
            label: Text(
              isAr ? 'محادثة الطلب' : 'Order Chat',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),

          // Real OS Phone Call button (tel:) when siteContactPhone is provided
          if (req.siteContactPhone != null &&
              req.siteContactPhone!.trim().isNotEmpty)
            OutlinedButton.icon(
              key: const ValueKey('details_call_contact_btn'),
              style: calmSecondaryStyle,
              onPressed: () => _launchSitePhoneCall(
                context,
                req.siteContactPhone!.trim(),
                isAr,
              ),
              icon: const Icon(Icons.phone_in_talk_rounded,
                  size: 16, color: AppColors.teal),
              label: Text(
                isAr ? 'اتصال بمسؤول الموقع' : 'Call Site Contact',
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),

          // Real OS Email Support Escalation (mailto:)
          OutlinedButton.icon(
            key: const ValueKey('details_email_support_btn'),
            style: calmSecondaryStyle,
            onPressed: () => _launchSupportEmail(context, req, isAr),
            icon: const Icon(Icons.mail_outline_rounded,
                size: 16, color: AppColors.navy),
            label: Text(
              isAr ? 'مراسلة الدعم' : 'Email Support',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),

          // 1-Tap Quick Reorder
          if (isRequester)
            OutlinedButton.icon(
              key: const ValueKey('details_quick_reorder_btn'),
              style: calmSecondaryStyle,
              onPressed: () {
                final draft = provider.buildReorderDraft(req);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateWorkRequestScreen(initialDraft: draft),
                  ),
                );
              },
              icon: const Icon(Icons.replay_rounded,
                  size: 16, color: AppColors.navy),
              label: Text(
                isAr ? 'إعادة طلب سريعة' : 'Quick Reorder',
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),

          // Requester Cancel Request (before offer acceptance)
          if (isRequester &&
              (req.status == WorkRequestStatus.open ||
                  req.status == WorkRequestStatus.offerReceived))
            OutlinedButton.icon(
              key: const ValueKey('details_cancel_request_btn'),
              style: calmDangerStyle,
              onPressed: provider.isSubmitting
                  ? null
                  : () => _showCancelRequestSheet(context, provider, req, isAr),
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: AppColors.danger),
              label: Text(
                isAr ? 'إلغاء الطلب' : 'Cancel Request',
                style: AppTypography.label(color: AppColors.danger)
                    .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),

          // Post-completion Mutual Rating Modal
          if (req.status == WorkRequestStatus.completed &&
              (isRequester || isAssignedProvider) &&
              !_hasSubmittedRating)
            ElevatedButton.icon(
              key: const ValueKey('details_rate_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showRatingModal(
                context,
                provider,
                req,
                isRequester: isRequester,
                isAr: isAr,
              ),
              icon: const Icon(Icons.star_rounded,
                  size: 17, color: AppColors.gold),
              label: Text(
                isAr ? 'تقييم التجربة' : 'Rate Experience',
                style: AppTypography.label(color: Colors.white)
                    .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),

          // Dispute Reporting Modal
          if (disputable && (isRequester || isAssignedProvider))
            OutlinedButton.icon(
              key: const ValueKey('details_dispute_btn'),
              style: calmDangerStyle,
              onPressed: () => _showDisputeModal(
                context,
                provider,
                req,
                reporterRole: isRequester ? 'requester' : 'provider',
                isAr: isAr,
              ),
              icon: const Icon(Icons.report_problem_outlined,
                  size: 16, color: AppColors.danger),
              label: Text(
                isAr ? 'الإبلاغ عن نزاع' : 'Report Dispute',
                style: AppTypography.label(color: AppColors.danger)
                    .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedProviderControls(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req, {
    required WorkRequestStatus? nextStage,
    required bool isAr,
  }) {
    if (nextStage == null &&
        req.status != WorkRequestStatus.deliveredPendingConfirmation) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('provider_fulfillment_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'إدارة تنفيذ وتوصيل الطلب (للمزود المكلّف)'
                      : 'Provider Fulfillment & Handover Controls',
                  style: AppTypography.title().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nextStage != null)
            MashwarButton(
              key: ValueKey('advance_stage_${nextStage.value}'),
              text: _nextStageCtaLabel(nextStage, isAr),
              isLoading: provider.isSubmitting,
              onPressed: () {
                final needsInvoiceOption = nextStage ==
                        WorkRequestStatus.pickedUp ||
                    nextStage == WorkRequestStatus.inTransit ||
                    nextStage == WorkRequestStatus.deliveredPendingConfirmation;
                if (needsInvoiceOption) {
                  _showAdvanceStageSheet(
                      context, provider, req, nextStage, isAr);
                } else {
                  provider.advanceStatus(
                    requestId: req.id,
                    nextStatus: nextStage,
                    actorRole: 'provider',
                  );
                }
              },
            ),
          if (req.status == WorkRequestStatus.deliveredPendingConfirmation) ...[
            Text(
              isAr
                  ? 'اطلب رمز التسليم المكون من 6 خانات من المستلم في موقع العمل لإتمام الطلب رسمياً.'
                  : 'Ask the site contact for their 6-character handover code to verify delivery and complete the request.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            MashwarButton(
              key: const ValueKey('details_verify_handover_btn'),
              text: isAr
                  ? 'إدخال رمز التسليم (6 خانات)'
                  : 'Verify 6-Char Handover Code',
              isLoading: provider.isSubmitting,
              onPressed: () =>
                  _showHandoverVerificationModal(context, provider, req, isAr),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderOfferGateCard(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isAr,
  ) {
    final approved = provider.isApprovedProvider;
    return Container(
      key: const ValueKey('provider_offer_gate_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: approved ? AppColors.tealSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: approved
              ? AppColors.teal.withValues(alpha: 0.35)
              : AppColors.slateBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                approved
                    ? Icons.verified_user_rounded
                    : Icons.lock_person_outlined,
                color: approved ? AppColors.teal : AppColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  approved
                      ? (isAr
                          ? 'أنت مزود معتمد — يمكنك تقديم عرض توريد لهذا الطلب'
                          : 'Approved Provider — Submit a Supply Offer')
                      : (isAr
                          ? 'تقديم العروض متاح فقط للمزودين المعتمدين بالبطاقة القطرية (QID)'
                          : 'Only Approved QID-Verified Providers Can Submit Offers'),
                  style: AppTypography.title().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            approved
                ? (isAr
                    ? 'حدد أتعاب التوصيل ووقت الوصول التقديري بالريال القطري.'
                    : 'Propose your QAR delivery fee, item estimate, and ETA in minutes.')
                : (isAr
                    ? 'أكمل ملف المزود وارفع البطاقة القطرية للمراجعة والاعتماد قبل تقديم عروض التوريد.'
                    : 'Complete your provider profile and 11-digit QID verification to unlock bidding on worksite requests.'),
            style: AppTypography.bodySmall(color: AppColors.textSecondary)
                .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (approved)
            MashwarButton(
              key: const ValueKey('details_submit_offer_btn'),
              text: isAr ? 'تقديم عرض توريد' : 'Submit Offer',
              onPressed: () =>
                  _showSubmitOfferSheet(context, provider, req, isAr),
            )
          else
            OutlinedButton(
              key: const ValueKey('details_verify_provider_btn'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProviderProfileScreen(),
                  ),
                );
              },
              child: Text(
                isAr
                    ? 'إعداد وتوثيق حساب المزود (QID)'
                    : 'Complete Provider QID Verification',
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req, {
    required bool isRequester,
    required String? currentUid,
    required bool isAr,
  }) {
    final offers = provider.selectedOffers;
    final canAccept = isRequester &&
        (req.status == WorkRequestStatus.open ||
            req.status == WorkRequestStatus.offerReceived);

    final pendingOffers =
        offers.where((o) => o.status == 'pending').toList();
    int? minTotalMinor;
    bool hasDistinctPrices = false;
    int? minEtaMinutes;
    bool hasDistinctEtas = false;
    double maxRating = 0.0;
    bool hasTopRatedWinner = false;

    if (pendingOffers.length >= 2) {
      final totals = pendingOffers
          .map((o) =>
              (o.estimatedItemsCostMinor ?? req.estimatedItemsCostMinor)
                  .minorUnits +
              o.proposedFeeMinor.minorUnits)
          .toList();
      minTotalMinor = totals.reduce(math.min);
      hasDistinctPrices = totals.toSet().length > 1;

      final etas = pendingOffers.map((o) => o.estimatedEtaMinutes).toList();
      minEtaMinutes = etas.reduce(math.min);
      hasDistinctEtas = etas.toSet().length > 1;

      final ratings = pendingOffers.map((o) => o.providerRating).toList();
      maxRating = ratings.reduce(math.max);
      hasTopRatedWinner =
          maxRating > 0 && ratings.any((rating) => rating < maxRating);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr
                ? 'العروض المقدمة (${offers.length})'
                : 'Submitted Offers (${offers.length})',
            style: AppTypography.title().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (offers.isEmpty)
            Text(
              isAr
                  ? 'لم يتم استلام عروض على هذا الطلب حتى الآن.'
                  : 'No offers submitted for this request yet.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
            )
          else
            ...offers.map((offer) {
              final itemsMinor =
                  offer.estimatedItemsCostMinor ?? req.estimatedItemsCostMinor;
              final totalOfferMinor = itemsMinor + offer.proposedFeeMinor;
              final hasRealRating = offer.providerRating > 0;
              final isPending = offer.status == 'pending';
              final isOwnerProvider =
                  currentUid != null && currentUid == offer.providerId;

              final showLowestPrice = isPending &&
                  hasDistinctPrices &&
                  minTotalMinor != null &&
                  totalOfferMinor.minorUnits == minTotalMinor;
              final showFastestEta = isPending &&
                  hasDistinctEtas &&
                  minEtaMinutes != null &&
                  offer.estimatedEtaMinutes == minEtaMinutes;
              final showTopRated = isPending &&
                  hasTopRatedWinner &&
                  offer.providerRating == maxRating;

              return Container(
                key: ValueKey('offer_card_${offer.id}'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: offer.isSelected
                      ? AppColors.tealSurface
                      : (offer.status == 'withdrawn'
                          ? AppColors.offlineBg
                          : AppColors.slateBg),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: offer.isSelected
                        ? AppColors.teal
                        : AppColors.slateBorder,
                  ),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                offer.providerName,
                                style: AppTypography.body(color: AppColors.navy)
                                    .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            MashwarBadge(
                              type: offer.status == 'withdrawn' ||
                                      offer.status == 'rejected'
                                  ? BadgeType.suspended
                                  : BadgeType.verified,
                              customLabel: offer.status == 'withdrawn'
                                  ? (isAr ? 'تم السحب' : 'Withdrawn')
                                  : (offer.status == 'rejected'
                                      ? (isAr ? 'غير مختار' : 'Declined')
                                      : (isAr ? 'مزود معتمد' : 'Approved')),
                            ),
                          ],
                        ),
                        Text(
                          hasRealRating
                              ? '${offer.providerRating.toStringAsFixed(1)} ★ (${offer.providerCompletedJobs})'
                              : (isAr
                                  ? 'مزود جديد (${offer.providerCompletedJobs})'
                                  : 'New (${offer.providerCompletedJobs} jobs)'),
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (showLowestPrice || showFastestEta || showTopRated) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (showLowestPrice)
                            _buildOfferComparisonBadge(
                              key: ValueKey(
                                  'offer_badge_lowest_price_${offer.id}'),
                              icon: Icons.savings_outlined,
                              label: isAr ? 'الأقل سعراً' : 'Lowest Price',
                              color: AppColors.teal,
                              bgColor: AppColors.tealSurface,
                            ),
                          if (showFastestEta)
                            _buildOfferComparisonBadge(
                              key: ValueKey(
                                  'offer_badge_fastest_eta_${offer.id}'),
                              icon: Icons.bolt_rounded,
                              label: isAr ? 'الأسرع وصولاً' : 'Fastest ETA',
                              color: AppColors.navy,
                              bgColor: AppColors.cobaltSurface,
                            ),
                          if (showTopRated)
                            _buildOfferComparisonBadge(
                              key: ValueKey(
                                  'offer_badge_top_rated_${offer.id}'),
                              icon: Icons.star_rounded,
                              label: isAr ? 'الأعلى تقييماً' : 'Top Rated',
                              color: AppColors.navy,
                              bgColor: AppColors.sand,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          isAr
                              ? 'أتعاب التوريد: ${offer.proposedFeeMinor.format(isArabic: true)}'
                              : 'Service Fee: ${offer.proposedFeeMinor.format(isArabic: false)}',
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isAr
                              ? 'الإجمالي التقديري: ${totalOfferMinor.format(isArabic: true)}'
                              : 'Est. Total: ${totalOfferMinor.format(isArabic: false)}',
                          style: AppTypography.label(color: AppColors.teal)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isAr
                              ? 'الوصول خلال ${offer.estimatedEtaMinutes} دقيقة'
                              : 'ETA: ${offer.estimatedEtaMinutes} min',
                          style: AppTypography.label(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (offer.notes != null &&
                        offer.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        offer.notes!,
                        style: AppTypography.bodySmall(color: AppColors.navy),
                      ),
                    ],
                    if (canAccept && isPending) ...[
                      const SizedBox(height: 10),
                      MashwarButton(
                        key: ValueKey('accept_offer_btn_${offer.id}'),
                        text: isAr ? 'قبول هذا العرض' : 'Accept Offer',
                        height: 42,
                        isLoading: provider.isSubmitting,
                        onPressed: () {
                          provider.acceptOffer(
                            requestId: req.id,
                            offerId: offer.id,
                          );
                        },
                      ),
                    ],
                    if (isOwnerProvider && isPending) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: ValueKey('withdraw_offer_btn_${offer.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: AppColors.slateBorder, width: 1.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: provider.isSubmitting
                            ? null
                            : () {
                                provider.withdrawOffer(
                                  requestId: req.id,
                                  offerId: offer.id,
                                );
                              },
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text(
                          isAr ? 'سحب العرض' : 'Withdraw Offer',
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOfferComparisonBadge({
    Key? key,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.label(color: color).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(List<RequestEvent> events, bool isAr) {
    return Container(
      key: const ValueKey('request_events_timeline'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'سجل تتبع الطلب الزمني' : 'Request Audit Timeline',
            style: AppTypography.title().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              isAr ? 'لا توجد أحداث مسجلة بعد.' : 'No timeline events yet.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
            )
          else
            ...events.map((evt) {
              final ts = evt.createdAt.toLocal();
              final timeStr =
                  '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
              final statusTitle = evt.toStatus != null
                  ? evt.toStatus!.label(isArabic: isAr)
                  : evt.eventType;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 8,
                            children: [
                              Text(
                                statusTitle,
                                style: AppTypography.bodySecondary(
                                        color: AppColors.navy)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${evt.actorRole} · $timeStr',
                                style: AppTypography.label(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          if (evt.note != null && evt.note!.isNotEmpty)
                            Text(
                              evt.note!,
                              style: AppTypography.bodySmall(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showSubmitOfferSheet(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isAr,
  ) {
    final feeCtrl = TextEditingController(
      text: req.deliveryFeeBudgetMinor.toDecimalString(alwaysShowDecimals: false),
    );
    final itemsCtrl = TextEditingController(
      text:
          req.estimatedItemsCostMinor.toDecimalString(alwaysShowDecimals: false),
    );
    final etaCtrl = TextEditingController(text: '45');
    final notesCtrl = TextEditingController();
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
                      isAr ? 'تقديم عرض توريد وتوصيل' : 'Submit Supply Offer',
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    if (modalErr != null) ...[
                      Text(modalErr!,
                          style: AppTypography.label(color: AppColors.danger)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      key: const ValueKey('offer_fee_qar_input'),
                      controller: feeCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'رسوم التوصيل المقترحة (QAR) *'
                            : 'Proposed Delivery Fee (QAR) *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('offer_items_qar_input'),
                      controller: itemsCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'تقدير تكلفة المشتريات (QAR)'
                            : 'Estimated Items Cost (QAR)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('offer_eta_input'),
                      controller: etaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'مدة التوصيل التقديرية (بالدقائق) *'
                            : 'Estimated ETA (minutes) *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('offer_notes_input'),
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: isAr ? 'ملاحظات العرض' : 'Offer Notes',
                      ),
                    ),
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_submit_offer_btn'),
                      text: isAr ? 'إرسال العرض' : 'Send Offer',
                      onPressed: () async {
                        MoneyMinor? fee;
                        MoneyMinor? items;
                        try {
                          fee = MoneyMinor.fromDecimalString(feeCtrl.text);
                          if (itemsCtrl.text.trim().isNotEmpty) {
                            items =
                                MoneyMinor.fromDecimalString(itemsCtrl.text);
                          }
                        } catch (_) {
                          setModalState(() {
                            modalErr = isAr
                                ? 'يرجى إدخال مبالغ صحيحة بالريال القطري.'
                                : 'Please enter valid QAR amounts.';
                          });
                          return;
                        }
                        final eta = int.tryParse(etaCtrl.text.trim()) ?? 0;
                        if (fee.minorUnits <= 0 || eta <= 0) {
                          setModalState(() {
                            modalErr = isAr
                                ? 'الرسوم ومدة الوصول يجب أن تكون أكبر من صفر.'
                                : 'Fee and ETA must be greater than zero.';
                          });
                          return;
                        }
                        final res = await provider.submitOffer(
                          requestId: req.id,
                          proposedFeeMinor: fee,
                          estimatedItemsCostMinor: items,
                          estimatedEtaMinutes: eta,
                          notes: notesCtrl.text.trim().isNotEmpty
                              ? notesCtrl.text.trim()
                              : null,
                        );
                        if (!sheetCtx.mounted) return;
                        if (res != null) {
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

  void _showAdvanceStageSheet(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    WorkRequestStatus nextStage,
    bool isAr,
  ) {
    final invoiceUrlCtrl =
        TextEditingController(text: req.receiptImageUrl ?? '');
    final actualReceiptCtrl = TextEditingController(
      text: req.actualReceiptTotalMinor
              ?.toDecimalString(alwaysShowDecimals: false) ??
          '',
    );
    final noteCtrl = TextEditingController();
    final auth = context.read<AuthProvider?>();
    String? modalErr;
    bool isUploadingInvoice = false;
    MediaUploadResult? uploadedInvoice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            Future<void> pickInvoice(ImageSource source) async {
              setModalState(() {
                isUploadingInvoice = true;
                modalErr = null;
              });
              try {
                final res = await MediaUploadService.instance
                    .pickAndUploadWorkRequestInvoice(
                  requestId: req.id,
                  source: source,
                  allowDevMocks: auth?.isDevMockAuthEnabled ?? false,
                );
                if (!sheetCtx.mounted) return;
                setModalState(() {
                  isUploadingInvoice = false;
                  if (res != null) {
                    uploadedInvoice = res;
                    invoiceUrlCtrl.text = res.downloadUrl;
                  }
                });
              } on MediaUploadException catch (e) {
                if (!sheetCtx.mounted) return;
                setModalState(() {
                  isUploadingInvoice = false;
                  modalErr = e.localizedMessage(isArabic: isAr);
                });
              } catch (e) {
                if (!sheetCtx.mounted) return;
                setModalState(() {
                  isUploadingInvoice = false;
                  modalErr = isAr
                      ? 'تعذّر رفع صورة الفاتورة: $e'
                      : 'Failed to upload invoice image: $e';
                });
              }
            }

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
                      _nextStageCtaLabel(nextStage, isAr),
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    if (modalErr != null) ...[
                      Container(
                        key: const ValueKey('stage_invoice_upload_error'),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          modalErr!,
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      key: const ValueKey('upload_stage_invoice_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: AppColors.slateBorder, width: 1.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isUploadingInvoice
                          ? null
                          : () => pickInvoice(ImageSource.gallery),
                      icon: isUploadingInvoice
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.navy,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined,
                              size: 18, color: AppColors.teal),
                      label: Text(
                        isUploadingInvoice
                            ? (isAr
                                ? 'جاري رفع فاتورة الشراء...'
                                : 'Uploading store invoice...')
                            : (isAr
                                ? 'رفع صورة فاتورة المتجر (حتى 10MB)'
                                : 'Upload Store Invoice Photo (<= 10 MB)'),
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (uploadedInvoice != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        key: const ValueKey('stage_invoice_uploaded_pill'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                uploadedInvoice!.bytes,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppColors.teal,
                                    size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${uploadedInvoice!.fileName} (${uploadedInvoice!.formattedSize})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(color: AppColors.navy)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('stage_invoice_url_input'),
                      controller: invoiceUrlCtrl,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'رابط صورة فاتورة الشراء (تلقائي بعد الرفع)'
                            : 'Store Invoice Photo URL (Populated on Upload)',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('stage_actual_total_input'),
                      controller: actualReceiptCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'إجمالي الفاتورة الفعلي (QAR)'
                            : 'Actual Receipt Total (QAR)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'ملاحظة التحديث' : 'Fulfillment Note',
                      ),
                    ),
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_stage_update_btn'),
                      text: isAr ? 'حفظ وتحديث الحالة' : 'Confirm Stage Update',
                      onPressed: () async {
                        MoneyMinor? actualTotal;
                        if (actualReceiptCtrl.text.trim().isNotEmpty) {
                          try {
                            actualTotal = MoneyMinor.fromDecimalString(
                                actualReceiptCtrl.text.trim());
                          } catch (_) {
                            setModalState(() {
                              modalErr = isAr
                                  ? 'أدخل قيمة صحيحة للفاتورة بالريال القطري.'
                                  : 'Enter a valid QAR receipt total.';
                            });
                            return;
                          }
                        }
                        final updated = await provider.advanceStatus(
                          requestId: req.id,
                          nextStatus: nextStage,
                          actorRole: 'provider',
                          receiptImageUrl: invoiceUrlCtrl.text.trim().isNotEmpty
                              ? invoiceUrlCtrl.text.trim()
                              : null,
                          actualReceiptTotalMinor: actualTotal,
                          note: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : null,
                        );
                        if (!sheetCtx.mounted) return;
                        if (updated != null) {
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

  void _showHandoverVerificationModal(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isAr,
  ) {
    final codeCtrl = TextEditingController();
    String? feedbackError;
    String? feedbackSuccess;
    bool isSubmittingLocal = false;

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
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isAr
                          ? 'التحقق من التسليم (QR أو الكود)'
                          : 'Verify Handover (QR or 6-Char Code)',
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'امسح رمز QR الظاهر على شاشة مسؤول الموقع أو أدخل الكود المكون من 6 أحرف/أرقام يدوياً.'
                          : 'Scan the requester\'s QR code or enter the 6-character code manually to complete delivery.',
                      style: AppTypography.bodySmall(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('handover_scan_qr_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: AppColors.slateBorder, width: 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmittingLocal
                          ? null
                          : () async {
                              final scanned = await showMashwarQrScanSheet(
                                sheetCtx,
                                isAr: isAr,
                                referenceId: req.id,
                                expectedLength: 6,
                                onEmergencyFallbackLogged: (record) {
                                  if (!sheetCtx.mounted) return;
                                  setModalState(() {
                                    feedbackError = null;
                                    feedbackSuccess = isAr
                                        ? 'تم تسجيل تسليم طوارئ (${record.fallbackRef}) باسم ${record.backupContactName}'
                                        : 'Emergency fallback logged (${record.fallbackRef}) for ${record.backupContactName}';
                                  });
                                },
                              );
                              if (scanned != null &&
                                  scanned.trim().isNotEmpty &&
                                  sheetCtx.mounted) {
                                setModalState(() {
                                  codeCtrl.text = scanned.trim().toUpperCase();
                                  feedbackError = null;
                                });
                              }
                            },
                      icon: const Icon(Icons.qr_code_scanner_rounded,
                          size: 19, color: AppColors.teal),
                      label: Text(
                        isAr
                            ? 'مسح رمز QR بالكاميرا'
                            : 'Scan Handover QR with Camera',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        key: const ValueKey('handover_code_input'),
                        controller: codeCtrl,
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: AppTypography.title(color: AppColors.navy)
                            .copyWith(letterSpacing: 6, fontSize: 22),
                        decoration: InputDecoration(
                          hintText: 'A2B3C4',
                          labelText: isAr
                              ? 'أو أدخل الكود يدوياً (6 خانات)'
                              : 'Or enter 6-char code manually',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const ValueKey('handover_modal_contingency_btn'),
                      onPressed: () {
                        showMashwarHandoverContingencySheet(
                          sheetCtx,
                          isAr: isAr,
                          referenceId: req.id,
                          onEmergencyFallbackLogged: (record) {
                            if (!sheetCtx.mounted) return;
                            setModalState(() {
                              feedbackError = null;
                              feedbackSuccess = isAr
                                  ? 'تم توثيق تسليم الطوارئ (${record.fallbackRef}) باسم ${record.backupContactName}'
                                  : 'Emergency handover logged (${record.fallbackRef}) for ${record.backupContactName}';
                            });
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.battery_alert_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      label: Text(
                        isAr
                            ? 'الكاميرا معطّلة أو بطارية الموبايل فصلت؟ عرض الحلول البديلة'
                            : 'Camera broken or dead battery? Emergency fallbacks',
                        textAlign: TextAlign.center,
                        style: AppTypography.label(color: AppColors.warning)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (feedbackError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        key: const ValueKey('handover_modal_error'),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          feedbackError!,
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    if (feedbackSuccess != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        key: const ValueKey('handover_modal_success'),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          feedbackSuccess!,
                          style: AppTypography.label(color: AppColors.teal)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('handover_confirm_btn'),
                      text: isAr
                          ? 'تأكيد الرمز وإتمام الطلب'
                          : 'Verify & Complete Delivery',
                      isLoading: isSubmittingLocal,
                      onPressed: () async {
                        final code = codeCtrl.text.trim().toUpperCase();
                        if (code.length != 6) {
                          setModalState(() {
                            feedbackError = isAr
                                ? 'رمز التسليم يجب أن يتكون من 6 خانات.'
                                : 'Handover code must be exactly 6 characters.';
                            feedbackSuccess = null;
                          });
                          return;
                        }
                        setModalState(() {
                          isSubmittingLocal = true;
                          feedbackError = null;
                        });
                        final result =
                            await provider.verifyHandoverCode(req.id, code);
                        if (!sheetCtx.mounted) return;
                        if (result != null && result.verified) {
                          setModalState(() {
                            isSubmittingLocal = false;
                            feedbackSuccess = result.message;
                          });
                          Navigator.of(sheetCtx).pop();
                        } else {
                          setModalState(() {
                            isSubmittingLocal = false;
                            feedbackError =
                                provider.localizedError(isArabic: isAr) ??
                                    (isAr
                                        ? 'رمز التسليم غير صحيح.'
                                        : 'Invalid handover code.');
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

  Future<bool> _launchExternalUri(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    final override = WorkRequestDetailsScreen.debugUrlLauncher;
    if (override != null) {
      return override(uri, mode: mode);
    }
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }

  Future<void> _launchSitePhoneCall(
    BuildContext context,
    String rawPhone,
    bool isAr,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final normalized = digits.startsWith('+')
        ? digits
        : (digits.length == 8 ? '+974$digits' : digits);
    final launched = await _launchExternalUri(
      Uri(scheme: 'tel', path: normalized),
    );
    if (!launched) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'لا يدعم هذا الجهاز الاتصال المباشر. يمكنك الاتصال يدوياً على $normalized'
                : 'This device cannot launch phone calls directly. Please dial $normalized manually.',
          ),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  Future<void> _launchSupportEmail(
    BuildContext context,
    WorkRequest req,
    bool isAr,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final subject =
        Uri.encodeComponent('MASHWAR Qatar Order #${req.id} - ${req.title}');
    final uri = Uri.parse('mailto:ops@mashwar.qa?subject=$subject');
    final launched = await _launchExternalUri(uri);
    if (!launched) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تعذّر فتح تطبيق البريد تلقائياً. راسلنا على ops@mashwar.qa بخصوص الطلب #${req.id}'
                : 'No email handler configured on this device. Contact ops@mashwar.qa regarding #${req.id}.',
          ),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  void _showTransferProofModal(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isAr,
  ) {
    final auth = context.read<AuthProvider?>();
    final proofCtrl = TextEditingController(
      text: req.paymentProofUrl ?? '',
    );
    final refCtrl = TextEditingController(
      text: req.paymentReference ?? '',
    );
    String? modalErr;
    bool isUploadingProof = false;
    MediaUploadResult? uploadedProof;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            Future<void> pickProofImage() async {
              setModalState(() {
                isUploadingProof = true;
                modalErr = null;
              });
              try {
                final res = await MediaUploadService.instance
                    .pickAndUploadWorkRequestPaymentProof(
                  requestId: req.id,
                  source: ImageSource.gallery,
                  allowDevMocks: auth?.isDevMockAuthEnabled ?? false,
                );
                if (!sheetCtx.mounted) return;
                setModalState(() {
                  isUploadingProof = false;
                  if (res != null) {
                    uploadedProof = res;
                    proofCtrl.text = res.downloadUrl;
                  }
                });
              } on MediaUploadException catch (e) {
                if (!sheetCtx.mounted) return;
                setModalState(() {
                  isUploadingProof = false;
                  modalErr = e.localizedMessage(isArabic: isAr);
                });
              } catch (e) {
                if (!sheetCtx.mounted) return;
                setModalState(() {
                  isUploadingProof = false;
                  modalErr = isAr
                      ? 'تعذّر رفع صورة إيصال التحويل: $e'
                      : 'Failed to upload transfer proof image: $e';
                });
              }
            }

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
                      isAr
                          ? 'رفع إيصال التحويل البنكي'
                          : 'Submit Bank Transfer Proof',
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    if (modalErr != null) ...[
                      Container(
                        key: const ValueKey('transfer_proof_upload_error'),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          modalErr!,
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      key: const ValueKey('pick_transfer_proof_image_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: AppColors.slateBorder, width: 1.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isUploadingProof ? null : pickProofImage,
                      icon: isUploadingProof
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
                        isUploadingProof
                            ? (isAr
                                ? 'جاري رفع إيصال التحويل...'
                                : 'Uploading transfer receipt...')
                            : (isAr
                                ? 'اختيار ورفع صورة الإيصال (حتى 10MB)'
                                : 'Select & Upload Transfer Receipt (<= 10 MB)'),
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (uploadedProof != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        key: const ValueKey('transfer_proof_uploaded_pill'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                uploadedProof!.bytes,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.account_balance_rounded,
                                    color: AppColors.teal,
                                    size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${uploadedProof!.fileName} (${uploadedProof!.formattedSize})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(color: AppColors.navy)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('transfer_proof_url_input'),
                      controller: proofCtrl,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'رابط صورة إيصال التحويل *'
                            : 'Transfer Receipt URL *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('transfer_ref_input'),
                      controller: refCtrl,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'رقم المرجع البنكي / فوراً'
                            : 'Bank / Fawran Reference Number',
                      ),
                    ),
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_transfer_proof_btn'),
                      text: isAr ? 'تأكيد رفع الإيصال' : 'Submit Proof',
                      onPressed: () async {
                        final res = await provider.submitTransferProof(
                          requestId: req.id,
                          proofUrl: proofCtrl.text.trim(),
                          referenceNumber: refCtrl.text.trim().isNotEmpty
                              ? refCtrl.text.trim()
                              : null,
                        );
                        if (!sheetCtx.mounted) return;
                        if (res != null) {
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

  void _showRatingModal(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req, {
    required bool isRequester,
    required bool isAr,
  }) {
    int selectedStars = 5;
    final commentCtrl = TextEditingController();
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
                      isAr ? 'تقييم تجربة التوريد' : 'Rate Supply Experience',
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          icon: Icon(
                            star <= selectedStars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.gold,
                            size: 32,
                          ),
                          onPressed: () =>
                              setModalState(() => selectedStars = star),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'ملاحظات إضافية (اختياري)' : 'Comment',
                      ),
                    ),
                    if (modalErr != null) ...[
                      const SizedBox(height: 8),
                      Text(modalErr!,
                          style: AppTypography.label(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_rating_btn'),
                      text: isAr ? 'إرسال التقييم' : 'Submit Review',
                      onPressed: () async {
                        final targetId = isRequester
                            ? (req.assignedProviderId ?? '')
                            : req.requesterId;
                        final rating = await provider.submitRating(
                          requestId: req.id,
                          raterRole: isRequester ? 'requester' : 'provider',
                          targetUserId: targetId,
                          score: selectedStars,
                          comment: commentCtrl.text.trim().isNotEmpty
                              ? commentCtrl.text.trim()
                              : null,
                        );
                        if (!sheetCtx.mounted) return;
                        if (rating != null) {
                          setState(() => _hasSubmittedRating = true);
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

  void _showDisputeModal(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req, {
    required String reporterRole,
    required bool isAr,
  }) {
    final reasonCtrl = TextEditingController();
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
                      isAr ? 'الإبلاغ عن نزاع تشغيلي' : 'Report Request Dispute',
                      style: AppTypography.title().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('dispute_reason_input'),
                      controller: reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isAr ? 'سبب النزاع *' : 'Dispute Reason *',
                        hintText: isAr
                            ? 'اشرح المشكلة المتعلقة بالمواد أو الفاتورة أو التسليم...'
                            : 'Describe the issue with items, invoice, or delivery...',
                      ),
                    ),
                    if (modalErr != null) ...[
                      const SizedBox(height: 8),
                      Text(modalErr!,
                          style: AppTypography.label(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_dispute_btn'),
                      text: isAr ? 'تأكيد فتح النزاع' : 'Submit Dispute',
                      variant: MashwarButtonVariant.danger,
                      onPressed: () async {
                        if (reasonCtrl.text.trim().isEmpty) {
                          setModalState(() {
                            modalErr = isAr
                                ? 'يرجى كتابة سبب النزاع.'
                                : 'Please enter a dispute reason.';
                          });
                          return;
                        }
                        final updated = await provider.reportDispute(
                          requestId: req.id,
                          reporterRole: reporterRole,
                          reason: reasonCtrl.text.trim(),
                        );
                        if (!sheetCtx.mounted) return;
                        if (updated != null) {
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

  void _showCancelRequestSheet(
    BuildContext context,
    WorksiteProvider provider,
    WorkRequest req,
    bool isAr,
  ) {
    final reasonCtrl = TextEditingController();
    final quickReasons = isAr
        ? const [
            'تم تأمين المواد محلياً من مورد آخر',
            'تعديل جدول أو مواصفات الموقع',
            'تغيير الكمية أو الميزانية المطلوبة',
          ]
        : const [
            'Sourced items directly near worksite',
            'Worksite schedule or specs changed',
            'Need to adjust quantity or QAR budget',
          ];
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
                top: 16,
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MashwarSheetHeader(
                      title: isAr
                          ? 'تأكيد إلغاء طلب التوريد'
                          : 'Cancel Supply Request',
                      subtitle: isAr
                          ? 'يمكنك إلغاء الطلب مجاناً قبل اختيار العرض وبدء الشراء.'
                          : 'You can cancel this request before offer acceptance and store pickup.',
                      leadingIcon: Icons.cancel_outlined,
                      onClose: () => Navigator.of(sheetCtx).pop(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickReasons.map((preset) {
                        return ActionChip(
                          label: Text(
                            preset,
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(fontSize: 11),
                          ),
                          backgroundColor: AppColors.slateBg,
                          onPressed: () {
                            setModalState(() {
                              reasonCtrl.text = preset;
                              modalErr = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('cancel_reason_input'),
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'سبب الإلغاء (اختياري)'
                            : 'Cancellation Reason (Optional)',
                        hintText: isAr
                            ? 'أدخل سبب إلغاء الطلب...'
                            : 'Share why this request is being cancelled...',
                      ),
                    ),
                    if (modalErr != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        modalErr!,
                        style: AppTypography.label(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 16),
                    MashwarButton(
                      key: const ValueKey('confirm_cancel_request_btn'),
                      text: isAr
                          ? 'تأكيد إلغاء الطلب'
                          : 'Confirm Request Cancellation',
                      variant: MashwarButtonVariant.danger,
                      isLoading: provider.isSubmitting,
                      onPressed: () async {
                        final updated = await provider.cancelRequest(
                          requestId: req.id,
                          reason: reasonCtrl.text.trim().isNotEmpty
                              ? reasonCtrl.text.trim()
                              : null,
                        );
                        if (!sheetCtx.mounted) return;
                        if (updated != null) {
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
