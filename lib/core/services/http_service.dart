import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/services/storage_service.dart';

/// Serviço HTTP com suporte a autenticação automática
/// Adiciona o access token nas requisições e renova automaticamente se expirado
class HttpService extends GetxService {
  // Serviço de storage para obter tokens
  late final StorageService _storage;
  // Serviço de autenticação para renovar tokens
  late final dynamic _authService;

  @override
  Future<void> onInit() async {
    super.onInit();
    _storage = Get.find<StorageService>();
  }

  /// Configura o AuthService para permitir renovação de tokens
  void setAuthService(dynamic authService) {
    _authService = authService;
  }

  /// Obtém os headers padrão com autenticação
  /// Adiciona o access token se disponível
  Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      // Verifica se o token está expirado e renova se necessário
      if (_storage.isTokenExpired()) {
        try {
          await _authService?.refreshAccessToken();
        } catch (e) {
          // Se falhar ao renovar, continua sem token
          print('Erro ao renovar token: $e');
        }
      }

      // Adiciona o access token ao header
      final accessToken = _storage.getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  /// Faz uma requisição GET autenticada
  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    );
  }

  /// Faz uma requisição POST autenticada
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
  }

  /// Faz uma requisição PUT autenticada
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
  }

  /// Faz uma requisição DELETE autenticada
  Future<http.Response> delete(String endpoint, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    );
  }
}
