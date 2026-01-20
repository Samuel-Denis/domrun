import 'package:domrun/app/maps/models/run_model.dart';

/// Modelo de dados para submeter resultado de uma batalha
class BattleSubmitModel {
  final String battleId;
  final double distance; // metros
  final int duration; // segundos
  final double averagePace; // min/km
  final double? maxSpeed; // km/h (opcional)
  final double? elevationGain; // metros (opcional)
  final int? calories; // (opcional)
  final List<PositionPoint> path; // Trajeto GPS

  BattleSubmitModel({
    required this.battleId,
    required this.distance,
    required this.duration,
    required this.averagePace,
    this.maxSpeed,
    this.elevationGain,
    this.calories,
    required this.path,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'battleId': battleId,
      'distance': distance,
      'duration': duration,
      'averagePace': averagePace,
      if (maxSpeed != null) 'maxSpeed': maxSpeed,
      if (elevationGain != null) 'elevationGain': elevationGain,
      if (calories != null) 'calories': calories,
      'path': path.map((p) => p.toJson()).toList(),
    };
  }
}
