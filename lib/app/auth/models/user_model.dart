import 'package:domrun/app/auth/models/legue_model.dart';
import 'package:domrun/app/maps/models/run_model.dart';
import 'package:domrun/app/maps/models/territory_model.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:flutter/material.dart';

/// Modelo de dados do usuário
/// Representa as informações do usuário autenticado
class UserModel {
  final String id;
  final String email;
  final String username;
  final String? name;
  final String? photoUrl;
  final String? color; // Cor do usuário (hexadecimal)
  final String? biography; // Biografia do usuário
  final int? level; // Nível do usuário
  final DateTime createdAt;
  final LeagueModel league;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final int? trophies;
  final int? winStreak;
  final List<RunModel> runs;
  final List<TerritoryModel> territories;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.name,
    this.photoUrl,
    this.color,
    this.biography,
    this.level,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.trophies,
    required this.league,
    this.winStreak,
    required this.runs,
    required this.territories,
  });

  /// Converte o modelo para JSON (para salvar no storage ou enviar para API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'photoUrl': photoUrl,
      'color': color,
      'biography': biography,
      'level': level,
      'trophies': trophies,
      'league': {
        'id': league.id,
        'code': league.code,
        'displayName': league.displayName,
        'order': league.order,
        'isChampion': league.isChampion,
        'minTrophiesToEnter': league.minTrophiesToEnter,
        'paceTopSecKm': league.paceTopSecKm,
        'paceBaseSecKm': league.paceBaseSecKm,
        'smurfCapSecKm': league.smurfCapSecKm,
        'weeklyConsistencyMaxBonus': league.weeklyConsistencyMaxBonus,
        'shieldName': league.shieldName,
        'shieldAsset': league.shieldAsset,
        'rewardJson': league.rewardJson,
        'themeJson': league.themeJson,
        'createdAt': league.createdAt.toIso8601String(),
        'updatedAt': league.updatedAt.toIso8601String(),
      },
      'winStreak': winStreak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'runs': runs.map((r) => r.toJson()).toList(),
      'territories': territories.map((t) => t.toJson()).toList(),
    };
  }

  /// Converte o modelo para JSON de criação (sem campos gerados pelo servidor)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'email': email,
      'password': '', // Não incluir senha no JSON de resposta
      'username': username,
    };
  }

  /// Cria o modelo a partir de JSON retornado pela API
  /// Ignora campos extras como postLikes, userAchievements, runs, posts, territories
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Cria uma cópia do JSON removendo campos que não fazem parte do UserModel
    final userMap = Map<String, dynamic>.from(json);

    // Remove campos extras que podem vir na resposta do login
    userMap.remove('password');
    userMap.remove('postLikes');
    userMap.remove('userAchievements');
    // userMap.remove('runs');
    userMap.remove('posts');
    // userMap.remove('territories');

    return UserModel(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      username:
          userMap['username'] as String? ??
          (userMap['email'] as String).split(
            '@',
          )[0], // Fallback para email se não tiver username
      name: userMap['name'] as String?,
      photoUrl: userMap['photoUrl'] != null
          ? "${ApiConstants.baseUrl}${userMap['photoUrl']}" as String?
          : null,
      color: userMap['color'] as String?,
      biography: userMap['biography'] != null
          ? userMap['biography'] as String
          : null,
      level: userMap['level'] as int?,
      trophies: userMap['trophies'] as int?,
      league: LeagueModel.fromMap(userMap['league'] as Map<String, dynamic>),
      winStreak: userMap['winStreak'] as int?,
      createdAt: DateTime.parse(userMap['createdAt'] as String),
      // updatedAt pode não estar presente na resposta do login
      updatedAt: userMap['updatedAt'] != null
          ? DateTime.parse(userMap['updatedAt'] as String)
          : null,
      // lastLogin está presente na resposta do login
      lastLogin: userMap['lastLogin'] != null
          ? DateTime.parse(userMap['lastLogin'] as String)
          : null,
      runs: userMap['runs'] != null
          ? (userMap['runs'] as List)
                .map((r) => RunModel.fromJson(r as Map<String, dynamic>))
                .toList()
          : [],
      territories: userMap['territories'] != null
          ? (userMap['territories'] as List)
                .map((t) => TerritoryModel.fromJson(t as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  /// Cria uma cópia do modelo com campos atualizados
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? name,
    String? photoUrl,
    String? color,
    String? biography,
    int? level,
    int? trophies,
    LeagueModel? league,
    int? winStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    List<RunModel>? runs,
    List<TerritoryModel>? territories,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      color: color ?? this.color,
      biography: biography ?? this.biography,
      level: level ?? this.level,
      trophies: trophies ?? this.trophies,
      league: league ?? this.league,
      winStreak: winStreak ?? this.winStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      runs: runs ?? this.runs,
      territories: territories ?? this.territories,
    );
  }

  /// Mescla campos vindos de um JSON parcial
  /// Útil para atualizar apenas alguns itens do usuário
  UserModel copyWithJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json);
    data.remove('password');
    data.remove('postLikes');
    data.remove('userAchievements');
    data.remove('runs');
    data.remove('posts');
    data.remove('territories');

    return copyWith(
      id: data.containsKey('id') ? data['id'] as String : null,
      email: data.containsKey('email') ? data['email'] as String : null,
      username: data.containsKey('username')
          ? data['username'] as String
          : null,
      name: data.containsKey('name') ? data['name'] as String? : null,
      photoUrl: data.containsKey('photoUrl')
          ? _normalizePhotoUrl(data['photoUrl'] as String?)
          : null,
      color: data.containsKey('color') ? data['color'] as String? : null,
      biography: data.containsKey('biography')
          ? data['biography'] as String?
          : null,
      level: data.containsKey('level') ? data['level'] as int? : null,
      trophies: data.containsKey('trophies') ? data['trophies'] as int? : null,
      league: data['league'] is Map<String, dynamic>
          ? LeagueModel.fromMap(data['league'] as Map<String, dynamic>)
          : null,
      winStreak: data.containsKey('winStreak')
          ? data['winStreak'] as int?
          : null,
      createdAt: data.containsKey('createdAt')
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      updatedAt: data.containsKey('updatedAt') && data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      lastLogin: data.containsKey('lastLogin') && data['lastLogin'] != null
          ? DateTime.parse(data['lastLogin'] as String)
          : null,
      runs: data.containsKey('runs') ? data['runs'] as List<RunModel> : null,
      territories: data.containsKey('territories')
          ? data['territories'] as List<TerritoryModel>
          : null,
    );
  }

  String get initials {
    final base = (name == null || name!.trim().isEmpty) ? username : name!;
    final parts = base.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    final first = parts.first.isNotEmpty ? parts.first[0] : 'U';
    if (parts.length == 1) {
      return first.toUpperCase();
    }
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Color get colorAsColor => _parseHexColor(color) ?? const Color(0xFF00E5FF);

  static String? _normalizePhotoUrl(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '${ApiConstants.baseUrl}$value';
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.isEmpty) return null;

  value = value.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value'; // alpha
  if (value.length != 8) return null;

  final intColor = int.tryParse(value, radix: 16);
  if (intColor == null) return null;

  return Color(intColor);
}
