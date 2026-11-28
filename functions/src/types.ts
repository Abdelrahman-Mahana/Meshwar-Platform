export type DomainErrorCode =
  | 'unauthenticated'
  | 'permission-denied'
  | 'invalid-argument'
  | 'not-found'
  | 'failed-precondition'
  | 'already-exists';

export class DomainError extends Error {
  public readonly code: DomainErrorCode;
  public readonly details?: Record<string, unknown>;

  constructor(
    code: DomainErrorCode,
    message: string,
    details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'DomainError';
    this.code = code;
    this.details = details;
  }
}

export const WORK_REQUEST_STATUSES = [
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
] as const;

export type WorkRequestStatus = (typeof WORK_REQUEST_STATUSES)[number];

export const WORK_OFFER_STATUSES = [
  'pending',
  'accepted',
  'rejected',
  'withdrawn',
] as const;

export type WorkOfferStatus = (typeof WORK_OFFER_STATUSES)[number];

export const PROVIDER_APPROVAL_STATUSES = [
  'pending',
  'approved',
  'rejected',
  'suspended',
] as const;

export type ProviderApprovalStatus = (typeof PROVIDER_APPROVAL_STATUSES)[number];

export const PAYMENT_METHODS = [
  'cash_on_delivery',
  'bank_transfer_manual',
] as const;

export type PaymentMethod = (typeof PAYMENT_METHODS)[number];

export const PAYMENT_SETTLEMENT_STATUSES = [
  'unpaid',
  'transfer_proof_submitted',
  'verified_settled',
  'disputed',
] as const;

export type PaymentSettlementStatus = (typeof PAYMENT_SETTLEMENT_STATUSES)[number];

export const ALLOWED_ADMIN_ROLES = [
  'superAdmin',
  'reviewAdmin',
  'supportAdmin',
  'compliance',
  'operations',
  'financeAdmin',
  'devopsAdmin',
] as const;

export type AdminRole = (typeof ALLOWED_ADMIN_ROLES)[number];

export type ActorRole = 'requester' | 'provider' | 'admin' | 'system';

export interface AuthContext {
  uid: string | null;
  tokenClaims?: Record<string, unknown>;
}

export interface WorkRequestDoc extends Record<string, unknown> {
  id: string;
  requesterId: string;
  requesterName?: string | null;
  category: 'worksite_supply';
  supplyCategory?: string | null;
  title: string;
  description: string;
  pickupLocation: string;
  deliveryLocation: string;
  deliveryArea: string;
  siteContactName?: string | null;
  siteContactPhone?: string | null;
  itemNotes?: string | null;
  budgetMinor: number;
  estimatedItemsCostMinor?: number | null;
  maxItemsCapMinor?: number | null;
  deliveryFeeBudgetMinor?: number | null;
  scheduledBy?: string | null;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentSettlementStatus;
  paymentProofUrl?: string | null;
  paymentReference?: string | null;
  paymentVerifiedBy?: string | null;
  paymentVerifiedAtUtc?: string | null;
  status: WorkRequestStatus;
  offerCount: number;
  selectedOfferId: string | null;
  assignedProviderId: string | null;
  agreedAmountMinor: number | null;
  agreedFeeMinor: number | null;
  actualReceiptTotalMinor?: number | null;
  referenceImageUrls: string[];
  invoiceImageUrls: string[];
  cancellationReason?: string | null;
  disputeReason?: string | null;
  moderationNotes?: string | null;
  completedAtUtc?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface WorkOfferDoc extends Record<string, unknown> {
  id: string;
  requestId: string;
  providerId: string;
  providerName: string;
  totalAmountMinor: number;
  serviceFeeMinor: number;
  etaMinutes: number;
  notes: string | null;
  status: WorkOfferStatus;
  createdAt: string;
  updatedAt: string;
}

export interface WorkRequestSecretDoc extends Record<string, unknown> {
  requestId: string;
  codeHash: string;
  codeSalt: string;
  expiresAtUtc: string;
  attemptsRemaining: number;
  maxAttempts: number;
  usedAtUtc: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface WorkRequestHandoverViewDoc extends Record<string, unknown> {
  requestId: string;
  requesterId: string;
  handoverCode: string;
  expiresAtUtc: string;
  createdAt: string;
  updatedAt: string;
}

export interface RequestEventDoc extends Record<string, unknown> {
  id: string;
  requestId: string;
  actorId: string;
  actorRole: ActorRole;
  type: string;
  fromStatus: WorkRequestStatus | null;
  toStatus: WorkRequestStatus;
  note: string | null;
  metadata?: Record<string, unknown> | null;
  createdAt: string;
}

export interface ProviderProfileDoc extends Record<string, unknown> {
  id: string;
  userId: string;
  fullName: string;
  phone?: string;
  vehicleType?: string;
  vehiclePlate?: string;
  serviceAreas?: string[];
  approvalStatus: ProviderApprovalStatus;
  completedTasksCount: number;
  ratingAvg: number;
  ratingCount: number;
  reviewedBy?: string | null;
  reviewedAtUtc?: string | null;
  rejectionReason?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

export interface ProviderVerificationDoc extends Record<string, unknown> {
  id: string;
  providerId: string;
  fullName: string;
  qidNumber?: string;
  status: string;
  reviewedBy?: string | null;
  reviewedAtUtc?: string | null;
  rejectionReason?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

export interface BusinessProfileDoc extends Record<string, unknown> {
  id: string;
  userId: string;
  companyName?: string;
  contactName?: string;
  ratingAvg: number;
  ratingCount: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface RatingDoc extends Record<string, unknown> {
  id: string;
  requestId: string;
  fromUserId: string;
  toUserId: string;
  fromRole: 'requester' | 'provider';
  stars: number;
  comment: string | null;
  tags: string[];
  createdAt: string;
}

export interface AdminStaffDoc extends Record<string, unknown> {
  id: string;
  uid?: string;
  name: string;
  email: string;
  role: AdminRole;
  isActive: boolean;
}

export interface AdminAuditLogDoc extends Record<string, unknown> {
  id: string;
  adminUid: string;
  adminRole: AdminRole;
  action: string;
  targetCollection: string;
  targetEntityId: string;
  previousState: Record<string, unknown> | null;
  newState: Record<string, unknown>;
  reason: string | null;
  createdAt: string;
}

export interface NotificationDoc extends Record<string, unknown> {
  id: string;
  userId: string;
  requestId: string;
  type: string;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
}

export interface CreateWorkRequestInput {
  title?: unknown;
  description?: unknown;
  supplyCategory?: unknown;
  pickupLocation?: unknown;
  deliveryLocation?: unknown;
  deliveryArea?: unknown;
  siteContactName?: unknown;
  siteContactPhone?: unknown;
  itemNotes?: unknown;
  budgetMinor?: unknown;
  estimatedItemsCostMinor?: unknown;
  maxItemsCapMinor?: unknown;
  deliveryFeeBudgetMinor?: unknown;
  scheduledBy?: unknown;
  paymentMethod?: unknown;
  paymentStatus?: unknown;
  referenceImageUrls?: unknown;
  requesterName?: unknown;
}

export interface SubmitWorkOfferInput {
  requestId?: unknown;
  totalAmountMinor?: unknown;
  serviceFeeMinor?: unknown;
  etaMinutes?: unknown;
  notes?: unknown;
}

export interface WithdrawWorkOfferInput {
  requestId?: unknown;
  offerId?: unknown;
}

export interface AcceptWorkOfferInput {
  requestId?: unknown;
  offerId?: unknown;
}

export interface TransitionWorkRequestStatusInput {
  requestId?: unknown;
  targetStatus?: unknown;
  invoiceImageUrls?: unknown;
  actualReceiptTotalMinor?: unknown;
  reason?: unknown;
  paymentStatus?: unknown;
}

export interface VerifyHandoverAndCompleteInput {
  requestId?: unknown;
  code?: unknown;
}

export interface SubmitRequestRatingInput {
  requestId?: unknown;
  stars?: unknown;
  comment?: unknown;
  tags?: unknown;
}

export interface RecordPaymentStatusInput {
  requestId?: unknown;
  targetPaymentStatus?: unknown;
  paymentProofUrl?: unknown;
  referenceNumber?: unknown;
  paymentReference?: unknown;
}

export interface AdminReviewProviderInput {
  providerId?: unknown;
  decision?: unknown;
  reason?: unknown;
}

export interface AdminModerateWorkRequestInput {
  requestId?: unknown;
  action?: unknown;
  targetStatus?: unknown;
  reason?: unknown;
}
