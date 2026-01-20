/// Modelo de estatísticas do usuário
/// Representa as estatísticas exibidas na tela de perfil
class UserStatsModel {
  final double totalDistance; // Distância total percorrida em KM
  final double territoryPercentageKm2; // Área dominada em km²
  final double totalTerritoryAreaM2; // Área dominada em m²
  final int totalRuns;
  final int totalTerritories;
  final double averagePace;
  final int totalTime;
  final double longestRun;
  final int currentStreak;

  UserStatsModel({
    required this.totalDistance,
    required this.territoryPercentageKm2,
    required this.totalTerritoryAreaM2,
    required this.totalRuns,
    required this.totalTerritories,
    required this.averagePace,
    required this.totalTime,
    required this.longestRun,
    required this.currentStreak,
  });

  /// Cria um modelo a partir de JSON
  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      territoryPercentageKm2:
          (json['territoryPercentageKm2'] ?? 0.0).toDouble(),
      totalTerritoryAreaM2:
          (json['totalTerritoryAreaM2'] ?? 0.0).toDouble(),
      totalRuns: json['totalRuns'] ?? 0,
      totalTerritories: json['totalTerritories'] ?? 0,
      averagePace: (json['averagePace'] ?? 0.0).toDouble(),
      totalTime: json['totalTime'] ?? 0,
      longestRun: (json['longestRun'] ?? 0.0).toDouble(),
      currentStreak: json['currentStreak'] ?? 0,
    );
  }

  /// Converte o modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'territoryPercentageKm2': territoryPercentageKm2,
      'totalTerritoryAreaM2': totalTerritoryAreaM2,
      'totalRuns': totalRuns,
      'totalTerritories': totalTerritories,
      'averagePace': averagePace,
      'totalTime': totalTime,
      'longestRun': longestRun,
      'currentStreak': currentStreak,
    };
  }
}
