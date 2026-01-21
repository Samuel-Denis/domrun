import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/achievement/controller/achievement_controller.dart';
import 'package:domrun/app/navigation/widgets/bottom_navigation_bar.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';
import 'package:domrun/app/achievement/models/achievement_model.dart';

class AchievementsPage extends GetView<AchievementsController> {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      decoration: BoxDecoration(color: AppColors.surface),
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBarWidget(),
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(responsive),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.paddingHorizontal,
              ),
              child: Column(
                children: [
                  _header(responsive),
                  SizedBox(height: responsive.spacing(14)),
                  _searchAndFilters(responsive),
                  SizedBox(height: responsive.spacing(14)),
                  _categoryChips(responsive),
                  SizedBox(height: responsive.spacing(14)),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value != null) {
                  return _errorState(
                    responsive,
                    controller.errorMessage.value!,
                  );
                }

                final list = controller.filtered;
                if (list.isEmpty) {
                  return _emptyState(responsive);
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    responsive.paddingHorizontal,
                    0,
                    responsive.paddingHorizontal,
                    responsive.spacing(24),
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: responsive.spacing(12)),
                  itemBuilder: (_, i) => _achievementCard(responsive, list[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Responsive responsive) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: AppColors.white,
          size: responsive.iconSize(22),
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Conquistas',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: responsive.fontSize(20),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Obx(() {
          final unlockedOnly = controller.showOnlyUnlocked.value;
          return IconButton(
            tooltip: unlockedOnly
                ? 'Mostrando: desbloqueadas'
                : 'Mostrando: todas',
            icon: Icon(
              unlockedOnly ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: unlockedOnly ? AppColors.primary : AppColors.textPrimary,
            ),
            onPressed: controller.toggleUnlockedOnly,
          );
        }),
      ],
    );
  }

  Widget _header(Responsive responsive) {
    return Obx(() {
      final total = controller.achievements.length;
      final claimed = controller.achievements
          .where((a) => a.status == 'CLAIMED')
          .length;
      final unlocked = controller.achievements
          .where((a) => a.status == 'UNLOCKED')
          .length;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(responsive.spacing(14)),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.10),
              blurRadius: 18,
              spreadRadius: 1,
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
                gradient: (AppColors.successGradient),
              ),
              child: Icon(
                Icons.workspace_premium,
                color: AppColors.white,
                size: responsive.iconSize(22),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu progresso',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: responsive.fontSize(14),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    '$claimed/$total resgatadas • $unlocked disponíveis',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.65),
                      fontSize: responsive.fontSize(12),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(10),
                vertical: responsive.spacing(6),
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary.withOpacity(0.22)),
              ),
              child: Text(
                _progressPercent(claimed, total),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: responsive.fontSize(12),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _progressPercent(int claimed, int total) {
    if (total <= 0) return '0%';
    final pct = ((claimed / total) * 100).round();
    return '$pct%';
  }

  Widget _searchAndFilters(Responsive responsive) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: controller.setQuery,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              prefixIcon: const Icon(Icons.search, color: AppColors.white),
              hintText: 'Buscar conquistas...',
              hintStyle: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(14)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(width: responsive.spacing(10)),
        Obx(() {
          final unlockedOnly = controller.showOnlyUnlocked.value;
          return GestureDetector(
            onTap: controller.toggleUnlockedOnly,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(12),
                vertical: responsive.spacing(12),
              ),
              decoration: BoxDecoration(
                color: unlockedOnly
                    ? AppColors.primary.withOpacity(0.14)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(responsive.spacing(14)),
                border: Border.all(
                  color: unlockedOnly
                      ? AppColors.primary.withOpacity(0.45)
                      : AppColors.primary.withOpacity(0.18),
                ),
              ),
              child: Icon(
                unlockedOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: unlockedOnly ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _categoryChips(Responsive responsive) {
    final cats = const <String, String>{
      'ALL': 'Todas',
      'RUN': 'Corridas',
      'TERRITORY': 'Territórios',
      'SOCIAL': 'Social',
      'LEAGUE': 'Ligas',
      'EVENT': 'Eventos',
      'MILESTONE': 'Marcos',
    };

    return SizedBox(
      height: responsive.containerSize(40),
      child: Obx(() {
        final selected = controller.selectedCategory.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, __) => SizedBox(width: responsive.spacing(10)),
          itemBuilder: (_, i) {
            final key = cats.keys.elementAt(i);
            final label = cats[key]!;
            final isSelected = key == selected;

            return GestureDetector(
              onTap: () => controller.setCategory(key),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(14),
                  vertical: responsive.spacing(10),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.50)
                        : AppColors.primary.withOpacity(0.16),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: responsive.fontSize(12),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _achievementCard(Responsive responsive, AchievementModel a) {
    final rarity = _rarityConfig(a.rarity);
    final status = _statusConfig(a.status);

    final isLockedHidden = a.isHidden && a.status == 'LOCKED';
    if (isLockedHidden) return const SizedBox.shrink();

    final progress = a.progress.clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(responsive.spacing(14)),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(responsive.spacing(16)),
        border: Border.all(color: rarity.border.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: rarity.glow.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Opacity(
        opacity: (a.status == 'LOCKED') ? 0.75 : 1.0,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconBadge(responsive, a, rarity),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: responsive.fontSize(14),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(6)),
                      Text(
                        a.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.65),
                          fontSize: responsive.fontSize(12),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(10)),
                      Row(
                        children: [
                          _pill(
                            responsive,
                            rarity.label,
                            rarity.textColor,
                            rarity.bg,
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          _pill(
                            responsive,
                            status.label,
                            status.textColor,
                            status.bg,
                          ),
                          if (a.rewardXp > 0) ...[
                            SizedBox(width: responsive.spacing(8)),
                            _pill(
                              responsive,
                              '+${a.rewardXp} XP',
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (a.isClaimed)
                  Icon(
                    Icons.verified,
                    color: AppColors.primary,
                    size: responsive.iconSize(20),
                  ),
              ],
            ),

            SizedBox(height: responsive.spacing(12)),

            // Progress
            _progressBar(responsive, progress, a.progressText),

            SizedBox(height: responsive.spacing(12)),

            // Actions
            Row(
              children: [
                Expanded(child: _secondaryInfo(responsive, a)),
                SizedBox(width: responsive.spacing(10)),
                _actionButton(responsive, a),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBadge(
    Responsive responsive,
    AchievementModel a,
    _RarityCfg rarity,
  ) {
    return Container(
      width: responsive.containerSize(46),
      height: responsive.containerSize(46),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rarity.bg.withOpacity(0.25),
        border: Border.all(color: rarity.border.withOpacity(0.45)),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(a.category),
          color: rarity.textColor,
          size: responsive.iconSize(22),
        ),
      ),
    );
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'RUN':
        return Icons.directions_run;
      case 'TERRITORY':
        return Icons.public;
      case 'SOCIAL':
        return Icons.group;
      case 'LEAGUE':
        return Icons.emoji_events;
      case 'EVENT':
        return Icons.local_fire_department;
      case 'MILESTONE':
        return Icons.flag;
      default:
        return Icons.star;
    }
  }

  Widget _progressBar(
    Responsive responsive,
    double progress,
    String? progressText,
  ) {
    final text = progressText ?? '${(progress * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progresso',
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.70),
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              text,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: responsive.containerSize(8),
            backgroundColor: AppColors.loginInputBackground,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _secondaryInfo(Responsive responsive, AchievementModel a) {
    String line1 = _categoryLabel(a.category);
    String line2;

    if (a.status == 'CLAIMED') {
      line2 = 'Resgatada';
    } else if (a.status == 'UNLOCKED') {
      line2 = 'Disponível para resgate';
    } else if (a.status == 'IN_PROGRESS') {
      line2 = 'Continue assim';
    } else {
      line2 = 'Bloqueada';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line1,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: responsive.fontSize(12),
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          line2,
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.65),
            fontSize: responsive.fontSize(12),
          ),
        ),
      ],
    );
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'RUN':
        return 'Corridas';
      case 'TERRITORY':
        return 'Territórios';
      case 'SOCIAL':
        return 'Social';
      case 'LEAGUE':
        return 'Ligas';
      case 'EVENT':
        return 'Evento';
      case 'MILESTONE':
        return 'Marco';
      default:
        return c;
    }
  }

  Widget _actionButton(Responsive responsive, AchievementModel a) {
    final canClaim = a.isClaimable;

    return Obx(() {
      final claiming = controller.isClaiming[a.code] == true;

      if (a.isClaimed) {
        return _miniButton(
          responsive,
          label: 'OK',
          icon: Icons.check,
          enabled: false,
          onTap: () {},
        );
      }

      if (!canClaim) {
        return _miniButton(
          responsive,
          label: 'Ver',
          icon: Icons.info_outline,
          enabled: true,
          onTap: () => _openDetails(a),
        );
      }

      return _miniButton(
        responsive,
        label: claiming ? '...' : 'Resgatar',
        icon: claiming ? Icons.hourglass_top : Icons.redeem,
        enabled: !claiming,
        primary: true,
        onTap: () => controller.claimAchievement(a),
      );
    });
  }

  void _openDetails(AchievementModel a) {
    Get.bottomSheet(
      _AchievementDetailsSheet(achievement: a),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _miniButton(
    Responsive responsive, {
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final bg = primary
        ? AppColors.primary.withOpacity(0.16)
        : AppColors.loginInputBackground;
    final border = primary
        ? AppColors.primary.withOpacity(0.55)
        : AppColors.primary.withOpacity(0.18);
    final txt = primary ? AppColors.primary : AppColors.textPrimary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(12),
          vertical: responsive.spacing(10),
        ),
        decoration: BoxDecoration(
          color: enabled
              ? bg
              : AppColors.loginInputBackground.withOpacity(0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled ? txt : AppColors.textPrimary.withOpacity(0.35),
              size: responsive.iconSize(16),
            ),
            SizedBox(width: responsive.spacing(8)),
            Text(
              label,
              style: TextStyle(
                color: enabled ? txt : AppColors.textPrimary.withOpacity(0.35),
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(Responsive responsive, String text, Color fg, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(10),
        vertical: responsive.spacing(6),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: responsive.fontSize(11),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _errorState(Responsive responsive, String msg) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              color: AppColors.textPrimary.withOpacity(0.6),
              size: responsive.iconSize(40),
            ),
            SizedBox(height: responsive.spacing(12)),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: responsive.fontSize(14),
              ),
            ),
            SizedBox(height: responsive.spacing(14)),
            GestureDetector(
              onTap: controller.fetchAchievements,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(16),
                  vertical: responsive.spacing(12),
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Tentar novamente',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: responsive.fontSize(12),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(Responsive responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              color: AppColors.textPrimary.withOpacity(0.6),
              size: responsive.iconSize(44),
            ),
            SizedBox(height: responsive.spacing(12)),
            Text(
              'Nada por aqui ainda.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: responsive.fontSize(14),
              ),
            ),
            SizedBox(height: responsive.spacing(6)),
            Text(
              'Complete corridas, conquiste territórios e participe das ligas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.65),
                fontSize: responsive.fontSize(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _RarityCfg _rarityConfig(String r) {
    switch (r) {
      case 'LEGENDARY':
        return _RarityCfg(
          'LENDÁRIA',
          AppColors.primary,
          AppColors.primary,
          AppColors.primary,
        );
      case 'EPIC':
        return _RarityCfg(
          'ÉPICA',
          AppColors.primary,
          AppColors.primary,
          AppColors.primary,
        );
      case 'RARE':
        return _RarityCfg(
          'RARA',
          AppColors.white,
          AppColors.white,
          AppColors.white,
        );
      case 'COMMON':
      default:
        return _RarityCfg(
          'COMUM',
          AppColors.textPrimary,
          AppColors.textPrimary,
          AppColors.textPrimary,
        );
    }
  }

  _StatusCfg _statusConfig(String s) {
    switch (s) {
      case 'CLAIMED':
        return _StatusCfg(
          'RESGATADA',
          AppColors.primary,
          AppColors.primary.withOpacity(0.14),
        );
      case 'UNLOCKED':
        return _StatusCfg(
          'DESBLOQUEADA',
          AppColors.primary,
          AppColors.primary.withOpacity(0.14),
        );
      case 'IN_PROGRESS':
        return _StatusCfg(
          'EM PROGRESSO',
          AppColors.textPrimary,
          AppColors.loginInputBackground,
        );
      case 'LOCKED':
      default:
        return _StatusCfg(
          'BLOQUEADA',
          AppColors.textPrimary.withOpacity(0.85),
          AppColors.loginInputBackground,
        );
    }
  }
}

class _RarityCfg {
  final String label;
  final Color textColor;
  final Color border;
  final Color glow;
  final Color bg;

  _RarityCfg(this.label, this.textColor, this.border, this.glow)
    : bg = textColor.withOpacity(0.12);
}

class _StatusCfg {
  final String label;
  final Color textColor;
  final Color bg;

  _StatusCfg(this.label, this.textColor, this.bg);
}

class _AchievementDetailsSheet extends StatelessWidget {
  const _AchievementDetailsSheet({required this.achievement});

  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.only(
        left: responsive.paddingHorizontal,
        right: responsive.paddingHorizontal,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + responsive.spacing(16),
      ),
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(16)),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(responsive.spacing(18)),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsive.containerSize(44),
              height: responsive.containerSize(44),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.14),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Icon(Icons.workspace_premium, color: AppColors.primary),
            ),
            SizedBox(height: responsive.spacing(12)),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: responsive.fontSize(16),
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.65),
                fontSize: responsive.fontSize(12),
              ),
            ),
            SizedBox(height: responsive.spacing(14)),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(responsive.spacing(12)),
                    decoration: BoxDecoration(
                      color: AppColors.loginInputBackground,
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(14),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categoria',
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.65),
                            fontSize: responsive.fontSize(11),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(6)),
                        Text(
                          achievement.category,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(10)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(responsive.spacing(12)),
                    decoration: BoxDecoration(
                      color: AppColors.loginInputBackground,
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(14),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raridade',
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.65),
                            fontSize: responsive.fontSize(11),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(6)),
                        Text(
                          achievement.rarity,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(14)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.14),
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: responsive.fontSize(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
