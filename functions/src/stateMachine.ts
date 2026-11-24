import {
  ActorRole,
  DomainError,
  PAYMENT_SETTLEMENT_STATUSES,
  PaymentSettlementStatus,
  WORK_REQUEST_STATUSES,
  WorkRequestStatus,
} from './types';

export const PROVIDER_FULFILLMENT_TRANSITIONS: Readonly<
  Partial<Record<WorkRequestStatus, WorkRequestStatus>>
> = {
  accepted: 'in_progress',
  in_progress: 'picked_up',
  picked_up: 'in_transit',
  in_transit: 'delivered_pending_confirmation',
};

export const INVOICE_ATTACHMENT_STATUSES: ReadonlySet<WorkRequestStatus> = new Set([
  'picked_up',
  'in_transit',
  'delivered_pending_confirmation',
]);

export const REQUESTER_CANCELLABLE_STATUSES: ReadonlySet<WorkRequestStatus> = new Set([
  'open',
  'offer_received',
  'offer_selected',
  'accepted',
  'in_progress',
]);

export const DISPUTABLE_STATUSES: ReadonlySet<WorkRequestStatus> = new Set([
  'accepted',
  'in_progress',
  'picked_up',
  'in_transit',
  'delivered_pending_confirmation',
]);

export const TERMINAL_STATUSES: ReadonlySet<WorkRequestStatus> = new Set([
  'completed',
  'cancelled',
]);

export function isWorkRequestStatus(value: unknown): value is WorkRequestStatus {
  return (
    typeof value === 'string' &&
    (WORK_REQUEST_STATUSES as readonly string[]).includes(value)
  );
}

export function isPaymentSettlementStatus(
  value: unknown,
): value is PaymentSettlementStatus {
  return (
    typeof value === 'string' &&
    (PAYMENT_SETTLEMENT_STATUSES as readonly string[]).includes(value)
  );
}

export interface TransitionCheckOptions {
  isAssignedProvider?: boolean;
  isApprovedProvider?: boolean;
  isRequester?: boolean;
  isActiveAdmin?: boolean;
  allowSystemCompletion?: boolean;
}

export interface TransitionCheckResult {
  allowed: boolean;
  actorRole?: ActorRole;
  code?: 'permission-denied' | 'failed-precondition';
  reason?: string;
}

/**
 * Pure state machine validator for Worksite Supply request statuses.
 */
export function evaluateWorkRequestTransition(
  from: WorkRequestStatus,
  to: WorkRequestStatus,
  options: TransitionCheckOptions,
): TransitionCheckResult {
  if (from === to) {
    return {
      allowed: false,
      code: 'failed-precondition',
      reason: `Request is already in status '${from}'.`,
    };
  }

  if (TERMINAL_STATUSES.has(from)) {
    return {
      allowed: false,
      code: 'failed-precondition',
      reason: `Cannot transition out of terminal status '${from}'.`,
    };
  }

  // Handover completion is strictly reserved for verifyHandoverAndComplete.
  if (to === 'completed') {
    if (
      options.allowSystemCompletion &&
      from === 'delivered_pending_confirmation' &&
      options.isAssignedProvider &&
      options.isApprovedProvider
    ) {
      return { allowed: true, actorRole: 'provider' };
    }
    return {
      allowed: false,
      code: from === 'delivered_pending_confirmation' ? 'permission-denied' : 'failed-precondition',
      reason:
        "Status 'completed' can only be set by verifyHandoverAndComplete after valid handover code verification.",
    };
  }

  // Provider linear fulfillment chain:
  // accepted -> in_progress -> picked_up -> in_transit -> delivered_pending_confirmation
  const expectedNext = PROVIDER_FULFILLMENT_TRANSITIONS[from];
  if (expectedNext !== undefined && to === expectedNext) {
    if (!options.isAssignedProvider) {
      return {
        allowed: false,
        code: 'permission-denied',
        reason: `Only the assigned provider may transition '${from}' -> '${to}'.`,
      };
    }
    if (!options.isApprovedProvider) {
      return {
        allowed: false,
        code: 'permission-denied',
        reason: 'Provider approvalStatus must be approved to update fulfillment stages.',
      };
    }
    return { allowed: true, actorRole: 'provider' };
  }

  // Cancellation rules:
  // - Requester may cancel strictly before 'picked_up'
  // - Active admin may cancel any non-terminal status
  if (to === 'cancelled') {
    if (options.isActiveAdmin) {
      return { allowed: true, actorRole: 'admin' };
    }
    if (options.isRequester) {
      if (!REQUESTER_CANCELLABLE_STATUSES.has(from)) {
        return {
          allowed: false,
          code: 'failed-precondition',
          reason: `Requester cannot cancel once status has reached '${from}'.`,
        };
      }
      return { allowed: true, actorRole: 'requester' };
    }
    return {
      allowed: false,
      code: 'permission-denied',
      reason: 'Only the requester (before pickup) or an active admin may cancel this request.',
    };
  }

  // Dispute rules:
  // - Requester, assigned provider, or active admin during active fulfillment
  if (to === 'disputed') {
    if (!DISPUTABLE_STATUSES.has(from)) {
      return {
        allowed: false,
        code: 'failed-precondition',
        reason: `Disputes can only be opened during active fulfillment, not from '${from}'.`,
      };
    }
    if (options.isActiveAdmin) {
      return { allowed: true, actorRole: 'admin' };
    }
    if (options.isRequester) {
      return { allowed: true, actorRole: 'requester' };
    }
    if (options.isAssignedProvider) {
      return { allowed: true, actorRole: 'provider' };
    }
    return {
      allowed: false,
      code: 'permission-denied',
      reason: 'Only request participants or an active admin may open a dispute.',
    };
  }

  return {
    allowed: false,
    code: 'failed-precondition',
    reason: `Invalid state transition from '${from}' to '${to}'.`,
  };
}

export function assertWorkRequestTransition(
  from: WorkRequestStatus,
  to: WorkRequestStatus,
  options: TransitionCheckOptions,
): ActorRole {
  const result = evaluateWorkRequestTransition(from, to, options);
  if (!result.allowed || !result.actorRole) {
    throw new DomainError(
      result.code ?? 'failed-precondition',
      result.reason ?? `Invalid transition from '${from}' to '${to}'.`,
    );
  }
  return result.actorRole;
}

export interface PaymentTransitionOptions {
  isRequester?: boolean;
  isAssignedProvider?: boolean;
  isActiveAdmin?: boolean;
  paymentMethod?: string;
}

/**
 * Validates manual payment settlement status transitions.
 * Once `verified_settled`, paymentStatus is strictly immutable.
 */
export function assertPaymentStatusTransition(
  from: PaymentSettlementStatus,
  to: PaymentSettlementStatus,
  options: PaymentTransitionOptions,
): ActorRole {
  if (from === 'verified_settled') {
    throw new DomainError(
      'failed-precondition',
      "Payment status is already 'verified_settled' and cannot be modified or overwritten.",
    );
  }

  if (from === to) {
    throw new DomainError(
      'failed-precondition',
      `Payment status is already '${from}'.`,
    );
  }

  if (to === 'unpaid') {
    throw new DomainError(
      'failed-precondition',
      "Cannot revert payment status back to 'unpaid'.",
    );
  }

  if (to === 'transfer_proof_submitted') {
    if (!options.isRequester) {
      throw new DomainError(
        'permission-denied',
        'Only the request owner may submit bank transfer proof.',
      );
    }
    if (options.paymentMethod !== 'bank_transfer_manual') {
      throw new DomainError(
        'failed-precondition',
        "Transfer proof is only applicable when paymentMethod is 'bank_transfer_manual'.",
      );
    }
    if (from !== 'unpaid') {
      throw new DomainError(
        'failed-precondition',
        `Cannot submit transfer proof from payment status '${from}'.`,
      );
    }
    return 'requester';
  }

  if (to === 'verified_settled') {
    if (!options.isActiveAdmin) {
      throw new DomainError(
        'permission-denied',
        "Only an active administrator may mark payment status as 'verified_settled'.",
      );
    }
    return 'admin';
  }

  if (to === 'disputed') {
    if (options.isActiveAdmin) {
      return 'admin';
    }
    if (options.isRequester) {
      return 'requester';
    }
    if (options.isAssignedProvider) {
      return 'provider';
    }
    throw new DomainError(
      'permission-denied',
      'Only request participants or an active administrator may dispute payment status.',
    );
  }

  throw new DomainError(
    'invalid-argument',
    `Unsupported payment status transition to '${String(to)}'.`,
  );
}
