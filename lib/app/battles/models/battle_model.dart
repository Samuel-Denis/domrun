import 'package:nur_app/app/battles/models/battle_player_model.dart';

/// Modelo de dados para uma batalha PVP
class BattleModel {
  final String id;
  final String player1Id;
  final String? player2Id;
  final BattleStatus status;
  final BattleMode mode;
  final String? modeValue; // Ex: "15" para 15 minutos ou "5" para 5km
  final BattlePlayer? player1;
  final BattlePlayer? player2;
  final double? p1Score;
  final double? p2Score;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? finishedAt;

  BattleModel({
    required this.id,
    required this.player1Id,
    this.player2Id,
    required this.status,
    required this.mode,
    this.modeValue,
    this.player1,
    this.player2,
    this.p1Score,
    this.p2Score,
    this.winnerId,
    required this.createdAt,
    this.finishedAt,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'status': status.name,
      'mode': mode.name,
      'modeValue': modeValue,
      'player1': player1?.toJson(),
      'player2': player2?.toJson(),
      'p1Score': p1Score,
      'p2Score': p2Score,
      'winnerId': winnerId,
      'createdAt': createdAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
    };
  }

  /// Cria a partir de JSON
  factory BattleModel.fromJson(Map<String, dynamic> json) {
    return BattleModel(
      id: json['id'] as String? ?? '',
      player1Id: json['player1Id'] as String? ?? '',
      player2Id: json['player2Id'] as String?,
      status: json['status'] != null
          ? BattleStatus.values.firstWhere(
              (e) => e.name == json['status'] as String,
              orElse: () => BattleStatus.SEARCHING,
            )
          : BattleStatus.SEARCHING,
      mode: json['mode'] != null
          ? BattleMode.values.firstWhere(
              (e) => e.name == json['mode'] as String,
              orElse: () => BattleMode.timed,
            )
          : BattleMode.timed,
      modeValue: json['modeValue'] as String?,
      player1: json['player1'] != null
          ? BattlePlayer.fromJson(json['player1'] as Map<String, dynamic>)
          : null,
      player2: json['player2'] != null
          ? BattlePlayer.fromJson(json['player2'] as Map<String, dynamic>)
          : null,
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
      winnerId: json['winnerId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
    );
  }

  /// Cria uma cópia com campos atualizados
  BattleModel copyWith({
    String? id,
    String? player1Id,
    String? player2Id,
    BattleStatus? status,
    BattleMode? mode,
    String? modeValue,
    BattlePlayer? player1,
    BattlePlayer? player2,
    double? p1Score,
    double? p2Score,
    String? winnerId,
    DateTime? createdAt,
    DateTime? finishedAt,
  }) {
    return BattleModel(
      id: id ?? this.id,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      modeValue: modeValue ?? this.modeValue,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      p1Score: p1Score ?? this.p1Score,
      p2Score: p2Score ?? this.p2Score,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}

/// Status da batalha
enum BattleStatus {
  SEARCHING, // Procurando oponente
  IN_PROGRESS, // Batalha em andamento
  FINISHED, // Batalha finalizada
  CANCELLED, // Batalha cancelada
}

/// Modo de batalha
enum BattleMode {
  timed, // Batalha por tempo
  distance, // Batalha por distância
}
