import 'dart:async';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';
import 'package:nur_app/app/battles/models/battle_model.dart';
import 'package:nur_app/app/battles/models/battle_result_model.dart';
import 'package:nur_app/app/battles/models/battle_submit_model.dart';
import 'package:nur_app/app/battles/models/league_model.dart';
import 'package:nur_app/app/battles/service/battle_service.dart';
import 'package:nur_app/app/battles/utils/battle_score_calculator.dart';
import 'package:nur_app/app/maps/models/run_model.dart';
import 'package:nur_app/app/user/service/user_service.dart';

/// Controller para gerenciar batalhas PVP
class BattleController extends GetxController {
  late final BattleService _battleService;
  late final AuthService _authService;

  late final UserService _userService;

  // Batalha atual
  var currentBattle = Rxn<BattleModel>();

  // Status da batalha
  var battleStatus = BattleStatus.SEARCHING.obs;

  // Resultado da batalha
  var battleResult = Rxn<BattleResultModel>();

  // Flag para indicar se está procurando oponente
  var isSearchingOpponent = false.obs;

  // Flag para indicar se está em uma batalha
  var isInBattle = false.obs;

  // Histórico de batalhas
  var battleHistory = <BattleModel>[].obs;

  // Timer para batalhas por tempo
  Timer? _battleTimer;

  // Tempo restante da batalha (em segundos)
  var timeRemaining = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _battleService = Get.find<BattleService>();
    _authService = Get.find<AuthService>();
    _userService = Get.find<UserService>();
  }

  @override
  void onClose() {
    _battleTimer?.cancel();
    super.onClose();
  }

  /// Entra na fila de matchmaking
  /// [mode] - Modo da batalha (timed ou distance)
  /// [modeValue] - Valor opcional (ex: "15" para 15 minutos ou "5" para 5km)
  Future<void> joinQueue({required BattleMode mode, String? modeValue}) async {
    if (isSearchingOpponent.value) {
      print('⚠️ Já está procurando oponente');
      return;
    }

    try {
      isSearchingOpponent.value = true;
      print('🔍 Entrando na fila de matchmaking...');

      final battle = await _battleService.joinQueue(
        mode: mode,
        modeValue: modeValue,
      );

      currentBattle.value = battle;
      battleStatus.value = battle.status;

      if (battle.status == BattleStatus.IN_PROGRESS) {
        // Match encontrado imediatamente
        isInBattle.value = true;
        isSearchingOpponent.value = false;
        _startBattleTimer(mode, modeValue);
        print('✅ Oponente encontrado! Batalha iniciada');
      } else {
        // Ainda procurando oponente
        print('⏳ Procurando oponente...');
        // TODO: Implementar WebSocket para receber notificação quando encontrar oponente
      }
    } catch (e) {
      print('❌ Erro ao entrar na fila: $e');
      isSearchingOpponent.value = false;
      Get.snackbar(
        'Erro',
        'Não foi possível entrar na fila de matchmaking',
        backgroundColor: Get.theme.colorScheme.error,
      );
    }
  }

  /// Cancela a busca por oponente
  Future<void> cancelSearch() async {
    if (currentBattle.value == null) return;

    try {
      await _battleService.cancelBattle(currentBattle.value!.id);
      currentBattle.value = null;
      isSearchingOpponent.value = false;
      battleStatus.value = BattleStatus.CANCELLED;
      print('🚫 Busca cancelada');
    } catch (e) {
      print('❌ Erro ao cancelar busca: $e');
    }
  }

  /// Inicia o timer da batalha (para modo timed)
  void _startBattleTimer(BattleMode mode, String? modeValue) {
    if (mode != BattleMode.timed) return;

    _battleTimer?.cancel();

    // Converte modeValue para segundos (ex: "15" = 15 minutos = 900 segundos)
    final minutes = modeValue != null ? int.tryParse(modeValue) ?? 15 : 15;
    final totalSeconds = minutes * 60;
    timeRemaining.value = totalSeconds;

    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        // Tempo acabou
        timer.cancel();
        print('⏰ Tempo da batalha acabou!');
        // TODO: Notificar que o tempo acabou
      }
    });
  }

  /// Submete resultado da batalha após a corrida
  /// [distance] - Distância percorrida em metros
  /// [duration] - Duração em segundos
  /// [path] - Trajeto GPS
  Future<void> submitBattleResult({
    required double distance,
    required int duration,
    required List<PositionPoint> path,
  }) async {
    if (currentBattle.value == null) {
      print('⚠️ Nenhuma batalha ativa');
      return;
    }

    try {
      _battleTimer?.cancel();

      // Calcula pace médio
      final averagePace = BattleScoreCalculator.calculateAveragePace(
        distance: distance,
        duration: duration,
      );

      // Validações anti-cheat
      if (!BattleScoreCalculator.isValidPace(averagePace)) {
        print('⚠️ Pace inválido detectado (possível fraude)');
        Get.snackbar(
          'Corrida Inválida',
          'Pace muito rápido detectado. A corrida não será contabilizada.',
          backgroundColor: Get.theme.colorScheme.error,
        );
        return;
      }

      if (!BattleScoreCalculator.hasMinimumDuration(duration)) {
        print('⚠️ Duração mínima não atingida');
        Get.snackbar(
          'Corrida Inválida',
          'Duração mínima de 3 minutos não foi atingida.',
          backgroundColor: Get.theme.colorScheme.error,
        );
        return;
      }

      // Converte path para formato esperado pela API
      final pathJson = path.map((p) => p.toJson()).toList();

      // Valida trajeto GPS (anti-cheat)
      if (!BattleScoreCalculator.isValidPath(pathJson)) {
        print('⚠️ Trajeto GPS inválido detectado (possível Fake GPS)');
        Get.snackbar(
          'Corrida Inválida',
          'Trajeto GPS suspeito detectado. A corrida não será contabilizada.',
          backgroundColor: Get.theme.colorScheme.error,
        );
        return;
      }

      // Cria modelo de submissão
      final submitData = BattleSubmitModel(
        battleId: currentBattle.value!.id,
        distance: distance,
        duration: duration,
        averagePace: averagePace,
        path: path,
      );

      print('📤 Submetendo resultado da batalha...');
      final result = await _battleService.submitBattleResult(submitData);

      battleResult.value = result;
      battleStatus.value = BattleStatus.FINISHED;
      isInBattle.value = false;

      // Atualiza batalha atual com resultado
      if (currentBattle.value != null) {
        currentBattle.value = currentBattle.value!.copyWith(
          status: BattleStatus.FINISHED,
          p1Score: result.p1Score,
          p2Score: result.p2Score,
          winnerId: result.winnerId,
        );
      }

      // Mostra resultado
      _showBattleResult(result);

      // Recarrega histórico
      await loadBattleHistory();
    } catch (e) {
      print('❌ Erro ao submeter resultado: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível submeter resultado da batalha',
        backgroundColor: Get.theme.colorScheme.error,
      );
    }
  }

  /// Mostra o resultado da batalha
  void _showBattleResult(BattleResultModel result) {
    final user = _userService.currentUser.value;
    if (user == null) return;

    final isWinner = result.winnerId == user.id;
    final trophyChange = isWinner
        ? result.p1TrophyChange
        : result.p2TrophyChange;

    Get.snackbar(
      isWinner ? '🏆 Vitória!' : '😔 Derrota',
      isWinner
          ? 'Você ganhou! +$trophyChange troféus'
          : 'Você perdeu. $trophyChange troféus',
      backgroundColor: isWinner
          ? Get.theme.colorScheme.primary
          : Get.theme.colorScheme.error,
      duration: const Duration(seconds: 5),
    );
  }

  /// Carrega histórico de batalhas
  Future<void> loadBattleHistory({int limit = 20, int offset = 0}) async {
    try {
      final history = await _battleService.getBattleHistory(
        limit: limit,
        offset: offset,
      );
      battleHistory.value = history;
      print('✅ Histórico carregado: ${history.length} batalhas');
    } catch (e) {
      print('❌ Erro ao carregar histórico: $e');
    }
  }

  /// Limpa estado da batalha atual
  void clearCurrentBattle() {
    _battleTimer?.cancel();
    currentBattle.value = null;
    battleResult.value = null;
    battleStatus.value = BattleStatus.SEARCHING;
    isSearchingOpponent.value = false;
    isInBattle.value = false;
    timeRemaining.value = 0;
  }

  /// Obtém a liga baseada no número de troféus
  static LeagueModel getLeagueByTrophies(int trophies) {
    return LeagueModel.getLeagueByTrophies(trophies);
  }
}
