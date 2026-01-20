/// Modelos para representar dados GeoJSON retornados pela API /runs/map
/// GeoJSON Specification: https://geojson.org/

/// Modelo para FeatureCollection GeoJSON
/// Contém uma lista de Features (territórios)
class GeoJsonFeatureCollection {
  final String type; // Sempre "FeatureCollection"
  final List<GeoJsonFeature> features;

  GeoJsonFeatureCollection({
    required this.type,
    required this.features,
  });

  factory GeoJsonFeatureCollection.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeatureCollection(
      type: json['type'] as String,
      features: (json['features'] as List)
          .map((f) => GeoJsonFeature.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'features': features.map((f) => f.toJson()).toList(),
    };
  }
}

/// Modelo para Feature GeoJSON (representa um território)
class GeoJsonFeature {
  final String type; // Sempre "Feature"
  final String id; // UUID do território
  final GeoJsonGeometry geometry;
  final GeoJsonProperties properties;

  GeoJsonFeature({
    required this.type,
    required this.id,
    required this.geometry,
    required this.properties,
  });

  factory GeoJsonFeature.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeature(
      type: json['type'] as String,
      id: json['id'] as String,
      geometry: GeoJsonGeometry.fromJson(
        json['geometry'] as Map<String, dynamic>,
      ),
      properties: GeoJsonProperties.fromJson(
        json['properties'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'geometry': geometry.toJson(),
      'properties': properties.toJson(),
    };
  }
}

/// Modelo para Geometry GeoJSON (Polygon)
class GeoJsonGeometry {
  final String type; // Sempre "Polygon" para territórios
  final List<List<List<double>>> coordinates;

  GeoJsonGeometry({
    required this.type,
    required this.coordinates,
  });

  factory GeoJsonGeometry.fromJson(Map<String, dynamic> json) {
    return GeoJsonGeometry(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List)
          .map((ring) => (ring as List)
              .map((coord) => (coord as List)
                  .map((c) => (c as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  /// Retorna o anel externo do polígono (primeiro array de coordenadas)
  /// GeoJSON Polygon: [[[lng, lat], [lng, lat], ...]]
  List<List<double>> get outerRing => coordinates.isNotEmpty ? coordinates[0] : [];
}

/// Modelo para Properties do Feature (metadados do território)
class GeoJsonProperties {
  final String owner; // Username do dono (legado)
  final String color; // Cor hexadecimal do usuário
  final String? areaName; // Nome da área
  final String? userId; // ID do usuário
  final String? userName; // Nome completo do usuário
  final String? username; // Username do usuário
  final String? photoUrl; // URL da foto de perfil
  final String? capturedAt; // Data de captura (ISO string)
  final double? areaM2; // Área em metros quadrados

  GeoJsonProperties({
    required this.owner,
    required this.color,
    this.areaName,
    this.userId,
    this.userName,
    this.username,
    this.photoUrl,
    this.capturedAt,
    this.areaM2,
  });

  factory GeoJsonProperties.fromJson(Map<String, dynamic> json) {
    return GeoJsonProperties(
      owner: json['owner'] as String? ?? json['username'] as String? ?? '',
      color: json['color'] as String? ?? '#00E5FF', // Padrão: Ciano (era roxo #7B2CBF)
      areaName: json['areaName'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      username: json['username'] as String?,
      photoUrl: json['photoUrl'] as String?,
      capturedAt: json['capturedAt'] as String?,
      areaM2: json['areaM2'] != null ? (json['areaM2'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner': owner,
      'color': color,
      if (areaName != null) 'areaName': areaName,
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (username != null) 'username': username,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (capturedAt != null) 'capturedAt': capturedAt,
      if (areaM2 != null) 'areaM2': areaM2,
    };
  }
}
