import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/auth/models/user_model.dart';
import 'package:domrun/app/auth/service/auth_service.dart';
import 'package:domrun/app/maps/models/run_model.dart';
import 'package:domrun/app/navigation/widgets/bottom_navigation_bar.dart';
import 'package:domrun/app/profile/controller/profile_controller.dart';
import 'package:domrun/app/profile/models/run_post_model.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';
import 'package:domrun/routes/app_routes.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      bottomNavigationBar: const BottomNavigationBarWidget(),
      body: _ProfileBody(
        controller: controller,
        responsive: responsive,
      ),
    );
  }
}

/// =======================
/// WIDGETS
/// =======================

class _ProfileBody extends StatelessWidget {
  final ProfileController controller;
  final Responsive responsive;

  const _ProfileBody({
    required this.controller,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
        ),
        Obx(() {
          final error = controller.error.value;
          return (!controller.isLoading.value &&
                  error != null &&
                  error.isNotEmpty)
              ? _ErrorState(message: error, onRetry: controller.refresh)
              : const SizedBox.shrink();
        }),
        Obx(() {
          if (controller.isLoading.value) return const SizedBox.shrink();
          final error = controller.error.value;
          if (error != null && error.isNotEmpty) {
            return const SizedBox.shrink();
          }
          final user = controller.user.value;
          if (user == null) {
            return _ErrorState(
              message: 'Perfil indisponível no momento.',
              onRetry: controller.refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(context, user)),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _StatsRow(
                    user: user,
                    runCount: controller.runs.length,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                SliverToBoxAdapter(child: _BioCard(user: user)),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Corridas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 8)),
                controller.runs.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: _EmptyRuns(),
                        ),
                      )
                    : SliverList.separated(
                        itemCount: controller.runs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RunTile(
                          run: controller.runs[i],
                          resp: responsive,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

Widget _Header(BuildContext context, UserModel user) {
  final theme = Theme.of(context);
  final responsive = Responsive(context);

  return Container(
    padding: EdgeInsets.only(
      top: responsive.spacing(25),
      bottom: responsive.spacing(30),
      left: responsive.paddingHorizontal,
      right: responsive.paddingHorizontal,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          user.colorAsColor.withOpacity(0.35),
          user.colorAsColor.withOpacity(0.05),
        ],
      ),
    ),
    child: Column(
      children: [
        _buildHeader(context, responsive),
        SizedBox(height: responsive.spacing(10)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(context, user, responsive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? user.username,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label: 'Liga: ${user.league.displayName}',
                        icon: Icons.emoji_events,
                      ),
                      _Pill(
                        label: 'Level ${user.level}',
                        icon: Icons.trending_up,
                      ),
                      _Pill(
                        label: 'Win streak: ${user.winStreak}',
                        icon: Icons.local_fire_department,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildAvatar(
  BuildContext context,
  UserModel user,
  Responsive responsive,
) {
  final border = user.colorAsColor.withOpacity(0.7);

  return Stack(
    children: [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 2),
        ),
        child: ClipOval(
          child: user.photoUrl == null || user.photoUrl!.isEmpty
              ? Container(
                  color: user.colorAsColor.withOpacity(0.25),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              : Image.network(
                  user.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: user.colorAsColor.withOpacity(0.25),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: GestureDetector(
          onTap: () {
            // Navega para a tela de edição de perfil
            Get.toNamed(AppRoutes.editNewProfile);
          },
          child: Container(
            width: responsive.containerSize(30),
            height: responsive.containerSize(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  user.colorAsColor.withOpacity(0.35),
                  user.colorAsColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: Icon(
              Icons.edit,
              size: responsive.iconSize(16),
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, required this.runCount});

  final UserModel user;
  final int runCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Troféus',
              value: _formatInt(user.trophies ?? 0),
              icon: Icons.emoji_events_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              title: 'Corridas',
              value: _formatInt(runCount),
              icon: Icons.directions_run,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              title: 'Territórios',
              value: _formatInt(user.territories.length),
              icon: Icons.map_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bio', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              (user.biography == null || user.biography!.trim().isEmpty)
                  ? 'Sem biografia'
                  : user.biography!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Constrói o header com título e ícone de configurações
Widget _buildHeader(BuildContext context, Responsive responsive) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Meu Perfil',
        style: TextStyle(
          color: AppColors.white,
          fontSize: responsive.fontSize(15),
          fontWeight: FontWeight.bold,
        ),
      ),
      IconButton(
        icon: Icon(
          Icons.settings,
          color: AppColors.white,
          size: responsive.iconSize(24),
        ),
        onPressed: () {
          _showLogoutDialog(context, responsive);
        },
      ),
    ],
  );
}

/// Mostra diálogo de confirmação para logout
void _showLogoutDialog(BuildContext context, Responsive responsive) {
  final authService = Get.find<AuthService>();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Sair da Conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: responsive.fontSize(16),
          ),
        ),
        actions: [
          // Botão Cancelar
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ),
          // Botão Sair
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performLogout(authService);
            },
            child: Text(
              'Sair',
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Realiza o logout do usuário
Future<void> _performLogout(AuthService authService) async {
  try {
    // Mostra indicador de carregamento
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.surfaceDark),
        ),
      ),
      barrierDismissible: false,
    );

    // Realiza o logout
    await authService.logout();

    // Fecha o diálogo de carregamento
    Get.back();

    // Mostra mensagem de sucesso
    Get.snackbar(
      'Logout realizado',
      'Você saiu da sua conta com sucesso',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // Navega para a tela de login
    Get.offAllNamed(AppRoutes.login);
  } catch (e) {
    // Fecha o diálogo de carregamento se ainda estiver aberto
    try {
      Get.back();
    } catch (_) {
      // Ignora se não houver diálogo aberto
    }

    // Mostra mensagem de erro
    Get.snackbar(
      'Erro',
      'Erro ao fazer logout: ${e.toString()}',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({required this.run, required this.resp});

  final RunPostModel run;
  final Responsive resp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _showRunImageDialog(context, run),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      run.caption?.isNotEmpty == true
                          ? run.caption!
                          : 'Corrida',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(run.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                    label: '${run.distanceKm.toStringAsFixed(2)} km',
                    icon: Icons.straighten,
                  ),
                  _MetricChip(
                    label: run.durationLabel,
                    icon: Icons.timer_outlined,
                  ),
                  _MetricChip(label: run.paceLabel, icon: Icons.speed),
                  _MetricChip(
                    label: '${run.calories} kcal',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  _MetricChip(
                    label: '${run.pathPoints.length} pts',
                    icon: Icons.gps_fixed,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showRunImageDialog(context, run),
                child: Container(
                  width: double.infinity,
                  height: resp.height * 0.05,
                  decoration: BoxDecoration(
                    color: AppColors.promotionZone,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Gerar imagem',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: resp.fontSize(15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyRuns extends StatelessWidget {
  const _EmptyRuns();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_run),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhuma corrida registrada ainda.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(
              'Falha ao carregar perfil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// HELPERS
/// =======================
String _formatInt(int value) {
  // 2324 -> "2.324" pt-BR
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buffer.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

String _formatDateTime(DateTime dt) {
  // dd/MM HH:mm (simples)
  final d = dt.toLocal();
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm $hh:$mi';
}

String _formatDuration(int totalSec) {
  if (totalSec <= 0) return '--';
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

String _formatPace(double distanceKm, int durationSec) {
  if (distanceKm <= 0 || durationSec <= 0) return '--';
  final secPerKm = durationSec / distanceKm;
  final m = (secPerKm ~/ 60).toInt();
  final s = (secPerKm % 60).round().toInt().clamp(0, 59);
  return '${m}:${s.toString().padLeft(2, '0')} /km';
}

extension RunPostModelUi on RunPostModel {
  double get distanceKm => distance / 1000.0;

  int get durationSec => duration;

  String get durationLabel => _formatDuration(durationSec);

  String get paceLabel => _formatPace(distanceKm, durationSec);

  int get calories => 0;

  List<PositionPoint> get pathPoints => path;
}

void _showRunImageDialog(BuildContext context, RunPostModel run) {
  final controller = Get.find<ProfileController>();
  controller.resetRunImageState();
  if (run.path.isNotEmpty) {
    controller.generateRunImage(run);
  }

  Get.dialog(
    Obx(() {
      final isLoading = controller.isRunImageLoading.value;
      final imageBytes = controller.runImageBytes.value;
      final errorMessage = controller.runImageError.value;

      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Imagem do trajeto'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              if (isLoading) ...[
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
              ],
              if (errorMessage != null) ...[
                Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (imageBytes == null && !isLoading && errorMessage == null)
                Text(
                  run.path.isEmpty
                      ? 'Essa corrida não possui pontos de trajeto.'
                      : 'Gerar imagem do trajeto desta corrida.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
          if (imageBytes == null && !isLoading)
            TextButton(
              onPressed:
                  run.path.isEmpty ? null : () => controller.generateRunImage(run),
              child: const Text('Gerar novamente'),
            ),
          if (imageBytes != null)
            TextButton(
              onPressed:
                  isLoading ? null : () => controller.saveRunImageAndNotify(),
              child: const Text('Salvar na galeria'),
            ),
        ],
      );
    }),
  );
}
