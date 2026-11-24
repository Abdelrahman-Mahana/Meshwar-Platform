import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  DeleteUserAccountInput,
  acceptWorkOffer as acceptWorkOfferHandler,
  adminModerateWorkRequest as adminModerateWorkRequestHandler,
  adminReviewProvider as adminReviewProviderHandler,
  createWorkRequest as createWorkRequestHandler,
  deleteUserAccount as deleteUserAccountHandler,
  recordPaymentStatus as recordPaymentStatusHandler,
  submitRequestRating as submitRequestRatingHandler,
  submitWorkOffer as submitWorkOfferHandler,
  transitionWorkRequestStatus as transitionWorkRequestStatusHandler,
  verifyHandoverAndComplete as verifyHandoverAndCompleteHandler,
} from './handlers';
import { FirestoreStore } from './store';
import {
  AcceptWorkOfferInput,
  AdminModerateWorkRequestInput,
  AdminReviewProviderInput,
  AuthContext,
  CreateWorkRequestInput,
  DomainError,
  RecordPaymentStatusInput,
  SubmitRequestRatingInput,
  SubmitWorkOfferInput,
  TransitionWorkRequestStatusInput,
  VerifyHandoverAndCompleteInput,
} from './types';

const FUNCTION_REGION = 'europe-west1';

function ensureAdminApp(): void {
  if (getApps().length === 0) {
    initializeApp();
  }
}

function getStore(): FirestoreStore {
  ensureAdminApp();
  return new FirestoreStore(getFirestore());
}

function toAuthContext(request: CallableRequest<unknown>): AuthContext {
  return {
    uid: request.auth?.uid ?? null,
    tokenClaims: (request.auth?.token as Record<string, unknown> | undefined) ?? undefined,
  };
}

function wrapCallable<TInput, TResult>(
  fn: (store: FirestoreStore, context: AuthContext, input: TInput) => Promise<TResult>,
) {
  return onCall<TInput, Promise<TResult>>(
    { region: FUNCTION_REGION },
    async (request) => {
      try {
        const store = getStore();
        const authContext = toAuthContext(request);
        const input = (request.data ?? {}) as TInput;
        return await fn(store, authContext, input);
      } catch (err) {
        if (err instanceof DomainError) {
          throw new HttpsError(err.code, err.message, err.details);
        }
        if (err instanceof HttpsError) {
          throw err;
        }
        throw new HttpsError(
          'internal',
          err instanceof Error ? err.message : 'Unexpected server error.',
        );
      }
    },
  );
}

export const createWorkRequest = wrapCallable<
  CreateWorkRequestInput,
  Awaited<ReturnType<typeof createWorkRequestHandler>>
>(createWorkRequestHandler);

export const submitWorkOffer = wrapCallable<
  SubmitWorkOfferInput,
  Awaited<ReturnType<typeof submitWorkOfferHandler>>
>(submitWorkOfferHandler);

export const acceptWorkOffer = wrapCallable<
  AcceptWorkOfferInput,
  Awaited<ReturnType<typeof acceptWorkOfferHandler>>
>(acceptWorkOfferHandler);

export const transitionWorkRequestStatus = wrapCallable<
  TransitionWorkRequestStatusInput,
  Awaited<ReturnType<typeof transitionWorkRequestStatusHandler>>
>(transitionWorkRequestStatusHandler);

export const verifyHandoverAndComplete = wrapCallable<
  VerifyHandoverAndCompleteInput,
  Awaited<ReturnType<typeof verifyHandoverAndCompleteHandler>>
>(verifyHandoverAndCompleteHandler);

export const submitRequestRating = wrapCallable<
  SubmitRequestRatingInput,
  Awaited<ReturnType<typeof submitRequestRatingHandler>>
>(submitRequestRatingHandler);

export const recordPaymentStatus = wrapCallable<
  RecordPaymentStatusInput,
  Awaited<ReturnType<typeof recordPaymentStatusHandler>>
>(recordPaymentStatusHandler);

export const adminReviewProvider = wrapCallable<
  AdminReviewProviderInput,
  Awaited<ReturnType<typeof adminReviewProviderHandler>>
>(adminReviewProviderHandler);

export const adminModerateWorkRequest = wrapCallable<
  AdminModerateWorkRequestInput,
  Awaited<ReturnType<typeof adminModerateWorkRequestHandler>>
>(adminModerateWorkRequestHandler);

export const deleteUserAccount = wrapCallable<
  DeleteUserAccountInput,
  Awaited<ReturnType<typeof deleteUserAccountHandler>>
>((store, context, input) =>
  deleteUserAccountHandler(store, context, input, {
    deleteAuthUser: async (uid: string) => {
      ensureAdminApp();
      try {
        await getAuth().deleteUser(uid);
      } catch (err) {
        const code = (err as { code?: string } | null)?.code;
        if (code === 'auth/user-not-found') {
          return;
        }
        throw err;
      }
    },
  }),
);
