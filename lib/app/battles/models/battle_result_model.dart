/// Modelo de dados para o resultado de uma batalha
class BattleResultModel {
  final String battleId;
  final String? winnerId;
  final String? loserId;
  final double? p1Score;
  final double? p2Score;
  final int p1TrophyChange;
  final int p2TrophyChange;
  final int p1NewTrophies;
  final int p2NewTrophies;
  final String? p1NewLeague;
  final String? p2NewLeague;
  final bool invalidated;

  BattleResultModel({
    required this.battleId,
    this.winnerId,
    this.loserId,
    this.p1Score,
    this.p2Score,
    required this.p1TrophyChange,
    required this.p2TrophyChange,
    required this.p1NewTrophies,
    required this.p2NewTrophies,
    this.p1NewLeague,
    this.p2NewLeague,
    required this.invalidated,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'battleId': battleId,
      'winnerId': winnerId,
      'loserId': loserId,
      'p1Score': p1Score,
      'p2Score': p2Score,
      'p1TrophyChange': p1TrophyChange,
      'p2TrophyChange': p2TrophyChange,
      'p1NewTrophies': p1NewTrophies,
      'p2NewTrophies': p2NewTrophies,
      'p1NewLeague': p1NewLeague,
      'p2NewLeague': p2NewLeague,
      'invalidated': invalidated,
    };
  }

  /// Cria a partir de JSON
  factory BattleResultModel.fromJson(Map<String, dynamic> json) {
    return BattleResultModel(
      battleId: json['battleId'] as String,
      winnerId: json['winnerId'] as String?,
      loserId: json['loserId'] as String?,
      p1Score: json['p1Score'] != null
          ? (json['p1Score'] is int
              ? (json['p1Score'] as int).toDouble()
              : json['p1Score'] as double)
          : null,
      p2Score: json['p2Score'] != null
          ? (json['p2Score'] is int
              ? (json['p2Score'] as int).toDouble()
              : json['p2Score'] as double)
          : null,
      p1TrophyChange: json['p1TrophyChange'] is int
          ? json['p1TrophyChange'] as int
          : (json['p1TrophyChange'] as double).round(),
      p2TrophyChange: json['p2TrophyChange'] is int
          ? json['p2TrophyChange'] as int
          : (json['p2TrophyChange'] as double).round(),
      p1NewTrophies: json['p1NewTrophies'] is int
          ? json['p1NewTrophies'] as int
          : (json['p1NewTrophies'] as double).round(),
      p2NewTrophies: json['p2NewTrophies'] is int
          ? json['p2NewTrophies'] as int
          : (json['p2NewTrophies'] as double).round(),
      p1NewLeague: json['p1NewLeague'] as String?,
      p2NewLeague: json['p2NewLeague'] as String?,
      invalidated: json['invalidated'] as bool? ?? false,
    );
  }
}
