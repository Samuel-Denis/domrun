import 'dart:convert';
import 'package:get/get.dart';
import 'package:domrun/app/profile/models/public_user_profile.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/http_service.dart';

/// Serviço para buscar perfil público de um usuário
class PublicProfileService {
  final HttpService _httpService = Get.find<HttpService>();

  Future<PublicUserProfile> getUserById(String userId) async {
    final endpoint = '${ApiConstants.publicUserEndpoint}/$userId';
    final response = await _httpService.get(
      endpoint,
      includeAuth: false,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar usuário: Status ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    return PublicUserProfile.fromJson(userData);
  }
}
