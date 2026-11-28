import test from 'node:test';
import assert from 'node:assert/strict';

import { InMemoryStore } from '../lib/store.js';
import {
  generateHandoverCode,
  generateHandoverSalt,
  hashHandoverCode,
  verifyHandoverCodeHash,
} from '../lib/handoverCrypto.js';
import {
  acceptWorkOffer,
  adminModerateWorkRequest,
  adminReviewProvider,
  createWorkRequest,
  deleteUserAccount,
  recordPaymentStatus,
  submitRequestRating,
  submitWorkOffer,
  transitionWorkRequestStatus,
  verifyHandoverAndComplete,
  withdrawWorkOffer,
} from '../lib/handlers.js';

function createSeededStore() {
  const store = new InMemoryStore();

  store.seed('provider_profiles', 'prov_approved_1', {
    id: 'prov_approved_1',
    userId: 'prov_approved_1',
    fullName: 'Khalid Supply',
    approvalStatus: 'approved',
    completedTasksCount: 2,
    ratingAvg: 4.5,
    ratingCount: 2,
  });

  store.seed('provider_profiles', 'prov_approved_2', {
    id: 'prov_approved_2',
    userId: 'prov_approved_2',
    fullName: 'Tariq Hardware Runner',
    approvalStatus: 'approved',
    completedTasksCount: 0,
    ratingAvg: 0,
    ratingCount: 0,
  });

  store.seed('provider_profiles', 'prov_pending', {
    id: 'prov_pending',
    userId: 'prov_pending',
    fullName: 'Pending Courier',
    approvalStatus: 'pending',
    completedTasksCount: 0,
    ratingAvg: 0,
    ratingCount: 0,
  });

  store.seed('provider_profiles', 'prov_rejected', {
    id: 'prov_rejected',
    userId: 'prov_rejected',
    fullName: 'Rejected Courier',
    approvalStatus: 'rejected',
    completedTasksCount: 0,
    ratingAvg: 0,
    ratingCount: 0,
  });

  store.seed('provider_verifications', 'prov_pending', {
    id: 'prov_pending',
    providerId: 'prov_pending',
    fullName: 'Pending Courier',
    qidNumber: '29663401842',
    status: 'underReview',
  });

  store.seed('admin_staff', 'admin_1', {
    id: 'admin_1',
    uid: 'admin_1',
    name: 'Nasser Ops',
    email: 'nasser@mashwar.qa',
    role: 'operations',
    isActive: true,
  });

  store.seed('admin_staff', 'admin_inactive', {
    id: 'admin_inactive',
    uid: 'admin_inactive',
    name: 'Disabled Staff',
    email: 'disabled@mashwar.qa',
    role: 'superAdmin',
    isActive: false,
  });

  return store;
}

function makeDeps(fixedIso = '2026-11-24T12:00:00.000Z') {
  let seq = 0;
  let currentMs = Date.parse(fixedIso);
  return {
    setNow(iso) {
      currentMs = Date.parse(iso);
    },
    advanceMs(ms) {
      currentMs += ms;
    },
    deps: {
      now: () => new Date(currentMs),
      idGenerator: () => `id_${++seq}`,
    },
  };
}

async function setupAcceptedRequest(store, clock, paymentMethod = 'cash_on_delivery') {
  const { requestId } = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: '20 bags Portland cement + PVC elbows',
      pickupLocation: 'Industrial Area Street 14',
      deliveryLocation: 'Lusail Marina Plot 4',
      deliveryArea: 'Lusail',
      budgetMinor: 45000,
      paymentMethod,
    },
    clock.deps,
  );

  const offer1 = await submitWorkOffer(
    store,
    { uid: 'prov_approved_1' },
    {
      requestId,
      totalAmountMinor: 44000,
      serviceFeeMinor: 6000,
      etaMinutes: 90,
      notes: 'Flatbed pickup ready',
    },
    clock.deps,
  );

  const offer2 = await submitWorkOffer(
    store,
    { uid: 'prov_approved_2' },
    {
      requestId,
      totalAmountMinor: 46000,
      serviceFeeMinor: 7000,
      etaMinutes: 120,
    },
    clock.deps,
  );

  const accepted = await acceptWorkOffer(
    store,
    { uid: 'req_1' },
    { requestId, offerId: offer1.offerId },
    clock.deps,
  );

  return { requestId, offer1, offer2, accepted };
}

test('handoverCrypto generates [A-HJ-NP-Z2-9]{6} codes and verifies constant-time salted hashes', () => {
  const pattern = /^[A-HJ-NP-Z2-9]{6}$/;
  for (let i = 0; i < 200; i += 1) {
    const code = generateHandoverCode();
    assert.match(code, pattern);
  }

  const salt1 = generateHandoverSalt();
  const salt2 = generateHandoverSalt();
  assert.notEqual(salt1, salt2);

  const hash1 = hashHandoverCode('ab34kp', salt1);
  const hash2 = hashHandoverCode('AB34KP', salt2);
  assert.notEqual(hash1, hash2);

  assert.equal(verifyHandoverCodeHash('  ab34kp ', salt1, hash1), true);
  assert.equal(verifyHandoverCodeHash('AB34KQ', salt1, hash1), false);
  assert.equal(verifyHandoverCodeHash('AB34KP', salt1, 'deadbeef'), false);
});

test('unauthenticated callers are denied across all callable handlers', async () => {
  const store = createSeededStore();
  const unauth = { uid: null };

  await assert.rejects(
    createWorkRequest(store, unauth, {
      title: 'Steel rebar',
      pickupLocation: 'Industrial Area',
      deliveryLocation: 'Al Wakrah',
      budgetMinor: 10000,
    }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    submitWorkOffer(store, unauth, {
      requestId: 'req_x',
      totalAmountMinor: 5000,
      serviceFeeMinor: 1000,
      etaMinutes: 45,
    }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    acceptWorkOffer(store, unauth, { requestId: 'req_x', offerId: 'off_x' }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    withdrawWorkOffer(store, unauth, { requestId: 'req_x', offerId: 'off_x' }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    transitionWorkRequestStatus(store, unauth, {
      requestId: 'req_x',
      targetStatus: 'cancelled',
    }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    verifyHandoverAndComplete(store, unauth, { requestId: 'req_x', code: 'ABC234' }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    submitRequestRating(store, unauth, { requestId: 'req_x', stars: 5 }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    recordPaymentStatus(store, unauth, {
      requestId: 'req_x',
      targetPaymentStatus: 'verified_settled',
    }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    adminReviewProvider(store, unauth, { providerId: 'prov_pending', decision: 'approved' }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    adminModerateWorkRequest(store, unauth, { requestId: 'req_x', action: 'cancel' }),
    { code: 'unauthenticated' },
  );
  await assert.rejects(
    deleteUserAccount(store, unauth, {}),
    { code: 'unauthenticated' },
  );
});

test('createWorkRequest validates positive integer budgetMinor, required fields, and initial state', async () => {
  const store = createSeededStore();
  const clock = makeDeps();

  await assert.rejects(
    createWorkRequest(store, { uid: 'req_1' }, {
      title: 'Pipes',
      pickupLocation: 'Industrial Area',
      deliveryLocation: 'Doha',
      budgetMinor: 0,
    }, clock.deps),
    { code: 'invalid-argument' },
  );

  await assert.rejects(
    createWorkRequest(store, { uid: 'req_1' }, {
      title: 'Pipes',
      pickupLocation: 'Industrial Area',
      deliveryLocation: 'Doha',
      budgetMinor: 150.25,
    }, clock.deps),
    { code: 'invalid-argument' },
  );

  await assert.rejects(
    createWorkRequest(store, { uid: 'req_1' }, {
      title: ' ',
      pickupLocation: 'Industrial Area',
      deliveryLocation: 'Doha',
      budgetMinor: 15000,
    }, clock.deps),
    { code: 'invalid-argument' },
  );

  const created = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: 'Electrical conduits 25mm',
      pickupLocation: 'Salwa Road Hardware Hub',
      deliveryLocation: 'West Bay Site B',
      budgetMinor: 25000,
    },
    clock.deps,
  );

  assert.equal(created.request.status, 'open');
  assert.equal(created.request.category, 'worksite_supply');
  assert.equal(created.request.paymentStatus, 'unpaid');
  assert.equal(created.request.deliveryArea, 'West Bay Site B');
  assert.equal(created.request.createdAt, '2026-11-24T12:00:00.000Z');

  const events = store.listCollection('request_events');
  assert.equal(events.length, 1);
  assert.equal(events[0].data.type, 'request_created');
  assert.equal(events[0].data.toStatus, 'open');
});

test('self-bidding and unapproved providers are rejected for offers and stage transitions', async () => {
  const store = createSeededStore();
  const clock = makeDeps();

  const { requestId } = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: '10 boxes M12 anchor bolts',
      pickupLocation: 'Industrial Area St 22',
      deliveryLocation: 'Al Khor Site 1',
      budgetMinor: 18000,
    },
    clock.deps,
  );

  // Even if requester also had an approved provider profile, self-bidding is forbidden.
  store.seed('provider_profiles', 'req_1', {
    id: 'req_1',
    userId: 'req_1',
    fullName: 'Requester Also Provider',
    approvalStatus: 'approved',
    completedTasksCount: 0,
    ratingAvg: 0,
    ratingCount: 0,
  });

  await assert.rejects(
    submitWorkOffer(store, { uid: 'req_1' }, {
      requestId,
      totalAmountMinor: 17000,
      serviceFeeMinor: 3000,
      etaMinutes: 60,
    }, clock.deps),
    { code: 'permission-denied' },
  );

  for (const badProvider of ['prov_pending', 'prov_rejected', 'prov_unknown']) {
    await assert.rejects(
      submitWorkOffer(store, { uid: badProvider }, {
        requestId,
        totalAmountMinor: 17000,
        serviceFeeMinor: 3000,
        etaMinutes: 60,
      }, clock.deps),
      { code: 'permission-denied' },
    );
  }

  // If an assigned provider is suspended/unapproved mid-flight, stage transition is blocked.
  const offerRes = await submitWorkOffer(
    store,
    { uid: 'prov_approved_1' },
    {
      requestId,
      totalAmountMinor: 17500,
      serviceFeeMinor: 3500,
      etaMinutes: 75,
    },
    clock.deps,
  );
  await acceptWorkOffer(
    store,
    { uid: 'req_1' },
    { requestId, offerId: offerRes.offerId },
    clock.deps,
  );

  await adminReviewProvider(
    store,
    { uid: 'admin_1' },
    { providerId: 'prov_approved_1', decision: 'suspended', reason: 'Expired vehicle permit' },
    clock.deps,
  );

  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'prov_approved_1' },
      { requestId, targetStatus: 'in_progress' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );
});

test('requester cannot accept/modify another users request or self-complete directly', async () => {
  const store = createSeededStore();
  const clock = makeDeps();
  const { requestId, offer1, offer2 } = await setupAcceptedRequest(store, clock);

  // Other offers were rejected atomically on acceptance.
  assert.equal(store.getDoc('work_offers', offer1.offerId).status, 'accepted');
  assert.equal(store.getDoc('work_offers', offer2.offerId).status, 'rejected');

  // Handover secret is hashed and requester handover view exists.
  const secret = store.getDoc('work_request_secrets', requestId);
  const view = store.getDoc('work_request_handover_view', requestId);
  assert.ok(secret);
  assert.ok(view);
  assert.equal(secret.attemptsRemaining, 5);
  assert.equal(secret.maxAttempts, 5);
  assert.equal(secret.usedAtUtc, null);
  assert.equal(view.requesterId, 'req_1');
  assert.match(view.handoverCode, /^[A-HJ-NP-Z2-9]{6}$/);
  assert.equal(verifyHandoverCodeHash(view.handoverCode, secret.codeSalt, secret.codeHash), true);

  // Another user cannot mutate req_1's request.
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'other_user' },
      { requestId, targetStatus: 'cancelled' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  // Unrelated approved provider cannot advance req_1's request.
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'prov_approved_2' },
      { requestId, targetStatus: 'in_progress' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  // Advance cleanly to delivered_pending_confirmation.
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'in_progress' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    {
      requestId,
      targetStatus: 'picked_up',
      invoiceImageUrls: ['https://storage.example.com/work_requests/inv1.jpg'],
    },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'in_transit' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'delivered_pending_confirmation' },
    clock.deps,
  );

  // Requester, provider, AND admin are forbidden from setting 'completed' directly via transitionWorkRequestStatus.
  for (const actorUid of ['req_1', 'prov_approved_1', 'admin_1']) {
    await assert.rejects(
      transitionWorkRequestStatus(
        store,
        { uid: actorUid },
        { requestId, targetStatus: 'completed' },
        clock.deps,
      ),
      (err) => err.code === 'permission-denied' || err.code === 'failed-precondition',
    );
  }
});

test('invalid state transitions and late requester cancellations are rejected', async () => {
  const store = createSeededStore();
  const clock = makeDeps();
  const { requestId } = await setupAcceptedRequest(store, clock);

  // Cannot skip in_progress straight to picked_up.
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'prov_approved_1' },
      { requestId, targetStatus: 'picked_up' },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  // Cannot attach invoiceImageUrls on in_progress.
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'prov_approved_1' },
      {
        requestId,
        targetStatus: 'in_progress',
        invoiceImageUrls: ['https://storage.example.com/early.jpg'],
      },
      clock.deps,
    ),
    { code: 'invalid-argument' },
  );

  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'in_progress' },
    clock.deps,
  );

  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'picked_up' },
    clock.deps,
  );

  // Requester CANNOT cancel once status has reached picked_up.
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'req_1' },
      { requestId, targetStatus: 'cancelled', reason: 'Changed mind late' },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  // Cannot open dispute on an open (unassigned) request.
  const openReq = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: 'Sandbags',
      pickupLocation: 'Depot 1',
      deliveryLocation: 'Site 2',
      budgetMinor: 5000,
    },
    clock.deps,
  );
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'req_1' },
      { requestId: openReq.requestId, targetStatus: 'disputed' },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  // Requester CAN cancel while still open.
  const cancelRes = await transitionWorkRequestStatus(
    store,
    { uid: 'req_1' },
    { requestId: openReq.requestId, targetStatus: 'cancelled', reason: 'No longer needed' },
    clock.deps,
  );
  assert.equal(cancelRes.toStatus, 'cancelled');
});

test('handover verification rejects invalid, exhausted-attempts, expired, and reused codes', async () => {
  const store = createSeededStore();
  const clock = makeDeps('2026-11-24T12:00:00.000Z');
  const { requestId, accepted } = await setupAcceptedRequest(store, clock);

  // Reject handover before delivered_pending_confirmation.
  await assert.rejects(
    verifyHandoverAndComplete(
      store,
      { uid: 'prov_approved_1' },
      { requestId, code: accepted.handoverCode },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'in_progress' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'picked_up' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'in_transit' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'delivered_pending_confirmation' },
    clock.deps,
  );

  // Non-assigned user rejected.
  await assert.rejects(
    verifyHandoverAndComplete(
      store,
      { uid: 'req_1' },
      { requestId, code: accepted.handoverCode },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  // Wrong code decrements attemptsRemaining persistently and throws failed-precondition.
  await assert.rejects(
    verifyHandoverAndComplete(
      store,
      { uid: 'prov_approved_1' },
      { requestId, code: 'WRONG1' },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );
  assert.equal(store.getDoc('work_request_secrets', requestId).attemptsRemaining, 4);

  // Valid code (even lowercase with spaces) completes and increments completedTasksCount.
  const completed = await verifyHandoverAndComplete(
    store,
    { uid: 'prov_approved_1' },
    { requestId, code: ` ${accepted.handoverCode.toLowerCase()} ` },
    clock.deps,
  );
  assert.equal(completed.status, 'completed');
  assert.equal(store.getDoc('work_requests', requestId).status, 'completed');
  assert.ok(store.getDoc('work_request_secrets', requestId).usedAtUtc);
  assert.equal(store.getDoc('provider_profiles', 'prov_approved_1').completedTasksCount, 3);

  // Reused code rejected.
  await assert.rejects(
    verifyHandoverAndComplete(
      store,
      { uid: 'prov_approved_1' },
      { requestId, code: accepted.handoverCode },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  // Test exhausted attempts (5 wrong tries -> 0 remaining -> even correct code fails).
  const clock2 = makeDeps('2026-11-24T12:00:00.000Z');
  const flow2 = await setupAcceptedRequest(store, clock2);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow2.requestId, targetStatus: 'in_progress' }, clock2.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow2.requestId, targetStatus: 'picked_up' }, clock2.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow2.requestId, targetStatus: 'in_transit' }, clock2.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow2.requestId, targetStatus: 'delivered_pending_confirmation' }, clock2.deps);

  for (let attempt = 0; attempt < 5; attempt += 1) {
    await assert.rejects(
      verifyHandoverAndComplete(
        store,
        { uid: 'prov_approved_1' },
        { requestId: flow2.requestId, code: 'BAD999' },
        clock2.deps,
      ),
      { code: 'failed-precondition' },
    );
  }
  assert.equal(store.getDoc('work_request_secrets', flow2.requestId).attemptsRemaining, 0);

  await assert.rejects(
    verifyHandoverAndComplete(
      store,
      { uid: 'prov_approved_1' },
      { requestId: flow2.requestId, code: flow2.accepted.handoverCode },
      clock2.deps,
    ),
    { code: 'failed-precondition' },
  );

  // Test expired code (> +24h).
  const clock3 = makeDeps('2026-11-24T12:00:00.000Z');
  const flow3 = await setupAcceptedRequest(store, clock3);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow3.requestId, targetStatus: 'in_progress' }, clock3.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow3.requestId, targetStatus: 'picked_up' }, clock3.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow3.requestId, targetStatus: 'in_transit' }, clock3.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId: flow3.requestId, targetStatus: 'delivered_pending_confirmation' }, clock3.deps);

  clock3.advanceMs(24 * 60 * 60 * 1000 + 1000);
  await assert.rejects(
    verifyHandoverAndComplete(
      store,
      { uid: 'prov_approved_1' },
      { requestId: flow3.requestId, code: flow3.accepted.handoverCode },
      clock3.deps,
    ),
    { code: 'failed-precondition' },
  );
});

test('payment status cannot be forged or overwritten once verified_settled', async () => {
  const store = createSeededStore();
  const clock = makeDeps();

  // Cannot forge verified_settled on creation.
  await assert.rejects(
    createWorkRequest(
      store,
      { uid: 'req_1' },
      {
        title: 'Water pump',
        pickupLocation: 'Salwa Road',
        deliveryLocation: 'Al Rayyan',
        budgetMinor: 30000,
        paymentMethod: 'bank_transfer_manual',
        paymentStatus: 'verified_settled',
      },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  const { requestId, accepted } = await setupAcceptedRequest(
    store,
    clock,
    'bank_transfer_manual',
  );

  // Cannot inject paymentStatus via transitionWorkRequestStatus.
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'prov_approved_1' },
      {
        requestId,
        targetStatus: 'in_progress',
        paymentStatus: 'verified_settled',
      },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  // Requester and provider cannot self-mark verified_settled.
  await assert.rejects(
    recordPaymentStatus(
      store,
      { uid: 'req_1' },
      { requestId, targetPaymentStatus: 'verified_settled' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    recordPaymentStatus(
      store,
      { uid: 'prov_approved_1' },
      { requestId, targetPaymentStatus: 'verified_settled' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  // Requester submits bank transfer proof legitimately.
  const proofRes = await recordPaymentStatus(
    store,
    { uid: 'req_1' },
    {
      requestId,
      targetPaymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.example.com/work_requests/proof.jpg',
    },
    clock.deps,
  );
  assert.equal(proofRes.paymentStatus, 'transfer_proof_submitted');

  // Active admin settles payment.
  const settled = await adminModerateWorkRequest(
    store,
    { uid: 'admin_1' },
    { requestId, action: 'verify_payment_settled' },
    clock.deps,
  );
  assert.equal(settled.paymentStatus, 'verified_settled');

  // Once verified_settled, ANY overwrite attempt fails for requester, provider, AND admin.
  for (const actorUid of ['req_1', 'prov_approved_1', 'admin_1']) {
    await assert.rejects(
      recordPaymentStatus(
        store,
        { uid: actorUid },
        { requestId, targetPaymentStatus: 'disputed' },
        clock.deps,
      ),
      { code: 'failed-precondition' },
    );
    await assert.rejects(
      recordPaymentStatus(
        store,
        { uid: actorUid },
        { requestId, targetPaymentStatus: 'unpaid' },
        clock.deps,
      ),
      { code: 'failed-precondition' },
    );
  }

  await assert.rejects(
    adminModerateWorkRequest(
      store,
      { uid: 'admin_1' },
      { requestId, action: 'verify_payment_settled' },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  assert.ok(accepted.handoverCode);
});

test('ratings require completed request, enforce one rating per participant pair, and compute running average', async () => {
  const store = createSeededStore();
  const clock = makeDeps();
  const { requestId, accepted } = await setupAcceptedRequest(store, clock);

  await assert.rejects(
    submitRequestRating(
      store,
      { uid: 'req_1' },
      { requestId, stars: 5 },
      clock.deps,
    ),
    { code: 'failed-precondition' },
  );

  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId, targetStatus: 'in_progress' }, clock.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId, targetStatus: 'picked_up' }, clock.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId, targetStatus: 'in_transit' }, clock.deps);
  await transitionWorkRequestStatus(store, { uid: 'prov_approved_1' }, { requestId, targetStatus: 'delivered_pending_confirmation' }, clock.deps);
  await verifyHandoverAndComplete(store, { uid: 'prov_approved_1' }, { requestId, code: accepted.handoverCode }, clock.deps);

  // Non-participant rejected.
  await assert.rejects(
    submitRequestRating(store, { uid: 'outsider' }, { requestId, stars: 5 }, clock.deps),
    { code: 'permission-denied' },
  );

  // Invalid stars rejected.
  await assert.rejects(
    submitRequestRating(store, { uid: 'req_1' }, { requestId, stars: 6 }, clock.deps),
    { code: 'invalid-argument' },
  );

  // Prov_approved_1 starts with ratingAvg 4.5, ratingCount 2 -> adding 3 gives (9 + 3)/3 = 4.0.
  const ratedProv = await submitRequestRating(
    store,
    { uid: 'req_1' },
    { requestId, stars: 3, comment: 'Good delivery' },
    clock.deps,
  );
  assert.equal(ratedProv.ratingAvg, 4);
  assert.equal(ratedProv.ratingCount, 3);

  // Duplicate rating from same participant rejected.
  await assert.rejects(
    submitRequestRating(store, { uid: 'req_1' }, { requestId, stars: 5 }, clock.deps),
    { code: 'already-exists' },
  );

  // Provider can rate requester once as well.
  const ratedReq = await submitRequestRating(
    store,
    { uid: 'prov_approved_1' },
    { requestId, stars: 5 },
    clock.deps,
  );
  assert.equal(ratedReq.ratingAvg, 5);
  assert.equal(ratedReq.ratingCount, 1);
});

test('adminReviewProvider and adminModerateWorkRequest require active admin_staff and append audit logs', async () => {
  const store = createSeededStore();
  const clock = makeDeps();

  // Inactive or non-admin blocked.
  await assert.rejects(
    adminReviewProvider(
      store,
      { uid: 'admin_inactive' },
      { providerId: 'prov_pending', decision: 'approved' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    adminReviewProvider(
      store,
      { uid: 'req_1' },
      { providerId: 'prov_pending', decision: 'approved' },
      clock.deps,
    ),
    { code: 'permission-denied' },
  );

  // Active admin approves pending provider.
  const reviewRes = await adminReviewProvider(
    store,
    { uid: 'admin_1' },
    { providerId: 'prov_pending', decision: 'approved' },
    clock.deps,
  );
  assert.equal(reviewRes.approvalStatus, 'approved');
  assert.equal(store.getDoc('provider_profiles', 'prov_pending').approvalStatus, 'approved');
  assert.equal(store.getDoc('provider_verifications', 'prov_pending').status, 'approved');

  // Dispute and admin moderation flow.
  const { requestId } = await setupAcceptedRequest(store, clock);
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId, targetStatus: 'in_progress' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'req_1' },
    { requestId, targetStatus: 'disputed', reason: 'Wrong rebar gauge delivered' },
    clock.deps,
  );

  const modRes = await adminModerateWorkRequest(
    store,
    { uid: 'admin_1' },
    {
      requestId,
      action: 'resolve_dispute',
      targetStatus: 'cancelled',
      reason: 'Confirmed wrong spec; request cancelled by ops',
    },
    clock.deps,
  );
  assert.equal(modRes.status, 'cancelled');

  const logs = store.listCollection('admin_audit_logs');
  assert.equal(logs.length, 2);
  assert.equal(logs[0].data.adminUid, 'admin_1');
  assert.equal(logs[1].data.action, 'moderate_resolve_dispute');
});

test('deleteUserAccount blocks active work_requests across all active statuses, and deletes profiles + audit log + Firebase Auth user when clear', async () => {
  const store = createSeededStore();
  const clock = makeDeps();
  const deletedAuthUids = [];

  store.seed('users', 'req_1', {
    id: 'req_1',
    fullName: 'Eng. Fahad',
    phone: '55112233',
    email: 'fahad@site.qa',
  });
  store.seed('provider_profiles', 'req_1', {
    id: 'req_1',
    userId: 'req_1',
    fullName: 'Eng. Fahad',
    approvalStatus: 'pending',
    completedTasksCount: 0,
    ratingAvg: 0,
    ratingCount: 0,
  });
  store.seed('provider_verifications', 'req_1', {
    id: 'req_1',
    providerId: 'req_1',
    fullName: 'Eng. Fahad',
    qidNumber: '29163401122',
    status: 'pending',
  });
  store.seed('business_profiles', 'req_1', {
    id: 'req_1',
    userId: 'req_1',
    companyName: 'Lusail Contracting WLL',
    ratingAvg: 5,
    ratingCount: 1,
  });

  const depsWithAuth = {
    ...clock.deps,
    deleteAuthUser: async (uid) => {
      deletedAuthUids.push(uid);
    },
  };

  // Setup accepted request: both req_1 (requester) and prov_approved_1 (assigned provider) must be blocked!
  const { requestId, accepted } = await setupAcceptedRequest(store, clock);

  for (const activeStatus of [
    'accepted',
    'in_progress',
    'picked_up',
    'in_transit',
    'delivered_pending_confirmation',
    'disputed',
  ]) {
    if (activeStatus !== 'accepted') {
      await transitionWorkRequestStatus(
        store,
        { uid: activeStatus === 'disputed' ? 'req_1' : 'prov_approved_1' },
        {
          requestId,
          targetStatus: activeStatus,
          ...(activeStatus === 'disputed' ? { reason: 'Temporary check' } : {}),
        },
        clock.deps,
      );
    }

    await assert.rejects(
      deleteUserAccount(store, { uid: 'req_1' }, { reason: 'Leaving platform' }, depsWithAuth),
      { code: 'failed-precondition' },
    );
    await assert.rejects(
      deleteUserAccount(store, { uid: 'prov_approved_1' }, {}, depsWithAuth),
      { code: 'failed-precondition' },
    );

    // Ensure profile docs and auth account were NOT deleted when blocked
    assert.ok(store.getDoc('users', 'req_1'));
    assert.equal(deletedAuthUids.length, 0);
  }

  // Resolve dispute -> delivered_pending_confirmation -> verify handover -> completed
  await adminModerateWorkRequest(
    store,
    { uid: 'admin_1' },
    {
      requestId,
      action: 'resolve_dispute',
      targetStatus: 'delivered_pending_confirmation',
      reason: 'Resolved on-site',
    },
    clock.deps,
  );
  await verifyHandoverAndComplete(
    store,
    { uid: 'prov_approved_1' },
    { requestId, code: accepted.handoverCode },
    clock.deps,
  );

  // Also create an unassigned 'open' request owned by req_1 (should be auto-cancelled, not block)
  const openRes = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: 'Unused open draft supply',
      pickupLocation: 'Industrial Area',
      deliveryLocation: 'Lusail',
      budgetMinor: 9000,
    },
    clock.deps,
  );

  // Now req_1 has only completed + open requests -> deleteUserAccount succeeds cleanly!
  const deleted = await deleteUserAccount(
    store,
    { uid: 'req_1' },
    { reason: 'Project completed' },
    depsWithAuth,
  );

  assert.equal(deleted.uid, 'req_1');
  assert.equal(deleted.authUserDeleted, true);
  assert.deepEqual(deletedAuthUids, ['req_1']);
  assert.deepEqual(deleted.cancelledOpenRequestIds, [openRes.requestId]);

  // Verify Firestore PII profile docs are purged
  assert.equal(store.getDoc('users', 'req_1'), null);
  assert.equal(store.getDoc('provider_profiles', 'req_1'), null);
  assert.equal(store.getDoc('provider_verifications', 'req_1'), null);
  assert.equal(store.getDoc('business_profiles', 'req_1'), null);

  // Open request was cancelled while completed historical audit record remains intact
  assert.equal(store.getDoc('work_requests', openRes.requestId).status, 'cancelled');
  assert.equal(store.getDoc('work_requests', requestId).status, 'completed');

  // Immutable admin_audit_logs entry recorded
  const auditDoc = store.getDoc('admin_audit_logs', deleted.auditLogId);
  assert.ok(auditDoc);
  assert.equal(auditDoc.action, 'delete_user_account');
  assert.equal(auditDoc.targetEntityId, 'req_1');
});

test('createWorkRequest, transitionWorkRequestStatus, recordPaymentStatus, submitRequestRating persist extended worksite fields and validate inputs', async () => {
  const store = createSeededStore();
  const clock = makeDeps('2026-11-28T10:00:00.000Z');

  // Seed a financeAdmin staff record to verify expanded AdminRole alignment.
  store.seed('admin_staff', 'admin_finance', {
    id: 'admin_finance',
    uid: 'admin_finance',
    name: 'Salma Finance',
    email: 'finance@mashwar.qa',
    role: 'financeAdmin',
    isActive: true,
  });

  // Invalid scheduledBy or negative minor fields are rejected.
  await assert.rejects(
    createWorkRequest(
      store,
      { uid: 'req_1' },
      {
        title: 'Cable trays',
        pickupLocation: 'Industrial Area St 10',
        deliveryLocation: 'Lusail Marina',
        budgetMinor: 50000,
        scheduledBy: 'not-a-date',
      },
      clock.deps,
    ),
    { code: 'invalid-argument' },
  );
  await assert.rejects(
    createWorkRequest(
      store,
      { uid: 'req_1' },
      {
        title: 'Cable trays',
        pickupLocation: 'Industrial Area St 10',
        deliveryLocation: 'Lusail Marina',
        budgetMinor: 50000,
        estimatedItemsCostMinor: -100,
      },
      clock.deps,
    ),
    { code: 'invalid-argument' },
  );

  const created = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: 'Heavy-duty electrical cables + breaker panel',
      description: '3x 100m copper rolls + ABB 3-phase breaker',
      supplyCategory: 'electrical_materials',
      pickupLocation: 'Industrial Area St 10 Electrical Hub',
      deliveryLocation: 'Lusail Tower Plot 9',
      deliveryArea: 'Lusail',
      siteContactName: 'Eng. Omar Al-Sulaiti',
      siteContactPhone: '+97455123456',
      itemNotes: 'Request stamped tax invoice from supplier',
      budgetMinor: 95000,
      estimatedItemsCostMinor: 80000,
      maxItemsCapMinor: 85000,
      deliveryFeeBudgetMinor: 10000,
      scheduledBy: '2026-11-28T16:30:00Z',
      paymentMethod: 'bank_transfer_manual',
      referenceImageUrls: ['https://storage.example.com/work_requests/ref_cable.jpg'],
    },
    clock.deps,
  );

  const savedReq = store.getDoc('work_requests', created.requestId);
  assert.equal(savedReq.supplyCategory, 'electrical_materials');
  assert.equal(savedReq.siteContactName, 'Eng. Omar Al-Sulaiti');
  assert.equal(savedReq.siteContactPhone, '+97455123456');
  assert.equal(savedReq.itemNotes, 'Request stamped tax invoice from supplier');
  assert.equal(savedReq.estimatedItemsCostMinor, 80000);
  assert.equal(savedReq.maxItemsCapMinor, 85000);
  assert.equal(savedReq.deliveryFeeBudgetMinor, 10000);
  assert.equal(savedReq.scheduledBy, '2026-11-28T16:30:00.000Z');
  assert.deepEqual(savedReq.referenceImageUrls, ['https://storage.example.com/work_requests/ref_cable.jpg']);

  // Submit & accept offer
  const offer = await submitWorkOffer(
    store,
    { uid: 'prov_approved_1' },
    {
      requestId: created.requestId,
      totalAmountMinor: 92000,
      serviceFeeMinor: 9500,
      etaMinutes: 60,
    },
    clock.deps,
  );
  const accepted = await acceptWorkOffer(
    store,
    { uid: 'req_1' },
    { requestId: created.requestId, offerId: offer.offerId },
    clock.deps,
  );

  // actualReceiptTotalMinor rejected on in_progress
  await assert.rejects(
    transitionWorkRequestStatus(
      store,
      { uid: 'prov_approved_1' },
      {
        requestId: created.requestId,
        targetStatus: 'in_progress',
        actualReceiptTotalMinor: 81500,
      },
      clock.deps,
    ),
    { code: 'invalid-argument' },
  );

  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId: created.requestId, targetStatus: 'in_progress' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    {
      requestId: created.requestId,
      targetStatus: 'picked_up',
      invoiceImageUrls: ['https://storage.example.com/work_requests/receipt_1.jpg'],
      actualReceiptTotalMinor: 81500,
    },
    clock.deps,
  );
  assert.equal(store.getDoc('work_requests', created.requestId).actualReceiptTotalMinor, 81500);

  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId: created.requestId, targetStatus: 'in_transit' },
    clock.deps,
  );
  await transitionWorkRequestStatus(
    store,
    { uid: 'prov_approved_1' },
    { requestId: created.requestId, targetStatus: 'delivered_pending_confirmation' },
    clock.deps,
  );

  // Record bank transfer proof with referenceNumber -> persisted as paymentReference
  await recordPaymentStatus(
    store,
    { uid: 'req_1' },
    {
      requestId: created.requestId,
      targetPaymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.example.com/work_requests/bank_slip.jpg',
      referenceNumber: 'QNB-2026-998877',
    },
    clock.deps,
  );
  assert.equal(store.getDoc('work_requests', created.requestId).paymentReference, 'QNB-2026-998877');

  // financeAdmin can settle payment
  const settled = await recordPaymentStatus(
    store,
    { uid: 'admin_finance' },
    {
      requestId: created.requestId,
      targetPaymentStatus: 'verified_settled',
    },
    clock.deps,
  );
  assert.equal(settled.paymentStatus, 'verified_settled');

  // Complete handover and submit rating with tags
  await verifyHandoverAndComplete(
    store,
    { uid: 'prov_approved_1' },
    { requestId: created.requestId, code: accepted.handoverCode },
    clock.deps,
  );

  await assert.rejects(
    submitRequestRating(
      store,
      { uid: 'req_1' },
      { requestId: created.requestId, stars: 5, tags: 'not-an-array' },
      clock.deps,
    ),
    { code: 'invalid-argument' },
  );

  const ratingRes = await submitRequestRating(
    store,
    { uid: 'req_1' },
    {
      requestId: created.requestId,
      stars: 5,
      comment: 'Fast delivery and clear invoice',
      tags: ['on_time', 'clear_receipt', 'on_time'],
    },
    clock.deps,
  );
  assert.deepEqual(store.getDoc('ratings', ratingRes.ratingId).tags, ['on_time', 'clear_receipt']);

  // adminReviewProvider maps 'suspended' -> 'rejected' on provider_verifications
  await adminReviewProvider(
    store,
    { uid: 'admin_1' },
    { providerId: 'prov_pending', decision: 'suspended', reason: 'Document mismatch' },
    clock.deps,
  );
  assert.equal(store.getDoc('provider_profiles', 'prov_pending').approvalStatus, 'suspended');
  assert.equal(store.getDoc('provider_verifications', 'prov_pending').status, 'rejected');
});

test('withdrawWorkOffer atomically marks offer withdrawn, decrements offerCount, and reverts status to open when 0 pending offers remain', async () => {
  const store = createSeededStore();
  const clock = makeDeps('2026-11-28T11:00:00.000Z');

  const { requestId } = await createWorkRequest(
    store,
    { uid: 'req_1' },
    {
      title: '15 boxes ceramic tile adhesive',
      pickupLocation: 'Salwa Road Depot',
      deliveryLocation: 'Al Wakrah Plot 12',
      budgetMinor: 35000,
    },
    clock.deps,
  );

  const off1 = await submitWorkOffer(
    store,
    { uid: 'prov_approved_1' },
    { requestId, totalAmountMinor: 34000, serviceFeeMinor: 5000, etaMinutes: 50 },
    clock.deps,
  );
  const off2 = await submitWorkOffer(
    store,
    { uid: 'prov_approved_2' },
    { requestId, totalAmountMinor: 33000, serviceFeeMinor: 4500, etaMinutes: 70 },
    clock.deps,
  );

  assert.equal(store.getDoc('work_requests', requestId).status, 'offer_received');
  assert.equal(store.getDoc('work_requests', requestId).offerCount, 2);

  // Another user/provider cannot withdraw prov_approved_1's offer
  await assert.rejects(
    withdrawWorkOffer(store, { uid: 'prov_approved_2' }, { requestId, offerId: off1.offerId }, clock.deps),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    withdrawWorkOffer(store, { uid: 'req_1' }, { requestId, offerId: off1.offerId }, clock.deps),
    { code: 'permission-denied' },
  );

  // First withdrawal: 1 pending offer remains -> stays offer_received, offerCount becomes 1
  const res1 = await withdrawWorkOffer(
    store,
    { uid: 'prov_approved_1' },
    { requestId, offerId: off1.offerId },
    clock.deps,
  );
  assert.equal(res1.offerStatus, 'withdrawn');
  assert.equal(res1.requestStatus, 'offer_received');
  assert.equal(res1.offerCount, 1);
  assert.equal(store.getDoc('work_offers', off1.offerId).status, 'withdrawn');
  assert.equal(store.getDoc('work_requests', requestId).status, 'offer_received');
  assert.equal(store.getDoc('work_requests', requestId).offerCount, 1);

  // Double-withdraw rejected
  await assert.rejects(
    withdrawWorkOffer(store, { uid: 'prov_approved_1' }, { requestId, offerId: off1.offerId }, clock.deps),
    { code: 'failed-precondition' },
  );

  // Second withdrawal: 0 pending offers remain -> reverts to open, offerCount becomes 0
  const res2 = await withdrawWorkOffer(
    store,
    { uid: 'prov_approved_2' },
    { requestId, offerId: off2.offerId },
    clock.deps,
  );
  assert.equal(res2.offerStatus, 'withdrawn');
  assert.equal(res2.requestStatus, 'open');
  assert.equal(res2.offerCount, 0);
  assert.equal(store.getDoc('work_offers', off2.offerId).status, 'withdrawn');
  assert.equal(store.getDoc('work_requests', requestId).status, 'open');
  assert.equal(store.getDoc('work_requests', requestId).offerCount, 0);
});
