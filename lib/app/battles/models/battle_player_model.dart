/// Modelo de dados para um jogador em uma batalha
class BattlePlayer {
  final String id;
  final String username;
  final String? name;
  final String? color;
  final String? photoUrl;
  final int trophies;
  final String league;

  BattlePlayer({
    required this.id,
    required this.username,
    this.name,
    this.color,
    this.photoUrl,
    required this.trophies,
    required this.league,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'color': color,
      'photoUrl': photoUrl,
      'trophies': trophies,
      'league': league,
    };
  }

  /// Cria a partir de JSON
  factory BattlePlayer.fromJson(Map<String, dynamic> json) {
    return BattlePlayer(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String?,
      color: json['color'] as String?,
      photoUrl: json['photoUrl'] as String?,
      trophies: json['trophies'] != null
          ? (json['trophies'] is int
              ? json['trophies'] as int
              : (json['trophies'] as double).round())
          : 0,
      league: json['league'] as String? ?? 'Bronze III',
    );
  }
}
