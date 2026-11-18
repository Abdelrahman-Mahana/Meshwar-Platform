import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException ($statusCode): $message';
}

/// Centralized API HTTP Client for MASHWAR Backend Communications.
class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client, String? authToken})
      : _client = client ?? http.Client(),
        _authToken = authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      'X-Client-Platform': 'Flutter',
      'X-Client-Version': '1.0.0',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint').replace(
      queryParameters: queryParams,
    );
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'تعذر الاتصال بالخادم، تأكد من اتصال الإنترنت.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: -1, message: e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'تعذر الاتصال بالخادم، تأكد من اتصال الإنترنت.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: -1, message: e.toString());
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: -1, message: e.toString());
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: -1, message: e.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(utf8.decode(response.bodyBytes));
    }

    String message = 'حدث خطأ في الخادم (${response.statusCode})';
    try {
      final errBody = json.decode(utf8.decode(response.bodyBytes));
      if (errBody is Map && errBody['message'] != null) {
        message = errBody['message'].toString();
      }
    } catch (_) {}

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }
}
