import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nur_app/app/profile/models/public_user_profile.dart';
import 'package:nur_app/core/constants/api_constants.dart';

/// Serviço para buscar perfil público de um usuário
class PublicProfileService {
  Future<PublicUserProfile> getUserById(String userId) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.publicUserEndpoint}/$userId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar usuário: Status ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    return PublicUserProfile.fromJson(userData);
  }
}
