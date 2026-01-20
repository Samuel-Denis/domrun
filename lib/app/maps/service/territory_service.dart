import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nur_app/app/maps/models/territory_model.dart';
import 'package:nur_app/app/maps/models/run_model.dart';
import 'package:nur_app/app/maps/models/geojson_models.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/services/http_service.dart';

/// Serviço para gerenciar territórios
/// Envia territórios capturados para o servidor
class TerritoryService extends GetxService {
  late final HttpService _httpService;
  bool _sendRunImages = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    _httpService = Get.find<HttpService>();
  }

  /// Salva um território capturado no servidor
  ///
  /// IMPORTANTE: O frontend envia os pontos como uma LINESTRING (rastro da rua)
  /// O backend DEVE:
  /// 1. Receber os pontos e criar uma LineString (ST_MakeLine ou ST_GeomFromText com LINESTRING)
  /// 2. Aplicar ST_Buffer(linestring, 10) no PostGIS para criar uma área de 10 metros ao redor
  /// 3. Calcular a área real usando ST_Area(ST_Transform(buffer, 3857))
  /// 4. Retornar o polígono bufferizado no formato GeoJSON
  ///
  /// Isso cria uma "pintura" do asfalto ao redor do rastro da rua, não um polígono fechado simples
  ///
  /// [territory] - Modelo do território a ser salvo (boundary = LineString, não Polygon fechado)
  /// [mapImagePath] - Caminho opcional da imagem 9:16 com infos (será enviada como `mapImage`)
  /// [mapImageCleanPath] - Caminho opcional da imagem 3:4 sem infos (será enviada como `mapImageClean`)
  /// Retorna o território salvo com ID do servidor (com o polígono já bufferizado)
  /// Lança uma exceção se houver erro
  Future<TerritoryModel> saveTerritory(TerritoryModel territory) async {
    try {
      final url = ApiConstants.runsEndpoint;
      // Prepara o JSON do território (usado em ambos os casos)
      final requestBody = territory.toJson();
      final response = await _httpService.post(
        url,
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TerritoryModel.fromJson(data);
      } else {
        throw Exception('Erro ao salvar território: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao salvar território: $e');
      throw Exception('Erro ao salvar território: $e');
    }
  }

  /// Obtém todos os territórios do mapa no formato GeoJSON FeatureCollection
  /// Endpoint público que não requer autenticação
  /// Retorna FeatureCollection com todos os territórios de todos os usuários
  /// Obtém territórios no formato GeoJSON
  /// [bbox] - Bounding box opcional no formato [minLng, minLat, maxLng, maxLat]
  ///          Se fornecido, retorna apenas territórios dentro dessa área
  ///          Se null, retorna todos os territórios (compatibilidade com código antigo)
  Future<GeoJsonFeatureCollection> getMapTerritories({
    List<double>? bbox,
  }) async {
    try {
      var url = '${ApiConstants.baseUrl}${ApiConstants.mapTerritoriesEndpoint}';

      // Adiciona bbox como parâmetro de query se fornecido
      if (bbox != null && bbox.length == 4) {
        final bboxParam = bbox.map((e) => e.toString()).join(',');
        url += '?bbox=$bboxParam';
        print('🔍 Buscando territories com bbox: [$bboxParam]');
      } else {
        print('🔍 Buscando territories no formato GeoJSON na URL: $url');
      }

      final response = await _httpService.getUrl(
        url,
        includeAuth: false,
      );

      print('📡 Resposta da API: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Verifica se é um FeatureCollection válido
        if (data['type'] != 'FeatureCollection') {
          throw Exception(
            'Formato inválido: esperado FeatureCollection, recebido ${data['type']}',
          );
        }

        final featureCollection = GeoJsonFeatureCollection.fromJson(data);
        print(
          '✅ ${featureCollection.features.length} territories recebidos no formato GeoJSON',
        );

        return featureCollection;
      } else {
        print('❌ Erro na resposta da API: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Erro ao obter territories: Status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar territories: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtém todos os territórios do usuário atual
  /// Retorna lista de territórios (método legado - mantido para compatibilidade)
  /// NOTA: Este método pode não estar disponível dependendo da API
  /// Prefira usar getMapTerritories() e filtrar pelo usuário
  Future<List<TerritoryModel>> getUserTerritories() async {
    try {
      final endpoint = ApiConstants.runsEndpoint;

      print('🔍 Buscando territórios na URL: ${ApiConstants.baseUrl}$endpoint');

      final response = await _httpService.get(endpoint);

      print('📡 Resposta da API: Status ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} territórios recebidos da API');

        final territories = data.map((t) {
          try {
            return TerritoryModel.fromJson(t as Map<String, dynamic>);
          } catch (e) {
            print('❌ Erro ao parsear território: $e');
            print('   Dados: $t');
            rethrow;
          }
        }).toList();

        print('✅ ${territories.length} territórios parseados com sucesso');
        return territories;
      } else {
        print('❌ Erro na resposta da API: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Erro ao obter territórios: Status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar territórios: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtém todos os territórios de uma área específica
  /// [areaName] - Nome da área
  /// Retorna lista de territórios da área
  Future<List<TerritoryModel>> getTerritoriesByArea(String areaName) async {
    try {
      final response = await _httpService.get(
        '/territories?area=$areaName',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((t) => TerritoryModel.fromJson(t as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Erro ao obter territórios: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Salva uma corrida no servidor (com território conquistado)
  /// Usado quando o usuário captura um território (circuito fechado)
  /// [run] - Modelo da corrida a ser salva
  /// [mapImagePath] - Caminho opcional da imagem 9:16 (será enviada como `mapImage`)
  /// [mapImageCleanPath] - Caminho opcional da imagem 3:4 (será enviada como `mapImageClean`)
  /// Retorna o modelo da corrida salva com ID do servidor
  /// Lança uma exceção se houver erro
  Future<RunModel> saveRun(
    RunModel run, {
    File? mapImagePath,
    File? mapImageCleanPath,
  }) async {
    try {
      final headers = await _httpService.getHeaders();
      final endpoint = ApiConstants.runsEndpoint;
      final url = '${ApiConstants.baseUrl}$endpoint';

      print('📤 Enviando corrida (com território) para o servidor:');
      print('   - Start time: ${run.startTime}');
      print('   - End time: ${run.endTime}');
      print('   - Distance: ${run.distance} m');
      print('   - Duration: ${run.duration}');
      print('   - Path points: ${run.path.length}');
      print('   - URL: $url');

      // Prepara o JSON da corrida
      final requestBody = run.toJson();
      final jsonBody = json.encode(requestBody);

      // Se houver imagem, usa multipart/form-data, senão usa JSON simples
      http.Response response;

      final hasMapImage = mapImagePath != null && mapImagePath.existsSync();
      final hasCleanImage =
          mapImageCleanPath != null && mapImageCleanPath.existsSync();

      if (_sendRunImages && (hasMapImage || hasCleanImage)) {
        print('📸 Enviando corrida com imagem do trajeto...');
        if (hasMapImage) {
          print('   - Caminho da imagem 9:16: $mapImagePath');
        }
        if (hasCleanImage) {
          print('   - Caminho da imagem 3:4: $mapImageCleanPath');
        }

        // Prepara multipart request
        final request = http.MultipartRequest('POST', Uri.parse(url));

        // Adiciona headers de autenticação
        request.headers.addAll(headers);

        // Adiciona os dados da corrida como JSON string no campo 'data'
        request.fields['data'] = jsonBody;
        print('   - Tamanho do JSON: ${jsonBody.length} bytes');

        if (hasMapImage) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'mapImage',
              mapImagePath!.path,
              filename:
                  'run_${run.startTime.toIso8601String().replaceAll(':', '-').split('.')[0]}_story.png',
              contentType: http.MediaType.parse('image/png'),
            ),
          );
        }

        if (hasCleanImage) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'mapImageClean',
              mapImageCleanPath!.path,
              filename:
                  'run_${run.startTime.toIso8601String().replaceAll(':', '-').split('.')[0]}_map.png',
              contentType: http.MediaType.parse('image/png'),
            ),
          );
        }

        print('   - Enviando como multipart/form-data com imagem');
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Envia apenas JSON (sem imagem)
        if (mapImagePath != null || mapImageCleanPath != null) {
          print('ℹ️  Envio de imagens desativado (servidor não aceita).');
        }

        print('   - Tamanho do JSON: ${jsonBody.length} bytes');
        response = await _httpService.post(
          endpoint,
          requestBody,
        );
      }

      print('📥 Resposta do servidor: Status ${response.statusCode}');
      print('📥 Body da resposta: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          // Verifica se o body não está vazio
          if (response.body.isEmpty) {
            print('⚠️ Resposta vazia do servidor, retornando modelo básico');
            // Retorna o modelo original já que foi salvo com sucesso
            return run;
          }

          final decoded = json.decode(response.body);

          // Se a resposta for um Map, usa diretamente
          if (decoded is Map<String, dynamic>) {
            final data = decoded;
            print('✅ Corrida (com território) salva com sucesso');
            return RunModel.fromJson(data);
          } else {
            // Se não for um Map, retorna o modelo original
            print('⚠️ Resposta não é um Map, retornando modelo original');
            return run;
          }
        } catch (e) {
          print('⚠️ Erro ao parsear resposta do servidor: $e');
          print(
            '   Retornando modelo original (corrida foi salva com sucesso)',
          );
          // Retorna o modelo original já que foi salvo com sucesso
          return run;
        }
      } else {
        String errorMessage = 'Erro ao salvar corrida';

        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              errorData['detail'] ??
              'Erro ao salvar corrida';
        } catch (_) {
          // Se não conseguir parsear JSON, usa a mensagem padrão
        }

        print('❌ ERRO ao salvar corrida (com território):');
        print('   - Status: ${response.statusCode}');
        print('   - Mensagem: $errorMessage');
        print('   - Body: ${response.body}');

        throw Exception(
          'Erro ao salvar corrida: Status ${response.statusCode} - $errorMessage',
        );
      }
    } catch (e) {
      print('❌ Erro ao salvar corrida (com território): $e');
      rethrow;
    }
  }

  /// Salva uma corrida simples no servidor (sem território)
  /// Usado quando o usuário para a corrida sem fechar um circuito
  /// [run] - Modelo da corrida a ser salva
  /// [mapImagePath] - Caminho opcional da imagem 9:16 (será enviada como `mapImage`)
  /// [mapImageCleanPath] - Caminho opcional da imagem 3:4 (será enviada como `mapImageClean`)
  /// Retorna o modelo da corrida salva com ID do servidor
  /// Lança uma exceção se houver erro
  Future<RunModel> saveSimpleRun(
    RunModel run, {
    File? mapImagePath,
    File? mapImageCleanPath,
  }) async {
    try {
      final headers = await _httpService.getHeaders();
      final endpoint = ApiConstants.simpleRunEndpoint;
      final url = '${ApiConstants.baseUrl}$endpoint';

      print('📤 Enviando corrida simples para o servidor:');
      print('   - Start time: ${run.startTime}');
      print('   - End time: ${run.endTime}');
      print('   - Distance: ${run.distance} m');
      print('   - Duration: ${run.duration}');
      print('   - Path points: ${run.path.length}');
      print('   - URL: $url');

      // Prepara o JSON da corrida
      final requestBody = run.toJson();
      final jsonBody = json.encode(requestBody);

      // Se houver imagem, usa multipart/form-data, senão usa JSON simples
      http.Response response;

      final hasMapImage = mapImagePath != null && mapImagePath.existsSync();
      final hasCleanImage =
          mapImageCleanPath != null && mapImageCleanPath.existsSync();

      if (_sendRunImages && (hasMapImage || hasCleanImage)) {
        print('📸 Enviando corrida com imagem do trajeto...');
        if (hasMapImage) {
          print('   - Caminho da imagem 9:16: $mapImagePath');
        }
        if (hasCleanImage) {
          print('   - Caminho da imagem 3:4: $mapImageCleanPath');
        }

        // Prepara multipart request
        final request = http.MultipartRequest('POST', Uri.parse(url));

        request.headers.addAll(headers);

        // Adiciona os dados da corrida como JSON string no campo 'data'
        request.fields['data'] = jsonBody;
        print('   - Tamanho do JSON: ${jsonBody.length} bytes');

        if (hasMapImage) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'mapImage',
              mapImagePath!.path,
              filename:
                  'run_${run.startTime.toIso8601String().replaceAll(':', '-').split('.')[0]}_story.png',
              contentType: http.MediaType.parse('image/png'),
            ),
          );
        }

        if (hasCleanImage) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'mapImageClean',
              mapImageCleanPath!.path,
              filename:
                  'run_${run.startTime.toIso8601String().replaceAll(':', '-').split('.')[0]}_map.png',
              contentType: http.MediaType.parse('image/png'),
            ),
          );
        }

        print('   - Enviando como multipart/form-data com imagem');
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Envia apenas JSON (sem imagem)
        if (mapImagePath != null || mapImageCleanPath != null) {
          print('ℹ️  Envio de imagens desativado (servidor não aceita).');
        }

        print('   - Tamanho do JSON: ${jsonBody.length} bytes');
        response = await _httpService.post(
          endpoint,
          requestBody,
        );
      }

      print('📥 Resposta do servidor: Status ${response.statusCode}');
      print('📥 Body da resposta: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          // Verifica se o body não está vazio
          if (response.body.isEmpty) {
            print('⚠️ Resposta vazia do servidor, retornando modelo básico');
            // Retorna o modelo original já que foi salvo com sucesso
            return run;
          }

          final decoded = json.decode(response.body);

          // Se a resposta for um Map, usa diretamente
          if (decoded is Map<String, dynamic>) {
            final data = decoded;
            print('✅ Corrida simples salva com sucesso');
            return RunModel.fromJson(data);
          } else {
            // Se não for um Map, retorna o modelo original
            print('⚠️ Resposta não é um Map, retornando modelo original');
            return run;
          }
        } catch (e) {
          print('⚠️ Erro ao parsear resposta do servidor: $e');
          print(
            '   Retornando modelo original (corrida foi salva com sucesso)',
          );
          // Retorna o modelo original já que foi salvo com sucesso
          return run;
        }
      } else {
        String errorMessage = 'Erro ao salvar corrida';

        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              errorData['detail'] ??
              'Erro ao salvar corrida';
        } catch (_) {
          // Se não conseguir parsear JSON, usa a mensagem padrão
        }

        print('❌ ERRO ao salvar corrida simples:');
        print('   - Status: ${response.statusCode}');
        print('   - Mensagem: $errorMessage');
        print('   - Body: ${response.body}');

        throw Exception(
          'Erro ao salvar corrida: Status ${response.statusCode} - $errorMessage',
        );
      }
    } catch (e) {
      print('❌ Erro ao salvar corrida simples: $e');
      rethrow;
    }
  }
}
