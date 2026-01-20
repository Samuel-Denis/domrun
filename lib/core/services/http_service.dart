import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/storage_service.dart';

/// Serviço HTTP com suporte a autenticação automática
/// Adiciona o access token nas requisições e renova automaticamente se expirado
class HttpService {
  static const Duration _defaultTimeout = Duration(seconds: 20);

  // Serviço de storage para obter tokens
  late final StorageService _storage;
  // Serviço de autenticação para renovar tokens
  late final dynamic _authService;

  Future<void> init() async {
    _storage = Get.find<StorageService>();
  }

  /// Configura o AuthService para permitir renovação de tokens
  void setAuthService(dynamic authService) {
    _authService = authService;
  }

  /// Obtém os headers padrão com autenticação
  /// Adiciona o access token se disponível
  Future<Map<String, String>> getHeaders({
    bool includeAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (includeAuth) {
      // Verifica se o token está expirado e renova se necessário
      if (_storage.isTokenExpired()) {
        try {
          await _authService?.refreshAccessToken();
        } catch (e) {
          // Se falhar ao renovar, continua sem token
          _debug('Erro ao renovar token: $e');
        }
      }

      // Adiciona o access token ao header
      final accessToken = _storage.getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Faz uma requisição GET autenticada
  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return _send(
      () => http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      ),
      endpoint: endpoint,
    );
  }

  /// Faz uma requisição POST autenticada
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: json.encode(body),
      ),
      endpoint: endpoint,
    );
  }

  /// Faz uma requisição PUT autenticada
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return _send(
      () => http.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: json.encode(body),
      ),
      endpoint: endpoint,
    );
  }

  /// Faz uma requisição DELETE autenticada
  Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return _send(
      () => http.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      ),
      endpoint: endpoint,
    );
  }

  /// Faz uma requisição GET para uma URL absoluta
  Future<http.Response> getUrl(
    String url, {
    bool includeAuth = true,
    Map<String, String>? headers,
  }) async {
    final baseHeaders = await getHeaders(
      includeAuth: includeAuth,
      extraHeaders: headers,
    );
    return _send(
      () => http.get(Uri.parse(url), headers: baseHeaders),
      endpoint: url,
    );
  }

  /// Faz uma requisição POST para uma URL absoluta
  Future<http.Response> postUrl(
    String url,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    Map<String, String>? headers,
  }) async {
    final baseHeaders = await getHeaders(
      includeAuth: includeAuth,
      extraHeaders: headers,
    );
    return _send(
      () => http.post(
        Uri.parse(url),
        headers: baseHeaders,
        body: json.encode(body),
      ),
      endpoint: url,
    );
  }

  /// Faz uma requisição PUT para uma URL absoluta
  Future<http.Response> putUrl(
    String url,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    Map<String, String>? headers,
  }) async {
    final baseHeaders = await getHeaders(
      includeAuth: includeAuth,
      extraHeaders: headers,
    );
    return _send(
      () => http.put(
        Uri.parse(url),
        headers: baseHeaders,
        body: json.encode(body),
      ),
      endpoint: url,
    );
  }

  /// Faz uma requisição DELETE para uma URL absoluta
  Future<http.Response> deleteUrl(
    String url, {
    bool includeAuth = true,
    Map<String, String>? headers,
  }) async {
    final baseHeaders = await getHeaders(
      includeAuth: includeAuth,
      extraHeaders: headers,
    );
    return _send(
      () => http.delete(Uri.parse(url), headers: baseHeaders),
      endpoint: url,
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required String endpoint,
  }) async {
    try {
      final response = await request().timeout(_defaultTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromResponse(response, endpoint: endpoint);
      }
      return response;
    } on TimeoutException catch (_) {
      throw ApiException.timeout(endpoint: endpoint);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(endpoint: endpoint, message: e.toString());
    }
  }

  void _debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? endpoint;
  final dynamic body;

  const ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
    this.body,
  });

  factory ApiException.fromResponse(
    http.Response response, {
    required String endpoint,
  }) {
    final parsed = _parseErrorMessage(response.body);
    return ApiException(
      statusCode: response.statusCode,
      message: parsed ?? 'Erro na requisição (${response.statusCode})',
      endpoint: endpoint,
      body: response.body,
    );
  }

  factory ApiException.timeout({required String endpoint}) {
    return ApiException(message: 'Tempo limite excedido', endpoint: endpoint);
  }

  factory ApiException.network({
    required String endpoint,
    required String message,
  }) {
    return ApiException(message: message, endpoint: endpoint);
  }

  static String? _parseErrorMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // ignora parse inválido
    }
    if (body.trim().isNotEmpty) {
      return body.trim();
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, endpoint: $endpoint)';
  }
}
