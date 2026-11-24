import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_environment.dart';

/// Typed bilingual exception thrown by [MediaUploadService] whenever picking,
/// validating, or uploading binary media fails.
class MediaUploadException implements Exception {
  final String code;
  final String messageEn;
  final String messageAr;

  const MediaUploadException({
    required this.code,
    required this.messageEn,
    required this.messageAr,
  });

  String localizedMessage({required bool isArabic}) =>
      isArabic ? messageAr : messageEn;

  @override
  String toString() => '$messageAr | $messageEn';

  factory MediaUploadException.fromFirebase(FirebaseException error) {
    final normalized = error.code.trim().toLowerCase();
    switch (normalized) {
      case 'unauthorized':
      case 'permission-denied':
        return const MediaUploadException(
          code: 'permission-denied',
          messageEn:
              'You do not have permission to upload this image under Storage security rules.',
          messageAr:
              'ليس لديك صلاحية لرفع هذه الصورة وفق قواعد أمان التخزين السحابي.',
        );
      case 'unauthenticated':
        return const MediaUploadException(
          code: 'unauthenticated',
          messageEn: 'Please sign in before uploading images.',
          messageAr: 'يرجى تسجيل الدخول قبل رفع الصور.',
        );
      case 'canceled':
        return const MediaUploadException(
          code: 'canceled',
          messageEn: 'Image upload was canceled.',
          messageAr: 'تم إلغاء عملية رفع الصورة.',
        );
      case 'quota-exceeded':
        return const MediaUploadException(
          code: 'quota-exceeded',
          messageEn:
              'Cloud Storage quota has been exceeded. Please try again later.',
          messageAr:
              'تم تجاوز حصة التخزين السحابي المتاحة حالياً. حاول لاحقاً.',
        );
      case 'retry-limit-exceeded':
        return const MediaUploadException(
          code: 'unavailable',
          messageEn:
              'Upload timed out due to unstable network. Check your connection and retry.',
          messageAr:
              'انتهت مهلة رفع الصورة بسبب ضعف الاتصال. تحقق من الإنترنت وأعد المحاولة.',
        );
      default:
        return MediaUploadException(
          code: normalized.isEmpty ? 'storage-error' : normalized,
          messageEn: error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Failed to upload image to Firebase Storage (${error.code}).',
          messageAr: 'تعذّر رفع الصورة إلى التخزين السحابي (${error.code}).',
        );
    }
  }
}

/// Immutable result of a validated binary image upload.
@immutable
class MediaUploadResult {
  final String downloadUrl;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final Uint8List bytes;
  final bool isDevMock;

  const MediaUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
    required this.isDevMock,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }
}

/// Binary storage gateway abstraction for clean unit testing of [FirebaseStorage]
/// uploads (`putData` + `SettableMetadata(contentType: mime)` + `getDownloadURL`).
abstract interface class MediaStorageGateway {
  Future<String> putBytes({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  });
}

class FirebaseMediaStorageGateway implements MediaStorageGateway {
  final FirebaseStorage _storage;

  FirebaseMediaStorageGateway({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> putBytes({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    final normalizedRefPath =
        storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;
    final ref = _storage.ref(normalizedRefPath);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMetadata,
    );
    final snapshot = await ref.putData(bytes, metadata);
    final url = await snapshot.ref.getDownloadURL();
    if (url.trim().isEmpty) {
      throw const MediaUploadException(
        code: 'empty-download-url',
        messageEn: 'Firebase Storage returned an empty download URL.',
        messageAr: 'أرجع التخزين السحابي رابط تنزيل فارغاً.',
      );
    }
    return url.trim();
  }
}

typedef MediaImagePickerFn = Future<XFile?> Function({
  required ImageSource source,
  int? imageQuality,
  double? maxWidth,
});

/// Cross-platform (Web, Android, iOS) binary image upload service backed by
/// `image_picker` (`XFile.readAsBytes()`) and `firebase_storage` (`putData`).
///
/// Enforces exact `storage.rules` constraints:
/// - `size > 0 && size <= 10 MB`
/// - `contentType` matching `image/*`
/// - Exact authorized paths:
///   - `/work_requests/{requestId}/reference/{fileName}`
///   - `/work_requests/{requestId}/invoices/{fileName}`
///   - `/work_requests/{requestId}/payment_proofs/{fileName}`
///   - `/provider_verifications/{uid}/{docType}_{ts}.{ext}`
class MediaUploadService {
  static const int maxUploadBytes = 10 * 1024 * 1024; // 10 MB

  static const Map<String, String> _extensionToMime = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
  };

  static MediaUploadService? _debugOverride;

  /// Optional test hook allowing widget tests to inject a deterministic
  /// [MediaUploadService] across screens without native platform channels.
  @visibleForTesting
  static set debugOverride(MediaUploadService? service) {
    _debugOverride = service;
  }

  static MediaUploadService get instance =>
      _debugOverride ?? MediaUploadService();

  final MediaStorageGateway? _injectedGateway;
  final MediaImagePickerFn? _injectedPicker;
  final bool? _useFirebaseOverride;
  final bool? _allowDevMocksOverride;
  final DateTime Function() _clock;

  MediaUploadService({
    MediaStorageGateway? storageGateway,
    MediaImagePickerFn? imagePickerFn,
    bool? useFirebaseOverride,
    bool? allowDevMocksOverride,
    DateTime Function()? clock,
  })  : _injectedGateway = storageGateway,
        _injectedPicker = imagePickerFn,
        _useFirebaseOverride = useFirebaseOverride,
        _allowDevMocksOverride = allowDevMocksOverride,
        _clock = clock ?? DateTime.now;

  bool get _effectiveUseFirebase =>
      _useFirebaseOverride ?? AppEnvironment.useFirebase;

  bool _isDevMockActive({bool allowDevMocks = false}) {
    if (_effectiveUseFirebase) return false;
    if (!AppEnvironment.isDevMocksAllowed(
      flavor: AppEnvironment.flavor,
      useFirebase: _effectiveUseFirebase,
    )) {
      return false;
    }
    return _allowDevMocksOverride ??
        (allowDevMocks || AppEnvironment.useDevMocks);
  }

  // ---------------------------------------------------------------------------
  // Canonical storage.rules Path Builders
  // ---------------------------------------------------------------------------

  static String buildWorkRequestReferencePath({
    required String requestId,
    required String fileName,
  }) {
    final cleanId = _sanitizeSegment(requestId, fallback: 'draft_request');
    final cleanFile = _sanitizeFileName(fileName, defaultExt: 'jpg');
    return '/work_requests/$cleanId/reference/$cleanFile';
  }

  static String buildWorkRequestInvoicePath({
    required String requestId,
    required String fileName,
  }) {
    final cleanId = _sanitizeSegment(requestId, fallback: 'request');
    final cleanFile = _sanitizeFileName(fileName, defaultExt: 'jpg');
    return '/work_requests/$cleanId/invoices/$cleanFile';
  }

  static String buildWorkRequestPaymentProofPath({
    required String requestId,
    required String fileName,
  }) {
    final cleanId = _sanitizeSegment(requestId, fallback: 'request');
    final cleanFile = _sanitizeFileName(fileName, defaultExt: 'jpg');
    return '/work_requests/$cleanId/payment_proofs/$cleanFile';
  }

  static String buildProviderVerificationPath({
    required String uid,
    required String docType,
    required int timestampMs,
    required String extension,
  }) {
    final cleanUid = _sanitizeSegment(uid, fallback: 'anonymous');
    final cleanDocType = _sanitizeSegment(docType, fallback: 'qid_doc');
    final cleanExt = _sanitizeExtension(extension);
    return '/provider_verifications/$cleanUid/${cleanDocType}_$timestampMs.$cleanExt';
  }

  static String _sanitizeSegment(String raw, {required String fallback}) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  static String _sanitizeExtension(String raw) {
    final lower = raw.trim().toLowerCase().replaceAll('.', '');
    if (_extensionToMime.containsKey(lower)) {
      return lower == 'jpeg' ? 'jpg' : lower;
    }
    return 'jpg';
  }

  static String _sanitizeFileName(String raw, {required String defaultExt}) {
    final baseName = raw.trim().split(RegExp(r'[/\\]')).last;
    if (baseName.isEmpty) {
      return 'image_${DateTime.now().millisecondsSinceEpoch}.$defaultExt';
    }
    final dotIdx = baseName.lastIndexOf('.');
    if (dotIdx <= 0 || dotIdx == baseName.length - 1) {
      final stem = _sanitizeSegment(baseName, fallback: 'image');
      return '$stem.$defaultExt';
    }
    final stem =
        _sanitizeSegment(baseName.substring(0, dotIdx), fallback: 'image');
    final ext = baseName
        .substring(dotIdx + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$stem.${ext.isEmpty ? defaultExt : ext}';
  }

  // ---------------------------------------------------------------------------
  // MIME & Size Validation (<= 10 MB, image/*)
  // ---------------------------------------------------------------------------

  static String resolveAndValidateImageMime({
    required Uint8List bytes,
    required String fileName,
    String? explicitMimeType,
  }) {
    if (bytes.isEmpty) {
      throw const MediaUploadException(
        code: 'empty-file',
        messageEn: 'Selected image file is empty (0 bytes).',
        messageAr: 'ملف الصورة المحدد فارغ (0 بايت).',
      );
    }

    if (bytes.lengthInBytes > maxUploadBytes) {
      throw const MediaUploadException(
        code: 'file-too-large',
        messageEn:
            'Image exceeds the 10 MB maximum limit allowed by security rules.',
        messageAr: 'حجم الصورة يتجاوز الحد الأقصى المسموح به (10 ميجابايت).',
      );
    }

    final trimmedMime = explicitMimeType?.trim().toLowerCase();
    if (trimmedMime != null && trimmedMime.isNotEmpty) {
      if (!trimmedMime.startsWith('image/')) {
        throw MediaUploadException(
          code: 'invalid-mime-type',
          messageEn:
              'Unsupported file type "$trimmedMime". Only image/* files are allowed.',
          messageAr:
              'نوع الملف غير مدعوم ($trimmedMime). يُسمح برفع الصور فقط.',
        );
      }
      return trimmedMime;
    }

    final dotIdx = fileName.lastIndexOf('.');
    if (dotIdx >= 0 && dotIdx < fileName.length - 1) {
      final ext = fileName.substring(dotIdx + 1).trim().toLowerCase();
      final mapped = _extensionToMime[ext];
      if (mapped != null) {
        return mapped;
      }
      // Explicitly reject known non-image extensions such as .pdf, .doc, .zip
      throw MediaUploadException(
        code: 'invalid-mime-type',
        messageEn:
            'Unsupported file extension ".$ext". Only JPG, PNG, WEBP, GIF, or HEIC images are allowed.',
        messageAr:
            'امتداد الملف (.$ext) غير مدعوم. يُسمح فقط بصور JPG أو PNG أو WEBP أو HEIC.',
      );
    }

    // Magic-byte fallback when XFile has neither mimeType nor file extension
    final sniffed = _sniffMagicBytesMime(bytes);
    if (sniffed != null) {
      return sniffed;
    }

    throw const MediaUploadException(
      code: 'invalid-mime-type',
      messageEn:
          'Unable to verify image format. Please choose a valid JPG, PNG, or WEBP image.',
      messageAr:
          'تعذّر التحقق من صيغة الصورة. يرجى اختيار صورة صالحة بصيغة JPG أو PNG أو WEBP.',
    );
  }

  static String? _sniffMagicBytesMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  static String _extensionFromMime(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      case 'image/bmp':
        return 'bmp';
      default:
        return 'jpg';
    }
  }

  // ---------------------------------------------------------------------------
  // Image Picking + Upload Operations
  // ---------------------------------------------------------------------------

  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 88,
    double maxWidth = 2048,
  }) async {
    try {
      final pickerFn = _injectedPicker;
      if (pickerFn != null) {
        return await pickerFn(
          source: source,
          imageQuality: imageQuality,
          maxWidth: maxWidth,
        );
      }
      final picker = ImagePicker();
      return await picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    } on MediaUploadException {
      rethrow;
    } catch (e) {
      throw MediaUploadException(
        code: 'picker-failed',
        messageEn: 'Unable to access camera or photo library: $e',
        messageAr: 'تعذّر الوصول إلى الكاميرا أو معرض الصور على هذا الجهاز.',
      );
    }
  }

  Future<MediaUploadResult> uploadToPath({
    required String storagePath,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    bool allowDevMocks = false,
    Map<String, String>? customMetadata,
  }) async {
    final validatedMime = resolveAndValidateImageMime(
      bytes: bytes,
      fileName: fileName,
      explicitMimeType: mimeType,
    );

    final cleanFileName = _sanitizeFileName(
      fileName,
      defaultExt: _extensionFromMime(validatedMime),
    );

    if (_effectiveUseFirebase || _injectedGateway != null) {
      try {
        final gateway = _injectedGateway ?? FirebaseMediaStorageGateway();
        final downloadUrl = await gateway.putBytes(
          storagePath: storagePath,
          bytes: bytes,
          contentType: validatedMime,
          customMetadata: customMetadata,
        );
        return MediaUploadResult(
          downloadUrl: downloadUrl,
          storagePath: storagePath,
          fileName: cleanFileName,
          mimeType: validatedMime,
          sizeBytes: bytes.lengthInBytes,
          bytes: bytes,
          isDevMock: false,
        );
      } on MediaUploadException {
        rethrow;
      } on FirebaseException catch (e) {
        throw MediaUploadException.fromFirebase(e);
      } catch (e) {
        throw MediaUploadException(
          code: 'upload-failed',
          messageEn: 'Failed to upload image: $e',
          messageAr: 'فشل رفع الصورة إلى الخادم. يرجى المحاولة مرة أخرى.',
        );
      }
    }

    if (_isDevMockActive(allowDevMocks: allowDevMocks)) {
      final normalizedPath =
          storagePath.startsWith('/') ? storagePath : '/$storagePath';
      return MediaUploadResult(
        downloadUrl: 'https://storage.mashwar.qa$normalizedPath',
        storagePath: normalizedPath,
        fileName: cleanFileName,
        mimeType: validatedMime,
        sizeBytes: bytes.lengthInBytes,
        bytes: bytes,
        isDevMock: true,
      );
    }

    throw const MediaUploadException(
      code: 'storage-not-configured',
      messageEn:
          'Firebase Storage is not enabled in this environment. Build with USE_FIREBASE=true to upload real media.',
      messageAr:
          'خدمة Firebase Storage غير مفعّلة في هذه البيئة. يرجى تفعيل الاتصال السحابي لرفع الصور.',
    );
  }

  Future<MediaUploadResult> uploadWorkRequestReference({
    required String requestId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    bool allowDevMocks = false,
  }) {
    final validatedMime = resolveAndValidateImageMime(
      bytes: bytes,
      fileName: fileName,
      explicitMimeType: mimeType,
    );
    final ts = _clock().toUtc().millisecondsSinceEpoch;
    final cleanFile = _sanitizeFileName(
      fileName,
      defaultExt: _extensionFromMime(validatedMime),
    );
    final stampedFile = '${ts}_$cleanFile';
    final path = buildWorkRequestReferencePath(
      requestId: requestId,
      fileName: stampedFile,
    );
    return uploadToPath(
      storagePath: path,
      bytes: bytes,
      fileName: cleanFile,
      mimeType: validatedMime,
      allowDevMocks: allowDevMocks,
      customMetadata: {'category': 'reference', 'requestId': requestId},
    );
  }

  Future<MediaUploadResult> uploadWorkRequestInvoice({
    required String requestId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    bool allowDevMocks = false,
  }) {
    final validatedMime = resolveAndValidateImageMime(
      bytes: bytes,
      fileName: fileName,
      explicitMimeType: mimeType,
    );
    final ts = _clock().toUtc().millisecondsSinceEpoch;
    final cleanFile = _sanitizeFileName(
      fileName,
      defaultExt: _extensionFromMime(validatedMime),
    );
    final stampedFile = '${ts}_$cleanFile';
    final path = buildWorkRequestInvoicePath(
      requestId: requestId,
      fileName: stampedFile,
    );
    return uploadToPath(
      storagePath: path,
      bytes: bytes,
      fileName: cleanFile,
      mimeType: validatedMime,
      allowDevMocks: allowDevMocks,
      customMetadata: {'category': 'invoice', 'requestId': requestId},
    );
  }

  Future<MediaUploadResult> uploadWorkRequestPaymentProof({
    required String requestId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    bool allowDevMocks = false,
  }) {
    final validatedMime = resolveAndValidateImageMime(
      bytes: bytes,
      fileName: fileName,
      explicitMimeType: mimeType,
    );
    final ts = _clock().toUtc().millisecondsSinceEpoch;
    final cleanFile = _sanitizeFileName(
      fileName,
      defaultExt: _extensionFromMime(validatedMime),
    );
    final stampedFile = '${ts}_$cleanFile';
    final path = buildWorkRequestPaymentProofPath(
      requestId: requestId,
      fileName: stampedFile,
    );
    return uploadToPath(
      storagePath: path,
      bytes: bytes,
      fileName: cleanFile,
      mimeType: validatedMime,
      allowDevMocks: allowDevMocks,
      customMetadata: {'category': 'payment_proof', 'requestId': requestId},
    );
  }

  Future<MediaUploadResult> uploadProviderVerificationDoc({
    required String uid,
    required String docType,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    int? timestampMs,
    bool allowDevMocks = false,
  }) {
    final validatedMime = resolveAndValidateImageMime(
      bytes: bytes,
      fileName: fileName,
      explicitMimeType: mimeType,
    );
    final ext = _extensionFromMime(validatedMime);
    final ts = timestampMs ?? _clock().toUtc().millisecondsSinceEpoch;
    final path = buildProviderVerificationPath(
      uid: uid,
      docType: docType,
      timestampMs: ts,
      extension: ext,
    );
    return uploadToPath(
      storagePath: path,
      bytes: bytes,
      fileName: fileName.trim().isEmpty ? '${docType}_$ts.$ext' : fileName,
      mimeType: validatedMime,
      allowDevMocks: allowDevMocks,
      customMetadata: {'docType': docType, 'uid': uid},
    );
  }

  Future<MediaUploadResult?> pickAndUploadWorkRequestReference({
    required String requestId,
    ImageSource source = ImageSource.gallery,
    bool allowDevMocks = false,
  }) async {
    final xfile = await pickImage(source: source);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    return uploadWorkRequestReference(
      requestId: requestId,
      bytes: bytes,
      fileName: xfile.name,
      mimeType: xfile.mimeType,
      allowDevMocks: allowDevMocks,
    );
  }

  Future<MediaUploadResult?> pickAndUploadWorkRequestInvoice({
    required String requestId,
    ImageSource source = ImageSource.gallery,
    bool allowDevMocks = false,
  }) async {
    final xfile = await pickImage(source: source);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    return uploadWorkRequestInvoice(
      requestId: requestId,
      bytes: bytes,
      fileName: xfile.name,
      mimeType: xfile.mimeType,
      allowDevMocks: allowDevMocks,
    );
  }

  Future<MediaUploadResult?> pickAndUploadWorkRequestPaymentProof({
    required String requestId,
    ImageSource source = ImageSource.gallery,
    bool allowDevMocks = false,
  }) async {
    final xfile = await pickImage(source: source);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    return uploadWorkRequestPaymentProof(
      requestId: requestId,
      bytes: bytes,
      fileName: xfile.name,
      mimeType: xfile.mimeType,
      allowDevMocks: allowDevMocks,
    );
  }

  Future<MediaUploadResult?> pickAndUploadProviderVerificationDoc({
    required String uid,
    required String docType,
    ImageSource source = ImageSource.gallery,
    bool allowDevMocks = false,
  }) async {
    final xfile = await pickImage(source: source);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    return uploadProviderVerificationDoc(
      uid: uid,
      docType: docType,
      bytes: bytes,
      fileName: xfile.name,
      mimeType: xfile.mimeType,
      allowDevMocks: allowDevMocks,
    );
  }
}
