import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:http/http.dart' as http;

import '../../core/config/app_environment.dart';

/// Firestore Database Schema Constants & Document Path Registry.
/// Centralizes collection naming, nested subcollections, and schema references.
class FirestoreCollections {
  static const String users = 'users';
  static const String rides = 'rides';
  static const String boardAds = 'board_ads';
  static const String boardOffers = 'offers'; // subcollection of board_ads
  static const String parcels = 'parcels';
  static const String bookings = 'bookings';
  static const String conversations = 'conversations';
  static const String messages = 'messages'; // subcollection of conversations
  static const String routeAlerts = 'route_alerts';
  static const String walletTransactions = 'wallet_transactions';
  static const String driverVerifications = 'driver_verifications';
  static const String adminAuditLogs = 'admin_audit_logs';
  static const String platformConfig = 'platform_config';
  static const String serviceCatalog = 'service_catalog';
  static const String corridors = 'corridors';
  static const String escrowHolds = 'escrow_holds';
  static const String disputes = 'disputes';
  static const String featureFlags = 'feature_flags';
  static const String adminStaff = 'admin_staff';
  static const String investorInquiries = 'investor_inquiries';

  // Worksite Supply MVP (Qatar Pilot Collections 20-29)
  static const String businessProfiles = 'business_profiles';
  static const String providerProfiles = 'provider_profiles';
  static const String providerVerifications = 'provider_verifications';
  static const String workRequests = 'work_requests';
  static const String workOffers = 'work_offers';
  static const String workRequestSecrets = 'work_request_secrets';
  static const String workRequestHandoverView = 'work_request_handover_view';
  static const String requestEvents = 'request_events';
  static const String ratings = 'ratings';
  static const String notifications = 'notifications';
  static const String userPrivateSubcollection = 'private';

  /// Path to a specific user's document
  static String userDoc(String userId) => '$users/$userId';

  /// Path to a specific ride's document
  static String rideDoc(String rideId) => '$rides/$rideId';

  /// Path to an ad's offers subcollection
  static String adOffers(String adId) => '$boardAds/$adId/$boardOffers';

  /// Path to a conversation's messages subcollection
  static String conversationMessages(String conversationId) =>
      '$conversations/$conversationId/$messages';

  static String businessProfileDoc(String uid) => '$businessProfiles/$uid';
  static String providerProfileDoc(String uid) => '$providerProfiles/$uid';
  static String providerVerificationDoc(String uid) =>
      '$providerVerifications/$uid';
  static String workRequestDoc(String requestId) => '$workRequests/$requestId';
  static String workRequestHandoverViewDoc(String requestId) =>
      '$workRequestHandoverView/$requestId';
  static String userSavedWorksiteDoc(String uid, String worksiteId) =>
      '$users/$uid/$userPrivateSubcollection/$worksiteId';
}

/// Firebase & REST API Gateway Configuration.
class FirebaseConfig {
  /// Check whether the app is currently in Firebase-connected mode or Local-Offline mode.
  static const bool useFirebase = AppEnvironment.useFirebase;

  /// Target Firestore Project ID.
  static const String projectId = AppEnvironment.firebaseProjectId;

  /// Target Firebase Cloud Functions / Firestore Region (matches `functions/src/index.ts`).
  static const String region = AppEnvironment.firebaseRegion;

  /// Optional full Cloud Functions v2 base URL override (`--dart-define=FUNCTIONS_BASE_URL=...`).
  static const String functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: '',
  );

  /// Optional Cloud Functions Emulator host override (`--dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001`).
  static const String functionsEmulatorHost = String.fromEnvironment(
    'FUNCTIONS_EMULATOR_HOST',
    defaultValue: '',
  );
}

/// Typed, bilingual exception thrown by Worksite Supply repositories and callable gateways.
class WorksiteRepositoryException implements Exception {
  final String code;
  final String messageEn;
  final String messageAr;
  final Map<String, dynamic>? details;

  const WorksiteRepositoryException({
    required this.code,
    required this.messageEn,
    required this.messageAr,
    this.details,
  });

  String localizedMessage({required bool isArabic}) =>
      isArabic ? messageAr : messageEn;

  String get message => '$messageAr | $messageEn';

  @override
  String toString() =>
      'WorksiteRepositoryException($code): $messageEn ($messageAr)';

  factory WorksiteRepositoryException.unauthenticated() {
    return const WorksiteRepositoryException(
      code: 'unauthenticated',
      messageAr: 'يرجى تسجيل الدخول للمتابعة.',
      messageEn: 'Authentication is required to continue.',
    );
  }

  factory WorksiteRepositoryException.fromFirebase(Object error) {
    if (error is WorksiteRepositoryException) return error;
    if (error is FirebaseException) {
      return WorksiteRepositoryException.fromCode(
        error.code,
        rawMessage: error.message,
      );
    }
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException) {
      return const WorksiteRepositoryException(
        code: 'unavailable',
        messageAr: 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وأعد المحاولة.',
        messageEn:
            'Unable to reach server. Check your internet connection and retry.',
      );
    }
    return WorksiteRepositoryException(
      code: 'unknown',
      messageAr: 'حدث خطأ غير متوقع أثناء تنفيذ العملية.',
      messageEn: error.toString(),
    );
  }

  factory WorksiteRepositoryException.fromCode(
    String rawCode, {
    String? rawMessage,
    Map<String, dynamic>? details,
  }) {
    final normalized = _normalizeCode(rawCode);
    final detailMsg = rawMessage?.trim();

    switch (normalized) {
      case 'unauthenticated':
        return WorksiteRepositoryException(
          code: 'unauthenticated',
          messageAr: 'انتهت جلسة الدخول أو لم يتم تسجيل الدخول.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Authentication is required.',
          details: details,
        );
      case 'permission-denied':
        return WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Permission denied for this operation.',
          details: details,
        );
      case 'invalid-argument':
        return WorksiteRepositoryException(
          code: 'invalid-argument',
          messageAr: 'البيانات المدخلة غير مكتملة أو غير صالحة.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Invalid input provided.',
          details: details,
        );
      case 'not-found':
        return WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'السجل المطلوب غير موجود.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Requested record was not found.',
          details: details,
        );
      case 'failed-precondition':
        return WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: _arabicPreconditionMessage(detailMsg, details),
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Operation precondition was not satisfied.',
          details: details,
        );
      case 'already-exists':
        return WorksiteRepositoryException(
          code: 'already-exists',
          messageAr: 'تم تنفيذ هذا الإجراء مسبقاً.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Record already exists.',
          details: details,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return WorksiteRepositoryException(
          code: 'unavailable',
          messageAr: 'الخدمة غير متاحة حالياً. أعد المحاولة بعد قليل.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Service temporarily unavailable. Please retry.',
          details: details,
        );
      default:
        return WorksiteRepositoryException(
          code: normalized,
          messageAr: 'تعذّر إتمام الطلب في الوقت الحالي.',
          messageEn: detailMsg?.isNotEmpty == true
              ? detailMsg!
              : 'Request failed ($normalized).',
          details: details,
        );
    }
  }

  static String _arabicPreconditionMessage(
    String? rawMessage,
    Map<String, dynamic>? details,
  ) {
    final msg = (rawMessage ?? '').toLowerCase();
    if (msg.contains('invalid handover code')) {
      final remaining = details?['attemptsRemaining'];
      if (remaining != null) {
        return 'رمز التسليم غير صحيح. المحاولات المتبقية: $remaining.';
      }
      return 'رمز التسليم غير صحيح.';
    }
    if (msg.contains('expired')) {
      return 'انتهت صلاحية رمز التسليم.';
    }
    if (msg.contains('already been used')) {
      return 'تم استخدام رمز التسليم مسبقاً.';
    }
    if (msg.contains('exhausted')) {
      return 'تم استنفاد جميع محاولات التحقق من رمز التسليم.';
    }
    return 'لا يمكن تنفيذ هذا الإجراء في الحالة الحالية للطلب.';
  }

  static String _normalizeCode(String raw) {
    final lower = raw.trim().toLowerCase().replaceAll('_', '-');
    switch (lower) {
      case 'unauthenticated':
      case '401':
        return 'unauthenticated';
      case 'permission-denied':
      case '403':
        return 'permission-denied';
      case 'invalid-argument':
      case '400':
        return 'invalid-argument';
      case 'not-found':
      case '404':
        return 'not-found';
      case 'failed-precondition':
      case '412':
        return 'failed-precondition';
      case 'already-exists':
      case '409':
        return 'already-exists';
      case 'unavailable':
      case 'deadline-exceeded':
      case '503':
      case '504':
        return 'unavailable';
      default:
        return lower.isEmpty ? 'unknown' : lower;
    }
  }
}

/// Converts Firestore [Timestamp], [DateTime], epoch millis, or ISO strings to UTC ISO-8601 strings
/// so domain `fromJson` factories work uniformly across Firestore & Cloud Functions payloads.
Map<String, dynamic> normalizeFirestoreDocument(
  Map<String, dynamic> raw, {
  String? fallbackId,
}) {
  dynamic convertValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), convertValue(nested)),
      );
    }
    if (value is Iterable) {
      return value.map(convertValue).toList();
    }
    return value;
  }

  final normalized = <String, dynamic>{};
  raw.forEach((key, value) {
    normalized[key] = convertValue(value);
  });
  if (fallbackId != null &&
      (normalized['id'] == null || normalized['id'].toString().isEmpty)) {
    normalized['id'] = fallbackId;
  }
  return normalized;
}

/// Lightweight Firebase Cloud Functions v2 HTTP Callable client using `package:http`
/// and `FirebaseAuth.currentUser.getIdToken()`, supporting production URLs as well as
/// `--dart-define=FUNCTIONS_BASE_URL` and `--dart-define=FUNCTIONS_EMULATOR_HOST`.
class FirebaseFunctionsCallableClient {
  final String projectId;
  final String region;
  final String functionsBaseUrlOverride;
  final String emulatorHostOverride;
  final http.Client _httpClient;
  final Future<String?> Function() _idTokenProvider;
  final Duration timeout;

  FirebaseFunctionsCallableClient({
    this.projectId = FirebaseConfig.projectId,
    this.region = FirebaseConfig.region,
    this.functionsBaseUrlOverride = FirebaseConfig.functionsBaseUrl,
    this.emulatorHostOverride = FirebaseConfig.functionsEmulatorHost,
    http.Client? httpClient,
    Future<String?> Function()? idTokenProvider,
    this.timeout = const Duration(seconds: 20),
  })  : _httpClient = httpClient ?? http.Client(),
        _idTokenProvider = idTokenProvider ??
            (() async => fb_auth.FirebaseAuth.instance.currentUser?.getIdToken());

  /// Resolves the HTTP Callable v2 endpoint URI for [functionName].
  Uri buildFunctionUri(String functionName) {
    final cleanName = functionName.trim();
    final baseOverride = functionsBaseUrlOverride.trim();
    if (baseOverride.isNotEmpty) {
      final normalizedBase = _stripTrailingSlash(baseOverride);
      final parsed = Uri.parse(normalizedBase);
      final hasEmptyPath = parsed.path.isEmpty || parsed.path == '/';
      if (hasEmptyPath && !parsed.host.endsWith('.cloudfunctions.net')) {
        return Uri.parse('$normalizedBase/$projectId/$region/$cleanName');
      }
      return Uri.parse('$normalizedBase/$cleanName');
    }

    final emulatorHost = emulatorHostOverride.trim();
    if (emulatorHost.isNotEmpty) {
      final withScheme = emulatorHost.startsWith('http://') ||
              emulatorHost.startsWith('https://')
          ? emulatorHost
          : 'http://$emulatorHost';
      final normalized = _stripTrailingSlash(withScheme);
      return Uri.parse('$normalized/$projectId/$region/$cleanName');
    }

    return Uri.parse('https://$region-$projectId.cloudfunctions.net/$cleanName');
  }

  String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Invokes a Firebase Cloud Functions v2 `onCall` endpoint with Firebase ID token auth.
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final token = await _idTokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }

    final uri = buildFunctionUri(functionName);
    late final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token.trim()}',
            },
            body: jsonEncode({'data': data}),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    } on SocketException catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    } on http.ClientException catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }

    Map<String, dynamic>? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        final rawJson = jsonDecode(response.body);
        if (rawJson is Map) {
          decoded = rawJson.map((k, v) => MapEntry(k.toString(), v));
        }
      } on FormatException {
        throw WorksiteRepositoryException(
          code: 'internal',
          messageAr: 'استجابة غير صالحة من الخادم.',
          messageEn:
              'Invalid JSON response from callable $functionName (HTTP ${response.statusCode}).',
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded != null && decoded['error'] is Map) {
        throw _parseErrorMap(
          decoded['error'] as Map,
          httpStatus: response.statusCode,
        );
      }
      final result = decoded?['result'] ?? decoded?['data'] ?? decoded;
      if (result is Map) {
        return result.map((k, v) => MapEntry(k.toString(), v));
      }
      return <String, dynamic>{};
    }

    if (decoded != null && decoded['error'] is Map) {
      throw _parseErrorMap(
        decoded['error'] as Map,
        httpStatus: response.statusCode,
      );
    }

    throw WorksiteRepositoryException.fromCode(
      response.statusCode.toString(),
      rawMessage: decoded?['message']?.toString() ??
          'Callable $functionName failed with HTTP ${response.statusCode}.',
    );
  }

  WorksiteRepositoryException _parseErrorMap(
    Map errorMap, {
    required int httpStatus,
  }) {
    final rawStatus =
        (errorMap['status'] ?? httpStatus).toString();
    final rawMessage = errorMap['message']?.toString();
    final rawDetails = errorMap['details'];
    final details = rawDetails is Map
        ? rawDetails.map((k, v) => MapEntry(k.toString(), v))
        : null;
    return WorksiteRepositoryException.fromCode(
      rawStatus,
      rawMessage: rawMessage,
      details: details,
    );
  }
}
