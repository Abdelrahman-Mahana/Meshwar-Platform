import '../../models/worksite_models.dart';

/// Repository contract for the Qatar Worksite Supply MVP lifecycle:
/// request creation, provider offers, selection, fulfillment progression,
/// handover verification, settlement tracking, ratings, disputes, and audit events.
abstract class IWorksiteRepository {
  Future<WorkRequest> createRequest(WorkRequest request);

  Future<List<WorkRequest>> listRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  });

  Future<WorkRequest?> getRequestById(String requestId);

  Future<List<WorkOffer>> listOffersForRequest(String requestId);

  Future<WorkOffer> submitOffer(WorkOffer offer);

  Future<void> withdrawOffer({
    required String requestId,
    required String offerId,
    required String providerId,
  });

  Future<WorkRequest> acceptOffer({
    required String requestId,
    required String offerId,
    required String requesterId,
  });

  Future<WorkRequest> cancelRequest({
    required String requestId,
    required String requesterId,
    String? reason,
  });

  Future<WorkRequest> updateFulfillmentStatus({
    required String requestId,
    required WorkRequestStatus nextStatus,
    required String actorId,
    required String actorRole,
    String? note,
    String? receiptImageUrl,
    MoneyMinor? actualReceiptTotalMinor,
  });

  Future<String> getRequesterHandoverCode({
    required String requestId,
    required String requesterId,
  });

  Future<HandoverVerificationResult> verifyHandoverCode({
    required String requestId,
    required String providerId,
    required String code,
  });

  Future<RequestRating> submitRating(RequestRating rating);

  Future<WorkRequest> reportDispute({
    required String requestId,
    required String reporterId,
    required String reporterRole,
    required String reason,
  });

  Future<List<RequestEvent>> listRequestEvents(String requestId);

  Future<WorkRequest> recordPaymentStatus({
    required String requestId,
    required PaymentMethod method,
    required PaymentSettlementStatus settlementStatus,
    required String actorId,
    required String actorRole,
    String? proofUrl,
    String? referenceNumber,
  });
}
