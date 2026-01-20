import 'dart:convert';
import 'package:get/get.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/services/http_service.dart';

/// Serviço de API para conquistas (GET/POST)
class AchievementApiService extends GetxService {
  late final HttpService _httpService;

  @override
  void onInit() {
    super.onInit();
    _httpService = Get.find<HttpService>();
  }

  Future<List<dynamic>> fetchAchievements() async {
    final response = await _httpService.get(
      ApiConstants.achievementsEndpoint,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['achievements'] is List) {
      return decoded['achievements'] as List;
    }
    return <dynamic>[];
  }

  Future<void> claimAchievement(String code) async {
    final endpoint =
        '${ApiConstants.achievementsEndpoint}/$code/claim';
    final response = await _httpService.post(endpoint, {});
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
