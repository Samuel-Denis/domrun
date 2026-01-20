import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/app/maps/models/run_model.dart';

/// Modelo combinado de corrida com postagem
/// Representa uma corrida que pode ter uma postagem associada
class RunPostModel {
  final String runId;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final double distance; // em metros
  final int duration; // em segundos
  final double averagePace; // em min/km
  final String? location; // Localização da corrida (ex: "Parque Central")
  final String? territoryId; // ID do território conquistado (se houver)
  final bool isTerritorySafe; // Se o território está seguro

  // Dados da postagem (opcional)
  final String? postId;
  final String? postType; // "photo" ou "video"
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? mapImageUrl;
  final String? mapImageUrlClean;
  final List<PositionPoint> path;
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime? postCreatedAt;

  RunPostModel({
    required this.runId,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.duration,
    required this.averagePace,
    this.location,
    this.territoryId,
    this.isTerritorySafe = false,
    this.postId,
    this.postType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mapImageUrl,
    this.mapImageUrlClean,
    this.path = const [],
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.postCreatedAt,
  });

  /// Cria um modelo a partir de dados de corrida e postagem
  factory RunPostModel.fromRunAndPost({
    required Map<String, dynamic> run,
    Map<String, dynamic>? post,
    String? username,
    String? userPhotoUrl,
    List<Map<String, dynamic>>? postLikes,
  }) {
    // Calcula a localização baseada nos dados do backend (cidade)
    final startTime = DateTime.parse(run['startTime'] as String);
    final location =
        (run['city'] ?? run['location'] ?? run['cityName'] ?? run['areaName'])
            as String?;
    final endTime = run['endTime'] != null
        ? DateTime.parse(run['endTime'] as String)
        : null;
    final durationSeconds = run['duration'] is num
        ? (run['duration'] as num).toInt()
        : endTime != null
        ? endTime.difference(startTime).inSeconds
        : 0;

    // Calcula se é território seguro (se tem territoryId)
    final isTerritorySafe = run['territoryId'] != null;

    // Verifica se o usuário curtiu a postagem
    final postId = post?['id'] as String?;
    final isLiked = postId != null && postLikes != null
        ? postLikes.any((like) => like['postId'] == postId)
        : false;

    final rawMapImage =
        run['mapImageUrlClean'] ??
        run['mapImageUrl_3x4'] ??
        run['mapImageUrl34'] ??
        run['mapImageUrl'];

    final rawMapImageClean =
        run['mapImageUrlClean'] ??
        run['mapImageUrl_3x4'] ??
        run['mapImageUrl34'];

    String? buildMapUrl(dynamic value) {
      if (value == null) return null;
      final url = value.toString();
      if (url.isEmpty) return null;
      return url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
    }

    final pathList = _parsePath(run['pathPoints'] ?? run['path']);

    final distanceMeters = run['distance'] is num
        ? (run['distance'] as num).toDouble()
        : 0.0;
    final averagePaceValue = run['averagePace'] is num
        ? (run['averagePace'] as num).toDouble()
        : (distanceMeters > 0 && durationSeconds > 0)
        ? (durationSeconds / 60) / (distanceMeters / 1000)
        : 0.0;

    return RunPostModel(
      runId: run['id'] as String,
      userId: run['userId'] as String,
      username: username ?? '',
      userPhotoUrl: userPhotoUrl,
      startTime: startTime,
      endTime: endTime,
      distance: distanceMeters,
      duration: durationSeconds,
      averagePace: averagePaceValue,
      location: location,
      territoryId: run['territoryId'] as String?,
      isTerritorySafe: isTerritorySafe,
      postId: postId,
      postType: post?['type'] as String?,
      mediaUrl: post?['mediaUrl'] as String?,
      thumbnailUrl: post?['thumbnailUrl'] as String?,
      mapImageUrl: buildMapUrl(rawMapImage),
      mapImageUrlClean: buildMapUrl(rawMapImageClean),
      path: pathList,
      caption: run['caption'] as String?,
      likesCount: post?['likesCount'] as int? ?? 0,
      commentsCount: post?['commentsCount'] as int? ?? 0,
      isLiked: isLiked,
      postCreatedAt: post?['createdAt'] != null
          ? DateTime.parse(post?['createdAt'] as String)
          : null,
    );
  }

  RunPostModel copyWith({String? location}) {
    return RunPostModel(
      runId: runId,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      startTime: startTime,
      endTime: endTime,
      distance: distance,
      duration: duration,
      averagePace: averagePace,
      location: location ?? this.location,
      territoryId: territoryId,
      isTerritorySafe: isTerritorySafe,
      postId: postId,
      postType: postType,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      mapImageUrl: mapImageUrl,
      mapImageUrlClean: mapImageUrlClean,
      path: path,
      caption: caption,
      likesCount: likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked,
      postCreatedAt: postCreatedAt,
    );
  }

  static List<PositionPoint> _parsePath(dynamic rawPath) {
    if (rawPath is! List) return [];

    final orderedItems = List<dynamic>.from(rawPath);
    final hasSequence = orderedItems.any(
      (item) => item is Map<String, dynamic> && item['sequenceOrder'] is num,
    );
    if (hasSequence) {
      orderedItems.sort((a, b) {
        final aSeq = a is Map<String, dynamic> ? a['sequenceOrder'] : null;
        final bSeq = b is Map<String, dynamic> ? b['sequenceOrder'] : null;
        final aValue = aSeq is num ? aSeq.toDouble() : 0.0;
        final bValue = bSeq is num ? bSeq.toDouble() : 0.0;
        return aValue.compareTo(bValue);
      });
    }

    final points = <PositionPoint>[];
    for (final item in orderedItems) {
      if (item is Map<String, dynamic>) {
        final lat = item['latitude'] ?? item['lat'];
        final lng = item['longitude'] ?? item['lng'];
        final ts = item['timestamp'] ?? item['time'];
        if (lat is num && lng is num) {
          final parsedTime = ts is String ? DateTime.tryParse(ts) : null;
          points.add(
            PositionPoint(
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
              timestamp: parsedTime ?? DateTime.now(),
            ),
          );
        }
      } else if (item is List && item.length >= 2) {
        final lng = item[0];
        final lat = item[1];
        if (lat is num && lng is num) {
          points.add(
            PositionPoint(
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    }
    return points;
  }

  String? buildStaticMapUrl({
    required int width,
    required int height,
    String? strokeColorHex,
  }) {
    if (path.length < 2) return null;

    double minLat = path.first.latitude;
    double maxLat = path.first.latitude;
    double minLng = path.first.longitude;
    double maxLng = path.first.longitude;

    for (final point in path) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latPadding = (maxLat - minLat) * 0.25;
    final lngPadding = (maxLng - minLng) * 0.25;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final zoom = _calculateOptimalZoom(minLat, maxLat, minLng, maxLng);

    final mapboxToken = ApiConstants.mapboxAccessToken;
    const username = 'mapbox';
    const styleId = 'dark-v11';
    final strokeColor = (strokeColorHex ?? '#FF7A00').replaceAll('#', '');

    const maxUrlLength = 7000;
    int maxPoints = path.length > 500 ? 30 : 50;

    List<PositionPoint> simplified = _simplifyPathToMaxPoints(path, maxPoints);
    String polyline = _encodePolyline(simplified);
    String overlay = 'path-5+$strokeColor($polyline)';
    String encodedOverlay = Uri.encodeComponent(overlay);
    String url =
        'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';

    int attempts = 0;
    const maxAttempts = 5;
    while (attempts < maxAttempts && url.length >= maxUrlLength) {
      maxPoints = (maxPoints * 0.5).round().clamp(10, maxPoints);
      simplified = _simplifyPathToMaxPoints(path, maxPoints);
      polyline = _encodePolyline(simplified);
      overlay = 'path-5+$strokeColor($polyline)';
      encodedOverlay = Uri.encodeComponent(overlay);
      url =
          'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';
      attempts++;
    }

    if (url.length >= maxUrlLength) {
      simplified = _simplifyPathToMaxPoints(path, 10);
      polyline = _encodePolyline(simplified);
      overlay = 'path-5+$strokeColor($polyline)';
      encodedOverlay = Uri.encodeComponent(overlay);
      url =
          'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';
    }

    return url;
  }

  List<PositionPoint> _simplifyPathToMaxPoints(
    List<PositionPoint> original,
    int maxPoints,
  ) {
    if (original.length <= maxPoints) return original;
    final result = <PositionPoint>[];
    final step = (original.length - 1) / (maxPoints - 1);
    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).round().clamp(0, original.length - 1);
      result.add(original[index]);
    }
    return result;
  }

  String _encodePolyline(List<PositionPoint> points) {
    if (points.isEmpty) return '';
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      final lat = (point.latitude * 1e5).round();
      final lng = (point.longitude * 1e5).round();
      final dLat = lat - prevLat;
      final dLng = lng - prevLng;
      _encodeValue(dLat, buffer);
      _encodeValue(dLng, buffer);
      prevLat = lat;
      prevLng = lng;
    }
    return buffer.toString();
  }

  void _encodeValue(int value, StringBuffer buffer) {
    var val = value < 0 ? ~(value << 1) : value << 1;
    while (val >= 0x20) {
      buffer.writeCharCode((0x20 | (val & 0x1f)) + 63);
      val >>= 5;
    }
    buffer.writeCharCode(val + 63);
  }

  double _calculateOptimalZoom(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff > 0.1) return 12.0;
    if (maxDiff > 0.05) return 13.0;
    if (maxDiff > 0.02) return 14.0;
    if (maxDiff > 0.01) return 15.0;
    if (maxDiff > 0.005) return 16.0;
    return 17.0;
  }

  /// Formata a data para exibição
  String getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final runDate = DateTime(startTime.year, startTime.month, startTime.day);

    if (runDate == today) {
      return 'Hoje';
    } else if (runDate == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else {
      // Formata como "DD/MM"
      return '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}';
    }
  }

  /// Formata a hora para exibição
  String getFormattedTime() {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formata a distância para exibição
  String getFormattedDistance() {
    final km = distance / 1000.0;
    return '${km.toStringAsFixed(1)}km';
  }

  /// Formata a duração para exibição
  String getFormattedDuration() {
    final minutes = duration ~/ 60;
    return '${minutes}min';
  }

  /// Formata o ritmo para exibição
  String getFormattedPace() {
    return '${averagePace.toStringAsFixed(2)}/km';
  }

  /// Obtém o tipo de corrida baseado na hora
  String getRunType() {
    final hour = startTime.hour;
    if (hour >= 5 && hour < 12) {
      return 'Corrida Matinal';
    } else if (hour >= 12 && hour < 18) {
      return 'Corrida da Tarde';
    } else if (hour >= 18 && hour < 22) {
      return 'Corrida Noturna';
    } else {
      return 'Corrida';
    }
  }
}
