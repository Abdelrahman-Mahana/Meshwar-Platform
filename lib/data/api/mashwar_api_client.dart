import 'dart:convert';
import 'api_endpoints.dart';

/// Standardized API Response envelope for MASHWAR backend calls.
class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic dataJson)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      data: json['data'] != null && fromData != null ? fromData(json['data']) : json['data'] as T?,
      message: json['message'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

/// Request log item for inspecting outgoing payloads during backend development.
class ApiRequestLog {
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final DateTime timestamp;
  final int statusCode;

  const ApiRequestLog({
    required this.method,
    required this.path,
    this.body,
    required this.timestamp,
    this.statusCode = 200,
  });
}

/// Backend-ready HTTP client wrapper for MASHWAR.
/// Manages JWT Bearer tokens, Arabic/English Accept-Language headers,
/// request logging, and mock-to-live switching.
class MashwarApiClient {
  MashwarApiClient._();
  static final MashwarApiClient instance = MashwarApiClient._();

  String? _accessToken;
  String _locale = 'ar';
  bool _useMockAdapter = true;

  final List<ApiRequestLog> _recentLogs = [
    ApiRequestLog(
      method: 'GET',
      path: ApiEndpoints.userProfile,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      statusCode: 200,
    ),
    ApiRequestLog(
      method: 'GET',
      path: ApiEndpoints.searchRides,
      body: {'fromCity': 'الدوحة', 'toCity': 'الخور'},
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      statusCode: 200,
    ),
  ];

  String? get accessToken => _accessToken;
  bool get useMockAdapter => _useMockAdapter;
  List<ApiRequestLog> get recentLogs => List.unmodifiable(_recentLogs);

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void setLocale(String localeCode) {
    _locale = localeCode;
  }

  String get currentLocale => _locale;

  void setUseMockAdapter(bool value) {
    _useMockAdapter = value;
  }

  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': _locale,
        'X-Client-Platform': 'flutter-mashwar-v1.2',
        if (_accessToken != null && _accessToken!.isNotEmpty)
          'Authorization': 'Bearer $_accessToken',
      };

  void recordRequest(String method, String path, {Map<String, dynamic>? body, int statusCode = 200}) {
    _recentLogs.insert(
      0,
      ApiRequestLog(
        method: method,
        path: path,
        body: body,
        timestamp: DateTime.now(),
        statusCode: statusCode,
      ),
    );
    if (_recentLogs.length > 30) {
      _recentLogs.removeLast();
    }
  }

  String formatCurlPreview(String method, String path, {Map<String, dynamic>? body}) {
    final url = '${ApiEndpoints.baseUrl}$path';
    final headersPart = defaultHeaders.entries
        .map((e) => '-H "${e.key}: ${e.value}"')
        .join(' ');
    final bodyPart = body != null ? "-d '${jsonEncode(body)}'" : '';
    return 'curl -X $method "$url" $headersPart $bodyPart'.trim();
  }
}
