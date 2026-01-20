import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nur_app/app/auth/models/user_model.dart';
import 'package:nur_app/core/constants/api_constants.dart';

/// Serviço dedicado ao estado do usuário logado
/// Responsável por buscar e armazenar o usuário em memória
class UserService extends GetxService {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  bool get hasUser => currentUser.value != null;

  void setUser(UserModel user) {
    currentUser.value = user;
  }

  void clearUser() {
    currentUser.value = null;
  }

  Future<UserModel> loadUserFromApi(String accessToken) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.profileCompleteEndpoint}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final rawUser = data['user'];
          final Map<String, dynamic> userMap;
          if (rawUser is Map<String, dynamic>) {
            userMap = rawUser;
          } else if (data.containsKey('id')) {
            userMap = data;
          } else {
            throw Exception('Dados do usuário não encontrados na resposta');
          }

          final user = UserModel.fromJson(userMap);
          currentUser.value = user;
          return user;
        }
        throw Exception('Resposta inválida do servidor');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Token inválido ou expirado');
      } else {
        throw Exception(
          'Erro ao carregar usuário: Status ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw TimeoutException('Servidor indisponível');
    } on SocketException {
      throw SocketException('Servidor indisponível');
    }
  }
}
