import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/battles/controller/battle_controller.dart';
import 'package:nur_app/app/battles/models/battle_model.dart';
import 'package:nur_app/app/user/service/user_service.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';

/// Página de batalhas PVP
/// Permite entrar na fila de matchmaking, ver oponente e resultados
class BattlePage extends StatelessWidget {
  const BattlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final controller = Get.find<BattleController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('⚔️ Batalhas PVP'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Obx(
            () => controller.isSearchingOpponent.value
                ? _buildSearchingView(context, controller, responsive)
                : const SizedBox.shrink(),
          ),
          Obx(
            () => controller.isInBattle.value &&
                    controller.currentBattle.value != null
                ? _buildBattleInProgressView(context, controller, responsive)
                : const SizedBox.shrink(),
          ),
          Obx(
            () => controller.battleResult.value != null
                ? _buildBattleResultView(context, controller, responsive)
                : const SizedBox.shrink(),
          ),
          Obx(
            () => !controller.isSearchingOpponent.value &&
                    !(controller.isInBattle.value &&
                        controller.currentBattle.value != null) &&
                    controller.battleResult.value == null
                ? _buildModeSelectionView(context, controller, responsive)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Tela de seleção de modo de batalha
  Widget _buildModeSelectionView(
    BuildContext context,
    BattleController controller,
    Responsive responsive,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Escolha o modo de batalha',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.spacing(40)),

            // Modo por tempo
            _buildModeCard(
              context,
              responsive,
              title: '⏱️ Por Tempo',
              description: 'Corra por um tempo determinado',
              options: ['15 min', '30 min', '45 min', '60 min'],
              onTap: (value) {
                final minutes = value.replaceAll(' min', '');
                controller.joinQueue(
                  mode: BattleMode.timed,
                  modeValue: minutes,
                );
              },
            ),

            SizedBox(height: responsive.spacing(20)),

            // Modo por distância
            _buildModeCard(
              context,
              responsive,
              title: '📏 Por Distância',
              description: 'Corra uma distância determinada',
              options: ['3 km', '5 km', '10 km', '21 km'],
              onTap: (value) {
                final km = value.replaceAll(' km', '');
                controller.joinQueue(mode: BattleMode.distance, modeValue: km);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Card de modo de batalha
  Widget _buildModeCard(
    BuildContext context,
    Responsive responsive, {
    required String title,
    required String description,
    required List<String> options,
    required Function(String) onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(20)),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBlue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: responsive.spacing(16)),
          Wrap(
            spacing: responsive.spacing(10),
            runSpacing: responsive.spacing(10),
            children: options.map((option) {
              return ElevatedButton(
                onPressed: () => onTap(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20),
                    vertical: responsive.spacing(12),
                  ),
                ),
                child: Text(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Tela de procurando oponente
  Widget _buildSearchingView(
    BuildContext context,
    BattleController controller,
    Responsive responsive,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
            ),
            SizedBox(height: responsive.spacing(30)),
            const Text(
              'Procurando oponente...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.spacing(10)),
            const Text(
              'Aguarde enquanto encontramos um oponente compatível',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(40)),
            ElevatedButton(
              onPressed: () => controller.cancelSearch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(30),
                  vertical: responsive.spacing(15),
                ),
              ),
              child: const Text('Cancelar Busca'),
            ),
          ],
        ),
      ),
    );
  }

  /// Tela de batalha em andamento
  Widget _buildBattleInProgressView(
    BuildContext context,
    BattleController controller,
    Responsive responsive,
  ) {
    final battle = controller.currentBattle.value!;
    final user = Get.find<UserService>().currentUser.value;

    // Determina qual jogador é o usuário atual
    final isPlayer1 = battle.player1Id == user?.id;
    final opponent = isPlayer1 ? battle.player2 : battle.player1;

    return Padding(
      padding: EdgeInsets.all(responsive.spacing(20)),
      child: Column(
        children: [
          // Informações do oponente
          if (opponent != null) ...[
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentBlue, width: 2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.accentBlue,
                    backgroundImage: opponent.photoUrl != null
                        ? NetworkImage(opponent.photoUrl!)
                        : null,
                    child: opponent.photoUrl == null
                        ? Text(
                            opponent.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: responsive.spacing(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opponent.name ?? opponent.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          '${opponent.league} • ${opponent.trophies} troféus',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(20)),
          ],

          // Timer (se modo timed)
          if (battle.mode == BattleMode.timed) ...[
            Obx(() {
              final minutes = controller.timeRemaining.value ~/ 60;
              final seconds = controller.timeRemaining.value % 60;
              return Container(
                padding: EdgeInsets.all(responsive.spacing(20)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tempo Restante',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: responsive.spacing(20)),
          ],

          // Instruções
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '⚔️ Batalha em Andamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Vá para a tela do mapa e inicie sua corrida!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tela de resultado da batalha
  Widget _buildBattleResultView(
    BuildContext context,
    BattleController controller,
    Responsive responsive,
  ) {
    final result = controller.battleResult.value!;
    final battle = controller.currentBattle.value;
    final user = Get.find<UserService>().currentUser.value;

    if (battle == null || user == null) {
      return const Center(
        child: Text(
          'Erro ao carregar resultado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final isPlayer1 = battle.player1Id == user.id;
    final isWinner = result.winnerId == user.id;
    final myScore = isPlayer1 ? result.p1Score : result.p2Score;
    final opponentScore = isPlayer1 ? result.p2Score : result.p1Score;
    final trophyChange = isPlayer1
        ? result.p1TrophyChange
        : result.p2TrophyChange;
    final newTrophies = isPlayer1 ? result.p1NewTrophies : result.p2NewTrophies;
    final newLeague = isPlayer1 ? result.p1NewLeague : result.p2NewLeague;

    return Padding(
      padding: EdgeInsets.all(responsive.spacing(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Resultado
          Container(
            padding: EdgeInsets.all(responsive.spacing(30)),
            decoration: BoxDecoration(
              color: isWinner
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWinner ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isWinner ? '🏆 Vitória!' : '😔 Derrota',
                  style: TextStyle(
                    color: isWinner ? Colors.green : Colors.red,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: responsive.spacing(20)),
                Text(
                  'Seu Score: ${myScore?.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  'Oponente: ${opponentScore?.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(30)),

          // Mudança de troféus
          Container(
            padding: EdgeInsets.all(responsive.spacing(20)),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  trophyChange > 0 ? '+$trophyChange' : '$trophyChange',
                  style: TextStyle(
                    color: trophyChange > 0 ? Colors.green : Colors.red,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'troféus',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (newLeague != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Nova Liga: $newLeague',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Total: $newTrophies troféus',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(30)),

          // Botão para voltar
          ElevatedButton(
            onPressed: () {
              controller.clearCurrentBattle();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(40),
                vertical: responsive.spacing(15),
              ),
            ),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}
