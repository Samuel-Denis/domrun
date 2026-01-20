import 'package:flutter/material.dart';

/// Cores globais da aplicação
/// Tema: Dark • Neon • Game/Fitness (baseado no code.html)
class AppColors {
  // =========================
  // 🎯 BRAND / IDENTIDADE
  // =========================

  // 🔹 Backgrounds
  static const Color background = Color(0xFF0A1929); // fundo principal
  static const Color surface = Color(0xFF0F2235); // cards
  static const Color surfaceDark = Color(0xFF08121D); // barras / nav

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.transparent, AppColors.background],
  );

  // 🔹 Primary (Ciano Neon)
  static const Color primary = Color(0xFF00E5FF);
  static const Color primarySoft = Color(0xFF4DEEFF);
  static const Color primaryDark = Color(0xFF00B8CC);

  // 🔹 Accent / Highlight
  static const Color accentBlue = Color(0xFF2EC5FF);
  static const Color accentPurple = Color(0xFF7B61FF);

  // 🔹 Status
  static const Color success = Color(0xFF2EFF7A);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF4D4D);

  // 🔹 Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9DB2C6);
  static const Color textMuted = Color(0xFF6B7C93);

  // 🔹 Borders & Dividers
  static const Color border = Color(0xFF1E3A52);

  // 🔹 Buttons
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = Color(0xFF132E45);

  // 🔹 League Colors
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gold = Color(0xFFFFD700);
  static const Color elite = Color(0xFFFFB703);

  /// Cor secundária (Blue)
  static const Color secondary = Color(0xFF3B82F6);

  /// Cor de destaque premium (Gold)
  static const Color accent = Color(0xFFFFD700);

  /// Cards secundários
  static const Color progressBarBackground = Color(0xFF1E293B);

  static const Color white = Color.fromARGB(255, 255, 255, 255);

  // =========================
  // 🚦 STATUS
  // =========================

  static const Color gradient1 = Color(0xFF1E3A8A);
  static const Color gradient2 = Color(0xFF00E0FF);

  // =========================
  // 🏃 CORRIDA / TRACKING
  // =========================

  static const Color trackingActive = Color(0xFF22C55E);
  static const Color trackingInactive = Color(0xFF6B7280);
  static const Color routeLine = Color(0xFF00E0FF);

  // =========================
  // 🗺️ MAPA / TERRITÓRIOS
  // =========================

  static const Color territoryOwned = Color(0xFF00E0FF);
  static const Color territoryEnemy = Color(0xFFEF4444);
  static const Color territoryNeutral = Color(0xFF475569);
  static const Color territoryDisputed = Color(0xFFD97706);

  static const Color locationMarker = Color(0xFF00E0FF);

  // =========================
  // 🏆 PvP / LIGAS
  // =========================

  static const Color leagueBronze = Color(0xFFCD7F32);
  static const Color leagueSilver = Color(0xFFC0C0C0);
  static const Color leagueGold = Color(0xFFFFD700);
  static const Color leagueElite = Color(0xFF00E0FF);

  static const Color promotionZone = Color(0xFF22C55E);
  static const Color neutralZone = Color(0xFF9CA3AF);
  static const Color relegationZone = Color(0xFFEF4444);

  // =========================
  // 🔐 LOGIN / AUTH
  // =========================

  static const Color loginInputBackground = surface;
  static const Color loginInputBorder = primary;

  // =========================
  // 🧩 ÍCONES
  // =========================

  static const Color iconActive = Color(0xFF00E0FF);
  static const Color iconInactive = Color(0xFF6B7280);

  // =========================
  // 🌈 GRADIENTES (code.html)
  // =========================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E0FF), Color(0xFF3B82F6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF00E0FF)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color.fromARGB(255, 165, 107, 71)],
    end: Alignment.bottomCenter,
    begin: Alignment.topCenter,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF050A14), Color(0xFF000000)],
  );

  static const LinearGradient firstPlaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD700), // Gold

      Color(0xFFFFA000), // Deep gold
      Color(0xFFFFD700), // Gold
    ],
  );

  static const LinearGradient secondPlaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFBDBDBD), // Dark silver
      Color(0xFFE0E0E0), // Silver
      Color(0xFFBDBDBD), // Dark silver
    ],
  );

  static const LinearGradient thirdPlaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFCD7F32), // Bronze
      Color(0xFF92400E), // Dark bronze
      Color(0xFFCD7F32), // Bronze
    ],
  );

  static const LinearGradient otherPlacesGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A2A2A), // Dark gray
      Color(0xFF2A2A2A), // Dark grayil
    ],
  );

  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceCard = Color(0xFF1E293B);
  static const Color surfaceGlass = Color(0x0DFFFFFF); // white 5%
  static const Color cardDark = Color(0xFF0F172A);

  // =========================
  // 🔒 CONSTRUTOR PRIVADO
  // =========================

  AppColors._();
}
