import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the backend returns a non-2xx response.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client for the NestJS backend API.
/// Automatically injects the Supabase JWT as a Bearer token.
class ApiClient {
  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _baseUrl = dotenv.env['API_BASE_URL'] ??
            (Platform.isAndroid
                ? 'http://10.0.2.2:3001/api'
                : 'http://localhost:3001/api');

  final http.Client _httpClient;
  final String _baseUrl;

  /// Sends a GET request to the backend.
  ///
  /// @param path - The API path (e.g. '/consents')
  /// @returns Decoded JSON response body
  /// @throws ApiException on non-2xx responses
  Future<dynamic> get(String path) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl$path'),
      headers: _buildHeaders(),
    );
    return _handleResponse(response);
  }

  /// Sends a POST request to the backend with a JSON body.
  ///
  /// @param path - The API path (e.g. '/consents')
  /// @param body - The request body as a Map
  /// @returns Decoded JSON response body
  /// @throws ApiException on non-2xx responses
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl$path'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Map<String, String> _buildHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map ? (body['message'] ?? 'Unknown error') : 'Unknown error';
    throw ApiException(response.statusCode, message.toString());
  }
}

/// Riverpod provider for the API client.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
