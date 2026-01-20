import 'package:nur_app/app/maps/models/run_model.dart';

/// Modelo de dados para um território capturado
/// Representa uma área geográfica que pertence a um usuário
class TerritoryModel {
  final String id;
  final String userId;
  final String userName;
  final String userColor; // Cor do usuário (hexadecimal)
  final String areaName; // Nome da área (ex: "Parque Ibirapuera - Sul")
  final List<PositionPoint> boundary; // Pontos que formam o perímetro do território
  final DateTime capturedAt; // Data/hora em que foi capturado
  final double area; // Área em metros quadrados (opcional)
  final double? distance; // Distância em metros
  final int? duration; // Duração em segundos
  final double? averagePace; // Ritmo médio em min/km
  final double? maxSpeed; // Velocidade máxima em km/h
  final double? elevationGain; // Ganho de elevação em metros
  final double? calories; // Calorias queimadas

  TerritoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.areaName,
    required this.boundary,
    required this.capturedAt,
    this.area = 0.0,
    this.distance,
    this.duration,
    this.averagePace,
    this.maxSpeed,
    this.elevationGain,
    this.calories,
  });

  /// Converte o modelo para JSON (para enviar para API)
  /// IMPORTANTE: Preserva a ordem dos pontos conforme foram coletados
  /// O backend deve manter essa ordem para que o polígono siga exatamente o caminho das ruas
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userColor': userColor,
      'areaName': areaName,
      // Envia boundary como array de pontos (latitude, longitude, timestamp)
      'boundary': boundary.map((p) => p.toJson()).toList(),
      'capturedAt': capturedAt.toIso8601String(),
      'area': area,
      if (distance != null) 'distance': distance,
      if (duration != null) 'duration': duration,
      if (averagePace != null) 'averagePace': averagePace,
      if (maxSpeed != null) 'maxSpeed': maxSpeed,
      if (elevationGain != null) 'elevationGain': elevationGain,
      if (calories != null) 'calories': calories,
    };
  }

  /// Cria o modelo a partir de JSON retornado pela API
  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    return TerritoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userColor: json['userColor'] as String,
      areaName: json['areaName'] as String,
      boundary: (json['boundary'] as List)
          .map((p) => PositionPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.round(),
      averagePace: (json['averagePace'] as num?)?.toDouble(),
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble(),
      elevationGain: (json['elevationGain'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toDouble(),
    );
  }
}
