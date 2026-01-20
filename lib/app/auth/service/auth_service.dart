import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:domrun/app/auth/models/user_model.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/http_service.dart';
import 'package:domrun/core/services/storage_service.dart';

/// Serviço de autenticação
/// Gerencia todas as operações relacionadas à autenticação do usuário
/// Pode ser facilmente substituído por integração com Firebase, Supabase, etc.
class AuthService extends GetxService {
  // Serviço de storage para guardar tokens
  late final StorageService _storage;
  late final UserService _userService;
  late final HttpService _httpService;

  // Indica se o usuário está autenticado
  bool get isAuthenticated => _userService.hasUser;

  /// Inicializa o serviço de autenticação
  /// Configura o storage
  /// Nota: checkAuthStatus() é chamado no main.dart antes de iniciar o app
  @override
  void onInit() {
    super.onInit();
    // Inicializa o storage
    _storage = Get.find<StorageService>();
    _userService = Get.find<UserService>();
    _httpService = Get.find<HttpService>();
    // checkAuthStatus() é chamado no main.dart para garantir que os dados
    // sejam carregados antes de definir a rota inicial
  }

  /// Obtém o access token atual
  /// Retorna null se não houver token ou se estiver expirado
  String? getAccessToken() {
    return _storage.getAccessToken();
  }

  /// Obtém o refresh token atual
  /// Retorna null se não houver token
  String? getRefreshToken() {
    return _storage.getRefreshToken();
  }

  /// Realiza login com username e senha
  /// [email] - Email ou nome de usuário do usuário (a API aceita username)
  /// [password] - Senha do usuário
  /// Retorna o UserModel se o login for bem-sucedido
  /// Lança uma exceção se o login falhar
  Future<UserModel> loginWithEmail(String username, String password) async {
    try {
      // Validação básica antes de fazer a requisição
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username e senha são obrigatórios');
      }

      if (password.length < 6) {
        throw Exception('Senha deve ter pelo menos 6 caracteres');
      }

      // Prepara o corpo da requisição conforme a estrutura da API
      // A API espera username e password
      final requestBody = {
        'username': username, // O campo pode ser username ou email
        'password': password,
      };

      // Faz a requisição POST para fazer login
      final response = await _httpService.post(
        ApiConstants.loginEndpoint,
        requestBody,
        includeAuth: false,
      );

      // Verifica se a requisição foi bem-sucedida (status 200/201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Decodifica a resposta JSON
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Extrai os tokens da resposta
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw Exception('Tokens não recebidos do servidor');
        }

        // Salva os tokens de forma segura no storage
        await _storage.saveTokens(accessToken, refreshToken);

        // Salva a data de expiração do access token (7 dias)
        final expiryDate = DateTime.now().add(const Duration(days: 7));
        await _storage.saveTokenExpiry(expiryDate);

        // Extrai os dados do usuário
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData == null) {
          throw Exception('Dados do usuário não recebidos');
        }

        // Cria o modelo de usuário a partir da resposta
        // O fromJson já remove campos extras automaticamente
        final user = UserModel.fromJson(userData);

        _userService.setUser(user);

        return user;
      } else {
        // Se a requisição falhou, tenta extrair mensagem de erro
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Credenciais inválidas';
          throw Exception(errorMessage);
        } catch (_) {
          // Se não conseguir decodificar o erro, lança exceção genérica
          throw Exception('Erro ao fazer login: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      // Re-lança a exceção para ser tratada pelo controller
      rethrow;
    }
  }

  /// Realiza cadastro de novo usuário
  /// [email] - Email do usuário
  /// [password] - Senha do usuário
  /// [name] - Nome do usuário
  /// [username] - Nome de usuário único
  /// Retorna o UserModel se o cadastro for bem-sucedido
  /// Lança uma exceção se o cadastro falhar
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // Validações básicas antes de fazer a requisição
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email e senha são obrigatórios');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Email inválido');
      }

      if (password.length < 6) {
        throw Exception('Senha deve ter pelo menos 6 caracteres');
      }

      if (name.isEmpty) {
        throw Exception('Nome é obrigatório');
      }

      if (username.isEmpty) {
        throw Exception('Nome de usuário é obrigatório');
      }

      // Prepara o corpo da requisição conforme a estrutura da API
      // A API espera: username, email, password, name
      final requestBody = {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
      };

      // Faz a requisição POST para registrar o usuário
      final response = await _httpService.post(
        ApiConstants.registerEndpoint,
        requestBody,
        includeAuth: false,
      );

      // Verifica se a requisição foi bem-sucedida (status 201 Created)
      if (response.statusCode == 201) {
        // Decodifica a resposta JSON
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Extrai os tokens da resposta
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw Exception('Tokens não recebidos do servidor');
        }

        // Salva os tokens de forma segura no storage
        await _storage.saveTokens(accessToken, refreshToken);

        // Salva a data de expiração do access token (7 dias)
        final expiryDate = DateTime.now().add(const Duration(days: 7));
        await _storage.saveTokenExpiry(expiryDate);

        // Extrai os dados do usuário
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData == null) {
          throw Exception('Dados do usuário não recebidos');
        }

        // Cria o modelo de usuário a partir da resposta
        // O fromJson já remove campos extras automaticamente
        final user = UserModel.fromJson(userData);

        _userService.setUser(user);

        return user;
      } else {
        // Se a requisição falhou, tenta extrair mensagem de erro
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Erro ao criar conta';
          throw Exception(errorMessage);
        } catch (_) {
          // Se não conseguir decodificar o erro, lança exceção genérica
          throw Exception('Erro ao criar conta: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      // Re-lança a exceção para ser tratada pelo controller
      rethrow;
    }
  }

  /// Envia email de recuperação de senha
  /// [email] - Email do usuário que deseja recuperar a senha
  /// Retorna true se o email foi enviado com sucesso
  /// Lança uma exceção se houver erro
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // Simula delay de rede
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Substituir por chamada real à API
      // final response = await http.post(
      //   Uri.parse('${ApiConstants.baseUrl}/auth/forgot-password'),
      //   body: {'email': email},
      // );
      // if (response.statusCode == 200) {
      //   return true;
      // } else {
      //   throw Exception('Erro ao enviar email');
      // }

      // Validação básica
      if (email.isEmpty) {
        throw Exception('Email é obrigatório');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Email inválido');
      }

      // Simula envio bem-sucedido
      // Em produção, isso enviaria um email real
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Realiza login com Google
  /// Retorna o UserModel se o login for bem-sucedido
  /// Lança uma exceção se o login falhar
  Future<UserModel> loginWithGoogle() async {
    try {
      // TODO: Implementar autenticação com Google
      // Exemplo com google_sign_in:
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) {
      //   throw Exception('Login cancelado pelo usuário');
      // }
      // final GoogleSignInAuthentication googleAuth =
      //     await googleUser.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      // final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // final user = UserModel.fromFirebase(userCredential.user);
      // currentUser.value = user;
      // return user;

      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Login com Google ainda não implementado');
    } catch (e) {
      rethrow;
    }
  }

  /// Realiza login com Apple
  /// Retorna o UserModel se o login for bem-sucedido
  /// Lança uma exceção se o login falhar
  Future<UserModel> loginWithApple() async {
    try {
      // TODO: Implementar autenticação com Apple
      // Exemplo com sign_in_with_apple:
      // final credential = await SignInWithApple.getAppleIDCredential(...);
      // final user = UserModel.fromApple(credential);
      // currentUser.value = user;
      // return user;

      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Login com Apple ainda não implementado');
    } catch (e) {
      rethrow;
    }
  }

  /// Renova o access token usando o refresh token
  /// Retorna o novo access token se bem-sucedido
  /// Lança uma exceção se o refresh falhar
  Future<String> refreshAccessToken() async {
    try {
      // Obtém o refresh token salvo
      final refreshToken = _storage.getRefreshToken();

      if (refreshToken == null) {
        throw Exception('Refresh token não encontrado. Faça login novamente.');
      }

      // Prepara o corpo da requisição
      final requestBody = {'refresh_token': refreshToken};

      // Faz a requisição POST para renovar o token
      final response = await _httpService.post(
        ApiConstants.refreshEndpoint,
        requestBody,
        includeAuth: false,
      );

      // Verifica se a requisição foi bem-sucedida (status 200 OK)
      if (response.statusCode == 200) {
        // Decodifica a resposta JSON
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Extrai o novo access token
        final newAccessToken = data['access_token'] as String?;

        if (newAccessToken == null) {
          throw Exception('Novo access token não recebido');
        }

        // Salva o novo access token
        await _storage.saveAccessToken(newAccessToken);

        // Atualiza a data de expiração (7 dias a partir de agora)
        final expiryDate = DateTime.now().add(const Duration(days: 7));
        await _storage.saveTokenExpiry(expiryDate);

        return newAccessToken;
      } else {
        // Se o refresh token estiver inválido, limpa os dados
        if (response.statusCode == 401 || response.statusCode == 403) {
          await _storage.clearAuthData();
          _userService.clearUser();
          throw Exception('Refresh token inválido. Faça login novamente.');
        }

        // Tenta extrair mensagem de erro
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Erro ao renovar token';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
            'Erro ao renovar token: Status ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Realiza logout do usuário
  /// Invalida o refresh token no servidor e limpa os dados localmente
  Future<void> logout() async {
    try {
      // Obtém o refresh token para invalidar no servidor
      final refreshToken = _storage.getRefreshToken();

      // Se houver refresh token, tenta invalidá-lo no servidor
      if (refreshToken != null) {
        try {
          final requestBody = {'refresh_token': refreshToken};

          await _httpService.post(
            ApiConstants.logoutEndpoint,
            requestBody,
            includeAuth: false,
          );
        } catch (e) {
          // Se falhar ao invalidar no servidor, continua com a limpeza local
          print('Erro ao invalidar token no servidor: $e');
        }
      }

      // Limpa todos os dados de autenticação localmente
      await _storage.clearAuthData();

      _userService.clearUser();
    } catch (e) {
      // Mesmo se houver erro, limpa os dados localmente
      await _storage.clearAuthData();
      _userService.clearUser();
      rethrow;
    }
  }

  /// Valida se o email tem formato válido
  /// [email] - Email a ser validado
  /// Retorna true se o email for válido
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Atualiza o perfil do usuário
  /// [name] - Novo nome do usuário
  /// [username] - Novo username
  /// [color] - Nova cor do domínio (hexadecimal)
  /// [password] - Nova senha (opcional, apenas se quiser alterar)
  /// [biography] - Biografia do usuário (opcional)
  /// Retorna o UserModel atualizado
  /// Lança uma exceção se a atualização falhar
  Future<UserModel> updateProfile({
    required String name,
    required String username,
    String? color,
    String? password,
    String? biography,
    File? photo,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.updateProfileEndpoint}',
        ),
      );

      final headers = await _httpService.getHeaders();
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de acesso não encontrado');
      }
      request.headers.addAll(headers);

      request.fields.addAll({
        'name': name,
        'username': username,
        if (color != null) 'color': color,
        if (password != null && password.isNotEmpty) 'password': password,
        if (biography != null && biography.isNotEmpty) 'biography': biography,
      });

      // Adiciona o arquivo apenas se fornecido (servidor espera o campo 'file')
      // O ParseFilePipe valida tipos: jpg, jpeg, png, gif, webp
      if (photo != null && await photo.exists()) {
        // Obtém a extensão do arquivo para garantir o content-type correto
        final extension = photo.path.split('.').last.toLowerCase();
        String? contentType;

        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'photo', // Campo esperado pelo ParseFilePipe
            photo.path,
            filename: 'profile_photo.$extension',
            contentType: contentType != null
                ? http.MediaType.parse(contentType)
                : null,
          ),
        );
      }

      // Faz a requisição PUT para atualizar o perfil
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Decodifica a resposta JSON
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Cria o modelo de usuário atualizado
        final userMap = Map<String, dynamic>.from(data);
        userMap.remove('password'); // Remove senha se estiver presente
        userMap.remove('postLikes');
        userMap.remove('userAchievements');
        userMap.remove('runs');
        userMap.remove('posts');
        userMap.remove('territories');

        final baseUser = _userService.currentUser.value;
        final updatedUser = baseUser != null
            ? baseUser.copyWithJson(userMap)
            : UserModel.fromJson(userMap);

        _userService.setUser(updatedUser);

        return updatedUser;
      } else {
        // Tenta extrair mensagem de erro
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Erro ao atualizar perfil';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
            'Erro ao atualizar perfil: Status ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica se o usuário está autenticado
  /// Restaura a sessão se houver tokens válidos salvos
  /// Tenta renovar o token se estiver expirado
  /// Carrega os dados do usuário da API se o token for válido
  Future<bool> checkAuthStatus() async {
    try {
      // Verifica se há refresh token salvo
      final refreshToken = _storage.getRefreshToken();

      if (refreshToken == null) {
        // Não há tokens, usuário não está autenticado
        _userService.clearUser();
        return false;
      }

      // Verifica se o access token está expirado
      if (_storage.isTokenExpired()) {
        // Tenta renovar o token
        try {
          await refreshAccessToken();
        } catch (e) {
          // Se falhar ao renovar, limpa os dados
          await _storage.clearAuthData();
          _userService.clearUser();
          return false;
        }
      }

      // Verifica se o access token existe
      final accessToken = _storage.getAccessToken();
      if (accessToken == null) {
        await _storage.clearAuthData();
        _userService.clearUser();
        return false;
      }

      // Tenta buscar os dados do usuário da API para validar o token
      try {
        await _userService.loadUserFromApi(accessToken);
        return true;
      } on TimeoutException catch (e) {
        print('Servidor indisponível (timeout): $e');
        return false;
      } on SocketException catch (e) {
        print('Servidor indisponível (socket): $e');
        return false;
      } catch (e) {
        // Se falhar ao buscar dados, só limpa se for token inválido
        print('Erro ao carregar usuário: $e');
        final message = e.toString();
        final isUnauthorized =
            message.contains('Token inválido') ||
            message.contains('Status 401') ||
            message.contains('Status 403');
        if (isUnauthorized) {
          await _storage.clearAuthData();
          _userService.clearUser();
          return false;
        }
        return false;
      }
    } catch (e) {
      // Em caso de erro, limpa os dados
      print('Erro ao verificar autenticação: $e');
      await _storage.clearAuthData();
      _userService.clearUser();
      return false;
    }
  }
}
