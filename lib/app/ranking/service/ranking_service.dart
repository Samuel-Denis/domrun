import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nur_app/app/ranking/models/trophy_ranking_entry.dart';
import 'package:nur_app/core/constants/api_constants.dart';

/// Serviço para buscar ranking por troféus (rota pública)
class RankingService {
  Future<List<TrophyRankingEntry>> getTrophyRanking({int limit = 10}) async {
    final safeLimit = limit.clamp(1, 100);
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.trophyRankingEndpoint}?limit=$safeLimit';

    final response = await http.get(Uri.parse(url));
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
