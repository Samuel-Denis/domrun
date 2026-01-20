import 'package:get_storage/get_storage.dart';

/// Serviço de armazenamento local seguro
/// Gerencia o armazenamento de tokens e dados do usuário
/// Usa GetStorage para armazenamento persistente e seguro
class StorageService {
  // Instância do GetStorage para armazenamento local
  GetStorage? _storage;

  // Chaves para armazenamento
  // Tokens e cache básico do usuário
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userDataKey = 'user_data';

  /// Obtém a instância do GetStorage, inicializando se necessário
  /// Garante que o storage esteja sempre disponível
  GetStorage get storage {
    if (_storage == null) {
      // Se não estiver inicializado, inicializa agora
      // O GetStorage.init() já foi chamado no main.dart
      _storage = GetStorage();
    }
    return _storage!;
  }

  /// Inicializa o serviço de storage
  /// Deve ser chamado antes de usar o serviço
  Future<void> init() async {
    // O GetStorage.init() já foi chamado no main.dart
    // Apenas obtém a instância do singleton
    _storage = GetStorage();
  }

  /// Salva o access token de forma segura
  /// [token] - Token de acesso a ser salvo
  Future<void> saveAccessToken(String token) async {
    await storage.write(_accessTokenKey, token);
  }

  /// Salva o refresh token de forma segura
  /// [token] - Refresh token a ser salvo
  Future<void> saveRefreshToken(String token) async {
    await storage.write(_refreshTokenKey, token);
  }

  /// Salva ambos os tokens de uma vez
  /// [accessToken] - Token de acesso
  /// [refreshToken] - Refresh token
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(_accessTokenKey, accessToken);
    await storage.write(_refreshTokenKey, refreshToken);
  }

  /// Obtém o access token salvo
  /// Retorna null se não houver token salvo
  String? getAccessToken() {
    return storage.read<String>(_accessTokenKey);
  }

  /// Obtém o refresh token salvo
  /// Retorna null se não houver token salvo
  String? getRefreshToken() {
    return storage.read<String>(_refreshTokenKey);
  }

  /// Salva dados básicos do usuário (cache local)
  Future<void> saveUserData(Map<String, dynamic> data) async {
    await storage.write(_userDataKey, data);
  }

  /// Obtém dados básicos do usuário do cache
  Map<String, dynamic>? getUserData() {
    final data = storage.read(_userDataKey);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Salva a data de expiração do token
  /// [expiryDate] - Data de expiração em formato ISO string
  Future<void> saveTokenExpiry(DateTime expiryDate) async {
    await storage.write(_tokenExpiryKey, expiryDate.toIso8601String());
  }

  /// Obtém a data de expiração do token
  /// Retorna null se não houver data salva
  DateTime? getTokenExpiry() {
    final expiryString = storage.read<String>(_tokenExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  /// Verifica se o token está expirado
  /// Retorna true se o token estiver expirado ou não existir
  bool isTokenExpired() {
    final expiry = getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// Limpa todos os dados de autenticação
  /// Remove apenas tokens (dados do usuário não são armazenados)
  Future<void> clearAuthData() async {
    // Garante que o storage esteja inicializado antes de usar
    final storageInstance = storage;
    await storageInstance.remove(_accessTokenKey);
    await storageInstance.remove(_refreshTokenKey);
    await storageInstance.remove(_tokenExpiryKey);
    await storageInstance.remove(_userDataKey);
  }

  /// Limpa todo o storage
  Future<void> clearAll() async {
    await storage.erase();
  }
}
