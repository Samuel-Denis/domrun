import 'dart:math' as math;

/// Calculadora de Battle Score (BS)
/// Fórmula: BS = (Distância_Metros × 0.6) + ((720 - Pace_Segundos)/(720 - 240) × 1000 × 0.4)
class BattleScoreCalculator {
  /// Calcula o Battle Score baseado na distância e pace
  /// [distance] - Distância percorrida em metros
  /// [averagePace] - Pace médio em min/km (ex: 4.5 para 4:30 min/km)
  /// Retorna o Battle Score calculado
  static double calculateBattleScore({
    required double distance,
    required double averagePace,
  }) {
    // Converte pace de min/km para segundos/km
    final paceSeconds = averagePace * 60;

    // Componente de distância (60% do score)
    final distanceScore = distance * 0.6;

    // Componente de pace (40% do score)
    // Pace Score: 0-1000 pontos baseado no pace
    // ≤ 4:00 min/km (240s) = 1000 pontos (máximo)
    // ≥ 12:00 min/km (720s) = 0 pontos (mínimo)
    double paceScore = 0.0;

    if (paceSeconds <= 240) {
      // Pace muito rápido (≤ 4:00 min/km) = máximo
      paceScore = 1000.0;
    } else if (paceSeconds >= 720) {
      // Pace muito lento (≥ 12:00 min/km) = mínimo
      paceScore = 0.0;
    } else {
      // Interpolação linear entre 240s e 720s
      final paceRatio = (720 - paceSeconds) / (720 - 240);
      paceScore = paceRatio * 1000;
    }

    // Componente de pace (40% do score)
    final paceComponent = paceScore * 0.4;

    // Battle Score final
    final battleScore = distanceScore + paceComponent;

    print('📊 Cálculo de Battle Score:');
    print('   - Distância: ${distance.toStringAsFixed(2)}m');
    print('   - Pace: ${averagePace.toStringAsFixed(2)} min/km (${paceSeconds.toStringAsFixed(0)}s/km)');
    print('   - Distance Score: ${distanceScore.toStringAsFixed(2)} (60%)');
    print('   - Pace Score: ${paceScore.toStringAsFixed(2)}');
    print('   - Pace Component: ${paceComponent.toStringAsFixed(2)} (40%)');
    print('   - Battle Score Final: ${battleScore.toStringAsFixed(2)}');

    return battleScore;
  }

  /// Calcula o pace médio baseado na distância e duração
  /// [distance] - Distância percorrida em metros
  /// [duration] - Duração em segundos
  /// Retorna o pace médio em min/km
  static double calculateAveragePace({
    required double distance,
    required int duration,
  }) {
    if (distance <= 0 || duration <= 0) return 0.0;

    // Converte distância de metros para km
    final distanceKm = distance / 1000.0;

    // Calcula pace em segundos/km
    final paceSecondsPerKm = duration / distanceKm;

    // Converte para min/km
    final paceMinPerKm = paceSecondsPerKm / 60.0;

    return paceMinPerKm;
  }

  /// Valida se o pace é válido (anti-cheat: velocidade humana)
  /// Retorna true se o pace for válido (≥ 2:30 min/km)
  static bool isValidPace(double averagePace) {
    // Limite: pace médio < 2:30 min/km (150 segundos/km) é suspeito
    final paceSeconds = averagePace * 60;
    return paceSeconds >= 150;
  }

  /// Valida se a duração mínima foi atingida
  /// Retorna true se a duração for ≥ 3 minutos (180 segundos)
  static bool hasMinimumDuration(int duration) {
    return duration >= 180;
  }

  /// Detecta saltos suspeitos no trajeto GPS (anti-cheat)
  /// [path] - Lista de pontos GPS
  /// Retorna true se não houver saltos suspeitos
  static bool isValidPath(List<Map<String, dynamic>> path) {
    if (path.length < 2) return true;

    for (int i = 1; i < path.length; i++) {
      final prevPoint = path[i - 1];
      final currentPoint = path[i];

      final prevLat = prevPoint['latitude'] as double;
      final prevLng = prevPoint['longitude'] as double;
      final prevTime = DateTime.parse(prevPoint['timestamp'] as String);

      final currLat = currentPoint['latitude'] as double;
      final currLng = currentPoint['longitude'] as double;
      final currTime = DateTime.parse(currentPoint['timestamp'] as String);

      // Calcula distância entre pontos
      final distance = _calculateDistanceBetween(
        prevLat,
        prevLng,
        currLat,
        currLng,
      );

      // Calcula tempo entre pontos
      final timeDiff = currTime.difference(prevTime).inSeconds;

      // Se distância > 100m em ≤ 5 segundos, é suspeito (GPS Jump)
      if (distance > 100 && timeDiff <= 5) {
        print('⚠️ GPS Jump detectado: ${distance.toStringAsFixed(2)}m em ${timeDiff}s');
        return false;
      }
    }

    return true;
  }

  /// Calcula distância entre dois pontos usando fórmula de Haversine
  static double _calculateDistanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // Raio da Terra em metros

    final double lat1Rad = lat1 * (math.pi / 180);
    final double lat2Rad = lat2 * (math.pi / 180);
    final double deltaLat = (lat2 - lat1) * (math.pi / 180);
    final double deltaLon = (lng2 - lng1) * (math.pi / 180);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }
}
