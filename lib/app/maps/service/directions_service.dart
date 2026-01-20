import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nur_app/core/constants/api_constants.dart';

/// Serviço para usar a API Directions do Mapbox
/// Faz road snapping - ajusta pontos GPS para seguir as ruas
class DirectionsService {
  // Base URL da API Directions do Mapbox
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5';

  /// Obtém uma rota entre dois pontos usando a API Directions do Mapbox
  /// Retorna todos os pontos da rota que segue as ruas
  /// [from] - Ponto de origem (Position do Mapbox)
  /// [to] - Ponto de destino (Position do Mapbox)
  /// Retorna uma lista de Position que segue as ruas entre os dois pontos
  /// Se houver erro, retorna apenas o ponto de destino (fallback)
  Future<List<mb.Position>> getRouteBetweenPoints({
    required mb.Position from,
    required mb.Position to,
    String profile = 'walking', // walking, driving, cycling
  }) async {
    try {
      // Formata as coordenadas no formato exigido pela API: lng,lat;lng,lat
      final coordinates = '${from.lng},${from.lat};${to.lng},${to.lat}';

      // IMPORTANTE: A API Directions requer o prefixo "mapbox/" antes do perfil
      // Perfis válidos: mapbox/walking, mapbox/cycling, mapbox/driving, mapbox/driving-traffic
      final fullProfile = profile.startsWith('mapbox/') ? profile : 'mapbox/$profile';

      // URL da API Directions
      // Formato correto: https://api.mapbox.com/directions/v5/mapbox/{profile}/{coordinates}
      // Parâmetros:
      // - geometries=geojson: Retorna geometria no formato GeoJSON
      // - steps=false: Não precisa de instruções de direção
      // - overview=full: Retorna todos os pontos da rota (máxima precisão)
      final urlString = '$_baseUrl/$fullProfile/$coordinates'
          '?access_token=${ApiConstants.mapboxAccessToken}'
          '&geometries=geojson'
          '&steps=false'
          '&overview=full'
          '&alternatives=false';
      
      final url = Uri.parse(urlString);

      print('🗺️  Buscando rota na API Directions do Mapbox...');
      print('   Profile: $fullProfile');
      print('   De: [${from.lng}, ${from.lat}]');
      print('   Para: [${to.lng}, ${to.lat}]');
      print('   URL: ${urlString.replaceAll(ApiConstants.mapboxAccessToken, 'TOKEN_HIDDEN')}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // A API retorna uma lista de rotas (geralmente apenas uma)
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List).first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;

          // Converte as coordenadas GeoJSON [lng, lat] para mb.Position(lng, lat)
          final routePoints = <mb.Position>[];
          for (final coord in coordinates) {
            final coordList = coord as List<dynamic>;
            final lng = (coordList[0] as num).toDouble();
            final lat = (coordList[1] as num).toDouble();
            routePoints.add(mb.Position(lng, lat));
          }

          print(
            '   ✅ Rota obtida: ${routePoints.length} pontos seguindo as ruas',
          );

          // Não remove o primeiro ponto - mantém todos os pontos para seguir
          // precisamente as vias de tráfego (curvas, rotatórias, etc)
          // O código que chama este método já trata duplicações adequadamente
          return routePoints;
        } else {
          print('   ⚠️  Nenhuma rota encontrada, usando ponto direto');
          return [to]; // Fallback: retorna apenas o ponto de destino
        }
      } else {
        print('   ❌ Erro na API Directions: ${response.statusCode}');
        print('   Body: ${response.body}');
        
        // Diagnóstico de erro
        if (response.statusCode == 404) {
          print('   🔍 Diagnóstico 404:');
          print('      - Verifique se o profile está correto: $fullProfile');
          print('      - Verifique se o token de acesso é válido');
          print('      - Verifique se as coordenadas são válidas');
        }
        
        return [to]; // Fallback: retorna apenas o ponto de destino
      }
    } catch (e, stackTrace) {
      print('   ❌ Erro ao buscar rota: $e');
      print('   Stack trace: $stackTrace');
      return [to]; // Fallback: retorna apenas o ponto de destino
    }
  }

  /// Obtém uma rota entre múltiplos pontos (waypoints)
  /// Útil para snap contínuo durante uma corrida
  /// [points] - Lista de pontos a serem conectados
  /// Retorna todos os pontos da rota que conecta todos os waypoints
  Future<List<mb.Position>> getRouteThroughWaypoints({
    required List<mb.Position> points,
    String profile = 'walking',
  }) async {
    if (points.length < 2) {
      return points; // Retorna os pontos originais se houver menos de 2
    }

    try {
      // Formata as coordenadas: lng,lat;lng,lat;lng,lat...
      final coordinates = points.map((p) => '${p.lng},${p.lat}').join(';');

      // IMPORTANTE: A API Directions requer o prefixo "mapbox/" antes do perfil
      final fullProfile = profile.startsWith('mapbox/') ? profile : 'mapbox/$profile';

      final urlString = '$_baseUrl/$fullProfile/$coordinates'
          '?access_token=${ApiConstants.mapboxAccessToken}'
          '&geometries=geojson'
          '&steps=false'
          '&overview=full'
          '&alternatives=false';
      
      final url = Uri.parse(urlString);

      print('🗺️  Buscando rota com ${points.length} waypoints...');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List).first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;

          final routePoints = <mb.Position>[];
          for (final coord in coordinates) {
            final coordList = coord as List<dynamic>;
            final lng = (coordList[0] as num).toDouble();
            final lat = (coordList[1] as num).toDouble();
            routePoints.add(mb.Position(lng, lat));
          }

          print('   ✅ Rota obtida: ${routePoints.length} pontos');

          return routePoints;
        } else {
          print('   ⚠️  Nenhuma rota encontrada, usando pontos originais');
          return points;
        }
      } else {
        print('   ❌ Erro na API Directions: ${response.statusCode}');
        return points; // Fallback: retorna pontos originais
      }
    } catch (e) {
      print('   ❌ Erro ao buscar rota: $e');
      return points; // Fallback: retorna pontos originais
    }
  }
}
