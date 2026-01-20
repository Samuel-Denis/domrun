import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nur_app/app/battles/models/battle_model.dart';
import 'package:nur_app/app/battles/models/battle_result_model.dart';
import 'package:nur_app/app/battles/models/battle_submit_model.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/services/storage_service.dart';

/// Serviço para gerenciar batalhas PVP
class BattleService extends GetxService {
  late final StorageService _storage;

  @override
  Future<void> onInit() async {
    super.onInit();
    _storage = Get.find<StorageService>();
  }

  /// Obtém os headers com autenticação
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final accessToken = _storage.getAccessToken();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// Entra na fila de matchmaking
  /// [mode] - Modo da batalha (timed ou distance)
  /// [modeValue] - Valor opcional (ex: "15" para 15 minutos ou "5" para 5km)
  Future<BattleModel> joinQueue({
    required BattleMode mode,
    String? modeValue,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConstants.baseUrl}${ApiConstants.battlesQueueEndpoint}';

      final body = <String, dynamic>{
        'mode': mode.name,
        if (modeValue != null) 'modeValue': modeValue,
      };

      print('🔍 Entrando na fila de matchmaking...');
      print('   - Modo: ${mode.name}');
      if (modeValue != null) print('   - Valor: $modeValue');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      print('📡 Resposta da API: Status ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('   📦 Dados recebidos: $data');
        final battle = BattleModel.fromJson(data);
        print('✅ Batalha criada/encontrada: ${battle.id}');
        print('   - Status: ${battle.status.name}');
        return battle;
      } else {
        print('❌ Erro na resposta da API: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Erro ao entrar na fila: Status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao entrar na fila: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Submete resultado de uma batalha
  /// [submitData] - Dados da corrida para submeter
  Future<BattleResultModel> submitBattleResult(
    BattleSubmitModel submitData,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConstants.baseUrl}${ApiConstants.battlesSubmitEndpoint}';

      print('📤 Submetendo resultado da batalha...');
      print('   - Battle ID: ${submitData.battleId}');
      print('   - Distância: ${submitData.distance}m');
      print('   - Duração: ${submitData.duration}s');
      print('   - Pace: ${submitData.averagePace} min/km');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(submitData.toJson()),
      );

      print('📡 Resposta da API: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final result = BattleResultModel.fromJson(data);
        print('✅ Resultado submetido com sucesso');
        print('   - P1 Score: ${result.p1Score}');
        print('   - P2 Score: ${result.p2Score}');
        if (result.winnerId != null) {
          print('   - Vencedor: ${result.winnerId}');
        }
        return result;
      } else {
        print('❌ Erro na resposta da API: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Erro ao submeter resultado: Status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao submeter resultado: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancela uma batalha
  /// [battleId] - ID da batalha a ser cancelada
  Future<void> cancelBattle(String battleId) async {
    try {
      final headers = await _getHeaders();
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.battlesCancelEndpoint}/$battleId';

      print('🚫 Cancelando batalha: $battleId');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('📡 Resposta da API: Status ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Batalha cancelada com sucesso');
      } else {
        print('❌ Erro na resposta da API: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Erro ao cancelar batalha: Status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao cancelar batalha: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtém histórico de batalhas
  /// [limit] - Número máximo de batalhas a retornar (padrão: 20)
  /// [offset] - Offset para paginação (padrão: 0)
  Future<List<BattleModel>> getBattleHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.battlesHistoryEndpoint}?limit=$limit&offset=$offset';

      print('📜 Buscando histórico de batalhas...');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📡 Resposta da API: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final battles = data
            .map((b) => BattleModel.fromJson(b as Map<String, dynamic>))
            .toList();
        print('✅ ${battles.length} batalhas encontradas no histórico');
        return battles;
      } else {
        print('❌ Erro na resposta da API: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Erro ao obter histórico: Status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao obter histórico: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
