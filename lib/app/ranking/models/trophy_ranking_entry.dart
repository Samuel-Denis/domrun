import 'package:nur_app/app/auth/models/legue_model.dart';
import 'package:nur_app/core/constants/api_constants.dart';

class TrophyRankingEntry {
  final int position;
  final String id;
  final String username;
  final String? name;
  final String? photoUrl;
  final String? color;
  final int trophies;
  final LeagueModel league;
  final int winStreak;
  final int? level;
  final int? losses;
  final int? wins;

  const TrophyRankingEntry({
    required this.position,
    required this.id,
    required this.username,
    this.name,
    this.photoUrl,
    this.color,
    required this.trophies,
    required this.league,
    required this.winStreak,
    this.level,
    this.losses,
    this.wins,
  });

  /// Helpers seguros
  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String? _toStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _normalizePhotoUrl(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;

    // Se já for absoluta, não prefixa baseUrl
    final lower = v.toLowerCase();
    final isAbsolute =
        lower.startsWith('http://') || lower.startsWith('https://');
    if (isAbsolute) return v;

    // Garante barra única (evita //)
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;

    final path = v.startsWith('/') ? v : '/$v';
    return '$base$path';
  }

  factory TrophyRankingEntry.fromJson(Map<String, dynamic> json) {
    final rawPhoto = _toStringOrNull(json['photoUrl']);

    return TrophyRankingEntry(
      position: _toInt(json['position']),
      id: _toStringOrNull(json['id']) ?? '',
      username: _toStringOrNull(json['username']) ?? '',
      name: _toStringOrNull(json['name']),
      photoUrl: _normalizePhotoUrl(rawPhoto),
      color: _toStringOrNull(json['color']),
      trophies: _toInt(json['trophies']),
      league: LeagueModel.fromMap(json['league'] as Map<String, dynamic>),
      winStreak: _toInt(json['winStreak']),
      level: json['level'] == null ? null : _toInt(json['level']),
      wins: json['wins'] == null ? null : _toInt(json['wins']),
      losses: json['losses'] == null ? null : _toInt(json['losses']),
    );
  }

  /// Opcional: útil pra recalcular posição no controller
  TrophyRankingEntry copyWith({int? position}) {
    return TrophyRankingEntry(
      position: position ?? this.position,
      id: id,
      username: username,
      name: name,
      photoUrl: photoUrl,
      color: color,
      trophies: trophies,
      league: league,
      winStreak: winStreak,
      level: level,
      wins: wins,
      losses: losses,
    );
  }
}
