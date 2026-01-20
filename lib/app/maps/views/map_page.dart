import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nur_app/app/user/service/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nur_app/app/maps/controller/controller.dart';
import 'package:nur_app/app/navigation/widgets/bottom_navigation_bar.dart';
import 'package:nur_app/app/navigation/controller/navigation_controller.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';
import 'package:nur_app/routes/app_routes.dart';

// Importação corrigida (caso precise descomentar no futuro)
// import 'package:nur_app/app/navigation/controller/navigation_controller.dart';

/// Página completa do mapa com interface gamificada
/// Exibe o mapa Mapbox com cabeçalho, estatísticas, missão diária e controles
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    // Obtém os controllers e serviços
    final MapController controller = Get.find<MapController>();
    final UserService userService = Get.find<UserService>();
    // final AuthService authService = Get.find<AuthService>();

    // Atualiza o índice da navegação para Mapa (1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navController = Get.find<NavigationController>();
      if (navController.currentIndex.value != 1) {
        navController.currentIndex.value = 1;
      }
      // Evita excluir o LoginController aqui para não
      // destruir TextEditingControllers ainda referenciados.
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Fundo escuro
      body: Stack(
        children: [
          // CAMADA 1: O MAPA (Fundo)
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: controller.onMapCreated,
            onTapListener: controller.handleMapTap,
            cameraOptions: CameraOptions(
              // Coordenadas de Ribeirão Preto, SP
              center: Point(coordinates: Position(-47.8103, -21.1775)),
              zoom: 13.0,
            ),
            styleUri: ApiConstants.mapboxStyleDark,
          ),

          // CAMADA 4: ESTATÍSTICAS
          Positioned(
            top: MediaQuery.of(context).padding.top + responsive.spacing(10),
            left: responsive.width * 0.02,
            right: responsive.width * 0.02,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicador de Map Matching em progresso
                _buildMapMatchingIndicator(context, controller, responsive),
                SizedBox(height: responsive.spacing(8)),
                Obx(
                  () =>
                      controller.isTracking.value ||
                          controller.isRunSummaryLoading.value ||
                          controller.isRunSummaryVisible.value
                      ? const SizedBox.shrink()
                      : _buildLeagueSummaryCard(userService, responsive),
                ),

                Obx(
                  () => controller.isTracking.value
                      ? _buildStats(context, controller)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // CAMADA 5: CARD DE MISSÃO DIÁRIA
          //  _buildDailyMission(context),
          // CAMADA 6: BOTÕES DE AÇÃO
          Obx(
            () =>
                controller.isRunSummaryLoading.value ||
                    controller.isRunSummaryVisible.value
                ? const SizedBox.shrink()
                : _buildActionButtons(context, controller),
          ),

          // CAMADA 7: BOTÃO DE INFORMAÇÃO (I)
          _buildInfoButton(context, responsive),

          // CAMADA 8: CARD DE INFORMAÇÕES DO TERRITÓRIO
          Obx(
            () => controller.selectedTerritory.value != null
                ? _buildTerritoryInfoCard(context, controller, responsive)
                : const SizedBox.shrink(),
          ),

          // CAMADA 9: RESUMO DA CORRIDA (overlay)
          Obx(
            () => controller.isRunSummaryVisible.value
                ? _buildRunSummaryOverlay(context, controller, responsive)
                : const SizedBox.shrink(),
          ),

          // CAMADA 10: LOADING DO RESUMO (bloqueia navegação)
          Obx(
            () => controller.isRunSummaryLoading.value
                ? _buildRunSummaryLoading(responsive)
                : const SizedBox.shrink(),
          ),

          Obx(
            () =>
                controller.isTracking.value ||
                    controller.isRunSummaryLoading.value ||
                    controller.isRunSummaryVisible.value
                ? const SizedBox.shrink()
                : Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: BottomNavigationBarWidget(),
                  ),
          ),
        ],
      ),
      //bottomNavigationBar: const ,
    );
  }

  /// Constrói o indicador visual de Map Matching
  Widget _buildMapMatchingIndicator(
    BuildContext context,
    MapController controller,
    Responsive responsive,
  ) {
    return Obx(() {
      if (!controller.isApplyingMapMatching.value) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(12),
          vertical: responsive.spacing(8),
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(responsive.spacing(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: responsive.containerSize(16),
              height: responsive.containerSize(16),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: responsive.spacing(10)),
            Text(
              'Corrigindo trajeto...',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Constrói as estatísticas da corrida
  Widget _buildStats(BuildContext context, MapController controller) {
    final responsive = Responsive(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildStatCard(
            'Distância',
            () => controller.formatDistance(controller.currentDistance.value),
            responsive,
          ),
        ),
        SizedBox(width: responsive.spacing(5)),
        Expanded(
          child: _buildStatCard(
            'Tempo',
            () => controller.formatDuration(controller.currentDuration.value),
            responsive,
          ),
        ),
        SizedBox(width: responsive.spacing(5)),
        Expanded(
          child: _buildStatCard(
            'Pace',
            () => controller.formatPace(
              controller.currentDuration.value,
              controller.currentDistance.value,
            ),
            responsive,
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSummaryCard(
    UserService userService,
    Responsive responsive,
  ) {
    return Obx(() {
      final user = userService.currentUser.value;
      final leagueName = user?.league;
      final trophies = user?.trophies ?? 0;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16),
          vertical: responsive.spacing(12),
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(responsive.spacing(18)),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: responsive.containerSize(44),
              height: responsive.containerSize(44),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 22,
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIGA ATUAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: responsive.fontSize(11),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    leagueName?.displayName ?? 'Liga',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: responsive.containerSize(36),
              color: AppColors.border,
            ),
            SizedBox(width: responsive.spacing(12)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TROFÉUS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: responsive.fontSize(11),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Row(
                  children: [
                    Text(
                      _formatTrophies(trophies),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: responsive.fontSize(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(6)),
                    Icon(
                      Icons.emoji_events,
                      color: AppColors.primary,
                      size: responsive.iconSize(18),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _formatTrophies(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  Widget _buildStatCard(
    String label,
    String Function() value,
    Responsive responsive,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(10),
            ),
          ),
          SizedBox(height: responsive.spacing(5)),
          Obx(
            () => Text(
              value(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o card de missão diária
  Widget _buildDailyMission(BuildContext context) {
    final responsive = Responsive(context);
    final bottomNavHeight = responsive.buttonHeight(15);
    final actionButtonsHeight = responsive.buttonHeight(55);

    return Positioned(
      bottom: bottomNavHeight + actionButtonsHeight,
      left: responsive.width * 0.02,
      right: responsive.width * 0.02,
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(15)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(responsive.spacing(5)),
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: responsive.containerSize(60),
              height: responsive.containerSize(60),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
              ),
              child: Icon(
                Icons.forest,
                color: AppColors.white,
                size: responsive.iconSize(30),
              ),
            ),
            SizedBox(width: responsive.spacing(15)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Missão Diária',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(10)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(8),
                          vertical: responsive.spacing(4),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(12),
                          ),
                        ),
                        child: Text(
                          'XP x2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(5)),
                  Text(
                    'Capture 3 novos pontos no Ibirapuera.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: responsive.fontSize(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói os botões de ação
  Widget _buildActionButtons(BuildContext context, MapController controller) {
    final responsive = Responsive(context);
    final bottomNavHeight = responsive.buttonHeight(100);

    return Positioned(
      bottom: bottomNavHeight,
      left: responsive.width * 0.02,
      right: responsive.width * 0.02,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () =>
                controller.isTracking.value ||
                    controller.isRunSummaryLoading.value ||
                    controller.isRunSummaryVisible.value
                ? Container(
                    width: responsive.containerSize(55),
                    height: responsive.buttonHeight(55),

                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  )
                : _buildActionButton(
                    icon: Icons.sports_martial_arts,
                    color: AppColors.elite,
                    onPressed: () {
                      Get.toNamed(AppRoutes.battles);
                    },
                    responsive: responsive,
                  ),
          ),

          Obx(
            () => _buildActionButton(
              icon: controller.isTracking.value ? Icons.stop : Icons.play_arrow,
              color: controller.isTracking.value
                  ? AppColors.territoryEnemy
                  : AppColors.primary,
              onPressed: () {
                if (controller.isTracking.value) {
                  controller.prepareRunStop();
                } else {
                  controller.startRun();
                }
              },
              responsive: responsive,
            ),
          ),

          _buildActionButton(
            icon: Icons.my_location,
            color: AppColors.surfaceDark,
            onPressed: () => controller.centerUser(),
            responsive: responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required Responsive responsive,
  }) {
    return Container(
      width: responsive.containerSize(55),
      height: responsive.buttonHeight(55),

      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: GestureDetector(
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: responsive.iconSize(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildRunSummaryOverlay(
    BuildContext context,
    MapController controller,
    Responsive responsive,
  ) {
    final startTime = controller.startTime.value;
    final endTime = controller.endTime.value;
    final mapImageFile = controller.getCapturedRunMapOnlyImagePath();

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(responsive.spacing(16)),
            child: Container(
              width: responsive.width * 0.9,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(responsive.spacing(16)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Padding(
                padding: EdgeInsets.all(responsive.spacing(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resumo da corrida',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: responsive.fontSize(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: controller.discardStoppedRun,
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    if (controller.isTerritoryPending.value) ...[
                      SizedBox(height: responsive.spacing(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(10),
                          vertical: responsive.spacing(6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(12),
                          ),
                          border: Border.all(color: AppColors.white),
                        ),
                        child: Text(
                          'Território detectado',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: responsive.spacing(12)),
                    _buildSummaryStats(controller, responsive),
                    SizedBox(height: responsive.spacing(12)),
                    _buildSummaryTimes(
                      controller,
                      startTime,
                      endTime,
                      responsive,
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(12),
                      ),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: mapImageFile != null && mapImageFile.existsSync()
                            ? Image.file(mapImageFile, fit: BoxFit.cover)
                            : Container(
                                color: Colors.black26,
                                child: Icon(
                                  Icons.map_outlined,
                                  color: Colors.white24,
                                  size: responsive.iconSize(48),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    TextField(
                      controller: controller.runCaptionController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Escreva uma legenda...',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: responsive.fontSize(12),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(12),
                          ),
                          borderSide: BorderSide(color: AppColors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(12),
                          ),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(12),
                          ),
                          borderSide: BorderSide(color: AppColors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    Obx(
                      () => GestureDetector(
                        onTap: controller.isSavingRun.value
                            ? null
                            : controller.saveStoppedRun,

                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.successGradient,
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ),
                          ),
                          width: double.infinity,
                          height: responsive.containerSize(55),
                          child: controller.isSavingRun.value
                              ? SizedBox(
                                  height: responsive.iconSize(18),
                                  width: responsive.iconSize(18),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'Salvar corrida',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: responsive.fontSize(18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(MapController controller, Responsive responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryStat(
          'Distância',
          controller.formatDistance(controller.currentDistance.value),
          responsive,
        ),
        _buildSummaryStat(
          'Ritmo',
          controller.formatPace(
            controller.currentDuration.value,
            controller.currentDistance.value,
          ),
          responsive,
        ),
        _buildSummaryStat(
          'Tempo',
          controller.formatDuration(controller.currentDuration.value),
          responsive,
        ),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value, Responsive responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: responsive.fontSize(12),
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTimes(
    MapController controller,
    DateTime? start,
    DateTime? end,
    Responsive responsive,
  ) {
    final isTerritory = controller.isTerritoryPending.value;
    if (isTerritory) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryStat('Início', _formatTime(start), responsive),
          _buildSummaryStat(
            'Área',
            controller.formatCurrentTerritoryAreaKm2(),
            responsive,
          ),
          _buildSummaryStat('Término', _formatTime(end), responsive),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryStat('Início', _formatTime(start), responsive),
        _buildSummaryStat('Término', _formatTime(end), responsive),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildRunSummaryLoading(Responsive responsive) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                SizedBox(height: responsive.spacing(12)),
                Text(
                  'Gerando resumo da corrida...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o botão de informação (I) customizado no canto inferior direito
  /// Totalmente responsivo para diferentes tamanhos de tela
  Widget _buildInfoButton(BuildContext context, Responsive responsive) {
    final bottomNavHeight = responsive.buttonHeight(160);
    return Positioned(
      bottom: bottomNavHeight + responsive.spacing(20),
      right: responsive.width * 0.04,
      child: Container(
        width: responsive.containerSize(45),
        height: responsive.containerSize(45),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.white.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(1, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              responsive.containerSize(45) / 2,
            ),
            onTap: () => _showAttributionBottomSheet(context, responsive),
            child: Center(
              child: Icon(
                Icons.info_outline,
                color: Colors.white,
                size: responsive.iconSize(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Exibe um BottomSheet com informações de atribuição do mapa
  /// Totalmente responsivo para diferentes tamanhos de tela
  /// Limitado a metade da altura da tela
  void _showAttributionBottomSheet(
    BuildContext context,
    Responsive responsive,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.75, // Limita a 3/4 da tela
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(responsive.spacing(20)),
                topRight: Radius.circular(responsive.spacing(20)),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle (barra para arrastar)
                  Container(
                    margin: EdgeInsets.only(top: responsive.spacing(12)),
                    width: responsive.width * 0.15,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Título
                  Padding(
                    padding: EdgeInsets.all(responsive.spacing(20)),
                    child: Row(
                      children: [
                        SizedBox(
                          width: responsive.containerSize(40),
                          height: responsive.containerSize(40),

                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.white,
                            size: responsive.iconSize(30),
                          ),
                        ),
                        SizedBox(width: responsive.spacing(15)),
                        Expanded(
                          child: Text(
                            'Sobre o Mapa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsive.fontSize(22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppColors.white,
                            size: responsive.iconSize(24),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Conteúdo do BottomSheet
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(20),
                        vertical: responsive.spacing(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Atribuições oficiais conforme documentação do Mapbox
                          _buildAttributionItem(
                            context,
                            responsive,
                            '© Intermap Technologies',
                            'https://www.intermap.com/',
                            Icons.satellite_outlined,
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          _buildAttributionItem(
                            context,
                            responsive,
                            '© Mapbox',
                            'https://www.mapbox.com/about/maps',
                            Icons.map_outlined,
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          _buildAttributionItem(
                            context,
                            responsive,
                            '© Maxar',
                            'https://www.maxar.com/',
                            Icons.terrain_outlined,
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          _buildAttributionItem(
                            context,
                            responsive,
                            '© OpenStreetMap',
                            'http://www.openstreetmap.org/copyright',
                            Icons.layers_outlined,
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          _buildAttributionItem(
                            context,
                            responsive,
                            '© EarthEnv',
                            'https://www.earthenv.org/',
                            Icons.public_outlined,
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          _buildAttributionItem(
                            context,
                            responsive,
                            '© ESA WorldCover project / Contains modified Copernicus Sentinel data (2020) processed by ESA WorldCover consortium',
                            'https://worldcover2021.esa.int/',
                            Icons.public_outlined,
                            wrapText: true,
                          ),
                          SizedBox(height: responsive.spacing(20)),
                          // Link para melhorar o mapa
                          _buildAttributionItem(
                            context,
                            responsive,
                            'Aprimorar este mapa',
                            'https://apps.mapbox.com/feedback/',
                            Icons.feedback_outlined,
                          ),
                          SizedBox(height: responsive.spacing(30)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Constrói um item de atribuição clicável com link
  Widget _buildAttributionItem(
    BuildContext context,
    Responsive responsive,
    String title,
    String url,
    IconData icon, {
    bool wrapText = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        onTap: () async {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                Get.snackbar(
                  'Erro',
                  'Não foi possível abrir o link: $url',
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              Get.snackbar(
                'Erro',
                'Erro ao abrir link: $e',
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              );
            }
            print('Erro ao abrir URL $url: $e');
          }
        },
        child: Container(
          padding: EdgeInsets.all(responsive.spacing(15)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: responsive.containerSize(40),
                height: responsive.containerSize(40),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(responsive.spacing(8)),
                ),
                child: Icon(
                  icon,
                  color: AppColors.iconActive,
                  size: responsive.iconSize(20),
                ),
              ),
              SizedBox(width: responsive.spacing(15)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    height: wrapText ? 1.4 : 1.2,
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(10)),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: responsive.iconSize(16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerritoryInfoCard(
    BuildContext context,
    MapController controller,
    Responsive responsive,
  ) {
    final territory = controller.selectedTerritory.value!;
    final userName =
        territory['userName'] as String? ??
        territory['owner'] as String? ??
        'Desconhecido';
    final username =
        territory['username'] as String? ?? territory['owner'] as String? ?? '';
    final photoUrl = territory['photoUrl'] as String?;
    final capturedAt = territory['capturedAt'] as String?;
    final areaM2 = territory['areaM2'] as double?;
    final color =
        territory['color'] as String? ??
        '#00E5FF'; // Padrão: Ciano (era roxo #7B2CBF)

    // Formata a data
    String formattedDate = 'Data desconhecida';
    if (capturedAt != null) {
      try {
        final date = DateTime.parse(capturedAt);
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        formattedDate = capturedAt;
      }
    }

    // Formata a área
    String formattedArea = 'Área desconhecida';
    if (areaM2 != null) {
      if (areaM2 >= 10000) {
        formattedArea = '${(areaM2 / 10000).toStringAsFixed(2)} hectares';
      } else {
        formattedArea = '${areaM2.toStringAsFixed(0)} m²';
      }
    }

    // URL completa da foto
    String? fullPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        fullPhotoUrl = photoUrl;
      } else {
        fullPhotoUrl = '${ApiConstants.baseUrl}$photoUrl';
      }
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + responsive.spacing(80),
      left: responsive.paddingHorizontal,
      right: responsive.paddingHorizontal,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.only(
            bottom: responsive.spacing(12),
          ), // Espaço para a ponta
          child: ClipPath(
            clipper: SpeechBubbleClipper(),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(15)),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                border: Border.all(
                  color: _hexToColor(color).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com foto e nome
                  Row(
                    children: [
                      // Foto de perfil
                      Container(
                        width: responsive.containerSize(60),
                        height: responsive.containerSize(60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _hexToColor(color),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: _hexToColor(color).withOpacity(0.2),
                          backgroundImage: fullPhotoUrl != null
                              ? NetworkImage(fullPhotoUrl)
                              : null,
                          child: fullPhotoUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: _hexToColor(color),
                                  size: responsive.iconSize(30),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(15)),
                      // Nome e username
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.fontSize(18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (username.isNotEmpty)
                              Text(
                                '@$username',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: responsive.fontSize(14),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Botão de fechar
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: responsive.iconSize(24),
                        ),
                        onPressed: () =>
                            controller.selectedTerritory.value = null,
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(15)),
                  // Informações do território
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          responsive,
                          Icons.calendar_today,
                          'Capturado em',
                          formattedDate,
                          _hexToColor(color),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(10)),
                      Expanded(
                        child: _buildInfoItem(
                          responsive,
                          Icons.area_chart,
                          'Área',
                          formattedArea,
                          _hexToColor(color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói um item de informação dentro do card
  Widget _buildInfoItem(
    Responsive responsive,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(10)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.spacing(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: responsive.iconSize(16)),
              SizedBox(width: responsive.spacing(5)),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: responsive.fontSize(12),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(5)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Converte string hexadecimal para Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff');
      }
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppColors.white;
    }
  }
}

/// Clipper customizado para criar o formato de balão de conversa com ponta
class SpeechBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(dynamic size) {
    // Se o erro persistir, tente trocar a linha acima por:
    // Path getClip(dynamic size) {
    // Mas o correto para a versão atual do Flutter é como está abaixo:
    // Certifique-se de que Size não tem '?' e Path também não
    final path = Path();
    final borderRadius = 12.0;
    //final arrowHeight = 1.0;
    //final arrowWidth = 20.0;
    final arrowPosition = size.width * 0.75; // Centralizado horizontalmente

    // Início: Canto superior esquerdo
    path.moveTo(borderRadius, 0);

    // Linha superior
    path.lineTo(size.width - borderRadius, 0);

    // Canto superior direito
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);

    // Lado direito até o início da curva inferior
    path.lineTo(size.width, size.height - borderRadius);

    // Canto inferior direito
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - borderRadius,
      size.height,
    );

    // Seta (Triângulo inferior)
    path.lineTo(arrowPosition, size.height);
    path.lineTo(arrowPosition, size.height);
    path.lineTo(arrowPosition, size.height);

    // Lado inferior esquerdo
    path.lineTo(borderRadius, size.height);

    // Canto inferior esquerdo
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);

    // Lado esquerdo voltando para o topo
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
