import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:domrun/app/navigation/widgets/bottom_navigation_bar.dart';
import 'package:domrun/app/ranking/controller/ranking_controller.dart';
import 'package:domrun/app/ranking/models/trophy_ranking_entry.dart';
import 'package:domrun/core/theme/app_colors.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RankingController>();

    // Atualiza o índice da navegação para Mapa (1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navController = Get.find<NavigationController>();
      if (navController.currentIndex.value != 2) {
        navController.currentIndex.value = 2;
      }
      // Evita excluir o LoginController aqui para não
      // destruir TextEditingControllers ainda referenciados.
    });

    return Scaffold(
      bottomNavigationBar: BottomNavigationBarWidget(),
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ranking'),
        centerTitle: true,
      ),
      body: _RankingBody(controller: c),
    );
  }
}

/* -------------------- Widgets -------------------- */

class _RankingBody extends StatelessWidget {
  final RankingController controller;
  const _RankingBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
        ),
        Obx(
          () => (!controller.isLoading.value && controller.error.value != null)
              ? _ErrorState(
                  message: controller.error.value!,
                  onRetry: () => controller.load(),
                )
              : const SizedBox.shrink(),
        ),
        Obx(() {
          if (controller.isLoading.value || controller.error.value != null) {
            return const SizedBox.shrink();
          }

          if (controller.users.isEmpty) {
            return _EmptyState(onReload: () => controller.load());
          }

          final users = controller.users;
          final TrophyRankingEntry? first = users.isNotEmpty ? users[0] : null;
          final TrophyRankingEntry? second = users.length > 1 ? users[1] : null;
          final TrophyRankingEntry? third = users.length > 2 ? users[2] : null;

          final List<TrophyRankingEntry> rest = users.length > 3
              ? users.sublist(3)
              : const [];

          return RefreshIndicator(
            onRefresh: () => controller.load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Top3Podium(first: first, second: second, third: third),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'Top jogadores por troféus'),
                const SizedBox(height: 12),
                ...rest.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RankingRow(entry: entry),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Top3Podium extends StatelessWidget {
  final TrophyRankingEntry? first;
  final TrophyRankingEntry? second;
  final TrophyRankingEntry? third;

  const _Top3Podium({this.first, this.second, this.third});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOP 3',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _PodiumCard(place: 2, entry: second)),
              const SizedBox(width: 10),
              Expanded(
                child: _PodiumCard(place: 1, entry: first, isChampion: true),
              ),
              const SizedBox(width: 10),
              Expanded(child: _PodiumCard(place: 3, entry: third)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int place;
  final TrophyRankingEntry? entry;
  final bool isChampion;

  const _PodiumCard({
    required this.place,
    required this.entry,
    this.isChampion = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isChampion
        ? const Color(0xFFFFD700).withOpacity(.7)
        : Colors.white.withOpacity(.08);

    final badgeColor = isChampion
        ? const Color(0xFFFFD700)
        : const Color(0xFF0083FF);

    final displayName = (entry?.name?.trim().isNotEmpty ?? false)
        ? entry!.name!.trim()
        : (entry?.username ?? '--');

    final username = entry?.username ?? '--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: place == 1
            ? AppColors.firstPlaceGradient
            : place == 2
            ? AppColors.secondPlaceGradient
            : AppColors.thirdPlaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.white),
            ),
            child: Text(
              '#$place',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Avatar(
            photoUrl: entry?.photoUrl,
            nameOrUsername: displayName,
            radius: isChampion ? 22 : 18,
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12),
          ),
          const SizedBox(height: 10),
          _TrophyLine(trophies: entry?.trophies ?? 0),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final TrophyRankingEntry entry;

  const _RankingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final displayName = (entry.name?.trim().isNotEmpty ?? false)
        ? entry.name!.trim()
        : entry.username;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.position > 0 ? entry.position : '-'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _Avatar(
            photoUrl: entry.photoUrl,
            nameOrUsername: displayName,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${entry.username} • ${entry.league.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _TrophyLine(trophies: entry.trophies),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String nameOrUsername;
  final double radius;

  const _Avatar({
    required this.photoUrl,
    required this.nameOrUsername,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(nameOrUsername);

    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withOpacity(.08),
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, __) {},
        child: const SizedBox.shrink(),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.white,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.surfaceDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _initials(String v) {
    final text = v.trim();
    if (text.isEmpty) return '?';
    final parts = text
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _TrophyLine extends StatelessWidget {
  final int trophies;
  const _TrophyLine({required this.trophies});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.emoji_events, size: 18, color: Color(0xFFFFD700)),
        const SizedBox(width: 6),
        Text(
          '$trophies',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            fontFamily: 'RobotoMono',
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onReload;
  const _EmptyState({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard,
              size: 48,
              color: Colors.white.withOpacity(.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sem dados no ranking ainda',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quando houver corridas e troféus, o ranking aparece aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(.65)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onReload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0083FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Recarregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(.7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
