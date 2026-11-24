import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..', '..');

const PROJECT_ID = 'demo-mashwar-qatar';
const FIXED_DATE = new Date('2026-11-24T12:00:00.000Z');

const firestoreRules = fs.readFileSync(path.join(REPO_ROOT, 'firestore.rules'), 'utf8');
const storageRules = fs.readFileSync(path.join(REPO_ROOT, 'storage.rules'), 'utf8');

function makeBusinessProfile(uid, overrides = {}) {
  return {
    id: uid,
    userId: uid,
    companyName: 'Al Maha Contracting WLL',
    contactName: 'Faisal Al-Thani',
    phone: '+97455123456',
    defaultWorksiteArea: 'Lusail',
    ratingAvg: 0,
    ratingCount: 0,
    createdAt: FIXED_DATE,
    updatedAt: FIXED_DATE,
    ...overrides,
  };
}

function makeProviderProfile(uid, overrides = {}) {
  return {
    id: uid,
    userId: uid,
    fullName: 'Khalid Supply Runner',
    phone: '+97455234567',
    vehicleType: 'Pickup Truck',
    vehiclePlate: 'QAT-48291',
    serviceAreas: ['Lusail', 'Industrial Area'],
    approvalStatus: 'pending',
    completedTasksCount: 0,
    ratingAvg: 0,
    ratingCount: 0,
    createdAt: FIXED_DATE,
    updatedAt: FIXED_DATE,
    ...overrides,
  };
}

function makeProviderVerification(uid, overrides = {}) {
  return {
    id: uid,
    providerId: uid,
    fullName: 'Khalid Supply Runner',
    qidNumber: '29663401842',
    qidFrontUrl: `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/qid_front.jpg`,
    qidBackUrl: `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/qid_back.jpg`,
    selfieUrl: `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/selfie.jpg`,
    status: 'pending',
    createdAt: FIXED_DATE,
    updatedAt: FIXED_DATE,
    ...overrides,
  };
}

function makeWorkRequest(id, requesterId, overrides = {}) {
  return {
    id,
    requesterId,
    category: 'worksite_supply',
    title: '25 bags Portland cement + rebar ties',
    description: 'Deliver to Lusail Marina Plot 4 Gate B',
    pickupLocation: 'Industrial Area Street 14 Hardware Depot',
    deliveryLocation: 'Lusail Marina Plot 4',
    deliveryArea: 'Lusail',
    budgetMinor: 45000,
    paymentMethod: 'cash_on_delivery',
    paymentStatus: 'unpaid',
    status: 'open',
    offerCount: 0,
    selectedOfferId: null,
    assignedProviderId: null,
    createdAt: FIXED_DATE,
    updatedAt: FIXED_DATE,
    ...overrides,
  };
}

function makeWorkOffer(id, requestId, providerId, overrides = {}) {
  return {
    id,
    requestId,
    providerId,
    providerName: 'Khalid Supply Runner',
    totalAmountMinor: 44000,
    serviceFeeMinor: 5000,
    etaMinutes: 90,
    notes: 'Flatbed pickup ready immediately',
    status: 'pending',
    createdAt: FIXED_DATE,
    updatedAt: FIXED_DATE,
    ...overrides,
  };
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: firestoreRules },
    storage: { rules: storageRules },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

describe('Live Firestore & Storage Security Rules (MASHWAR Worksite Supply MVP)', () => {
  test('denies unauthenticated read and write across work_requests, work_offers, provider_profiles, provider_verifications, and business_profiles', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('business_profiles').doc('biz_1').set(makeBusinessProfile('biz_1'));
      await db
        .collection('provider_profiles')
        .doc('prov_1')
        .set(makeProviderProfile('prov_1', { approvalStatus: 'approved' }));
      await db
        .collection('provider_verifications')
        .doc('prov_1')
        .set(makeProviderVerification('prov_1'));
      await db
        .collection('work_requests')
        .doc('req_1')
        .set(makeWorkRequest('req_1', 'biz_1'));
      await db
        .collection('work_offers')
        .doc('offer_1')
        .set(makeWorkOffer('offer_1', 'req_1', 'prov_1'));
    });

    const unauthDb = testEnv.unauthenticatedContext().firestore();

    await assertFails(unauthDb.collection('work_requests').doc('req_1').get());
    await assertFails(
      unauthDb.collection('work_requests').doc('req_unauth').set(makeWorkRequest('req_unauth', 'anon')),
    );

    await assertFails(unauthDb.collection('work_offers').doc('offer_1').get());
    await assertFails(
      unauthDb
        .collection('work_offers')
        .doc('offer_unauth')
        .set(makeWorkOffer('offer_unauth', 'req_1', 'prov_1')),
    );

    await assertFails(unauthDb.collection('provider_profiles').doc('prov_1').get());
    await assertFails(
      unauthDb.collection('provider_profiles').doc('prov_unauth').set(makeProviderProfile('prov_unauth')),
    );

    await assertFails(unauthDb.collection('provider_verifications').doc('prov_1').get());
    await assertFails(
      unauthDb
        .collection('provider_verifications')
        .doc('prov_unauth')
        .set(makeProviderVerification('prov_unauth')),
    );

    await assertFails(unauthDb.collection('business_profiles').doc('biz_1').get());
    await assertFails(
      unauthDb.collection('business_profiles').doc('biz_unauth').set(makeBusinessProfile('biz_unauth')),
    );
  });

  test('denies work_request_secrets read and write to ALL clients including requester, assigned provider, and admin claims', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('work_requests').doc('req_sec').set(
        makeWorkRequest('req_sec', 'req_owner', {
          status: 'accepted',
          selectedOfferId: 'off_1',
          assignedProviderId: 'prov_assigned',
          offerCount: 1,
        }),
      );
      await db.collection('work_request_secrets').doc('req_sec').set({
        requestId: 'req_sec',
        codeHash: '9f86d081884c7d659a2feaa0c55ad015',
        codeSalt: 'random_salt_hex',
        attemptsRemaining: 5,
        maxAttempts: 5,
      });
    });

    const contexts = [
      testEnv.unauthenticatedContext(),
      testEnv.authenticatedContext('req_owner'),
      testEnv.authenticatedContext('prov_assigned'),
      testEnv.authenticatedContext('admin_1', { admin: true, role: 'superAdmin' }),
    ];

    for (const ctx of contexts) {
      const db = ctx.firestore();
      await assertFails(db.collection('work_request_secrets').doc('req_sec').get());
      await assertFails(
        db.collection('work_request_secrets').doc('req_sec').set({
          requestId: 'req_sec',
          codeHash: 'forged',
        }),
      );
      await assertFails(db.collection('work_request_secrets').doc('req_sec').delete());
    }
  });

  test('allows work_request_handover_view read ONLY for requesterId and denies reads to provider/stranger and writes to all clients', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('work_requests').doc('req_ho').set(
        makeWorkRequest('req_ho', 'req_owner', {
          status: 'accepted',
          selectedOfferId: 'off_1',
          assignedProviderId: 'prov_assigned',
          offerCount: 1,
        }),
      );
      await db.collection('work_request_handover_view').doc('req_ho').set({
        requestId: 'req_ho',
        requesterId: 'req_owner',
        handoverCode: 'KP34M9',
      });
    });

    const requesterDb = testEnv.authenticatedContext('req_owner').firestore();
    const providerDb = testEnv.authenticatedContext('prov_assigned').firestore();
    const strangerDb = testEnv.authenticatedContext('stranger_1').firestore();
    const adminDb = testEnv.authenticatedContext('admin_1', { admin: true }).firestore();

    const snap = await assertSucceeds(
      requesterDb.collection('work_request_handover_view').doc('req_ho').get(),
    );
    assert.equal(snap.data().handoverCode, 'KP34M9');

    await assertFails(providerDb.collection('work_request_handover_view').doc('req_ho').get());
    await assertFails(strangerDb.collection('work_request_handover_view').doc('req_ho').get());

    for (const db of [requesterDb, providerDb, strangerDb, adminDb]) {
      await assertFails(
        db.collection('work_request_handover_view').doc('req_ho').set({
          requestId: 'req_ho',
          requesterId: 'req_owner',
          handoverCode: 'FORGED',
        }),
      );
      await assertFails(
        db.collection('work_request_handover_view').doc('req_ho').update({ handoverCode: 'FORGED' }),
      );
      await assertFails(db.collection('work_request_handover_view').doc('req_ho').delete());
    }
  });

  test('enforces provider_profiles owner create with pending status & zero stats and blocks self-approval updates', async () => {
    const ownerDb = testEnv.authenticatedContext('prov_new').firestore();
    const adminDb = testEnv.authenticatedContext('admin_1', { admin: true, role: 'admin' }).firestore();

    // Cannot create pre-approved or with non-zero stats
    await assertFails(
      ownerDb
        .collection('provider_profiles')
        .doc('prov_new')
        .set(makeProviderProfile('prov_new', { approvalStatus: 'approved' })),
    );
    await assertFails(
      ownerDb
        .collection('provider_profiles')
        .doc('prov_new')
        .set(makeProviderProfile('prov_new', { completedTasksCount: 3 })),
    );
    await assertFails(
      ownerDb
        .collection('provider_profiles')
        .doc('prov_new')
        .set(makeProviderProfile('prov_new', { ratingAvg: 4.9, ratingCount: 5 })),
    );

    // Valid pending profile with zero stats succeeds
    await assertSucceeds(
      ownerDb.collection('provider_profiles').doc('prov_new').set(makeProviderProfile('prov_new')),
    );

    // Self-approval update (pending -> approved) is strictly denied
    await assertFails(
      ownerDb.collection('provider_profiles').doc('prov_new').update({
        approvalStatus: 'approved',
        updatedAt: FIXED_DATE,
      }),
    );

    // Owner updating non-privileged vehiclePlate succeeds while approvalStatus remains pending
    await assertSucceeds(
      ownerDb.collection('provider_profiles').doc('prov_new').update({
        vehiclePlate: 'QAT-99112',
        updatedAt: FIXED_DATE,
      }),
    );

    // Admin approval succeeds
    await assertSucceeds(
      adminDb.collection('provider_profiles').doc('prov_new').update({
        approvalStatus: 'approved',
        reviewedBy: 'admin_1',
        updatedAt: FIXED_DATE,
      }),
    );
  });

  test('restricts provider_verifications reads to owner/admin and enforces 11-digit QID regex', async () => {
    const ownerDb = testEnv.authenticatedContext('prov_kyc').firestore();
    const otherUserDb = testEnv.authenticatedContext('other_user').firestore();
    const adminDb = testEnv.authenticatedContext('admin_1', { admin: true }).firestore();

    // Invalid QID formats (10 digits, 12 digits, alphanumeric) are rejected
    for (const badQid of ['1234567890', '123456789012', '2966340184A']) {
      await assertFails(
        ownerDb
          .collection('provider_verifications')
          .doc('prov_kyc')
          .set(makeProviderVerification('prov_kyc', { qidNumber: badQid })),
      );
    }

    // Valid 11-digit QID succeeds
    await assertSucceeds(
      ownerDb
        .collection('provider_verifications')
        .doc('prov_kyc')
        .set(makeProviderVerification('prov_kyc', { qidNumber: '29663401842' })),
    );

    // Owner and admin can read; other authenticated users are denied
    await assertSucceeds(ownerDb.collection('provider_verifications').doc('prov_kyc').get());
    await assertSucceeds(adminDb.collection('provider_verifications').doc('prov_kyc').get());
    await assertFails(otherUserDb.collection('provider_verifications').doc('prov_kyc').get());
  });

  test('enforces work_requests creation guards, blocks direct completion/settled forgery, and permits approved assigned provider stage progression', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db
        .collection('provider_profiles')
        .doc('prov_approved')
        .set(makeProviderProfile('prov_approved', { approvalStatus: 'approved' }));
      await db
        .collection('provider_profiles')
        .doc('prov_pending')
        .set(makeProviderProfile('prov_pending', { approvalStatus: 'pending' }));
    });

    const requesterDb = testEnv.authenticatedContext('req_1').firestore();
    const approvedProvDb = testEnv.authenticatedContext('prov_approved').firestore();
    const pendingProvDb = testEnv.authenticatedContext('prov_pending').firestore();

    // Valid owner creates for both payment methods
    await assertSucceeds(
      requesterDb
        .collection('work_requests')
        .doc('req_cod')
        .set(makeWorkRequest('req_cod', 'req_1', { paymentMethod: 'cash_on_delivery' })),
    );
    await assertSucceeds(
      requesterDb
        .collection('work_requests')
        .doc('req_bank')
        .set(makeWorkRequest('req_bank', 'req_1', { paymentMethod: 'bank_transfer_manual' })),
    );

    // Invalid budgetMinor (0 or float) or forged initial paymentStatus/status denied
    await assertFails(
      requesterDb
        .collection('work_requests')
        .doc('req_bad_budget')
        .set(makeWorkRequest('req_bad_budget', 'req_1', { budgetMinor: 0 })),
    );
    await assertFails(
      requesterDb
        .collection('work_requests')
        .doc('req_float_budget')
        .set(makeWorkRequest('req_float_budget', 'req_1', { budgetMinor: 125.5 })),
    );
    await assertFails(
      requesterDb
        .collection('work_requests')
        .doc('req_forged_paid')
        .set(makeWorkRequest('req_forged_paid', 'req_1', { paymentStatus: 'verified_settled' })),
    );

    // Requester cannot mark open request directly completed or verified_settled
    await assertFails(
      requesterDb.collection('work_requests').doc('req_cod').update({
        status: 'completed',
        updatedAt: FIXED_DATE,
      }),
    );
    await assertFails(
      requesterDb.collection('work_requests').doc('req_bank').update({
        paymentStatus: 'verified_settled',
        updatedAt: FIXED_DATE,
      }),
    );

    // Seed accepted requests for unapproved vs approved provider stage transition checks
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('work_requests').doc('req_unapproved_stage').set(
        makeWorkRequest('req_unapproved_stage', 'req_1', {
          status: 'accepted',
          offerCount: 1,
          selectedOfferId: 'off_p',
          assignedProviderId: 'prov_pending',
          agreedAmountMinor: 42000,
          agreedFeeMinor: 4000,
        }),
      );
      await db.collection('work_requests').doc('req_flow').set(
        makeWorkRequest('req_flow', 'req_1', {
          status: 'accepted',
          offerCount: 1,
          selectedOfferId: 'off_a',
          assignedProviderId: 'prov_approved',
          agreedAmountMinor: 44000,
          agreedFeeMinor: 5000,
        }),
      );
    });

    // Unapproved provider stage update denied even if assigned
    await assertFails(
      pendingProvDb.collection('work_requests').doc('req_unapproved_stage').update({
        status: 'in_progress',
        updatedAt: FIXED_DATE,
      }),
    );

    // Approved assigned provider cannot forge paymentStatus = verified_settled or skip stages
    await assertFails(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'in_progress',
        paymentStatus: 'verified_settled',
        updatedAt: FIXED_DATE,
      }),
    );
    await assertFails(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'in_transit',
        updatedAt: FIXED_DATE,
      }),
    );

    // Approved assigned provider valid stage progression:
    // accepted -> in_progress -> picked_up -> in_transit -> delivered_pending_confirmation
    await assertSucceeds(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'in_progress',
        updatedAt: FIXED_DATE,
      }),
    );
    await assertSucceeds(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'picked_up',
        invoiceImageUrls: [`https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/inv.png`],
        updatedAt: FIXED_DATE,
      }),
    );
    await assertSucceeds(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'in_transit',
        updatedAt: FIXED_DATE,
      }),
    );
    await assertSucceeds(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'delivered_pending_confirmation',
        updatedAt: FIXED_DATE,
      }),
    );

    // Neither requester nor assigned provider can jump directly to completed from client SDK
    await assertFails(
      requesterDb.collection('work_requests').doc('req_flow').update({
        status: 'completed',
        updatedAt: FIXED_DATE,
      }),
    );
    await assertFails(
      approvedProvDb.collection('work_requests').doc('req_flow').update({
        status: 'completed',
        updatedAt: FIXED_DATE,
      }),
    );

    // Legitimate requester updates: attach manual bank transfer proof & cancel open request
    await assertSucceeds(
      requesterDb.collection('work_requests').doc('req_bank').update({
        paymentStatus: 'transfer_proof_submitted',
        paymentProofUrl: `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/proof.jpg`,
        updatedAt: FIXED_DATE,
      }),
    );
    await assertSucceeds(
      requesterDb.collection('work_requests').doc('req_cod').update({
        status: 'cancelled',
        updatedAt: FIXED_DATE,
      }),
    );

    // Max-schema complexity check: structured map locations + 5 reference URLs + 5 invoice URLs
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('work_requests').doc('req_max_schema').set(
        makeWorkRequest('req_max_schema', 'req_1', {
          pickupLocation: {
            label: 'Industrial Area Depot',
            address: 'Street 14, Building 82',
            area: 'Industrial Area',
            notes: 'Loading Bay 2',
            lat: 25.2048,
            lng: 51.4391,
            placeId: 'place_ind_14',
          },
          deliveryLocation: {
            label: 'Lusail Marina Tower Plot 4',
            address: 'Marina District Zone 69',
            area: 'Lusail',
            notes: 'Call site foreman at Gate B',
            lat: 25.4012,
            lng: 51.5218,
            placeId: 'place_lusail_4',
          },
          status: 'picked_up',
          offerCount: 2,
          selectedOfferId: 'off_max',
          assignedProviderId: 'prov_approved',
          agreedAmountMinor: 48000,
          agreedFeeMinor: 6000,
          referenceImageUrls: [
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/ref1.jpg`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/ref2.jpg`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/ref3.jpg`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/ref4.jpg`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/ref5.jpg`,
          ],
          invoiceImageUrls: [
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/inv1.png`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/inv2.png`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/inv3.png`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/inv4.png`,
            `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}/o/inv5.png`,
          ],
        }),
      );
    });

    await assertSucceeds(
      approvedProvDb.collection('work_requests').doc('req_max_schema').update({
        status: 'in_transit',
        updatedAt: FIXED_DATE,
      }),
    );
  });

  test('denies work_offers creation by unapproved providers and self-bidders while allowing approved providers', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('work_requests').doc('req_open').set(makeWorkRequest('req_open', 'req_owner'));
      // Even if req_owner holds an approved provider profile, self-bidding must fail
      await db
        .collection('provider_profiles')
        .doc('req_owner')
        .set(makeProviderProfile('req_owner', { approvalStatus: 'approved' }));
      await db
        .collection('provider_profiles')
        .doc('prov_pending')
        .set(makeProviderProfile('prov_pending', { approvalStatus: 'pending' }));
      await db
        .collection('provider_profiles')
        .doc('prov_approved')
        .set(makeProviderProfile('prov_approved', { approvalStatus: 'approved' }));
    });

    const selfBidDb = testEnv.authenticatedContext('req_owner').firestore();
    const pendingProvDb = testEnv.authenticatedContext('prov_pending').firestore();
    const noProfileDb = testEnv.authenticatedContext('prov_none').firestore();
    const approvedProvDb = testEnv.authenticatedContext('prov_approved').firestore();

    await assertFails(
      selfBidDb
        .collection('work_offers')
        .doc('off_self')
        .set(makeWorkOffer('off_self', 'req_open', 'req_owner')),
    );
    await assertFails(
      pendingProvDb
        .collection('work_offers')
        .doc('off_pending')
        .set(makeWorkOffer('off_pending', 'req_open', 'prov_pending')),
    );
    await assertFails(
      noProfileDb
        .collection('work_offers')
        .doc('off_none')
        .set(makeWorkOffer('off_none', 'req_open', 'prov_none')),
    );

    await assertSucceeds(
      approvedProvDb
        .collection('work_offers')
        .doc('off_valid')
        .set(makeWorkOffer('off_valid', 'req_open', 'prov_approved')),
    );
  });

  test('allows ratings/${requestId}_${uid} creation once when work_request is completed and denies duplicates, updates, and deletes', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('work_requests').doc('req_incomplete').set(
        makeWorkRequest('req_incomplete', 'req_owner', {
          status: 'delivered_pending_confirmation',
          offerCount: 1,
          selectedOfferId: 'off_1',
          assignedProviderId: 'prov_approved',
        }),
      );
      await db.collection('work_requests').doc('req_done').set(
        makeWorkRequest('req_done', 'req_owner', {
          status: 'completed',
          offerCount: 1,
          selectedOfferId: 'off_1',
          assignedProviderId: 'prov_approved',
        }),
      );
    });

    const requesterDb = testEnv.authenticatedContext('req_owner').firestore();
    const strangerDb = testEnv.authenticatedContext('stranger_1').firestore();

    // Rating before request is completed is denied
    await assertFails(
      requesterDb.collection('ratings').doc('req_incomplete_req_owner').set({
        id: 'req_incomplete_req_owner',
        requestId: 'req_incomplete',
        fromUserId: 'req_owner',
        toUserId: 'prov_approved',
        fromRole: 'requester',
        toRole: 'provider',
        stars: 5,
        createdAt: FIXED_DATE,
      }),
    );

    // Non-participant rating on completed request is denied
    await assertFails(
      strangerDb.collection('ratings').doc('req_done_stranger_1').set({
        id: 'req_done_stranger_1',
        requestId: 'req_done',
        fromUserId: 'stranger_1',
        toUserId: 'prov_approved',
        stars: 5,
        createdAt: FIXED_DATE,
      }),
    );

    const ratingId = 'req_done_req_owner';
    const ratingPayload = {
      id: ratingId,
      requestId: 'req_done',
      fromUserId: 'req_owner',
      toUserId: 'prov_approved',
      fromRole: 'requester',
      toRole: 'provider',
      stars: 5,
      comment: 'On-time cement delivery',
      createdAt: FIXED_DATE,
    };

    // First rating submission succeeds
    await assertSucceeds(requesterDb.collection('ratings').doc(ratingId).set(ratingPayload));

    // Duplicate submission (overwrite same deterministic doc OR alternate doc ID), update, and delete are denied
    await assertFails(requesterDb.collection('ratings').doc(ratingId).set(ratingPayload));
    await assertFails(
      requesterDb
        .collection('ratings')
        .doc(`${ratingId}_dup`)
        .set({ ...ratingPayload, id: `${ratingId}_dup` }),
    );
    await assertFails(requesterDb.collection('ratings').doc(ratingId).update({ stars: 2 }));
    await assertFails(requesterDb.collection('ratings').doc(ratingId).delete());
  });

  test('enforces Cloud Storage rules for auth, size/MIME limits, private KYC paths, and participant work_request invoices', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db
        .collection('provider_profiles')
        .doc('prov_approved')
        .set(makeProviderProfile('prov_approved', { approvalStatus: 'approved' }));
      await db.collection('work_requests').doc('req_inv_1').set(
        makeWorkRequest('req_inv_1', 'req_owner', {
          status: 'picked_up',
          offerCount: 1,
          selectedOfferId: 'off_1',
          assignedProviderId: 'prov_approved',
        }),
      );
    });

    const unauthStorage = testEnv.unauthenticatedContext().storage();
    const provStorage = testEnv.authenticatedContext('prov_approved').storage();
    const requesterStorage = testEnv.authenticatedContext('req_owner').storage();
    const strangerStorage = testEnv.authenticatedContext('stranger_1').storage();
    const adminStorage = testEnv.authenticatedContext('admin_1', { admin: true }).storage();

    const smallJpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);
    const smallPng = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    const pdfBytes = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
    const oversizedJpeg = new Uint8Array(10 * 1024 * 1024 + 1024);

    // 1. Unauthenticated upload denied
    await assertFails(
      unauthStorage
        .ref('provider_verifications/prov_approved/qid_front.jpg')
        .put(smallJpeg, { contentType: 'image/jpeg' }),
    );

    // 2. > 10 MB upload denied & application/pdf non-image upload denied
    await assertFails(
      provStorage
        .ref('provider_verifications/prov_approved/oversized.jpg')
        .put(oversizedJpeg, { contentType: 'image/jpeg' }),
    );
    await assertFails(
      provStorage
        .ref('provider_verifications/prov_approved/qid_doc.pdf')
        .put(pdfBytes, { contentType: 'application/pdf' }),
    );

    // 3. /provider_verifications/{uid}/qid_front.jpg: cross-user upload/read denied & owner image/jpeg upload allowed
    await assertFails(
      strangerStorage
        .ref('provider_verifications/prov_approved/qid_front.jpg')
        .put(smallJpeg, { contentType: 'image/jpeg' }),
    );
    await assertSucceeds(
      provStorage
        .ref('provider_verifications/prov_approved/qid_front.jpg')
        .put(smallJpeg, { contentType: 'image/jpeg' }),
    );
    await assertSucceeds(
      provStorage.ref('provider_verifications/prov_approved/qid_front.jpg').getMetadata(),
    );
    await assertSucceeds(
      adminStorage.ref('provider_verifications/prov_approved/qid_front.jpg').getMetadata(),
    );
    await assertFails(
      strangerStorage.ref('provider_verifications/prov_approved/qid_front.jpg').getMetadata(),
    );
    await assertFails(
      requesterStorage.ref('provider_verifications/prov_approved/qid_front.jpg').getMetadata(),
    );

    // 4. /work_requests/{id}/invoices/inv.png: stranger upload/read denied & participant image/png upload/read allowed
    await assertFails(
      strangerStorage
        .ref('work_requests/req_inv_1/invoices/inv.png')
        .put(smallPng, { contentType: 'image/png' }),
    );
    await assertSucceeds(
      provStorage
        .ref('work_requests/req_inv_1/invoices/inv.png')
        .put(smallPng, { contentType: 'image/png' }),
    );
    await assertSucceeds(
      provStorage.ref('work_requests/req_inv_1/invoices/inv.png').getMetadata(),
    );
    await assertSucceeds(
      requesterStorage.ref('work_requests/req_inv_1/invoices/inv.png').getMetadata(),
    );
    await assertFails(
      strangerStorage.ref('work_requests/req_inv_1/invoices/inv.png').getMetadata(),
    );
  });

  test('allows users/{uid} create with empty phone (Email signup) or empty fullName (Phone OTP) while rejecting invalid phone or isVerified=true', async () => {
    const emailUid = 'usr_email_no_phone';
    const phoneUid = 'usr_phone_no_name';
    const badPhoneUid = 'usr_bad_phone';
    const verifiedUid = 'usr_forged_verified';

    const makeBaseUser = (uid, overrides = {}) => ({
      id: uid,
      fullName: 'Eng. Fahad Al-Marri',
      phone: '55123456',
      gender: 'preferNotToSay',
      isVerified: false,
      idVerificationStatus: 'unverified',
      walletBalance: 0,
      rating: 0,
      completedRides: 0,
      completedParcels: 0,
      email: `${uid}@mashwar.qa`,
      ...overrides,
    });

    // Email registration without optional phone succeeds
    const emailDb = testEnv.authenticatedContext(emailUid).firestore();
    await assertSucceeds(
      emailDb.collection('users').doc(emailUid).set(makeBaseUser(emailUid, { phone: '' })),
    );

    // Phone OTP sign-in before profile setup (empty fullName) succeeds
    const phoneDb = testEnv.authenticatedContext(phoneUid).firestore();
    await assertSucceeds(
      phoneDb
        .collection('users')
        .doc(phoneUid)
        .set(makeBaseUser(phoneUid, { fullName: '', email: null })),
    );

    // Invalid short phone is still rejected
    const badPhoneDb = testEnv.authenticatedContext(badPhoneUid).firestore();
    await assertFails(
      badPhoneDb.collection('users').doc(badPhoneUid).set(makeBaseUser(badPhoneUid, { phone: '123' })),
    );

    // Self-verification privilege escalation is still rejected
    const verifiedDb = testEnv.authenticatedContext(verifiedUid).firestore();
    await assertFails(
      verifiedDb
        .collection('users')
        .doc(verifiedUid)
        .set(makeBaseUser(verifiedUid, { isVerified: true })),
    );
  });
});
