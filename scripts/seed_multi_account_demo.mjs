#!/usr/bin/env node
/**
 * MASHWAR Qatar — Live Multi-Account Firebase Auth + Firestore Demo Seeder & Verifier
 *
 * Targets Firebase project `mashwar-qatar-2026-ec99d` (Spark-plan safe, zero Cloud Functions required).
 * Authenticates via the local Firebase CLI OAuth session (`firebase-tools/lib`):
 *   const acct = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
 *   const opts = { project: projectId };
 *   auth.setActiveAccount(opts, acct);
 *   await requireAuth(opts);
 *
 * Modes:
 *   node scripts/seed_multi_account_demo.mjs                # Provision/update 5 Auth accounts + seed all demo docs + verify readback
 *   node scripts/seed_multi_account_demo.mjs --verify-only  # Read-only verification of all 5 Auth accounts, claims, counts & invariants
 */

import crypto from 'node:crypto';
import fs from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DEFAULT_PROJECT_ID = 'mashwar-qatar-2026-ec99d';

const ALT_PROVIDER_ID = 'demo_ma_prov_alt';
const ALT_PROVIDER_NAME = 'سعد المهندي للتوريدات الهندسية';

const CHAT_CONVERSATION_ID = 'chat_حمد_المري_الدوحة_←_الخور';

const HANDOVER_CODES = Object.freeze({
  demo_ma_wr_04_accepted: 'K7M4P9',
  demo_ma_wr_05_in_prog: 'Q9R3W8',
  demo_ma_wr_06_picked_up: 'M4N8X2',
  demo_ma_wr_07_in_transit: 'H6P2V5',
  demo_ma_wr_08_deliv_pend: 'T5K9B3',
});

const ACCOUNT_SPECS = Object.freeze([
  {
    key: 'requester',
    label: 'Account 1 — Requester / Customer',
    email: 'requester.demo@mashwar.qa',
    password: 'Mashwar@2026',
    displayName: 'م. خالد الكواري',
    customClaims: {},
  },
  {
    key: 'provider',
    label: 'Account 2 — Approved Provider & Verified Captain',
    email: 'provider.demo@mashwar.qa',
    password: 'Mashwar@2026',
    displayName: 'حمد المري',
    customClaims: {},
  },
  {
    key: 'traveler',
    label: 'Account 3 — Ladies-Only Traveler & Pending Provider',
    email: 'traveler.demo@mashwar.qa',
    password: 'Mashwar@2026',
    displayName: 'نورة العطية',
    customClaims: {},
  },
  {
    key: 'fresh',
    label: 'Account 4 — Fresh Clean-Slate Comparison Account',
    email: 'fresh.demo@mashwar.qa',
    password: 'Mashwar@2026',
    displayName: 'طارق السليطي',
    customClaims: {},
  },
  {
    key: 'admin',
    label: 'Account 5 — Super Admin / Command Center',
    email: 'admin.demo@mashwar.qa',
    password: 'MashwarAdmin@2026',
    displayName: 'إدارة عمليات مشوار',
    customClaims: { admin: true, role: 'superAdmin' },
  },
]);

const EXPECTED_WORK_STATUSES = [
  'open',
  'offer_received',
  'offer_selected',
  'accepted',
  'in_progress',
  'picked_up',
  'in_transit',
  'delivered_pending_confirmation',
  'completed',
  'disputed',
  'cancelled',
];

const EXPECTED_PARCEL_STATUSES = [
  'requested',
  'accepted',
  'handedOver',
  'inTransit',
  'delivered',
];

function parseArgs(argv) {
  let projectId = process.env.MASHWAR_FIREBASE_PROJECT || DEFAULT_PROJECT_ID;
  let verifyOnly = false;

  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--verify-only' || arg === '-VerifyOnly') {
      verifyOnly = true;
    } else if (arg === '--project' && argv[i + 1]) {
      projectId = argv[++i].trim();
    }
  }
  return { projectId, verifyOnly };
}

function resolveFirebaseToolsLib() {
  const candidates = [];
  if (process.env.MASHWAR_FT_LIB) {
    candidates.push(process.env.MASHWAR_FT_LIB);
  }
  if (process.env.APPDATA) {
    candidates.push(path.join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools', 'lib'));
  }
  if (process.env.LOCALAPPDATA) {
    candidates.push(
      path.join(process.env.LOCALAPPDATA, 'npm', 'node_modules', 'firebase-tools', 'lib'),
    );
  }
  for (const dir of candidates) {
    if (
      dir &&
      fs.existsSync(path.join(dir, 'auth.js')) &&
      fs.existsSync(path.join(dir, 'requireAuth.js')) &&
      fs.existsSync(path.join(dir, 'apiv2.js'))
    ) {
      return dir;
    }
  }
  throw new Error(
    'Could not locate firebase-tools/lib (expected at %APPDATA%\\npm\\node_modules\\firebase-tools\\lib).',
  );
}

/** Wraps a Date or ISO string so Firestore REST serializes it as `timestampValue`. */
function ts(dateOrIso) {
  const iso = dateOrIso instanceof Date ? dateOrIso.toISOString() : new Date(dateOrIso).toISOString();
  return { __firestoreTimestamp: iso };
}

/** Wraps a float so Firestore REST serializes it as `doubleValue` even if whole. */
function dbl(value) {
  return { __firestoreDouble: Number(value) };
}

function qarMinor(majorQar) {
  return Math.round(majorQar * 100);
}

/** Exact salted SHA-256 hex matching `functions/src/handoverCrypto.ts`. */
function hashHandoverCode(code, salt) {
  const normalized = code.trim().toUpperCase();
  return crypto.createHash('sha256').update(`${salt}:${normalized}`, 'utf8').digest('hex');
}

function deterministicSaltForRequest(requestId) {
  return crypto
    .createHash('sha256')
    .update(`mashwar-qatar-2026-handover-salt:${requestId}`, 'utf8')
    .digest('hex')
    .slice(0, 32);
}

function encodeFirestoreValue(val) {
  if (val === null) {
    return { nullValue: null };
  }
  if (typeof val === 'boolean') {
    return { booleanValue: val };
  }
  if (typeof val === 'string') {
    return { stringValue: val };
  }
  if (typeof val === 'number') {
    if (Number.isInteger(val)) {
      return { integerValue: String(val) };
    }
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    if (val.length === 0) {
      return { arrayValue: {} };
    }
    return { arrayValue: { values: val.map((item) => encodeFirestoreValue(item)) } };
  }
  if (typeof val === 'object') {
    if (typeof val.__firestoreTimestamp === 'string') {
      return { timestampValue: val.__firestoreTimestamp };
    }
    if (typeof val.__firestoreDouble === 'number') {
      return { doubleValue: val.__firestoreDouble };
    }
    return { mapValue: { fields: encodeFirestoreFields(val) } };
  }
  throw new Error(`Unsupported Firestore value type: ${typeof val}`);
}

function encodeFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined) continue;
    fields[k] = encodeFirestoreValue(v);
  }
  return fields;
}

function decodeFirestoreValue(raw) {
  if (!raw || typeof raw !== 'object') return null;
  if ('nullValue' in raw) return null;
  if ('booleanValue' in raw) return Boolean(raw.booleanValue);
  if ('stringValue' in raw) return String(raw.stringValue);
  if ('integerValue' in raw) return Number(raw.integerValue);
  if ('doubleValue' in raw) return Number(raw.doubleValue);
  if ('timestampValue' in raw) return String(raw.timestampValue);
  if ('arrayValue' in raw) {
    const values = raw.arrayValue?.values;
    return Array.isArray(values) ? values.map(decodeFirestoreValue) : [];
  }
  if ('mapValue' in raw) {
    return decodeFirestoreFields(raw.mapValue?.fields || {});
  }
  return null;
}

function decodeFirestoreFields(fieldsObj) {
  const out = {};
  for (const [k, v] of Object.entries(fieldsObj || {})) {
    out[k] = decodeFirestoreValue(v);
  }
  return out;
}

function parseClaims(customAttributes) {
  if (!customAttributes) return {};
  try {
    const parsed = JSON.parse(customAttributes);
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch {
    return {};
  }
}

async function lookupAuthUserByEmail({ identityClient, projectId, email }) {
  const res = await identityClient.post(
    `/v1/projects/${projectId}/accounts:lookup`,
    { email: [email] },
    { headers: { 'x-goog-user-project': projectId } },
  );
  return res.body?.users?.[0] || null;
}

async function provisionOrVerifyAccounts({ identityClient, projectId, verifyOnly }) {
  const resolved = {};

  for (const spec of ACCOUNT_SPECS) {
    let user = await lookupAuthUserByEmail({ identityClient, projectId, email: spec.email });
    let action = 'verified';

    if (!user) {
      if (verifyOnly) {
        throw new Error(`Account '${spec.email}' does not exist in Firebase Auth (${projectId}).`);
      }
      const createRes = await identityClient.post(
        `/v1/projects/${projectId}/accounts`,
        {
          email: spec.email,
          password: spec.password,
          displayName: spec.displayName,
          emailVerified: true,
        },
        { headers: { 'x-goog-user-project': projectId } },
      );
      const createdUid = createRes.body?.localId;
      if (!createdUid) {
        throw new Error(
          `Failed to create Auth user '${spec.email}': ${JSON.stringify(createRes.body)}`,
        );
      }
      action = 'created';
      user = await lookupAuthUserByEmail({ identityClient, projectId, email: spec.email });
    }

    if (!verifyOnly) {
      await identityClient.post(
        `/v1/projects/${projectId}/accounts:update`,
        {
          localId: user.localId,
          email: spec.email,
          password: spec.password,
          displayName: spec.displayName,
          emailVerified: true,
          customAttributes: JSON.stringify(spec.customClaims),
        },
        { headers: { 'x-goog-user-project': projectId } },
      );
      if (action === 'verified') {
        action = 'updated';
      }
      user = await lookupAuthUserByEmail({ identityClient, projectId, email: spec.email });
    }

    const claims = parseClaims(user.customAttributes);
    if (spec.key === 'admin') {
      if (claims.admin !== true || claims.role !== 'superAdmin') {
        throw new Error(
          `Expected custom claims { admin: true, role: "superAdmin" } on ${spec.email} (${user.localId}), found: ${JSON.stringify(claims)}`,
        );
      }
    } else if (claims.admin === true || claims.role === 'superAdmin' || claims.role === 'admin') {
      throw new Error(
        `Unexpected admin claim on non-admin account ${spec.email} (${user.localId}): ${JSON.stringify(claims)}`,
      );
    }

    if (user.displayName !== spec.displayName) {
      throw new Error(
        `Display name mismatch for ${spec.email}: expected '${spec.displayName}', got '${user.displayName || ''}'`,
      );
    }

    resolved[spec.key] = {
      ...spec,
      uid: user.localId,
      claims,
      action,
    };
  }

  return resolved;
}

/**
 * Queries a root Firestore collection for documents matching `fieldPath == value`.
 * Returns relative document paths (`collection/docId`).
 */
async function queryDocPathsByField({ firestoreClient, projectId, collectionId, fieldPath, value }) {
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const res = await firestoreClient.post(
    `/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
    {
      structuredQuery: {
        from: [{ collectionId }],
        where: {
          fieldFilter: {
            field: { fieldPath },
            op: 'EQUAL',
            value: encodeFirestoreValue(value),
          },
        },
      },
    },
    { headers: { 'x-goog-user-project': projectId } },
  );

  const rows = Array.isArray(res.body) ? res.body : [];
  const paths = [];
  for (const row of rows) {
    if (row.document?.name && row.document.name.startsWith(`${dbRoot}/`)) {
      paths.push(row.document.name.slice(dbRoot.length + 1));
    }
  }
  return paths;
}

/** Lists all document paths inside `users/{uid}/private`. */
async function listUserPrivateDocPaths({ firestoreClient, projectId, uid }) {
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const res = await firestoreClient.get(
    `/v1/projects/${projectId}/databases/(default)/documents/users/${uid}/private`,
    { headers: { 'x-goog-user-project': projectId } },
  );
  const docs = res.body?.documents || [];
  return docs
    .map((d) => d.name)
    .filter((name) => typeof name === 'string' && name.startsWith(`${dbRoot}/`))
    .map((name) => name.slice(dbRoot.length + 1));
}

/**
 * Finds ANY documents belonging to Account 4 (`uid4`) across all user-data collections
 * so Account 4 stays 100% clean-slate on every re-run.
 */
async function findStaleDocsForFreshAccount({ firestoreClient, projectId, uid4 }) {
  const checks = [
    { collectionId: 'notifications', fieldPath: 'userId' },
    { collectionId: 'bookings', fieldPath: 'passengerId' },
    { collectionId: 'bookings', fieldPath: 'driverId' },
    { collectionId: 'rides', fieldPath: 'driverId' },
    { collectionId: 'parcels', fieldPath: 'senderId' },
    { collectionId: 'parcels', fieldPath: 'driverId' },
    { collectionId: 'parcels', fieldPath: 'receiverId' },
    { collectionId: 'board_ads', fieldPath: 'authorId' },
    { collectionId: 'route_alerts', fieldPath: 'userId' },
    { collectionId: 'wallet_transactions', fieldPath: 'userId' },
    { collectionId: 'work_requests', fieldPath: 'requesterId' },
    { collectionId: 'work_requests', fieldPath: 'assignedProviderId' },
    { collectionId: 'work_offers', fieldPath: 'providerId' },
    { collectionId: 'ratings', fieldPath: 'fromUserId' },
    { collectionId: 'ratings', fieldPath: 'toUserId' },
  ];

  const foundSet = new Set();
  for (const check of checks) {
    const paths = await queryDocPathsByField({
      firestoreClient,
      projectId,
      collectionId: check.collectionId,
      fieldPath: check.fieldPath,
      value: uid4,
    });
    for (const p of paths) {
      foundSet.add(p);
    }
  }

  // Also check conversations where participantIds array-contains uid4
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const convRes = await firestoreClient.post(
    `/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
    {
      structuredQuery: {
        from: [{ collectionId: 'conversations' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'participantIds' },
            op: 'ARRAY_CONTAINS',
            value: encodeFirestoreValue(uid4),
          },
        },
      },
    },
    { headers: { 'x-goog-user-project': projectId } },
  );
  for (const row of Array.isArray(convRes.body) ? convRes.body : []) {
    if (row.document?.name && row.document.name.startsWith(`${dbRoot}/`)) {
      foundSet.add(row.document.name.slice(dbRoot.length + 1));
    }
  }

  // Also check users/{uid4}/private subcollection
  try {
    const privPaths = await listUserPrivateDocPaths({ firestoreClient, projectId, uid: uid4 });
    for (const p of privPaths) {
      foundSet.add(p);
    }
  } catch {
    // Subcollection may not exist; ignore.
  }

  // Always ensure these per-UID singleton docs are absent for uid4
  const absentSingletons = [
    `provider_profiles/${uid4}`,
    `provider_verifications/${uid4}`,
    `business_profiles/${uid4}`,
    `admin_staff/${uid4}`,
  ];

  return {
    staleQueryPaths: [...foundSet],
    absentSingletons,
  };
}

function buildMultiAccountDataset({ accounts, now = new Date() }) {
  const uid1 = accounts.requester.uid;
  const uid2 = accounts.provider.uid;
  const uid3 = accounts.traveler.uid;
  const uid4 = accounts.fresh.uid;
  const uid5 = accounts.admin.uid;

  const anchorMs = now.getTime();
  const ago = ({ days = 0, hours = 0, minutes = 0 }) =>
    new Date(anchorMs - ((days * 24 + hours) * 60 + minutes) * 60 * 1000);
  const ahead = ({ days = 0, hours = 0, minutes = 0 }) =>
    new Date(anchorMs + ((days * 24 + hours) * 60 + minutes) * 60 * 1000);

  // 1. Admin Staff
  const adminStaffDocs = [
    {
      docPath: `admin_staff/${uid5}`,
      collectionKey: 'admin_staff',
      data: {
        id: uid5,
        uid: uid5,
        name: 'إدارة عمليات مشوار',
        email: 'admin.demo@mashwar.qa',
        role: 'superAdmin',
        isActive: true,
        createdAt: ts(ago({ days: 60 })),
        updatedAt: ts(now),
      },
    },
  ];

  // 2. Users (5 real accounts + 1 secondary verified provider for competing offers)
  const userDocs = [
    {
      docPath: `users/${uid1}`,
      collectionKey: 'users',
      data: {
        id: uid1,
        fullName: 'م. خالد الكواري',
        phone: '55102030',
        email: 'requester.demo@mashwar.qa',
        gender: 'male',
        governorate: 'بلدية الضعاين (لوسيل)',
        city: 'مارينا لوسيل',
        emergencyContactName: 'سالم الكواري',
        emergencyContactPhone: '55901122',
        occupation: 'مهندس مشاريع وطالب خدمات توريد',
        ladiesOnlyPreference: false,
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: dbl(350.0),
        rating: dbl(4.9),
        completedRides: 8,
        completedParcels: 5,
        hasActiveAlerts: true,
        hasUpcomingBooking: true,
        createdAt: ts(ago({ days: 45 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `users/${uid2}`,
      collectionKey: 'users',
      data: {
        id: uid2,
        fullName: 'حمد المري',
        phone: '55405060',
        email: 'provider.demo@mashwar.qa',
        gender: 'male',
        governorate: 'بلدية الريان',
        city: 'طريق سلوى',
        occupation: 'تويوتا هايلكس 2025 · أبيض (قطر 774210)',
        ladiesOnlyPreference: false,
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: dbl(1280.0),
        rating: dbl(4.95),
        completedRides: 42,
        completedParcels: 27,
        hasActiveAlerts: false,
        hasUpcomingBooking: false,
        createdAt: ts(ago({ days: 60 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `users/${uid3}`,
      collectionKey: 'users',
      data: {
        id: uid3,
        fullName: 'نورة العطية',
        phone: '66708090',
        email: 'traveler.demo@mashwar.qa',
        gender: 'female',
        governorate: 'بلدية الوكرة',
        city: 'الوكرة',
        occupation: 'كيا سبورتاج 2024 · فضي (قطر 518390)',
        ladiesOnlyPreference: true,
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: dbl(220.0),
        rating: dbl(4.85),
        completedRides: 12,
        completedParcels: 6,
        hasActiveAlerts: true,
        hasUpcomingBooking: false,
        createdAt: ts(ago({ days: 35 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `users/${uid4}`,
      collectionKey: 'users',
      data: {
        id: uid4,
        fullName: 'طارق السليطي',
        phone: '',
        email: 'fresh.demo@mashwar.qa',
        gender: 'preferNotToSay',
        governorate: null,
        city: null,
        ladiesOnlyPreference: false,
        isVerified: false,
        idVerificationStatus: 'unverified',
        walletBalance: dbl(0.0),
        rating: dbl(0.0),
        completedRides: 0,
        completedParcels: 0,
        hasActiveAlerts: false,
        hasUpcomingBooking: false,
        createdAt: ts(now),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `users/${uid5}`,
      collectionKey: 'users',
      data: {
        id: uid5,
        fullName: 'إدارة عمليات مشوار',
        phone: '55001000',
        email: 'admin.demo@mashwar.qa',
        gender: 'male',
        governorate: 'الدوحة',
        city: 'الخليج الغربي',
        occupation: 'مركز قيادة عمليات مشوار قطر',
        ladiesOnlyPreference: false,
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: dbl(0.0),
        rating: dbl(5.0),
        completedRides: 0,
        completedParcels: 0,
        hasActiveAlerts: false,
        hasUpcomingBooking: false,
        createdAt: ts(ago({ days: 60 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `users/${ALT_PROVIDER_ID}`,
      collectionKey: 'users',
      data: {
        id: ALT_PROVIDER_ID,
        fullName: ALT_PROVIDER_NAME,
        phone: '55819203',
        email: 'saad.supply@mashwar.qa',
        gender: 'male',
        governorate: 'الدوحة',
        city: 'المنطقة الصناعية',
        occupation: 'نيسان نافارا 2024 · رمادي (قطر 609314)',
        ladiesOnlyPreference: false,
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: dbl(460.0),
        rating: dbl(4.82),
        completedRides: 19,
        completedParcels: 14,
        hasActiveAlerts: false,
        hasUpcomingBooking: false,
        createdAt: ts(ago({ days: 50 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
  ];

  // 3. Provider Profiles & Verifications
  const providerProfileDocs = [
    {
      docPath: `provider_profiles/${uid2}`,
      collectionKey: 'provider_profiles',
      data: {
        id: uid2,
        userId: uid2,
        fullName: 'حمد المري',
        phone: '55405060',
        vehicleType: 'بيك أب تويوتا هايلكس 2025',
        vehiclePlate: 'قطر 774210',
        serviceAreas: ['الدوحة', 'لوسيل', 'الريان', 'الوكرة', 'الخور', 'المنطقة الصناعية'],
        approvalStatus: 'approved',
        completedTasksCount: 34,
        ratingAvg: dbl(4.95),
        ratingCount: 34,
        reviewedBy: uid5,
        reviewedAtUtc: ago({ days: 30 }).toISOString(),
        rejectionReason: null,
        createdAt: ts(ago({ days: 40 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `provider_profiles/${uid3}`,
      collectionKey: 'provider_profiles',
      data: {
        id: uid3,
        userId: uid3,
        fullName: 'نورة العطية',
        phone: '66708090',
        vehicleType: 'كيا سبورتاج 2024 SUV',
        vehiclePlate: 'قطر 518390',
        serviceAreas: ['الوكرة', 'الدوحة', 'لوسيل', 'الريان'],
        approvalStatus: 'pending',
        completedTasksCount: 0,
        ratingAvg: dbl(0.0),
        ratingCount: 0,
        reviewedBy: null,
        reviewedAtUtc: null,
        rejectionReason: null,
        createdAt: ts(ago({ hours: 12 })),
        updatedAt: ts(ago({ hours: 6 })),
      },
    },
    {
      docPath: `provider_profiles/${ALT_PROVIDER_ID}`,
      collectionKey: 'provider_profiles',
      data: {
        id: ALT_PROVIDER_ID,
        userId: ALT_PROVIDER_ID,
        fullName: ALT_PROVIDER_NAME,
        phone: '55819203',
        vehicleType: 'نيسان نافارا بيك أب 2024',
        vehiclePlate: 'قطر 609314',
        serviceAreas: ['الدوحة', 'المنطقة الصناعية', 'الريان', 'لوسيل', 'الوكرة'],
        approvalStatus: 'approved',
        completedTasksCount: 21,
        ratingAvg: dbl(4.82),
        ratingCount: 21,
        reviewedBy: uid5,
        reviewedAtUtc: ago({ days: 25 }).toISOString(),
        rejectionReason: null,
        createdAt: ts(ago({ days: 30 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
  ];

  const providerVerificationDocs = [
    {
      docPath: `provider_verifications/${uid2}`,
      collectionKey: 'provider_verifications',
      data: {
        id: uid2,
        providerId: uid2,
        fullName: 'حمد المري',
        qidNumber: '28963412345',
        qidFrontUrl: `https://storage.mashwar.qa/kyc/${uid2}/qid_front.jpg`,
        qidBackUrl: `https://storage.mashwar.qa/kyc/${uid2}/qid_back.jpg`,
        selfieUrl: `https://storage.mashwar.qa/kyc/${uid2}/selfie.jpg`,
        vehicleLicenseUrl: `https://storage.mashwar.qa/kyc/${uid2}/istamara.jpg`,
        status: 'approved',
        rejectionReason: null,
        reviewedBy: uid5,
        reviewedAtUtc: ago({ days: 30 }).toISOString(),
        createdAt: ts(ago({ days: 40 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `provider_verifications/${uid3}`,
      collectionKey: 'provider_verifications',
      data: {
        id: uid3,
        providerId: uid3,
        fullName: 'نورة العطية',
        qidNumber: '29563454321',
        qidFrontUrl: `https://storage.mashwar.qa/kyc/${uid3}/qid_front.jpg`,
        qidBackUrl: `https://storage.mashwar.qa/kyc/${uid3}/qid_back.jpg`,
        selfieUrl: `https://storage.mashwar.qa/kyc/${uid3}/selfie.jpg`,
        vehicleLicenseUrl: `https://storage.mashwar.qa/kyc/${uid3}/istamara.jpg`,
        status: 'underReview',
        rejectionReason: null,
        reviewedBy: null,
        reviewedAtUtc: null,
        createdAt: ts(ago({ hours: 12 })),
        updatedAt: ts(ago({ hours: 6 })),
      },
    },
    {
      docPath: `provider_verifications/${ALT_PROVIDER_ID}`,
      collectionKey: 'provider_verifications',
      data: {
        id: ALT_PROVIDER_ID,
        providerId: ALT_PROVIDER_ID,
        fullName: ALT_PROVIDER_NAME,
        qidNumber: '28763499881',
        qidFrontUrl: `https://storage.mashwar.qa/kyc/${ALT_PROVIDER_ID}/qid_front.jpg`,
        qidBackUrl: `https://storage.mashwar.qa/kyc/${ALT_PROVIDER_ID}/qid_back.jpg`,
        selfieUrl: `https://storage.mashwar.qa/kyc/${ALT_PROVIDER_ID}/selfie.jpg`,
        vehicleLicenseUrl: `https://storage.mashwar.qa/kyc/${ALT_PROVIDER_ID}/istamara.jpg`,
        status: 'approved',
        rejectionReason: null,
        reviewedBy: uid5,
        reviewedAtUtc: ago({ days: 25 }).toISOString(),
        createdAt: ts(ago({ days: 30 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
  ];

  // 4. Business Profile & Saved Worksites for Account 1
  const businessProfileDocs = [
    {
      docPath: `business_profiles/${uid1}`,
      collectionKey: 'business_profiles',
      data: {
        id: uid1,
        userId: uid1,
        companyName: 'الكواري للمقاولات والإنشاءات الهندسية',
        contactName: 'م. خالد الكواري',
        phone: '55102030',
        defaultWorksiteArea: 'لوسيل',
        ratingAvg: dbl(4.9),
        ratingCount: 8,
        createdAt: ts(ago({ days: 40 })),
        updatedAt: ts(now),
      },
    },
  ];

  const savedWorksiteDocs = [
    {
      docPath: `users/${uid1}/private/demo_ma_site_lusail_b`,
      collectionKey: 'saved_worksites',
      data: {
        id: 'demo_ma_site_lusail_b',
        docType: 'saved_worksite',
        ownerUserId: uid1,
        businessProfileId: uid1,
        label: 'مارينا لوسيل - برج B',
        municipality: 'لوسيل',
        zoneOrStreet: 'منطقة 69، شارع المارينا 210، برج B',
        landmark: 'بوابة المقاولين الشمالية',
        gateInstructions: 'الاتصال بـ م. خالد قبل الوصول بـ 10 دقائق لتنسيق تصريح الدخول',
        siteContactName: 'م. خالد الكواري',
        siteContactPhone: '55102030',
        latitude: dbl(25.4357),
        longitude: dbl(51.491),
        isDefault: true,
        createdAt: ts(ago({ days: 20 })),
        updatedAt: ts(ago({ days: 2 })),
      },
    },
    {
      docPath: `users/${uid1}/private/demo_ma_site_msheireb_4`,
      collectionKey: 'saved_worksites',
      data: {
        id: 'demo_ma_site_msheireb_4',
        docType: 'saved_worksite',
        ownerUserId: uid1,
        businessProfileId: uid1,
        label: 'مشيرب قلب الدوحة - مبنى 4',
        municipality: 'الدوحة',
        zoneOrStreet: 'مشيرب قلب الدوحة، شارع السكة، مبنى 4',
        landmark: 'بوابة خدمات الصيانة الخلفية بجوار مترو مشيرب',
        gateInstructions: 'إبراز فاتورة الشراء لمكتب الأمن قبل تنزيل المواد',
        siteContactName: 'سالم الكواري',
        siteContactPhone: '55901122',
        latitude: dbl(25.2867),
        longitude: dbl(51.5269),
        isDefault: false,
        createdAt: ts(ago({ days: 15 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
  ];

  // 5. Worksite Supply Requests (12 owned by uid1 + 1 open owned by uid3 = 13 total)
  function makeWorkRequestDoc({
    id,
    requesterId,
    requesterName,
    supplyCategory,
    title,
    description,
    pickupLocation,
    deliveryLocation,
    deliveryArea,
    siteContactName,
    siteContactPhone,
    itemNotes = null,
    estimatedQar,
    maxCapQar,
    feeBudgetQar,
    agreedFeeQar = null,
    actualReceiptQar = null,
    receiptUrl = null,
    paymentMethod,
    paymentStatus,
    paymentProofUrl = null,
    paymentReference = null,
    status,
    offerCount = 0,
    selectedOfferId = null,
    assignedProviderId = null,
    assignedProviderName = null,
    isHandoverVerified = false,
    cancellationReason = null,
    disputeReason = null,
    scheduledBy = null,
    createdAt,
    updatedAt,
  }) {
    const estimatedItemsCostMinor = qarMinor(estimatedQar);
    const maxItemsCapMinor = qarMinor(maxCapQar);
    const deliveryFeeBudgetMinor = qarMinor(feeBudgetQar);
    const budgetMinor = maxItemsCapMinor + deliveryFeeBudgetMinor;
    return {
      docPath: `work_requests/${id}`,
      collectionKey: 'work_requests',
      data: {
        id,
        requesterId,
        requesterName,
        category: 'worksite_supply',
        supplyCategory,
        title,
        description,
        pickupLocation,
        deliveryLocation,
        deliveryArea,
        siteContactName,
        siteContactPhone,
        ...(itemNotes ? { itemNotes } : {}),
        budgetMinor,
        estimatedItemsCostMinor,
        maxItemsCapMinor,
        deliveryFeeBudgetMinor,
        paymentMethod,
        paymentStatus,
        paymentProofUrl,
        paymentReference,
        status,
        offerCount,
        selectedOfferId,
        assignedProviderId,
        assignedProviderName,
        agreedAmountMinor: actualReceiptQar !== null ? qarMinor(actualReceiptQar) : null,
        agreedFeeMinor: agreedFeeQar !== null ? qarMinor(agreedFeeQar) : null,
        isHandoverVerified,
        cancellationReason,
        disputeReason,
        referenceImageUrls: [],
        invoiceImageUrls: receiptUrl ? [receiptUrl] : [],
        ...(scheduledBy ? { scheduledBy: ts(scheduledBy) } : {}),
        createdAt: ts(createdAt),
        updatedAt: ts(updatedAt),
      },
    };
  }

  const workRequestDocs = [
    // 1. open (Account 1 -> open for Account 2 to submit live offer!)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_01_open',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'electrical',
      title: 'لوحات توزيع كهربائية وقواطع Schneider 32A | Electrical Panels & Breakers',
      description:
        'توريد لوحتي توزيع فرعيتين مع 10 قواطع Schneider 32A وكابلات نحاس 4مم من المنطقة الصناعية إلى مارينا لوسيل.',
      pickupLocation: 'المنطقة الصناعية - شارع 10 (شركة الدوحة للكهرباء)',
      deliveryLocation: 'مارينا لوسيل - برج B',
      deliveryArea: 'لوسيل',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      itemNotes: 'مطلوب فاتورة ضريبية معتمدة وختم الوكيل على الكرتون.',
      estimatedQar: 480,
      maxCapQar: 550,
      feeBudgetQar: 60,
      status: 'open',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ minutes: 20 }),
      updatedAt: ago({ minutes: 20 }),
      scheduledBy: ahead({ hours: 3 }),
    }),
    // 2. offer_received (Account 1 -> 2 competing offers from uid2 & ALT_PROVIDER_ID)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_02_offers',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'plumbing',
      title: 'مواسير سباكة PPR إيطالية 32مم ومحابس نحاس | Italian PPR Plumbing Pipes',
      description:
        'شراء 25 ماسورة PPR إيطالية مقاس 32مم PN20 مع 6 محابس نحاس أصلية وتوصيلها لمشروع مشيرب.',
      pickupLocation: 'طريق سلوى - مجمع الدوحة للسباكة',
      deliveryLocation: 'مشيرب قلب الدوحة - مبنى 4',
      deliveryArea: 'الدوحة',
      siteContactName: 'سالم الكواري',
      siteContactPhone: '55901122',
      itemNotes: 'مقارنة عروض المزودين المعتمدين واختيار الأنسب وقتاً وسعراً.',
      estimatedQar: 360,
      maxCapQar: 420,
      feeBudgetQar: 55,
      status: 'offer_received',
      offerCount: 2,
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 2 }),
      updatedAt: ago({ minutes: 12 }),
      scheduledBy: ahead({ hours: 4 }),
    }),
    // 3. offer_selected (Account 1 -> uid2 selected)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_03_offer_sel',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'tools',
      title: 'مثقاب خرسانة Makita SDS-Plus وطقم ريش | Makita Hammer Drill',
      description:
        'توريد مثقاب خرسانة Makita أصلي مع طقم ريش 8-16مم وقرص قطع ألماس لورشة التركيبات.',
      pickupLocation: 'طريق سلوى - وكيل معدات البناء',
      deliveryLocation: 'مارينا لوسيل - برج B',
      deliveryArea: 'لوسيل',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 760,
      maxCapQar: 840,
      feeBudgetQar: 65,
      agreedFeeQar: 55,
      selectedOfferId: 'demo_ma_off_03',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 1,
      status: 'offer_selected',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 4 }),
      updatedAt: ago({ minutes: 45 }),
    }),
    // 4. accepted (handover code K7M4P9)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_04_accepted',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'safety_ppe',
      title: 'خوذات سلامة PPE وسترات عاكسة (20 طقم) | Safety PPE Helmets & Vests',
      description:
        'توريد 20 خوذة سلامة معتمدة وسترات عاكسة وأحذية أمان لفريق الصيانة في موقع الخور.',
      pickupLocation: 'المنطقة الصناعية - مركز الخليج للسلامة المهنية',
      deliveryLocation: 'الخور - بوابة المشروع اللوجستية 3',
      deliveryArea: 'الخور',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 520,
      maxCapQar: 580,
      feeBudgetQar: 75,
      agreedFeeQar: 70,
      selectedOfferId: 'demo_ma_off_04',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 1,
      status: 'accepted',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_ma_wr_04_qnb.jpg',
      paymentReference: 'QNB-2026-50401',
      createdAt: ago({ hours: 6 }),
      updatedAt: ago({ hours: 2 }),
    }),
    // 5. in_progress (handover code Q9R3W8)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_05_in_prog',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'civil_materials',
      title: 'أكياس أسمنت قطري وجبس مقاوم للرطوبة | Cement & Gypsum Bags',
      description:
        'شراء 25 كيس أسمنت قطري و15 كيس جبس مقاوم للرطوبة من شارع 10 بالمنطقة الصناعية.',
      pickupLocation: 'المنطقة الصناعية - شارع 10 مستودع مواد البناء',
      deliveryLocation: 'مشيرب قلب الدوحة - مبنى 4',
      deliveryArea: 'الدوحة',
      siteContactName: 'سالم الكواري',
      siteContactPhone: '55901122',
      estimatedQar: 440,
      maxCapQar: 500,
      feeBudgetQar: 65,
      agreedFeeQar: 60,
      selectedOfferId: 'demo_ma_off_05',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 1,
      status: 'in_progress',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 7 }),
      updatedAt: ago({ hours: 1, minutes: 20 }),
    }),
    // 6. picked_up (handover code M4N8X2)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_06_picked_up',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'hvac',
      title: 'غاز فريون R410A ومواسير نحاس للتكييف | AC Refrigerant & Copper Tubing',
      description:
        'توريد أسطوانتي غاز فريون R410A أصلي مع 3 لفات مواسير نحاس معزولة وفاتورة المتجر.',
      pickupLocation: 'طريق سلوى - مركز التبريد والتكييف',
      deliveryLocation: 'الريان - مجمع الفلل السكنية بوابة 2',
      deliveryArea: 'الريان',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 610,
      maxCapQar: 680,
      feeBudgetQar: 55,
      agreedFeeQar: 50,
      actualReceiptQar: 595,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_ma_wr_06.jpg',
      selectedOfferId: 'demo_ma_off_06',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 1,
      status: 'picked_up',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_ma_wr_06_cbq.jpg',
      paymentReference: 'CBQ-2026-50602',
      createdAt: ago({ hours: 9 }),
      updatedAt: ago({ minutes: 55 }),
    }),
    // 7. in_transit (handover code H6P2V5)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_07_in_transit',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'electrical',
      title: 'كشافات LED مقاومة للماء 150W لمارينا لوسيل | IP66 LED Floodlights',
      description:
        'توريد 10 كشافات LED مقاومة للماء IP66 بقوة 150W للعمل الليلي في موقع مارينا لوسيل.',
      pickupLocation: 'المنطقة الصناعية - شارع 10 معرض الإنارة',
      deliveryLocation: 'مارينا لوسيل - برج B',
      deliveryArea: 'لوسيل',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 490,
      maxCapQar: 540,
      feeBudgetQar: 55,
      agreedFeeQar: 50,
      actualReceiptQar: 475,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_ma_wr_07.jpg',
      selectedOfferId: 'demo_ma_off_07',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 2,
      status: 'in_transit',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 11 }),
      updatedAt: ago({ minutes: 25 }),
    }),
    // 8. delivered_pending_confirmation (handover code T5K9B3)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_08_deliv_pend',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'safety_ppe',
      title: 'إعادة تعبئة طفايات حريق وحساسات دخان | Fire Extinguisher Refill & Sensors',
      description:
        'وصلت الشحنة مع الفاتورة الأصلية لبوابة المدينة التعليمية بانتظار تأكيد رمز التسليم T5K9B3 أو مسح QR.',
      pickupLocation: 'الدوحة - شارع المطار التجاري مركز السلامة',
      deliveryLocation: 'الريان - المدينة التعليمية بوابة الصيانة 6',
      deliveryArea: 'الريان',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      itemNotes: 'رمز تأكيد التسليم السري: T5K9B3 لإغلاق المهمة فوراً.',
      estimatedQar: 540,
      maxCapQar: 600,
      feeBudgetQar: 65,
      agreedFeeQar: 60,
      actualReceiptQar: 525,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_ma_wr_08.jpg',
      selectedOfferId: 'demo_ma_off_08',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 2,
      status: 'delivered_pending_confirmation',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_ma_wr_08_fawran.jpg',
      paymentReference: 'FAWRAN-2026-50803',
      createdAt: ago({ hours: 14 }),
      updatedAt: ago({ minutes: 10 }),
    }),
    // 9. completed (bank_transfer_manual + verified_settled + 5-star rating)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_09_comp_bank',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'electrical',
      title: 'كابلات طاقة مدرعة 16مم وقواطع رئيسية | Armored 16mm Power Cables',
      description:
        'توريد كابلات طاقة مدرعة وقواطع رئيسية مع فاتورة ضريبية معتمدة وتسوية تحويل بنكي مكتملة.',
      pickupLocation: 'المنطقة الصناعية - شارع 14 مستودع الكابلات',
      deliveryLocation: 'مارينا لوسيل - برج B',
      deliveryArea: 'لوسيل',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 850,
      maxCapQar: 920,
      feeBudgetQar: 80,
      agreedFeeQar: 75,
      actualReceiptQar: 840,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_ma_wr_09.jpg',
      selectedOfferId: 'demo_ma_off_09',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 2,
      isHandoverVerified: true,
      status: 'completed',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'verified_settled',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_ma_wr_09_qnb.jpg',
      paymentReference: 'QNB-2026-50904',
      createdAt: ago({ days: 2 }),
      updatedAt: ago({ days: 1, hours: 18 }),
    }),
    // 10. completed (cash_on_delivery -> ready for Quick Reorder!)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_10_comp_cod',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'hardware',
      title: 'مرابط تثبيت فولاذية وأقراص جلي وتقطيع | Steel Anchors & Cutting Discs',
      description:
        'طلب توريد مستهلكات ورشة مكتمل بالدفع النقدي عند الاستلام وجاهز لإعادة الطلب السريع.',
      pickupLocation: 'طريق سلوى - سوق العدد والأدوات',
      deliveryLocation: 'مشيرب قلب الدوحة - مبنى 4',
      deliveryArea: 'الدوحة',
      siteContactName: 'سالم الكواري',
      siteContactPhone: '55901122',
      estimatedQar: 310,
      maxCapQar: 360,
      feeBudgetQar: 45,
      agreedFeeQar: 40,
      actualReceiptQar: 300,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_ma_wr_10.jpg',
      selectedOfferId: 'demo_ma_off_10',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 1,
      isHandoverVerified: true,
      status: 'completed',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'verified_settled',
      paymentReference: 'COD-2026-51005',
      createdAt: ago({ days: 4 }),
      updatedAt: ago({ days: 3, hours: 20 }),
    }),
    // 11. disputed (disputed tile delivery under review)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_11_disputed',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'civil_materials',
      title: 'بلاط بورسلان رمادي 60×60 ولاصق سيراميك | Grey Porcelain Tiles & Adhesive',
      description:
        'توريد 18 كرتون بلاط بورسلان رمادي مطفي 60×60 مع لاصق سيراميك لغرفة الاستقبال في الوكرة.',
      pickupLocation: 'المنطقة الصناعية - شارع 24 مستودع السيراميك',
      deliveryLocation: 'الوكرة - مبنى الخدمات الإدارية قطاع 4',
      deliveryArea: 'الوكرة',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 640,
      maxCapQar: 700,
      feeBudgetQar: 70,
      agreedFeeQar: 65,
      actualReceiptQar: 630,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_ma_wr_11.jpg',
      selectedOfferId: 'demo_ma_off_11',
      assignedProviderId: uid2,
      assignedProviderName: 'حمد المري',
      offerCount: 1,
      disputeReason:
        'وصول 3 كراتين بلون مختلف عن الكود المطلوب في الفاتورة — قيد المراجعة مع الدعم | 3 boxes delivered in wrong color batch.',
      status: 'disputed',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'disputed',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_ma_wr_11_qnb.jpg',
      paymentReference: 'QNB-2026-51106',
      createdAt: ago({ days: 1, hours: 5 }),
      updatedAt: ago({ hours: 3 }),
    }),
    // 12. cancelled (cancelled request)
    makeWorkRequestDoc({
      id: 'demo_ma_wr_12_cancelled',
      requesterId: uid1,
      requesterName: 'م. خالد الكواري',
      supplyCategory: 'general_site_supply',
      title: 'لفات بلاستيك حماية أرضيات وشريط تحذير | Floor Protection Rolls & Tape',
      description: 'توريد 12 لفة نايلون حماية للأرضيات قبل أعمال الدهان في موقع مارينا لوسيل.',
      pickupLocation: 'طريق سلوى - سوق الجملة لمواد التغليف',
      deliveryLocation: 'مارينا لوسيل - برج B',
      deliveryArea: 'لوسيل',
      siteContactName: 'م. خالد الكواري',
      siteContactPhone: '55102030',
      estimatedQar: 240,
      maxCapQar: 280,
      feeBudgetQar: 40,
      cancellationReason:
        'تم تأمين المواد من مستودع الشركة الداخلي قبل الترسية | Sourced internally from company warehouse.',
      status: 'cancelled',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ days: 5 }),
      updatedAt: ago({ days: 4, hours: 21 }),
    }),
    // 13. open request owned by Account 3 (نورة العطية) for marketplace variety!
    makeWorkRequestDoc({
      id: 'demo_ma_wr_13_open_noura',
      requesterId: uid3,
      requesterName: 'نورة العطية',
      supplyCategory: 'general_site_supply',
      title: 'مستلزمات تجهيز معرض تصميم داخلي في الوكرة | Interior Studio Setup Supplies',
      description:
        'مطلوب شراء كشافات عرض مكتبية ولوحات تثبيت ومستلزمات تغليف من إيكيا/طريق سلوى وتوصيلها لمكتب الوكرة.',
      pickupLocation: 'طريق سلوى - معرض مستلزمات الديكور',
      deliveryLocation: 'الوكرة - مجمع المكاتب الإدارية الطابق 2',
      deliveryArea: 'الوكرة',
      siteContactName: 'نورة العطية',
      siteContactPhone: '66708090',
      itemNotes: 'التوصيل لمكتب الاستقبال الأرضي مع الفاتورة الأصلية.',
      estimatedQar: 320,
      maxCapQar: 380,
      feeBudgetQar: 45,
      status: 'open',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ minutes: 35 }),
      updatedAt: ago({ minutes: 35 }),
      scheduledBy: ahead({ hours: 5 }),
    }),
  ];

  // 6. Work Offers
  function makeOfferDoc({
    id,
    requestId,
    providerId,
    providerName,
    providerRating,
    providerCompletedJobs,
    feeQar,
    itemsQar,
    etaMinutes,
    notes,
    isSelected,
    status,
    createdAt,
    updatedAt,
  }) {
    const serviceFeeMinor = qarMinor(feeQar);
    const estimatedItemsCostMinor = qarMinor(itemsQar);
    return {
      docPath: `work_offers/${id}`,
      collectionKey: 'work_offers',
      data: {
        id,
        requestId,
        providerId,
        providerName,
        providerRating: dbl(providerRating),
        providerCompletedJobs,
        totalAmountMinor: estimatedItemsCostMinor + serviceFeeMinor,
        serviceFeeMinor,
        estimatedItemsCostMinor,
        etaMinutes,
        notes,
        isSelected,
        status,
        createdAt: ts(createdAt),
        updatedAt: ts(updatedAt),
      },
    };
  }

  const workOfferDocs = [
    // 2 competing pending offers on demo_ma_wr_02_offers (from uid2 and ALT_PROVIDER_ID)
    makeOfferDoc({
      id: 'demo_ma_off_02_prov',
      requestId: 'demo_ma_wr_02_offers',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 45,
      itemsQar: 350,
      etaMinutes: 35,
      notes: 'متواجد قرب طريق سلوى بالبيك أب، التوصيل لمشيرب خلال 35 دقيقة مع فاتورة ضريبية.',
      isSelected: false,
      status: 'pending',
      createdAt: ago({ minutes: 45 }),
      updatedAt: ago({ minutes: 45 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_02_alt',
      requestId: 'demo_ma_wr_02_offers',
      providerId: ALT_PROVIDER_ID,
      providerName: ALT_PROVIDER_NAME,
      providerRating: 4.82,
      providerCompletedJobs: 21,
      feeQar: 50,
      itemsQar: 360,
      etaMinutes: 45,
      notes: 'خبرة في توريد مستلزمات السباكة الإيطالية PN20 مع تغليف وحماية للمحابس.',
      isSelected: false,
      status: 'pending',
      createdAt: ago({ minutes: 20 }),
      updatedAt: ago({ minutes: 20 }),
    }),
    // Accepted offers for requests 03..11
    makeOfferDoc({
      id: 'demo_ma_off_03',
      requestId: 'demo_ma_wr_03_offer_sel',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 55,
      itemsQar: 760,
      etaMinutes: 40,
      notes: 'تأكدت من توفر المثقاب الأصلي Makita لدى الوكيل وجاهز للتحرك فوراً.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 3 }),
      updatedAt: ago({ minutes: 45 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_04',
      requestId: 'demo_ma_wr_04_accepted',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 70,
      itemsQar: 520,
      etaMinutes: 55,
      notes: 'توريد معدات السلامة المعتمدة وتوصيلها مباشرة لبوابة الخور.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 5 }),
      updatedAt: ago({ hours: 3 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_05',
      requestId: 'demo_ma_wr_05_in_prog',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 60,
      itemsQar: 440,
      etaMinutes: 45,
      notes: 'جارٍ تحميل أكياس الأسمنت والجبس من شارع 10 بالمنطقة الصناعية.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 6 }),
      updatedAt: ago({ hours: 5 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_06',
      requestId: 'demo_ma_wr_06_picked_up',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 50,
      itemsQar: 595,
      etaMinutes: 35,
      notes: 'تم الشراء من مركز التبريد ورفع الفاتورة الأصلية بقيمة 595 ر.ق.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 8 }),
      updatedAt: ago({ hours: 7 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_07',
      requestId: 'demo_ma_wr_07_in_transit',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 50,
      itemsQar: 475,
      etaMinutes: 30,
      notes: 'في الطريق الآن نحو مارينا لوسيل - برج B.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 10 }),
      updatedAt: ago({ hours: 9 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_08',
      requestId: 'demo_ma_wr_08_deliv_pend',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 60,
      itemsQar: 525,
      etaMinutes: 40,
      notes: 'تم الوصول لبوابة المدينة التعليمية بانتظار تأكيد التسليم.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 13 }),
      updatedAt: ago({ hours: 11 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_09',
      requestId: 'demo_ma_wr_09_comp_bank',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 75,
      itemsQar: 840,
      etaMinutes: 45,
      notes: 'توريد الكابلات المدرعة إلى مارينا لوسيل.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ days: 2 }),
      updatedAt: ago({ days: 1, hours: 18 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_10',
      requestId: 'demo_ma_wr_10_comp_cod',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 40,
      itemsQar: 300,
      etaMinutes: 35,
      notes: 'توريد مستلزمات الورشة إلى مشيرب.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ days: 4 }),
      updatedAt: ago({ days: 3, hours: 20 }),
    }),
    makeOfferDoc({
      id: 'demo_ma_off_11',
      requestId: 'demo_ma_wr_11_disputed',
      providerId: uid2,
      providerName: 'حمد المري',
      providerRating: 4.95,
      providerCompletedJobs: 34,
      feeQar: 65,
      itemsQar: 630,
      etaMinutes: 50,
      notes: 'توصيل شحنة البورسلان إلى الوكرة.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ days: 1, hours: 4 }),
      updatedAt: ago({ days: 1, hours: 2 }),
    }),
  ];

  // 7. Handover Secrets & Requester-Scoped Handover Views (Salted SHA-256)
  const expiresDate = ahead({ hours: 24 });
  const expiresAtUtc = expiresDate.toISOString();
  const reqMap = new Map(workRequestDocs.map((d) => [d.data.id, d.data]));

  const secretDocs = [];
  const handoverViewDocs = [];
  for (const [requestId, plainCode] of Object.entries(HANDOVER_CODES)) {
    const req = reqMap.get(requestId);
    const codeSalt = deterministicSaltForRequest(requestId);
    const codeHash = hashHandoverCode(plainCode, codeSalt);
    secretDocs.push({
      docPath: `work_request_secrets/${requestId}`,
      collectionKey: 'work_request_secrets',
      data: {
        requestId,
        codeHash,
        codeSalt,
        expiresAtUtc,
        expiresAt: ts(expiresDate),
        attemptsRemaining: 5,
        maxAttempts: 5,
        usedAtUtc: null,
        createdAt: ts(now),
        updatedAt: ts(now),
      },
    });
    handoverViewDocs.push({
      docPath: `work_request_handover_view/${requestId}`,
      collectionKey: 'work_request_handover_view',
      data: {
        requestId,
        requesterId: req.requesterId,
        handoverCode: plainCode,
        expiresAtUtc,
        expiresAt: ts(expiresDate),
        createdAt: ts(now),
        updatedAt: ts(now),
      },
    });
  }

  // 8. Request Events (Lifecycle audit trail)
  function makeEvent({
    id,
    requestId,
    actorId,
    actorRole,
    eventType,
    fromStatus = null,
    toStatus,
    note,
    metadata = null,
    createdAt,
  }) {
    return {
      docPath: `request_events/${id}`,
      collectionKey: 'request_events',
      data: {
        id,
        requestId,
        actorId,
        actorRole,
        type: eventType,
        eventType,
        fromStatus,
        toStatus,
        note,
        ...(metadata ? { metadata } : {}),
        createdAt: ts(createdAt),
      },
    };
  }

  const requestEventDocs = [
    makeEvent({
      id: 'demo_ma_evt_01_1',
      requestId: 'demo_ma_wr_01_open',
      actorId: uid1,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم نشر طلب اللوحات الكهربائية لموقع مارينا لوسيل بانتظار عروض المزودين.',
      createdAt: ago({ minutes: 20 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_02_1',
      requestId: 'demo_ma_wr_02_offers',
      actorId: uid1,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم إنشاء طلب مواسير السباكة الإيطالية لمبنى مشيرب.',
      createdAt: ago({ hours: 2 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_02_2',
      requestId: 'demo_ma_wr_02_offers',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'offer_submitted',
      fromStatus: 'open',
      toStatus: 'offer_received',
      note: 'تم تقديم عرضين تنافسيين من حمد المري وسعد المهندي للتوريدات.',
      metadata: { offerId: 'demo_ma_off_02_prov', feeMinor: 4500 },
      createdAt: ago({ minutes: 45 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_03_1',
      requestId: 'demo_ma_wr_03_offer_sel',
      actorId: uid1,
      actorRole: 'requester',
      eventType: 'offer_selected',
      fromStatus: 'offer_received',
      toStatus: 'offer_selected',
      note: 'تم اختيار عرض حمد المري لتوريد مثقاب Makita.',
      metadata: { offerId: 'demo_ma_off_03', feeMinor: 5500 },
      createdAt: ago({ minutes: 45 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_04_1',
      requestId: 'demo_ma_wr_04_accepted',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'offer_accepted',
      fromStatus: 'offer_selected',
      toStatus: 'accepted',
      note: 'تم قبول مهمة توريد معدات السلامة وإصدار رمز التسليم السري.',
      createdAt: ago({ hours: 3 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_05_1',
      requestId: 'demo_ma_wr_05_in_prog',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'accepted',
      toStatus: 'in_progress',
      note: 'المزود حمد المري متواجد في شارع 10 بالمنطقة الصناعية لشراء الأسمنت والجبس.',
      createdAt: ago({ hours: 1, minutes: 20 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_06_1',
      requestId: 'demo_ma_wr_06_picked_up',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'in_progress',
      toStatus: 'picked_up',
      note: 'تم شراء الفريون ومواسير النحاس وإرفاق فاتورة المتجر (595 ر.ق).',
      createdAt: ago({ minutes: 55 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_07_1',
      requestId: 'demo_ma_wr_07_in_transit',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'picked_up',
      toStatus: 'in_transit',
      note: 'الشحنة في الطريق عبر طريق لوسيل السريع نحو برج B.',
      createdAt: ago({ minutes: 25 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_08_1',
      requestId: 'demo_ma_wr_08_deliv_pend',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'in_transit',
      toStatus: 'delivered_pending_confirmation',
      note: 'وصل المزود إلى بوابة المدينة التعليمية بانتظار تأكيد التسليم بالرمز T5K9B3.',
      createdAt: ago({ minutes: 10 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_09_1',
      requestId: 'demo_ma_wr_09_comp_bank',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'handover_completed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'completed',
      note: 'تم التحقق من رمز التسليم وتوثيق التحويل البنكي QNB-2026-50904.',
      createdAt: ago({ days: 1, hours: 18 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_10_1',
      requestId: 'demo_ma_wr_10_comp_cod',
      actorId: uid2,
      actorRole: 'provider',
      eventType: 'handover_completed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'completed',
      note: 'تم التسليم والتحصيل النقدي في مشيرب قلب الدوحة بنجاح.',
      createdAt: ago({ days: 3, hours: 20 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_11_1',
      requestId: 'demo_ma_wr_11_disputed',
      actorId: uid1,
      actorRole: 'requester',
      eventType: 'status_changed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'disputed',
      note: 'تم فتح نزاع بخصوص اختلاف درجة لون 3 كراتين بورسلان للمراجعة.',
      createdAt: ago({ hours: 3 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_12_1',
      requestId: 'demo_ma_wr_12_cancelled',
      actorId: uid1,
      actorRole: 'requester',
      eventType: 'status_changed',
      fromStatus: 'open',
      toStatus: 'cancelled',
      note: 'أُلغي الطلب بعد تأمين المواد من المستودع الداخلي.',
      createdAt: ago({ days: 4, hours: 21 }),
    }),
    makeEvent({
      id: 'demo_ma_evt_13_1',
      requestId: 'demo_ma_wr_13_open_noura',
      actorId: uid3,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم نشر طلب توريد مستلزمات المعرض لمكتب الوكرة.',
      createdAt: ago({ minutes: 35 }),
    }),
  ];

  // 9. Ratings (5-star rating on completed bank-transfer request)
  const ratingDocs = [
    {
      docPath: `ratings/demo_ma_wr_09_comp_bank_${uid1}`,
      collectionKey: 'ratings',
      data: {
        id: `demo_ma_wr_09_comp_bank_${uid1}`,
        requestId: 'demo_ma_wr_09_comp_bank',
        fromUserId: uid1,
        toUserId: uid2,
        fromRole: 'requester',
        toRole: 'provider',
        stars: 5,
        comment: 'دقة ممتازة في الموعد ومطابقة كاملة للفاتورة الضريبية في مارينا لوسيل.',
        tags: ['on_time', 'accurate_invoice', 'verified_handover'],
        createdAt: ts(ago({ days: 1, hours: 17 })),
      },
    },
  ];

  // 10. Shared Rides (4 by uid2 + 2 Ladies-Only by uid3 = 6 active rides)
  const rideDocs = [
    {
      docPath: 'rides/demo_ma_ride_01',
      collectionKey: 'rides',
      data: {
        id: 'demo_ma_ride_01',
        driverId: uid2,
        driverName: 'حمد المري',
        driverCar: 'تويوتا هايلكس 2025 · أبيض (قطر 774210)',
        driverPhone: '55405060',
        fromCity: 'الدوحة',
        toCity: 'الخور',
        pickupPoint: 'محطة مترو مشيرب - البوابة الرئيسية',
        dropoffPoint: 'كورنيش الخور - دوار الخور',
        departureTime: '07:30 صباحاً',
        departureDate: 'غداً',
        remainingSeats: 2,
        pricePerSeat: 35,
        acceptsParcels: true,
        parcelPrice: 20,
        isVerified: true,
        isLadiesOnly: false,
        isInstantBooking: true,
        driverRating: dbl(4.95),
        status: 'active',
        createdAt: ts(ago({ hours: 5 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'rides/demo_ma_ride_02',
      collectionKey: 'rides',
      data: {
        id: 'demo_ma_ride_02',
        driverId: uid2,
        driverName: 'حمد المري',
        driverCar: 'تويوتا هايلكس 2025 · أبيض (قطر 774210)',
        driverPhone: '55405060',
        fromCity: 'الدوحة',
        toCity: 'الوكرة',
        pickupPoint: 'الخليج الغربي - محطة مترو الدفنة',
        dropoffPoint: 'سوق الوكرة القديم - البوابة الشمالية',
        departureTime: '04:30 مساءً',
        departureDate: 'اليوم',
        remainingSeats: 3,
        pricePerSeat: 25,
        acceptsParcels: true,
        parcelPrice: 15,
        isVerified: true,
        isLadiesOnly: false,
        isInstantBooking: true,
        driverRating: dbl(4.95),
        status: 'active',
        createdAt: ts(ago({ hours: 4 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'rides/demo_ma_ride_03',
      collectionKey: 'rides',
      data: {
        id: 'demo_ma_ride_03',
        driverId: uid2,
        driverName: 'حمد المري',
        driverCar: 'تويوتا هايلكس 2025 · أبيض (قطر 774210)',
        driverPhone: '55405060',
        fromCity: 'لوسيل',
        toCity: 'المنطقة الصناعية',
        pickupPoint: 'مارينا لوسيل - محطة الترام',
        dropoffPoint: 'المنطقة الصناعية - تقاطع شارع 10',
        departureTime: '08:00 صباحاً',
        departureDate: 'غداً',
        remainingSeats: 2,
        pricePerSeat: 30,
        acceptsParcels: true,
        parcelPrice: 20,
        isVerified: true,
        isLadiesOnly: false,
        isInstantBooking: false,
        driverRating: dbl(4.95),
        status: 'active',
        createdAt: ts(ago({ hours: 3 })),
        updatedAt: ts(ago({ minutes: 40 })),
      },
    },
    {
      docPath: 'rides/demo_ma_ride_04',
      collectionKey: 'rides',
      data: {
        id: 'demo_ma_ride_04',
        driverId: uid2,
        driverName: 'حمد المري',
        driverCar: 'تويوتا هايلكس 2025 · أبيض (قطر 774210)',
        driverPhone: '55405060',
        fromCity: 'الدوحة',
        toCity: 'دخان',
        pickupPoint: 'طريق سلوى - مجمع فيلاجيو',
        dropoffPoint: 'دخان - المدخل الرئيسي',
        departureTime: '06:30 صباحاً',
        departureDate: 'الخميس القادم',
        remainingSeats: 3,
        pricePerSeat: 45,
        acceptsParcels: true,
        parcelPrice: 25,
        isVerified: true,
        isLadiesOnly: false,
        isInstantBooking: false,
        driverRating: dbl(4.95),
        status: 'active',
        createdAt: ts(ago({ hours: 2 })),
        updatedAt: ts(ago({ minutes: 30 })),
      },
    },
    {
      docPath: 'rides/demo_ma_ride_05_ladies',
      collectionKey: 'rides',
      data: {
        id: 'demo_ma_ride_05_ladies',
        driverId: uid3,
        driverName: 'نورة العطية',
        driverCar: 'كيا سبورتاج 2024 · فضي (قطر 518390)',
        driverPhone: '66708090',
        fromCity: 'لوسيل',
        toCity: 'المدينة التعليمية',
        pickupPoint: 'بوليفارد لوسيل - البوابة الجنوبية',
        dropoffPoint: 'المدينة التعليمية - مكتبة قطر الوطنية',
        departureTime: '08:15 صباحاً',
        departureDate: 'غداً',
        remainingSeats: 3,
        pricePerSeat: 25,
        acceptsParcels: true,
        parcelPrice: 15,
        isVerified: true,
        isLadiesOnly: true,
        isInstantBooking: true,
        driverRating: dbl(4.85),
        status: 'active',
        createdAt: ts(ago({ hours: 3 })),
        updatedAt: ts(ago({ minutes: 30 })),
      },
    },
    {
      docPath: 'rides/demo_ma_ride_06_ladies',
      collectionKey: 'rides',
      data: {
        id: 'demo_ma_ride_06_ladies',
        driverId: uid3,
        driverName: 'نورة العطية',
        driverCar: 'كيا سبورتاج 2024 · فضي (قطر 518390)',
        driverPhone: '66708090',
        fromCity: 'الوكرة',
        toCity: 'الخليج الغربي',
        pickupPoint: 'محطة مترو الوكرة',
        dropoffPoint: 'أبراج الخليج الغربي - بوابة سيتي سنتر',
        departureTime: '07:45 صباحاً',
        departureDate: 'غداً',
        remainingSeats: 2,
        pricePerSeat: 20,
        acceptsParcels: true,
        parcelPrice: 15,
        isVerified: true,
        isLadiesOnly: true,
        isInstantBooking: true,
        driverRating: dbl(4.85),
        status: 'active',
        createdAt: ts(ago({ hours: 2 })),
        updatedAt: ts(ago({ minutes: 15 })),
      },
    },
  ];

  // 11. Bookings for Account 1 (1 confirmed + 1 completed)
  const bookingDocs = [
    {
      docPath: 'bookings/demo_ma_bk_01_confirmed',
      collectionKey: 'bookings',
      data: {
        id: 'demo_ma_bk_01_confirmed',
        rideId: 'demo_ma_ride_01',
        passengerId: uid1,
        passengerName: 'م. خالد الكواري',
        passengerPhone: '55102030',
        driverId: uid2,
        seats: 1,
        totalPrice: 35,
        pickupLocation: 'محطة مترو مشيرب - البوابة الرئيسية',
        dropoffLocation: 'كورنيش الخور - دوار الخور',
        status: 'confirmed',
        otpCode: '4821',
        createdAt: ts(ago({ hours: 2 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'bookings/demo_ma_bk_02_completed',
      collectionKey: 'bookings',
      data: {
        id: 'demo_ma_bk_02_completed',
        rideId: 'demo_ma_ride_02',
        passengerId: uid1,
        passengerName: 'م. خالد الكواري',
        passengerPhone: '55102030',
        driverId: uid2,
        seats: 1,
        totalPrice: 25,
        pickupLocation: 'الخليج الغربي - محطة مترو الدفنة',
        dropoffLocation: 'سوق الوكرة القديم - البوابة الشمالية',
        status: 'completed',
        otpCode: '3190',
        createdAt: ts(ago({ days: 3 })),
        updatedAt: ts(ago({ days: 2 })),
      },
    },
  ];

  // 12. Parcels (5 interconnected parcels covering ALL 5 statuses)
  const parcelDocs = [
    {
      docPath: 'parcels/demo_ma_pcl_01_requested',
      collectionKey: 'parcels',
      data: {
        id: 'demo_ma_pcl_01_requested',
        senderId: uid3,
        senderName: 'نورة العطية',
        senderPhone: '66708090',
        receiverName: 'مريم الخاطر',
        receiverPhone: '66812233',
        route: 'لوسيل ← الوكرة',
        fromCity: 'لوسيل',
        toCity: 'الوكرة',
        description: 'عينات أقمشة وتصاميم هندسية مغلفة بعناية',
        size: 'small',
        weightKg: dbl(1.5),
        estimatedValue: 180,
        fee: 25,
        pickupOtp: '2940',
        deliveryOtp: '6412',
        status: 'requested',
        createdAt: ts(ago({ hours: 2 })),
        updatedAt: ts(ago({ hours: 2 })),
      },
    },
    {
      docPath: 'parcels/demo_ma_pcl_02_accepted',
      collectionKey: 'parcels',
      data: {
        id: 'demo_ma_pcl_02_accepted',
        senderId: uid1,
        senderName: 'م. خالد الكواري',
        senderPhone: '55102030',
        driverId: uid2,
        driverName: 'حمد المري',
        receiverName: 'م. جاسم المهندي',
        receiverPhone: '55667788',
        route: 'الدوحة ← الخور',
        fromCity: 'الدوحة',
        toCity: 'الخور',
        description: 'جهاز قياس ليزر ومخططات موقع معتمدة',
        size: 'medium',
        weightKg: dbl(4.2),
        estimatedValue: 650,
        fee: 30,
        pickupOtp: '5142',
        deliveryOtp: '8390',
        status: 'accepted',
        createdAt: ts(ago({ hours: 4 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'parcels/demo_ma_pcl_03_handed_over',
      collectionKey: 'parcels',
      data: {
        id: 'demo_ma_pcl_03_handed_over',
        senderId: uid1,
        senderName: 'م. خالد الكواري',
        senderPhone: '55102030',
        driverId: uid2,
        driverName: 'حمد المري',
        receiverName: 'سالم الكواري',
        receiverPhone: '55901122',
        route: 'المنطقة الصناعية ← لوسيل',
        fromCity: 'المنطقة الصناعية',
        toCity: 'لوسيل',
        description: 'صندوق قطع غيار ميكانيكية لمضخة المياه',
        size: 'large',
        weightKg: dbl(8.5),
        estimatedValue: 1200,
        fee: 45,
        pickupOtp: '6214',
        deliveryOtp: '9103',
        submittedOtp: '6214',
        status: 'handedOver',
        createdAt: ts(ago({ hours: 6 })),
        updatedAt: ts(ago({ hours: 1, minutes: 30 })),
      },
    },
    {
      docPath: 'parcels/demo_ma_pcl_04_in_transit',
      collectionKey: 'parcels',
      data: {
        id: 'demo_ma_pcl_04_in_transit',
        senderId: uid3,
        senderName: 'نورة العطية',
        senderPhone: '66708090',
        driverId: uid2,
        driverName: 'حمد المري',
        receiverName: 'شيخة النعيمي',
        receiverPhone: '77223344',
        route: 'الدوحة ← دخان',
        fromCity: 'الدوحة',
        toCity: 'دخان',
        description: 'مظروف عقود ومستندات رسمية مختومة',
        size: 'envelope',
        weightKg: dbl(0.4),
        estimatedValue: 100,
        fee: 25,
        pickupOtp: '3319',
        deliveryOtp: '7724',
        submittedOtp: '3319',
        status: 'inTransit',
        createdAt: ts(ago({ hours: 8 })),
        updatedAt: ts(ago({ minutes: 35 })),
      },
    },
    {
      docPath: 'parcels/demo_ma_pcl_05_delivered',
      collectionKey: 'parcels',
      data: {
        id: 'demo_ma_pcl_05_delivered',
        senderId: uid1,
        senderName: 'م. خالد الكواري',
        senderPhone: '55102030',
        driverId: uid2,
        driverName: 'حمد المري',
        receiverName: 'م. طارق الكواري',
        receiverPhone: '55224466',
        route: 'الدوحة ← الوكرة',
        fromCity: 'الدوحة',
        toCity: 'الوكرة',
        description: 'طقم مفاتيح معايرة وأجهزة اختبار كهربائي',
        size: 'small',
        weightKg: dbl(2.0),
        estimatedValue: 320,
        fee: 20,
        pickupOtp: '1845',
        deliveryOtp: '5092',
        submittedOtp: '1845',
        status: 'delivered',
        createdAt: ts(ago({ days: 2 })),
        updatedAt: ts(ago({ days: 1, hours: 19 })),
      },
    },
  ];

  // 13. Community Board Ads (6 ads across uid1, uid2, uid3)
  const boardAdDocs = [
    {
      docPath: 'board_ads/demo_ma_ad_01',
      collectionKey: 'board_ads',
      data: {
        id: 'demo_ma_ad_01',
        authorId: uid1,
        type: 'rideRequest',
        authorName: 'م. خالد الكواري',
        isVerified: true,
        tripCount: 8,
        postedAgo: 'منذ 15 دقيقة',
        fromCity: 'لوسيل',
        toCity: 'الخور',
        timeText: 'غداً الساعة 08:00 صباحاً',
        description: 'أبحث عن مقعد مشترك هادئ من مارينا لوسيل إلى الخور لحضور اجتماع موقع.',
        priceOrBudget: 35,
        notes: 'يفضل الانطلاق من محطة ترام المارينا.',
        isLadiesOnly: false,
        status: 'active',
        createdAt: ts(ago({ minutes: 15 })),
        updatedAt: ts(ago({ minutes: 15 })),
      },
    },
    {
      docPath: 'board_ads/demo_ma_ad_02',
      collectionKey: 'board_ads',
      data: {
        id: 'demo_ma_ad_02',
        authorId: uid2,
        type: 'rideOffer',
        authorName: 'حمد المري',
        isVerified: true,
        tripCount: 42,
        postedAgo: 'منذ 30 دقيقة',
        fromCity: 'الدوحة',
        toCity: 'المنطقة الصناعية',
        timeText: 'يومياً 07:15 صباحاً',
        description: 'متاح مقعدان ومساحة شحن بالبيك أب من طريق سلوى إلى شارع 10 بالصناعية.',
        priceOrBudget: 30,
        notes: 'توصيل فوري للطرود الخفيفة على نفس المسار.',
        isLadiesOnly: false,
        status: 'active',
        createdAt: ts(ago({ minutes: 30 })),
        updatedAt: ts(ago({ minutes: 30 })),
      },
    },
    {
      docPath: 'board_ads/demo_ma_ad_03',
      collectionKey: 'board_ads',
      data: {
        id: 'demo_ma_ad_03',
        authorId: uid3,
        type: 'rideOffer',
        authorName: 'نورة العطية',
        isVerified: true,
        tripCount: 12,
        postedAgo: 'منذ ساعة',
        fromCity: 'لوسيل',
        toCity: 'المدينة التعليمية',
        timeText: 'أيام الدوام 08:15 صباحاً',
        description: 'رحلة سيدات فقط مريحة من بوليفارد لوسيل إلى المدينة التعليمية ومكتبة قطر الوطنية.',
        priceOrBudget: 25,
        notes: 'سيدات فقط — سيارة عائلية مكيفة وهادئة.',
        isLadiesOnly: true,
        status: 'active',
        createdAt: ts(ago({ hours: 1 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'board_ads/demo_ma_ad_04',
      collectionKey: 'board_ads',
      data: {
        id: 'demo_ma_ad_04',
        authorId: uid1,
        type: 'parcelRequest',
        authorName: 'م. خالد الكواري',
        isVerified: true,
        tripCount: 8,
        postedAgo: 'منذ ساعتين',
        fromCity: 'المنطقة الصناعية',
        toCity: 'لوسيل',
        timeText: 'اليوم قبل 05:00 مساءً',
        description: 'مطلوب توصيل كرتون عينات هندسية خفيف (3 كجم) من ورشة شارع 18 إلى مارينا لوسيل.',
        priceOrBudget: 35,
        notes: 'التسليم بكود OTP عند البوابة الشمالية.',
        isLadiesOnly: false,
        status: 'active',
        createdAt: ts(ago({ hours: 2 })),
        updatedAt: ts(ago({ hours: 2 })),
      },
    },
    {
      docPath: 'board_ads/demo_ma_ad_05',
      collectionKey: 'board_ads',
      data: {
        id: 'demo_ma_ad_05',
        authorId: uid3,
        type: 'errandService',
        authorName: 'نورة العطية',
        isVerified: true,
        tripCount: 12,
        postedAgo: 'منذ 3 ساعات',
        fromCity: 'الوكرة',
        toCity: 'الدوحة',
        timeText: 'اليوم خلال ساعتين',
        description: 'مهمة استلام ملفات مطبوعة ومخططات ديكور من مطبعة في الدوحة وإيصالها لمكتب الوكرة.',
        priceOrBudget: 45,
        notes: 'يوجد عرض مقدم بقيمة 40 ر.ق قيد المراجعة.',
        isLadiesOnly: true,
        status: 'offerSent',
        myOfferPrice: 40,
        createdAt: ts(ago({ hours: 3 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'board_ads/demo_ma_ad_06',
      collectionKey: 'board_ads',
      data: {
        id: 'demo_ma_ad_06',
        authorId: uid2,
        type: 'errandService',
        authorName: 'حمد المري',
        isVerified: true,
        tripCount: 42,
        postedAgo: 'منذ يومين',
        fromCity: 'طريق سلوى',
        toCity: 'الدوحة',
        timeText: 'تم التنفيذ بنجاح',
        description: 'استلام قطع غيار تكييف من وكيل طريق سلوى وتوصيلها لموقع صيانة في مشيرب.',
        priceOrBudget: 50,
        isLadiesOnly: false,
        status: 'completed',
        myOfferPrice: 50,
        createdAt: ts(ago({ days: 2 })),
        updatedAt: ts(ago({ days: 1, hours: 18 })),
      },
    },
  ];

  // Subcollection offer for demo_ma_ad_05
  const boardOfferDocs = [
    {
      docPath: 'board_ads/demo_ma_ad_05/offers/demo_ma_boff_01',
      collectionKey: 'board_offers',
      data: {
        id: 'demo_ma_boff_01',
        adId: 'demo_ma_ad_05',
        driverId: uid2,
        driverName: 'حمد المري',
        offerPrice: 40,
        timeText: 'التسليم خلال 45 دقيقة',
        status: 'pending',
        notes: 'متوجه من الدوحة إلى الوكرة ويمكنني استلام الملفات مباشرة.',
        createdAt: ts(ago({ hours: 1 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
  ];

  // 14. Route Alerts (2 for uid1 + 1 for uid3; 0 for uid4)
  const routeAlertDocs = [
    {
      docPath: 'route_alerts/demo_ma_alert_01',
      collectionKey: 'route_alerts',
      data: {
        id: 'demo_ma_alert_01',
        userId: uid1,
        fromCity: 'الدوحة',
        toCity: 'الخور',
        dateRange: 'طوال الأسبوع',
        category: 'ركاب',
        isActive: true,
        isExpired: false,
        createdAt: ts(ago({ days: 3 })),
        updatedAt: ts(ago({ hours: 2 })),
      },
    },
    {
      docPath: 'route_alerts/demo_ma_alert_02',
      collectionKey: 'route_alerts',
      data: {
        id: 'demo_ma_alert_02',
        userId: uid1,
        fromCity: 'لوسيل',
        toCity: 'مطار حمد الدولي',
        dateRange: 'نهاية الأسبوع',
        category: 'ركاب',
        isActive: true,
        isExpired: false,
        createdAt: ts(ago({ days: 2 })),
        updatedAt: ts(ago({ hours: 3 })),
      },
    },
    {
      docPath: 'route_alerts/demo_ma_alert_03',
      collectionKey: 'route_alerts',
      data: {
        id: 'demo_ma_alert_03',
        userId: uid3,
        fromCity: 'الوكرة',
        toCity: 'المدينة التعليمية',
        dateRange: 'أيام الدوام (الأحد - الخميس)',
        category: 'ركاب',
        isActive: true,
        isExpired: false,
        createdAt: ts(ago({ days: 4 })),
        updatedAt: ts(ago({ hours: 5 })),
      },
    },
  ];

  // 15. Wallet Transactions (3 for uid1 = 350 QAR, 4 for uid2 = 1280 QAR, 2 for uid3 = 220 QAR, 0 for uid4)
  const walletTransactionDocs = [
    // uid1 (450 - 35 - 65 = 350 QAR)
    {
      docPath: 'wallet_transactions/demo_ma_tx_u1_01',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u1_01',
        userId: uid1,
        amount: dbl(450.0),
        type: 'deposit',
        method: 'fawran',
        referenceNumber: 'FAWRAN-2026-10101',
        status: 'success',
        titleAr: 'شحن رصيد عبر فورا (Fawran)',
        titleEn: 'Wallet Top-up via Fawran',
        timestamp: ts(ago({ days: 5 })),
        createdAt: ts(ago({ days: 5 })),
      },
    },
    {
      docPath: 'wallet_transactions/demo_ma_tx_u1_02',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u1_02',
        userId: uid1,
        amount: dbl(-35.0),
        type: 'ridePayment',
        method: 'fawran',
        referenceNumber: 'RIDE-2026-10102',
        status: 'success',
        titleAr: 'حجز مقعد مشترك: الدوحة ← الخور',
        titleEn: 'Shared Seat Booking: Doha -> Al Khor',
        timestamp: ts(ago({ hours: 2 })),
        createdAt: ts(ago({ hours: 2 })),
      },
    },
    {
      docPath: 'wallet_transactions/demo_ma_tx_u1_03',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u1_03',
        userId: uid1,
        amount: dbl(-65.0),
        type: 'errandPayment',
        method: 'qpay',
        referenceNumber: 'SUP-2026-10103',
        status: 'success',
        titleAr: 'رسوم توريد مستلزمات موقع مشيرب',
        titleEn: 'Msheireb Worksite Supply Service Fee',
        timestamp: ts(ago({ days: 1, hours: 18 })),
        createdAt: ts(ago({ days: 1, hours: 18 })),
      },
    },
    // uid2 (500 + 540 + 165 + 75 = 1280 QAR)
    {
      docPath: 'wallet_transactions/demo_ma_tx_u2_01',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u2_01',
        userId: uid2,
        amount: dbl(500.0),
        type: 'deposit',
        method: 'fawran',
        referenceNumber: 'FAWRAN-2026-20201',
        status: 'success',
        titleAr: 'رصيد تشغيلي عبر فورا (Fawran)',
        titleEn: 'Operating Deposit via Fawran',
        timestamp: ts(ago({ days: 7 })),
        createdAt: ts(ago({ days: 7 })),
      },
    },
    {
      docPath: 'wallet_transactions/demo_ma_tx_u2_02',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u2_02',
        userId: uid2,
        amount: dbl(540.0),
        type: 'errandEarning',
        method: 'fawran',
        referenceNumber: 'SUP-2026-20202',
        status: 'success',
        titleAr: 'أرباح مهام توريد المواقع الإنشائية',
        titleEn: 'Worksite Supply Fulfilment Earnings',
        timestamp: ts(ago({ days: 1, hours: 18 })),
        createdAt: ts(ago({ days: 1, hours: 18 })),
      },
    },
    {
      docPath: 'wallet_transactions/demo_ma_tx_u2_03',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u2_03',
        userId: uid2,
        amount: dbl(165.0),
        type: 'rideEarning',
        method: 'qpay',
        referenceNumber: 'RIDE-2026-20203',
        status: 'success',
        titleAr: 'تحصيل أرباح رحلات مشتركة (الخور والوكرة)',
        titleEn: 'Shared Rides Captain Earnings',
        timestamp: ts(ago({ hours: 6 })),
        createdAt: ts(ago({ hours: 6 })),
      },
    },
    {
      docPath: 'wallet_transactions/demo_ma_tx_u2_04',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u2_04',
        userId: uid2,
        amount: dbl(75.0),
        type: 'parcelEarning',
        method: 'cash',
        referenceNumber: 'PCL-2026-20204',
        status: 'success',
        titleAr: 'أرباح توصيل طرود على الطريق',
        titleEn: 'Route Parcel Delivery Earnings',
        timestamp: ts(ago({ hours: 3 })),
        createdAt: ts(ago({ hours: 3 })),
      },
    },
    // uid3 (175 + 45 = 220 QAR)
    {
      docPath: 'wallet_transactions/demo_ma_tx_u3_01',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u3_01',
        userId: uid3,
        amount: dbl(175.0),
        type: 'deposit',
        method: 'applePay',
        referenceNumber: 'APAY-2026-30301',
        status: 'success',
        titleAr: 'شحن رصيد عبر Apple Pay',
        titleEn: 'Wallet Deposit via Apple Pay',
        timestamp: ts(ago({ days: 4 })),
        createdAt: ts(ago({ days: 4 })),
      },
    },
    {
      docPath: 'wallet_transactions/demo_ma_tx_u3_02',
      collectionKey: 'wallet_transactions',
      data: {
        id: 'demo_ma_tx_u3_02',
        userId: uid3,
        amount: dbl(45.0),
        type: 'rideEarning',
        method: 'fawran',
        referenceNumber: 'RIDE-2026-30302',
        status: 'success',
        titleAr: 'أرباح رحلة سيدات: لوسيل ← المدينة التعليمية',
        titleEn: 'Ladies-Only Ride Earning: Lusail -> Education City',
        timestamp: ts(ago({ days: 1 })),
        createdAt: ts(ago({ days: 1 })),
      },
    },
  ];

  // 16. Live Chat (1 active conversation between uid1 & uid2 + 3 messages including Google Maps link)
  const conversationDocs = [
    {
      docPath: `conversations/${CHAT_CONVERSATION_ID}`,
      collectionKey: 'conversations',
      data: {
        id: CHAT_CONVERSATION_ID,
        participantIds: [uid1, uid2],
        lastMessage:
          'وصلت نقطة الالتقاء قرب محطة مترو مشيرب، هذا الموقع المباشر: https://www.google.com/maps/search/?api=1&query=25.4357,51.4910',
        lastMessageTimestamp: ts(ago({ minutes: 8 })),
        lastSenderId: uid2,
        createdAt: ts(ago({ minutes: 35 })),
        updatedAt: ts(ago({ minutes: 8 })),
      },
    },
  ];

  const messageDocs = [
    {
      docPath: `conversations/${CHAT_CONVERSATION_ID}/messages/demo_ma_msg_01`,
      collectionKey: 'messages',
      data: {
        id: 'demo_ma_msg_01',
        conversationId: CHAT_CONVERSATION_ID,
        senderId: uid1,
        senderName: 'م. خالد الكواري',
        text: 'السلام عليكم أخ حمد، تم تأكيد حجز مقعد رحلة الدوحة ← الخور (رمز 4821). متى التجمع؟ | Assalamu Alaikum Hamad, seat confirmed for Doha -> Al Khor.',
        timestamp: ts(ago({ minutes: 35 })),
        isRead: true,
      },
    },
    {
      docPath: `conversations/${CHAT_CONVERSATION_ID}/messages/demo_ma_msg_02`,
      collectionKey: 'messages',
      data: {
        id: 'demo_ma_msg_02',
        conversationId: CHAT_CONVERSATION_ID,
        senderId: uid2,
        senderName: 'حمد المري',
        text: 'وعليكم السلام م. خالد، أهلاً بك! الانطلاق بإذن الله 07:30 صباحاً من بوابة محطة مترو مشيرب. | Welcome Eng. Khaled! Departure at 07:30 AM from Msheireb Metro Gate.',
        timestamp: ts(ago({ minutes: 20 })),
        isRead: true,
      },
    },
    {
      docPath: `conversations/${CHAT_CONVERSATION_ID}/messages/demo_ma_msg_03`,
      collectionKey: 'messages',
      data: {
        id: 'demo_ma_msg_03',
        conversationId: CHAT_CONVERSATION_ID,
        senderId: uid2,
        senderName: 'حمد المري',
        text: 'وصلت نقطة الالتقاء قرب محطة مترو مشيرب، هذا الموقع المباشر: https://www.google.com/maps/search/?api=1&query=25.4357,51.4910',
        timestamp: ts(ago({ minutes: 8 })),
        isRead: false,
      },
    },
  ];

  // 17. Owner-Scoped Notifications (uid1: 5 [3 unread, 2 read], uid2: 4 [2 unread, 2 read], uid3: 3 [1 unread, 2 read], uid4: 0)
  const notificationDocs = [
    // Account 1 (uid1): 5 notifications (3 unread + 2 read)
    {
      docPath: 'notifications/demo_ma_ntf_u1_01',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u1_01',
        userId: uid1,
        title: 'عرضان جديدان على طلب مواسير السباكة',
        titleAr: 'عرضان جديدان على طلب مواسير السباكة',
        titleEn: '2 new offers on your Italian PPR pipes request',
        body: 'قارن بين عرض حمد المري (45 ر.ق) وعرض سعد المهندي (50 ر.ق) لموقع مشيرب.',
        bodyAr: 'قارن بين عرض حمد المري (45 ر.ق) وعرض سعد المهندي (50 ر.ق) لموقع مشيرب.',
        bodyEn: 'Compare offers from Hamad Al-Marri (45 QAR) and Saad Al-Mohannadi (50 QAR).',
        type: 'new_offer',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_02_offers',
        offerId: 'demo_ma_off_02_prov',
        targetRoute: '/work-requests/demo_ma_wr_02_offers',
        isRead: false,
        createdAt: ts(ago({ minutes: 12 })),
        updatedAt: ts(ago({ minutes: 12 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u1_02',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u1_02',
        userId: uid1,
        title: 'الشحنة وصلت بوابة المدينة التعليمية — بانتظار رمز التسليم',
        titleAr: 'الشحنة وصلت بوابة المدينة التعليمية — بانتظار رمز التسليم',
        titleEn: 'Delivery arrived at Education City — handover code required',
        body: 'أعطِ المزود حمد المري رمز التسليم السري (T5K9B3) أو امسح QR لإتمام طلب طفايات الحريق.',
        bodyAr: 'أعطِ المزود حمد المري رمز التسليم السري (T5K9B3) أو امسح QR لإتمام طلب طفايات الحريق.',
        bodyEn: 'Share handover code (T5K9B3) or scan QR with Hamad Al-Marri to complete delivery.',
        type: 'handover_pending',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_08_deliv_pend',
        targetRoute: '/work-requests/demo_ma_wr_08_deliv_pend',
        isRead: false,
        createdAt: ts(ago({ minutes: 10 })),
        updatedAt: ts(ago({ minutes: 10 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u1_03',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u1_03',
        userId: uid1,
        title: 'كشافات LED في الطريق إلى مارينا لوسيل',
        titleAr: 'كشافات LED في الطريق إلى مارينا لوسيل',
        titleEn: 'LED Floodlights are in transit to Lusail Marina',
        body: 'حمد المري في الطريق نحو برج B. رمز التسليم السري: H6P2V5',
        bodyAr: 'حمد المري في الطريق نحو برج B. رمز التسليم السري: H6P2V5',
        bodyEn: 'Hamad Al-Marri is en route to Tower B. Secret handover code: H6P2V5',
        type: 'status_update',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_07_in_transit',
        targetRoute: '/work-requests/demo_ma_wr_07_in_transit',
        isRead: false,
        createdAt: ts(ago({ minutes: 25 })),
        updatedAt: ts(ago({ minutes: 25 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u1_04',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u1_04',
        userId: uid1,
        title: 'تمت تسوية التحويل البنكي وإغلاق طلب الكابلات',
        titleAr: 'تمت تسوية التحويل البنكي وإغلاق طلب الكابلات',
        titleEn: 'Bank transfer verified & cables order completed',
        body: 'تم إغلاق طلب كابلات الطاقة المدرعة (QNB-2026-50904) وحفظ تقييمك 5 نجوم.',
        bodyAr: 'تم إغلاق طلب كابلات الطاقة المدرعة (QNB-2026-50904) وحفظ تقييمك 5 نجوم.',
        bodyEn: 'Armored cables order (QNB-2026-50904) settled and 5-star rating recorded.',
        type: 'request_completed',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_09_comp_bank',
        targetRoute: '/work-requests/demo_ma_wr_09_comp_bank',
        isRead: true,
        readAt: ts(ago({ days: 1, hours: 16 })),
        createdAt: ts(ago({ days: 1, hours: 18 })),
        updatedAt: ts(ago({ days: 1, hours: 16 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u1_05',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u1_05',
        userId: uid1,
        title: 'نزاع شحنة البورسلان قيد المراجعة الإدارية',
        titleAr: 'نزاع شحنة البورسلان قيد المراجعة الإدارية',
        titleEn: 'Porcelain tiles dispute is under admin review',
        body: 'يراجع فريق عمليات مشوار تفاصيل اختلاف اللون في شحنة الوكرة وسيتواصل معك قريباً.',
        bodyAr: 'يراجع فريق عمليات مشوار تفاصيل اختلاف اللون في شحنة الوكرة وسيتواصل معك قريباً.',
        bodyEn: 'Mashwar Ops is reviewing the color batch discrepancy on your Al Wakrah order.',
        type: 'dispute_opened',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_11_disputed',
        targetRoute: '/work-requests/demo_ma_wr_11_disputed',
        isRead: true,
        readAt: ts(ago({ hours: 2 })),
        createdAt: ts(ago({ hours: 3 })),
        updatedAt: ts(ago({ hours: 2 })),
      },
    },

    // Account 2 (uid2): 4 notifications (2 unread + 2 read)
    {
      docPath: 'notifications/demo_ma_ntf_u2_01',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u2_01',
        userId: uid2,
        title: 'تم اختيار عرضك لتوريد مثقاب Makita',
        titleAr: 'تم اختيار عرضك لتوريد مثقاب Makita',
        titleEn: 'Your offer was selected for Makita Hammer Drill',
        body: 'اختار م. خالد الكواري عرضك (55 ر.ق) لموقع مارينا لوسيل — أكّد قبول المهمة للبدء.',
        bodyAr: 'اختار م. خالد الكواري عرضك (55 ر.ق) لموقع مارينا لوسيل — أكّد قبول المهمة للبدء.',
        bodyEn: 'Eng. Khaled selected your 55 QAR offer for Lusail Marina — accept to begin.',
        type: 'offer_selected',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_03_offer_sel',
        offerId: 'demo_ma_off_03',
        targetRoute: '/work-requests/demo_ma_wr_03_offer_sel',
        isRead: false,
        createdAt: ts(ago({ minutes: 45 })),
        updatedAt: ts(ago({ minutes: 45 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u2_02',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u2_02',
        userId: uid2,
        title: 'أدخل رمز التسليم لإغلاق مهمة المدينة التعليمية',
        titleAr: 'أدخل رمز التسليم لإغلاق مهمة المدينة التعليمية',
        titleEn: 'Enter handover code to close Education City job',
        body: 'اطلب رمز التسليم المكون من 6 خانات من م. خالد الكواري لتأكيد إتمام توصيل طفايات الحريق.',
        bodyAr: 'اطلب رمز التسليم المكون من 6 خانات من م. خالد الكواري لتأكيد إتمام توصيل طفايات الحريق.',
        bodyEn: 'Request the 6-char handover code from Eng. Khaled to complete the delivery.',
        type: 'handover_pending',
        category: 'worksite_supply',
        requestId: 'demo_ma_wr_08_deliv_pend',
        targetRoute: '/work-requests/demo_ma_wr_08_deliv_pend',
        isRead: false,
        createdAt: ts(ago({ minutes: 10 })),
        updatedAt: ts(ago({ minutes: 10 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u2_03',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u2_03',
        userId: uid2,
        title: 'حجز مقعد جديد على رحلة الدوحة ← الخور',
        titleAr: 'حجز مقعد جديد على رحلة الدوحة ← الخور',
        titleEn: 'New seat booking on Doha -> Al Khor ride',
        body: 'حجز م. خالد الكواري مقعداً واحداً (35 ر.ق) برمز صعود 4821.',
        bodyAr: 'حجز م. خالد الكواري مقعداً واحداً (35 ر.ق) برمز صعود 4821.',
        bodyEn: 'Eng. Khaled Al-Kuwari booked 1 seat (35 QAR) with boarding OTP 4821.',
        type: 'booking_confirmed',
        category: 'rides',
        targetRoute: '/rides/demo_ma_ride_01',
        isRead: true,
        readAt: ts(ago({ hours: 1 })),
        createdAt: ts(ago({ hours: 2 })),
        updatedAt: ts(ago({ hours: 1 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u2_04',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u2_04',
        userId: uid2,
        title: 'تم إيداع أرباح التوريد في محفظتك (540 ر.ق)',
        titleAr: 'تم إيداع أرباح التوريد في محفظتك (540 ر.ق)',
        titleEn: 'Supply payout credited to your wallet (540 QAR)',
        body: 'تم تحويل مستحقاتك بعد إغلاق مهام توريد لوسيل ومشيرب بنجاح.',
        bodyAr: 'تم تحويل مستحقاتك بعد إغلاق مهام توريد لوسيل ومشيرب بنجاح.',
        bodyEn: 'Your payout for completed Lusail & Msheireb supply tasks has been settled.',
        type: 'payout_received',
        category: 'wallet',
        requestId: 'demo_ma_wr_09_comp_bank',
        targetRoute: '/wallet',
        isRead: true,
        readAt: ts(ago({ days: 1, hours: 15 })),
        createdAt: ts(ago({ days: 1, hours: 17 })),
        updatedAt: ts(ago({ days: 1, hours: 15 })),
      },
    },

    // Account 3 (uid3): 3 notifications (1 unread + 2 read)
    {
      docPath: 'notifications/demo_ma_ntf_u3_01',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u3_01',
        userId: uid3,
        title: 'طلب توثيق مزود التوريد (QID) قيد المراجعة',
        titleAr: 'طلب توثيق مزود التوريد (QID) قيد المراجعة',
        titleEn: 'Provider QID verification is under review',
        body: 'تم استلام بيانات البطاقة القطرية والاستمارة وجارٍ مراجعتها من إدارة مشوار.',
        bodyAr: 'تم استلام بيانات البطاقة القطرية والاستمارة وجارٍ مراجعتها من إدارة مشوار.',
        bodyEn: 'Your Qatar QID and vehicle license were received and are under admin review.',
        type: 'provider_verification_under_review',
        category: 'provider_kyc',
        targetRoute: '/provider/onboarding',
        isRead: false,
        createdAt: ts(ago({ hours: 6 })),
        updatedAt: ts(ago({ hours: 6 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u3_02',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u3_02',
        userId: uid3,
        title: 'طردك إلى دخان الآن في الطريق',
        titleAr: 'طردك إلى دخان الآن في الطريق',
        titleEn: 'Your parcel to Dukhan is now in transit',
        body: 'الكابتن حمد المري استلم المظروف وهو في الطريق إلى شيخة النعيمي (كود التسليم: 7724).',
        bodyAr: 'الكابتن حمد المري استلم المظروف وهو في الطريق إلى شيخة النعيمي (كود التسليم: 7724).',
        bodyEn: 'Captain Hamad Al-Marri is en route to Dukhan (delivery OTP: 7724).',
        type: 'parcel_in_transit',
        category: 'parcels',
        targetRoute: '/parcels/demo_ma_pcl_04_in_transit',
        isRead: true,
        readAt: ts(ago({ minutes: 20 })),
        createdAt: ts(ago({ minutes: 35 })),
        updatedAt: ts(ago({ minutes: 20 })),
      },
    },
    {
      docPath: 'notifications/demo_ma_ntf_u3_03',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ma_ntf_u3_03',
        userId: uid3,
        title: 'تم نشر رحلة السيدات: لوسيل ← المدينة التعليمية',
        titleAr: 'تم نشر رحلة السيدات: لوسيل ← المدينة التعليمية',
        titleEn: 'Ladies-Only ride published: Lusail -> Education City',
        body: 'رحلتك متاحة الآن للحجز الفوري لـ 3 مقاعد بسعر 25 ر.ق للمقعد.',
        bodyAr: 'رحلتك متاحة الآن للحجز الفوري لـ 3 مقاعد بسعر 25 ر.ق للمقعد.',
        bodyEn: 'Your ride is live for instant booking (3 seats, 25 QAR/seat).',
        type: 'ride_published',
        category: 'rides',
        targetRoute: '/rides/demo_ma_ride_05_ladies',
        isRead: true,
        readAt: ts(ago({ hours: 2 })),
        createdAt: ts(ago({ hours: 3 })),
        updatedAt: ts(ago({ hours: 2 })),
      },
    },
  ];

  return {
    allDocs: [
      ...adminStaffDocs,
      ...userDocs,
      ...businessProfileDocs,
      ...savedWorksiteDocs,
      ...providerProfileDocs,
      ...providerVerificationDocs,
      ...workRequestDocs,
      ...workOfferDocs,
      ...secretDocs,
      ...handoverViewDocs,
      ...requestEventDocs,
      ...ratingDocs,
      ...rideDocs,
      ...bookingDocs,
      ...parcelDocs,
      ...boardAdDocs,
      ...boardOfferDocs,
      ...routeAlertDocs,
      ...walletTransactionDocs,
      ...conversationDocs,
      ...messageDocs,
      ...notificationDocs,
    ],
  };
}

async function commitDataset({ firestoreClient, projectId, allDocs, deleteDocPaths }) {
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const writes = [
    ...allDocs.map((entry) => ({
      update: {
        name: `${dbRoot}/${entry.docPath}`,
        fields: encodeFirestoreFields(entry.data),
      },
    })),
    ...deleteDocPaths.map((docPath) => ({
      delete: `${dbRoot}/${docPath}`,
    })),
  ];

  const chunkSize = 200;
  let committed = 0;
  for (let i = 0; i < writes.length; i += chunkSize) {
    const slice = writes.slice(i, i + chunkSize);
    await firestoreClient.post(
      `/v1/projects/${projectId}/databases/(default)/documents:commit`,
      { writes: slice },
      { headers: { 'x-goog-user-project': projectId } },
    );
    committed += slice.length;
  }
  return committed;
}

async function verifyReadback({ firestoreClient, projectId, accounts, allDocs }) {
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const uid1 = accounts.requester.uid;
  const uid2 = accounts.provider.uid;
  const uid3 = accounts.traveler.uid;
  const uid4 = accounts.fresh.uid;
  const uid5 = accounts.admin.uid;

  const absentPaths = [
    `provider_profiles/${uid4}`,
    `provider_verifications/${uid4}`,
    `business_profiles/${uid4}`,
    `admin_staff/${uid4}`,
  ];

  const lookupNames = [
    ...allDocs.map((d) => `${dbRoot}/${d.docPath}`),
    ...absentPaths.map((p) => `${dbRoot}/${p}`),
  ];

  const foundByPath = new Map();
  const chunkSize = 90;
  for (let i = 0; i < lookupNames.length; i += chunkSize) {
    const slice = lookupNames.slice(i, i + chunkSize);
    const res = await firestoreClient.post(
      `/v1/projects/${projectId}/databases/(default)/documents:batchGet`,
      { documents: slice },
      { headers: { 'x-goog-user-project': projectId } },
    );
    const items = Array.isArray(res.body) ? res.body : [];
    for (const item of items) {
      if (item.found?.name) {
        const relPath = item.found.name.slice(dbRoot.length + 1);
        foundByPath.set(relPath, decodeFirestoreFields(item.found.fields || {}));
      }
    }
  }

  const errors = [];
  const countsByCollection = new Map();

  for (const entry of allDocs) {
    if (!countsByCollection.has(entry.collectionKey)) {
      countsByCollection.set(entry.collectionKey, { expected: 0, found: 0 });
    }
    const stat = countsByCollection.get(entry.collectionKey);
    stat.expected += 1;
    if (foundByPath.has(entry.docPath)) {
      stat.found += 1;
    } else {
      errors.push(`Missing seeded document: ${entry.docPath}`);
    }
  }

  // Verify Account 4 has ZERO stale/associated documents anywhere
  const freshCheck = await findStaleDocsForFreshAccount({ firestoreClient, projectId, uid4 });
  if (freshCheck.staleQueryPaths.length > 0) {
    errors.push(
      `Account 4 (${uid4}) is NOT clean-slate! Found unexpected docs: ${freshCheck.staleQueryPaths.join(', ')}`,
    );
  }
  for (const p of absentPaths) {
    if (foundByPath.has(p)) {
      errors.push(`Account 4 (${uid4}) has unexpected doc: ${p}`);
    }
  }

  // Verify user profiles readback values
  const u1 = foundByPath.get(`users/${uid1}`);
  const u2 = foundByPath.get(`users/${uid2}`);
  const u3 = foundByPath.get(`users/${uid3}`);
  const u4 = foundByPath.get(`users/${uid4}`);
  const u5 = foundByPath.get(`users/${uid5}`);
  if (!u1 || u1.walletBalance !== 350) errors.push(`users/${uid1} walletBalance mismatch`);
  if (!u2 || u2.walletBalance !== 1280) errors.push(`users/${uid2} walletBalance mismatch`);
  if (!u3 || u3.walletBalance !== 220 || u3.ladiesOnlyPreference !== true) {
    errors.push(`users/${uid3} walletBalance/ladiesOnlyPreference mismatch`);
  }
  if (!u4 || u4.walletBalance !== 0 || u4.isVerified !== false || u4.phone !== '') {
    errors.push(`users/${uid4} clean-slate fields mismatch`);
  }
  if (!u5) errors.push(`users/${uid5} missing`);

  // Verify provider approval statuses
  const pp2 = foundByPath.get(`provider_profiles/${uid2}`);
  const pp3 = foundByPath.get(`provider_profiles/${uid3}`);
  const pv2 = foundByPath.get(`provider_verifications/${uid2}`);
  const pv3 = foundByPath.get(`provider_verifications/${uid3}`);
  if (pp2?.approvalStatus !== 'approved' || pv2?.status !== 'approved') {
    errors.push(`Account 2 provider approval/verification not approved`);
  }
  if (pp3?.approvalStatus !== 'pending' || pv3?.status !== 'underReview') {
    errors.push(`Account 3 provider approval/verification not pending/underReview`);
  }

  // Verify all 11 work_request statuses exist
  const liveRequests = allDocs
    .filter((d) => d.collectionKey === 'work_requests')
    .map((d) => foundByPath.get(d.docPath))
    .filter(Boolean);
  const seenWrStatuses = new Set(liveRequests.map((r) => r.status));
  for (const st of EXPECTED_WORK_STATUSES) {
    if (!seenWrStatuses.has(st)) {
      errors.push(`Missing work_requests status '${st}'`);
    }
  }

  // Verify all 5 parcel statuses exist
  const liveParcels = allDocs
    .filter((d) => d.collectionKey === 'parcels')
    .map((d) => foundByPath.get(d.docPath))
    .filter(Boolean);
  const seenParcelStatuses = new Set(liveParcels.map((p) => p.status));
  for (const st of EXPECTED_PARCEL_STATUSES) {
    if (!seenParcelStatuses.has(st)) {
      errors.push(`Missing parcels status '${st}'`);
    }
  }

  // Verify salted SHA-256 handover codes
  for (const [requestId, expectedCode] of Object.entries(HANDOVER_CODES)) {
    const secret = foundByPath.get(`work_request_secrets/${requestId}`);
    const view = foundByPath.get(`work_request_handover_view/${requestId}`);
    if (!secret || !view) {
      errors.push(`Missing secret or handover view for ${requestId}`);
      continue;
    }
    if (view.handoverCode !== expectedCode) {
      errors.push(`Handover code mismatch on ${requestId}: expected ${expectedCode}, got ${view.handoverCode}`);
    }
    const recomputed = hashHandoverCode(expectedCode, secret.codeSalt);
    if (recomputed !== secret.codeHash) {
      errors.push(`SHA-256 hash mismatch on work_request_secrets/${requestId}`);
    }
  }

  // Verify notification counts per user via live query
  const ntfCounts = {};
  for (const key of ['requester', 'provider', 'traveler', 'fresh']) {
    const uid = accounts[key].uid;
    const paths = await queryDocPathsByField({
      firestoreClient,
      projectId,
      collectionId: 'notifications',
      fieldPath: 'userId',
      value: uid,
    });
    ntfCounts[key] = paths.length;
  }
  if (ntfCounts.fresh !== 0) {
    errors.push(`Expected 0 notifications for fresh account, found ${ntfCounts.fresh}`);
  }

  // Verify chat messages readback
  const liveMsg3 = foundByPath.get(`conversations/${CHAT_CONVERSATION_ID}/messages/demo_ma_msg_03`);
  if (!liveMsg3 || !String(liveMsg3.text || '').includes('https://www.google.com/maps/search/?api=1&query=25.4357,51.4910')) {
    errors.push('Chat message with Google Maps link missing or corrupted');
  }

  return { countsByCollection, ntfCounts, errors };
}

async function main() {
  const args = parseArgs(process.argv);
  const ftLib = resolveFirebaseToolsLib();

  const auth = require(path.join(ftLib, 'auth'));
  const { requireAuth } = require(path.join(ftLib, 'requireAuth'));
  const apiv2 = require(path.join(ftLib, 'apiv2'));
  const api = require(path.join(ftLib, 'api'));

  const acct = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
  if (!acct) {
    throw new Error('No authenticated Firebase CLI account found. Run `firebase login` first.');
  }
  const opts = { project: args.projectId };
  auth.setActiveAccount(opts, acct);
  await requireAuth(opts);

  const identityClient = new apiv2.Client({ urlPrefix: api.identityOrigin(), auth: true });
  const firestoreClient = new apiv2.Client({ urlPrefix: api.firestoreOrigin(), auth: true });

  console.log(
    `=== MASHWAR Qatar Multi-Account Live Demo ${args.verifyOnly ? 'Verifier (--verify-only)' : 'Seeder & Verifier'} [${args.projectId}] ===`,
  );

  // 1. Provision or verify all 5 Firebase Auth accounts
  const accounts = await provisionOrVerifyAccounts({
    identityClient,
    projectId: args.projectId,
    verifyOnly: args.verifyOnly,
  });

  console.log('\n[AUTH] Provisioned / Verified 5 Firebase Auth Accounts:');
  for (const spec of ACCOUNT_SPECS) {
    const a = accounts[spec.key];
    console.log(
      `  - ${a.key.padEnd(10)} | UID: ${a.uid} | ${a.email} | Name: ${a.displayName} | Claims: ${JSON.stringify(a.claims)} (${a.action})`,
    );
  }

  // 2. Build deterministic multi-account Firestore dataset
  const dataset = buildMultiAccountDataset({ accounts, now: new Date() });

  // 3. Clean stale Account 4 docs + commit all demo docs
  if (!args.verifyOnly) {
    const staleForFresh = await findStaleDocsForFreshAccount({
      firestoreClient,
      projectId: args.projectId,
      uid4: accounts.fresh.uid,
    });
    const deleteDocPaths = [
      ...new Set([...staleForFresh.staleQueryPaths, ...staleForFresh.absentSingletons]),
    ];
    const committed = await commitDataset({
      firestoreClient,
      projectId: args.projectId,
      allDocs: dataset.allDocs,
      deleteDocPaths,
    });
    console.log(
      `\n[FIRESTORE] Committed ${committed} idempotent operations (${dataset.allDocs.length} upserts, ${deleteDocPaths.length} clean-slate deletes for Account 4).`,
    );
  }

  // 4. Full readback verification
  const { countsByCollection, ntfCounts, errors } = await verifyReadback({
    firestoreClient,
    projectId: args.projectId,
    accounts,
    allDocs: dataset.allDocs,
  });

  console.log('\n[VERIFY] Live Firestore Readback Counts by Collection:');
  for (const [col, stat] of countsByCollection.entries()) {
    console.log(`  - ${col.padEnd(28)}: ${stat.found}/${stat.expected}`);
  }
  console.log(
    `\n[VERIFY] Live Notifications Query Counts -> requester: ${ntfCounts.requester}, provider: ${ntfCounts.provider}, traveler: ${ntfCounts.traveler}, fresh: ${ntfCounts.fresh}`,
  );
  console.log('\n[VERIFY] Active Handover Codes (SHA-256 Verified):');
  for (const [reqId, code] of Object.entries(HANDOVER_CODES)) {
    console.log(`  - ${reqId.padEnd(28)}: ${code}`);
  }
  console.log(`[VERIFY] Active Chat Conversation ID: ${CHAT_CONVERSATION_ID}`);

  if (errors.length > 0) {
    console.error('\n[FAIL] Verification errors:');
    for (const err of errors) {
      console.error(`  * ${err}`);
    }
    process.exit(1);
  }

  console.log('\n[PASS] All 5 Firebase Auth accounts, custom claims, collections, handover SHA-256 hashes, and Account 4 clean-slate invariants verified 100%.');
}

main().catch((err) => {
  console.error('[ERROR]', err && err.stack ? err.stack : String(err));
  process.exit(1);
});
