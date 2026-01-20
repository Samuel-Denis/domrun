import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/app/maps/models/run_model.dart';

class PublicTerritory {
  final String id;
  final String? areaName;
  final double? area;
  final DateTime? capturedAt;

  PublicTerritory({
    required this.id,
    this.areaName,
    this.area,
    this.capturedAt,
  });

  factory PublicTerritory.fromJson(Map<String, dynamic> json) {
    return PublicTerritory(
      id: json['id'] as String? ?? '',
      areaName: json['areaName'] as String?,
      area: (json['area'] as num?)?.toDouble(),
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
    );
  }
}

class PublicRun {
  final String id;
  final double distance;
  final int duration;
  final double averagePace;
  final DateTime? createdAt;
  final String mediaUrl;
  final String? location;
  final List<PositionPoint> path;

  PublicRun({
    required this.id,
    required this.distance,
    required this.duration,
    required this.averagePace,
    this.createdAt,
    required this.mediaUrl,
    this.location,
    this.path = const [],
  });

  factory PublicRun.fromJson(Map<String, dynamic> json) {
    final rawMapImage =
        json['mapImageUrl34'] ??
        json['mapImageUrl_3x4'] ??
        json['mapImageUrlClean'] ??
        json['mapImageCleanUrl'] ??
        json['mapImageUrlStory'] ??
        json['mapImageUrl'];
    final pathList = _parsePath(json['pathPoints'] ?? json['path']);

    return PublicRun(
      id: json['id'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.round() ?? 0,
      mediaUrl: rawMapImage != null
          ? '${ApiConstants.baseUrl}$rawMapImage'
          : '',
      averagePace: (json['averagePace'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      location: (json['city'] ??
              json['location'] ??
              json['cityName'] ??
              json['areaName'])
          as String?,
      path: pathList,
    );
  }

  PublicRun copyWith({
    String? location,
  }) {
    return PublicRun(
      id: id,
      distance: distance,
      duration: duration,
      averagePace: averagePace,
      createdAt: createdAt,
      mediaUrl: mediaUrl,
      location: location ?? this.location,
      path: path,
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
}

class PublicAchievement {
  final String achievementId;
  final String? status;
  final String? medalType;
  final String? category;
  final DateTime? unlockedAt;

  PublicAchievement({
    required this.achievementId,
    this.status,
    this.medalType,
    this.category,
    this.unlockedAt,
  });

  factory PublicAchievement.fromJson(Map<String, dynamic> json) {
    return PublicAchievement(
      achievementId: json['achievementId'] as String? ?? '',
      status: json['status'] as String?,
      medalType: json['medalType'] as String?,
      category: json['category'] as String?,
      unlockedAt: DateTime.tryParse(json['unlockedAt'] as String? ?? ''),
    );
  }
}

class PublicAchievementProgress {
  final String achievementId;
  final double progress;
  final DateTime? lastUpdated;

  PublicAchievementProgress({
    required this.achievementId,
    required this.progress,
    this.lastUpdated,
  });

  factory PublicAchievementProgress.fromJson(Map<String, dynamic> json) {
    return PublicAchievementProgress(
      achievementId: json['achievementId'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? ''),
    );
  }
}

class PublicXpInfo {
  final int level;
  final int xp;
  final int xpForNextLevel;
  final double xpProgress;

  PublicXpInfo({
    required this.level,
    required this.xp,
    required this.xpForNextLevel,
    required this.xpProgress,
  });

  factory PublicXpInfo.fromJson(Map<String, dynamic> json) {
    return PublicXpInfo(
      level: (json['level'] as num?)?.round() ?? 0,
      xp: (json['xp'] as num?)?.round() ?? 0,
      xpForNextLevel: (json['xpForNextLevel'] as num?)?.round() ?? 0,
      xpProgress: (json['xpProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Perfil público de um usuário (visualização por ranking)
class PublicUserProfile {
  final String id;
  final String username;
  final String? name;
  final String? photoUrl;
  final String? color;
  final String? biography;
  final int trophies;
  final String? league;
  final int winStreak;
  final int? level;
  final int? battleWins;
  final int? battleLosses;
  final double? totalTerritoryAreaM2;
  final int? xp;
  final PublicXpInfo? xpInfo;
  final List<PublicTerritory> territories;
  final List<PublicRun> runs;
  final List<PublicAchievement> achievements;
  final List<PublicAchievementProgress> achievementProgress;

  PublicUserProfile({
    required this.id,
    required this.username,
    this.name,
    this.photoUrl,
    this.color,
    this.biography,
    required this.trophies,
    this.league,
    required this.winStreak,
    this.level,
    this.battleWins,
    this.battleLosses,
    this.totalTerritoryAreaM2,
    this.xp,
    this.xpInfo,
    required this.territories,
    required this.runs,
    required this.achievements,
    required this.achievementProgress,
  });

  PublicUserProfile copyWith({
    List<PublicRun>? runs,
  }) {
    return PublicUserProfile(
      id: id,
      username: username,
      name: name,
      photoUrl: photoUrl,
      color: color,
      biography: biography,
      trophies: trophies,
      league: league,
      winStreak: winStreak,
      level: level,
      battleWins: battleWins,
      battleLosses: battleLosses,
      totalTerritoryAreaM2: totalTerritoryAreaM2,
      xp: xp,
      xpInfo: xpInfo,
      territories: territories,
      runs: runs ?? this.runs,
      achievements: achievements,
      achievementProgress: achievementProgress,
    );
  }

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photoUrl'] as String?;
    final territories = (json['territories'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PublicTerritory.fromJson)
        .toList();
    final runs = (json['runs'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PublicRun.fromJson)
        .toList();
    final achievements = (json['userAchievements'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PublicAchievement.fromJson)
        .toList();
    final progress = (json['userAchievementProgress'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PublicAchievementProgress.fromJson)
        .toList();

    return PublicUserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String?,
      photoUrl: rawPhoto != null ? '${ApiConstants.baseUrl}$rawPhoto' : null,
      color: json['color'] as String?,
      biography: json['biography'] as String?,
      trophies: (json['trophies'] ?? 0) is int
          ? json['trophies'] as int
          : (json['trophies'] as num).round(),
      league: json['league'] as String?,
      winStreak: (json['winStreak'] ?? 0) is int
          ? json['winStreak'] as int
          : (json['winStreak'] as num).round(),
      level: json['level'] as int?,
      battleWins: (json['battleWins'] as num?)?.round(),
      battleLosses: (json['battleLosses'] as num?)?.round(),
      totalTerritoryAreaM2: (json['totalTerritoryAreaM2'] as num?)?.toDouble(),
      xp: (json['xp'] as num?)?.round(),
      xpInfo: json['xpInfo'] is Map<String, dynamic>
          ? PublicXpInfo.fromJson(json['xpInfo'] as Map<String, dynamic>)
          : null,
      territories: territories,
      runs: runs,
      achievements: achievements,
      achievementProgress: progress,
    );
  }
}
