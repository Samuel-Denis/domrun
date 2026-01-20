import 'dart:convert';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/http_service.dart';

/// Serviço para usar a API Map Matching do Mapbox
/// O Map Matching é o "segredo do Strava": ajusta pontos GPS "sujos" para seguir exatamente as ruas
/// Diferente da Directions API (que calcula rotas), o Map Matching corrige trajetos já percorridos
class MapMatchingService {
  final HttpService _httpService = Get.find<HttpService>();
  // Base URL da API Map Matching do Mapbox
  static const String _baseUrl = 'https://api.mapbox.com/matching/v5';

  /// Faz Map Matching de uma lista de pontos GPS
  /// Envia os pontos "sujos" do GPS e recebe pontos "limpos" que seguem exatamente o meio da rua
  /// [points] - Lista de pontos GPS brutos (mb.Position)
  /// [profile] - Perfil de transporte: 'walking', 'cycling', 'driving' (será prefixado com 'mapbox/')
  /// Retorna a lista de pontos corrigidos que seguem as ruas, ou null se houver erro
  Future<List<mb.Position>?> matchPoints({
    required List<mb.Position> points,
    String profile = 'walking',
  }) async {
    if (points.isEmpty) {
      return null;
    }

    // Se houver apenas 1 ponto, não precisa fazer matching
    if (points.length == 1) {
      return points;
    }

    try {
      // Valida número de pontos (API aceita até 100 pontos)
      // Cria uma cópia da lista para não modificar o parâmetro original
      List<mb.Position> pointsToProcess = points;
      if (points.length > 100) {
        print('   ⚠️  AVISO: ${points.length} pontos excedem o limite de 100. Usando apenas os primeiros 100.');
        pointsToProcess = points.sublist(0, 100);
      }

      // Formata as coordenadas no formato exigido pela API: lng,lat;lng,lat;...
      // IMPORTANTE: O Map Matching API aceita até 100 pontos por requisição
      final coordinates = pointsToProcess.map((p) => '${p.lng},${p.lat}').join(';');

      // IMPORTANTE: A API Map Matching requer o prefixo "mapbox/" antes do perfil
      // Perfis válidos: mapbox/walking, mapbox/cycling, mapbox/driving, mapbox/driving-traffic
      final fullProfile = profile.startsWith('mapbox/') ? profile : 'mapbox/$profile';

      // URL da API Map Matching
      // Formato correto: https://api.mapbox.com/matching/v5/mapbox/{profile}/{coordinates}
      // Parâmetros:
      // - geometries=geojson: Retorna geometria no formato GeoJSON
      // - overview=full: Retorna todos os pontos da geometria corrigida (máxima precisão)
      // - steps=false: Não precisa de instruções de direção
      final urlString = '$_baseUrl/$fullProfile/$coordinates'
          '?access_token=${ApiConstants.mapboxAccessToken}'
          '&geometries=geojson'
          '&overview=full'
          '&steps=false';
      
      // Valida comprimento da URL (alguns servidores têm limite de ~2000 caracteres)
      if (urlString.length > 2000) {
        print('   ⚠️  AVISO: URL muito longa (${urlString.length} caracteres). Pode causar problemas.');
        print('   💡 Considere reduzir o número de pontos ou usar POST em vez de GET');
      }

      print('🗺️  Fazendo Map Matching de ${pointsToProcess.length} pontos GPS...');
      print('   Profile: $fullProfile');
      print('   Coordenadas formatadas: ${coordinates.length} caracteres');
      if (pointsToProcess.length >= 3) {
        print('   Primeiros 3 pontos: ${pointsToProcess.take(3).map((p) => '[${p.lng},${p.lat}]').join(', ')}');
      }

      final response = await _httpService.getUrl(
        urlString,
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Verifica se há matchings (geralmente apenas um)
        if (data['matchings'] != null &&
            (data['matchings'] as List).isNotEmpty) {
          final matching = (data['matchings'] as List).first
              as Map<String, dynamic>;
          final geometry = matching['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;

          // Converte as coordenadas GeoJSON [lng, lat] para mb.Position(lng, lat)
          final matchedPoints = <mb.Position>[];
          for (final coord in coordinates) {
            final coordList = coord as List<dynamic>;
            final lng = (coordList[0] as num).toDouble();
            final lat = (coordList[1] as num).toDouble();
            matchedPoints.add(mb.Position(lng, lat));
          }

          print(
            '   ✅ Map Matching concluído: ${matchedPoints.length} pontos corrigidos seguindo as ruas',
          );
          print(
            '   - Pontos originais: ${points.length} | Pontos corrigidos: ${matchedPoints.length}',
          );

          return matchedPoints;
        } else {
          print('   ⚠️  Nenhum matching encontrado, retornando pontos originais');
          return points; // Fallback: retorna pontos originais
        }
      } else {
        print('   ❌ Erro na API Map Matching: ${response.statusCode}');
        print('   Body: ${response.body}');
        
        // Logs adicionais para debugging
        if (response.statusCode == 404) {
          print('   🔍 Diagnóstico 404:');
          print('      - Verifique se o profile está correto: $fullProfile');
          print('      - Verifique se o token de acesso é válido');
          print('      - Verifique se as coordenadas estão no formato correto (lng,lat)');
          print('      - URL completa: ${urlString.replaceAll(ApiConstants.mapboxAccessToken, 'TOKEN_HIDDEN')}');
        } else if (response.statusCode == 400) {
          print('   🔍 Diagnóstico 400 (Bad Request):');
          print('      - Verifique se as coordenadas são válidas');
          print('      - Verifique se há pelo menos 2 pontos');
        } else if (response.statusCode == 401) {
          print('   🔍 Diagnóstico 401 (Unauthorized):');
          print('      - Token de acesso inválido ou expirado');
        } else if (response.statusCode == 422) {
          print('   🔍 Diagnóstico 422 (Unprocessable Entity):');
          print('      - Coordenadas podem estar muito distantes');
          print('      - Pode não haver rotas entre os pontos');
        }
        
        print('   ⚠️  Usando pontos GPS originais como fallback (sem correção de ruas)');
        return points; // Fallback: retorna pontos originais
      }
    } catch (e, stackTrace) {
      print('   ❌ Erro ao fazer Map Matching: $e');
      print('   Stack trace: $stackTrace');
      print('   ⚠️  Usando pontos GPS originais como fallback');
      return points; // Fallback: retorna pontos originais
    }
  }

  /// Faz Map Matching em lote quando há muitos pontos (>100)
  /// Divide os pontos em chunks de até 100 pontos e faz matching de cada chunk
  /// [points] - Lista de pontos GPS brutos
  /// [profile] - Perfil de transporte
  /// Retorna a lista completa de pontos corrigidos
  Future<List<mb.Position>> matchPointsBatch({
    required List<mb.Position> points,
    String profile = 'walking',
  }) async {
    if (points.isEmpty) {
      return points;
    }

    // Se houver 100 ou menos pontos, faz matching direto
    if (points.length <= 100) {
      final matched = await matchPoints(points: points, profile: profile);
      return matched ?? points;
    }

    print(
      '📦 Dividindo ${points.length} pontos em batches para Map Matching...',
    );

    // Divide em chunks de 100 pontos (limite da API)
    final matchedAll = <mb.Position>[];
    const chunkSize = 100;

    for (int i = 0; i < points.length; i += chunkSize) {
      final end = (i + chunkSize < points.length) ? i + chunkSize : points.length;
      final chunk = points.sublist(i, end);

      print('   - Processando chunk ${(i ~/ chunkSize) + 1}: ${chunk.length} pontos');

      final matched = await matchPoints(points: chunk, profile: profile);
      if (matched != null && matched.isNotEmpty) {
        // Conecta os chunks: remove o último ponto do chunk anterior se for igual ao primeiro do próximo
        if (matchedAll.isNotEmpty && matched.isNotEmpty) {
          final lastPoint = matchedAll.last;
          final firstPoint = matched.first;

          // Se os pontos são muito próximos (< 5m), não adiciona o primeiro ponto do novo chunk
          final distance = _calculateDistance(lastPoint, firstPoint);
          if (distance < 5.0) {
            matchedAll.addAll(matched.skip(1));
          } else {
            matchedAll.addAll(matched);
          }
        } else {
          matchedAll.addAll(matched);
        }
      }

      // Pequeno delay para não sobrecarregar a API
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Map Matching em batch concluído: ${matchedAll.length} pontos');
    return matchedAll;
  }

  /// Calcula distância entre dois pontos (Haversine)
  double _calculateDistance(mb.Position p1, mb.Position p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    final lat1Rad = p1.lat * (math.pi / 180.0);
    final lat2Rad = p2.lat * (math.pi / 180.0);
    final deltaLat = (p2.lat - p1.lat) * (math.pi / 180.0);
    final deltaLng = (p2.lng - p1.lng) * (math.pi / 180.0);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}
