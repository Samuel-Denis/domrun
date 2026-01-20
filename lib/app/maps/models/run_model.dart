import 'dart:math' as math;

/// Modelo de dados para uma corrida
class RunModel {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<PositionPoint> path;
  final double? distance; // em metros
  final Duration? duration;
  final String? caption;

  RunModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.path,
    this.distance,
    this.duration,
    this.caption,
  });

  /// Calcula a distância total da corrida
  double calculateDistance() {
    if (path.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < path.length; i++) {
      totalDistance += _calculateDistanceBetween(path[i - 1], path[i]);
    }
    return totalDistance;
  }

  /// Calcula a distância entre dois pontos usando fórmula de Haversine
  double _calculateDistanceBetween(PositionPoint p1, PositionPoint p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros

    final double lat1Rad = p1.latitude * (math.pi / 180);
    final double lat2Rad = p2.latitude * (math.pi / 180);
    final double deltaLat = (p2.latitude - p1.latitude) * (math.pi / 180);
    final double deltaLon = (p2.longitude - p1.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Converte para JSON (para salvar no storage)
  Map<String, dynamic> toJson() {
    final data = {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'path': path.map((p) => p.toJson()).toList(),
      'distance': distance,
      'duration': duration?.inSeconds,
    };
    if (caption != null && caption!.trim().isNotEmpty) {
      data['caption'] = caption!.trim();
    }
    return data;
  }

  /// Cria a partir de JSON
  factory RunModel.fromJson(Map<String, dynamic> json) {
    final pathList = _parsePath(json['pathPoints'] ?? json['path']);

    return RunModel(
      id: json['id'] as String? ?? '',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      path: pathList,
      distance: json['distance'] != null
          ? (json['distance'] is int
                ? (json['distance'] as int).toDouble()
                : json['distance'] as double)
          : null,
      duration: json['duration'] != null
          ? Duration(
              seconds: json['duration'] is int
                  ? json['duration'] as int
                  : (json['duration'] as double).round(),
            )
          : null,
      caption: json['caption'] as String?,
    );
  }
}

/// Modelo para um ponto de posição
class PositionPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  PositionPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      // IMPORTANTE: O timestamp preserva a ordem cronológica do caminho
      // O backend deve usar este timestamp para ordenar os pontos corretamente
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PositionPoint.fromJson(Map<String, dynamic> json) {
    return PositionPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

List<PositionPoint> _parsePath(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((p) => PositionPoint.fromJson(Map<String, dynamic>.from(p)))
      .toList();
}
