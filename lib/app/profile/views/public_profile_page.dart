import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/profile/controller/public_profile_controller.dart';
import 'package:domrun/app/achievement/local/data/achievements_data.dart';
import 'package:domrun/app/achievement/local/models/achievement_definition.dart';
import 'package:domrun/app/achievement/local/models/achievement_model.dart';
import 'package:domrun/app/profile/models/public_user_profile.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';

/// Tela de perfil público (visualização via ranking)
class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  int _selectedTab = 1; // 1: Conquistas, 2: Corridas, 3: Territórios
  Map<String, List<AchievementDefinition>> _definitionsByCategory = {};
  bool _isDefinitionsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievementDefinitions();
  }

  Future<void> _loadAchievementDefinitions() async {
    final definitions = await AchievementsData.getAchievementsByCategory();
    if (!mounted) {
      return;
    }
    setState(() {
      _definitionsByCategory = definitions;
      _isDefinitionsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final controller = Get.find<PublicProfileController>();

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: _buildBody(controller, responsive),
    );
  }

  Widget _buildBody(
    PublicProfileController controller,
    Responsive responsive,
  ) {
    return Stack(
      children: [
        Obx(
          () => controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Obx(
          () => (!controller.isLoading.value &&
                  controller.error.value != null)
              ? Center(
                  child: Text(
                    'Erro ao carregar perfil',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: responsive.fontSize(16),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Obx(() {
          if (controller.isLoading.value || controller.error.value != null) {
            return const SizedBox.shrink();
          }

          final user = controller.user.value;
          if (user == null) {
            return const SizedBox.shrink();
          }

          final userColor = _hexToColor(user.color);
          final totalDistanceKm =
              user.runs.fold<double>(0, (sum, run) => sum + run.distance) /
                  1000;
          final territoryAreaKm2 = (user.totalTerritoryAreaM2 ?? 0) / 1000000;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, responsive),
                _buildProfileSection(user, responsive, userColor),
                _buildStatsSection(
                  responsive,
                  totalDistanceKm,
                  territoryAreaKm2,
                  user.trophies,
                ),
                _buildTabsSection(responsive),
                _buildTabContent(user, responsive),
                SizedBox(height: responsive.hp(60)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Responsive responsive) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + responsive.spacing(10),
        left: responsive.paddingHorizontal,
        right: responsive.paddingHorizontal,
        bottom: responsive.spacing(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Perfil do Jogador',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: responsive.iconSize(20),
            ),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    PublicUserProfile user,
    Responsive responsive,
    Color userColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.paddingHorizontal),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: responsive.containerSize(100),
                height: responsive.containerSize(100),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: userColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: userColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: responsive.containerSize(50),
                  backgroundColor: AppColors.white.withOpacity(0.3),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: responsive.iconSize(50),
                          color: userColor,
                        )
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(width: responsive.spacing(15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name ?? user.username,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: responsive.fontSize(22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (user.level != null || user.xpInfo != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(12),
                          vertical: responsive.spacing(6),
                        ),
                        decoration: BoxDecoration(
                          color: userColor,
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(20),
                          ),
                        ),
                        child: Text(
                          'Lvl ${user.level ?? user.xpInfo?.level ?? 0}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: responsive.fontSize(14),
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                if (user.biography != null && user.biography!.isNotEmpty)
                  Text(
                    user.biography!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: responsive.fontSize(14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    Responsive responsive,
    double totalDistanceKm,
    double territoryAreaKm2,
    int trophies,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.paddingHorizontal,
        vertical: responsive.spacing(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: '${totalDistanceKm.toInt()}km',
              label: 'PERCORRIDO',
              color: Colors.blue,
              responsive: responsive,
            ),
          ),
          SizedBox(width: responsive.spacing(10)),
          Expanded(
            child: _buildStatCard(
              value: '${territoryAreaKm2.toStringAsFixed(2)}km²',
              label: 'CONQUISTADO',
              color: AppColors.white,
              responsive: responsive,
            ),
          ),
          SizedBox(width: responsive.spacing(10)),
          Expanded(
            child: _buildStatCard(
              value: '$trophies',
              label: 'TROFÉUS',
              color: Colors.yellow,
              responsive: responsive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required Responsive responsive,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(15)),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: AppColors.loginInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: responsive.fontSize(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.spacing(5)),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: responsive.fontSize(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.paddingHorizontal),
      child: Row(
        children: [
          _buildTab('Conquistas', 1, responsive),
          SizedBox(width: responsive.spacing(15)),
          _buildTab('Corridas', 2, responsive),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, Responsive responsive) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
          decoration: BoxDecoration(
            border: Border(
              bottom: isActive
                  ? BorderSide(color: AppColors.white, width: 2)
                  : BorderSide(color: Colors.transparent, width: 2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(14),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(PublicUserProfile user, Responsive responsive) {
    if (_selectedTab == 2) {
      return _buildRunsTab(user, responsive);
    }
    return _buildAchievementsTab(user, responsive);
  }

  Widget _buildRunsTab(PublicUserProfile user, Responsive responsive) {
    if (user.runs.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Center(
          child: Text(
            'Nenhuma corrida encontrada',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: responsive.fontSize(14),
            ),
          ),
        ),
      );
    }

    final cardWidth = responsive.widthWithoutPadding;
    final cardHeight = responsive.hp(250);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.paddingHorizontal,
          ),
          child: SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: user.runs.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: responsive.spacing(12)),
              itemBuilder: (context, index) {
                final run = user.runs[index];
                return SizedBox(
                  width: cardWidth,
                  child: _buildListCard(
                    run: run,
                    territory: null,
                    responsive: responsive,
                    strokeColorHex: user.color,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.paddingHorizontal,
          ),
          child: Text(
            'Territórios',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        _buildTerritoriesGrid(user, responsive),
      ],
    );
  }

  Widget _buildTerritoriesGrid(PublicUserProfile user, Responsive responsive) {
    if (user.territories.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Center(
          child: Text(
            'Nenhum território encontrado',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: responsive.fontSize(14),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.paddingHorizontal),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: responsive.spacing(10),
          mainAxisSpacing: responsive.spacing(10),
          childAspectRatio: 3 / 4,
        ),
        itemCount: user.territories.length,
        itemBuilder: (context, index) {
          final territory = user.territories[index];
          return _buildListCard(
            run: null,
            territory: territory,
            responsive: responsive,
            strokeColorHex: user.color,
          );
        },
      ),
    );
  }

  Widget _buildAchievementsTab(PublicUserProfile user, Responsive responsive) {
    if (_isDefinitionsLoading) {
      return Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        ),
      );
    }

    if (_definitionsByCategory.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Center(
          child: Text(
            'Nenhuma conquista disponível',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: responsive.fontSize(14),
            ),
          ),
        ),
      );
    }

    final achievementsByCategory = _buildAchievementsByCategory(user);
    return _buildAchievementsList(achievementsByCategory, responsive);
  }

  String _formatDistance(double meters) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
  }

  Map<String, List<AchievementModel>> _buildAchievementsByCategory(
    PublicUserProfile user,
  ) {
    final completedIds = user.achievements
        .map((achievement) => achievement.achievementId)
        .toSet();
    final progressMap = <String, double>{};
    for (final progress in user.achievementProgress) {
      progressMap[progress.achievementId] = progress.progress;
    }

    final Map<String, List<AchievementModel>> grouped = {};
    _definitionsByCategory.forEach((category, definitions) {
      final items = definitions.map((def) {
        final isCompleted = completedIds.contains(def.id);
        final progressValue = (progressMap[def.id] ?? 0.0).clamp(0.0, 1.0);

        AchievementStatus status;
        double? progress;
        String? progressText;

        if (isCompleted) {
          status = AchievementStatus.completed;
        } else if (progressValue > 0) {
          status = AchievementStatus.inProgress;
          progress = progressValue;
          progressText = '${(progressValue * 100).toInt()}%';
        } else {
          status = AchievementStatus.locked;
          progress = 0.0;
          progressText = '0%';
        }

        return AchievementModel(
          id: def.id,
          title: def.name,
          description: def.description,
          medal: def.medal,
          icon: _getAchievementImage(def.medal, status),
          status: status,
          progress: status == AchievementStatus.completed ? null : progress,
          progressText: status == AchievementStatus.completed
              ? null
              : progressText,
        );
      }).toList();

      grouped[category] = items;
    });

    return grouped;
  }

  Widget _buildAchievementsList(
    Map<String, List<AchievementModel>> achievementsByCategory,
    Responsive responsive,
  ) {
    if (achievementsByCategory.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Center(
          child: Text(
            'Nenhuma conquista disponível',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: responsive.fontSize(14),
            ),
          ),
        ),
      );
    }

    final List<Widget> widgets = [];
    final categories = achievementsByCategory.keys.toList();

    for (int i = 0; i < categories.length; i++) {
      final categoryName = categories[i];
      final categoryAchievements = achievementsByCategory[categoryName] ?? [];

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: i > 0 ? responsive.spacing(30) : responsive.spacing(20),
            bottom: responsive.spacing(15),
            left: responsive.paddingHorizontal,
            right: responsive.paddingHorizontal,
          ),
          child: Text(
            categoryName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(20),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.paddingHorizontal,
          ),
          child: Column(
            children: categoryAchievements.map((achievement) {
              return Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(15)),
                child: _buildAchievementCard(achievement, responsive),
              );
            }).toList(),
          ),
        ),
      );

      if (i < categories.length - 1) {
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.paddingHorizontal,
              vertical: responsive.spacing(20),
            ),
            child: Divider(color: Colors.black12, thickness: 1),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildAchievementCard(
    AchievementModel achievement,
    Responsive responsive,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(15)),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: AppColors.loginInputBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: responsive.containerSize(60),
            height: responsive.containerSize(60),
            child: Image.asset(
              achievement.icon ?? 'assets/medal/default.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: responsive.iconSize(24),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: responsive.spacing(15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: responsive.spacing(5)),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: responsive.fontSize(12),
                  ),
                ),
                if (achievement.status != AchievementStatus.completed &&
                    achievement.progress != null) ...[
                  SizedBox(height: responsive.spacing(8)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.status == AchievementStatus.locked
                              ? Colors.grey.withOpacity(0.5)
                              : AppColors.white,
                        ),
                      ),
                      if (achievement.progressText != null) ...[
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          achievement.progressText!,
                          style: TextStyle(
                            color:
                                achievement.status == AchievementStatus.locked
                                ? Colors.grey
                                : AppColors.white,
                            fontSize: responsive.fontSize(11),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: responsive.spacing(10)),
          _buildAchievementStatus(achievement, responsive),
        ],
      ),
    );
  }

  Widget _buildAchievementStatus(
    AchievementModel achievement,
    Responsive responsive,
  ) {
    switch (achievement.status) {
      case AchievementStatus.completed:
        return Icon(
          Icons.check_circle,
          color: Colors.green,
          size: responsive.iconSize(28),
        );
      case AchievementStatus.inProgress:
        return Text(
          achievement.progressText ?? '0%',
          style: TextStyle(
            color: AppColors.white,
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.bold,
          ),
        );
      case AchievementStatus.locked:
        return Icon(
          Icons.lock,
          color: Colors.grey,
          size: responsive.iconSize(24),
        );
    }
  }

  Widget _buildListCard({
    required PublicRun? run,
    required PublicTerritory? territory,
    required Responsive responsive,
    String? strokeColorHex,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(15)),
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(2)),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: AppColors.loginInputBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.spacing(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('Distância'),
                    Text(
                      run != null
                          ? _formatDistance(run.distance)
                          : territory?.areaName ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Pace'),
                    Text(
                      run != null
                          ? run.averagePace > 0
                                ? '${run.averagePace.toStringAsFixed(2)} min/km'
                                : '-'
                          : territory?.areaName ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    Text('Duração'),
                    Text(
                      run != null
                          ? _formatDuration(run.duration)
                          : territory?.area.toString() ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(responsive.spacing(10)),

            child: Container(
              width: double.infinity,
              color: Colors.black12,
              child: Image.network(
                run != null
                    ? run.buildStaticMapUrl(
                            width: 800,
                            height: 600,
                            strokeColorHex: strokeColorHex,
                          ) ??
                          ''
                    : '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.withOpacity(0.3),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: responsive.iconSize(24),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

}

Color _hexToColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return AppColors.white;
  }

  final sanitized = hexColor.replaceAll('#', '');
  if (sanitized.length != 6) {
    return AppColors.white;
  }

  return Color(int.parse('FF$sanitized', radix: 16));
}

String _getAchievementImage(String medal, AchievementStatus status) {
  if (status != AchievementStatus.completed) {
    return 'assets/medal/default.png';
  }

  switch (medal.toLowerCase()) {
    case 'bronze':
      return 'assets/medal/bronze.png';
    case 'silver':
      return 'assets/medal/silver.png';
    case 'gold':
      return 'assets/medal/gold.png';
    case 'legendary':
    case 'lenda':
      return 'assets/medal/lenda.png';
    default:
      return 'assets/medal/default.png';
  }
}

