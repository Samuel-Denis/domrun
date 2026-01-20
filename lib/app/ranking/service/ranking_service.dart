import 'dart:convert';
import 'package:get/get.dart';
import 'package:domrun/app/ranking/models/trophy_ranking_entry.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/http_service.dart';

/// Serviço para buscar ranking por troféus (rota pública)
class RankingService {
  final HttpService _httpService = Get.find<HttpService>();

  Future<List<TrophyRankingEntry>> getTrophyRanking({int limit = 10}) async {
    final safeLimit = limit.clamp(1, 100);
    final endpoint =
        '${ApiConstants.trophyRankingEndpoint}?limit=$safeLimit';

    final response = await _httpService.get(
      endpoint,
      includeAuth: false,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar ranking: Status ${response.statusCode}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final rankingList = (data['ranking'] as List? ?? [])
        .map((item) => TrophyRankingEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    return rankingList;
  }
}
