import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:domrun/app/navigation/widgets/bottom_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<HomePage> {
  RankingScope _scope = RankingScope.world;

  // Simula o usuário logado
  final String currentUserId = 'u6';

  final List<RankUser> users = const [
    RankUser(id: 'u1', name: 'Bruno Rodrigues', level: 6, score: 3405),
    RankUser(id: 'u2', name: 'Cristina Ramos', level: 5, score: 3362),
    RankUser(id: 'u3', name: 'Rodrigo Lopes', level: 5, score: 3361),
    RankUser(id: 'u4', name: 'Thiago Barbosa', level: 5, score: 3347),
    RankUser(id: 'u5', name: 'Beatriz Carvalho', level: 5, score: 3281),
    RankUser(
      id: 'u6',
      name: 'Samuel Denis',
      level: 99,
      score: 3000,
      hasPhoto: true,
    ),
    RankUser(id: 'u7', name: 'Gabriel Rocha', level: 5, score: 2996),
  ];

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A1929);
    const surface = Color(0xFF0F2233);
    const surface2 = Color(0xFF132A3D);
    const cyan = Color(0xFF00E5FF);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      surface: surface,
    );

    // Atualiza o índice da navegação para Mapa (1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navController = Get.find<NavigationController>();
      if (navController.currentIndex.value != 0) {
        navController.currentIndex.value = 0;
      }
      // Evita excluir o LoginController aqui para não
      // destruir TextEditingControllers ainda referenciados.
    });

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: bg,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBarWidget(),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Ranking',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SegmentedScope(
                        value: _scope,
                        onChanged: (v) => setState(() => _scope = v),
                      ),
                      const SizedBox(height: 14),
                      // Linha de cabeçalho (ultra-clean)
                      const _ListHeader(),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final position = index + 1;
                    final isMe = user.id == currentUserId;

                    return _RankRow(
                      position: position,
                      user: user,
                      isMe: isMe,
                      bg: isMe ? surface2 : surface,
                      accent: cyan,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum RankingScope { world, city, friends }

class RankUser {
  final String id;
  final String name;
  final int level;
  final int score;
  final bool hasPhoto;

  const RankUser({
    required this.id,
    required this.name,
    required this.level,
    required this.score,
    this.hasPhoto = false,
  });
}

class _SegmentedScope extends StatelessWidget {
  const _SegmentedScope({required this.value, required this.onChanged});

  final RankingScope value;
  final ValueChanged<RankingScope> onChanged;

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00E5FF);
    final text = Theme.of(context).textTheme.bodyMedium;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0F2233),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _SegItem(
            label: 'Mundial',
            selected: value == RankingScope.world,
            onTap: () => onChanged(RankingScope.world),
            accent: cyan,
            textStyle: text,
          ),
          _SegItem(
            label: 'Cidade',
            selected: value == RankingScope.city,
            onTap: () => onChanged(RankingScope.city),
            accent: cyan,
            textStyle: text,
          ),
          _SegItem(
            label: 'Amigos',
            selected: value == RankingScope.friends,
            onTap: () => onChanged(RankingScope.friends),
            accent: cyan,
            textStyle: text,
          ),
        ],
      ),
    );
  }
}

class _SegItem extends StatelessWidget {
  const _SegItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.textStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: (textStyle ?? const TextStyle()).copyWith(
              color: selected ? Colors.white : Colors.white.withOpacity(0.65),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            '#',
            style: s?.copyWith(color: Colors.white.withOpacity(0.45)),
          ),
        ),
        Expanded(
          child: Text(
            'Atleta',
            style: s?.copyWith(color: Colors.white.withOpacity(0.45)),
          ),
        ),
        SizedBox(
          width: 64,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'LV',
              style: s?.copyWith(color: Colors.white.withOpacity(0.45)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'PTS',
              style: s?.copyWith(color: Colors.white.withOpacity(0.45)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.position,
    required this.user,
    required this.isMe,
    required this.bg,
    required this.accent,
  });

  final int position;
  final RankUser user;
  final bool isMe;
  final Color bg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final divider = Colors.white.withOpacity(0.06);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        children: [
          // Accent bar (Strava-level: sutil e funcional)
          Container(
            width: 3,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isMe ? accent : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Posição
          SizedBox(
            width: 34,
            child: Text(
              '$position',
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: position <= 3
                    ? Colors.white
                    : Colors.white.withOpacity(0.90),
              ),
            ),
          ),

          // Avatar pequeno (opcional)
          _Avatar(hasPhoto: user.hasPhoto, isMe: isMe),
          const SizedBox(width: 10),

          // Nome + label YOU
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'VOCÊ',
                          style: t.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: accent.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleFor(user),
                  style: t.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.60),
                  ),
                ),
              ],
            ),
          ),

          // LV (coluna)
          SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${user.level}',
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: user.level >= 50
                      ? accent.withOpacity(0.95)
                      : Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // PTS (coluna)
          SizedBox(
            width: 76,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${user.score}',
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  String _subtitleFor(RankUser u) {
    // Ultra-clean e alinhado com “território / mundo real”
    // Troque por: km, áreas conquistadas, streak etc.
    if (u.level >= 80) return 'Elite • Consistência alta';
    if (u.level >= 30) return 'Ativo • Boa progressão';
    return 'Atleta • Em evolução';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.hasPhoto, required this.isMe});

  final bool hasPhoto;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00E5FF);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: isMe ? cyan.withOpacity(0.55) : Colors.white.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.asset(
                'assets/avatar_me.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            )
          : Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.75)),
    );
  }
}
