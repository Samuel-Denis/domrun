import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:domrun/app/auth/models/user_model.dart';
import 'package:domrun/app/achievement/local/models/achievement_model.dart';
import 'package:domrun/app/profile/models/run_post_model.dart';
import 'package:domrun/app/profile/service/profile_service.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/app/profile/models/user_stats_model.dart';
import 'package:domrun/app/achievement/local/service/achievement_service.dart';
import 'package:domrun/core/services/storage_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:domrun/app/maps/models/run_model.dart';
import 'package:domrun/app/maps/service/geocoding_service.dart';
import 'package:domrun/app/maps/service/mapbox_static_image_service.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart' as svg;

/// Controller para gerenciar os dados do perfil do usuário
/// Busca dados da API e mantém em variáveis reativas
class ProfileController extends GetxController {
  late final StorageService _storage;
  late final UserService _userService;
  late final ProfileService _profileService;
  late final MapboxGeocodingService _geocodingService;
  late final MapboxStaticImageService _mapboxStaticImageService;

  // Variáveis reativas para os dados do perfil
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<UserStatsModel?> stats = Rx<UserStatsModel?>(null);
  final RxList<AchievementModel> achievements = <AchievementModel>[].obs;
  final Rx<Map<String, List<AchievementModel>>> achievementsByCategory =
      Rx<Map<String, List<AchievementModel>>>({});
  final RxList<RunPostModel> runs = <RunPostModel>[].obs;
  final Map<String, String> _cityCache = {};
  final RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;

  // Estado da geração da imagem do trajeto
  final RxBool isRunImageLoading = false.obs;
  final Rxn<Uint8List> runImageBytes = Rxn<Uint8List>();
  final RxnString runImageError = RxnString();

  // Estado de carregamento
  final RxBool isLoading = false.obs;
  final Rxn<String> error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _userService = Get.find<UserService>();
    _profileService = Get.find<ProfileService>();
    _geocodingService = Get.find<MapboxGeocodingService>();
    _mapboxStaticImageService = Get.find<MapboxStaticImageService>();
    // Busca dados quando o controller é inicializado
    loadProfileData();
  }

  void resetRunImageState() {
    isRunImageLoading.value = false;
    runImageBytes.value = null;
    runImageError.value = null;
  }

  Future<void> generateRunImage(RunPostModel run) async {
    isRunImageLoading.value = true;
    runImageError.value = null;
    runImageBytes.value = null;

    try {
      final bytes = await _generateRunImageBytes(run);
      if (bytes == null) {
        runImageError.value = 'Não foi possível gerar a imagem.';
      } else {
        runImageBytes.value = bytes;
      }
    } catch (_) {
      runImageError.value = 'Não foi possível gerar a imagem.';
    } finally {
      isRunImageLoading.value = false;
    }
  }

  Future<bool> saveRunImageToGallery() async {
    final bytes = runImageBytes.value;
    if (bytes == null) return false;
    return _saveImageToGallery(bytes);
  }

  Future<void> saveRunImageAndNotify() async {
    try {
      final ok = await saveRunImageToGallery();
      if (ok) {
        Get.snackbar('Pronto', 'Imagem salva na galeria.');
      } else {
        Get.snackbar('Erro', 'Não foi possível salvar a imagem na galeria.');
      }
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível salvar a imagem na galeria.');
    }
  }

  /// Carrega todos os dados do perfil da API
  Future<void> loadProfileData() async {
    try {
      isLoading.value = true;
      error.value = null;

      final accessToken = _storage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Token de acesso não encontrado');
      }

      // Busca dados completos do perfil
      final data = await _profileService.getCompleteProfile();
      final userData = (data['user'] as Map<String, dynamic>?) ?? data;

        final userMap = Map<String, dynamic>.from(userData);
        userMap.remove('password');
        userMap.remove('postLikes');
        userMap.remove('userAchievements');
        userMap.remove('posts');

        user.value = UserModel.fromJson(userMap);
        if (user.value != null) {
          _userService.setUser(user.value!);
        }

        final runsSource =
            (data['user'] as Map<String, dynamic>?)?['runs'] ??
            data['runs'] ??
            userData['runs'];
        final postsSource =
            (data['user'] as Map<String, dynamic>?)?['posts'] ??
            data['posts'] ??
            userData['posts'];
        final postLikesSource = data['postLikes'];

        if (runsSource is List) {
          final runsList = runsSource;
          final postsList = postsSource is List
              ? postsSource.cast<Map<String, dynamic>>()
              : null;
          final postLikesList = postLikesSource is List
              ? postLikesSource.cast<Map<String, dynamic>>()
              : null;
          final currentUser = user.value;

          runs.value = runsList.map<RunPostModel>((run) {
            final runMap = run as Map<String, dynamic>;
            final runId = runMap['id'] as String?;
            final post = postsList?.firstWhere(
              (p) => p['runId'] == runId,
              orElse: () => <String, dynamic>{},
            );

            return RunPostModel.fromRunAndPost(
              run: runMap,
              post: post?.isNotEmpty == true ? post : null,
              username: currentUser?.username ?? '',
              userPhotoUrl: currentUser?.photoUrl,
              postLikes: postLikesList,
            );
          }).toList();

          await _fillRunCities();
          await _updateAchievementsForRuns(runs);
        } else {
          runs.clear();
        }

        await _loadAchievements();
    } catch (e) {
      error.value = e.toString();
      print('Erro ao carregar dados do perfil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Uint8List?> _generateRunImageBytes(RunPostModel run) async {
    final path = run.path;
    if (path.isEmpty) return null;

    double minLat = path.first.latitude;
    double maxLat = path.first.latitude;
    double minLng = path.first.longitude;
    double maxLng = path.first.longitude;

    for (final p in path) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latPadding = (maxLat - minLat) * 0.35;
    final lngPadding = (maxLng - minLng) * 0.25;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final zoom = _calculateOptimalZoom(minLat, maxLat, minLng, maxLng);

    final userColorHex = _getUserColorHex();
    const username = 'mapbox';
    const styleId = 'satellite-v9';

    const width = 540;
    const height = 960;

    const maxUrlLength = 7000;
    int maxPoints = path.length > 500 ? 30 : 50;

    List<PositionPoint> simplified = _simplifyPathToMaxPoints(path, maxPoints);
    String overlay = 'path-5+$userColorHex(${_encodePolyline(simplified)})';
    String url = _buildStaticUrl(
      overlay: overlay,
      centerLng: centerLng,
      centerLat: centerLat,
      zoom: zoom,
      width: width,
      height: height,
      username: username,
      styleId: styleId,
    );

    int attempts = 0;
    while (attempts < 5 && url.length >= maxUrlLength) {
      maxPoints = (maxPoints * 0.5).round().clamp(10, maxPoints);
      simplified = _simplifyPathToMaxPoints(path, maxPoints);
      overlay = 'path-5+$userColorHex(${_encodePolyline(simplified)})';
      url = _buildStaticUrl(
        overlay: overlay,
        centerLng: centerLng,
        centerLat: centerLat,
        zoom: zoom,
        width: width,
        height: height,
        username: username,
        styleId: styleId,
      );
      attempts++;
    }

    final bytes = await _mapboxStaticImageService.fetchImageBytes(url);
    if (bytes == null) return null;

    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final uiImage = await _convertImageToUiImage(image);
    if (uiImage == null) return null;
    final uiImageWithInfo = await _addRunInfoToImage(
      image,
      uiImage,
      run.distance,
      run.duration,
    );
    final pngBytes = img.encodePng(uiImageWithInfo);
    return pngBytes;
  }

  /// Carrega um SVG e renderiza em alta resolução como ui.Image
  /// size: tamanho desejado em pixels (quanto maior, melhor a qualidade)
  Future<ui.Image?> _loadSvgAsUiImage(String assetPath, double size) async {
    try {
      print('   🎨 Carregando SVG: $assetPath em ${size}x${size}px...');

      // Carrega o SVG como string e injeta cores inline
      var svgString = await rootBundle.loadString(assetPath);
      svgString = svgString
          .replaceAll('class="fil0"', 'fill="#0A1929"')
          .replaceAll('class="fil1"', 'fill="#26C8C6"')
          .replaceAll('class="fil2"', 'fill="#F4F4F4"')
          .replaceAll(
            'class="fil2 str0"',
            'fill="#F4F4F4" stroke="#0A1929" stroke-width="84.67" stroke-miterlimit="22.9256"',
          )
          .replaceAll(
            'class="str0"',
            'stroke="#0A1929" stroke-width="84.67" stroke-miterlimit="22.9256"',
          );

      // Usa a API do flutter_svg 2.0 com loader de string
      final pictureInfo = await svg.vg.loadPicture(
        svg.SvgStringLoader(svgString),
        null,
      );

      // Obtém as dimensões do SVG
      final pictureSize = pictureInfo.size;
      final svgWidth = pictureSize.width <= 0 ? size : pictureSize.width;
      final svgHeight = pictureSize.height <= 0 ? size : pictureSize.height;

      print('   📐 SVG original: ${svgWidth}x${svgHeight}');

      // Calcula o scale para manter proporção e preencher o tamanho desejado
      final scale = size / math.max(svgWidth, svgHeight);

      print('   🔍 Scale calculado: $scale');

      // Renderiza diretamente o Picture em um canvas e converte para Image
      // Isso garante que as cores sejam preservadas corretamente
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Desenha um fundo transparente (necessário para PNG com transparência)
      // Não desenhamos fundo, deixamos transparente

      // Move para o centro e aplica o scale
      canvas.save();
      canvas.translate(size / 2, size / 2);
      canvas.scale(scale);
      canvas.translate(-svgWidth / 2, -svgHeight / 2);

      // Renderiza o SVG no canvas
      canvas.drawPicture(pictureInfo.picture);
      canvas.restore();

      // Finaliza e converte para ui.Image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(size.toInt(), size.toInt());

      // Limpa o Picture da memória
      pictureInfo.picture.dispose();

      print(
        '   ✅ SVG carregado e renderizado: ${uiImage.width}x${uiImage.height}px',
      );
      return uiImage;
    } catch (e, stackTrace) {
      print('   ❌ Erro ao carregar SVG: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Adiciona informações da corrida sobre a imagem
  /// [image] - Imagem do mapa (img.Image) para referência de dimensões
  /// [uiMapImage] - Imagem do mapa (ui.Image) para desenhar no canvas
  /// Retorna a imagem com informações desenhadas
  Future<img.Image> _addRunInfoToImage(
    img.Image image,
    ui.Image uiMapImage,
    double currentDistance,
    int currentDurationSeconds,
  ) async {
    try {
      print('📝 Adicionando informações à imagem...');

      // Obtém informações do usuário e da corrida
      final user = _userService.currentUser.value;
      final userName = user?.name ?? user?.username ?? 'Corredor';
      final distance = currentDistance;
      final duration = Duration(seconds: currentDurationSeconds);

      print('   👤 Nome: $userName');
      print('   📏 Distância: $distance m');
      print('   ⏱️ Duração: $duration');
      final distanceKm = distance >= 1000
          ? '${(distance / 1000).toStringAsFixed(2)} km'
          : '${distance.toStringAsFixed(0)} m';

      // Calcula o pace (min/km)
      String paceText = '--:-- /km';
      if (distance > 0 && duration.inSeconds > 0) {
        final paceSeconds = (duration.inSeconds / (distance / 1000)).round();
        final paceMinutes = paceSeconds ~/ 60;
        final paceSecs = paceSeconds % 60;
        paceText =
            '${paceMinutes.toString().padLeft(2, '0')}:${paceSecs.toString().padLeft(2, '0')} /km';
      }

      // Formata o tempo
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      String timeText;
      if (hours > 0) {
        timeText =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        timeText =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }

      // Cria um canvas para desenhar TUDO (mapa + overlay) em um único canvas
      // Isso garante que tudo seja desenhado corretamente sem problemas de composição
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      );

      // PRIMEIRO: Desenha a imagem do mapa como fundo
      print('   🗺️ Desenhando imagem do mapa no canvas...');
      canvas.drawImage(uiMapImage, Offset.zero, Paint());
      print('   ✅ Mapa desenhado no canvas');

      // Layout igual ao _createMinimalistRunImage, usando o mapa como fundo
      final scale = image.width / 1080;
      final labelStyle = TextStyle(
        color: const Color(0xE6FFFFFF),
        fontSize: 32 * scale,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            color: Color(0xFF000000),
            blurRadius: 3.0,
            offset: Offset(1, 1),
          ),
        ],
      );
      final valueStyle = TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: 72 * scale,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            color: Color(0xFF000000),
            blurRadius: 4.0,
            offset: Offset(1, 1),
          ),
        ],
      );

      double statsTop = 80 * scale;

      // Distância
      final distanceLabel = TextPainter(
        text: TextSpan(text: 'Distância', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      distanceLabel.layout();
      distanceLabel.paint(
        canvas,
        Offset((image.width - distanceLabel.width) / 2, statsTop),
      );

      final distanceValue = TextPainter(
        text: TextSpan(text: distanceKm, style: valueStyle),
        textDirection: TextDirection.ltr,
      );
      distanceValue.layout();
      distanceValue.paint(
        canvas,
        Offset((image.width - distanceValue.width) / 2, statsTop + 40 * scale),
      );

      statsTop += 180 * scale;

      // Pace
      final paceLabel = TextPainter(
        text: TextSpan(text: 'Pace', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      paceLabel.layout();
      paceLabel.paint(
        canvas,
        Offset((image.width - paceLabel.width) / 2, statsTop),
      );

      final paceValue = TextPainter(
        text: TextSpan(text: paceText, style: valueStyle),
        textDirection: TextDirection.ltr,
      );
      paceValue.layout();
      paceValue.paint(
        canvas,
        Offset((image.width - paceValue.width) / 2, statsTop + 40 * scale),
      );

      statsTop += 180 * scale;

      // Tempo
      final timeLabel = TextPainter(
        text: TextSpan(text: 'Tempo', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      timeLabel.layout();
      timeLabel.paint(
        canvas,
        Offset((image.width - timeLabel.width) / 2, statsTop),
      );

      final timeValue = TextPainter(
        text: TextSpan(text: timeText, style: valueStyle),
        textDirection: TextDirection.ltr,
      );
      timeValue.layout();
      timeValue.paint(
        canvas,
        Offset((image.width - timeValue.width) / 2, statsTop + 40 * scale),
      );

      // Desenha a logo do app (canto inferior direito) + texto "DOMRUN"
      final logoSize = 220.0 * scale;
      final logoPadding = 60.0 * scale;
      final logoOffset = Offset(
        image.width - logoSize - logoPadding,
        image.height - logoSize - logoPadding,
      );

      final logoImage = await _loadSvgAsUiImage(
        'assets/images/domrun.svg',
        logoSize,
      );
      if (logoImage != null) {
        canvas.drawImage(logoImage, logoOffset, Paint());
      }

      // Texto abaixo da logo (simula o texto do SVG)
      final logoTextSize = logoSize * 0.32;
      final logoText = TextPainter(
        text: TextSpan(
          style: TextStyle(
            fontSize: logoTextSize,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: const [
              Shadow(
                color: Color(0xFF000000),
                blurRadius: 3,
                offset: Offset(1, 1),
              ),
            ],
          ),
          children: const [
            TextSpan(
              text: 'DOM',
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
            TextSpan(
              text: 'RUN',
              style: TextStyle(color: Color(0xFF26C8C6)),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      );
      logoText.layout();
      final textOffset = Offset(
        logoOffset.dx + (logoSize - logoText.width) / 1.5,
        logoOffset.dy + logoSize / 1.5,
      );
      logoText.paint(canvas, textOffset);

      // Finaliza o desenho - agora temos tudo (mapa + overlay) em um único canvas
      final picture = recorder.endRecording();
      print(
        '   🎨 Canvas completo desenhado (mapa + informações), convertendo para imagem...',
      );

      final finalUiImage = await picture.toImage(image.width, image.height);
      print(
        '   ✅ Imagem final criada: ${finalUiImage.width}x${finalUiImage.height}',
      );

      // Converte a imagem final para bytes PNG
      final byteData = await finalUiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        print(
          '⚠️ Erro ao converter imagem final para bytes, retornando imagem original',
        );
        return image;
      }

      // Converte para img.Image para retornar
      final finalImageBytes = byteData.buffer.asUint8List();
      final finalImage = img.decodeImage(finalImageBytes);

      if (finalImage == null) {
        print(
          '⚠️ Erro ao decodificar imagem final, retornando imagem original',
        );
        return image;
      }

      print('✅ Informações adicionadas à imagem');
      print('   📐 Imagem final: ${finalImage.width}x${finalImage.height}');
      return finalImage;
    } catch (e, stackTrace) {
      print('❌ Erro ao adicionar informações à imagem: $e');
      print('Stack trace: $stackTrace');
      // Retorna a imagem original se houver erro
      return image;
    }
  }

  /// Converte img.Image para ui.Image
  Future<ui.Image?> _convertImageToUiImage(img.Image image) async {
    try {
      final pngBytes = img.encodePng(image);
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('❌ Erro ao converter imagem: $e');
      return null;
    }
  }

  String _buildStaticUrl({
    required String overlay,
    required double centerLng,
    required double centerLat,
    required double zoom,
    required int width,
    required int height,
    required String username,
    required String styleId,
  }) {
    final encodedOverlay = Uri.encodeComponent(overlay);
    final token = ApiConstants.mapboxAccessToken;
    return 'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$token';
  }

  String _getUserColorHex() {
    final user = _userService.currentUser.value;
    if (user?.color != null && user!.color!.isNotEmpty) {
      return user.color!.replaceAll('#', '');
    }
    return '00E5FF';
  }

  List<PositionPoint> _simplifyPathToMaxPoints(
    List<PositionPoint> path,
    int maxPoints,
  ) {
    if (path.length <= maxPoints) return path;
    if (maxPoints <= 2) return [path.first, path.last];

    final result = <PositionPoint>[path.first];
    final step = (path.length - 1) / (maxPoints - 1);
    int lastIndex = 0;

    for (int i = 1; i < maxPoints - 1; i++) {
      final idx = (i * step).round().clamp(1, path.length - 2);
      if (idx == lastIndex) continue;
      result.add(path[idx]);
      lastIndex = idx;
    }

    result.add(path.last);
    return result;
  }

  String _encodePolyline(List<PositionPoint> positions) {
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final pos in positions) {
      final lat = (pos.latitude * 1e5).round();
      final lng = (pos.longitude * 1e5).round();

      final dLat = lat - prevLat;
      final dLng = lng - prevLng;

      _encodeValue(dLat, buffer);
      _encodeValue(dLng, buffer);

      prevLat = lat;
      prevLng = lng;
    }

    return buffer.toString();
  }

  void _encodeValue(int val, StringBuffer buffer) {
    var value = val < 0 ? ~(val << 1) : val << 1;
    while (value >= 0x20) {
      buffer.writeCharCode((0x20 | (value & 0x1f)) + 63);
      value >>= 5;
    }
    buffer.writeCharCode(value + 63);
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

  Future<bool> _saveImageToGallery(Uint8List bytes) async {
    final permission = await PhotoManager.requestPermissionExtend();
    final hasAccess =
        permission == PermissionState.authorized ||
        permission == PermissionState.limited ||
        permission.isAuth;
    if (!hasAccess) return false;

    final filename = 'domrun_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final entity = await PhotoManager.editor.saveImage(
      bytes,
      filename: filename,
    );
    return entity.id.isNotEmpty;
  }

  /// Carrega conquistas do AchievementService (JSON estático)
  /// Primeiro busca progresso do backend e mescla com o local
  Future<void> _loadAchievements() async {
    try {
      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();

        // Busca progresso do backend e mescla com o local
        await achievementService.fetchProgressFromBackend();

        // Carrega conquistas com progresso atualizado
        final grouped = await achievementService
            .getUserAchievementsByCategory();
        achievementsByCategory.value = grouped;
        // Também mantém a lista plana para compatibilidade
        achievements.value = grouped.values.expand((list) => list).toList();
      } else {
        print('Aviso: AchievementService não está registrado');
        achievements.value = [];
        achievementsByCategory.value = {};
      }
    } catch (e) {
      print('Erro ao carregar conquistas: $e');
      achievements.value = [];
      achievementsByCategory.value = {};
    }
  }

  /// Atualiza conquistas relacionadas a corridas
  Future<void> _updateAchievementsForRuns(List<RunPostModel> runs) async {
    try {
      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();

        // Calcula estatísticas das corridas
        int runCount = runs.length;
        double totalDistance = 0.0;

        for (final run in runs) {
          // RunPostModel tem distance como double não-nullable
          totalDistance += run.distance;
        }

        await achievementService.checkAndUpdateAchievements(
          runCount: runCount,
          totalDistance: totalDistance,
        );

        print('✅ Conquistas atualizadas para corridas');
        print('   - Total de corridas: $runCount');
        print('   - Distância total: ${totalDistance.toStringAsFixed(2)} m');
      }
    } catch (e) {
      print('❌ Erro ao atualizar conquistas para corridas: $e');
    }
  }

  Future<void> _fillRunCities() async {
    if (runs.isEmpty) return;

    final updatedRuns = <RunPostModel>[];
    for (final run in runs) {
      if ((run.location ?? '').trim().isNotEmpty) {
        updatedRuns.add(run);
        continue;
      }

      if (run.path.isEmpty) {
        updatedRuns.add(run);
        continue;
      }

      final point = run.path.first;
      final cacheKey =
          '${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}';
      if (_cityCache.containsKey(cacheKey)) {
        updatedRuns.add(run.copyWith(location: _cityCache[cacheKey]));
        continue;
      }

      final city = await _reverseGeocodeCity(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (city != null && city.isNotEmpty) {
        _cityCache[cacheKey] = city;
        updatedRuns.add(run.copyWith(location: city));
      } else {
        updatedRuns.add(run);
      }
    }

    runs.value = updatedRuns;
  }

  Future<String?> _reverseGeocodeCity({
    required double latitude,
    required double longitude,
  }) async {
    return _geocodingService.reverseGeocodeCity(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Recarrega os dados do perfil
  Future<void> refresh() async {
    await loadProfileData();
  }
}
