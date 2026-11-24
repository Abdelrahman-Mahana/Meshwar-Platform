import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../../models/worksite_models.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../contracts/i_provider_repository.dart';

/// Persistence gateway used by [FirebaseProviderRepository] so unit tests can
/// exercise Firestore mapping and rules alignment without sealed SDK mocks.
@visibleForTesting
abstract interface class FirebaseProviderStore {
  Future<Map<String, dynamic>?> getProviderProfileDoc(String uid);

  Future<Map<String, dynamic>?> getProviderVerificationDoc(String uid);

  Future<void> setProviderProfileDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  });

  Future<void> updateProviderProfileDoc(
    String uid,
    Map<String, dynamic> patch,
  );

  Future<void> setProviderVerificationDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  });

  Future<void> updateProviderVerificationDoc(
    String uid,
    Map<String, dynamic> patch,
  );

  Future<List<Map<String, dynamic>>> queryPendingProviderProfiles(int limit);

  Future<void> saveWorksiteDoc(
    String ownerUid,
    String worksiteId,
    Map<String, dynamic> data, {
    required bool clearExistingDefaults,
  });

  Future<List<Map<String, dynamic>>> listSavedWorksiteDocs(String ownerUid);
}

class _FirestoreProviderStore implements FirebaseProviderStore {
  final FirebaseFirestore? _injectedFirestore;

  _FirestoreProviderStore([this._injectedFirestore]);

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getProviderProfileDoc(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.providerProfiles)
        .doc(uid)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return normalizeFirestoreDocument(snap.data()!, fallbackId: snap.id);
  }

  @override
  Future<Map<String, dynamic>?> getProviderVerificationDoc(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.providerVerifications)
        .doc(uid)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return normalizeFirestoreDocument(snap.data()!, fallbackId: snap.id);
  }

  @override
  Future<void> setProviderProfileDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore
        .collection(FirestoreCollections.providerProfiles)
        .doc(uid)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> updateProviderProfileDoc(
    String uid,
    Map<String, dynamic> patch,
  ) async {
    await _firestore
        .collection(FirestoreCollections.providerProfiles)
        .doc(uid)
        .update(patch);
  }

  @override
  Future<void> setProviderVerificationDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore
        .collection(FirestoreCollections.providerVerifications)
        .doc(uid)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> updateProviderVerificationDoc(
    String uid,
    Map<String, dynamic> patch,
  ) async {
    await _firestore
        .collection(FirestoreCollections.providerVerifications)
        .doc(uid)
        .update(patch);
  }

  @override
  Future<List<Map<String, dynamic>>> queryPendingProviderProfiles(
    int limit,
  ) async {
    final snap = await _firestore
        .collection(FirestoreCollections.providerProfiles)
        .where('approvalStatus', isEqualTo: ProviderApprovalStatus.pending.value)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => normalizeFirestoreDocument(doc.data(), fallbackId: doc.id))
        .toList();
  }

  @override
  Future<void> saveWorksiteDoc(
    String ownerUid,
    String worksiteId,
    Map<String, dynamic> data, {
    required bool clearExistingDefaults,
  }) async {
    final collection = _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUid)
        .collection(FirestoreCollections.userPrivateSubcollection);

    final batch = _firestore.batch();
    if (clearExistingDefaults) {
      final existing = await collection
          .where('docType', isEqualTo: 'saved_worksite')
          .where('isDefault', isEqualTo: true)
          .get();
      for (final doc in existing.docs) {
        if (doc.id != worksiteId) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
    }
    batch.set(collection.doc(worksiteId), data);
    await batch.commit();
  }

  @override
  Future<List<Map<String, dynamic>>> listSavedWorksiteDocs(
    String ownerUid,
  ) async {
    final snap = await _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUid)
        .collection(FirestoreCollections.userPrivateSubcollection)
        .where('docType', isEqualTo: 'saved_worksite')
        .get();
    return snap.docs
        .map((doc) => normalizeFirestoreDocument(doc.data(), fallbackId: doc.id))
        .toList();
  }
}

/// Production Cloud Firestore + Cloud Functions implementation of [IProviderRepository].
class FirebaseProviderRepository implements IProviderRepository {
  static final RegExp _qatarQidRegex = RegExp(r'^[0-9]{11}$');
  static final RegExp _phoneRegex =
      RegExp(r'^(?:\+?974)?[3567][0-9]{7}$|^\+?[0-9\s-]{10,20}$');

  final Future<String?> Function() _currentUidProvider;
  final FirebaseFunctionsCallableClient _functionsClient;
  final FirebaseProviderStore _store;

  FirebaseProviderRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctionsCallableClient? functionsClient,
  })  : _currentUidProvider = (() async =>
            (firebaseAuth ?? fb_auth.FirebaseAuth.instance).currentUser?.uid),
        _functionsClient = functionsClient ??
            FirebaseFunctionsCallableClient(
              idTokenProvider: () async =>
                  (firebaseAuth ?? fb_auth.FirebaseAuth.instance)
                      .currentUser
                      ?.getIdToken(),
            ),
        _store = _FirestoreProviderStore(firestore);

  @visibleForTesting
  FirebaseProviderRepository.withDeps({
    required Future<String?> Function() currentUidProvider,
    required FirebaseFunctionsCallableClient functionsClient,
    required FirebaseProviderStore store,
  })  : _currentUidProvider = currentUidProvider,
        _functionsClient = functionsClient,
        _store = store;

  Future<String> _requireSignedInUid({String? expectedUid}) async {
    final uid = (await _currentUidProvider())?.trim();
    if (uid == null || uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    if (expectedUid != null &&
        expectedUid.trim().isNotEmpty &&
        expectedUid.trim() != uid) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'لا يمكنك تعديل ملف مستخدم آخر.',
        messageEn: 'Authenticated UID does not match target userId.',
      );
    }
    return uid;
  }

  @override
  Future<ProviderProfile?> getProviderProfile(String userId) async {
    final callerUid = await _requireSignedInUid();
    final targetUid = userId.trim();
    if (targetUid.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'معرف المزود مطلوب.',
        messageEn: 'userId is required.',
      );
    }

    try {
      final profileData = await _store.getProviderProfileDoc(targetUid);
      if (profileData == null) return null;

      Map<String, dynamic>? verificationData;
      if (callerUid == targetUid) {
        try {
          verificationData = await _store.getProviderVerificationDoc(targetUid);
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied' && e.code != 'not-found') {
            rethrow;
          }
        }
      }
      return _mergeProfileAndVerification(profileData, verificationData);
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<ProviderProfile> upsertProviderProfile(ProviderProfile profile) async {
    final uid = await _requireSignedInUid(expectedUid: profile.userId);
    final fullName = profile.fullName.trim();
    final phone = profile.phone.trim();
    final vehicleType = (profile.vehicleType ?? '').trim();
    final vehiclePlate = (profile.vehiclePlate ?? '').trim();

    if (fullName.length < 2 || fullName.length > 120) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'الاسم الكامل يجب أن يكون بين حرفين و120 حرفاً.',
        messageEn: 'Provider fullName must be between 2 and 120 characters.',
      );
    }
    if (!_phoneRegex.hasMatch(phone)) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'أدخل رقم جوال قطري صحيح.',
        messageEn: 'Valid Qatar mobile phone number is required.',
      );
    }
    if (vehicleType.isEmpty || vehicleType.length > 80) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى تحديد نوع المركبة.',
        messageEn: 'vehicleType is required (1-80 characters).',
      );
    }
    if (vehiclePlate.isEmpty || vehiclePlate.length > 40) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى إدخال رقم لوحة المركبة.',
        messageEn: 'vehiclePlate is required (1-40 characters).',
      );
    }
    final areas = profile.serviceMunicipalities
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(15)
        .toList();

    try {
      final existing = await _store.getProviderProfileDoc(uid);
      if (existing == null) {
        // Strictly adheres to firestore.rules provider_profiles create schema.
        await _store.setProviderProfileDoc(uid, {
          'id': uid,
          'userId': uid,
          'fullName': fullName,
          'phone': phone,
          'vehicleType': vehicleType,
          'vehiclePlate': vehiclePlate,
          'serviceAreas': areas,
          'approvalStatus': ProviderApprovalStatus.pending.value,
          'completedTasksCount': 0,
          'ratingAvg': 0.0,
          'ratingCount': 0,
          'reviewedBy': null,
          'reviewedAtUtc': null,
          'rejectionReason': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Never touch immutable or server-managed approval/rating fields.
        await _store.updateProviderProfileDoc(uid, {
          'fullName': fullName,
          'phone': phone,
          'vehicleType': vehicleType,
          'vehiclePlate': vehiclePlate,
          'serviceAreas': areas,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final refreshed = await _store.getProviderProfileDoc(uid);
      if (refreshed == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر قراءة ملف المزود بعد الحفظ.',
          messageEn: 'Failed to reload provider profile after saving.',
        );
      }
      return ProviderProfile.fromJson(refreshed);
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<ProviderProfile> submitProviderVerification({
    required String userId,
    required String qidNumber,
    required String qidFrontUrl,
    required String qidBackUrl,
    String? selfieUrl,
    String? vehicleType,
    String? vehiclePlate,
    List<String> serviceMunicipalities = const [],
    List<String> supplySpecialties = const [],
  }) async {
    final uid = await _requireSignedInUid(expectedUid: userId);
    final cleanQid = qidNumber.trim();
    final cleanFront = qidFrontUrl.trim();
    final cleanBack = qidBackUrl.trim();
    final cleanSelfie = (selfieUrl ?? '').trim();

    if (!_qatarQidRegex.hasMatch(cleanQid)) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'البطاقة الشخصية القطرية (QID) يجب أن تتكون من 11 رقماً.',
        messageEn: 'Qatar QID must be exactly 11 numeric digits.',
      );
    }
    if (!_isValidMvpUrl(cleanFront) ||
        !_isValidMvpUrl(cleanBack) ||
        !_isValidMvpUrl(cleanSelfie)) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr:
            'روابط صور البطاقة القطرية وصورة السيلفي مطلوبة بصيغة HTTPS أو GS.',
        messageEn:
            'Valid HTTPS/HTTP/GS URLs are required for QID front, back, and selfie.',
      );
    }

    try {
      var profileDoc = await _store.getProviderProfileDoc(uid);
      if (profileDoc == null) {
        final cleanVehicleType = (vehicleType ?? '').trim();
        final cleanVehiclePlate = (vehiclePlate ?? '').trim();
        if (cleanVehicleType.isEmpty || cleanVehiclePlate.isEmpty) {
          throw const WorksiteRepositoryException(
            code: 'failed-precondition',
            messageAr: 'يرجى حفظ ملف المركبة وبيانات التواصل قبل إرسال التوثيق.',
            messageEn:
                'Provider profile with vehicleType and vehiclePlate must be saved before submitting KYC.',
          );
        }
        await _store.setProviderProfileDoc(uid, {
          'id': uid,
          'userId': uid,
          'fullName': 'مزود خدمات',
          'phone': '55000000',
          'vehicleType': cleanVehicleType,
          'vehiclePlate': cleanVehiclePlate,
          'serviceAreas': serviceMunicipalities
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .take(15)
              .toList(),
          'approvalStatus': ProviderApprovalStatus.pending.value,
          'completedTasksCount': 0,
          'ratingAvg': 0.0,
          'ratingCount': 0,
          'reviewedBy': null,
          'reviewedAtUtc': null,
          'rejectionReason': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        profileDoc = await _store.getProviderProfileDoc(uid);
      } else if ((vehicleType != null && vehicleType.trim().isNotEmpty) ||
          (vehiclePlate != null && vehiclePlate.trim().isNotEmpty) ||
          serviceMunicipalities.isNotEmpty) {
        await _store.updateProviderProfileDoc(uid, {
          if (vehicleType != null && vehicleType.trim().isNotEmpty)
            'vehicleType': vehicleType.trim(),
          if (vehiclePlate != null && vehiclePlate.trim().isNotEmpty)
            'vehiclePlate': vehiclePlate.trim(),
          if (serviceMunicipalities.isNotEmpty)
            'serviceAreas': serviceMunicipalities
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .take(15)
                .toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        profileDoc = await _store.getProviderProfileDoc(uid);
      }

      final providerName =
          (profileDoc?['fullName']?.toString().trim().isNotEmpty == true)
              ? profileDoc!['fullName'].toString().trim()
              : 'مزود خدمات';

      final existingVerification = await _store.getProviderVerificationDoc(uid);
      if (existingVerification == null) {
        await _store.setProviderVerificationDoc(uid, {
          'id': uid,
          'providerId': uid,
          'fullName': providerName,
          'qidNumber': cleanQid,
          'qidFrontUrl': cleanFront,
          'qidBackUrl': cleanBack,
          'selfieUrl': cleanSelfie,
          'status': 'pending',
          'rejectionReason': null,
          'reviewedBy': null,
          'reviewedAtUtc': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _store.updateProviderVerificationDoc(uid, {
          'fullName': providerName,
          'qidNumber': cleanQid,
          'qidFrontUrl': cleanFront,
          'qidBackUrl': cleanBack,
          'selfieUrl': cleanSelfie,
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final verificationDoc = await _store.getProviderVerificationDoc(uid);
      return _mergeProfileAndVerification(
        profileDoc ?? {'id': uid, 'userId': uid, 'fullName': providerName},
        verificationDoc,
      );
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<List<ProviderProfile>> listPendingVerifications({int limit = 50}) async {
    await _requireSignedInUid();
    try {
      final docs = await _store.queryPendingProviderProfiles(limit);
      final profiles = <ProviderProfile>[];
      for (final doc in docs) {
        final uid = (doc['userId'] ?? doc['id'] ?? '').toString();
        Map<String, dynamic>? verification;
        if (uid.isNotEmpty) {
          try {
            verification = await _store.getProviderVerificationDoc(uid);
          } on FirebaseException catch (e) {
            if (e.code != 'permission-denied' && e.code != 'not-found') {
              rethrow;
            }
          }
        }
        profiles.add(_mergeProfileAndVerification(doc, verification));
      }
      return profiles;
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<ProviderProfile> reviewProviderApproval({
    required String userId,
    required ProviderApprovalStatus decision,
    required String reviewerId,
    String? reason,
  }) async {
    await _requireSignedInUid(expectedUid: reviewerId);
    final targetUid = userId.trim();
    if (targetUid.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'معرف المزود مطلوب.',
        messageEn: 'userId is required.',
      );
    }

    await _functionsClient.call('adminReviewProvider', {
      'providerId': targetUid,
      'decision': decision.value,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });

    final refreshed = await getProviderProfile(targetUid);
    if (refreshed == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'ملف مزود الخدمة غير موجود.',
        messageEn: 'Provider profile not found after review.',
      );
    }
    return refreshed;
  }

  @override
  Future<SavedWorksite> saveWorksite(SavedWorksite worksite) async {
    final uid = await _requireSignedInUid(expectedUid: worksite.ownerUserId);
    if (worksite.label.trim().isEmpty ||
        worksite.municipality.trim().isEmpty ||
        worksite.zoneOrStreet.trim().isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى إدخال اسم الموقع والبلدية والعنوان.',
        messageEn: 'Worksite label, municipality, and zoneOrStreet are required.',
      );
    }

    final worksiteId = worksite.id.trim().isNotEmpty
        ? worksite.id.trim()
        : 'site_${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final normalized = worksite.copyWith(
      id: worksiteId,
      ownerUserId: uid,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      await _store.saveWorksiteDoc(
        uid,
        worksiteId,
        {
          ...normalized.toJson(),
          'docType': 'saved_worksite',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        clearExistingDefaults: normalized.isDefault,
      );
      return normalized;
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<List<SavedWorksite>> listSavedWorksites(String ownerUserId) async {
    final uid = await _requireSignedInUid(expectedUid: ownerUserId);
    try {
      final docs = await _store.listSavedWorksiteDocs(uid);
      return docs.map(SavedWorksite.fromJson).toList()
        ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  ProviderProfile _mergeProfileAndVerification(
    Map<String, dynamic> profileJson,
    Map<String, dynamic>? verificationJson,
  ) {
    final merged = Map<String, dynamic>.from(profileJson);
    if (verificationJson != null) {
      merged['qidNumber'] ??= verificationJson['qidNumber'];
      merged['qidFrontUrl'] ??= verificationJson['qidFrontUrl'];
      merged['qidBackUrl'] ??= verificationJson['qidBackUrl'];
      merged['selfieUrl'] ??= verificationJson['selfieUrl'];
    }
    return ProviderProfile.fromJson(merged);
  }

  bool _isValidMvpUrl(String url) {
    return url.length >= 8 &&
        url.length <= 1000 &&
        (url.startsWith('https://') ||
            url.startsWith('http://') ||
            url.startsWith('gs://'));
  }
}
