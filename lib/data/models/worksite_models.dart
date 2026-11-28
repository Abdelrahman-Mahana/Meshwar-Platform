import 'package:flutter/foundation.dart';

/// Immutable integer minor-unit money wrapper for QAR (`1 QAR = 100 dirhams/fils`).
///
/// All new MVP models use [MoneyMinor] (serialized as integer `minorUnits`)
/// rather than floating-point `double` fields to eliminate rounding drift.
@immutable
class MoneyMinor implements Comparable<MoneyMinor> {
  static const int minorPerMajor = 100;
  static const String defaultCurrency = 'QAR';

  final int minorUnits;
  final String currency;

  const MoneyMinor(
    this.minorUnits, {
    this.currency = defaultCurrency,
  });

  const MoneyMinor.zero({this.currency = defaultCurrency}) : minorUnits = 0;

  factory MoneyMinor.fromMajorQar(
    int qar, {
    String currency = defaultCurrency,
  }) {
    return MoneyMinor(qar * minorPerMajor, currency: currency);
  }

  /// Parses a decimal string such as `'150'`, `'150.5'`, `'150.00'`, or `'-12.25'`
  /// strictly with integer arithmetic (zero `double` conversion).
  factory MoneyMinor.fromDecimalString(
    String raw, {
    String currency = defaultCurrency,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty money string');
    }
    final negative = trimmed.startsWith('-');
    final unsigned = negative || trimmed.startsWith('+')
        ? trimmed.substring(1)
        : trimmed;
    if (unsigned.isEmpty) {
      throw FormatException('Invalid money string: $raw');
    }

    final parts = unsigned.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid decimal money string: $raw');
    }

    final majorPart = parts[0].isEmpty ? '0' : parts[0];
    if (!RegExp(r'^[0-9]+$').hasMatch(majorPart)) {
      throw FormatException('Invalid major units in money string: $raw');
    }
    final major = int.parse(majorPart);

    int minor = 0;
    if (parts.length == 2) {
      final frac = parts[1];
      if (frac.isEmpty || frac.length > 2 || !RegExp(r'^[0-9]+$').hasMatch(frac)) {
        throw FormatException('Invalid fractional units (max 2 decimals): $raw');
      }
      minor = frac.length == 1 ? int.parse(frac) * 10 : int.parse(frac);
    }

    final total = major * minorPerMajor + minor;
    return MoneyMinor(negative ? -total : total, currency: currency);
  }

  /// Deserializes minor units from `int`, `num` (truncated via `toInt`),
  /// decimal `String`, or `{'minorUnits': int, 'currency': String}`.
  factory MoneyMinor.fromJson(
    dynamic value, {
    String currency = defaultCurrency,
  }) {
    if (value == null) {
      return MoneyMinor.zero(currency: currency);
    }
    if (value is MoneyMinor) {
      return value;
    }
    if (value is int) {
      return MoneyMinor(value, currency: currency);
    }
    if (value is num) {
      return MoneyMinor(value.round(), currency: currency);
    }
    if (value is String) {
      final asInt = int.tryParse(value.trim());
      if (asInt != null) {
        return MoneyMinor(asInt, currency: currency);
      }
      return MoneyMinor.fromDecimalString(value, currency: currency);
    }
    if (value is Map) {
      final units = (value['minorUnits'] as num?)?.toInt() ?? 0;
      final curr = (value['currency'] as String?) ?? currency;
      return MoneyMinor(units, currency: curr);
    }
    throw ArgumentError.value(value, 'value', 'Unsupported MoneyMinor JSON');
  }

  static MoneyMinor? tryParseNullable(dynamic value) {
    if (value == null) return null;
    return MoneyMinor.fromJson(value);
  }

  int toJson() => minorUnits;

  Map<String, dynamic> toMap() => {
        'minorUnits': minorUnits,
        'currency': currency,
      };

  int get wholeQar => minorUnits ~/ minorPerMajor;
  int get remainderMinor => minorUnits.abs() % minorPerMajor;
  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  String toDecimalString({bool alwaysShowDecimals = true}) {
    final sign = minorUnits < 0 ? '-' : '';
    final absUnits = minorUnits.abs();
    final major = absUnits ~/ minorPerMajor;
    final frac = absUnits % minorPerMajor;
    if (!alwaysShowDecimals && frac == 0) {
      return '$sign$major';
    }
    return '$sign$major.${frac.toString().padLeft(2, '0')}';
  }

  /// Formats for display, e.g.:
  /// - `15000` with `forceDecimals: true` -> `'150.00 QAR'` / `'150.00 ر.ق'`
  /// - `15000` with `forceDecimals: false` -> `'150 QAR'` / `'150 ر.ق'`
  /// - `15050` -> `'150.50 QAR'` / `'150.50 ر.ق'`
  String format({
    bool isArabic = false,
    bool forceDecimals = false,
  }) {
    final amountStr = toDecimalString(
      alwaysShowDecimals: forceDecimals || remainderMinor != 0,
    );
    final unit = isArabic ? 'ر.ق' : currency;
    return '$amountStr $unit';
  }

  String formatQar({bool forceDecimals = false}) =>
      format(isArabic: false, forceDecimals: forceDecimals);

  String formatArabic({bool forceDecimals = false}) =>
      format(isArabic: true, forceDecimals: forceDecimals);

  MoneyMinor operator +(MoneyMinor other) {
    _assertSameCurrency(other);
    return MoneyMinor(minorUnits + other.minorUnits, currency: currency);
  }

  MoneyMinor operator -(MoneyMinor other) {
    _assertSameCurrency(other);
    return MoneyMinor(minorUnits - other.minorUnits, currency: currency);
  }

  MoneyMinor operator -() => MoneyMinor(-minorUnits, currency: currency);

  void _assertSameCurrency(MoneyMinor other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Currency mismatch: cannot combine $currency and ${other.currency}',
      );
    }
  }

  @override
  int compareTo(MoneyMinor other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MoneyMinor &&
            other.minorUnits == minorUnits &&
            other.currency == currency);
  }

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => formatQar(forceDecimals: true);
}

/// Canonical snake_case Worksite Supply request lifecycle statuses.
enum WorkRequestStatus {
  open('open'),
  offerReceived('offer_received'),
  offerSelected('offer_selected'),
  accepted('accepted'),
  inProgress('in_progress'),
  pickedUp('picked_up'),
  inTransit('in_transit'),
  deliveredPendingConfirmation('delivered_pending_confirmation'),
  completed('completed'),
  cancelled('cancelled'),
  disputed('disputed');

  final String value;
  const WorkRequestStatus(this.value);

  static WorkRequestStatus fromString(String raw) {
    final normalized = raw.trim();
    for (final status in WorkRequestStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    throw ArgumentError.value(
      raw,
      'status',
      'Unknown WorkRequestStatus; expected exact snake_case status',
    );
  }

  static WorkRequestStatus? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.trim();
    for (final status in WorkRequestStatus.values) {
      if (status.value == normalized) return status;
    }
    return null;
  }
}

/// Canonical Worksite Supply status transition validator & RBAC guard.
class WorkRequestStatusMachine {
  WorkRequestStatusMachine._();

  static const Set<String> allowedStatusStrings = {
    'open',
    'offer_received',
    'offer_selected',
    'accepted',
    'in_progress',
    'picked_up',
    'in_transit',
    'delivered_pending_confirmation',
    'completed',
    'cancelled',
    'disputed',
  };

  static const Set<String> allowedRoles = {
    'requester',
    'provider',
    'admin',
    'system',
  };

  static bool isValidStatusString(String raw) =>
      allowedStatusStrings.contains(raw);

  static bool isTerminal(WorkRequestStatus status) =>
      status == WorkRequestStatus.completed ||
      status == WorkRequestStatus.cancelled;

  /// Enforces allowed transitions across requester, assigned approved provider,
  /// system, and admin roles:
  /// - Requesters CANNOT mark `completed`.
  /// - Providers CANNOT select offers or accept another provider's job.
  /// - Unapproved providers CANNOT submit offers, accept, or advance fulfillment.
  /// - Provider completion from `delivered_pending_confirmation` requires
  ///   [handoverCodeVerified] to be `true`.
  static bool canTransition(
    WorkRequestStatus from,
    WorkRequestStatus to, {
    required String actorRole,
    String? actorId,
    String? requesterId,
    String? assignedProviderId,
    String? selectedOfferProviderId,
    bool isProviderApproved = true,
    bool handoverCodeVerified = false,
  }) {
    final role = actorRole.trim().toLowerCase();
    if (!allowedRoles.contains(role)) return false;
    if (isTerminal(from)) return false;

    if (role == 'requester' &&
        actorId != null &&
        requesterId != null &&
        actorId != requesterId) {
      return false;
    }

    if (role == 'provider') {
      if (!isProviderApproved) return false;
      if (actorId != null && requesterId != null && actorId == requesterId) {
        return false;
      }
    }

    switch (from) {
      case WorkRequestStatus.open:
        switch (to) {
          case WorkRequestStatus.offerReceived:
            return role == 'provider' || role == 'system' || role == 'admin';
          case WorkRequestStatus.cancelled:
            return role == 'requester' || role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.offerReceived:
        switch (to) {
          case WorkRequestStatus.offerReceived:
            return role == 'provider' || role == 'system' || role == 'admin';
          case WorkRequestStatus.offerSelected:
            return role == 'requester' || role == 'admin';
          case WorkRequestStatus.cancelled:
            return role == 'requester' || role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.offerSelected:
        switch (to) {
          case WorkRequestStatus.accepted:
            if (role == 'admin') return true;
            if (role != 'provider') return false;
            return _matchesExpectedProvider(
              actorId: actorId,
              expectedProviderId: selectedOfferProviderId ?? assignedProviderId,
            );
          case WorkRequestStatus.open:
            return role == 'requester' || role == 'admin';
          case WorkRequestStatus.cancelled:
            return role == 'requester' || role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.accepted:
        switch (to) {
          case WorkRequestStatus.inProgress:
          case WorkRequestStatus.pickedUp:
            if (role == 'admin') return true;
            if (role != 'provider') return false;
            return _matchesExpectedProvider(
              actorId: actorId,
              expectedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.cancelled:
            if (role == 'requester' || role == 'admin') return true;
            if (role == 'provider') {
              return _matchesExpectedProvider(
                actorId: actorId,
                expectedProviderId: assignedProviderId,
              );
            }
            return false;
          case WorkRequestStatus.disputed:
            return _canDispute(
              role: role,
              actorId: actorId,
              assignedProviderId: assignedProviderId,
            );
          default:
            return false;
        }

      case WorkRequestStatus.inProgress:
        switch (to) {
          case WorkRequestStatus.pickedUp:
          case WorkRequestStatus.inTransit:
            if (role == 'admin') return true;
            if (role != 'provider') return false;
            return _matchesExpectedProvider(
              actorId: actorId,
              expectedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.disputed:
            return _canDispute(
              role: role,
              actorId: actorId,
              assignedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.cancelled:
            return role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.pickedUp:
        switch (to) {
          case WorkRequestStatus.inTransit:
          case WorkRequestStatus.deliveredPendingConfirmation:
            if (role == 'admin') return true;
            if (role != 'provider') return false;
            return _matchesExpectedProvider(
              actorId: actorId,
              expectedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.disputed:
            return _canDispute(
              role: role,
              actorId: actorId,
              assignedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.cancelled:
            return role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.inTransit:
        switch (to) {
          case WorkRequestStatus.deliveredPendingConfirmation:
            if (role == 'admin') return true;
            if (role != 'provider') return false;
            return _matchesExpectedProvider(
              actorId: actorId,
              expectedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.disputed:
            return _canDispute(
              role: role,
              actorId: actorId,
              assignedProviderId: assignedProviderId,
            );
          case WorkRequestStatus.cancelled:
            return role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.deliveredPendingConfirmation:
        switch (to) {
          case WorkRequestStatus.completed:
            if (role == 'requester') return false;
            if (role == 'admin' || role == 'system') return true;
            if (role == 'provider') {
              return handoverCodeVerified &&
                  _matchesExpectedProvider(
                    actorId: actorId,
                    expectedProviderId: assignedProviderId,
                  );
            }
            return false;
          case WorkRequestStatus.disputed:
            return _canDispute(
              role: role,
              actorId: actorId,
              assignedProviderId: assignedProviderId,
            );
          default:
            return false;
        }

      case WorkRequestStatus.disputed:
        switch (to) {
          case WorkRequestStatus.completed:
          case WorkRequestStatus.cancelled:
          case WorkRequestStatus.inTransit:
            return role == 'admin';
          default:
            return false;
        }

      case WorkRequestStatus.completed:
      case WorkRequestStatus.cancelled:
        return false;
    }
  }

  static bool _matchesExpectedProvider({
    required String? actorId,
    required String? expectedProviderId,
  }) {
    if (expectedProviderId == null || expectedProviderId.isEmpty) {
      return actorId == null || actorId.isNotEmpty;
    }
    return actorId != null && actorId == expectedProviderId;
  }

  static bool _canDispute({
    required String role,
    required String? actorId,
    required String? assignedProviderId,
  }) {
    if (role == 'requester' || role == 'admin') return true;
    if (role == 'provider') {
      return _matchesExpectedProvider(
        actorId: actorId,
        expectedProviderId: assignedProviderId,
      );
    }
    return false;
  }

  static void assertTransition(
    WorkRequestStatus from,
    WorkRequestStatus to, {
    required String actorRole,
    String? actorId,
    String? requesterId,
    String? assignedProviderId,
    String? selectedOfferProviderId,
    bool isProviderApproved = true,
    bool handoverCodeVerified = false,
  }) {
    final allowed = canTransition(
      from,
      to,
      actorRole: actorRole,
      actorId: actorId,
      requesterId: requesterId,
      assignedProviderId: assignedProviderId,
      selectedOfferProviderId: selectedOfferProviderId,
      isProviderApproved: isProviderApproved,
      handoverCodeVerified: handoverCodeVerified,
    );
    if (!allowed) {
      throw StateError(
        'Transition ${from.value} -> ${to.value} not permitted for role=$actorRole',
      );
    }
  }

  static Set<WorkRequestStatus> allowedNextStatuses(
    WorkRequestStatus from, {
    required String actorRole,
    String? actorId,
    String? requesterId,
    String? assignedProviderId,
    String? selectedOfferProviderId,
    bool isProviderApproved = true,
    bool handoverCodeVerified = false,
  }) {
    return WorkRequestStatus.values
        .where(
          (candidate) => canTransition(
            from,
            candidate,
            actorRole: actorRole,
            actorId: actorId,
            requesterId: requesterId,
            assignedProviderId: assignedProviderId,
            selectedOfferProviderId: selectedOfferProviderId,
            isProviderApproved: isProviderApproved,
            handoverCodeVerified: handoverCodeVerified,
          ),
        )
        .toSet();
  }
}

/// Supported settlement methods in Qatar Worksite Supply Pilot Phase 1.
enum PaymentMethod {
  cashOnDelivery('cash_on_delivery'),
  bankTransferManual('bank_transfer_manual');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String raw) {
    final normalized = raw.trim();
    for (final method in PaymentMethod.values) {
      if (method.value == normalized) return method;
    }
    throw ArgumentError.value(raw, 'paymentMethod', 'Unknown PaymentMethod');
  }

  static PaymentMethod? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final method in PaymentMethod.values) {
      if (method.value == raw.trim()) return method;
    }
    return null;
  }
}

/// Settlement tracking status for cash on delivery or manual bank transfer.
enum PaymentSettlementStatus {
  unpaid('unpaid'),
  transferProofSubmitted('transfer_proof_submitted'),
  verifiedSettled('verified_settled'),
  disputed('disputed');

  final String value;
  const PaymentSettlementStatus(this.value);

  static PaymentSettlementStatus fromString(String raw) {
    final normalized = raw.trim();
    for (final status in PaymentSettlementStatus.values) {
      if (status.value == normalized) return status;
    }
    throw ArgumentError.value(
      raw,
      'paymentSettlementStatus',
      'Unknown PaymentSettlementStatus',
    );
  }

  static PaymentSettlementStatus? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final status in PaymentSettlementStatus.values) {
      if (status.value == raw.trim()) return status;
    }
    return null;
  }
}

/// Provider onboarding & QID review status.
enum ProviderApprovalStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  suspended('suspended');

  final String value;
  const ProviderApprovalStatus(this.value);

  static ProviderApprovalStatus fromString(String raw) {
    final normalized = raw.trim();
    for (final status in ProviderApprovalStatus.values) {
      if (status.value == normalized) return status;
    }
    throw ArgumentError.value(
      raw,
      'approvalStatus',
      'Unknown ProviderApprovalStatus',
    );
  }

  static ProviderApprovalStatus? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final status in ProviderApprovalStatus.values) {
      if (status.value == raw.trim()) return status;
    }
    return null;
  }
}

/// UI presentation helpers only — NEVER serialize these localized labels into DB fields.
extension WorkRequestStatusPresentation on WorkRequestStatus {
  String label({required bool isArabic}) {
    switch (this) {
      case WorkRequestStatus.open:
        return isArabic ? 'مفتوح للعروض' : 'Open';
      case WorkRequestStatus.offerReceived:
        return isArabic ? 'تم استلام عروض' : 'Offer Received';
      case WorkRequestStatus.offerSelected:
        return isArabic ? 'تم اختيار عرض' : 'Offer Selected';
      case WorkRequestStatus.accepted:
        return isArabic ? 'مقبول من المنفّذ' : 'Accepted';
      case WorkRequestStatus.inProgress:
        return isArabic ? 'قيد التنفيذ والشراء' : 'In Progress';
      case WorkRequestStatus.pickedUp:
        return isArabic ? 'تم الاستلام من المتجر' : 'Picked Up';
      case WorkRequestStatus.inTransit:
        return isArabic ? 'في الطريق للموقع' : 'In Transit';
      case WorkRequestStatus.deliveredPendingConfirmation:
        return isArabic ? 'بانتظار تأكيد التسليم' : 'Delivered (Pending Confirmation)';
      case WorkRequestStatus.completed:
        return isArabic ? 'مكتمل' : 'Completed';
      case WorkRequestStatus.cancelled:
        return isArabic ? 'ملغى' : 'Cancelled';
      case WorkRequestStatus.disputed:
        return isArabic ? 'قيد النزاع' : 'Disputed';
    }
  }
}

extension PaymentMethodPresentation on PaymentMethod {
  String label({required bool isArabic}) {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return isArabic ? 'الدفع نقداً عند الاستلام' : 'Cash on Delivery';
      case PaymentMethod.bankTransferManual:
        return isArabic ? 'تحويل بنكي يدوي (بإيصال)' : 'Manual Bank Transfer';
    }
  }
}

extension PaymentSettlementStatusPresentation on PaymentSettlementStatus {
  String label({required bool isArabic}) {
    switch (this) {
      case PaymentSettlementStatus.unpaid:
        return isArabic ? 'غير مسدد' : 'Unpaid';
      case PaymentSettlementStatus.transferProofSubmitted:
        return isArabic ? 'تم رفع إيصال التحويل' : 'Transfer Proof Submitted';
      case PaymentSettlementStatus.verifiedSettled:
        return isArabic ? 'تم التحقق والتسوية' : 'Verified & Settled';
      case PaymentSettlementStatus.disputed:
        return isArabic ? 'متنازع عليه' : 'Disputed';
    }
  }
}

extension ProviderApprovalStatusPresentation on ProviderApprovalStatus {
  String label({required bool isArabic}) {
    switch (this) {
      case ProviderApprovalStatus.pending:
        return isArabic ? 'قيد المراجعة' : 'Pending Review';
      case ProviderApprovalStatus.approved:
        return isArabic ? 'معتمد' : 'Approved';
      case ProviderApprovalStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case ProviderApprovalStatus.suspended:
        return isArabic ? 'موقوف' : 'Suspended';
    }
  }
}

DateTime _parseUtcDateTime(dynamic raw, {DateTime? fallback}) {
  if (raw is DateTime) return raw.toUtc();
  if (raw is String && raw.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return parsed.toUtc();
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  return (fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
      .toUtc();
}

DateTime? _parseNullableUtcDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toUtc();
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim())?.toUtc();
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  return null;
}

@immutable
class WorkRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? businessProfileId;
  final String? savedWorksiteId;
  final String title;
  final String description;
  final String supplyCategory;
  final String pickupLocation;
  final String dropoffWorksite;
  final String municipality;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? itemNotes;
  final MoneyMinor estimatedItemsCostMinor;
  final MoneyMinor maxItemsCapMinor;
  final MoneyMinor deliveryFeeBudgetMinor;
  final MoneyMinor? agreedFeeMinor;
  final WorkRequestStatus status;
  final PaymentMethod paymentMethod;
  final PaymentSettlementStatus paymentSettlementStatus;
  final String? paymentProofUrl;
  final String? paymentReference;
  final String? selectedOfferId;
  final String? assignedProviderId;
  final String? assignedProviderName;
  final bool requiresPurchaseReceipt;
  final String? receiptImageUrl;
  final List<String> referenceImageUrls;
  final MoneyMinor? actualReceiptTotalMinor;
  final int offerCount;
  final bool isHandoverVerified;
  final String? cancellationReason;
  final String? disputeReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledBy;

  const WorkRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.businessProfileId,
    this.savedWorksiteId,
    required this.title,
    required this.description,
    this.supplyCategory = 'general_site_supply',
    required this.pickupLocation,
    required this.dropoffWorksite,
    required this.municipality,
    this.siteContactName,
    this.siteContactPhone,
    this.itemNotes,
    required this.estimatedItemsCostMinor,
    required this.maxItemsCapMinor,
    required this.deliveryFeeBudgetMinor,
    this.agreedFeeMinor,
    this.status = WorkRequestStatus.open,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.paymentSettlementStatus = PaymentSettlementStatus.unpaid,
    this.paymentProofUrl,
    this.paymentReference,
    this.selectedOfferId,
    this.assignedProviderId,
    this.assignedProviderName,
    this.requiresPurchaseReceipt = true,
    this.receiptImageUrl,
    this.referenceImageUrls = const [],
    this.actualReceiptTotalMinor,
    this.offerCount = 0,
    this.isHandoverVerified = false,
    this.cancellationReason,
    this.disputeReason,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledBy,
  });

  MoneyMinor get effectiveTotalMinor => MoneyMinor(
        (actualReceiptTotalMinor ?? estimatedItemsCostMinor).minorUnits +
            (agreedFeeMinor ?? deliveryFeeBudgetMinor).minorUnits,
      );

  WorkRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? businessProfileId,
    String? savedWorksiteId,
    String? title,
    String? description,
    String? supplyCategory,
    String? pickupLocation,
    String? dropoffWorksite,
    String? municipality,
    String? siteContactName,
    String? siteContactPhone,
    String? itemNotes,
    MoneyMinor? estimatedItemsCostMinor,
    MoneyMinor? maxItemsCapMinor,
    MoneyMinor? deliveryFeeBudgetMinor,
    MoneyMinor? agreedFeeMinor,
    WorkRequestStatus? status,
    PaymentMethod? paymentMethod,
    PaymentSettlementStatus? paymentSettlementStatus,
    String? paymentProofUrl,
    String? paymentReference,
    String? selectedOfferId,
    String? assignedProviderId,
    String? assignedProviderName,
    bool? requiresPurchaseReceipt,
    String? receiptImageUrl,
    List<String>? referenceImageUrls,
    MoneyMinor? actualReceiptTotalMinor,
    int? offerCount,
    bool? isHandoverVerified,
    String? cancellationReason,
    String? disputeReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledBy,
  }) {
    return WorkRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      businessProfileId: businessProfileId ?? this.businessProfileId,
      savedWorksiteId: savedWorksiteId ?? this.savedWorksiteId,
      title: title ?? this.title,
      description: description ?? this.description,
      supplyCategory: supplyCategory ?? this.supplyCategory,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffWorksite: dropoffWorksite ?? this.dropoffWorksite,
      municipality: municipality ?? this.municipality,
      siteContactName: siteContactName ?? this.siteContactName,
      siteContactPhone: siteContactPhone ?? this.siteContactPhone,
      itemNotes: itemNotes ?? this.itemNotes,
      estimatedItemsCostMinor:
          estimatedItemsCostMinor ?? this.estimatedItemsCostMinor,
      maxItemsCapMinor: maxItemsCapMinor ?? this.maxItemsCapMinor,
      deliveryFeeBudgetMinor:
          deliveryFeeBudgetMinor ?? this.deliveryFeeBudgetMinor,
      agreedFeeMinor: agreedFeeMinor ?? this.agreedFeeMinor,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentSettlementStatus:
          paymentSettlementStatus ?? this.paymentSettlementStatus,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      selectedOfferId: selectedOfferId ?? this.selectedOfferId,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      assignedProviderName: assignedProviderName ?? this.assignedProviderName,
      requiresPurchaseReceipt:
          requiresPurchaseReceipt ?? this.requiresPurchaseReceipt,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      referenceImageUrls: referenceImageUrls ?? this.referenceImageUrls,
      actualReceiptTotalMinor:
          actualReceiptTotalMinor ?? this.actualReceiptTotalMinor,
      offerCount: offerCount ?? this.offerCount,
      isHandoverVerified: isHandoverVerified ?? this.isHandoverVerified,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: (createdAt ?? this.createdAt).toUtc(),
      updatedAt: (updatedAt ?? this.updatedAt).toUtc(),
      scheduledBy: (scheduledBy ?? this.scheduledBy)?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'businessProfileId': businessProfileId,
      'savedWorksiteId': savedWorksiteId,
      'title': title,
      'description': description,
      'supplyCategory': supplyCategory,
      'pickupLocation': pickupLocation,
      'dropoffWorksite': dropoffWorksite,
      'municipality': municipality,
      'siteContactName': siteContactName,
      'siteContactPhone': siteContactPhone,
      'itemNotes': itemNotes,
      'estimatedItemsCostMinor': estimatedItemsCostMinor.toJson(),
      'maxItemsCapMinor': maxItemsCapMinor.toJson(),
      'deliveryFeeBudgetMinor': deliveryFeeBudgetMinor.toJson(),
      'agreedFeeMinor': agreedFeeMinor?.toJson(),
      'status': status.value,
      'paymentMethod': paymentMethod.value,
      'paymentSettlementStatus': paymentSettlementStatus.value,
      'paymentProofUrl': paymentProofUrl,
      'paymentReference': paymentReference,
      'selectedOfferId': selectedOfferId,
      'assignedProviderId': assignedProviderId,
      'assignedProviderName': assignedProviderName,
      'requiresPurchaseReceipt': requiresPurchaseReceipt,
      'receiptImageUrl': receiptImageUrl,
      if (referenceImageUrls.isNotEmpty)
        'referenceImageUrls': referenceImageUrls,
      'actualReceiptTotalMinor': actualReceiptTotalMinor?.toJson(),
      'offerCount': offerCount,
      'isHandoverVerified': isHandoverVerified,
      'cancellationReason': cancellationReason,
      'disputeReason': disputeReason,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'scheduledBy': scheduledBy?.toUtc().toIso8601String(),
    };
  }

  factory WorkRequest.fromJson(Map<String, dynamic> json) {
    final estimatedMinor = MoneyMinor.fromJson(
      json['estimatedItemsCostMinor'] ?? json['budgetMinor'] ?? 0,
    );
    final maxCapMinor = MoneyMinor.fromJson(
      json['maxItemsCapMinor'] ?? json['budgetMinor'] ?? estimatedMinor.minorUnits,
    );
    final feeBudgetMinor = MoneyMinor.fromJson(
      json['deliveryFeeBudgetMinor'] ?? json['agreedFeeMinor'] ?? 0,
    );
    final receiptList = json['invoiceImageUrls'];
    final firstReceipt = receiptList is Iterable && receiptList.isNotEmpty
        ? receiptList.first.toString()
        : null;

    return WorkRequest(
      id: (json['id'] ?? '').toString(),
      requesterId: (json['requesterId'] ?? '').toString(),
      requesterName: (json['requesterName'] ?? '').toString(),
      businessProfileId: json['businessProfileId'] as String?,
      savedWorksiteId: json['savedWorksiteId'] as String?,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      supplyCategory: (json['supplyCategory'] ??
              json['category'] ??
              'general_site_supply')
          .toString(),
      pickupLocation: (json['pickupLocation'] ?? '').toString(),
      dropoffWorksite:
          (json['dropoffWorksite'] ?? json['deliveryLocation'] ?? '').toString(),
      municipality:
          (json['municipality'] ?? json['deliveryArea'] ?? '').toString(),
      siteContactName: json['siteContactName'] as String?,
      siteContactPhone: json['siteContactPhone'] as String?,
      itemNotes: json['itemNotes'] as String?,
      estimatedItemsCostMinor: estimatedMinor,
      maxItemsCapMinor: maxCapMinor,
      deliveryFeeBudgetMinor: feeBudgetMinor,
      agreedFeeMinor: MoneyMinor.tryParseNullable(json['agreedFeeMinor']),
      status: WorkRequestStatus.tryParse(json['status']?.toString()) ??
          WorkRequestStatus.open,
      paymentMethod:
          PaymentMethod.tryParse(json['paymentMethod']?.toString()) ??
              PaymentMethod.cashOnDelivery,
      paymentSettlementStatus: PaymentSettlementStatus.tryParse(
            (json['paymentSettlementStatus'] ?? json['paymentStatus'])
                ?.toString(),
          ) ??
          PaymentSettlementStatus.unpaid,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      paymentReference: json['paymentReference'] as String?,
      selectedOfferId: json['selectedOfferId'] as String?,
      assignedProviderId: json['assignedProviderId'] as String?,
      assignedProviderName: json['assignedProviderName'] as String?,
      requiresPurchaseReceipt:
          json['requiresPurchaseReceipt'] as bool? ?? true,
      receiptImageUrl: (json['receiptImageUrl'] as String?) ?? firstReceipt,
      referenceImageUrls: json['referenceImageUrls'] is Iterable
          ? (json['referenceImageUrls'] as Iterable)
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList(growable: false)
          : const [],
      actualReceiptTotalMinor: MoneyMinor.tryParseNullable(
        json['actualReceiptTotalMinor'] ?? json['agreedAmountMinor'],
      ),
      offerCount: (json['offerCount'] as num?)?.toInt() ?? 0,
      isHandoverVerified: json['isHandoverVerified'] as bool? ?? false,
      cancellationReason: json['cancellationReason'] as String?,
      disputeReason: json['disputeReason'] as String?,
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
      scheduledBy: _parseNullableUtcDateTime(json['scheduledBy']),
    );
  }
}

@immutable
class WorkOffer {
  final String id;
  final String requestId;
  final String providerId;
  final String providerName;
  final double providerRating;
  final int providerCompletedJobs;
  final MoneyMinor proposedFeeMinor;
  final MoneyMinor? estimatedItemsCostMinor;
  final int estimatedEtaMinutes;
  final String? notes;
  final bool isSelected;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkOffer({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    this.providerRating = 0.0,
    this.providerCompletedJobs = 0,
    required this.proposedFeeMinor,
    this.estimatedItemsCostMinor,
    this.estimatedEtaMinutes = 45,
    this.notes,
    this.isSelected = false,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  WorkOffer copyWith({
    String? id,
    String? requestId,
    String? providerId,
    String? providerName,
    double? providerRating,
    int? providerCompletedJobs,
    MoneyMinor? proposedFeeMinor,
    MoneyMinor? estimatedItemsCostMinor,
    int? estimatedEtaMinutes,
    String? notes,
    bool? isSelected,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkOffer(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerRating: providerRating ?? this.providerRating,
      providerCompletedJobs:
          providerCompletedJobs ?? this.providerCompletedJobs,
      proposedFeeMinor: proposedFeeMinor ?? this.proposedFeeMinor,
      estimatedItemsCostMinor:
          estimatedItemsCostMinor ?? this.estimatedItemsCostMinor,
      estimatedEtaMinutes: estimatedEtaMinutes ?? this.estimatedEtaMinutes,
      notes: notes ?? this.notes,
      isSelected: isSelected ?? this.isSelected,
      status: status ?? this.status,
      createdAt: (createdAt ?? this.createdAt).toUtc(),
      updatedAt: (updatedAt ?? this.updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'providerId': providerId,
      'providerName': providerName,
      'providerRating': providerRating,
      'providerCompletedJobs': providerCompletedJobs,
      'proposedFeeMinor': proposedFeeMinor.toJson(),
      'estimatedItemsCostMinor': estimatedItemsCostMinor?.toJson(),
      'estimatedEtaMinutes': estimatedEtaMinutes,
      'notes': notes,
      'isSelected': isSelected,
      'status': status,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory WorkOffer.fromJson(Map<String, dynamic> json) {
    return WorkOffer(
      id: (json['id'] ?? '').toString(),
      requestId: (json['requestId'] ?? '').toString(),
      providerId: (json['providerId'] ?? '').toString(),
      providerName: (json['providerName'] ?? '').toString(),
      providerRating: (json['providerRating'] as num?)?.toDouble() ?? 0.0,
      providerCompletedJobs:
          (json['providerCompletedJobs'] as num?)?.toInt() ?? 0,
      proposedFeeMinor: MoneyMinor.fromJson(
        json['proposedFeeMinor'] ?? json['serviceFeeMinor'],
      ),
      estimatedItemsCostMinor: MoneyMinor.tryParseNullable(
        json['estimatedItemsCostMinor'] ?? json['totalAmountMinor'],
      ),
      estimatedEtaMinutes: (json['estimatedEtaMinutes'] as num?)?.toInt() ??
          (json['etaMinutes'] as num?)?.toInt() ??
          45,
      notes: json['notes'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
    );
  }
}

@immutable
class RequestEvent {
  final String id;
  final String requestId;
  final String actorId;
  final String actorRole;
  final String eventType;
  final WorkRequestStatus? fromStatus;
  final WorkRequestStatus? toStatus;
  final String? note;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const RequestEvent({
    required this.id,
    required this.requestId,
    required this.actorId,
    required this.actorRole,
    required this.eventType,
    this.fromStatus,
    this.toStatus,
    this.note,
    this.metadata = const {},
    required this.createdAt,
  });

  RequestEvent copyWith({
    String? id,
    String? requestId,
    String? actorId,
    String? actorRole,
    String? eventType,
    WorkRequestStatus? fromStatus,
    WorkRequestStatus? toStatus,
    String? note,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return RequestEvent(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      actorId: actorId ?? this.actorId,
      actorRole: actorRole ?? this.actorRole,
      eventType: eventType ?? this.eventType,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      note: note ?? this.note,
      metadata: Map.unmodifiable(metadata ?? this.metadata),
      createdAt: (createdAt ?? this.createdAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'actorId': actorId,
      'actorRole': actorRole,
      'eventType': eventType,
      'fromStatus': fromStatus?.value,
      'toStatus': toStatus?.value,
      'note': note,
      'metadata': metadata,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory RequestEvent.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
    return RequestEvent(
      id: (json['id'] ?? '').toString(),
      requestId: (json['requestId'] ?? '').toString(),
      actorId: (json['actorId'] ?? '').toString(),
      actorRole: (json['actorRole'] ?? '').toString(),
      eventType: (json['eventType'] ?? json['type'] ?? '').toString(),
      fromStatus: WorkRequestStatus.tryParse(json['fromStatus']?.toString()),
      toStatus: WorkRequestStatus.tryParse(json['toStatus']?.toString()),
      note: json['note'] as String?,
      metadata: rawMeta is Map
          ? Map<String, dynamic>.unmodifiable(
              rawMeta.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const {},
      createdAt: _parseUtcDateTime(json['createdAt']),
    );
  }
}

@immutable
class ProviderProfile {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String? qidNumber;
  final String? qidFrontUrl;
  final String? qidBackUrl;
  final String? selfieUrl;
  final String? vehicleType;
  final String? vehiclePlate;
  final List<String> serviceMunicipalities;
  final List<String> supplySpecialties;
  final ProviderApprovalStatus approvalStatus;
  final String? rejectionReason;
  final double rating;
  final int completedJobsCount;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.qidNumber,
    this.qidFrontUrl,
    this.qidBackUrl,
    this.selfieUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.serviceMunicipalities = const [],
    this.supplySpecialties = const [],
    this.approvalStatus = ProviderApprovalStatus.pending,
    this.rejectionReason,
    this.rating = 0.0,
    this.completedJobsCount = 0,
    this.isAvailable = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canAcceptWorksiteJobs =>
      approvalStatus == ProviderApprovalStatus.approved;

  ProviderProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? qidNumber,
    String? qidFrontUrl,
    String? qidBackUrl,
    String? selfieUrl,
    String? vehicleType,
    String? vehiclePlate,
    List<String>? serviceMunicipalities,
    List<String>? supplySpecialties,
    ProviderApprovalStatus? approvalStatus,
    String? rejectionReason,
    double? rating,
    int? completedJobsCount,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      qidNumber: qidNumber ?? this.qidNumber,
      qidFrontUrl: qidFrontUrl ?? this.qidFrontUrl,
      qidBackUrl: qidBackUrl ?? this.qidBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      serviceMunicipalities: List.unmodifiable(
        serviceMunicipalities ?? this.serviceMunicipalities,
      ),
      supplySpecialties: List.unmodifiable(
        supplySpecialties ?? this.supplySpecialties,
      ),
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rating: rating ?? this.rating,
      completedJobsCount: completedJobsCount ?? this.completedJobsCount,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: (createdAt ?? this.createdAt).toUtc(),
      updatedAt: (updatedAt ?? this.updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'qidNumber': qidNumber,
      'qidFrontUrl': qidFrontUrl,
      'qidBackUrl': qidBackUrl,
      'selfieUrl': selfieUrl,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'serviceMunicipalities': serviceMunicipalities,
      'supplySpecialties': supplySpecialties,
      'approvalStatus': approvalStatus.value,
      'rejectionReason': rejectionReason,
      'rating': rating,
      'completedJobsCount': completedJobsCount,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final municipalities = json['serviceMunicipalities'] ?? json['serviceAreas'];
    final specialties = json['supplySpecialties'];
    return ProviderProfile(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['providerId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      qidNumber: json['qidNumber'] as String?,
      qidFrontUrl: json['qidFrontUrl'] as String?,
      qidBackUrl: json['qidBackUrl'] as String?,
      selfieUrl: json['selfieUrl'] as String?,
      vehicleType: json['vehicleType'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      serviceMunicipalities: municipalities is Iterable
          ? List<String>.unmodifiable(
              municipalities.map((e) => e.toString()),
            )
          : const [],
      supplySpecialties: specialties is Iterable
          ? List<String>.unmodifiable(
              specialties.map((e) => e.toString()),
            )
          : const [],
      approvalStatus: ProviderApprovalStatus.tryParse(
            json['approvalStatus']?.toString(),
          ) ??
          ProviderApprovalStatus.pending,
      rejectionReason: json['rejectionReason'] as String?,
      rating: ((json['rating'] ?? json['ratingAvg']) as num?)?.toDouble() ?? 0.0,
      completedJobsCount: ((json['completedJobsCount'] ??
                  json['completedTasksCount']) as num?)
              ?.toInt() ??
          0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
    );
  }
}

@immutable
class BusinessProfile {
  final String id;
  final String ownerUserId;
  final String companyName;
  final String? commercialRegistrationNumber;
  final String? contactPersonName;
  final String contactPhone;
  final String? billingEmail;
  final String? municipality;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProfile({
    required this.id,
    required this.ownerUserId,
    required this.companyName,
    this.commercialRegistrationNumber,
    this.contactPersonName,
    required this.contactPhone,
    this.billingEmail,
    this.municipality,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessProfile copyWith({
    String? id,
    String? ownerUserId,
    String? companyName,
    String? commercialRegistrationNumber,
    String? contactPersonName,
    String? contactPhone,
    String? billingEmail,
    String? municipality,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      companyName: companyName ?? this.companyName,
      commercialRegistrationNumber:
          commercialRegistrationNumber ?? this.commercialRegistrationNumber,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPhone: contactPhone ?? this.contactPhone,
      billingEmail: billingEmail ?? this.billingEmail,
      municipality: municipality ?? this.municipality,
      isVerified: isVerified ?? this.isVerified,
      createdAt: (createdAt ?? this.createdAt).toUtc(),
      updatedAt: (updatedAt ?? this.updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'companyName': companyName,
      'commercialRegistrationNumber': commercialRegistrationNumber,
      'contactPersonName': contactPersonName,
      'contactPhone': contactPhone,
      'billingEmail': billingEmail,
      'municipality': municipality,
      'isVerified': isVerified,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: (json['id'] ?? '').toString(),
      ownerUserId: (json['ownerUserId'] ?? json['userId'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      commercialRegistrationNumber:
          json['commercialRegistrationNumber'] as String?,
      contactPersonName:
          (json['contactPersonName'] ?? json['contactName']) as String?,
      contactPhone: (json['contactPhone'] ?? json['phone'] ?? '').toString(),
      billingEmail: json['billingEmail'] as String?,
      municipality:
          (json['municipality'] ?? json['defaultWorksiteArea']) as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
    );
  }
}

@immutable
class SavedWorksite {
  final String id;
  final String ownerUserId;
  final String? businessProfileId;
  final String label;
  final String municipality;
  final String zoneOrStreet;
  final String? landmark;
  final String? gateInstructions;
  final String siteContactName;
  final String siteContactPhone;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedWorksite({
    required this.id,
    required this.ownerUserId,
    this.businessProfileId,
    required this.label,
    required this.municipality,
    required this.zoneOrStreet,
    this.landmark,
    this.gateInstructions,
    required this.siteContactName,
    required this.siteContactPhone,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedWorksite copyWith({
    String? id,
    String? ownerUserId,
    String? businessProfileId,
    String? label,
    String? municipality,
    String? zoneOrStreet,
    String? landmark,
    String? gateInstructions,
    String? siteContactName,
    String? siteContactPhone,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedWorksite(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      businessProfileId: businessProfileId ?? this.businessProfileId,
      label: label ?? this.label,
      municipality: municipality ?? this.municipality,
      zoneOrStreet: zoneOrStreet ?? this.zoneOrStreet,
      landmark: landmark ?? this.landmark,
      gateInstructions: gateInstructions ?? this.gateInstructions,
      siteContactName: siteContactName ?? this.siteContactName,
      siteContactPhone: siteContactPhone ?? this.siteContactPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: (createdAt ?? this.createdAt).toUtc(),
      updatedAt: (updatedAt ?? this.updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'businessProfileId': businessProfileId,
      'label': label,
      'municipality': municipality,
      'zoneOrStreet': zoneOrStreet,
      'landmark': landmark,
      'gateInstructions': gateInstructions,
      'siteContactName': siteContactName,
      'siteContactPhone': siteContactPhone,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory SavedWorksite.fromJson(Map<String, dynamic> json) {
    return SavedWorksite(
      id: (json['id'] ?? '').toString(),
      ownerUserId: (json['ownerUserId'] ?? '').toString(),
      businessProfileId: json['businessProfileId'] as String?,
      label: (json['label'] ?? '').toString(),
      municipality: (json['municipality'] ?? '').toString(),
      zoneOrStreet: (json['zoneOrStreet'] ?? '').toString(),
      landmark: json['landmark'] as String?,
      gateInstructions: json['gateInstructions'] as String?,
      siteContactName: (json['siteContactName'] ?? '').toString(),
      siteContactPhone: (json['siteContactPhone'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: _parseUtcDateTime(json['createdAt']),
      updatedAt: _parseUtcDateTime(json['updatedAt']),
    );
  }
}

@immutable
class RequestRating {
  final String id;
  final String requestId;
  final String raterUserId;
  final String raterRole;
  final String targetUserId;
  final int score;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  const RequestRating({
    required this.id,
    required this.requestId,
    required this.raterUserId,
    required this.raterRole,
    required this.targetUserId,
    required this.score,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  }) : assert(score >= 1 && score <= 5, 'Rating score must be between 1 and 5');

  RequestRating copyWith({
    String? id,
    String? requestId,
    String? raterUserId,
    String? raterRole,
    String? targetUserId,
    int? score,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return RequestRating(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      raterUserId: raterUserId ?? this.raterUserId,
      raterRole: raterRole ?? this.raterRole,
      targetUserId: targetUserId ?? this.targetUserId,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      tags: List.unmodifiable(tags ?? this.tags),
      createdAt: (createdAt ?? this.createdAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'raterUserId': raterUserId,
      'raterRole': raterRole,
      'targetUserId': targetUserId,
      'score': score,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory RequestRating.fromJson(Map<String, dynamic> json) {
    final rawScore = ((json['score'] ?? json['stars']) as num?)?.toInt() ?? 5;
    final clampedScore = rawScore.clamp(1, 5);
    final rawTags = json['tags'];
    return RequestRating(
      id: (json['id'] ?? '').toString(),
      requestId: (json['requestId'] ?? '').toString(),
      raterUserId:
          (json['raterUserId'] ?? json['fromUserId'] ?? '').toString(),
      raterRole: (json['raterRole'] ?? json['fromRole'] ?? '').toString(),
      targetUserId:
          (json['targetUserId'] ?? json['toUserId'] ?? '').toString(),
      score: clampedScore,
      comment: json['comment'] as String?,
      tags: rawTags is Iterable
          ? List<String>.unmodifiable(rawTags.map((e) => e.toString()))
          : const [],
      createdAt: _parseUtcDateTime(json['createdAt']),
    );
  }
}

@immutable
class HandoverVerificationResult {
  final bool verified;
  final String requestId;
  final WorkRequestStatus resultingStatus;
  final String message;
  final DateTime? verifiedAt;
  final String? verifiedByProviderId;
  final String? eventId;

  const HandoverVerificationResult({
    required this.verified,
    required this.requestId,
    required this.resultingStatus,
    required this.message,
    this.verifiedAt,
    this.verifiedByProviderId,
    this.eventId,
  });

  HandoverVerificationResult copyWith({
    bool? verified,
    String? requestId,
    WorkRequestStatus? resultingStatus,
    String? message,
    DateTime? verifiedAt,
    String? verifiedByProviderId,
    String? eventId,
  }) {
    return HandoverVerificationResult(
      verified: verified ?? this.verified,
      requestId: requestId ?? this.requestId,
      resultingStatus: resultingStatus ?? this.resultingStatus,
      message: message ?? this.message,
      verifiedAt: (verifiedAt ?? this.verifiedAt)?.toUtc(),
      verifiedByProviderId: verifiedByProviderId ?? this.verifiedByProviderId,
      eventId: eventId ?? this.eventId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verified': verified,
      'requestId': requestId,
      'resultingStatus': resultingStatus.value,
      'message': message,
      'verifiedAt': verifiedAt?.toUtc().toIso8601String(),
      'verifiedByProviderId': verifiedByProviderId,
      'eventId': eventId,
    };
  }

  factory HandoverVerificationResult.fromJson(Map<String, dynamic> json) {
    return HandoverVerificationResult(
      verified: json['verified'] as bool? ?? false,
      requestId: (json['requestId'] ?? '').toString(),
      resultingStatus: WorkRequestStatus.tryParse(
            json['resultingStatus']?.toString(),
          ) ??
          WorkRequestStatus.deliveredPendingConfirmation,
      message: (json['message'] ?? '').toString(),
      verifiedAt: _parseNullableUtcDateTime(json['verifiedAt']),
      verifiedByProviderId: json['verifiedByProviderId'] as String?,
      eventId: json['eventId'] as String?,
    );
  }
}
