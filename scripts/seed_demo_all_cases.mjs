#!/usr/bin/env node
/**
 * MASHWAR Qatar Worksite Supply MVP — Live All-Cases Demo Seeder & Verifier
 *
 * Targets Firebase project `mashwar-qatar-2026-ec99d` (Spark-plan safe, zero Cloud Functions required).
 * Authenticates via the local Firebase CLI session (`firebase-tools/lib`) using:
 *   const acct = auth.getProjectDefaultAccount(process.cwd());
 *   const opts = { project: 'mashwar-qatar-2026-ec99d' };
 *   auth.setActiveAccount(opts, acct);
 *   await requireAuth(opts);
 *
 * Modes:
 *   node scripts/seed_demo_all_cases.mjs                  # Grant admin claim + upsert all demo docs + verify readback
 *   node scripts/seed_demo_all_cases.mjs --verify-only    # Read-only verification of rules release, claims & all collections
 */

import crypto from 'node:crypto';
import fs from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..');

const DEFAULT_PROJECT_ID = 'mashwar-qatar-2026-ec99d';
const DEFAULT_OWNER_UID = 'QB0hyc4BVZTkr91EC9KUd2EFbCw1';
const DEFAULT_OWNER_EMAIL = 'abdelrahmanmahana01@gmail.com';
const DEFAULT_OWNER_NAME = 'عبدالرحمن مهنا';

const PEER_KHALED_ID = 'demo_req_khaled';
const PEER_SARA_ID = 'demo_req_sara';

const PROV_MAIN_ID = 'demo_prov_main';
const PROV_SAFETY_ID = 'demo_prov_safety';
const PROV_FAST_ID = 'demo_prov_fast';
const PROV_PENDING_ID = 'demo_prov_pending';
const PROV_UNVERIFIED_ID = 'demo_prov_unverified_docs';
const PROV_REJECTED_ID = 'demo_prov_rejected';
const PROV_SUSPENDED_ID = 'demo_prov_suspended';

const HANDOVER_CODES = Object.freeze({
  demo_wr_06_accepted: 'K7M4P9',
  demo_wr_07_in_prog: 'Q9R3W8',
  demo_wr_08_picked_up: 'M4N8X2',
  demo_wr_09_transit: 'H6P2V5',
  demo_wr_10_deliv_pend: 'T5K9B3',
});

const EXPECTED_STATUSES = [
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
];

const EXPECTED_PROVIDER_STATUSES = ['approved', 'pending', 'rejected', 'suspended'];
const EXPECTED_PAYMENT_METHODS = ['cash_on_delivery', 'bank_transfer_manual'];
const EXPECTED_PAYMENT_STATUSES = [
  'unpaid',
  'transfer_proof_submitted',
  'verified_settled',
  'disputed',
];
const EXPECTED_QATAR_MUNICIPALITIES = [
  'الدوحة',
  'الريان',
  'الوكرة',
  'الخور',
  'أم صلال',
  'الضعاين',
  'الشمال',
  'الشيحانية',
];

function parseArgs(argv) {
  let projectId = process.env.MASHWAR_FIREBASE_PROJECT || DEFAULT_PROJECT_ID;
  let ownerUid = DEFAULT_OWNER_UID;
  let ownerEmail = DEFAULT_OWNER_EMAIL;
  let ownerName = DEFAULT_OWNER_NAME;
  let verifyOnly = false;
  let skipRulesCheck = false;

  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--verify-only' || arg === '-VerifyOnly') {
      verifyOnly = true;
    } else if (arg === '--skip-rules-check') {
      skipRulesCheck = true;
    } else if (arg === '--project' && argv[i + 1]) {
      projectId = argv[++i].trim();
    } else if (arg === '--owner-uid' && argv[i + 1]) {
      ownerUid = argv[++i].trim();
    } else if (arg === '--owner-email' && argv[i + 1]) {
      ownerEmail = argv[++i].trim();
    } else if (arg === '--owner-name' && argv[i + 1]) {
      ownerName = argv[++i].trim();
    }
  }

  return { projectId, ownerUid, ownerEmail, ownerName, verifyOnly, skipRulesCheck };
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

/**
 * Builds the complete Qatar-first demo dataset mirroring `MashwarDemoCasesCatalog.build()`.
 */
function buildCatalogDataset({ ownerUid, ownerEmail, ownerName, now = new Date() }) {
  const anchorMs = now.getTime();
  const ago = ({ days = 0, hours = 0, minutes = 0 }) =>
    new Date(anchorMs - ((days * 24 + hours) * 60 + minutes) * 60 * 1000);
  const ahead = ({ days = 0, hours = 0, minutes = 0 }) =>
    new Date(anchorMs + ((days * 24 + hours) * 60 + minutes) * 60 * 1000);

  const adminStaffDocs = [
    {
      docPath: `admin_staff/${ownerUid}`,
      collectionKey: 'admin_staff',
      data: {
        id: ownerUid,
        uid: ownerUid,
        name: ownerName,
        email: ownerEmail,
        role: 'superAdmin',
        isActive: true,
        createdAt: ts(ago({ days: 30 })),
        updatedAt: ts(now),
      },
    },
  ];

  const userDocs = [
    {
      docPath: `users/${ownerUid}`,
      collectionKey: 'users',
      data: {
        id: ownerUid,
        fullName: ownerName,
        phone: '+97455889900',
        email: ownerEmail,
        gender: 'male',
        governorate: 'الدوحة',
        city: 'لوسيل',
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: 0,
        rating: dbl(4.95),
        completedRides: 0,
        completedParcels: 12,
        hasActiveAlerts: true,
        hasUpcomingBooking: false,
        createdAt: ts(ago({ days: 30 })),
        updatedAt: ts(now),
      },
    },
    {
      docPath: `users/${PEER_KHALED_ID}`,
      collectionKey: 'users',
      data: {
        id: PEER_KHALED_ID,
        fullName: 'م. خالد العطية (شركة المدار)',
        phone: '+97450312290',
        email: 'khaled@almadar-contracting.qa',
        gender: 'male',
        governorate: 'الدوحة',
        city: 'المنطقة الصناعية',
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: 0,
        rating: dbl(4.9),
        completedRides: 0,
        completedParcels: 8,
        createdAt: ts(ago({ days: 24 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
    {
      docPath: `users/${PEER_SARA_ID}`,
      collectionKey: 'users',
      data: {
        id: PEER_SARA_ID,
        fullName: 'م. سارة الكواري (الخليج الهندسية)',
        phone: '+97455449988',
        email: 'sara@gulf-engineering.qa',
        gender: 'female',
        governorate: 'الوكرة',
        city: 'الوكرة',
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: 0,
        rating: dbl(4.9),
        completedRides: 0,
        completedParcels: 6,
        createdAt: ts(ago({ days: 21 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
    {
      docPath: `users/${PROV_MAIN_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_MAIN_ID,
        fullName: 'خالد بن حمد المناعي للتوريدات',
        phone: '+97455341122',
        gender: 'male',
        governorate: 'الدوحة',
        city: 'المنطقة الصناعية',
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: 0,
        rating: dbl(4.9),
        completedRides: 0,
        completedParcels: 24,
        createdAt: ts(ago({ days: 28 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
    {
      docPath: `users/${PROV_SAFETY_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_SAFETY_ID,
        fullName: 'طارق جاسم المهندي للسلامة',
        phone: '+97466778899',
        gender: 'male',
        governorate: 'الخور',
        city: 'الخور',
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: 0,
        rating: dbl(4.8),
        completedRides: 0,
        completedParcels: 15,
        createdAt: ts(ago({ days: 20 })),
        updatedAt: ts(ago({ days: 2 })),
      },
    },
    {
      docPath: `users/${PROV_FAST_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_FAST_ID,
        fullName: 'ناصر راشد الهاجري للنقل السريع',
        phone: '+97477445566',
        gender: 'male',
        governorate: 'الريان',
        city: 'المنطقة الصناعية',
        isVerified: true,
        idVerificationStatus: 'verified',
        walletBalance: 0,
        rating: dbl(4.7),
        completedRides: 0,
        completedParcels: 11,
        createdAt: ts(ago({ days: 15 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
    {
      docPath: `users/${PROV_PENDING_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_PENDING_ID,
        fullName: 'سالم فهد الدوسري',
        phone: '+97477112233',
        gender: 'male',
        governorate: 'الوكرة',
        city: 'الوكرة',
        isVerified: false,
        idVerificationStatus: 'underReview',
        walletBalance: 0,
        rating: 0,
        completedRides: 0,
        completedParcels: 0,
        createdAt: ts(ago({ hours: 7 })),
        updatedAt: ts(ago({ hours: 4 })),
      },
    },
    {
      docPath: `users/${PROV_UNVERIFIED_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_UNVERIFIED_ID,
        fullName: 'عبدالعزيز حمد النعيمي',
        phone: '+97450119988',
        gender: 'male',
        governorate: 'الريان',
        city: 'أم صلال',
        isVerified: false,
        idVerificationStatus: 'unverified',
        walletBalance: 0,
        rating: 0,
        completedRides: 0,
        completedParcels: 0,
        createdAt: ts(ago({ hours: 3 })),
        updatedAt: ts(ago({ hours: 3 })),
      },
    },
    {
      docPath: `users/${PROV_REJECTED_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_REJECTED_ID,
        fullName: 'جاسم محمد الكعبي',
        phone: '+97466448822',
        gender: 'male',
        governorate: 'الضعاين',
        city: 'لوسيل',
        isVerified: false,
        idVerificationStatus: 'rejected',
        walletBalance: 0,
        rating: 0,
        completedRides: 0,
        completedParcels: 0,
        createdAt: ts(ago({ days: 6 })),
        updatedAt: ts(ago({ days: 4 })),
      },
    },
    {
      docPath: `users/${PROV_SUSPENDED_ID}`,
      collectionKey: 'users',
      data: {
        id: PROV_SUSPENDED_ID,
        fullName: 'مشعل سلطان العطية',
        phone: '+97455998811',
        gender: 'male',
        governorate: 'الدوحة',
        city: 'الريان',
        isVerified: false,
        idVerificationStatus: 'rejected',
        walletBalance: 0,
        rating: dbl(4.2),
        completedRides: 0,
        completedParcels: 6,
        createdAt: ts(ago({ days: 14 })),
        updatedAt: ts(ago({ days: 2 })),
      },
    },
  ];

  // Saved worksites live at `users/{uid}/private/{siteId}` with `docType: 'saved_worksite'`
  // (exact subcollection path queried by `FirebaseProviderRepository.listSavedWorksites`).
  const savedWorksiteDocs = [
    {
      docPath: `users/${ownerUid}/private/demo_site_lusail_marina`,
      collectionKey: 'saved_worksites',
      data: {
        id: 'demo_site_lusail_marina',
        docType: 'saved_worksite',
        ownerUserId: ownerUid,
        businessProfileId: null,
        label: 'مارينا لوسيل - برج B | Lusail Marina Tower B',
        municipality: 'لوسيل',
        zoneOrStreet: 'منطقة 69، شارع المارينا 210',
        landmark: 'بوابة المقاولين الشمالية',
        gateInstructions: 'الاتصال بمسؤول الموقع قبل الوصول بـ 10 دقائق',
        siteContactName: ownerName,
        siteContactPhone: '55123456',
        latitude: dbl(25.4192),
        longitude: dbl(51.529),
        isDefault: true,
        createdAt: ts(ago({ days: 10 })),
        updatedAt: ts(ago({ days: 2 })),
      },
    },
    {
      docPath: `users/${ownerUid}/private/demo_site_industrial_18`,
      collectionKey: 'saved_worksites',
      data: {
        id: 'demo_site_industrial_18',
        docType: 'saved_worksite',
        ownerUserId: ownerUid,
        businessProfileId: null,
        label: 'المنطقة الصناعية - ورشة شارع 18 | Industrial Area St. 18 Yard',
        municipality: 'المنطقة الصناعية',
        zoneOrStreet: 'المنطقة الصناعية، شارع 18، قسيمة 44',
        landmark: 'مقابل مخازن المعدات الثقيلة',
        gateInstructions: 'الدخول من بوابة الشحن الخلفية وإبراز سند التوريد',
        siteContactName: 'م. طارق الكواري',
        siteContactPhone: '55224466',
        latitude: dbl(25.161),
        longitude: dbl(51.4417),
        isDefault: false,
        createdAt: ts(ago({ days: 8 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
    {
      docPath: `users/${ownerUid}/private/demo_site_wakrah_yard`,
      collectionKey: 'saved_worksites',
      data: {
        id: 'demo_site_wakrah_yard',
        docType: 'saved_worksite',
        ownerUserId: ownerUid,
        businessProfileId: null,
        label: 'ساحة الوكرة اللوجستية - قطاع 4 | Al Wakrah Logistics Yard',
        municipality: 'الوكرة',
        zoneOrStreet: 'طريق الوكير، قطاع 90، بوابة 4',
        landmark: 'بجوار محطة وقود وقود الوكرة',
        gateInstructions: 'تسليم السند عند مكتب الأمن الداخلي قبل التفريغ',
        siteContactName: 'م. جاسم المهندي',
        siteContactPhone: '66335577',
        latitude: dbl(25.1715),
        longitude: dbl(51.6034),
        isDefault: false,
        createdAt: ts(ago({ days: 5 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
  ];

  // Provider entries (all 4 ProviderApprovalStatus values + approved profile for ownerUid)
  const rawProviders = [
    {
      uid: PROV_MAIN_ID,
      fullName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      phone: '55341122',
      qidNumber: '28963401122',
      qidFrontUrl: 'https://storage.mashwar.qa/kyc/demo_prov_main/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/kyc/demo_prov_main/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/kyc/demo_prov_main/selfie.jpg',
      vehicleLicenseUrl: 'https://storage.mashwar.qa/kyc/demo_prov_main/istamara.jpg',
      vehicleType: 'Toyota Hilux 4x4 Pickup',
      vehiclePlate: 'قطر 482910',
      serviceAreas: ['الدوحة', 'لوسيل', 'المنطقة الصناعية', 'الريان', 'الوكرة', 'مسيعيد'],
      approvalStatus: 'approved',
      ratingAvg: dbl(4.9),
      ratingCount: 24,
      completedTasksCount: 24,
      reviewedBy: ownerUid,
      reviewedAtUtc: ago({ days: 25 }).toISOString(),
      rejectionReason: null,
      hasVerificationRecord: true,
      createdAt: ago({ days: 28 }),
      updatedAt: ago({ days: 1 }),
    },
    {
      uid: PROV_SAFETY_ID,
      fullName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
      phone: '66778899',
      qidNumber: '28745612301',
      qidFrontUrl: 'https://storage.mashwar.qa/kyc/demo_prov_safety/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/kyc/demo_prov_safety/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/kyc/demo_prov_safety/selfie.jpg',
      vehicleLicenseUrl: 'https://storage.mashwar.qa/kyc/demo_prov_safety/istamara.jpg',
      vehicleType: 'Nissan Urvan Cargo Van',
      vehiclePlate: 'قطر 731042',
      serviceAreas: ['الدوحة', 'الخور', 'لوسيل', 'الضعاين', 'أم صلال'],
      approvalStatus: 'approved',
      ratingAvg: dbl(4.8),
      ratingCount: 15,
      completedTasksCount: 15,
      reviewedBy: ownerUid,
      reviewedAtUtc: ago({ days: 18 }).toISOString(),
      rejectionReason: null,
      hasVerificationRecord: true,
      createdAt: ago({ days: 20 }),
      updatedAt: ago({ days: 2 }),
    },
    {
      uid: PROV_FAST_ID,
      fullName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      phone: '77445566',
      qidNumber: '29011223344',
      qidFrontUrl: 'https://storage.mashwar.qa/kyc/demo_prov_fast/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/kyc/demo_prov_fast/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/kyc/demo_prov_fast/selfie.jpg',
      vehicleLicenseUrl: 'https://storage.mashwar.qa/kyc/demo_prov_fast/istamara.jpg',
      vehicleType: 'Mitsubishi L200 Double Cab',
      vehiclePlate: 'قطر 519204',
      serviceAreas: ['المنطقة الصناعية', 'الوكرة', 'مسيعيد', 'الشيحانية', 'الشمال'],
      approvalStatus: 'approved',
      ratingAvg: dbl(4.7),
      ratingCount: 11,
      completedTasksCount: 11,
      reviewedBy: ownerUid,
      reviewedAtUtc: ago({ days: 14 }).toISOString(),
      rejectionReason: null,
      hasVerificationRecord: true,
      createdAt: ago({ days: 15 }),
      updatedAt: ago({ days: 1 }),
    },
    {
      uid: ownerUid,
      fullName: ownerName,
      phone: '55889900',
      qidNumber: '29263401845',
      qidFrontUrl: `https://storage.mashwar.qa/kyc/${ownerUid}/qid_front.jpg`,
      qidBackUrl: `https://storage.mashwar.qa/kyc/${ownerUid}/qid_back.jpg`,
      selfieUrl: `https://storage.mashwar.qa/kyc/${ownerUid}/selfie.jpg`,
      vehicleLicenseUrl: `https://storage.mashwar.qa/kyc/${ownerUid}/istamara.jpg`,
      vehicleType: 'GMC Sierra 1500 Worksite Pickup',
      vehiclePlate: 'قطر 610482',
      serviceAreas: ['الدوحة', 'لوسيل', 'المنطقة الصناعية', 'الوكرة', 'الريان', 'الشيحانية'],
      approvalStatus: 'approved',
      ratingAvg: dbl(4.95),
      ratingCount: 12,
      completedTasksCount: 12,
      reviewedBy: ownerUid,
      reviewedAtUtc: ago({ days: 21 }).toISOString(),
      rejectionReason: null,
      hasVerificationRecord: true,
      createdAt: ago({ days: 22 }),
      updatedAt: ago({ hours: 6 }),
    },
    {
      uid: PROV_PENDING_ID,
      fullName: 'سالم فهد الدوسري | Salem Al-Dosari',
      phone: '77112233',
      qidNumber: '29663401842',
      qidFrontUrl: 'https://storage.mashwar.qa/kyc/demo_prov_pending/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/kyc/demo_prov_pending/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/kyc/demo_prov_pending/selfie.jpg',
      vehicleLicenseUrl: 'https://storage.mashwar.qa/kyc/demo_prov_pending/istamara.jpg',
      vehicleType: 'Ford Ranger Pickup',
      vehiclePlate: 'قطر 902150',
      serviceAreas: ['الوكرة', 'مسيعيد', 'الدوحة'],
      approvalStatus: 'pending',
      ratingAvg: 0,
      ratingCount: 0,
      completedTasksCount: 0,
      reviewedBy: null,
      reviewedAtUtc: null,
      rejectionReason: null,
      hasVerificationRecord: true,
      createdAt: ago({ hours: 7 }),
      updatedAt: ago({ hours: 4 }),
    },
    {
      uid: PROV_UNVERIFIED_ID,
      fullName: 'عبدالعزيز حمد النعيمي | Abdulaziz Al-Nuaimi',
      phone: '50119988',
      vehicleType: 'Isuzu D-Max',
      vehiclePlate: 'قطر 314509',
      serviceAreas: ['الريان', 'أم صلال'],
      approvalStatus: 'pending',
      ratingAvg: 0,
      ratingCount: 0,
      completedTasksCount: 0,
      reviewedBy: null,
      reviewedAtUtc: null,
      rejectionReason: null,
      hasVerificationRecord: false,
      createdAt: ago({ hours: 3 }),
      updatedAt: ago({ hours: 3 }),
    },
    {
      uid: PROV_REJECTED_ID,
      fullName: 'جاسم محمد الكعبي | Jassim Al-Kaabi',
      phone: '66448822',
      qidNumber: '29163407781',
      qidFrontUrl: 'https://storage.mashwar.qa/kyc/demo_prov_rejected/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/kyc/demo_prov_rejected/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/kyc/demo_prov_rejected/selfie.jpg',
      vehicleLicenseUrl: 'https://storage.mashwar.qa/kyc/demo_prov_rejected/istamara.jpg',
      vehicleType: 'Toyota Land Cruiser Pickup',
      vehiclePlate: 'قطر 339105',
      serviceAreas: ['الضعاين', 'لوسيل'],
      approvalStatus: 'rejected',
      ratingAvg: 0,
      ratingCount: 0,
      completedTasksCount: 0,
      reviewedBy: ownerUid,
      reviewedAtUtc: ago({ days: 4 }).toISOString(),
      rejectionReason:
        'صورة الوجه الخلفي للبطاقة القطرية (QID) منتهية الصلاحية وغير واضحة — يرجى إعادة الرفع | Back of Qatar QID is expired and blurry.',
      hasVerificationRecord: true,
      createdAt: ago({ days: 6 }),
      updatedAt: ago({ days: 4 }),
    },
    {
      uid: PROV_SUSPENDED_ID,
      fullName: 'مشعل سلطان العطية | Mishaal Al-Attiyah',
      phone: '55998811',
      qidNumber: '28863405599',
      qidFrontUrl: 'https://storage.mashwar.qa/kyc/demo_prov_suspended/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/kyc/demo_prov_suspended/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/kyc/demo_prov_suspended/selfie.jpg',
      vehicleLicenseUrl: 'https://storage.mashwar.qa/kyc/demo_prov_suspended/istamara.jpg',
      vehicleType: 'Hyundai H100 Van',
      vehiclePlate: 'قطر 228941',
      serviceAreas: ['الدوحة', 'الريان'],
      approvalStatus: 'suspended',
      ratingAvg: dbl(4.2),
      ratingCount: 6,
      completedTasksCount: 6,
      reviewedBy: ownerUid,
      reviewedAtUtc: ago({ days: 2 }).toISOString(),
      rejectionReason:
        'إيقاف مؤقت لحين تجديد رخصة المركبة (استمارة قطر) | Suspended pending Qatar vehicle istamara renewal.',
      hasVerificationRecord: true,
      createdAt: ago({ days: 14 }),
      updatedAt: ago({ days: 2 }),
    },
  ];

  const providerProfileDocs = rawProviders.map((p) => ({
    docPath: `provider_profiles/${p.uid}`,
    collectionKey: 'provider_profiles',
    data: {
      id: p.uid,
      userId: p.uid,
      fullName: p.fullName,
      phone: p.phone,
      vehicleType: p.vehicleType,
      vehiclePlate: p.vehiclePlate,
      serviceAreas: p.serviceAreas,
      approvalStatus: p.approvalStatus,
      completedTasksCount: p.completedTasksCount,
      ratingAvg: p.ratingAvg,
      ratingCount: p.ratingCount,
      reviewedBy: p.reviewedBy,
      reviewedAtUtc: p.reviewedAtUtc,
      rejectionReason: p.rejectionReason,
      createdAt: ts(p.createdAt),
      updatedAt: ts(p.updatedAt),
    },
  }));

  const providerVerificationDocs = rawProviders
    .filter((p) => p.hasVerificationRecord)
    .map((p) => ({
      docPath: `provider_verifications/${p.uid}`,
      collectionKey: 'provider_verifications',
      data: {
        id: p.uid,
        providerId: p.uid,
        fullName: p.fullName,
        qidNumber: p.qidNumber,
        qidFrontUrl: p.qidFrontUrl,
        qidBackUrl: p.qidBackUrl,
        selfieUrl: p.selfieUrl,
        vehicleLicenseUrl: p.vehicleLicenseUrl,
        status: p.approvalStatus === 'suspended' ? 'rejected' : p.approvalStatus,
        rejectionReason: p.rejectionReason,
        reviewedBy: p.reviewedBy,
        reviewedAtUtc: p.reviewedAtUtc,
        createdAt: ts(p.createdAt),
        updatedAt: ts(p.updatedAt),
      },
    }));

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

  // All 14 WorkRequests spanning ALL 11 statuses, ALL 8 Qatar municipalities + industrial hubs,
  // BOTH PaymentMethods, ALL 4 PaymentSettlementStatuses, and requesterId != assignedProviderId.
  const workRequestDocs = [
    makeWorkRequestDoc({
      id: 'demo_wr_01_open_mine',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'electrical',
      title: 'قواطع كهربائية Schneider 32A وكابلات نحاس | Schneider 32A Breakers & Copper Cables',
      description:
        'توريد 12 قاطع كهربائي Schneider 32A و3 لفات أسلاك نحاس 4مم من المنطقة الصناعية مع فاتورة متجر معتمدة.',
      pickupLocation: 'المنطقة الصناعية - شارع 10 (شركة الدوحة للكهرباء)',
      deliveryLocation: 'مارينا لوسيل - برج B',
      deliveryArea: 'لوسيل',
      siteContactName: ownerName,
      siteContactPhone: '55123456',
      itemNotes: 'التأكد من ختم الوكيل المعتمد على الكرتون وإرفاق الفاتورة.',
      estimatedQar: 420,
      maxCapQar: 480,
      feeBudgetQar: 55,
      status: 'open',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ minutes: 25 }),
      updatedAt: ago({ minutes: 25 }),
      scheduledBy: ahead({ hours: 3 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_02_open_mkt',
      requesterId: PEER_KHALED_ID,
      requesterName: 'م. خالد العطية (شركة المدار)',
      supplyCategory: 'civil_materials',
      title: 'أسمنت مقاوم للأملاح 30 كيس وشبكة تسليح | 30 Bags Sulfate-Resistant Cement',
      description:
        'مطلوب 30 كيس أسمنت قطري مقاوم للأملاح مع شبك حديدي خفيف وتسليم فوري لساحة المدار.',
      pickupLocation: 'المنطقة الصناعية - ساحة 22 لمواد البناء',
      deliveryLocation: 'المنطقة الصناعية - مستودع المدار شارع 33',
      deliveryArea: 'المنطقة الصناعية',
      siteContactName: 'م. خالد العطية',
      siteContactPhone: '50312290',
      itemNotes: 'تغطية الأكياس بمشمع مقاوم للرطوبة أثناء التحميل.',
      estimatedQar: 560,
      maxCapQar: 650,
      feeBudgetQar: 70,
      status: 'open',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'unpaid',
      createdAt: ago({ minutes: 45 }),
      updatedAt: ago({ minutes: 45 }),
      scheduledBy: ahead({ hours: 4 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_03_offers_mine',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'plumbing',
      title: 'مواسير PPR إيطالية 32مم ومحابس نحاس | Italian 32mm PPR Pipes & Brass Valves',
      description:
        '20 ماسورة PPR مقاس 32مم مع 8 محابس نحاس إيطالي، مطلوب مقارنة عروض الموردين قبل الترسية.',
      pickupLocation: 'طريق سلوى - مجمع الدوحة للسباكة',
      deliveryLocation: 'مشيرب قلب الدوحة - مبنى الصيانة 4',
      deliveryArea: 'الدوحة',
      siteContactName: ownerName,
      siteContactPhone: '55123456',
      itemNotes: 'مطابقة المقاس 32mm PN20 مع الفاتورة الأصلية.',
      estimatedQar: 340,
      maxCapQar: 400,
      feeBudgetQar: 50,
      status: 'offer_received',
      offerCount: 3,
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 2 }),
      updatedAt: ago({ minutes: 15 }),
      scheduledBy: ahead({ hours: 5 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_04_offers_mkt',
      requesterId: PEER_SARA_ID,
      requesterName: 'م. سارة الكواري (الخليج الهندسية)',
      supplyCategory: 'safety_ppe',
      title: 'خوذات سلامة MSA وسترات عاكسة (25 طقم) | 25 MSA Safety Helmets & Vests',
      description: 'توريد مستلزمات السلامة المهنية المعتمدة لفرق التشغيل في مرفأ الوكرة.',
      pickupLocation: 'المنطقة الصناعية - مركز الخليج للسلامة المهنية',
      deliveryLocation: 'الوكرة - مشروع المرفأ الساحلي بوابة 2',
      deliveryArea: 'الوكرة',
      siteContactName: 'مشرف السلامة راشد',
      siteContactPhone: '55449988',
      estimatedQar: 480,
      maxCapQar: 550,
      feeBudgetQar: 60,
      status: 'offer_received',
      offerCount: 1,
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 3 }),
      updatedAt: ago({ minutes: 40 }),
      scheduledBy: ahead({ hours: 6 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_05_offer_sel',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'tools',
      title: 'مثقاب خرسانة Makita SDS-Plus وقرص قص | Makita SDS-Plus Hammer Drill',
      description: 'شراء مثقاب خرسانة مع طقم ريش 8-16مم وقرص قطع ألماس من وكيل المعدات.',
      pickupLocation: 'طريق سلوى - وكيل معدات البناء',
      deliveryLocation: 'الريان - المدينة التعليمية بوابة الصيانة 6',
      deliveryArea: 'الريان',
      siteContactName: 'م. يوسف السليطي',
      siteContactPhone: '55771122',
      estimatedQar: 780,
      maxCapQar: 850,
      feeBudgetQar: 65,
      agreedFeeQar: 60,
      selectedOfferId: 'demo_off_05',
      assignedProviderId: PROV_FAST_ID,
      assignedProviderName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      offerCount: 1,
      status: 'offer_selected',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 4 }),
      updatedAt: ago({ hours: 1 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_06_accepted',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'hardware',
      title: 'مرابط تثبيت فولاذية M16 ومفاتيح عزم | M16 Steel Anchor Bolts & Wrenches',
      description: 'توريد 100 مسمار تثبيت فولاذي M16 مع مفاتيح شد عيارية لبوابة رأس لفان.',
      pickupLocation: 'المنطقة الصناعية - شارع 14 مستودع الحديد',
      deliveryLocation: 'الخور - بوابة رأس لفان اللوجستية 3',
      deliveryArea: 'الخور',
      siteContactName: 'مشرف التركيبات فهد',
      siteContactPhone: '66332211',
      estimatedQar: 620,
      maxCapQar: 700,
      feeBudgetQar: 85,
      agreedFeeQar: 80,
      selectedOfferId: 'demo_off_seed_06',
      assignedProviderId: PROV_MAIN_ID,
      assignedProviderName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      offerCount: 2,
      status: 'accepted',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_wr_06_qnb.jpg',
      paymentReference: 'QNB-2026-44102',
      createdAt: ago({ hours: 6 }),
      updatedAt: ago({ hours: 2 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_07_in_prog',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'safety_ppe',
      title: 'طفايات حريق CO2 6كجم ولوحات تحذير | 6kg CO2 Fire Extinguishers & Signage',
      description:
        'تجهيز 6 طفايات حريق معتمدة من الدفاع المدني مع لوحات إرشادية لمستودع أم صلال.',
      pickupLocation: 'الدوحة - شارع المطار التجاري معدات السلامة',
      deliveryLocation: 'أم صلال محمد - مجمع المخازن رقم 9',
      deliveryArea: 'أم صلال',
      siteContactName: 'مشرف المستودع عادل',
      siteContactPhone: '55883322',
      estimatedQar: 510,
      maxCapQar: 580,
      feeBudgetQar: 55,
      agreedFeeQar: 50,
      selectedOfferId: 'demo_off_seed_07',
      assignedProviderId: PROV_SAFETY_ID,
      assignedProviderName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
      offerCount: 1,
      status: 'in_progress',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 8 }),
      updatedAt: ago({ hours: 1, minutes: 30 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_08_picked_up',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'electrical',
      title: 'كشافات LED مقاومة للماء 150W للموقع | IP66 150W Site LED Floodlights',
      description: 'شراء 8 كشافات LED للعمل الليلي بالموقع مع إرفاق فاتورة المتجر الأصلية.',
      pickupLocation: 'المنطقة الصناعية - شارع 10 معرض الإنارة',
      deliveryLocation: 'الضعاين - مشروع الفلل الشمالية قطعة 14',
      deliveryArea: 'الضعاين',
      siteContactName: 'المهندس ماجد',
      siteContactPhone: '55994411',
      estimatedQar: 450,
      maxCapQar: 500,
      feeBudgetQar: 50,
      agreedFeeQar: 45,
      actualReceiptQar: 435,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_08.jpg',
      selectedOfferId: 'demo_off_seed_08',
      assignedProviderId: PROV_FAST_ID,
      assignedProviderName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      offerCount: 2,
      status: 'picked_up',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_wr_08_cbq.jpg',
      paymentReference: 'CBQ-2026-55819',
      createdAt: ago({ hours: 10 }),
      updatedAt: ago({ minutes: 50 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_09_transit',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'civil_materials',
      title: 'عوازل مائية بيتومين وغراء سيراميك صناعي | Bitumen Waterproofing & Adhesive',
      description: 'توريد 10 براميل عازل مائي و15 كيس غراء صناعي لمحطة الصيانة في مسيعيد.',
      pickupLocation: 'المنطقة الصناعية - شارع 28 مستودع العوازل',
      deliveryLocation: 'مسيعيد الصناعية - محطة الصيانة البحرية',
      deliveryArea: 'مسيعيد',
      siteContactName: 'م. حمد البوعينين',
      siteContactPhone: '66115522',
      estimatedQar: 720,
      maxCapQar: 780,
      feeBudgetQar: 95,
      agreedFeeQar: 90,
      actualReceiptQar: 710,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_09.jpg',
      selectedOfferId: 'demo_off_seed_09',
      assignedProviderId: PROV_MAIN_ID,
      assignedProviderName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      offerCount: 2,
      status: 'in_transit',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ hours: 12 }),
      updatedAt: ago({ minutes: 30 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_10_deliv_pend',
      requesterId: PEER_KHALED_ID,
      requesterName: 'م. خالد العطية (شركة المدار)',
      supplyCategory: 'plumbing',
      title: 'مضخة ضغط مياه 2 حصان ومفاتيح أوتوماتيك | 2HP Booster Pump & Pressure Switch',
      description:
        'وصلت الشحنة مع الفاتورة الأصلية إلى موقع الشيحانية بانتظار إدخال رمز التسليم T5K9B3 لإغلاق الطلب.',
      pickupLocation: 'طريق سلوى - مركز المضخات القطري',
      deliveryLocation: 'الشيحانية - محطة الخدمات بوابة 2',
      deliveryArea: 'الشيحانية',
      siteContactName: 'م. خالد العطية',
      siteContactPhone: '50312290',
      itemNotes: 'استخدم رمز التسليم التجريبي T5K9B3 لتأكيد التسليم وإكمال المهمة.',
      estimatedQar: 540,
      maxCapQar: 600,
      feeBudgetQar: 80,
      agreedFeeQar: 75,
      actualReceiptQar: 530,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_10.jpg',
      selectedOfferId: 'demo_off_seed_10',
      assignedProviderId: ownerUid,
      assignedProviderName: ownerName,
      offerCount: 2,
      status: 'delivered_pending_confirmation',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'transfer_proof_submitted',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_wr_10_qib.jpg',
      paymentReference: 'FAWRAN-2026-88301',
      createdAt: ago({ hours: 15 }),
      updatedAt: ago({ minutes: 10 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_11_comp_cash',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'hardware',
      title: 'أقفال أمان حديدية وسلاسل ربط للمعدات | Heavy-Duty Padlocks & Equipment Chains',
      description: 'تم شراء 15 قفل أمان ثقيل وسلاسل تثبيت وتسليمها في ميناء الرويس بالشمال.',
      pickupLocation: 'الخور - سوق المعدات المركزي',
      deliveryLocation: 'الشمال - مشروع ميناء الرويس قطاع C',
      deliveryArea: 'الشمال',
      siteContactName: 'مشرف المخازن علي',
      siteContactPhone: '55441100',
      estimatedQar: 400,
      maxCapQar: 450,
      feeBudgetQar: 110,
      agreedFeeQar: 100,
      actualReceiptQar: 390,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_11.jpg',
      selectedOfferId: 'demo_off_seed_11',
      assignedProviderId: PROV_MAIN_ID,
      assignedProviderName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      offerCount: 2,
      isHandoverVerified: true,
      status: 'completed',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'verified_settled',
      paymentReference: 'COD-2026-10492',
      createdAt: ago({ days: 2 }),
      updatedAt: ago({ days: 1, hours: 18 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_12_comp_bank',
      requesterId: PEER_SARA_ID,
      requesterName: 'م. سارة الكواري (الخليج الهندسية)',
      supplyCategory: 'electrical',
      title: 'لوحة توزيع فرعية 3 فاز وقاطع رئيسي 100A | 3-Phase Distribution Board 100A',
      description:
        'توريد لوحة توزيع كهربائية 3 فاز مع قاطع 100A وفاتورة ضريبية معتمدة لبوليفارد لوسيل.',
      pickupLocation: 'المنطقة الصناعية - شارع 10 الموزع الكهربائي',
      deliveryLocation: 'لوسيل - منطقة البوليفارد مبنى الأعمال 7',
      deliveryArea: 'لوسيل',
      siteContactName: 'م. سارة الكواري',
      siteContactPhone: '55449988',
      estimatedQar: 880,
      maxCapQar: 950,
      feeBudgetQar: 75,
      agreedFeeQar: 70,
      actualReceiptQar: 865,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_12.jpg',
      selectedOfferId: 'demo_off_seed_12',
      assignedProviderId: ownerUid,
      assignedProviderName: ownerName,
      offerCount: 3,
      isHandoverVerified: true,
      status: 'completed',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'verified_settled',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_wr_12_qnb.jpg',
      paymentReference: 'QNB-2026-77419',
      createdAt: ago({ days: 3 }),
      updatedAt: ago({ days: 2, hours: 20 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_13_cancelled',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'general_site_supply',
      title: 'مواد تغليف وبلاستيك حماية للأرضيات | Heavy Polythene Floor Protection Rolls',
      description: 'طلب 10 لفات بلاستيك حماية ثقيل لأرضيات المستودع قبل البدء بأعمال الدهان.',
      pickupLocation: 'طريق سلوى - سوق الجملة',
      deliveryLocation: 'ساحة الوكرة اللوجستية - قطاع 4',
      deliveryArea: 'الوكرة',
      siteContactName: 'م. جاسم المهندي',
      siteContactPhone: '66335577',
      estimatedQar: 260,
      maxCapQar: 300,
      feeBudgetQar: 45,
      cancellationReason:
        'تم توفير الكمية من المستودع الداخلي للمشروع قبل الترسية | Quantities sourced from project warehouse.',
      status: 'cancelled',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      createdAt: ago({ days: 4 }),
      updatedAt: ago({ days: 3, hours: 22 }),
    }),
    makeWorkRequestDoc({
      id: 'demo_wr_14_disputed',
      requesterId: ownerUid,
      requesterName: ownerName,
      supplyCategory: 'plumbing',
      title: 'صمامات عدم رجوع نحاسية 2 إنش PN16 | 2-Inch Brass Check Valves PN16',
      description: 'توريد 12 صمام عدم رجوع نحاسي مقاس 2 إنش لغرفة المضخات في الدفنة.',
      pickupLocation: 'المنطقة الصناعية - شارع 18 مخزن الصمامات',
      deliveryLocation: 'الدفنة - برج الأعمال رقم 12 غرفة المضخات',
      deliveryArea: 'الدوحة',
      siteContactName: 'م. طارق الكواري',
      siteContactPhone: '55224466',
      estimatedQar: 460,
      maxCapQar: 520,
      feeBudgetQar: 60,
      agreedFeeQar: 55,
      actualReceiptQar: 495,
      receiptUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_14.jpg',
      selectedOfferId: 'demo_off_seed_14',
      assignedProviderId: PROV_FAST_ID,
      assignedProviderName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      offerCount: 2,
      disputeReason:
        'اختلاف مقاس الصمامات الموردة عن المواصفة الهندسية (1.5 إنش بدلاً من 2 إنش) | Supplied 1.5" valves instead of 2" PN16 spec.',
      status: 'disputed',
      paymentMethod: 'bank_transfer_manual',
      paymentStatus: 'disputed',
      paymentProofUrl: 'https://storage.mashwar.qa/demo/proof_demo_wr_14_qnb.jpg',
      paymentReference: 'QNB-2026-66201',
      createdAt: ago({ days: 1, hours: 6 }),
      updatedAt: ago({ hours: 3 }),
    }),
  ];

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

  // 5 primary catalog offers (including 3 competing offers on demo_wr_03_offers_mine)
  // + 8 accepted offers matching selectedOfferId on active/completed/disputed requests.
  const workOfferDocs = [
    makeOfferDoc({
      id: 'demo_off_01',
      requestId: 'demo_wr_03_offers_mine',
      providerId: PROV_MAIN_ID,
      providerName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      providerRating: 4.9,
      providerCompletedJobs: 24,
      feeQar: 45,
      itemsQar: 330,
      etaMinutes: 35,
      notes: 'متواجد قرب طريق سلوى والسيارة البيك أب جاهزة مع فاتورة ضريبية فورية.',
      isSelected: false,
      status: 'pending',
      createdAt: ago({ minutes: 55 }),
      updatedAt: ago({ minutes: 55 }),
    }),
    makeOfferDoc({
      id: 'demo_off_02',
      requestId: 'demo_wr_03_offers_mine',
      providerId: PROV_SAFETY_ID,
      providerName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
      providerRating: 4.8,
      providerCompletedJobs: 15,
      feeQar: 50,
      itemsQar: 340,
      etaMinutes: 45,
      notes: 'تسليم مباشر لبوابة الصيانة في مشيرب مع تغليف محكم للمحابس.',
      isSelected: false,
      status: 'pending',
      createdAt: ago({ minutes: 35 }),
      updatedAt: ago({ minutes: 35 }),
    }),
    makeOfferDoc({
      id: 'demo_off_03',
      requestId: 'demo_wr_03_offers_mine',
      providerId: PROV_FAST_ID,
      providerName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      providerRating: 4.7,
      providerCompletedJobs: 11,
      feeQar: 40,
      itemsQar: 350,
      etaMinutes: 55,
      notes: 'أقل رسوم توصيل مع الالتزام بمواصفات PN20 الإيطالية.',
      isSelected: false,
      status: 'pending',
      createdAt: ago({ minutes: 15 }),
      updatedAt: ago({ minutes: 15 }),
    }),
    makeOfferDoc({
      id: 'demo_off_04',
      requestId: 'demo_wr_04_offers_mkt',
      providerId: PROV_SAFETY_ID,
      providerName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
      providerRating: 4.8,
      providerCompletedJobs: 15,
      feeQar: 55,
      itemsQar: 475,
      etaMinutes: 50,
      notes: 'خبرة في توريد معدات السلامة المهنية PPE ومطابقة مواصفات HSE.',
      isSelected: false,
      status: 'pending',
      createdAt: ago({ minutes: 40 }),
      updatedAt: ago({ minutes: 40 }),
    }),
    makeOfferDoc({
      id: 'demo_off_05',
      requestId: 'demo_wr_05_offer_sel',
      providerId: PROV_FAST_ID,
      providerName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      providerRating: 4.7,
      providerCompletedJobs: 11,
      feeQar: 60,
      itemsQar: 760,
      etaMinutes: 40,
      notes: 'تم فحص توفر المثقاب الأصلي لدى الوكيل وجاهز للتنفيذ.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 2 }),
      updatedAt: ago({ hours: 1 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_06',
      requestId: 'demo_wr_06_accepted',
      providerId: PROV_MAIN_ID,
      providerName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      providerRating: 4.9,
      providerCompletedJobs: 24,
      feeQar: 80,
      itemsQar: 620,
      etaMinutes: 60,
      notes: 'تسليم مباشر إلى بوابة رأس لفان اللوجستية 3.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 5 }),
      updatedAt: ago({ hours: 3 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_07',
      requestId: 'demo_wr_07_in_prog',
      providerId: PROV_SAFETY_ID,
      providerName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
      providerRating: 4.8,
      providerCompletedJobs: 15,
      feeQar: 50,
      itemsQar: 510,
      etaMinutes: 45,
      notes: 'طفايات حريق معتمدة مع شهادة فحص.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 6 }),
      updatedAt: ago({ hours: 5 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_08',
      requestId: 'demo_wr_08_picked_up',
      providerId: PROV_FAST_ID,
      providerName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      providerRating: 4.7,
      providerCompletedJobs: 11,
      feeQar: 45,
      itemsQar: 435,
      etaMinutes: 40,
      notes: 'تم الاستلام من معرض الإنارة مع الفاتورة الأصلية.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 9 }),
      updatedAt: ago({ hours: 8 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_09',
      requestId: 'demo_wr_09_transit',
      providerId: PROV_MAIN_ID,
      providerName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      providerRating: 4.9,
      providerCompletedJobs: 24,
      feeQar: 90,
      itemsQar: 710,
      etaMinutes: 65,
      notes: 'تحميل براميل العازل المائي والتوجه لمسيعيد الصناعية.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 11 }),
      updatedAt: ago({ hours: 10 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_10',
      requestId: 'demo_wr_10_deliv_pend',
      providerId: ownerUid,
      providerName: ownerName,
      providerRating: 4.95,
      providerCompletedJobs: 12,
      feeQar: 75,
      itemsQar: 530,
      etaMinutes: 50,
      notes: 'توريد المضخة مع الفاتورة الأصلية إلى موقع الشيحانية.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ hours: 13 }),
      updatedAt: ago({ hours: 10 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_11',
      requestId: 'demo_wr_11_comp_cash',
      providerId: PROV_MAIN_ID,
      providerName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
      providerRating: 4.9,
      providerCompletedJobs: 24,
      feeQar: 100,
      itemsQar: 390,
      etaMinutes: 75,
      notes: 'تسليم ميناء الرويس بالشمال.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ days: 2 }),
      updatedAt: ago({ days: 1, hours: 18 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_12',
      requestId: 'demo_wr_12_comp_bank',
      providerId: ownerUid,
      providerName: ownerName,
      providerRating: 4.95,
      providerCompletedJobs: 12,
      feeQar: 70,
      itemsQar: 865,
      etaMinutes: 40,
      notes: 'توريد لوحة التوزيع 3 فاز إلى بوليفارد لوسيل.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ days: 3 }),
      updatedAt: ago({ days: 2, hours: 20 }),
    }),
    makeOfferDoc({
      id: 'demo_off_seed_14',
      requestId: 'demo_wr_14_disputed',
      providerId: PROV_FAST_ID,
      providerName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
      providerRating: 4.7,
      providerCompletedJobs: 11,
      feeQar: 55,
      itemsQar: 495,
      etaMinutes: 45,
      notes: 'توريد صمامات عدم الرجوع لغرفة المضخات بالدفنة.',
      isSelected: true,
      status: 'accepted',
      createdAt: ago({ days: 1, hours: 4 }),
      updatedAt: ago({ days: 1, hours: 2 }),
    }),
  ];

  // Salted SHA-256 secrets & requester-scoped handover views for the 5 active codes
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
      id: 'demo_evt_01_1',
      requestId: 'demo_wr_01_open_mine',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم نشر طلب التوريد لموقع مارينا لوسيل بانتظار عروض المزودين.',
      createdAt: ago({ minutes: 25 }),
    }),
    makeEvent({
      id: 'demo_evt_02_1',
      requestId: 'demo_wr_02_open_mkt',
      actorId: PEER_KHALED_ID,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم نشر طلب توريد مواد بناء للمنطقة الصناعية.',
      createdAt: ago({ minutes: 45 }),
    }),
    makeEvent({
      id: 'demo_evt_03_1',
      requestId: 'demo_wr_03_offers_mine',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم إنشاء طلب السباكة لمشروع مشيرب.',
      createdAt: ago({ hours: 2 }),
    }),
    makeEvent({
      id: 'demo_evt_03_2',
      requestId: 'demo_wr_03_offers_mine',
      actorId: PROV_MAIN_ID,
      actorRole: 'provider',
      eventType: 'offer_submitted',
      fromStatus: 'open',
      toStatus: 'offer_received',
      note: 'تم تقديم 3 عروض تنافسية من مزودين معتمدين بالبطاقة القطرية.',
      metadata: { offerId: 'demo_off_01', feeMinor: 4500 },
      createdAt: ago({ minutes: 55 }),
    }),
    makeEvent({
      id: 'demo_evt_04_1',
      requestId: 'demo_wr_04_offers_mkt',
      actorId: PEER_SARA_ID,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم نشر طلب خوذات السلامة لمرفأ الوكرة.',
      createdAt: ago({ hours: 3 }),
    }),
    makeEvent({
      id: 'demo_evt_04_2',
      requestId: 'demo_wr_04_offers_mkt',
      actorId: PROV_SAFETY_ID,
      actorRole: 'provider',
      eventType: 'offer_submitted',
      fromStatus: 'open',
      toStatus: 'offer_received',
      note: 'عرض مقدم من طارق المهندي للسلامة (55 ر.ق رسوم توصيل).',
      metadata: { offerId: 'demo_off_04', feeMinor: 5500 },
      createdAt: ago({ minutes: 40 }),
    }),
    makeEvent({
      id: 'demo_evt_05_1',
      requestId: 'demo_wr_05_offer_sel',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: 'open',
      note: 'تم إنشاء طلب المثقاب الكهربائي لموقع الريان.',
      createdAt: ago({ hours: 4 }),
    }),
    makeEvent({
      id: 'demo_evt_05_2',
      requestId: 'demo_wr_05_offer_sel',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'offer_selected',
      fromStatus: 'offer_received',
      toStatus: 'offer_selected',
      note: 'تم اختيار عرض ناصر الهاجري بانتظار تأكيد بدء التنفيذ.',
      metadata: { offerId: 'demo_off_05', feeMinor: 6000 },
      createdAt: ago({ hours: 1 }),
    }),
    makeEvent({
      id: 'demo_evt_06_1',
      requestId: 'demo_wr_06_accepted',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'offer_accepted',
      fromStatus: 'offer_selected',
      toStatus: 'accepted',
      note: 'تم قبول العرض وإصدار رمز التسليم السري (6 خانات).',
      createdAt: ago({ hours: 3 }),
    }),
    makeEvent({
      id: 'demo_evt_06_2',
      requestId: 'demo_wr_06_accepted',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'payment_status_changed',
      fromStatus: 'accepted',
      toStatus: 'accepted',
      note: 'تم رفع إيصال التحويل البنكي QNB-2026-44102 بانتظار المراجعة.',
      createdAt: ago({ hours: 2 }),
    }),
    makeEvent({
      id: 'demo_evt_07_1',
      requestId: 'demo_wr_07_in_prog',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'offer_accepted',
      fromStatus: 'offer_selected',
      toStatus: 'accepted',
      note: 'تم قبول العرض وتعيين طارق المهندي للتوريد.',
      createdAt: ago({ hours: 5 }),
    }),
    makeEvent({
      id: 'demo_evt_07_2',
      requestId: 'demo_wr_07_in_prog',
      actorId: PROV_SAFETY_ID,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'accepted',
      toStatus: 'in_progress',
      note: 'توجه المزود إلى مورد السلامة المهنية في شارع المطار.',
      createdAt: ago({ hours: 1, minutes: 30 }),
    }),
    makeEvent({
      id: 'demo_evt_08_1',
      requestId: 'demo_wr_08_picked_up',
      actorId: PROV_FAST_ID,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'in_progress',
      toStatus: 'picked_up',
      note: 'تم شراء الكشافات وإرفاق فاتورة المتجر بقيمة 435 ر.ق.',
      createdAt: ago({ minutes: 50 }),
    }),
    makeEvent({
      id: 'demo_evt_09_1',
      requestId: 'demo_wr_09_transit',
      actorId: PROV_MAIN_ID,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'picked_up',
      toStatus: 'in_transit',
      note: 'المزود في الطريق عبر طريق الوكرة السريع نحو مسيعيد.',
      createdAt: ago({ minutes: 30 }),
    }),
    makeEvent({
      id: 'demo_evt_10_1',
      requestId: 'demo_wr_10_deliv_pend',
      actorId: PEER_KHALED_ID,
      actorRole: 'requester',
      eventType: 'offer_accepted',
      fromStatus: 'offer_selected',
      toStatus: 'accepted',
      note: 'تم تعيين المزود وتوليد رمز التسليم السري.',
      createdAt: ago({ hours: 10 }),
    }),
    makeEvent({
      id: 'demo_evt_10_2',
      requestId: 'demo_wr_10_deliv_pend',
      actorId: ownerUid,
      actorRole: 'provider',
      eventType: 'status_changed',
      fromStatus: 'in_transit',
      toStatus: 'delivered_pending_confirmation',
      note: 'وصل المزود إلى بوابة الشيحانية وبانتظار إدخال رمز التسليم T5K9B3.',
      createdAt: ago({ minutes: 10 }),
    }),
    makeEvent({
      id: 'demo_evt_11_1',
      requestId: 'demo_wr_11_comp_cash',
      actorId: PROV_MAIN_ID,
      actorRole: 'provider',
      eventType: 'handover_completed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'completed',
      note: 'تم التحقق من رمز التسليم وإتمام التسليم النقدي في ميناء الرويس.',
      createdAt: ago({ days: 1, hours: 18 }),
    }),
    makeEvent({
      id: 'demo_evt_12_1',
      requestId: 'demo_wr_12_comp_bank',
      actorId: ownerUid,
      actorRole: 'provider',
      eventType: 'handover_completed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'completed',
      note: 'تم تأكيد التسليم في لوسيل وتسوية التحويل البنكي QNB-2026-77419.',
      createdAt: ago({ days: 2, hours: 20 }),
    }),
    makeEvent({
      id: 'demo_evt_13_1',
      requestId: 'demo_wr_13_cancelled',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'status_changed',
      fromStatus: 'open',
      toStatus: 'cancelled',
      note: 'أُلغي الطلب لعدم الحاجة بعد توفر المواد بالمستودع الداخلي.',
      createdAt: ago({ days: 3, hours: 22 }),
    }),
    makeEvent({
      id: 'demo_evt_14_1',
      requestId: 'demo_wr_14_disputed',
      actorId: ownerUid,
      actorRole: 'requester',
      eventType: 'status_changed',
      fromStatus: 'delivered_pending_confirmation',
      toStatus: 'disputed',
      note: 'تم فتح نزاع تشغيلي ومالي لمراجعة اختلاف مقاس الصمامات.',
      createdAt: ago({ hours: 3 }),
    }),
  ];

  const ratingDocs = [
    {
      docPath: `ratings/demo_wr_11_comp_cash_${ownerUid}`,
      collectionKey: 'ratings',
      data: {
        id: `demo_wr_11_comp_cash_${ownerUid}`,
        requestId: 'demo_wr_11_comp_cash',
        fromUserId: ownerUid,
        toUserId: PROV_MAIN_ID,
        fromRole: 'requester',
        toRole: 'provider',
        stars: 5,
        comment: 'التزام تام بالموعد ومطابقة كاملة لفاتورة الشراء في ميناء الرويس.',
        tags: ['on_time', 'accurate_invoice', 'verified_handover'],
        createdAt: ts(ago({ days: 1, hours: 17 })),
      },
    },
    {
      docPath: `ratings/demo_wr_12_comp_bank_${PEER_SARA_ID}`,
      collectionKey: 'ratings',
      data: {
        id: `demo_wr_12_comp_bank_${PEER_SARA_ID}`,
        requestId: 'demo_wr_12_comp_bank',
        fromUserId: PEER_SARA_ID,
        toUserId: ownerUid,
        fromRole: 'requester',
        toRole: 'provider',
        stars: 5,
        comment: 'توريد احترافي وسرعة في إيصال لوحة التوزيع إلى بوليفارد لوسيل.',
        tags: ['fast_delivery', 'professional_handover'],
        createdAt: ts(ago({ days: 2, hours: 19 })),
      },
    },
  ];

  const notificationDocs = [
    {
      docPath: 'notifications/demo_ntf_01',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ntf_01',
        userId: ownerUid,
        title: '3 عروض جديدة على طلب مواسير السباكة',
        titleAr: '3 عروض جديدة على طلب مواسير السباكة',
        titleEn: '3 new offers on your plumbing supply request',
        body: 'تلقيت 3 عروض من مزودين معتمدين بالبطاقة القطرية لموقع مشيرب الدوحة.',
        bodyAr: 'تلقيت 3 عروض من مزودين معتمدين بالبطاقة القطرية لموقع مشيرب الدوحة.',
        bodyEn: 'You received 3 offers from QID-approved providers for Msheireb Doha.',
        type: 'new_offer',
        category: 'worksite_supply',
        requestId: 'demo_wr_03_offers_mine',
        offerId: 'demo_off_01',
        targetRoute: '/work-requests/demo_wr_03_offers_mine',
        isRead: false,
        createdAt: ts(ago({ minutes: 15 })),
        updatedAt: ts(ago({ minutes: 15 })),
      },
    },
    {
      docPath: 'notifications/demo_ntf_02',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ntf_02',
        userId: ownerUid,
        title: 'شحنة مسيعيد في الطريق إلى الموقع',
        titleAr: 'شحنة مسيعيد في الطريق إلى الموقع',
        titleEn: 'Mesaieed delivery is in transit',
        body: 'المزود خالد المناعي في الطريق. رمز تأكيد التسليم السري: H6P2V5',
        bodyAr: 'المزود خالد المناعي في الطريق. رمز تأكيد التسليم السري: H6P2V5',
        bodyEn: 'Provider Khalid Al-Mannai is en route. Secret handover code: H6P2V5',
        type: 'status_update',
        category: 'worksite_supply',
        requestId: 'demo_wr_09_transit',
        targetRoute: '/work-requests/demo_wr_09_transit',
        isRead: false,
        createdAt: ts(ago({ minutes: 30 })),
        updatedAt: ts(ago({ minutes: 30 })),
      },
    },
    {
      docPath: 'notifications/demo_ntf_03',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ntf_03',
        userId: ownerUid,
        title: 'بانتظار إدخال رمز التسليم لمهمة الشيحانية',
        titleAr: 'بانتظار إدخال رمز التسليم لمهمة الشيحانية',
        titleEn: 'Handover verification pending for Al Shahaniya job',
        body: 'أدخل رمز التسليم المكون من 6 خانات (T5K9B3) لإتمام توصيل مضخة المياه.',
        bodyAr: 'أدخل رمز التسليم المكون من 6 خانات (T5K9B3) لإتمام توصيل مضخة المياه.',
        bodyEn: 'Enter the 6-char handover code (T5K9B3) to complete the water pump job.',
        type: 'handover_pending',
        category: 'worksite_supply',
        requestId: 'demo_wr_10_deliv_pend',
        targetRoute: '/work-requests/demo_wr_10_deliv_pend',
        isRead: false,
        createdAt: ts(ago({ minutes: 10 })),
        updatedAt: ts(ago({ minutes: 10 })),
      },
    },
    {
      docPath: 'notifications/demo_ntf_04',
      collectionKey: 'notifications',
      data: {
        id: 'demo_ntf_04',
        userId: ownerUid,
        title: 'تم توثيق السداد وإغلاق طلب الشمال',
        titleAr: 'تم توثيق السداد وإغلاق طلب الشمال',
        titleEn: 'Al Shamal delivery completed & settled',
        body: 'تم إغلاق طلب ميناء الرويس بنجاح وتقييم المزود 5 نجوم.',
        bodyAr: 'تم إغلاق طلب ميناء الرويس بنجاح وتقييم المزود 5 نجوم.',
        bodyEn: 'Ruwais Port order completed and rated 5 stars.',
        type: 'request_completed',
        category: 'worksite_supply',
        requestId: 'demo_wr_11_comp_cash',
        targetRoute: '/work-requests/demo_wr_11_comp_cash',
        isRead: true,
        createdAt: ts(ago({ days: 1 })),
        updatedAt: ts(ago({ days: 1 })),
      },
    },
  ];

  const inq1Date = ago({ hours: 6 });
  const inq2Date = ago({ days: 1 });
  const inq3Date = ago({ days: 2 });
  const investorInquiryDocs = [
    {
      docPath: 'investor_inquiries/demo_inq_qdb_2026',
      collectionKey: 'investor_inquiries',
      data: {
        id: 'demo_inq_qdb_2026',
        fullName: 'طارق المنصور | Tariq Al-Mansoor',
        organization: 'Startup Qatar / QDB Venture Desk',
        email: 'tariq.mansoor@qdb.qa',
        phone: '+974 5512 8840',
        inquiryType: 'جلسة عرض ومراجعة نموذج توريد المواقع (Startup Qatar / VC)',
        notes: 'مراجعة خطة التوسع بين المنطقة الصناعية ولوسيل ومؤشرات الامتثال بالريال القطري.',
        lang: 'ar',
        source: 'landing_page',
        pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
        status: 'new',
        createdAtIso: inq1Date.toISOString(),
        createdAt: ts(inq1Date),
      },
    },
    {
      docPath: 'investor_inquiries/demo_inq_qstp_2026',
      collectionKey: 'investor_inquiries',
      data: {
        id: 'demo_inq_qstp_2026',
        fullName: 'Nadia Al-Kuwari',
        organization: 'QSTP Incubation & Tech Review',
        email: 'n.alkuwari@qstp.org.qa',
        phone: '+974 4454 7120',
        inquiryType: 'B2B Pilot & Security Rules Walkthrough',
        notes:
          'Requested live walkthrough of QID 11-digit KYC review and SHA-256 handover verification.',
        lang: 'en',
        source: 'landing_page',
        pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
        status: 'contacted',
        createdAtIso: inq2Date.toISOString(),
        createdAt: ts(inq2Date),
      },
    },
    {
      docPath: 'investor_inquiries/demo_inq_almadar_b2b',
      collectionKey: 'investor_inquiries',
      data: {
        id: 'demo_inq_almadar_b2b',
        fullName: 'م. خالد العطية',
        organization: 'شركة المدار للمقاولات - لوسيل',
        email: 'khaled@almadar-contracting.qa',
        phone: '+974 5031 2290',
        inquiryType: 'شراكة توريد يومي للمواقع الإنشائية (B2B Supply)',
        notes: 'تغطية 12 موقع عمل بين المنطقة الصناعية ولوسيل والوكرة.',
        lang: 'ar',
        source: 'web_app',
        pageUrl: 'https://mashwar-qatar.vercel.app',
        status: 'new',
        createdAtIso: inq3Date.toISOString(),
        createdAt: ts(inq3Date),
      },
    },
  ];

  const auditLogDocs = [
    {
      docPath: 'admin_audit_logs/demo_aud_01',
      collectionKey: 'admin_audit_logs',
      data: {
        id: 'demo_aud_01',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        actor: `${ownerName} (superAdmin)`,
        action: 'provider_review',
        targetCollection: 'provider_profiles',
        targetEntityId: PROV_MAIN_ID,
        target: `provider_profiles/${PROV_MAIN_ID}`,
        previousState: { approvalStatus: 'pending' },
        newState: { approvalStatus: 'approved' },
        reason: 'تم التحقق من البطاقة القطرية QID والاستمارة',
        beforeAfter: 'pending ← approved (QID verified)',
        createdAt: ts(ago({ days: 2 })),
      },
    },
    {
      docPath: 'admin_audit_logs/demo_aud_02',
      collectionKey: 'admin_audit_logs',
      data: {
        id: 'demo_aud_02',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        actor: `${ownerName} (superAdmin)`,
        action: 'verify_payment_settled',
        targetCollection: 'work_requests',
        targetEntityId: 'demo_wr_12_comp_bank',
        target: 'work_requests/demo_wr_12_comp_bank',
        previousState: { paymentStatus: 'transfer_proof_submitted' },
        newState: {
          paymentStatus: 'verified_settled',
          paymentReference: 'QNB-2026-77419',
        },
        reason: 'Ref: QNB-2026-77419',
        beforeAfter: 'transfer_proof_submitted ← verified_settled (QNB-2026-77419)',
        createdAt: ts(ago({ days: 1, hours: 12 })),
      },
    },
    {
      docPath: 'admin_audit_logs/demo_aud_03',
      collectionKey: 'admin_audit_logs',
      data: {
        id: 'demo_aud_03',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        actor: `${ownerName} (superAdmin)`,
        action: 'provider_review',
        targetCollection: 'provider_profiles',
        targetEntityId: PROV_REJECTED_ID,
        target: `provider_profiles/${PROV_REJECTED_ID}`,
        previousState: { approvalStatus: 'pending' },
        newState: { approvalStatus: 'rejected' },
        reason: 'صورة الوجه الخلفي للبطاقة القطرية منتهية الصلاحية',
        beforeAfter: 'pending ← rejected (Expired QID back photo)',
        createdAt: ts(ago({ days: 1 })),
      },
    },
    {
      docPath: 'admin_audit_logs/demo_aud_04',
      collectionKey: 'admin_audit_logs',
      data: {
        id: 'demo_aud_04',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        actor: `${ownerName} (superAdmin)`,
        action: 'moderate_flag_dispute',
        targetCollection: 'work_requests',
        targetEntityId: 'demo_wr_14_disputed',
        target: 'work_requests/demo_wr_14_disputed',
        previousState: { status: 'delivered_pending_confirmation' },
        newState: { status: 'disputed' },
        reason: 'اختلاف مقاس الصمامات الموردة عن المواصفة الهندسية',
        beforeAfter: 'delivered_pending_confirmation ← disputed',
        createdAt: ts(ago({ hours: 3 })),
      },
    },
  ];

  return {
    allDocs: [
      ...adminStaffDocs,
      ...userDocs,
      ...savedWorksiteDocs,
      ...providerProfileDocs,
      ...providerVerificationDocs,
      ...workRequestDocs,
      ...workOfferDocs,
      ...secretDocs,
      ...handoverViewDocs,
      ...requestEventDocs,
      ...ratingDocs,
      ...notificationDocs,
      ...investorInquiryDocs,
      ...auditLogDocs,
    ],
    absentDocPaths: [`provider_verifications/${PROV_UNVERIFIED_ID}`],
  };
}

async function verifyActiveFirestoreRules({ rulesClient, projectId }) {
  const localRulesPath = path.join(REPO_ROOT, 'firestore.rules');
  const localContent = fs.readFileSync(localRulesPath, 'utf8').replace(/\r\n/g, '\n').trim();

  const relRes = await rulesClient.get(`/v1/projects/${projectId}/releases/cloud.firestore`, {
    headers: { 'x-goog-user-project': projectId },
  });
  const rulesetName = relRes.body?.rulesetName;
  if (!rulesetName) {
    throw new Error(
      `Active cloud.firestore release has no rulesetName: ${JSON.stringify(relRes.body)}`,
    );
  }

  const rsRes = await rulesClient.get(`/v1/${rulesetName}`, {
    headers: { 'x-goog-user-project': projectId },
  });
  const files = rsRes.body?.source?.files || [];
  const rulesFile = files.find((f) => f.name === 'firestore.rules') || files[0];
  const remoteContent = (rulesFile?.content || '').replace(/\r\n/g, '\n').trim();

  if (remoteContent !== localContent) {
    throw new Error(
      `Active cloud.firestore ruleset (${rulesetName}) does NOT match local firestore.rules (remote ${remoteContent.length} chars vs local ${localContent.length} chars).`,
    );
  }

  return {
    rulesetName,
    updateTime: relRes.body?.updateTime || relRes.body?.createTime || 'unknown',
    bytes: Buffer.byteLength(localContent, 'utf8'),
  };
}

async function ensureOrVerifyAdminClaim({ identityClient, projectId, ownerUid, verifyOnly }) {
  const lookup = async () => {
    const res = await identityClient.post(
      `/v1/projects/${projectId}/accounts:lookup`,
      { localId: [ownerUid] },
      { headers: { 'x-goog-user-project': projectId } },
    );
    const user = res.body?.users?.[0];
    if (!user) {
      throw new Error(
        `Firebase Auth user '${ownerUid}' not found in project '${projectId}'.`,
      );
    }
    let claims = {};
    if (user.customAttributes) {
      try {
        claims = JSON.parse(user.customAttributes);
      } catch {
        claims = {};
      }
    }
    return { user, claims };
  };

  let { user, claims } = await lookup();

  if (!verifyOnly && (claims.admin !== true || claims.role !== 'superAdmin')) {
    const mergedClaims = {
      ...claims,
      admin: true,
      role: 'superAdmin',
    };
    await identityClient.post(
      `/v1/projects/${projectId}/accounts:update`,
      {
        localId: ownerUid,
        customAttributes: JSON.stringify(mergedClaims),
      },
      { headers: { 'x-goog-user-project': projectId } },
    );
    ({ user, claims } = await lookup());
  }

  if (claims.admin !== true || claims.role !== 'superAdmin') {
    throw new Error(
      `Expected custom claims { admin: true, role: "superAdmin" } on UID ${ownerUid}, found: ${JSON.stringify(claims)}`,
    );
  }

  return {
    uid: user.localId,
    email: user.email || '',
    displayName: user.displayName || '',
    claims,
  };
}

async function commitDemoDataset({ firestoreClient, projectId, allDocs, absentDocPaths }) {
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const writes = [
    ...allDocs.map((entry) => ({
      update: {
        name: `${dbRoot}/${entry.docPath}`,
        fields: encodeFirestoreFields(entry.data),
      },
    })),
    ...absentDocPaths.map((docPath) => ({
      delete: `${dbRoot}/${docPath}`,
    })),
  ];

  // Firestore commit limit is 500 writes per batch; chunk at 200 for fast reliability.
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

async function verifyDemoDatasetReadback({ firestoreClient, projectId, allDocs, absentDocPaths }) {
  const dbRoot = `projects/${projectId}/databases/(default)/documents`;
  const expectedNames = allDocs.map((d) => `${dbRoot}/${d.docPath}`);
  const absentNames = absentDocPaths.map((p) => `${dbRoot}/${p}`);
  const allLookupNames = [...expectedNames, ...absentNames];

  const foundByPath = new Map();
  const missingPaths = new Set();

  const chunkSize = 90;
  for (let i = 0; i < allLookupNames.length; i += chunkSize) {
    const slice = allLookupNames.slice(i, i + chunkSize);
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
      } else if (item.missing) {
        const relPath = String(item.missing).slice(dbRoot.length + 1);
        missingPaths.add(relPath);
      }
    }
  }

  const errors = [];
  const countsByCollection = new Map();

  for (const entry of allDocs) {
    countsByCollection.set(entry.collectionKey, countsByCollection.get(entry.collectionKey) || {
      expected: 0,
      found: 0,
    });
    const stat = countsByCollection.get(entry.collectionKey);
    stat.expected += 1;

    if (foundByPath.has(entry.docPath)) {
      stat.found += 1;
    } else {
      errors.push(`Missing seeded document: ${entry.docPath}`);
    }
  }

  for (const absentPath of absentDocPaths) {
    if (foundByPath.has(absentPath)) {
      errors.push(`Expected unverified provider doc '${absentPath}' to be absent, but it exists.`);
    }
  }

  // Deep domain invariants across live readback
  const liveRequests = allDocs
    .filter((d) => d.collectionKey === 'work_requests')
    .map((d) => foundByPath.get(d.docPath))
    .filter(Boolean);

  const seenStatuses = new Set(liveRequests.map((r) => r.status));
  for (const st of EXPECTED_STATUSES) {
    if (!seenStatuses.has(st)) {
      errors.push(`Missing WorkRequestStatus '${st}' in live work_requests.`);
    }
  }

  const seenPaymentMethods = new Set(liveRequests.map((r) => r.paymentMethod));
  for (const pm of EXPECTED_PAYMENT_METHODS) {
    if (!seenPaymentMethods.has(pm)) {
      errors.push(`Missing PaymentMethod '${pm}' in live work_requests.`);
    }
  }

  const seenPaymentStatuses = new Set(liveRequests.map((r) => r.paymentStatus));
  for (const ps of EXPECTED_PAYMENT_STATUSES) {
    if (!seenPaymentStatuses.has(ps)) {
      errors.push(`Missing PaymentSettlementStatus '${ps}' in live work_requests.`);
    }
  }

  const seenAreas = new Set(liveRequests.map((r) => r.deliveryArea));
  for (const mun of EXPECTED_QATAR_MUNICIPALITIES) {
    if (!seenAreas.has(mun)) {
      errors.push(`Missing Qatar municipality '${mun}' in live work_requests.`);
    }
  }

  for (const req of liveRequests) {
    if (req.assignedProviderId && req.assignedProviderId === req.requesterId) {
      errors.push(`Self-assigned request detected on ${req.id}: ${req.requesterId}`);
    }
  }

  const liveProviders = allDocs
    .filter((d) => d.collectionKey === 'provider_profiles')
    .map((d) => foundByPath.get(d.docPath))
    .filter(Boolean);
  const seenProvStatuses = new Set(liveProviders.map((p) => p.approvalStatus));
  for (const ps of EXPECTED_PROVIDER_STATUSES) {
    if (!seenProvStatuses.has(ps)) {
      errors.push(`Missing ProviderApprovalStatus '${ps}' in live provider_profiles.`);
    }
  }

  // Competing offers check on demo_wr_03_offers_mine
  const req03Offers = ['demo_off_01', 'demo_off_02', 'demo_off_03']
    .map((id) => foundByPath.get(`work_offers/${id}`))
    .filter(Boolean);
  if (req03Offers.length !== 3) {
    errors.push(`Expected 3 competing offers on demo_wr_03_offers_mine, found ${req03Offers.length}.`);
  }

  // Cryptographic SHA-256 handover verification check on all 5 codes
  for (const [requestId, expectedCode] of Object.entries(HANDOVER_CODES)) {
    const secret = foundByPath.get(`work_request_secrets/${requestId}`);
    const view = foundByPath.get(`work_request_handover_view/${requestId}`);
    if (!secret || !view) {
      errors.push(`Missing secret or handover view for ${requestId}`);
      continue;
    }
    if (view.handoverCode !== expectedCode) {
      errors.push(
        `Handover code mismatch on ${requestId}: expected ${expectedCode}, got ${view.handoverCode}`,
      );
    }
    const recomputed = hashHandoverCode(expectedCode, secret.codeSalt);
    if (recomputed !== secret.codeHash) {
      errors.push(`SHA-256 hash mismatch on work_request_secrets/${requestId}`);
    }
  }

  return { countsByCollection, errors };
}

async function main() {
  const args = parseArgs(process.argv);
  const ftLib = resolveFirebaseToolsLib();

  const auth = require(path.join(ftLib, 'auth'));
  const { requireAuth } = require(path.join(ftLib, 'requireAuth'));
  const apiv2 = require(path.join(ftLib, 'apiv2'));
  const api = require(path.join(ftLib, 'api'));

  // Required Firebase CLI OAuth authentication sequence
  const acct = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
  if (!acct) {
    throw new Error('No authenticated Firebase CLI account found. Run `firebase login` first.');
  }
  const opts = { project: args.projectId };
  auth.setActiveAccount(opts, acct);
  await requireAuth(opts);

  const rulesClient = new apiv2.Client({ urlPrefix: api.rulesOrigin(), auth: true });
  const identityClient = new apiv2.Client({ urlPrefix: api.identityOrigin(), auth: true });
  const firestoreClient = new apiv2.Client({ urlPrefix: api.firestoreOrigin(), auth: true });

  console.log(
    `=== MASHWAR Qatar Demo ${args.verifyOnly ? 'Verification (--verify-only)' : 'Seeder & Verifier'} [${args.projectId}] ===`,
  );

  if (!args.skipRulesCheck) {
    const rulesInfo = await verifyActiveFirestoreRules({
      rulesClient,
      projectId: args.projectId,
    });
    console.log(
      `[OK] Active cloud.firestore release verified: ${rulesInfo.rulesetName} (${rulesInfo.bytes} bytes, updated ${rulesInfo.updateTime})`,
    );
  }

  const claimInfo = await ensureOrVerifyAdminClaim({
    identityClient,
    projectId: args.projectId,
    ownerUid: args.ownerUid,
    verifyOnly: args.verifyOnly,
  });
  console.log(
    `[OK] Firebase Auth custom claims verified for ${claimInfo.uid} (${claimInfo.email}): ${JSON.stringify(claimInfo.claims)}`,
  );

  const dataset = buildCatalogDataset({
    ownerUid: args.ownerUid,
    ownerEmail: args.ownerEmail,
    ownerName: args.ownerName,
    now: new Date(),
  });

  if (!args.verifyOnly) {
    const writeCount = await commitDemoDataset({
      firestoreClient,
      projectId: args.projectId,
      allDocs: dataset.allDocs,
      absentDocPaths: dataset.absentDocPaths,
    });
    console.log(`[OK] Committed ${writeCount} idempotent Firestore operations.`);
  }

  const { countsByCollection, errors } = await verifyDemoDatasetReadback({
    firestoreClient,
    projectId: args.projectId,
    allDocs: dataset.allDocs,
    absentDocPaths: dataset.absentDocPaths,
  });

  console.log('\nCollection Readback Summary:');
  console.log('------------------------------------------------------------');
  let totalExpected = 0;
  let totalFound = 0;
  for (const [col, stat] of countsByCollection.entries()) {
    totalExpected += stat.expected;
    totalFound += stat.found;
    const label =
      col === 'saved_worksites' ? 'saved_worksites (users/{uid}/private)' : col;
    console.log(
      `  ${label.padEnd(40)} ${String(stat.found).padStart(3)} / ${String(stat.expected).padStart(3)}`,
    );
  }
  console.log('------------------------------------------------------------');
  console.log(
    `  ${'TOTAL SEEDED DOCUMENTS'.padEnd(40)} ${String(totalFound).padStart(3)} / ${String(totalExpected).padStart(3)}`,
  );
  console.log(
    `  Handover Codes Verified (SHA-256):       ${Object.entries(HANDOVER_CODES)
      .map(([k, v]) => `${k}=${v}`)
      .join(', ')}`,
  );

  if (errors.length > 0) {
    console.error('\n[FAIL] Verification errors detected:');
    for (const err of errors) {
      console.error(`  - ${err}`);
    }
    process.exit(1);
  }

  console.log('\n[PASS] All live Firestore demo collections, invariants, and claims verified.');
}

main().catch((err) => {
  console.error('[ERROR]', err && err.stack ? err.stack : String(err));
  process.exit(1);
});
