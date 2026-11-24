import crypto from 'node:crypto';
import {
  HANDOVER_MAX_ATTEMPTS,
  HANDOVER_TTL_MS,
  generateHandoverCode,
  generateHandoverSalt,
  hashHandoverCode,
  verifyHandoverCodeHash,
} from './handoverCrypto';
import {
  INVOICE_ATTACHMENT_STATUSES,
  assertPaymentStatusTransition,
  assertWorkRequestTransition,
  isPaymentSettlementStatus,
  isWorkRequestStatus,
} from './stateMachine';
import { DataStore, StoreTransaction } from './store';
import {
  ALLOWED_ADMIN_ROLES,
  AcceptWorkOfferInput,
  AdminAuditLogDoc,
  AdminModerateWorkRequestInput,
  AdminReviewProviderInput,
  AdminRole,
  AdminStaffDoc,
  AuthContext,
  BusinessProfileDoc,
  CreateWorkRequestInput,
  DomainError,
  NotificationDoc,
  PAYMENT_METHODS,
  PROVIDER_APPROVAL_STATUSES,
  PaymentMethod,
  ProviderApprovalStatus,
  ProviderProfileDoc,
  ProviderVerificationDoc,
  RatingDoc,
  RecordPaymentStatusInput,
  RequestEventDoc,
  SubmitRequestRatingInput,
  SubmitWorkOfferInput,
  TransitionWorkRequestStatusInput,
  VerifyHandoverAndCompleteInput,
  WorkOfferDoc,
  WorkRequestDoc,
  WorkRequestHandoverViewDoc,
  WorkRequestSecretDoc,
  WorkRequestStatus,
} from './types';

export interface HandlerDeps {
  now?: () => Date;
  idGenerator?: () => string;
  randomBytes?: (size: number) => Buffer;
}

const MAX_BUDGET_MINOR = 100_000_000;
const MAX_ETA_MINUTES = 10_080; // 7 days
const MAX_IMAGES = 10;

const MODERATION_ADMIN_ROLES: ReadonlySet<AdminRole> = new Set<AdminRole>([
  'superAdmin',
  'reviewAdmin',
  'supportAdmin',
  'compliance',
  'operations',
]);

const PROVIDER_REVIEW_ADMIN_ROLES: ReadonlySet<AdminRole> = new Set<AdminRole>([
  'superAdmin',
  'reviewAdmin',
  'compliance',
  'operations',
]);

function requireAuthUid(context: AuthContext): string {
  if (!context.uid || typeof context.uid !== 'string' || context.uid.trim().length === 0) {
    throw new DomainError('unauthenticated', 'Authentication is required.');
  }
  return context.uid.trim();
}

function requireNonEmptyString(
  value: unknown,
  fieldName: string,
  minLen = 1,
  maxLen = 300,
): string {
  if (typeof value !== 'string') {
    throw new DomainError('invalid-argument', `'${fieldName}' must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length < minLen || trimmed.length > maxLen) {
    throw new DomainError(
      'invalid-argument',
      `'${fieldName}' must be between ${minLen} and ${maxLen} characters.`,
    );
  }
  return trimmed;
}

function optionalString(value: unknown, fieldName: string, maxLen = 1000): string | null {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  if (typeof value !== 'string') {
    throw new DomainError('invalid-argument', `'${fieldName}' must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLen) {
    throw new DomainError(
      'invalid-argument',
      `'${fieldName}' cannot exceed ${maxLen} characters.`,
    );
  }
  return trimmed.length === 0 ? null : trimmed;
}

function requirePositiveInt(
  value: unknown,
  fieldName: string,
  maxVal = MAX_BUDGET_MINOR,
): number {
  if (
    typeof value !== 'number' ||
    !Number.isInteger(value) ||
    !Number.isFinite(value) ||
    value <= 0 ||
    value > maxVal
  ) {
    throw new DomainError(
      'invalid-argument',
      `'${fieldName}' must be a positive integer <= ${maxVal}.`,
    );
  }
  return value;
}

function requireNonNegativeInt(
  value: unknown,
  fieldName: string,
  maxVal = MAX_BUDGET_MINOR,
): number {
  if (
    typeof value !== 'number' ||
    !Number.isInteger(value) ||
    !Number.isFinite(value) ||
    value < 0 ||
    value > maxVal
  ) {
    throw new DomainError(
      'invalid-argument',
      `'${fieldName}' must be a non-negative integer <= ${maxVal}.`,
    );
  }
  return value;
}

function isSafeMediaUrl(url: string): boolean {
  if (url.length === 0 || url.length > 1000) {
    return false;
  }
  return (
    url.startsWith('https://') ||
    url.startsWith('http://') ||
    url.startsWith('gs://')
  );
}

function validateImageUrlList(value: unknown, fieldName: string): string[] {
  if (value === undefined || value === null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new DomainError('invalid-argument', `'${fieldName}' must be an array of URLs.`);
  }
  if (value.length > MAX_IMAGES) {
    throw new DomainError(
      'invalid-argument',
      `'${fieldName}' may contain at most ${MAX_IMAGES} images.`,
    );
  }
  const cleaned: string[] = [];
  for (const item of value) {
    if (typeof item !== 'string' || !isSafeMediaUrl(item.trim())) {
      throw new DomainError(
        'invalid-argument',
        `'${fieldName}' contains an invalid image URL.`,
      );
    }
    const normalized = item.trim();
    if (!cleaned.includes(normalized)) {
      cleaned.push(normalized);
    }
  }
  return cleaned;
}

function nextId(prefix: string, deps?: HandlerDeps): string {
  const raw = deps?.idGenerator ? deps.idGenerator() : crypto.randomUUID();
  return `${prefix}_${raw}`;
}

function nowDate(deps?: HandlerDeps): Date {
  return deps?.now ? deps.now() : new Date();
}

async function resolveActiveAdmin(
  tx: StoreTransaction,
  uid: string,
  allowedRoles: ReadonlySet<AdminRole>,
): Promise<AdminStaffDoc | null> {
  let staff = await tx.get<AdminStaffDoc>('admin_staff', uid);
  if (!staff) {
    const matches = await tx.query<AdminStaffDoc>('admin_staff', [
      { field: 'uid', op: '==', value: uid },
    ]);
    staff = matches[0]?.data ?? null;
  }
  if (!staff || staff.isActive !== true) {
    return null;
  }
  if (!(ALLOWED_ADMIN_ROLES as readonly string[]).includes(staff.role)) {
    return null;
  }
  if (!allowedRoles.has(staff.role)) {
    return null;
  }
  return staff;
}

function createEventDoc(
  deps: HandlerDeps | undefined,
  params: {
    requestId: string;
    actorId: string;
    actorRole: RequestEventDoc['actorRole'];
    type: string;
    fromStatus: WorkRequestStatus | null;
    toStatus: WorkRequestStatus;
    note?: string | null;
    metadata?: Record<string, unknown> | null;
    createdAt: string;
  },
): RequestEventDoc {
  return {
    id: nextId('evt', deps),
    requestId: params.requestId,
    actorId: params.actorId,
    actorRole: params.actorRole,
    type: params.type,
    fromStatus: params.fromStatus,
    toStatus: params.toStatus,
    note: params.note ?? null,
    metadata: params.metadata ?? null,
    createdAt: params.createdAt,
  };
}

function createNotificationDoc(
  deps: HandlerDeps | undefined,
  params: {
    userId: string;
    requestId: string;
    type: string;
    title: string;
    body: string;
    createdAt: string;
  },
): NotificationDoc {
  return {
    id: nextId('ntf', deps),
    userId: params.userId,
    requestId: params.requestId,
    type: params.type,
    title: params.title,
    body: params.body,
    isRead: false,
    createdAt: params.createdAt,
  };
}

/**
 * Creates a Worksite Supply request in status `'open'` with integer minor-unit budget.
 */
export async function createWorkRequest(
  store: DataStore,
  context: AuthContext,
  input: CreateWorkRequestInput,
  deps?: HandlerDeps,
): Promise<{ requestId: string; request: WorkRequestDoc }> {
  const uid = requireAuthUid(context);

  if (input.paymentStatus !== undefined && input.paymentStatus !== 'unpaid') {
    throw new DomainError(
      'permission-denied',
      "Cannot forge initial paymentStatus; new requests always start 'unpaid'.",
    );
  }

  const title = requireNonEmptyString(input.title, 'title', 2, 160);
  const description = optionalString(input.description, 'description', 2000) ?? '';
  const pickupLocation = requireNonEmptyString(
    input.pickupLocation,
    'pickupLocation',
    2,
    300,
  );
  const deliveryLocation = requireNonEmptyString(
    input.deliveryLocation,
    'deliveryLocation',
    2,
    300,
  );
  const deliveryArea =
    optionalString(input.deliveryArea, 'deliveryArea', 120) ?? deliveryLocation;
  const budgetMinor = requirePositiveInt(input.budgetMinor, 'budgetMinor');
  const requesterName = optionalString(input.requesterName, 'requesterName', 100);

  let paymentMethod: PaymentMethod = 'cash_on_delivery';
  if (input.paymentMethod !== undefined) {
    if (
      typeof input.paymentMethod !== 'string' ||
      !(PAYMENT_METHODS as readonly string[]).includes(input.paymentMethod)
    ) {
      throw new DomainError(
        'invalid-argument',
        "Invalid 'paymentMethod'. Allowed: 'cash_on_delivery', 'bank_transfer_manual'.",
      );
    }
    paymentMethod = input.paymentMethod as PaymentMethod;
  }

  const referenceImageUrls = validateImageUrlList(
    input.referenceImageUrls,
    'referenceImageUrls',
  );

  const nowIso = nowDate(deps).toISOString();
  const requestId = nextId('req', deps);

  const requestDoc: WorkRequestDoc = {
    id: requestId,
    requesterId: uid,
    requesterName,
    category: 'worksite_supply',
    title,
    description,
    pickupLocation,
    deliveryLocation,
    deliveryArea,
    budgetMinor,
    paymentMethod,
    paymentStatus: 'unpaid',
    paymentProofUrl: null,
    paymentVerifiedBy: null,
    paymentVerifiedAtUtc: null,
    status: 'open',
    offerCount: 0,
    selectedOfferId: null,
    assignedProviderId: null,
    agreedAmountMinor: null,
    agreedFeeMinor: null,
    referenceImageUrls,
    invoiceImageUrls: [],
    cancellationReason: null,
    disputeReason: null,
    moderationNotes: null,
    completedAtUtc: null,
    createdAt: nowIso,
    updatedAt: nowIso,
  };

  const eventDoc = createEventDoc(deps, {
    requestId,
    actorId: uid,
    actorRole: 'requester',
    type: 'request_created',
    fromStatus: null,
    toStatus: 'open',
    note: 'Worksite supply request created.',
    createdAt: nowIso,
  });

  await store.runTransaction(async (tx) => {
    await tx.set('work_requests', requestId, requestDoc);
    await tx.set('request_events', eventDoc.id, eventDoc);
  });

  return { requestId, request: requestDoc };
}

/**
 * Approved providers submit an offer against an `'open'` or `'offer_received'` request.
 * Prevents self-bidding and unapproved providers.
 */
export async function submitWorkOffer(
  store: DataStore,
  context: AuthContext,
  input: SubmitWorkOfferInput,
  deps?: HandlerDeps,
): Promise<{
  offerId: string;
  offer: WorkOfferDoc;
  requestStatus: WorkRequestStatus;
  offerCount: number;
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);
  const totalAmountMinor = requirePositiveInt(input.totalAmountMinor, 'totalAmountMinor');
  const serviceFeeMinor = requireNonNegativeInt(
    input.serviceFeeMinor,
    'serviceFeeMinor',
    totalAmountMinor,
  );
  const etaMinutes = requirePositiveInt(input.etaMinutes, 'etaMinutes', MAX_ETA_MINUTES);
  const notes = optionalString(input.notes, 'notes', 500);

  const nowIso = nowDate(deps).toISOString();
  const offerId = nextId('off', deps);

  return store.runTransaction(async (tx) => {
    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }

    if (request.requesterId === uid) {
      throw new DomainError(
        'permission-denied',
        'Requester cannot submit an offer on their own work request.',
      );
    }

    const provider = await tx.get<ProviderProfileDoc>('provider_profiles', uid);
    if (!provider || provider.approvalStatus !== 'approved') {
      throw new DomainError(
        'permission-denied',
        "Provider profile must have approvalStatus == 'approved' to submit offers.",
      );
    }

    if (request.status !== 'open' && request.status !== 'offer_received') {
      throw new DomainError(
        'failed-precondition',
        `Cannot submit offer when request status is '${request.status}'.`,
      );
    }

    const nextOfferCount = (request.offerCount ?? 0) + 1;
    const offerDoc: WorkOfferDoc = {
      id: offerId,
      requestId,
      providerId: uid,
      providerName: provider.fullName || 'Verified Provider',
      totalAmountMinor,
      serviceFeeMinor,
      etaMinutes,
      notes,
      status: 'pending',
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    const eventDoc = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole: 'provider',
      type: 'offer_submitted',
      fromStatus: request.status,
      toStatus: 'offer_received',
      note: `Offer ${offerId} submitted (${totalAmountMinor} minor units).`,
      metadata: { offerId, totalAmountMinor, serviceFeeMinor, etaMinutes },
      createdAt: nowIso,
    });

    const notifDoc = createNotificationDoc(deps, {
      userId: request.requesterId,
      requestId,
      type: 'new_offer',
      title: 'New supply offer received',
      body: `${offerDoc.providerName} submitted an offer for '${request.title}'.`,
      createdAt: nowIso,
    });

    await tx.set('work_offers', offerId, offerDoc);
    await tx.update('work_requests', requestId, {
      status: 'offer_received',
      offerCount: nextOfferCount,
      updatedAt: nowIso,
    });
    await tx.set('request_events', eventDoc.id, eventDoc);
    await tx.set('notifications', notifDoc.id, notifDoc);

    return {
      offerId,
      offer: offerDoc,
      requestStatus: 'offer_received',
      offerCount: nextOfferCount,
    };
  });
}

/**
 * Requester accepts one offer, rejects other pending offers, generates salted SHA-256
 * handover secret, and writes requester-only handover view.
 */
export async function acceptWorkOffer(
  store: DataStore,
  context: AuthContext,
  input: AcceptWorkOfferInput,
  deps?: HandlerDeps,
): Promise<{
  requestId: string;
  offerId: string;
  status: WorkRequestStatus;
  assignedProviderId: string;
  agreedAmountMinor: number;
  agreedFeeMinor: number;
  expiresAtUtc: string;
  handoverCode: string;
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);
  const offerId = requireNonEmptyString(input.offerId, 'offerId', 1, 128);

  const now = nowDate(deps);
  const nowIso = now.toISOString();
  const expiresAtUtc = new Date(now.getTime() + HANDOVER_TTL_MS).toISOString();

  return store.runTransaction(async (tx) => {
    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }
    if (request.requesterId !== uid) {
      throw new DomainError(
        'permission-denied',
        'Only the request owner may accept an offer.',
      );
    }
    if (request.status !== 'open' && request.status !== 'offer_received') {
      throw new DomainError(
        'failed-precondition',
        `Cannot accept offer when request status is '${request.status}'.`,
      );
    }

    const offer = await tx.get<WorkOfferDoc>('work_offers', offerId);
    if (!offer || offer.requestId !== requestId) {
      throw new DomainError(
        'not-found',
        `Offer '${offerId}' does not belong to request '${requestId}'.`,
      );
    }
    if (offer.status !== 'pending') {
      throw new DomainError(
        'failed-precondition',
        `Offer '${offerId}' is not pending (current: '${offer.status}').`,
      );
    }

    const provider = await tx.get<ProviderProfileDoc>('provider_profiles', offer.providerId);
    if (!provider || provider.approvalStatus !== 'approved') {
      throw new DomainError(
        'failed-precondition',
        'Selected provider is no longer approved.',
      );
    }

    const allRequestOffers = await tx.query<WorkOfferDoc>('work_offers', [
      { field: 'requestId', op: '==', value: requestId },
    ]);

    const handoverCode = generateHandoverCode(deps?.randomBytes);
    const codeSalt = generateHandoverSalt(deps?.randomBytes);
    const codeHash = hashHandoverCode(handoverCode, codeSalt);

    const secretDoc: WorkRequestSecretDoc = {
      requestId,
      codeHash,
      codeSalt,
      expiresAtUtc,
      attemptsRemaining: HANDOVER_MAX_ATTEMPTS,
      maxAttempts: HANDOVER_MAX_ATTEMPTS,
      usedAtUtc: null,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    const handoverViewDoc: WorkRequestHandoverViewDoc = {
      requestId,
      requesterId: request.requesterId,
      handoverCode,
      expiresAtUtc,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    const selectedEvent = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole: 'requester',
      type: 'offer_selected',
      fromStatus: request.status,
      toStatus: 'offer_selected',
      note: `Selected offer ${offerId} from provider ${offer.providerId}.`,
      metadata: { offerId, providerId: offer.providerId },
      createdAt: nowIso,
    });

    const acceptedEvent = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole: 'requester',
      type: 'offer_accepted',
      fromStatus: 'offer_selected',
      toStatus: 'accepted',
      note: 'Assigned provider confirmed and handover secret generated.',
      metadata: {
        offerId,
        providerId: offer.providerId,
        agreedAmountMinor: offer.totalAmountMinor,
        agreedFeeMinor: offer.serviceFeeMinor,
      },
      createdAt: nowIso,
    });

    const assignedNotif = createNotificationDoc(deps, {
      userId: offer.providerId,
      requestId,
      type: 'offer_accepted',
      title: 'Offer accepted',
      body: `Your offer for '${request.title}' was accepted. Proceed to fulfillment.`,
      createdAt: nowIso,
    });

    // Writes begin strictly after all reads complete.
    await tx.update('work_requests', requestId, {
      selectedOfferId: offerId,
      assignedProviderId: offer.providerId,
      agreedAmountMinor: offer.totalAmountMinor,
      agreedFeeMinor: offer.serviceFeeMinor,
      status: 'accepted',
      updatedAt: nowIso,
    });

    await tx.update('work_offers', offerId, {
      status: 'accepted',
      updatedAt: nowIso,
    });

    for (const other of allRequestOffers) {
      if (other.id !== offerId && other.data.status === 'pending') {
        await tx.update('work_offers', other.id, {
          status: 'rejected',
          updatedAt: nowIso,
        });
      }
    }

    await tx.set('work_request_secrets', requestId, secretDoc);
    await tx.set('work_request_handover_view', requestId, handoverViewDoc);
    await tx.set('request_events', selectedEvent.id, selectedEvent);
    await tx.set('request_events', acceptedEvent.id, acceptedEvent);
    await tx.set('notifications', assignedNotif.id, assignedNotif);

    return {
      requestId,
      offerId,
      status: 'accepted',
      assignedProviderId: offer.providerId,
      agreedAmountMinor: offer.totalAmountMinor,
      agreedFeeMinor: offer.serviceFeeMinor,
      expiresAtUtc,
      handoverCode,
    };
  });
}

/**
 * Transitions work_requests through fulfillment, cancellation, or dispute stages.
 * Never permits setting `'completed'` directly or tampering with paymentStatus.
 */
export async function transitionWorkRequestStatus(
  store: DataStore,
  context: AuthContext,
  input: TransitionWorkRequestStatusInput,
  deps?: HandlerDeps,
): Promise<{
  requestId: string;
  fromStatus: WorkRequestStatus;
  toStatus: WorkRequestStatus;
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);

  if (input.paymentStatus !== undefined) {
    throw new DomainError(
      'permission-denied',
      'paymentStatus cannot be modified via transitionWorkRequestStatus.',
    );
  }

  if (!isWorkRequestStatus(input.targetStatus)) {
    throw new DomainError('invalid-argument', 'Invalid targetStatus.');
  }
  const targetStatus = input.targetStatus;
  const reason = optionalString(input.reason, 'reason', 500);
  const newInvoiceUrls = validateImageUrlList(input.invoiceImageUrls, 'invoiceImageUrls');

  if (newInvoiceUrls.length > 0 && !INVOICE_ATTACHMENT_STATUSES.has(targetStatus)) {
    throw new DomainError(
      'invalid-argument',
      `invoiceImageUrls can only be attached when transitioning to picked_up, in_transit, or delivered_pending_confirmation.`,
    );
  }

  const nowIso = nowDate(deps).toISOString();

  return store.runTransaction(async (tx) => {
    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }

    const provider = await tx.get<ProviderProfileDoc>('provider_profiles', uid);
    const admin = await resolveActiveAdmin(tx, uid, MODERATION_ADMIN_ROLES);

    const isRequester = request.requesterId === uid;
    const isAssignedProvider = request.assignedProviderId === uid;
    const isApprovedProvider = provider?.approvalStatus === 'approved';
    const isActiveAdmin = admin !== null;

    const actorRole = assertWorkRequestTransition(request.status, targetStatus, {
      isRequester,
      isAssignedProvider,
      isApprovedProvider,
      isActiveAdmin,
      allowSystemCompletion: false,
    });

    const patch: Record<string, unknown> = {
      status: targetStatus,
      updatedAt: nowIso,
    };

    if (newInvoiceUrls.length > 0) {
      const merged = [...(request.invoiceImageUrls ?? [])];
      for (const url of newInvoiceUrls) {
        if (!merged.includes(url)) {
          merged.push(url);
        }
      }
      if (merged.length > MAX_IMAGES) {
        throw new DomainError(
          'invalid-argument',
          `Total invoiceImageUrls cannot exceed ${MAX_IMAGES}.`,
        );
      }
      patch.invoiceImageUrls = merged;
    }

    if (targetStatus === 'cancelled' && reason) {
      patch.cancellationReason = reason;
    }
    if (targetStatus === 'disputed' && reason) {
      patch.disputeReason = reason;
    }

    const eventDoc = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole,
      type: 'status_changed',
      fromStatus: request.status,
      toStatus: targetStatus,
      note: reason ?? `Transitioned from '${request.status}' to '${targetStatus}'.`,
      metadata: newInvoiceUrls.length > 0 ? { addedInvoices: newInvoiceUrls.length } : null,
      createdAt: nowIso,
    });

    const counterpartyId =
      uid === request.requesterId ? request.assignedProviderId : request.requesterId;

    await tx.update('work_requests', requestId, patch);
    await tx.set('request_events', eventDoc.id, eventDoc);

    if (counterpartyId) {
      const notifDoc = createNotificationDoc(deps, {
        userId: counterpartyId,
        requestId,
        type: 'status_update',
        title: `Request status: ${targetStatus}`,
        body: `Work request '${request.title}' moved to '${targetStatus}'.`,
        createdAt: nowIso,
      });
      await tx.set('notifications', notifDoc.id, notifDoc);
    }

    return {
      requestId,
      fromStatus: request.status,
      toStatus: targetStatus,
    };
  });
}

/**
 * Verifies the requester's 6-char handover code in constant time against the
 * salted SHA-256 secret and completes the request atomically.
 * Wrong codes persist `attemptsRemaining - 1` before rejecting with failed-precondition.
 */
export async function verifyHandoverAndComplete(
  store: DataStore,
  context: AuthContext,
  input: VerifyHandoverAndCompleteInput,
  deps?: HandlerDeps,
): Promise<{
  requestId: string;
  status: 'completed';
  completedAtUtc: string;
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);
  const code = requireNonEmptyString(input.code, 'code', 1, 32);

  const now = nowDate(deps);
  const nowIso = now.toISOString();

  const txResult = await store.runTransaction(async (tx) => {
    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }

    if (request.assignedProviderId !== uid) {
      throw new DomainError(
        'permission-denied',
        'Only the assigned provider may verify handover and complete this request.',
      );
    }

    const provider = await tx.get<ProviderProfileDoc>('provider_profiles', uid);
    if (!provider || provider.approvalStatus !== 'approved') {
      throw new DomainError(
        'permission-denied',
        'Assigned provider must remain approved to complete handover.',
      );
    }

    if (request.status !== 'delivered_pending_confirmation') {
      throw new DomainError(
        'failed-precondition',
        `Handover can only be verified when status is 'delivered_pending_confirmation' (current: '${request.status}').`,
      );
    }

    const secret = await tx.get<WorkRequestSecretDoc>('work_request_secrets', requestId);
    if (!secret) {
      throw new DomainError(
        'failed-precondition',
        'No handover verification secret exists for this request.',
      );
    }

    if (secret.usedAtUtc !== null) {
      throw new DomainError(
        'failed-precondition',
        'Handover code has already been used.',
      );
    }

    if (secret.attemptsRemaining <= 0) {
      throw new DomainError(
        'failed-precondition',
        'Handover verification attempts have been exhausted.',
      );
    }

    const expiresAtMs = Date.parse(secret.expiresAtUtc);
    if (Number.isNaN(expiresAtMs) || now.getTime() > expiresAtMs) {
      throw new DomainError('failed-precondition', 'Handover code has expired.');
    }

    const isMatch = verifyHandoverCodeHash(code, secret.codeSalt, secret.codeHash);
    if (!isMatch) {
      const nextAttempts = Math.max(0, secret.attemptsRemaining - 1);
      const failedEvent = createEventDoc(deps, {
        requestId,
        actorId: uid,
        actorRole: 'provider',
        type: 'handover_attempt_failed',
        fromStatus: request.status,
        toStatus: request.status,
        note: `Invalid handover code attempt (${nextAttempts} remaining).`,
        metadata: { attemptsRemaining: nextAttempts },
        createdAt: nowIso,
      });

      await tx.update('work_request_secrets', requestId, {
        attemptsRemaining: nextAttempts,
        updatedAt: nowIso,
      });
      await tx.set('request_events', failedEvent.id, failedEvent);

      return { matched: false as const, attemptsRemaining: nextAttempts };
    }

    assertWorkRequestTransition(request.status, 'completed', {
      isAssignedProvider: true,
      isApprovedProvider: true,
      allowSystemCompletion: true,
    });

    const completedEvent = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole: 'provider',
      type: 'handover_completed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'completed',
      note: 'Handover code verified; delivery confirmed and completed.',
      createdAt: nowIso,
    });

    const requesterNotif = createNotificationDoc(deps, {
      userId: request.requesterId,
      requestId,
      type: 'request_completed',
      title: 'Delivery confirmed',
      body: `Handover for '${request.title}' was verified and marked completed.`,
      createdAt: nowIso,
    });

    await tx.update('work_request_secrets', requestId, {
      usedAtUtc: nowIso,
      updatedAt: nowIso,
    });
    await tx.update('work_requests', requestId, {
      status: 'completed',
      completedAtUtc: nowIso,
      updatedAt: nowIso,
    });
    await tx.update('provider_profiles', uid, {
      completedTasksCount: (provider.completedTasksCount ?? 0) + 1,
      updatedAt: nowIso,
    });
    await tx.set('request_events', completedEvent.id, completedEvent);
    await tx.set('notifications', requesterNotif.id, requesterNotif);

    return { matched: true as const };
  });

  if (!txResult.matched) {
    throw new DomainError(
      'failed-precondition',
      `Invalid handover code. Attempts remaining: ${txResult.attemptsRemaining}.`,
      { attemptsRemaining: txResult.attemptsRemaining },
    );
  }

  return {
    requestId,
    status: 'completed',
    completedAtUtc: nowIso,
  };
}

/**
 * Allows requester or assigned provider on a completed request to submit one rating (1..5),
 * updating the target user's running average atomically.
 */
export async function submitRequestRating(
  store: DataStore,
  context: AuthContext,
  input: SubmitRequestRatingInput,
  deps?: HandlerDeps,
): Promise<{
  ratingId: string;
  toUserId: string;
  stars: number;
  ratingAvg: number;
  ratingCount: number;
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);
  const stars = requirePositiveInt(input.stars, 'stars', 5);
  const comment = optionalString(input.comment, 'comment', 500);
  const nowIso = nowDate(deps).toISOString();

  return store.runTransaction(async (tx) => {
    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }
    if (request.status !== 'completed') {
      throw new DomainError(
        'failed-precondition',
        'Ratings can only be submitted after a request is completed.',
      );
    }

    const isRequester = request.requesterId === uid;
    const isProvider = request.assignedProviderId === uid;
    if (!isRequester && !isProvider) {
      throw new DomainError(
        'permission-denied',
        'Only request participants may submit ratings.',
      );
    }

    const toUserId = isRequester ? request.assignedProviderId : request.requesterId;
    if (!toUserId) {
      throw new DomainError('failed-precondition', 'Target user is missing for rating.');
    }

    const ratingId = `${requestId}_${uid}`;
    const existingRating = await tx.get<RatingDoc>('ratings', ratingId);
    if (existingRating) {
      throw new DomainError(
        'already-exists',
        'You have already submitted a rating for this request.',
      );
    }

    const providerTarget = isRequester
      ? await tx.get<ProviderProfileDoc>('provider_profiles', toUserId)
      : null;
    const businessTarget = !isRequester
      ? await tx.get<BusinessProfileDoc>('business_profiles', toUserId)
      : null;

    const targetCollection = isRequester ? 'provider_profiles' : 'business_profiles';
    const currentProfile = isRequester ? providerTarget : businessTarget;

    const prevCount =
      typeof currentProfile?.ratingCount === 'number' ? currentProfile.ratingCount : 0;
    const prevAvg =
      typeof currentProfile?.ratingAvg === 'number' ? currentProfile.ratingAvg : 0;

    const nextCount = prevCount + 1;
    const nextAvg = Number((((prevAvg * prevCount) + stars) / nextCount).toFixed(2));

    const ratingDoc: RatingDoc = {
      id: ratingId,
      requestId,
      fromUserId: uid,
      toUserId,
      fromRole: isRequester ? 'requester' : 'provider',
      stars,
      comment,
      createdAt: nowIso,
    };

    await tx.set('ratings', ratingId, ratingDoc);

    if (currentProfile) {
      await tx.update(targetCollection, toUserId, {
        ratingAvg: nextAvg,
        ratingCount: nextCount,
        updatedAt: nowIso,
      });
    } else if (!isRequester) {
      const createdBusiness: BusinessProfileDoc = {
        id: toUserId,
        userId: toUserId,
        ratingAvg: nextAvg,
        ratingCount: nextCount,
        createdAt: nowIso,
        updatedAt: nowIso,
      };
      await tx.set('business_profiles', toUserId, createdBusiness);
    } else {
      throw new DomainError(
        'not-found',
        `Provider profile '${toUserId}' not found for rating update.`,
      );
    }

    return {
      ratingId,
      toUserId,
      stars,
      ratingAvg: nextAvg,
      ratingCount: nextCount,
    };
  });
}

/**
 * Enforces manual payment settlement state transitions and strict immutability
 * once paymentStatus reaches `'verified_settled'`.
 */
export async function recordPaymentStatus(
  store: DataStore,
  context: AuthContext,
  input: RecordPaymentStatusInput,
  deps?: HandlerDeps,
): Promise<{
  requestId: string;
  paymentStatus: WorkRequestDoc['paymentStatus'];
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);
  if (!isPaymentSettlementStatus(input.targetPaymentStatus)) {
    throw new DomainError('invalid-argument', 'Invalid targetPaymentStatus.');
  }
  const targetPaymentStatus = input.targetPaymentStatus;
  const paymentProofUrl = optionalString(input.paymentProofUrl, 'paymentProofUrl', 1000);
  if (paymentProofUrl !== null && !isSafeMediaUrl(paymentProofUrl)) {
    throw new DomainError('invalid-argument', 'Invalid paymentProofUrl.');
  }

  const nowIso = nowDate(deps).toISOString();

  return store.runTransaction(async (tx) => {
    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }

    const admin = await resolveActiveAdmin(tx, uid, MODERATION_ADMIN_ROLES);
    const actorRole = assertPaymentStatusTransition(
      request.paymentStatus,
      targetPaymentStatus,
      {
        isRequester: request.requesterId === uid,
        isAssignedProvider: request.assignedProviderId === uid,
        isActiveAdmin: admin !== null,
        paymentMethod: request.paymentMethod,
      },
    );

    if (targetPaymentStatus === 'transfer_proof_submitted' && !paymentProofUrl) {
      throw new DomainError(
        'invalid-argument',
        'paymentProofUrl is required when submitting transfer proof.',
      );
    }

    const patch: Record<string, unknown> = {
      paymentStatus: targetPaymentStatus,
      updatedAt: nowIso,
    };

    if (paymentProofUrl) {
      patch.paymentProofUrl = paymentProofUrl;
    }
    if (targetPaymentStatus === 'verified_settled') {
      patch.paymentVerifiedBy = uid;
      patch.paymentVerifiedAtUtc = nowIso;
    }

    const eventDoc = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole,
      type: 'payment_status_changed',
      fromStatus: request.status,
      toStatus: request.status,
      note: `Payment status updated from '${request.paymentStatus}' to '${targetPaymentStatus}'.`,
      metadata: {
        previousPaymentStatus: request.paymentStatus,
        newPaymentStatus: targetPaymentStatus,
      },
      createdAt: nowIso,
    });

    await tx.update('work_requests', requestId, patch);
    await tx.set('request_events', eventDoc.id, eventDoc);

    if (admin && targetPaymentStatus === 'verified_settled') {
      const auditDoc: AdminAuditLogDoc = {
        id: nextId('aud', deps),
        adminUid: uid,
        adminRole: admin.role,
        action: 'verify_payment_settled',
        targetCollection: 'work_requests',
        targetEntityId: requestId,
        previousState: { paymentStatus: request.paymentStatus },
        newState: { paymentStatus: 'verified_settled' },
        reason: null,
        createdAt: nowIso,
      };
      await tx.set('admin_audit_logs', auditDoc.id, auditDoc);
    }

    return {
      requestId,
      paymentStatus: targetPaymentStatus,
    };
  });
}

/**
 * Active admin reviews a provider application/status and appends an immutable audit log.
 */
export async function adminReviewProvider(
  store: DataStore,
  context: AuthContext,
  input: AdminReviewProviderInput,
  deps?: HandlerDeps,
): Promise<{
  providerId: string;
  approvalStatus: ProviderApprovalStatus;
  auditLogId: string;
}> {
  const uid = requireAuthUid(context);
  const providerId = requireNonEmptyString(input.providerId, 'providerId', 1, 128);

  if (
    typeof input.decision !== 'string' ||
    !(PROVIDER_APPROVAL_STATUSES as readonly string[]).includes(input.decision)
  ) {
    throw new DomainError(
      'invalid-argument',
      "Invalid 'decision'. Allowed: pending, approved, rejected, suspended.",
    );
  }
  const decision = input.decision as ProviderApprovalStatus;
  const reason = optionalString(input.reason, 'reason', 500);

  if ((decision === 'rejected' || decision === 'suspended') && !reason) {
    throw new DomainError(
      'invalid-argument',
      `A non-empty 'reason' is required when setting provider status to '${decision}'.`,
    );
  }

  const nowIso = nowDate(deps).toISOString();
  const auditLogId = nextId('aud', deps);

  return store.runTransaction(async (tx) => {
    const admin = await resolveActiveAdmin(tx, uid, PROVIDER_REVIEW_ADMIN_ROLES);
    if (!admin) {
      throw new DomainError(
        'permission-denied',
        'Active authorized admin_staff record is required.',
      );
    }

    const profile = await tx.get<ProviderProfileDoc>('provider_profiles', providerId);
    const verification = await tx.get<ProviderVerificationDoc>(
      'provider_verifications',
      providerId,
    );

    if (!profile && !verification) {
      throw new DomainError(
        'not-found',
        `Provider profile or verification '${providerId}' not found.`,
      );
    }

    const previousStatus = profile?.approvalStatus ?? verification?.status ?? null;

    if (profile) {
      await tx.update('provider_profiles', providerId, {
        approvalStatus: decision,
        reviewedBy: uid,
        reviewedAtUtc: nowIso,
        rejectionReason: decision === 'rejected' || decision === 'suspended' ? reason : null,
        updatedAt: nowIso,
      });
    } else {
      const createdProfile: ProviderProfileDoc = {
        id: providerId,
        userId: providerId,
        fullName: verification?.fullName ?? 'Provider',
        approvalStatus: decision,
        completedTasksCount: 0,
        ratingAvg: 0,
        ratingCount: 0,
        reviewedBy: uid,
        reviewedAtUtc: nowIso,
        rejectionReason: decision === 'rejected' || decision === 'suspended' ? reason : null,
        createdAt: nowIso,
        updatedAt: nowIso,
      };
      await tx.set('provider_profiles', providerId, createdProfile);
    }

    if (verification) {
      await tx.update('provider_verifications', providerId, {
        status: decision,
        reviewedBy: uid,
        reviewedAtUtc: nowIso,
        rejectionReason: decision === 'rejected' || decision === 'suspended' ? reason : null,
        updatedAt: nowIso,
      });
    }

    const auditDoc: AdminAuditLogDoc = {
      id: auditLogId,
      adminUid: uid,
      adminRole: admin.role,
      action: 'provider_review',
      targetCollection: 'provider_profiles',
      targetEntityId: providerId,
      previousState: { approvalStatus: previousStatus },
      newState: { approvalStatus: decision },
      reason,
      createdAt: nowIso,
    };

    const notifDoc = createNotificationDoc(deps, {
      userId: providerId,
      requestId: providerId,
      type: 'provider_review',
      title: `Provider account ${decision}`,
      body: reason
        ? `Your provider review status is '${decision}': ${reason}`
        : `Your provider review status is now '${decision}'.`,
      createdAt: nowIso,
    });

    await tx.set('admin_audit_logs', auditLogId, auditDoc);
    await tx.set('notifications', notifDoc.id, notifDoc);

    return {
      providerId,
      approvalStatus: decision,
      auditLogId,
    };
  });
}

/**
 * Active admin moderates a work request (cancel, flag dispute, resolve dispute,
 * or verify manual bank transfer settlement) and appends an immutable audit log.
 */
export async function adminModerateWorkRequest(
  store: DataStore,
  context: AuthContext,
  input: AdminModerateWorkRequestInput,
  deps?: HandlerDeps,
): Promise<{
  requestId: string;
  status: WorkRequestStatus;
  paymentStatus: WorkRequestDoc['paymentStatus'];
  auditLogId: string;
}> {
  const uid = requireAuthUid(context);
  const requestId = requireNonEmptyString(input.requestId, 'requestId', 1, 128);
  const action = requireNonEmptyString(input.action, 'action', 1, 64);
  const reason = optionalString(input.reason, 'reason', 500);
  const nowIso = nowDate(deps).toISOString();
  const auditLogId = nextId('aud', deps);

  return store.runTransaction(async (tx) => {
    const admin = await resolveActiveAdmin(tx, uid, MODERATION_ADMIN_ROLES);
    if (!admin) {
      throw new DomainError(
        'permission-denied',
        'Active authorized admin_staff record is required.',
      );
    }

    const request = await tx.get<WorkRequestDoc>('work_requests', requestId);
    if (!request) {
      throw new DomainError('not-found', `Work request '${requestId}' not found.`);
    }

    let nextStatus = request.status;
    let nextPaymentStatus = request.paymentStatus;
    const patch: Record<string, unknown> = { updatedAt: nowIso };

    if (action === 'cancel') {
      assertWorkRequestTransition(request.status, 'cancelled', { isActiveAdmin: true });
      nextStatus = 'cancelled';
      patch.status = 'cancelled';
      if (reason) patch.cancellationReason = reason;
    } else if (action === 'flag_dispute') {
      assertWorkRequestTransition(request.status, 'disputed', { isActiveAdmin: true });
      nextStatus = 'disputed';
      patch.status = 'disputed';
      if (reason) patch.disputeReason = reason;
    } else if (action === 'resolve_dispute') {
      if (request.status !== 'disputed') {
        throw new DomainError(
          'failed-precondition',
          "Can only resolve a dispute when request status is 'disputed'.",
        );
      }
      if (!isWorkRequestStatus(input.targetStatus)) {
        throw new DomainError('invalid-argument', 'Valid targetStatus is required to resolve dispute.');
      }
      if (
        input.targetStatus !== 'cancelled' &&
        input.targetStatus !== 'in_progress' &&
        input.targetStatus !== 'delivered_pending_confirmation'
      ) {
        throw new DomainError(
          'invalid-argument',
          "Dispute resolution targetStatus must be 'cancelled', 'in_progress', or 'delivered_pending_confirmation'.",
        );
      }
      nextStatus = input.targetStatus;
      patch.status = input.targetStatus;
      if (reason) patch.moderationNotes = reason;
    } else if (action === 'verify_payment_settled') {
      assertPaymentStatusTransition(request.paymentStatus, 'verified_settled', {
        isActiveAdmin: true,
        paymentMethod: request.paymentMethod,
      });
      nextPaymentStatus = 'verified_settled';
      patch.paymentStatus = 'verified_settled';
      patch.paymentVerifiedBy = uid;
      patch.paymentVerifiedAtUtc = nowIso;
    } else {
      throw new DomainError('invalid-argument', `Unsupported moderation action '${action}'.`);
    }

    const eventDoc = createEventDoc(deps, {
      requestId,
      actorId: uid,
      actorRole: 'admin',
      type: `admin_${action}`,
      fromStatus: request.status,
      toStatus: nextStatus,
      note: reason ?? `Admin moderation action '${action}'.`,
      metadata: {
        action,
        previousPaymentStatus: request.paymentStatus,
        newPaymentStatus: nextPaymentStatus,
      },
      createdAt: nowIso,
    });

    const auditDoc: AdminAuditLogDoc = {
      id: auditLogId,
      adminUid: uid,
      adminRole: admin.role,
      action: `moderate_${action}`,
      targetCollection: 'work_requests',
      targetEntityId: requestId,
      previousState: {
        status: request.status,
        paymentStatus: request.paymentStatus,
      },
      newState: {
        status: nextStatus,
        paymentStatus: nextPaymentStatus,
      },
      reason,
      createdAt: nowIso,
    };

    await tx.update('work_requests', requestId, patch);
    await tx.set('request_events', eventDoc.id, eventDoc);
    await tx.set('admin_audit_logs', auditLogId, auditDoc);

    return {
      requestId,
      status: nextStatus,
      paymentStatus: nextPaymentStatus,
      auditLogId,
    };
  });
}
