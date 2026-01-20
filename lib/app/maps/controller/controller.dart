import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart'
    as geo; // Usamos prefixo para não confundir
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'dart:async';
import 'package:nur_app/app/maps/models/territory_model.dart';
import 'package:nur_app/app/maps/models/run_model.dart';
//import 'package:nur_app/app/maps/models/geojson_models.dart';
import 'package:nur_app/app/maps/service/territory_service.dart';
import 'package:nur_app/app/maps/service/directions_service.dart';
import 'package:nur_app/app/maps/service/map_matching_service.dart';
import 'package:nur_app/app/profile/service/achievement_service.dart';
import 'package:nur_app/app/profile/controller/profile_controller.dart';
import 'package:nur_app/app/battles/controller/battle_controller.dart';
import 'package:nur_app/app/user/service/user_service.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Controlador responsável por gerenciar o mapa, localização GPS e rastreamento de corridas
class MapController extends GetxController {
  // Referência ao mapa para podermos mover a câmera ou desenhar
  mb.MapboxMap? mapboxMap;

  // Lista reativa de coordenadas para a corrida atual (formato Mapbox)
  var currentRunPath = <mb.Position>[].obs;

  // Status da corrida (true quando está rastreando)
  var isTracking = false.obs;

  // Localização atual do usuário (reativa)
  var currentLocation = Rxn<mb.Point>();

  // StreamSubscription serve para cancelar a escuta do GPS quando a corrida parar
  StreamSubscription<geo.Position>? _positionStream;

  // StreamSubscription para o rastreamento de localização geral (não durante corrida)
  StreamSubscription<geo.Position>? _locationTrackingStream;

  // Timer para atualizar o cronômetro a cada segundo
  Timer? _runTimer;

  // Timer para atualizar notificação com estatísticas
  Timer? _notificationUpdateTimer;

  // Timer para verificar mudanças na câmera do mapa
  Timer? _cameraChangeCheckTimer;

  // Último bbox usado para carregar territórios (para evitar recarregar a mesma área)
  List<double>? _lastLoadedBbox;

  // Flag para indicar se está carregando territórios (evita múltiplas requisições simultâneas)
  bool _isLoadingTerritories = false;

  // Gerenciador de anotações de polyline para desenhar o trajeto
  mb.PolylineAnnotationManager? _polylineAnnotationManager;

  // Polyline atual no mapa (armazena a annotation completa)
  mb.PolylineAnnotation? _currentPolyline;

  // Gerenciador de anotações de polígono para desenhar territórios conquistados (legado)
  mb.PolygonAnnotationManager? _polygonAnnotationManager;

  // Lista de polígonos de territórios no mapa (legado - usando PolygonAnnotation)
  final List<mb.PolygonAnnotation> _territoryPolygons = [];

  // Source ID para os territórios no mapa (FillLayer)
  static const String _territoriesSourceId = 'territories-source';

  // Layer ID para os territórios no mapa (FillLayer)
  static const String _territoriesLayerId = 'territories-layer';

  // Source ID para o trajeto em tempo real (LineLayer - estilo Strava)
  static const String _trailSourceId = 'user-trail-source';

  // Layer ID para o trajeto em tempo real (LineLayer)
  static const String _trailLayerId = 'user-trail-layer';

  // Referência ao GeoJsonSource para o trajeto em tempo real
  mb.GeoJsonSource? _trailGeoJsonSource;

  // GeoJSON FeatureCollection para os territórios
  final List<Map<String, dynamic>> _territoriesFeatures = [];

  // Referência ao GeoJsonSource para poder atualizar os dados
  mb.GeoJsonSource? _territoriesGeoJsonSource;

  // Serviços
  late final TerritoryService _territoryService;
  late final UserService _userService;
  late final DirectionsService _directionsService;
  late final MapMatchingService _mapMatchingService;

  // BattleController (opcional - só usado se houver batalha ativa)
  BattleController? _battleController;

  // Último ponto que foi adicionado ao caminho (para road snapping)
  mb.Position? _lastSnappedPoint;

  // Lista de pontos GPS brutos (coletados antes do Map Matching)
  final List<mb.Position> _rawGpsPoints = [];

  // Timer para fazer Map Matching periódico (configurável: 10-20 segundos)
  Timer? _mapMatchingTimer;

  // Intervalo configurável para Map Matching (em segundos)
  // Pode ser ajustado entre 10-20 segundos conforme necessário
  // Valores recomendados:
  // - 10 segundos: Mais frequente, melhor precisão, mais requisições à API
  // - 15 segundos: Balanceado (padrão recomendado)
  // - 20 segundos: Menos frequente, menos requisições, pode ter menos precisão
  static const int _mapMatchingIntervalSeconds = 15;

  // Estado reativo para indicar quando está fazendo Map Matching
  var isApplyingMapMatching = false.obs;

  // Cache de pontos já processados (últimos pontos para evitar reprocessamento)
  final List<mb.Position> _cachedMatchedPoints = [];
  int _lastMatchedIndex = 0; // Índice do último ponto processado

  // Estatísticas da corrida atual
  var currentDistance = 0.0.obs; // em metros
  var currentDuration = Duration.zero.obs;
  var startTime = Rxn<DateTime>();

  // Área atual do usuário
  var currentArea = 'Carregando...'.obs;
  var areaStatus = 'Livre'.obs; // Livre, Contestado, Capturado

  // Território selecionado (clicado) - armazena as properties do território
  var selectedTerritory = Rxn<Map<String, dynamic>>();

  // Notificações para foreground service (rastreamento em background)
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  static const int _notificationId = 1001;

  // Caminho da imagem capturada do trajeto (para salvar junto com a corrida)
  File? _capturedRunImagePath;
  // Caminho da imagem do mapa sem informações (3:4)
  File? _capturedRunMapOnlyImagePath;
  final RxBool isRunSummaryVisible = false.obs;
  final RxBool isRunSummaryLoading = false.obs;
  final RxBool isSavingRun = false.obs;
  final RxBool isTerritoryPending = false.obs;
  bool _hasClosedCircuit = false;
  bool _snapshotDebugEnabled = false;
  final Rxn<DateTime> endTime = Rxn<DateTime>();
  final TextEditingController runCaptionController = TextEditingController();
  bool _isMapDisposed = false;

  // Flag para evitar múltiplas execuções simultâneas de _saveTerritory()
  bool _isSavingTerritory = false;

  /// Método chamado quando o controller é inicializado
  /// Inicia o rastreamento básico de localização
  /// Aguarda os serviços estarem totalmente inicializados antes de usá-los
  @override
  Future<void> onInit() async {
    super.onInit();

    // IMPORTANTE: Aguarda os serviços estarem registrados e inicializados
    // O TerritoryService foi criado com Get.put() no MapBinding
    // O UserService foi criado com Get.put() no main.dart
    // Ambos têm onInit() assíncrono que precisa ser completado

    // Aguarda o TerritoryService estar registrado
    int attempts = 0;
    while (!Get.isRegistered<TerritoryService>() && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    // Inicializa o MapMatchingService
    _mapMatchingService = MapMatchingService();

    if (Get.isRegistered<TerritoryService>()) {
      _territoryService = Get.find<TerritoryService>();
    } else {
      print('ERRO: TerritoryService não está registrado após tentativas');
    }

    // O UserService já deve estar registrado no main.dart
    if (Get.isRegistered<UserService>()) {
      _userService = Get.find<UserService>();
    } else {
      print('ERRO: UserService não está registrado');
    }

    // Inicializa o serviço de Directions para road snapping
    _directionsService = DirectionsService();

    // Inicializa notificações para foreground service
    await _initializeNotifications();

    // Inicia o rastreamento básico de localização
    _startLocationTracking();
  }

  /// Inicializa o sistema de notificações para foreground service
  /// Permite rastreamento GPS mesmo com tela bloqueada
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      // Configuração para Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // Configuração para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Quando usuário toca na notificação, pode abrir o app
          // Por enquanto não faz nada, mas pode implementar navegação
        },
      );

      _notificationsInitialized = true;
      print('✅ Notificações inicializadas para foreground service');
    } catch (e) {
      print('⚠️ Erro ao inicializar notificações: $e');
      // Não é crítico - app continua funcionando
    }
  }

  /// Mostra notificação persistente durante a corrida
  /// Isso mantém o app rodando em background mesmo com tela bloqueada
  Future<void> _showTrackingNotification() async {
    if (!_notificationsInitialized) {
      await _initializeNotifications();
    }

    try {
      // Solicita permissão de notificação no Android 13+
      if (await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ==
          true) {
        print('✅ Permissão de notificação concedida');
      }

      // Cria canal de notificação para Android
      const androidChannel = AndroidNotificationChannel(
        'location_tracking_channel',
        'Rastreamento de Localização',
        description:
            'Notificação mostrando que o GPS está sendo rastreado durante a corrida',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      // Registra o canal (Android 8.0+)
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // Atualiza notificação periodicamente com estatísticas
      _updateTrackingNotification();
    } catch (e) {
      print('⚠️ Erro ao mostrar notificação: $e');
    }
  }

  /// Atualiza a notificação com estatísticas atuais da corrida
  Future<void> _updateTrackingNotification() async {
    if (!_notificationsInitialized) return;

    try {
      final distanceText = currentDistance.value >= 1000
          ? '${(currentDistance.value / 1000).toStringAsFixed(2)} km'
          : '${currentDistance.value.toStringAsFixed(0)} m';

      final duration = currentDuration.value;
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

      const androidDetails = AndroidNotificationDetails(
        'location_tracking_channel',
        'Rastreamento de Localização',
        channelDescription:
            'Notificação mostrando que o GPS está sendo rastreado durante a corrida',
        importance: Importance.high,
        priority: Priority.high,
        ongoing:
            true, // Notificação persistente (não pode ser removida pelo usuário)
        autoCancel: false,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public, // Visível na tela bloqueada
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _notificationId,
        '🏃 Corrida em Andamento',
        'Distância: $distanceText | Tempo: $timeText',
        notificationDetails,
      );
    } catch (e) {
      print('⚠️ Erro ao atualizar notificação: $e');
    }
  }

  /// Remove a notificação de rastreamento
  Future<void> _hideTrackingNotification() async {
    if (!_notificationsInitialized) return;

    try {
      await _notifications.cancel(_notificationId);
      print('✅ Notificação de rastreamento removida');
    } catch (e) {
      print('⚠️ Erro ao remover notificação: $e');
    }
  }

  /// Método chamado quando o controller é destruído
  /// Cancela todas as subscriptions e timers para evitar vazamento de memória
  @override
  void onClose() {
    _positionStream?.cancel();
    // Remove notificação e desativa wakelock
    _hideTrackingNotification();
    WakelockPlus.disable();
    _locationTrackingStream?.cancel();
    _runTimer?.cancel();
    _mapMatchingTimer?.cancel();
    _cameraChangeCheckTimer?.cancel();
    _removeRunPathFromMap();
    mapboxMap = null;
    _isMapDisposed = true;
    super.onClose();
  }

  /// Inicia o rastreamento básico de localização do usuário
  /// Atualiza a variável reativa currentLocation sempre que há uma nova posição
  /// Configurado para alta precisão e atualização a cada 2 metros
  void _startLocationTracking() {
    // Tenta obter a localização atual imediatamente
    _getCurrentLocationAndCenter();

    // Configura stream de GPS com alta precisão
    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 2, // Atualiza a cada 2 metros
    );

    _locationTrackingStream =
        geo.Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (geo.Position position) {
            // Atualiza localização reativa
            currentLocation.value = mb.Point(
              coordinates: mb.Position(position.longitude, position.latitude),
            );

            // Log da primeira localização recebida do stream
            if (!_hasCenteredOnUser) {
              print('🎉 PRIMEIRA localização GPS recebida do stream!');
              print(
                '📍 Posição: [${position.longitude}, ${position.latitude}]',
              );
              print(
                '   - Precisão: ${position.accuracy}m | Velocidade: ${position.speed}m/s',
              );
            }

            // Centraliza mapa na primeira localização
            if (mapboxMap != null &&
                !_hasCenteredOnUser &&
                currentLocation.value != null) {
              print('🗺️  Centralizando mapa na primeira localização...');
              _centerMapOnLocation(currentLocation.value!);
              _hasCenteredOnUser = true;
              print('✅ Mapa centralizado na localização do usuário');
            }
          },
          onError: (error) {
            print('❌ Erro no stream de GPS: $error');
            print('   ℹ️  Stream continuará tentando...');
          },
          cancelOnError: false,
        );

    print('✅ Stream de GPS configurado e ativo');
  }

  // Flag para controlar se já centralizou o mapa na localização do usuário
  bool _hasCenteredOnUser = false;

  // Flag para evitar chamadas simultâneas de _getCurrentLocationAndCenter
  bool _isGettingLocation = false;

  /// Obtém a localização atual do usuário e centraliza o mapa
  /// Tenta obter a localização imediatamente com fallback em cascata
  Future<void> _getCurrentLocationAndCenter() async {
    if (_isGettingLocation) return;
    _isGettingLocation = true;

    try {
      // Verifica permissões e GPS
      if (!await handleLocationPermission()) return;
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        Get.snackbar(
          "GPS Desabilitado",
          "Por favor, habilite o GPS nas configurações",
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Tenta obter localização com fallback em cascata
      geo.Position? position;

      // 1. Alta precisão (20s)
      try {
        position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ).timeout(const Duration(seconds: 20));
      } catch (_) {
        // 2. Precisão média (15s)
        try {
          position = await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ).timeout(const Duration(seconds: 15));
        } catch (_) {
          // 3. Última localização conhecida (cached)
          position = await geo.Geolocator.getLastKnownPosition();
        }
      }

      // Se obteve localização, atualiza e centraliza mapa
      if (position != null) {
        final location = mb.Point(
          coordinates: mb.Position(position.longitude, position.latitude),
        );
        currentLocation.value = location;

        if (mapboxMap != null) {
          _centerMapOnLocation(location);
          _hasCenteredOnUser = true;
        }
      }
    } catch (e) {
      // Erro não crítico - stream continuará tentando
      if (e.toString().contains('PERMISSION_DENIED')) {
        Get.snackbar(
          "Permissão Negada",
          "É necessário permitir o acesso à localização",
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isGettingLocation = false;
    }
  }

  /// Centraliza o mapa em uma localização específica
  /// [location] - A localização (Point) para onde centralizar
  Future<void> _centerMapOnLocation(mb.Point location) async {
    if (mapboxMap == null || _isMapDisposed) return;

    try {
      await mapboxMap!.flyTo(
        mb.CameraOptions(
          center: location,
          zoom: 16.0, // Zoom adequado para ver a área local
          bearing: 0, // Rotação (0 = Norte)
          pitch: 0, // Inclinação (0 = Olhando de cima)
        ),
        mb.MapAnimationOptions(duration: 1000), // Animação suave de 1 segundo
      );
      print("Mapa centralizado na localização do usuário");
    } catch (e) {
      print("Erro ao centralizar mapa: $e");
    }
  }

  /// Verifica e solicita permissões de localização do usuário
  /// Primeiro verifica a permissão básica (enquanto o app está aberto)
  /// Depois tenta solicitar permissão para uso em segundo plano (se necessário)
  /// Retorna true se a permissão foi concedida, false caso contrário
  Future<bool> handleLocationPermission() async {
    geo.LocationPermission permission;

    // 1. Verifica a permissão atual
    permission = await geo.Geolocator.checkPermission();

    // 2. Se a permissão foi negada, solicita ao usuário
    if (permission == geo.LocationPermission.denied) {
      // Isso vai abrir a primeira janelinha de permissão
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        print("Usuário recusou a permissão básica.");
        return false;
      }
    }

    // 3. Se a permissão foi negada permanentemente, sugere abrir configurações
    if (permission == geo.LocationPermission.deniedForever) {
      print(
        "Permissão negada permanentemente. Usuário precisa habilitar nas configurações.",
      );
      await _showOpenSettingsDialog(
        title: 'Permissão de localização',
        message:
            'Para usar o NUR corretamente, precisamos da localização em "Sempre". Abra as configurações e habilite.',
      );
      return false;
    }

    // 4. Se tem permissão "enquanto em uso", tenta solicitar permissão "sempre"
    // Nota: No Android 11+, isso geralmente leva o usuário para a tela de configurações do sistema
    if (permission == geo.LocationPermission.whileInUse) {
      print("Pedindo permissão para rodar em segundo plano...");
      final shouldRequestAlways = await _showAlwaysPermissionDialog();
      if (shouldRequestAlways) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.whileInUse) {
          await _showOpenSettingsDialog(
            title: 'Ativar localização sempre',
            message:
                'O sistema não permitiu "Sempre". Abra as configurações e ative manualmente.',
          );
        }
      }
    }

    // 5. Retorna true se a permissão foi concedida (sempre ou enquanto em uso)
    if (permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse) {
      print("Tudo pronto! Permissão concedida.");
      return true;
    }

    // 6. Se chegou aqui, a permissão não foi concedida
    return false;
  }

  Future<bool> _showAlwaysPermissionDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Permitir localização sempre'),
        content: const Text(
          'Para registrar corridas corretamente e capturar territórios, '
          'precisamos da localização definida como "Sempre".',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Ativar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  Future<void> _showOpenSettingsDialog({
    required String title,
    required String message,
  }) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await geo.Geolocator.openAppSettings();
              Get.back();
            },
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Callback chamado quando o mapa é criado
  /// Configura o ícone de localização personalizado (círculo laranja)
  /// Habilita o componente de localização do Mapbox com animação de pulso
  /// Centraliza o mapa na localização do usuário se já estiver disponível
  /// Inicializa o gerenciador de anotações de polyline para desenhar trajetos
  /// Nota: O estilo do mapa é definido no MapWidget através do parâmetro styleUri
  /// PRIORIDADE: Configura GPS primeiro, depois carrega desenhos em background
  Future<void> onMapCreated(mb.MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    _isMapDisposed = false;

    // ============================================================
    // 1. PRIORIDADE MÁXIMA: ATIVE O GPS PRIMEIRO (ANTES DE TUDO)
    // ============================================================
    // O LocationComponent do Mapbox deve ser configurado ANTES de qualquer desenho
    // para evitar conflitos com o geolocator que já está rodando no onInit
    try {
      final userColor = _getUserColor();

      // Tenta criar ícone com foto de perfil, se não houver usa círculo colorido
      /*      Uint8List iconBytes;
      final profileImageBytes = await _createProfileImageIcon();
      if (profileImageBytes != null) {
        iconBytes = profileImageBytes;
        print("✅ Usando foto de perfil como ícone de localização");
      } else {
        iconBytes = await _createCircleImage(userColor);
        print("✅ Usando círculo colorido como ícone de localização");
      }*/

      final iconBytes = await _createCircleImage(userColor);

      await mapboxMap.location.updateSettings(
        mb.LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: userColor.value,
          locationPuck: mb.LocationPuck(
            locationPuck2D: mb.LocationPuck2D(topImage: iconBytes),
          ),
        ),
      );
      print("✅ LocationComponent configurado com sucesso");
    } catch (e) {
      print("❌ Erro ao configurar LocationComponent: $e");
    }

    // ============================================================
    // DESABILITA ELEMENTOS VISUAIS DO MAPA (BÚSSOLA E ZOOM)
    // ============================================================
    try {
      // Desabilita a bússola no canto superior direito
      await mapboxMap.compass.updateSettings(
        mb.CompassSettings(enabled: false),
      );

      await mapboxMap.scaleBar.updateSettings(
        mb.ScaleBarSettings(enabled: false),
      );

      // Desabilita a atribuição padrão do Mapbox para criar botão customizado
      await mapboxMap.attribution.updateSettings(
        mb.AttributionSettings(enabled: false),
      );

      // Desabilita o logo/marca d'água do Mapbox (informações serão exibidas no BottomSheet customizado)
      await mapboxMap.logo.updateSettings(mb.LogoSettings(enabled: false));

      print("✅ Bússola, atribuição padrão e logo desabilitados");
    } catch (e) {
      print("⚠️ Erro ao desabilitar elementos visuais do mapa: $e");
      // Não é crítico - continuamos mesmo se falhar
    }

    // Centraliza mapa se já temos localização
    if (currentLocation.value != null && !_hasCenteredOnUser) {
      _centerMapOnLocation(currentLocation.value!);
      _hasCenteredOnUser = true;
    }

    // ============================================================
    // 2. INICIALIZA MANAGERS (rápido, não bloqueia)
    // ============================================================
    _polylineAnnotationManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();

    try {
      _polygonAnnotationManager = await mapboxMap.annotations
          .createPolygonAnnotationManager();
    } catch (e) {
      // Ignora erro se já existir (hot reload)
    }

    // ============================================================
    // 3. CARREGA DESENHOS EM BACKGROUND (não bloqueia GPS)
    // ============================================================
    // Desenhos pesados rodam em background para não travar o GPS
    // Usa microtask para dar prioridade ao GPS, mas não bloqueia
    Future.microtask(() async {
      try {
        // Aguarda estilo do mapa estar pronto (só quando necessário)
        await Future.delayed(const Duration(milliseconds: 200));

        // Inicializa layers
        await _initializeTrailLayer();
        await _initializeTerritoriesLayer();

        // Carrega territórios (pode demorar por causa da API)
        // Esta chamada é assíncrona e não bloqueia o GPS
        await _loadAndDrawTerritories();

        // Inicia timer para verificar mudanças na câmera e recarregar territórios
        _startCameraChangeCheckTimer();

        // Desenha território específico
        await _drawTerritoryFromSpecificWaypoints();
      } catch (e) {
        // Erros nos desenhos não devem bloquear o GPS
        print("⚠️ Erro ao carregar desenhos (GPS continua funcionando): $e");
      }
    });
  }

  /// Manipula cliques no mapa para detectar territórios
  /// Usa queryRenderedFeatures para identificar qual território foi clicado
  Future<void> handleMapTap(mb.MapContentGestureContext context) async {
    if (mapboxMap == null) return;

    try {
      // Obtém coordenadas de tela do tap
      final screenCoordinate = mb.ScreenCoordinate(
        x: context.touchPosition.x.toDouble(),
        y: context.touchPosition.y.toDouble(),
      );

      // Cria a geometria de query a partir da coordenada de tela
      final queryGeometry = mb.RenderedQueryGeometry.fromScreenCoordinate(
        screenCoordinate,
      );

      // Query para features renderizadas na camada de territórios
      final features = await mapboxMap!.queryRenderedFeatures(
        queryGeometry,
        mb.RenderedQueryOptions(layerIds: [_territoriesLayerId]),
      );

      if (features.isNotEmpty) {
        // Território foi clicado
        final queriedFeature = features.first;
        if (queriedFeature == null) {
          selectedTerritory.value = null;
          return;
        }

        final queriedFeatureData = queriedFeature.queriedFeature;
        final feature = queriedFeatureData.feature;

        if (feature.isNotEmpty) {
          // Obtém o ID da feature
          final featureId = feature['id'];

          if (featureId != null) {
            // Busca a feature completa na lista usando o ID
            try {
              final territoryFeature = _territoriesFeatures.firstWhere(
                (f) => f['id'].toString() == featureId.toString(),
              );

              if (territoryFeature['properties'] != null) {
                selectedTerritory.value = Map<String, dynamic>.from(
                  territoryFeature['properties'],
                );
                print(
                  '✅ Território clicado: ${selectedTerritory.value?['owner']}',
                );
              } else {
                selectedTerritory.value = null;
              }
            } catch (e) {
              // Se não encontrou na lista, tenta usar as properties diretamente do feature
              final properties = feature['properties'];
              if (properties != null && properties is Map) {
                selectedTerritory.value = Map<String, dynamic>.from(properties);
                print(
                  '✅ Território clicado (direto): ${selectedTerritory.value?['owner']}',
                );
              } else {
                selectedTerritory.value = null;
              }
            }
          } else {
            selectedTerritory.value = null;
          }
        } else {
          selectedTerritory.value = null;
        }
      } else {
        // Nenhum território foi clicado, limpa seleção
        selectedTerritory.value = null;
      }
    } catch (e, stackTrace) {
      print('⚠️ Erro ao processar clique no mapa: $e');
      print('Stack trace: $stackTrace');
      selectedTerritory.value = null;
    }
  }

  /// Obtém a cor do usuário atual ou retorna a cor padrão
  /// Converte a string hexadecimal para Color
  /// Retorna a cor do usuário se disponível, senão retorna a cor padrão
  Color _getUserColor() {
    try {
      final user = _userService.currentUser.value;
      if (user?.color != null && user!.color!.isNotEmpty) {
        // Converte a string hexadecimal para Color
        return _hexToColor(user.color!);
      }
    } catch (e) {
      print('Erro ao obter cor do usuário: $e');
    }
    // Retorna a cor padrão se não houver cor do usuário
    return AppColors.accentBlue;
  }

  /// Converte string hexadecimal para Color
  /// [hexString] - String no formato hexadecimal (ex: "#00E5FF" ou "00E5FF" - era "#7B2CBF")
  /// Retorna a cor correspondente ou a cor padrão se inválida
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff'); // Adiciona alpha se não tiver
      }
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      print('Erro ao converter cor hexadecimal: $e');
      return AppColors.accentBlue; // Retorna cor padrão em caso de erro
    }
  }

  /// Cria uma imagem de círculo colorido dinamicamente
  /// Usa Canvas do Flutter para desenhar um círculo e converter para bytes PNG
  /// Retorna os bytes da imagem que podem ser usados como ícone no mapa
  /// [color] - A cor do círculo a ser desenhado
  Future<Uint8List> _createCircleImage(Color color) async {
    // Cria um recorder para capturar o desenho
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    // Desenha um círculo de 40 pixels (raio de 20 pixels)
    canvas.drawCircle(const Offset(20, 20), 20, paint);

    // Finaliza o desenho e converte para imagem
    final picture = recorder.endRecording();
    final img = await picture.toImage(40, 40);

    // Converte a imagem para bytes PNG
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Cria uma imagem circular a partir da foto de perfil do usuário
  /// Se não houver foto, retorna null para usar o círculo colorido
  /// Retorna os bytes da imagem que podem ser usados como ícone no mapa
  Future<Uint8List?> _createProfileImageIcon() async {
    try {
      final user = _userService.currentUser.value;
      if (user?.photoUrl == null || user!.photoUrl!.isEmpty) {
        return null; // Não tem foto, usará círculo colorido
      }

      // Monta a URL completa da foto
      String photoUrl = user.photoUrl!;
      if (!photoUrl.startsWith('http')) {
        photoUrl = '${ApiConstants.baseUrl}$photoUrl';
      }

      // Faz download da imagem
      final response = await http
          .get(Uri.parse(photoUrl))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Timeout ao carregar foto de perfil');
            },
          );

      if (response.statusCode != 200) {
        print(
          '⚠️  Erro ao carregar foto de perfil: Status ${response.statusCode}',
        );
        return null; // Fallback para círculo colorido
      }

      // Decodifica e redimensiona a imagem para 40x40 (mesmo tamanho do círculo)
      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: 40,
        targetHeight: 40,
      );
      final frame = await codec.getNextFrame();
      final resizedImage = frame.image;

      // Cria um canvas para desenhar a imagem circular
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = 40.0;

      // Clippa para formato circular
      final clipPath = Path()..addOval(Rect.fromLTWH(0, 0, size, size));
      canvas.clipPath(clipPath);

      // Desenha a imagem redimensionada
      canvas.drawImageRect(
        resizedImage,
        Rect.fromLTWH(
          0,
          0,
          resizedImage.width.toDouble(),
          resizedImage.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size, size),
        Paint(),
      );

      // Adiciona borda colorida (opcional, para destacar)
      final userColor = _getUserColor();
      final borderPaint = Paint()
        ..color = userColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1, borderPaint);

      // Finaliza o desenho e converte para bytes PNG
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Libera recursos
      resizedImage.dispose();
      finalImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('⚠️  Erro ao criar ícone de foto de perfil: $e');
      return null; // Fallback para círculo colorido em caso de erro
    }
  }

  /// Centraliza a câmera do mapa na localização atual do usuário
  /// Usa animação de voo (flyTo) para uma transição suave
  /// Mostra uma mensagem se a localização ainda não foi obtida
  void centerUser() {
    if (mapboxMap != null && currentLocation.value != null) {
      _centerMapOnLocation(currentLocation.value!);
    } else {
      // Se não temos a localização ainda, tenta obter
      _getCurrentLocationAndCenter();
      if (currentLocation.value == null) {
        Get.snackbar("Aguarde", "Ainda não obtivemos sua localização.");
      }
    }
  }

  /// Inicia a gravação de uma corrida
  /// Verifica permissões, limpa o caminho anterior e começa a rastrear posições
  /// Adiciona cada nova posição ao currentRunPath e faz a câmera seguir o usuário
  /// Inicia o cronômetro e começa a desenhar o trajeto no mapa
  void startRun() async {
    // Verifica se tem permissão de localização
    bool hasPermission = await handleLocationPermission();

    if (hasPermission == true) {
      isTracking.value = true;
      currentRunPath.clear(); // Limpa rastro anterior
      _rawGpsPoints.clear(); // Limpa pontos GPS brutos
      _cachedMatchedPoints.clear(); // Limpa cache
      _lastMatchedIndex = 0; // Reseta índice do cache
      currentDistance.value = 0.0;
      currentDuration.value = Duration.zero;
      startTime.value = DateTime.now();
      _lastSnappedPoint = null; // Reseta o último ponto snapado
      isApplyingMapMatching.value = false; // Reseta indicador
      _hasClosedCircuit = false;

      // Remove qualquer trajeto anterior do mapa
      _removeRunPathFromMap();

      // IMPORTANTE: Ativa recursos para funcionar em background
      // 1. Ativa wakelock para manter CPU ativo (evita que sistema suspenda)
      try {
        await WakelockPlus.enable();
        print('✅ Wakelock ativado - app continuará rodando em background');
      } catch (e) {
        print('⚠️ Erro ao ativar wakelock: $e');
      }

      // 2. Mostra notificação persistente (foreground service)
      // Isso mantém o app rodando mesmo com tela bloqueada
      await _showTrackingNotification();
      print('✅ Notificação de rastreamento ativada');

      // Inicia timer para Map Matching periódico (intervalo configurável)
      _startMapMatchingTimer();

      // Inicia o cronômetro que atualiza a cada segundo
      _startRunTimer();

      // Inicia timer para atualizar notificação periodicamente
      _startNotificationUpdateTimer();

      // Cancela o rastreamento básico para evitar conflitos
      _locationTrackingStream?.cancel();

      // Solicita permissão de localização em background (Android 10+)
      // IMPORTANTE: Isso permite rastreamento mesmo com tela bloqueada
      if (await geo.Geolocator.checkPermission() ==
          geo.LocationPermission.whileInUse) {
        print(
          '⚠️ Permissão apenas "enquanto em uso" - solicitando "sempre" para background...',
        );
        // Tenta solicitar permissão "sempre" (pode levar usuário para configurações)
        final permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.always) {
          print(
            '✅ Permissão "sempre" concedida - rastreamento funcionará em background',
          );
        } else {
          print(
            '⚠️ Permissão "sempre" não concedida - rastreamento pode parar com tela bloqueada',
          );
          Get.snackbar(
            'Permissão de Background',
            'Para rastrear com tela bloqueada, permita acesso "sempre" nas configurações',
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          );
        }
      }

      // Começa a "escutar" o GPS em tempo real durante a corrida
      // IMPORTANTE: Usamos road snapping para que o caminho siga as ruas
      // Isso garante que o polígono não corte por cima de construções
      _positionStream =
          geo.Geolocator.getPositionStream(
            locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.high, // Alta precisão
              distanceFilter:
                  2, // 2 metros - estilo Strava (1 ponto por segundo)
              // Coleta frequente para rastro suave como migalhas de pão
            ),
          ).listen(
            (geo.Position position) async {
              // Convertemos o 'Position' do Geolocator para o 'Position' do Mapbox
              // IMPORTANTE: Mapbox usa (Longitude, Latitude)
              var gpsPosition = mb.Position(
                position.longitude,
                position.latitude,
              );

              // ESTILO STRAVA: Adiciona o ponto GPS bruto
              // Map Matching será aplicado periodicamente (a cada 15 segundos) para corrigir o trajeto
              await _addGpsPoint(gpsPosition);
            },
            onError: (error) {
              print("Erro ao rastrear posição durante corrida: $error");
            },
          );
    } else {
      Get.snackbar(
        "Permissão Negada",
        "É necessário permitir o acesso à localização para rastrear corridas.",
      );
    }
  }

  /// Inicia timer para atualizar notificação com estatísticas
  void _startNotificationUpdateTimer() {
    _notificationUpdateTimer?.cancel();

    // Atualiza notificação a cada 5 segundos com estatísticas
    _notificationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      if (isTracking.value) {
        _updateTrackingNotification();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> prepareRunStop() async {
    if (!isTracking.value) return;

    isRunSummaryLoading.value = true;
    isTracking.value = false;
    _positionStream?.cancel();
    _positionStream = null;

    _runTimer?.cancel();
    _runTimer = null;

    _mapMatchingTimer?.cancel();
    _mapMatchingTimer = null;

    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;

    await _hideTrackingNotification();
    try {
      await WakelockPlus.disable();
      print('✅ Wakelock desativado');
    } catch (e) {
      print('⚠️ Erro ao desativar wakelock: $e');
    }

    try {
      if (_rawGpsPoints.isNotEmpty && !isApplyingMapMatching.value) {
        print('🔄 Aplicando Map Matching final antes de mostrar resumo...');
        await _applyMapMatching();
        print('✅ Map Matching final concluído');
      }

      _lastSnappedPoint = null;
      endTime.value = DateTime.now();
      isTerritoryPending.value = _hasClosedCircuit || _isClosedCircuit();

      if (currentRunPath.isNotEmpty) {
        final storyImagePath = await _captureMapSnapshot(
          width: 540,
          height: 960,
          addInfo: true,
          fileSuffix: 'story',
        );
        final mapOnlyImagePath = await _captureMapSnapshot(
          width: 600,
          height: 800,
          addInfo: false,
          fileSuffix: 'map',
          isTerritory: isTerritoryPending.value,
        );
        if (storyImagePath != null) {
          _capturedRunImagePath = storyImagePath;
        }
        if (mapOnlyImagePath != null) {
          _capturedRunMapOnlyImagePath = mapOnlyImagePath;
        }
      }
    } catch (e) {
      print('❌ Erro ao preparar resumo da corrida: $e');
    } finally {
      isRunSummaryLoading.value = false;
    }

    isRunSummaryVisible.value = true;
  }

  Future<void> saveStoppedRun() async {
    if (isSavingRun.value) return;
    isSavingRun.value = true;

    try {
      final stopTime = endTime.value ?? DateTime.now();

      final wasBattleHandled = await _submitBattleResultIfActive(stopTime);
      if (wasBattleHandled) {
        _resetRunStateAfterSave();
        return;
      }

      if (isTerritoryPending.value) {
        await _saveTerritoryCapture();
      } else if (!_isSavingTerritory &&
          currentRunPath.isNotEmpty &&
          startTime.value != null) {
        await _saveSimpleRun(stopTime);
      } else {
        _showRunSaveUnavailable();
      }

      _resetRunStateAfterSave();
    } finally {
      isSavingRun.value = false;
    }
  }

  Future<bool> _submitBattleResultIfActive(DateTime stopTime) async {
    try {
      if (!Get.isRegistered<BattleController>()) return false;
      _battleController = Get.find<BattleController>();

      if (!_battleController!.isInBattle.value ||
          currentRunPath.isEmpty ||
          startTime.value == null) {
        return false;
      }

      final durationSeconds = stopTime.difference(startTime.value!).inSeconds;
      final pathPoints = _buildPathPoints(
        baseTimestamp: startTime.value!,
        stopTime: stopTime,
      );

      await _battleController!.submitBattleResult(
        distance: currentDistance.value,
        duration: durationSeconds,
        path: pathPoints,
      );
      print('✅ [BATALHA] Resultado submetido com sucesso');
      return true;
    } catch (e) {
      print('⚠️ [BATALHA] Erro ao verificar batalha ativa: $e');
      return false;
    }
  }

  Future<void> _saveTerritoryCapture() async {
    try {
      await _saveTerritory(skipStopRun: true);
      _closeRunSummaryOverlay();
      _startLocationTracking();
    } catch (e, stackTrace) {
      print('❌ [TERRITÓRIO] Erro ao salvar manualmente: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  Future<void> _saveSimpleRun(DateTime stopTime) async {
    try {
      print('🏃 [CORRIDA] Salvando corrida simples no servidor...');

      final baseTimestamp = startTime.value!;
      final pathPoints = _buildPathPoints(
        baseTimestamp: baseTimestamp,
        stopTime: stopTime,
      );
      final captionText = runCaptionController.text.trim();
      final run = RunModel(
        id: '',
        startTime: baseTimestamp,
        endTime: stopTime,
        path: pathPoints,
        distance: currentDistance.value,
        duration: currentDuration.value,
        caption: captionText.isNotEmpty ? captionText : null,
      );

      final mapImagePath = _capturedRunImagePath;
      final mapImageCleanPath = _capturedRunMapOnlyImagePath;

      await _territoryService.saveSimpleRun(
        run,
        mapImagePath: mapImagePath,
        mapImageCleanPath: mapImageCleanPath,
      );

      if (mapImagePath != null || mapImageCleanPath != null) {
        clearCapturedRunImagePath();
      }

      print('✅ [CORRIDA] Corrida simples salva com sucesso!');
      Get.snackbar(
        'Corrida salva',
        'Sua corrida foi enviada com sucesso.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      print('❌ [CORRIDA] Erro ao salvar corrida simples: $e');
      print('   Stack trace: $stackTrace');
      Get.snackbar(
        'Erro ao salvar',
        'Não foi possível salvar a corrida. Tente novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  List<PositionPoint> _buildPathPoints({
    required DateTime baseTimestamp,
    required DateTime stopTime,
  }) {
    final pathPoints = <PositionPoint>[];
    final totalSeconds = stopTime.difference(baseTimestamp).inSeconds;
    final intervalPerPoint = currentRunPath.length > 1
        ? totalSeconds / (currentRunPath.length - 1)
        : 0.0;

    for (int i = 0; i < currentRunPath.length; i++) {
      final pos = currentRunPath[i];
      final timestamp = baseTimestamp.add(
        Duration(seconds: (i * intervalPerPoint).round()),
      );
      pathPoints.add(
        PositionPoint(
          latitude: pos.lat.toDouble(),
          longitude: pos.lng.toDouble(),
          timestamp: timestamp,
        ),
      );
    }

    return pathPoints;
  }

  void _showRunSaveUnavailable() {
    if (_isSavingTerritory) {
      Get.snackbar(
        'Salvamento em andamento',
        'Um território está sendo processado.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (currentRunPath.isEmpty) {
      Get.snackbar(
        'Corrida vazia',
        'Nenhum trajeto foi registrado.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (startTime.value == null) {
      Get.snackbar(
        'Dados incompletos',
        'Não foi possível determinar o início da corrida.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void discardStoppedRun() {
    _resetRunStateAfterSave();
  }

  void _closeRunSummaryOverlay() {
    isRunSummaryVisible.value = false;
    isTerritoryPending.value = false;
    runCaptionController.clear();
    endTime.value = null;
    startTime.value = null;
  }

  void _resetRunStateAfterSave() {
    isRunSummaryVisible.value = false;
    isTerritoryPending.value = false;
    runCaptionController.clear();
    endTime.value = null;
    _hasClosedCircuit = false;

    currentRunPath.clear();
    _rawGpsPoints.clear();
    _cachedMatchedPoints.clear();
    _lastMatchedIndex = 0;
    _lastSnappedPoint = null;
    currentDistance.value = 0.0;
    currentDuration.value = Duration.zero;
    startTime.value = null;

    _startLocationTracking();
  }

  /// Para a gravação da corrida e limpa o fluxo de dados
  /// Cancela a subscription do GPS, para o cronômetro e reinicia o rastreamento básico
  Future<void> stopRun() async {
    isTracking.value = false;
    _positionStream?.cancel(); // Para de gastar bateria com o GPS
    _positionStream = null;

    // Para o cronômetro
    _runTimer?.cancel();
    _runTimer = null;

    // Para o timer de Map Matching
    _mapMatchingTimer?.cancel();
    _mapMatchingTimer = null;

    // Para o timer de atualização de notificação
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;

    // Remove notificação e desativa wakelock
    await _hideTrackingNotification();
    try {
      await WakelockPlus.disable();
      print('✅ Wakelock desativado');
    } catch (e) {
      print('⚠️ Erro ao desativar wakelock: $e');
    }

    // Faz um Map Matching final com todos os pontos restantes
    // Isso garante que o trajeto final esteja completamente corrigido antes de salvar
    if (_rawGpsPoints.isNotEmpty && !isApplyingMapMatching.value) {
      print('🔄 Aplicando Map Matching final antes de salvar...');
      await _applyMapMatching();
      print('✅ Map Matching final concluído');
    }

    // Reseta o último ponto snapado
    _lastSnappedPoint = null;

    print("Corrida finalizada com ${currentRunPath.length} pontos.");
    print('🔵🔵🔵 [DEBUG] stopRun() - Verificando se deve capturar imagem...');
    print('   - currentRunPath.isNotEmpty: ${currentRunPath.isNotEmpty}');

    // Captura imagens do mapa com o trajeto antes de limpar
    if (currentRunPath.isNotEmpty) {
      try {
        print('📸 [DEBUG] stopRun() - Capturando imagens da corrida...');
        final storyImagePath = await _captureMapSnapshot(
          width: 540,
          height: 960,
          addInfo: true,
          fileSuffix: 'story',
        );
        final mapOnlyImagePath = await _captureMapSnapshot(
          width: 600,
          height: 800,
          addInfo: false,
          fileSuffix: 'map',
        );
        print(
          '🔵🔵🔵 [DEBUG] stopRun() - storyImagePath: $storyImagePath | mapOnlyImagePath: $mapOnlyImagePath',
        );
        if (storyImagePath != null) {
          _capturedRunImagePath = storyImagePath;
          print('✅ Imagem 9:16 capturada: $storyImagePath');
        }
        if (mapOnlyImagePath != null) {
          _capturedRunMapOnlyImagePath = mapOnlyImagePath;
          print('✅ Imagem 3:4 capturada: $mapOnlyImagePath');
        }
        if (storyImagePath == null && mapOnlyImagePath == null) {
          print('⚠️ Não foi possível capturar imagens da corrida');
        }
      } catch (e) {
        print('❌ Erro ao capturar imagem do trajeto: $e');
        // Não impede o fluxo - continua mesmo se a captura falhar
      }
    }

    // Verifica se está em uma batalha ativa
    try {
      if (Get.isRegistered<BattleController>()) {
        _battleController = Get.find<BattleController>();
        if (_battleController!.isInBattle.value &&
            currentRunPath.isNotEmpty &&
            startTime.value != null) {
          print('⚔️ [BATALHA] Submetendo resultado da batalha...');

          // Converte currentRunPath (mb.Position) para PositionPoint
          final pathPoints = <PositionPoint>[];
          final baseTimestamp = startTime.value!;
          final endTime = DateTime.now();
          final durationSeconds = endTime.difference(baseTimestamp).inSeconds;

          // Calcula o intervalo de tempo entre pontos
          final totalSeconds = durationSeconds;
          final intervalPerPoint = currentRunPath.length > 1
              ? totalSeconds / (currentRunPath.length - 1)
              : 0.0;

          for (int i = 0; i < currentRunPath.length; i++) {
            final pos = currentRunPath[i];
            final timestamp = baseTimestamp.add(
              Duration(seconds: (i * intervalPerPoint).round()),
            );
            pathPoints.add(
              PositionPoint(
                latitude: pos.lat.toDouble(),
                longitude: pos.lng.toDouble(),
                timestamp: timestamp,
              ),
            );
          }

          // Submete resultado da batalha
          await _battleController!.submitBattleResult(
            distance: currentDistance.value,
            duration: durationSeconds,
            path: pathPoints,
          );

          print('✅ [BATALHA] Resultado submetido com sucesso');
          // Não salva como corrida simples se foi batalha
          return;
        }
      }
    } catch (e) {
      print('⚠️ [BATALHA] Erro ao verificar batalha ativa: $e');
      // Continua com o fluxo normal se houver erro
    }

    // Verifica se deve salvar como corrida simples (não é território fechado)
    // Se _isSavingTerritory é true, significa que já foi salvo como território
    if (!_isSavingTerritory &&
        currentRunPath.isNotEmpty &&
        startTime.value != null) {
      try {
        print('🏃 [CORRIDA] Salvando corrida simples no servidor...');
        print('   - Pontos no caminho: ${currentRunPath.length}');
        print('   - Distância: ${currentDistance.value.toStringAsFixed(2)} m');
        print('   - Duração: ${currentDuration.value}');

        // Converte currentRunPath (mb.Position) para PositionPoint
        final pathPoints = <PositionPoint>[];
        final baseTimestamp = startTime.value!;
        final endTime = DateTime.now();

        // Calcula o intervalo de tempo entre pontos
        final totalSeconds = endTime.difference(baseTimestamp).inSeconds;
        final intervalPerPoint = currentRunPath.length > 1
            ? totalSeconds / (currentRunPath.length - 1)
            : 0.0;

        for (int i = 0; i < currentRunPath.length; i++) {
          final pos = currentRunPath[i];
          final timestamp = baseTimestamp.add(
            Duration(seconds: (i * intervalPerPoint).round()),
          );
          pathPoints.add(
            PositionPoint(
              latitude: pos.lat.toDouble(),
              longitude: pos.lng.toDouble(),
              timestamp: timestamp,
            ),
          );
        }

        // Cria o modelo da corrida
        final run = RunModel(
          id: '', // Será gerado pelo servidor
          startTime: baseTimestamp,
          endTime: endTime,
          path: pathPoints,
          distance: currentDistance.value,
          duration: currentDuration.value,
        );

        // Obtém o caminho das imagens (se houver)
        final mapImagePath = _capturedRunImagePath;
        final mapImageCleanPath = _capturedRunMapOnlyImagePath;

        // Salva no servidor
        await _territoryService.saveSimpleRun(
          run,
          mapImagePath: mapImagePath,
          mapImageCleanPath: mapImageCleanPath,
        );

        // Limpa o caminho das imagens após enviar
        if (mapImagePath != null || mapImageCleanPath != null) {
          clearCapturedRunImagePath();
          print('✅ [CORRIDA] Imagens enviadas e caminho limpo');
        }

        print('✅ [CORRIDA] Corrida simples salva com sucesso!');
      } catch (e, stackTrace) {
        print('❌ [CORRIDA] Erro ao salvar corrida simples: $e');
        print('   Stack trace: $stackTrace');
        // Não relança o erro - não deve impedir a parada da corrida
      }
    } else {
      if (_isSavingTerritory) {
        print(
          '🏃 [CORRIDA] Já foi salvo como território, não salvando como corrida simples',
        );
      } else if (currentRunPath.isEmpty) {
        print('🏃 [CORRIDA] Caminho vazio, não salvando corrida');
      } else if (startTime.value == null) {
        print('🏃 [CORRIDA] Start time não disponível, não salvando corrida');
      }
    }

    // Limpa os dados da corrida após salvar
    currentRunPath.clear();
    _rawGpsPoints.clear();
    _cachedMatchedPoints.clear();
    _lastMatchedIndex = 0;
    _lastSnappedPoint = null;
    currentDistance.value = 0.0;
    currentDuration.value = Duration.zero;
    startTime.value = null;

    // Reinicia o rastreamento básico de localização
    _startLocationTracking();
  }

  /// Captura uma imagem do mapa mostrando o trajeto da corrida
  /// Usa a API Static Images do Mapbox para gerar a imagem
  /// [width]/[height] definem o formato final
  /// [addInfo] adiciona overlay de informações na imagem
  /// Retorna o caminho do arquivo salvo ou null em caso de erro
  Future<File?> _captureMapSnapshot({
    required int width,
    required int height,
    required bool addInfo,
    required String fileSuffix,
    bool isTerritory = false,
  }) async {
    final bool enableSnapshotDebug = _snapshotDebugEnabled;
    print('🔵🔵🔵 [DEBUG] _captureMapSnapshot() CHAMADA! 🔵🔵🔵');
    print('   - currentRunPath.length: ${currentRunPath.length}');

    if (currentRunPath.isEmpty) {
      print('⚠️ Não é possível capturar: trajeto vazio');
      return null;
    }

    try {
      print('📸 Gerando imagem do trajeto usando Mapbox Static Images API...');
      print('   - Pontos no trajeto: ${currentRunPath.length}');

      // Calcula os limites do trajeto
      double minLat = currentRunPath.first.lat.toDouble();
      double maxLat = currentRunPath.first.lat.toDouble();
      double minLng = currentRunPath.first.lng.toDouble();
      double maxLng = currentRunPath.first.lng.toDouble();

      for (final pos in currentRunPath) {
        final lat = pos.lat;
        final lng = pos.lng;
        if (lat < minLat) minLat = lat.toDouble();
        if (lat > maxLat) maxLat = lat.toDouble();
        if (lng < minLng) minLng = lng.toDouble();
        if (lng > maxLng) maxLng = lng.toDouble();
      }

      // Adiciona padding extra no topo/baixo para evitar o trajeto colado
      // ao limite superior/inferior do mini mapa
      final latPadding = (maxLat - minLat) * 0.35;
      final lngPadding = (maxLng - minLng) * 0.25;

      minLat -= latPadding;
      maxLat += latPadding;
      minLng -= lngPadding;
      maxLng += lngPadding;

      // Calcula o centro
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Monta a URL da API Static Images do Mapbox
      // Formato: https://api.mapbox.com/styles/v1/{username}/{style_id}/static/{overlay}/{lon},{lat},{zoom}/{width}x{height}{@2x}?access_token={token}
      // Para adicionar uma polyline: path-{strokeWidth}+{strokeColor}-{fillColor}({encodedPolyline})
      final mapboxToken = ApiConstants.mapboxAccessToken;
      // Usa estilo dark para foto estática do trajeto
      // Estilos disponíveis: streets-v12, outdoors-v12, light-v11, dark-v11, satellite-v9
      final username = 'mapbox';
      final styleId = 'dark-v11';

      // Formato definido pelos parâmetros (ex: 9:16 ou 3:4)
      final zoom = _calculateOptimalZoom(minLat, maxLat, minLng, maxLng);

      // Cor do trajeto (cor do usuário)
      final user = _userService.currentUser.value;
      final userColorHex = user?.color ?? '#00E5FF';
      // Remove # e converte para formato esperado pela API (sem #)
      final strokeColor = userColorHex.replaceAll('#', '');

      // Simplifica o trajeto de forma adaptativa baseado no tamanho da URL
      // A API Static Images do Mapbox tem limite de 8192 caracteres na URL
      // Usa limite seguro de 7000 caracteres para margem de segurança
      const maxUrlLength = 7000;

      // Para corridas muito longas, começa com menos pontos
      // Isso acelera o processo para trajetos de 10km+ que podem ter milhares de pontos
      int maxPoints = currentRunPath.length > 500 ? 30 : 50;
      print(
        '   📊 Trajeto original: ${currentRunPath.length} pontos → Começando com $maxPoints pontos',
      );

      List<mb.Position> simplifiedPath = _simplifyPathToMaxPoints(
        currentRunPath,
        maxPoints,
      );
      String overlay = _buildOverlayFromPath(
        simplifiedPath,
        strokeColor,
        isTerritory,
      );
      String encodedOverlay = Uri.encodeComponent(overlay);
      // Usa coordenadas explícitas ao invés de 'auto' para garantir que o mapa apareça
      // Formato: /static/{overlay}/{lon},{lat},{zoom}/{width}x{height}
      String url =
          'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';
      int attempts = 0;
      const maxAttempts = 5;

      // Loop adaptativo: reduz pontos até que a URL seja menor que o limite
      while (attempts < maxAttempts && url.length >= maxUrlLength) {
        // URL ainda muito longa, reduz pontos pela metade
        maxPoints = (maxPoints * 0.5).round().clamp(10, maxPoints);
        print(
          '   ⚠️ URL muito longa (${url.length} chars). Reduzindo para $maxPoints pontos...',
        );

        simplifiedPath = _simplifyPathToMaxPoints(currentRunPath, maxPoints);
        print(
          '   📉 Tentativa ${attempts + 1}: Simplificado para ${simplifiedPath.length} pontos',
        );

        overlay = _buildOverlayFromPath(
          simplifiedPath,
          strokeColor,
          isTerritory,
        );
        encodedOverlay = Uri.encodeComponent(overlay);

        // Monta a URL completa
        url =
            'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';

        attempts++;
      }

      if (url.length < maxUrlLength) {
        print(
          '   ✅ URL com tamanho aceitável: ${url.length} caracteres (limite: $maxUrlLength)',
        );
      } else {
        print(
          '   ⚠️ ATENÇÃO: URL ainda muito longa após todas as tentativas (${url.length} chars)',
        );
        print('   📉 Usando mínimo de 10 pontos para tentar gerar imagem...');
        // Última tentativa com mínimo de 10 pontos
        simplifiedPath = _simplifyPathToMaxPoints(currentRunPath, 10);
        overlay = _buildOverlayFromPath(
          simplifiedPath,
          strokeColor,
          isTerritory,
        );
        encodedOverlay = Uri.encodeComponent(overlay);
        url =
            'https://api.mapbox.com/styles/v1/$username/$styleId/static/$encodedOverlay/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';
      }

      print(
        '   📉 Trajeto simplificado final: ${currentRunPath.length} → ${simplifiedPath.length} pontos',
      );

      print(
        '   📍 URL gerada (primeiros 100 chars): ${url.substring(0, url.length > 100 ? 100 : url.length)}...',
      );
      print('   📍 Tamanho da URL: ${url.length} caracteres');
      print(
        '   📍 Token presente: ${mapboxToken.isNotEmpty ? "Sim (${mapboxToken.substring(0, 10)}...)" : "NÃO!"}',
      );
      if (url.length > 100) {
        print(
          '   📍 URL (últimos 100 chars): ...${url.substring(url.length - 100)}',
        );
      }

      // Faz download da imagem
      print('🌐 Fazendo requisição para:');
      print(
        '   URL (primeiros 200 chars): ${url.substring(0, url.length > 200 ? 200 : url.length)}...',
      );
      print('   Style: $username/$styleId');
      print('   Centro: $centerLat, $centerLng');
      print('   Zoom: $zoom');

      if (enableSnapshotDebug) {
        // Testa primeiro sem overlay para verificar se o mapa aparece
        String testUrlWithoutOverlay =
            'https://api.mapbox.com/styles/v1/$username/$styleId/static/$centerLng,$centerLat,$zoom/${width}x$height@2x?access_token=$mapboxToken';
        print(
          '   🧪 Testando URL sem overlay (primeiros 150 chars): ${testUrlWithoutOverlay.substring(0, testUrlWithoutOverlay.length > 150 ? 150 : testUrlWithoutOverlay.length)}...',
        );

        try {
          final testResponse = await http.get(Uri.parse(testUrlWithoutOverlay));
          if (testResponse.statusCode == 200) {
            print(
              '   ✅ Teste sem overlay: Mapa carregou com sucesso (${testResponse.bodyBytes.length} bytes)',
            );
          } else {
            print('   ⚠️ Teste sem overlay: Status ${testResponse.statusCode}');
            print('   ⚠️ Resposta: ${testResponse.body}');
          }
        } catch (e) {
          print('   ⚠️ Erro no teste sem overlay: $e');
        }
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        print('❌ Erro ao baixar imagem: Status ${response.statusCode}');
        print('❌ Resposta do servidor: ${response.body}');
        return null;
      }

      print('✅ Imagem baixada com sucesso: ${response.bodyBytes.length} bytes');

      // Se não precisa adicionar informações, salva direto os bytes do Mapbox
      if (!addInfo) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .split('.')[0];
        final fileName = 'run_${timestamp}_$fileSuffix.png';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('✅ Imagem salva em: $filePath');
        return file;
      }

      // Carrega a imagem usando o pacote image
      final imageBytes = response.bodyBytes;
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print('❌ Erro ao decodificar imagem');
        return null;
      }

      print('✅ Imagem decodificada: ${image.width}x${image.height} pixels');

      // Converte a imagem do pacote 'image' para ui.Image para poder desenhar no canvas
      final uiImageFromBytes = await _convertImageToUiImage(image);
      if (uiImageFromBytes == null) {
        print('❌ Erro ao converter imagem para ui.Image');
        return null;
      }

      if (enableSnapshotDebug) {
        // Verifica se a imagem tem conteúdo (não é apenas transparente/preto)
        int nonTransparentPixels = 0;
        int whitePixels = 0;
        int coloredPixels = 0;
        for (int y = 0; y < image.height; y += 10) {
          for (int x = 0; x < image.width; x += 10) {
            final pixel = image.getPixel(x, y);
            final alpha = pixel.a;
            final red = pixel.r;
            final green = pixel.g;
            final blue = pixel.b;

            if (alpha > 10) {
              nonTransparentPixels++;
              if (red > 240 && green > 240 && blue > 240) {
                whitePixels++;
              } else {
                coloredPixels++;
              }
            }
          }
        }
        print('   📊 Análise da imagem:');
        print('      - Pixels não-transparentes: $nonTransparentPixels');
        print('      - Pixels brancos (fundo): $whitePixels');
        print('      - Pixels coloridos (mapa/trajeto): $coloredPixels');

        if (coloredPixels < 10) {
          print('   ⚠️ ATENÇÃO: Imagem parece estar sem o mapa de fundo!');
          print(
            '   💡 Verifique se o estilo customizado está correto no Mapbox Studio',
          );
        }
      }

      final img.Image finalImage = addInfo
          ? await _addRunInfoToImage(image, uiImageFromBytes)
          : image;

      // Converte a imagem final para bytes
      final modifiedImageBytes = img.encodePng(finalImage);

      // Salva o arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final fileName = 'run_${timestamp}_$fileSuffix.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(modifiedImageBytes);

      print('✅ Imagem salva em: $filePath');

      return file;
    } catch (e, stackTrace) {
      print('❌ Erro ao capturar imagem do trajeto: $e');
      print('Stack trace: $stackTrace');
      return null;
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

  /// Carrega um SVG e renderiza em alta resolução como ui.Image
  /// size: tamanho desejado em pixels (quanto maior, melhor a qualidade)
  Future<ui.Image?> _loadSvgAsUiImage(String assetPath, double size) async {
    try {
      print('   🎨 Carregando SVG: $assetPath em ${size}x${size}px...');

      // Carrega o SVG usando flutter_svg (versão 2.0+)
      final svgString = await rootBundle.loadString(assetPath);

      // Usa a nova API do flutter_svg 2.0
      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      // Obtém as dimensões do SVG
      final pictureSize = pictureInfo.size;
      final svgWidth = pictureSize.width;
      final svgHeight = pictureSize.height;

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
  ) async {
    try {
      print('📝 Adicionando informações à imagem...');

      // Obtém informações do usuário e da corrida
      final user = _userService.currentUser.value;
      final userName = user?.name ?? user?.username ?? 'Corredor';
      final distance = currentDistance.value;
      final duration = currentDuration.value;

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

      // Desenha um fundo semi-transparente para o texto (canto superior esquerdo)
      // Usa preto com 95% de opacidade para melhor visibilidade
      final backgroundPaint = Paint()
        ..color =
            const Color(0xF2000000) // Preto com 95% de opacidade (mais visível)
        ..style = PaintingStyle.fill;
      final backgroundRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 20, 280, 180),
        const Radius.circular(12),
      );
      canvas.drawRRect(backgroundRect, backgroundPaint);

      // Configura o texto com cores mais vibrantes para melhor visibilidade
      // Não especifica fontFamily para usar a fonte padrão do sistema
      final textStyle = const TextStyle(
        color: Color(0xFFFFFFFF), // Branco totalmente opaco
        fontSize: 24,
        fontWeight: FontWeight.bold,
        // fontFamily removido - usa fonte padrão do sistema
        shadows: [
          Shadow(
            color: Color(0xFF000000), // Sombra preta para contraste
            blurRadius: 2.0,
            offset: Offset(1, 1),
          ),
        ],
      );
      final smallTextStyle = const TextStyle(
        color: Color(0xFFFFFFFF), // Branco totalmente opaco
        fontSize: 18,
        fontWeight: FontWeight.normal,
        // fontFamily removido - usa fonte padrão do sistema
        shadows: [
          Shadow(
            color: Color(0xFF000000), // Sombra preta para contraste
            blurRadius: 1.5,
            offset: Offset(1, 1),
          ),
        ],
      );

      // Desenha o nome do usuário
      final userNameParagraph = TextPainter(
        text: TextSpan(text: userName, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      userNameParagraph.layout();
      userNameParagraph.paint(canvas, const Offset(35, 30));

      // Desenha a distância
      final distanceParagraph = TextPainter(
        text: TextSpan(text: distanceKm, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      distanceParagraph.layout();
      distanceParagraph.paint(canvas, const Offset(35, 70));

      // Desenha o tempo
      final timeParagraph = TextPainter(
        text: TextSpan(text: timeText, style: smallTextStyle),
        textDirection: TextDirection.ltr,
      );
      timeParagraph.layout();
      timeParagraph.paint(canvas, const Offset(35, 110));

      // Desenha o pace
      final paceParagraph = TextPainter(
        text: TextSpan(text: paceText, style: smallTextStyle),
        textDirection: TextDirection.ltr,
      );
      paceParagraph.layout();
      paceParagraph.paint(canvas, const Offset(35, 145));

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

  /// Cria uma imagem minimalista da corrida (estilo social media)
  /// Fundo com cor do tema, trajeto como linha simples, estatísticas, logo e nome do app
  /// Formato 9:16 (vertical) para Instagram Stories
  Future<img.Image> _createMinimalistRunImage() async {
    try {
      print('🎨 Criando imagem minimalista da corrida...');

      // Obtém informações do usuário e da corrida
      final user = _userService.currentUser.value;
      final userName = user?.name ?? user?.username ?? 'Corredor';
      final distance = currentDistance.value;
      final duration = currentDuration.value;

      // Formata distância
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

      // Formato 9:16 (vertical) para Instagram Stories
      // 1080x1920 pixels (mesmo formato da imagem do mapa)
      const int width = 1080;
      const int height = 1920;

      // Cria o canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      // 1. Carrega e desenha a imagem de fundo
      try {
        print('   🖼️ Carregando imagem de fundo...');
        final backgroundBytes = await rootBundle.load(
          'assets/images/background_run.png',
        );
        final backgroundCodec = await ui.instantiateImageCodec(
          backgroundBytes.buffer.asUint8List(),
        );
        final backgroundFrame = await backgroundCodec.getNextFrame();
        final backgroundImage = backgroundFrame.image;

        // Desenha a imagem de fundo preenchendo todo o canvas
        canvas.drawImageRect(
          backgroundImage,
          Rect.fromLTWH(
            0,
            0,
            backgroundImage.width.toDouble(),
            backgroundImage.height.toDouble(),
          ),
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Paint()..filterQuality = FilterQuality.high,
        );
        print('   ✅ Imagem de fundo desenhada');
      } catch (e) {
        print('   ⚠️ Erro ao carregar imagem de fundo: $e, usando cor sólida');
        // Fallback: usa cor sólida se a imagem não carregar
        final backgroundPaint = Paint()
          ..color = AppColors.surface
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          backgroundPaint,
        );
      }

      // 2. Desenha o trajeto como uma linha simples (sem mapa)
      if (currentRunPath.isNotEmpty) {
        print(
          '   📍 Desenhando trajeto com ${currentRunPath.length} pontos...',
        );

        // Calcula os limites do trajeto para centralizar e escalar
        double minLat = currentRunPath.first.lat.toDouble();
        double maxLat = currentRunPath.first.lat.toDouble();
        double minLng = currentRunPath.first.lng.toDouble();
        double maxLng = currentRunPath.first.lng.toDouble();

        for (final pos in currentRunPath) {
          final lat = pos.lat;
          final lng = pos.lng;
          if (lat < minLat) minLat = lat.toDouble();
          if (lat > maxLat) maxLat = lat.toDouble();
          if (lng < minLng) minLng = lng.toDouble();
          if (lng > maxLng) maxLng = lng.toDouble();
        }

        // Área para desenhar o trajeto (centro da imagem, deixando espaço para texto e logo)
        const double pathAreaTop =
            600.0; // Espaço aumentado para mais distância das informações
        const double pathAreaBottom = 400.0; // Espaço para logo
        const double pathAreaLeft = 100.0;
        const double pathAreaRight = 100.0;
        final double pathAreaWidth = width - pathAreaLeft - pathAreaRight;
        final double pathAreaHeight = height - pathAreaTop - pathAreaBottom;

        // Calcula escala e offset para centralizar o trajeto
        // Normaliza as coordenadas para desenhar corretamente
        final double latRange = maxLat - minLat;
        final double lngRange = maxLng - minLng;

        // Usa a maior range para manter proporção
        final double maxRange = math.max(latRange, lngRange);
        final double scale = maxRange > 0
            ? (math.min(pathAreaWidth, pathAreaHeight) / maxRange) *
                  0.9 // 90% para padding
            : 1.0;

        final double centerLat = (minLat + maxLat) / 2;
        final double centerLng = (minLng + maxLng) / 2;

        // Offset para centralizar (latitude aumenta para cima, então inverte Y)
        final double offsetX =
            pathAreaLeft + pathAreaWidth / 2 - centerLng * scale;
        final double offsetY =
            pathAreaTop + pathAreaHeight / 2 + centerLat * scale; // Inverte Y

        // Desenha o trajeto como linha
        Color pathColor = AppColors.background; // Ciano vibrante (padrão)

        final pathPaint = Paint()
          ..color = pathColor
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              10.0 // Aumentado para melhor visibilidade
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final path = Path();
        bool isFirst = true;
        for (final pos in currentRunPath) {
          // Normaliza coordenadas relativas ao centro
          final double normalizedLng = (pos.lng - centerLng) * scale;
          final double normalizedLat = (pos.lat - centerLat) * scale;

          // Converte para coordenadas do canvas (inverte Y porque lat aumenta para cima)
          final double x = pathAreaLeft + pathAreaWidth / 2 + normalizedLng;
          final double y = pathAreaTop + pathAreaHeight / 2 - normalizedLat;

          if (isFirst) {
            path.moveTo(x, y);
            isFirst = false;
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, pathPaint);
        print('   ✅ Trajeto desenhado');
      }

      // 3. Desenha estatísticas centralizadas no topo
      double statsTop = 80.0;

      // Estilo para labels (texto pequeno)
      final labelStyle = const TextStyle(
        color: AppColors.surface,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

      // Estilo para valores (texto grande)
      final valueStyle = const TextStyle(
        color: Colors.white,
        fontSize: 72,
        fontWeight: FontWeight.bold,
      );

      // Distância
      final distanceLabel = TextPainter(
        text: TextSpan(text: 'Distância', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      distanceLabel.layout();
      final distanceLabelX = (width - distanceLabel.width) / 2; // Centraliza
      distanceLabel.paint(canvas, Offset(distanceLabelX, statsTop));

      final distanceValue = TextPainter(
        text: TextSpan(text: distanceKm, style: valueStyle),
        textDirection: TextDirection.ltr,
      );
      distanceValue.layout();
      final distanceValueX = (width - distanceValue.width) / 2; // Centraliza
      distanceValue.paint(canvas, Offset(distanceValueX, statsTop + 40));

      statsTop += 180; // Aumentado para mais espaçamento

      // Pace
      final paceLabel = TextPainter(
        text: TextSpan(text: 'Pace', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      paceLabel.layout();
      final paceLabelX = (width - paceLabel.width) / 2; // Centraliza
      paceLabel.paint(canvas, Offset(paceLabelX, statsTop));

      final paceValue = TextPainter(
        text: TextSpan(text: paceText, style: valueStyle),
        textDirection: TextDirection.ltr,
      );
      paceValue.layout();
      final paceValueX = (width - paceValue.width) / 2; // Centraliza
      paceValue.paint(canvas, Offset(paceValueX, statsTop + 40));

      statsTop += 180; // Aumentado para mais espaçamento

      // Tempo
      final timeLabel = TextPainter(
        text: TextSpan(text: 'Tempo', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      timeLabel.layout();
      final timeLabelX = (width - timeLabel.width) / 2; // Centraliza
      timeLabel.paint(canvas, Offset(timeLabelX, statsTop));

      final timeValue = TextPainter(
        text: TextSpan(text: timeText, style: valueStyle),
        textDirection: TextDirection.ltr,
      );
      timeValue.layout();
      final timeValueX = (width - timeValue.width) / 2; // Centraliza
      timeValue.paint(canvas, Offset(timeValueX, statsTop + 40));

      // 4. Carrega e desenha a logo do app (PNG)
      try {
        print('   🎨 Carregando logo PNG...');
        final logoBytes = await rootBundle.load('assets/images/domrun.png');
        final logoCodec = await ui.instantiateImageCodec(
          logoBytes.buffer.asUint8List(),
        );
        final logoFrame = await logoCodec.getNextFrame();
        final logoImage = logoFrame.image;

        // Desenha a logo no canto inferior direito
        const double logoSize = 220.0;
        const double logoRight = 60.0;
        const double logoBottom = 60.0;
        final logoRect = Rect.fromLTWH(
          width - logoRight - logoSize,
          height - logoBottom - logoSize,
          logoSize,
          logoSize,
        );

        // Usa drawImageRect com alta qualidade
        canvas.drawImageRect(
          logoImage,
          Rect.fromLTWH(
            0,
            0,
            logoImage.width.toDouble(),
            logoImage.height.toDouble(),
          ),
          logoRect,
          Paint()..filterQuality = FilterQuality.high,
        );
        print('   ✅ Logo PNG desenhada em alta qualidade');
      } catch (e, stackTrace) {
        print('   ⚠️ Erro ao carregar logo PNG: $e');
        print('   Stack trace: $stackTrace');
      }

      // Finaliza o desenho
      final picture = recorder.endRecording();
      final finalUiImage = await picture.toImage(width, height);
      final byteData = await finalUiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        print('❌ Erro ao converter imagem minimalista para bytes');
        throw Exception('Erro ao converter imagem');
      }

      // Converte para img.Image
      final finalImageBytes = byteData.buffer.asUint8List();
      final finalImage = img.decodeImage(finalImageBytes);

      if (finalImage == null) {
        print('❌ Erro ao decodificar imagem minimalista');
        throw Exception('Erro ao decodificar imagem');
      }

      print(
        '✅ Imagem minimalista criada: ${finalImage.width}x${finalImage.height}',
      );
      return finalImage;
    } catch (e, stackTrace) {
      print('❌ Erro ao criar imagem minimalista: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Simplifica o trajeto para reduzir o tamanho da URL da API Static Images
  /// Mantém primeiro, último e pontos distribuídos uniformemente
  /// Limite: 50 pontos para garantir URLs menores que 2048 caracteres
  List<mb.Position> _simplifyPathForImage(List<mb.Position> path) {
    return _simplifyPathToMaxPoints(path, 50);
  }

  /// Simplifica o trajeto para um número máximo de pontos usando algoritmo de Douglas-Peucker
  /// Mantém pontos que preservam melhor a forma do trajeto original
  List<mb.Position> _simplifyPathToMaxPoints(
    List<mb.Position> path,
    int maxPoints,
  ) {
    if (path.length <= maxPoints) {
      return path;
    }

    if (maxPoints < 2) {
      // Mínimo de 2 pontos (primeiro e último)
      return [path.first, path.last];
    }

    // Se precisamos de exatamente 2 pontos, retorna primeiro e último
    if (maxPoints == 2) {
      return [path.first, path.last];
    }

    // Usa busca binária para encontrar a tolerância (epsilon) que resulta em ~maxPoints
    // Começa com uma tolerância pequena e aumenta até conseguir o número desejado de pontos
    double minEpsilon = 0.0;
    double maxEpsilon = _calculateMaxEpsilon(path);
    double epsilon = maxEpsilon / 2;

    List<mb.Position> result = _douglasPeucker(path, epsilon);

    // Ajusta epsilon para aproximar o número desejado de pontos
    int iterations = 0;
    while (result.length != maxPoints && iterations < 20) {
      if (result.length > maxPoints) {
        // Muito poucos pontos removidos, aumenta epsilon
        minEpsilon = epsilon;
        epsilon = (epsilon + maxEpsilon) / 2;
      } else {
        // Muitos pontos removidos, diminui epsilon
        maxEpsilon = epsilon;
        epsilon = (minEpsilon + epsilon) / 2;
      }

      result = _douglasPeucker(path, epsilon);
      iterations++;

      // Se epsilon ficou muito pequeno, para
      if ((maxEpsilon - minEpsilon) < 1e-10) break;
    }

    // Se ainda tiver mais pontos que o desejado, remove os menos importantes
    if (result.length > maxPoints) {
      result = _reduceToMaxPoints(result, maxPoints);
    }

    return result;
  }

  /// Algoritmo de simplificação Douglas-Peucker
  /// [path] - Lista de pontos a simplificar
  /// [epsilon] - Distância máxima permitida entre um ponto e a linha simplificada (em graus)
  /// Retorna lista simplificada mantendo pontos que preservam a forma do trajeto
  List<mb.Position> _douglasPeucker(List<mb.Position> path, double epsilon) {
    if (path.length <= 2) {
      return List.from(path);
    }

    // Encontra o ponto mais distante da linha entre o primeiro e último ponto
    double maxDistance = 0.0;
    int maxIndex = 0;

    final firstPoint = path.first;
    final lastPoint = path.last;

    for (int i = 1; i < path.length - 1; i++) {
      final distance = _perpendicularDistance(path[i], firstPoint, lastPoint);

      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // Se a distância máxima for maior que epsilon, recursivamente simplifica
    if (maxDistance > epsilon) {
      // Simplifica o segmento antes do ponto mais distante
      final leftSegment = path.sublist(0, maxIndex + 1);
      final leftSimplified = _douglasPeucker(leftSegment, epsilon);

      // Simplifica o segmento depois do ponto mais distante
      final rightSegment = path.sublist(maxIndex);
      final rightSimplified = _douglasPeucker(rightSegment, epsilon);

      // Combina os resultados (remove duplicado do ponto intermediário)
      final result = <mb.Position>[
        ...leftSimplified,
        ...rightSimplified.sublist(
          1,
        ), // Remove o primeiro ponto que já está em leftSimplified
      ];

      return result;
    } else {
      // Todos os pontos estão próximos da linha, remove todos exceto primeiro e último
      return [firstPoint, lastPoint];
    }
  }

  /// Calcula a distância perpendicular de um ponto até uma linha
  /// [point] - Ponto a calcular a distância
  /// [lineStart] - Início da linha
  /// [lineEnd] - Fim da linha
  /// Retorna a distância em graus (aproximação usando fórmula de Haversine)
  double _perpendicularDistance(
    mb.Position point,
    mb.Position lineStart,
    mb.Position lineEnd,
  ) {
    // Calcula a distância usando coordenadas geodésicas
    // Para pequenas distâncias, podemos usar uma aproximação plana
    final dx = lineEnd.lng - lineStart.lng;
    final dy = lineEnd.lat - lineStart.lat;

    // Se a linha é muito curta, retorna distância do ponto ao início
    final lineLengthSq = dx * dx + dy * dy;
    if (lineLengthSq < 1e-10) {
      return _calculateDistanceBetween(point, lineStart);
    }

    // Calcula o parâmetro t que representa a projeção do ponto na linha
    final t =
        ((point.lng - lineStart.lng) * dx + (point.lat - lineStart.lat) * dy) /
        lineLengthSq;

    // Clamp t entre 0 e 1 para estar no segmento
    final clampedT = t.clamp(0.0, 1.0);

    // Calcula o ponto projetado na linha
    final projectedLng = lineStart.lng + clampedT * dx;
    final projectedLat = lineStart.lat + clampedT * dy;
    // mb.Position usa (longitude, latitude) como parâmetros posicionais
    final projectedPoint = mb.Position(projectedLng, projectedLat);

    // Retorna a distância entre o ponto e o ponto projetado
    return _calculateDistanceBetween(point, projectedPoint);
  }

  /// Calcula o epsilon máximo baseado no tamanho do trajeto
  /// Usa uma fração da distância total do trajeto
  double _calculateMaxEpsilon(List<mb.Position> path) {
    if (path.length < 2) return 1.0;

    double totalDistance = 0.0;
    for (int i = 1; i < path.length; i++) {
      totalDistance += _calculateDistanceBetween(path[i - 1], path[i]);
    }

    // Epsilon máximo como 5% da distância total, convertido para graus
    // Aproximação: 1 grau ≈ 111 km
    return (totalDistance * 0.05) / 111000.0;
  }

  /// Reduz a lista de pontos até o máximo desejado removendo pontos menos importantes
  /// Usa uma heurística simples: remove pontos que têm menor impacto visual
  List<mb.Position> _reduceToMaxPoints(List<mb.Position> path, int maxPoints) {
    if (path.length <= maxPoints) {
      return List.from(path);
    }

    // Mantém primeiro e último sempre
    if (maxPoints < 2) {
      return [path.first, path.last];
    }

    // Calcula a "importância" de cada ponto (exceto primeiro e último)
    final importance = <int, double>{};
    for (int i = 1; i < path.length - 1; i++) {
      // Importância é baseada na distância perpendicular dos vizinhos
      final prevPoint = path[i - 1];
      final currPoint = path[i];
      final nextPoint = path[i + 1];

      final distance = _perpendicularDistance(currPoint, prevPoint, nextPoint);
      importance[i] = distance;
    }

    // Ordena por importância (menor primeiro)
    final sortedIndices = importance.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Mantém os pontos mais importantes
    final keepIndices = <int>{0, path.length - 1}; // Primeiro e último sempre
    final toKeep = maxPoints - 2; // Espaços restantes

    for (
      int i = sortedIndices.length - 1;
      i >= sortedIndices.length - toKeep;
      i--
    ) {
      if (i >= 0) {
        keepIndices.add(sortedIndices[i].key);
      }
    }

    // Se ainda faltam pontos, adiciona os mais importantes que faltam
    while (keepIndices.length < maxPoints && keepIndices.length < path.length) {
      for (
        int i = path.length - 1;
        i >= 0 && keepIndices.length < maxPoints;
        i--
      ) {
        if (!keepIndices.contains(i)) {
          keepIndices.add(i);
        }
      }
    }

    // Ordena os índices e cria a lista resultante
    final sortedKeepIndices = keepIndices.toList()..sort();
    return sortedKeepIndices.map((i) => path[i]).toList();
  }

  /// Codifica uma lista de posições em formato polyline (algoritmo do Google)
  String _encodePolyline(List<mb.Position> positions) {
    if (positions.isEmpty) return '';

    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final pos in positions) {
      final lat = (pos.lat * 1e5).round();
      final lng = (pos.lng * 1e5).round();

      final dLat = lat - prevLat;
      final dLng = lng - prevLng;

      _encodeValue(dLat, buffer);
      _encodeValue(dLng, buffer);

      prevLat = lat;
      prevLng = lng;
    }

    return buffer.toString();
  }

  String _buildOverlayFromPath(
    List<mb.Position> path,
    String strokeColor,
    bool isTerritory,
  ) {
    if (!isTerritory || path.length < 3) {
      final polyline = _encodePolyline(path);
      return 'path-5+$strokeColor($polyline)';
    }

    final color = '#$strokeColor';
    final coords = <List<double>>[];
    for (final point in path) {
      coords.add([point.lng.toDouble(), point.lat.toDouble()]);
    }
    if (coords.isNotEmpty) {
      final first = coords.first;
      final last = coords.last;
      final isClosed =
          (first[0] - last[0]).abs() < 0.0000001 &&
          (first[1] - last[1]).abs() < 0.0000001;
      if (!isClosed) {
        coords.add(first);
      }
    }

    final geojson = {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coords],
      },
      'properties': {
        'stroke': color,
        'stroke-width': 3,
        'stroke-opacity': 0.9,
        'fill': color,
        'fill-opacity': 0.35,
      },
    };

    return 'geojson(${jsonEncode(geojson)})';
  }

  /// Codifica um valor para o formato polyline
  void _encodeValue(int val, StringBuffer buffer) {
    var value = val < 0 ? ~(val << 1) : val << 1;
    while (value >= 0x20) {
      buffer.writeCharCode((0x20 | (value & 0x1f)) + 63);
      value >>= 5;
    }
    buffer.writeCharCode(value + 63);
  }

  /// Calcula o zoom ótimo baseado nos limites do trajeto
  double _calculateOptimalZoom(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Fórmula aproximada para calcular zoom
    if (maxDiff > 0.1) return 12.0;
    if (maxDiff > 0.05) return 13.0;
    if (maxDiff > 0.02) return 14.0;
    if (maxDiff > 0.01) return 15.0;
    if (maxDiff > 0.005) return 16.0;
    return 17.0;
  }

  /// Retorna o caminho da imagem capturada do trajeto (se houver)
  /// Usado para salvar junto com os dados da corrida no servidor
  File? getCapturedRunImagePath() {
    return _capturedRunImagePath;
  }

  File? getCapturedRunMapOnlyImagePath() {
    return _capturedRunMapOnlyImagePath;
  }

  /// Limpa o caminho da imagem capturada
  void clearCapturedRunImagePath() {
    _capturedRunImagePath = null;
    _capturedRunMapOnlyImagePath = null;
  }

  /// Adiciona um ponto GPS bruto à lista (estilo Strava)
  /// Os pontos são coletados frequentemente (2 metros) e Map Matching é aplicado periodicamente
  /// [gpsPosition] - A posição GPS bruta do usuário
  Future<void> _addGpsPoint(mb.Position gpsPosition) async {
    try {
      // Se é o primeiro ponto, adiciona diretamente
      if (_lastSnappedPoint == null || _rawGpsPoints.isEmpty) {
        _lastSnappedPoint = gpsPosition;
        _rawGpsPoints.add(gpsPosition);
        currentRunPath.add(
          gpsPosition,
        ); // Adiciona também ao caminho visual imediato

        // Atualiza estatísticas e desenha o trajeto
        _updateRunStats();
        _updateRunPathOnMap();
        _followUser(gpsPosition);
        return;
      }

      // Calcula a distância entre o último ponto e o novo ponto GPS
      final distanceToLast = _calculateDistanceBetween(
        _rawGpsPoints.last,
        gpsPosition,
      );

      // Se a distância for muito pequena (< 1m), ignora para evitar muitos pontos
      if (distanceToLast < 1) {
        return;
      }

      // Adiciona o ponto GPS bruto à lista
      _rawGpsPoints.add(gpsPosition);

      // Adiciona também ao caminho visual imediato (será corrigido pelo Map Matching depois)
      currentRunPath.add(gpsPosition);

      // Atualiza o último ponto
      _lastSnappedPoint = gpsPosition;

      // Atualiza estatísticas (distância)
      _updateRunStats();

      // Desenha/atualiza o trajeto no mapa em tempo real
      _updateRunPathOnMap();

      // Verifica se formou um circuito fechado
      await _checkForClosedCircuit();

      // Move a câmera para seguir o usuário automaticamente
      _followUser(gpsPosition);
    } catch (e) {
      print('❌ Erro ao adicionar ponto GPS: $e');
      // Fallback: adiciona o ponto GPS bruto
      _rawGpsPoints.add(gpsPosition);
      currentRunPath.add(gpsPosition);
      _lastSnappedPoint = gpsPosition;
      _updateRunStats();
      _updateRunPathOnMap();
      _followUser(gpsPosition);
    }
  }

  /// Inicia o timer para fazer Map Matching periódico
  /// Intervalo configurável (padrão: 15 segundos, pode ser ajustado entre 10-20 segundos)
  /// Isso corrige o trajeto GPS "sujo" para seguir exatamente as ruas
  void _startMapMatchingTimer() {
    _mapMatchingTimer?.cancel();

    // Faz Map Matching no intervalo configurado
    _mapMatchingTimer = Timer.periodic(
      const Duration(seconds: _mapMatchingIntervalSeconds),
      (timer) {
        if (isTracking.value && _rawGpsPoints.length >= 5) {
          // Aplica Map Matching apenas se houver pelo menos 5 pontos novos
          // E se não estiver já processando
          if (!isApplyingMapMatching.value) {
            _applyMapMatching();
          }
        } else if (!isTracking.value) {
          // Para o timer se a corrida terminou
          timer.cancel();
        }
      },
    );

    print(
      '⏱️  Timer de Map Matching iniciado (intervalo: ${_mapMatchingIntervalSeconds}s)',
    );
  }

  /// Aplica Map Matching aos pontos GPS brutos coletados
  /// Usa cache para evitar reprocessar pontos já corrigidos
  /// Corrige o trajeto para seguir exatamente as ruas (estilo Strava)
  Future<void> _applyMapMatching() async {
    if (_rawGpsPoints.length < 5) {
      return; // Precisa de pelo menos 5 pontos para fazer matching
    }

    // Verifica se há pontos novos para processar (usando cache)
    if (_lastMatchedIndex >= _rawGpsPoints.length - 1) {
      print(
        '💾 Cache: Nenhum ponto novo para processar (todos já foram corrigidos)',
      );
      return;
    }

    // Marca que está processando (para indicador visual e evitar processamento duplicado)
    isApplyingMapMatching.value = true;

    try {
      // Pega apenas os pontos novos (não processados ainda)
      final newPoints = _rawGpsPoints.sublist(_lastMatchedIndex);

      print(
        '🗺️  Aplicando Map Matching a ${newPoints.length} pontos GPS novos...',
      );
      print(
        '   💾 Cache: ${_lastMatchedIndex} pontos já processados, ${newPoints.length} novos',
      );

      // Faz Map Matching apenas dos pontos novos
      final matchedPoints = await _mapMatchingService.matchPointsBatch(
        points: List.from(newPoints), // Cópia da lista
        profile: 'walking',
      );

      if (matchedPoints.isNotEmpty && matchedPoints.length >= 3) {
        print(
          '   ✅ Map Matching concluído: ${matchedPoints.length} pontos corrigidos',
        );

        // Combina pontos em cache com novos pontos corrigidos
        final allMatchedPoints = <mb.Position>[];

        // Adiciona pontos em cache (já corrigidos anteriormente)
        if (_cachedMatchedPoints.isNotEmpty) {
          allMatchedPoints.addAll(_cachedMatchedPoints);

          // Remove duplicação entre cache e novos pontos (se o último do cache for igual ao primeiro dos novos)
          if (allMatchedPoints.isNotEmpty && matchedPoints.isNotEmpty) {
            final lastCached = allMatchedPoints.last;
            final firstNew = matchedPoints.first;

            final distance = _calculateDistanceBetween(lastCached, firstNew);
            if (distance < 5.0) {
              // Pula o primeiro ponto dos novos se for muito próximo do último em cache
              allMatchedPoints.addAll(matchedPoints.skip(1));
            } else {
              allMatchedPoints.addAll(matchedPoints);
            }
          }
        } else {
          allMatchedPoints.addAll(matchedPoints);
        }

        // Atualiza o cache com todos os pontos corrigidos
        _cachedMatchedPoints.clear();
        _cachedMatchedPoints.addAll(allMatchedPoints);

        // Atualiza o índice do último ponto processado
        _lastMatchedIndex = _rawGpsPoints.length;

        // Substitui o caminho atual pelos pontos corrigidos
        currentRunPath.clear();
        currentRunPath.addAll(allMatchedPoints);

        // Limpa os pontos GPS brutos antigos (mantém apenas os últimos 20 para continuidade)
        // Isso ajuda a manter o cache eficiente
        if (_rawGpsPoints.length > 20 && _lastMatchedIndex > 10) {
          final keepPoints = _rawGpsPoints.sublist(_rawGpsPoints.length - 20);
          final removedCount = _rawGpsPoints.length - keepPoints.length;
          _rawGpsPoints.clear();
          _rawGpsPoints.addAll(keepPoints);

          // Ajusta o índice do último processado
          _lastMatchedIndex = _lastMatchedIndex - removedCount;
          if (_lastMatchedIndex < 0) _lastMatchedIndex = 0;

          print(
            '   🧹 Limpeza: ${removedCount} pontos GPS brutos antigos removidos',
          );
        }

        // Atualiza as estatísticas com o caminho corrigido
        _updateRunStats();

        // Atualiza o trajeto no mapa com os pontos corrigidos
        _updateRunPathOnMap();

        print('   🎨 Trajeto corrigido e atualizado no mapa (estilo Strava)');
        print(
          '   💾 Cache atualizado: ${_cachedMatchedPoints.length} pontos em cache',
        );
      } else {
        print(
          '   ⚠️  Map Matching retornou poucos pontos (${matchedPoints.length}), mantendo caminho original',
        );
      }
    } catch (e) {
      print('❌ Erro ao aplicar Map Matching: $e');
      // Continua com os pontos GPS brutos se o matching falhar
    } finally {
      // Remove o indicador de processamento
      isApplyingMapMatching.value = false;
    }
  }

  /// Faz a câmera do mapa seguir o ponto atual do usuário
  /// Atualiza a posição da câmera sem animação para seguir em tempo real
  /// [pos] - A posição (coordenadas) para onde a câmera deve se mover
  void _followUser(mb.Position pos) {
    mapboxMap?.setCamera(
      mb.CameraOptions(center: mb.Point(coordinates: pos), zoom: 16.0),
    );
  }

  /// Atualiza as estatísticas da corrida atual
  /// Calcula distância total e duração
  void _updateRunStats() {
    if (currentRunPath.length < 2) return;

    // Calcula distância total
    double totalDistance = 0.0;
    for (int i = 1; i < currentRunPath.length; i++) {
      totalDistance += _calculateDistanceBetween(
        currentRunPath[i - 1],
        currentRunPath[i],
      );
    }
    currentDistance.value = totalDistance;

    // Calcula duração
    if (startTime.value != null) {
      currentDuration.value = DateTime.now().difference(startTime.value!);
    }
  }

  /// Calcula a distância entre dois pontos usando fórmula de Haversine
  /// [p1] - Primeiro ponto
  /// [p2] - Segundo ponto
  /// Retorna a distância em metros
  double _calculateDistanceBetween(mb.Position p1, mb.Position p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros

    final double lat1Rad = p1.lat * (math.pi / 180);
    final double lat2Rad = p2.lat * (math.pi / 180);
    final double deltaLat = (p2.lat - p1.lat) * (math.pi / 180);
    final double deltaLon = (p2.lng - p1.lng) * (math.pi / 180);

    final double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _calculateDistanceBetweenPoints(PositionPoint p1, PositionPoint p2) {
    const double earthRadius = 6371000;
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

  double? _calculateMaxSpeedKmh(List<PositionPoint> points) {
    if (points.length < 2) return null;
    double maxSpeed = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      final seconds = p2.timestamp.difference(p1.timestamp).inSeconds;
      if (seconds <= 0) continue;
      final meters = _calculateDistanceBetweenPoints(p1, p2);
      final speedKmh = (meters / seconds) * 3.6;
      if (speedKmh > maxSpeed) {
        maxSpeed = speedKmh;
      }
    }
    return maxSpeed > 0 ? maxSpeed : null;
  }

  double? _estimateCalories(double distanceMeters) {
    if (distanceMeters <= 0) return null;
    final km = distanceMeters / 1000;
    // Estimativa simples: ~60 kcal por km
    return km * 60;
  }

  /// Verifica se o caminho da corrida formou um circuito fechado
  /// Um circuito é considerado fechado se a distância entre o primeiro e último ponto
  /// for menor que um threshold (ex: 50 metros) e o caminho tiver pelo menos 10 pontos
  Future<void> _checkForClosedCircuit() async {
    if (!_isClosedCircuit()) {
      return;
    }

    if (_hasClosedCircuit ||
        isRunSummaryVisible.value ||
        isRunSummaryLoading.value ||
        !isTracking.value) {
      return;
    }
    final distanceToStart = _distanceToStart();
    print('🔍 [CIRCUITO] Verificando circuito fechado:');
    print('   - Pontos no caminho: ${currentRunPath.length}');
    print('   - Distância ao início: ${distanceToStart.toStringAsFixed(2)} m');
    print('   - Threshold: 50 m');
    print('✅ [CIRCUITO] Circuito fechado detectado! Aguardando salvamento.');
    _hasClosedCircuit = true;
    Get.snackbar(
      'Território fechado',
      'Abrindo resumo da corrida...',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    await prepareRunStop();
  }

  bool _isClosedCircuit() {
    // Precisa de pelo menos 10 pontos para considerar um circuito
    if (currentRunPath.length < 10) return false;

    final distanceToStart = _distanceToStart();
    const double threshold = 50.0; // 50 metros
    return distanceToStart < threshold;
  }

  double _distanceToStart() {
    if (currentRunPath.length < 2) return double.infinity;
    return _calculateDistanceBetween(currentRunPath.first, currentRunPath.last);
  }

  /// Salva o território capturado no servidor
  /// Cria um modelo de território com o caminho fechado exatamente como foi corrido
  /// PRESERVA TODOS OS PONTOS do caminho para manter o formato exato do quarteirão
  Future<void> _saveTerritory({bool skipStopRun = false}) async {
    print('🏁 [TERRITÓRIO] ========== INÍCIO _saveTerritory ==========');

    // Evita múltiplas execuções simultâneas
    if (_isSavingTerritory) {
      print(
        '⚠️ [TERRITÓRIO] _saveTerritory() já está em execução, ignorando...',
      );
      return;
    }

    _isSavingTerritory = true;

    try {
      final user = _userService.currentUser.value;
      if (user == null) {
        print('❌ [TERRITÓRIO] Usuário não autenticado');
        _isSavingTerritory = false;
        return;
      }

      print('📍 [TERRITÓRIO] Salvando território capturado...');
      print('   - Usuário: ${user.id} (${user.name ?? user.username})');
      print('   - Total de pontos no caminho: ${currentRunPath.length}');

      if (currentRunPath.isEmpty) {
        print('❌ Erro: caminho está vazio');
        _isSavingTerritory = false;
        return;
      }

      // IMPORTANTE: Captura a imagem do trajeto ANTES de processar os dados
      // Isso garante que a imagem seja capturada mesmo quando o território é capturado automaticamente
      if ((_capturedRunImagePath == null ||
              _capturedRunMapOnlyImagePath == null) &&
          currentRunPath.isNotEmpty) {
        try {
          print(
            '📸 [TERRITÓRIO] Capturando imagem do trajeto antes de salvar...',
          );
          final storyImagePath = await _captureMapSnapshot(
            width: 540,
            height: 960,
            addInfo: true,
            fileSuffix: 'story',
          );
          final mapOnlyImagePath = await _captureMapSnapshot(
            width: 600,
            height: 800,
            addInfo: false,
            fileSuffix: 'map',
          );
          if (storyImagePath != null) {
            _capturedRunImagePath = storyImagePath;
            print(
              '✅ [TERRITÓRIO] Imagem 9:16 capturada: ${storyImagePath.path}',
            );
          }
          if (mapOnlyImagePath != null) {
            _capturedRunMapOnlyImagePath = mapOnlyImagePath;
            print(
              '✅ [TERRITÓRIO] Imagem 3:4 capturada: ${mapOnlyImagePath.path}',
            );
          }
          if (storyImagePath == null && mapOnlyImagePath == null) {
            print(
              '⚠️ [TERRITÓRIO] Não foi possível capturar imagens do trajeto',
            );
          }
        } catch (e) {
          print('❌ [TERRITÓRIO] Erro ao capturar imagem do trajeto: $e');
          // Não impede o salvamento - continua mesmo se a captura falhar
        }
      } else if (_capturedRunImagePath != null) {
        print(
          '📸 [TERRITÓRIO] Imagem já capturada anteriormente: ${_capturedRunImagePath!.path}',
        );
      }

      // IMPORTANTE: Usa a API Directions do Mapbox para garantir que o boundary
      // siga apenas as ruas (vias de tráfego) com curvas suaves, não passando por cima de edifícios
      // Divide o caminho em segmentos menores e refina cada segmento para capturar todas as curvas
      List<mb.Position> refinedPath;

      try {
        print('🛣️  Refinando caminho usando API Directions do Mapbox...');
        print(
          '   Garantindo que o boundary siga apenas vias de tráfego com curvas suaves...',
        );

        // Refina o caminho completo usando road snapping em segmentos
        // Isso garante que todas as curvas das ruas sejam capturadas
        refinedPath = await _refinePathWithRoadSnapping(currentRunPath);

        if (refinedPath.isEmpty) {
          print('   ⚠️  Nenhum ponto refinado, usando caminho original');
          refinedPath = List.from(currentRunPath);
        } else {
          print(
            '   ✅ Caminho refinado: ${refinedPath.length} pontos seguindo as ruas com curvas',
          );
        }
      } catch (e) {
        print('   ⚠️  Erro ao refinar caminho com API Directions: $e');
        print('   Usando caminho original como fallback');
        refinedPath = List.from(currentRunPath);
      }

      // Converte o caminho refinado do Mapbox para PositionPoint
      // IMPORTANTE: Preserva TODOS os pontos da rota NA ORDEM RETORNADA PELA API
      // A API Directions retorna os pontos já na ordem correta seguindo as ruas
      final boundary = <PositionPoint>[];
      final baseTimestamp = startTime.value ?? DateTime.now();

      for (int i = 0; i < refinedPath.length; i++) {
        final pos = refinedPath[i];
        // Usa um timestamp baseado no índice para preservar a ordem
        // A ordem dos pontos é mantida conforme retornado pela API Directions
        final timestamp = baseTimestamp.add(Duration(seconds: i));
        boundary.add(
          PositionPoint(
            latitude: pos.lat.toDouble(),
            longitude: pos.lng.toDouble(),
            timestamp: timestamp,
          ),
        );
      }

      // CRÍTICO: Garante que o polígono está fechado SEGUINDO AS RUAS
      // Não liga o último ponto ao primeiro com linha reta (cortaria prédios)
      // Em vez disso, pede uma rota de retorno pelas ruas usando Directions API
      final firstPoint = boundary.first;
      final lastPoint = boundary.last;
      final isClosed =
          (firstPoint.latitude - lastPoint.latitude).abs() < 0.000001 &&
          (firstPoint.longitude - lastPoint.longitude).abs() < 0.000001;

      if (!isClosed) {
        print(
          '   - Polígono não está fechado, obtendo rota de retorno pelas ruas...',
        );
        print(
          '   - Último ponto: [${lastPoint.longitude}, ${lastPoint.latitude}]',
        );
        print(
          '   - Primeiro ponto: [${firstPoint.longitude}, ${firstPoint.latitude}]',
        );

        try {
          // Obtém a rota de retorno do último ponto ao primeiro SEGUINDO AS RUAS
          // Isso evita que o polígono corte prédios com uma linha reta
          final returnRoute = await _directionsService.getRouteBetweenPoints(
            from: mb.Position(lastPoint.longitude, lastPoint.latitude),
            to: mb.Position(firstPoint.longitude, firstPoint.latitude),
            profile: 'walking', // Usa perfil walking com overview=full
          );

          if (returnRoute.isNotEmpty && returnRoute.length > 1) {
            print('   ✅ Rota de retorno obtida: ${returnRoute.length} pontos');
            print(
              '   - Isso garante que o território siga as ruas mesmo no fechamento',
            );

            // Adiciona os pontos da rota de retorno (exceto o primeiro se for igual ao último)
            final lastMbPosition = mb.Position(
              lastPoint.longitude,
              lastPoint.latitude,
            );
            final firstReturnPosition = returnRoute.first;

            // Verifica se o primeiro ponto da rota de retorno é muito próximo do último já adicionado
            final distanceToFirstReturn = _calculateDistanceBetween(
              lastMbPosition,
              firstReturnPosition,
            );

            int startIndex = 0;
            if (distanceToFirstReturn < 5.0) {
              // Se estiver muito próximo (< 5m), pula o primeiro ponto para evitar duplicação
              startIndex = 1;
              print(
                '   - Primeiro ponto da rota de retorno muito próximo, pulando...',
              );
            }

            // Adiciona todos os pontos da rota de retorno (exceto duplicados)
            int addedPoints = 0;
            for (int i = startIndex; i < returnRoute.length; i++) {
              final returnPos = returnRoute[i];
              final returnPoint = PositionPoint(
                latitude: returnPos.lat.toDouble(),
                longitude: returnPos.lng.toDouble(),
                timestamp: baseTimestamp.add(
                  Duration(seconds: refinedPath.length + addedPoints),
                ),
              );

              // Verifica se não está duplicado (muito próximo do ponto anterior)
              if (boundary.isEmpty ||
                  _calculateDistanceBetween(
                        mb.Position(
                          boundary.last.longitude,
                          boundary.last.latitude,
                        ),
                        returnPos,
                      ) >
                      1.0) {
                boundary.add(returnPoint);
                addedPoints++;
              }
            }

            print('   ✅ ${addedPoints} pontos da rota de retorno adicionados');
            print('   - Total de pontos no boundary: ${boundary.length}');
            print(
              '   - Território fechado seguindo as ruas (sem linhas retas sobre prédios)',
            );
          } else {
            // Fallback: se a rota de retorno falhar, adiciona o primeiro ponto diretamente
            print(
              '   ⚠️  Rota de retorno vazia ou falhou, usando fechamento direto como fallback',
            );
            boundary.add(
              PositionPoint(
                latitude: firstPoint.latitude,
                longitude: firstPoint.longitude,
                timestamp: baseTimestamp.add(
                  Duration(seconds: refinedPath.length),
                ),
              ),
            );
          }
        } catch (e) {
          print('   ⚠️  Erro ao obter rota de retorno: $e');
          print('   Usando fechamento direto como fallback');
          // Fallback: adiciona o primeiro ponto diretamente
          boundary.add(
            PositionPoint(
              latitude: firstPoint.latitude,
              longitude: firstPoint.longitude,
              timestamp: baseTimestamp.add(
                Duration(seconds: refinedPath.length),
              ),
            ),
          );
        }
      } else {
        print('   - Polígono já estava fechado corretamente');
      }

      print('   - Total de pontos no boundary: ${boundary.length}');
      print(
        '   - Primeiro ponto: [${boundary.first.latitude}, ${boundary.first.longitude}]',
      );
      print(
        '   - Último ponto: [${boundary.last.latitude}, ${boundary.last.longitude}]',
      );

      // Calcula a área aproximada (simplificado - pode ser melhorado)
      final area = _calculatePolygonArea(boundary);
      print('   - Área calculada: ${area.toStringAsFixed(2)} m²');

      final distanceMeters = currentDistance.value;
      final durationSeconds = currentDuration.value.inSeconds;
      final averagePace = distanceMeters > 0
          ? (durationSeconds / 60) / (distanceMeters / 1000)
          : null;
      final maxSpeed = _calculateMaxSpeedKmh(boundary);
      final calories = _estimateCalories(distanceMeters);

      // Cria o modelo de território
      // O backend DEVE preservar todos os pontos do boundary sem simplificação
      final territory = TerritoryModel(
        id: '', // Será gerado pelo servidor
        userId: user.id,
        userName: user.name ?? user.username,
        userColor: user.color ?? '#00E5FF', // Padrão: Ciano (era roxo #7B2CBF)
        areaName: currentArea.value,
        boundary: boundary, // TODOS os pontos do caminho corrido
        capturedAt: DateTime.now(),
        area: area,
        distance: distanceMeters,
        duration: durationSeconds,
        averagePace: averagePace,
        maxSpeed: maxSpeed,
        calories: calories,
      );

      print('   - Enviando para o servidor...');

      // Obtém o caminho das imagens capturadas (se houver)
      final mapImagePath = _capturedRunImagePath;
      final mapImageCleanPath = _capturedRunMapOnlyImagePath;
      if (mapImagePath != null) {
        print('   📸 Imagem 9:16 será enviada: $mapImagePath');
      }
      if (mapImageCleanPath != null) {
        print('   🗺️ Imagem 3:4 será enviada: $mapImageCleanPath');
      }
      if (mapImagePath == null && mapImageCleanPath == null) {
        print('   ⚠️  Nenhuma imagem capturada para enviar');
      }

      // Salva no servidor (com imagem se disponível)
      // IMPORTANTE: O backend deve salvar TODOS os pontos do boundary
      // e retornar no formato GeoJSON com TODOS os pontos preservados
      print('📤 [TERRITÓRIO] Chamando _territoryService.saveTerritory()...');
      print('   - Territory ID: ${territory.id}');
      print('   - Boundary points: ${territory.boundary.length}');
      print('   - Map image path: ${mapImagePath?.path ?? "null"}');

      await _territoryService.saveTerritory(territory);

      print(
        '✅ [TERRITÓRIO] _territoryService.saveTerritory() concluído com sucesso!',
      );

      // IMPORTANTE: Quando há conquista de território, também salva a corrida em /runs
      // (não /runs/simple, que é apenas para corridas sem território)
      if (startTime.value != null && currentRunPath.isNotEmpty) {
        try {
          print('🏃 [CORRIDA] Salvando corrida (com território) em /runs...');
          print('   - Pontos no caminho: ${currentRunPath.length}');
          print(
            '   - Distância: ${currentDistance.value.toStringAsFixed(2)} m',
          );
          print('   - Duração: ${currentDuration.value}');

          // Converte currentRunPath (mb.Position) para PositionPoint
          final pathPoints = <PositionPoint>[];
          final baseTimestamp = startTime.value!;
          final endTime = DateTime.now();

          // Calcula o intervalo de tempo entre pontos
          final totalSeconds = endTime.difference(baseTimestamp).inSeconds;
          final intervalPerPoint = currentRunPath.length > 1
              ? totalSeconds / (currentRunPath.length - 1)
              : 0.0;

          for (int i = 0; i < currentRunPath.length; i++) {
            final pos = currentRunPath[i];
            final timestamp = baseTimestamp.add(
              Duration(seconds: (i * intervalPerPoint).round()),
            );
            pathPoints.add(
              PositionPoint(
                latitude: pos.lat.toDouble(),
                longitude: pos.lng.toDouble(),
                timestamp: timestamp,
              ),
            );
          }

          // Cria o modelo da corrida
          final run = RunModel(
            id: '', // Será gerado pelo servidor
            startTime: baseTimestamp,
            endTime: endTime,
            path: pathPoints,
            distance: currentDistance.value,
            duration: currentDuration.value,
          );

          // Salva a corrida em /runs (com território)
          // Usa as mesmas imagens enviadas com o território
          await _territoryService.saveRun(
            run,
            mapImagePath: mapImagePath,
            mapImageCleanPath: mapImageCleanPath,
          );

          print(
            '✅ [CORRIDA] Corrida (com território) salva em /runs com sucesso!',
          );
        } catch (e, stackTrace) {
          print('❌ [CORRIDA] Erro ao salvar corrida (com território): $e');
          print('   Stack trace: $stackTrace');
          // Não relança o erro - não deve impedir o salvamento do território
        }
      }

      // Limpa o caminho das imagens após enviar
      if (mapImagePath != null || mapImageCleanPath != null) {
        clearCapturedRunImagePath();
        print('   ✅ Imagens enviadas e caminho limpo');
      }

      // Mostra mensagem de sucesso
      Get.snackbar(
        'Território Capturado!',
        'Você capturou ${currentArea.value}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Remove o trajeto do mapa (marcas do percurso)
      await _removeRunPathFromMap();

      // Limpa todos os dados do trajeto para permitir capturar outro território
      currentRunPath.clear();
      _rawGpsPoints.clear();
      _cachedMatchedPoints.clear();
      _lastMatchedIndex = 0;
      _lastSnappedPoint = null;
      currentDistance.value = 0.0;
      currentDuration.value = Duration.zero;

      // Recarrega e redesenha os territórios para incluir o novo
      await _loadAndDrawTerritories();

      // Atualiza conquistas após capturar território
      print(
        '🏆 [TERRITÓRIO] Chamando _updateAchievementsAfterTerritoryCapture com área: ${area.toStringAsFixed(2)} m²',
      );
      try {
        await _updateAchievementsAfterTerritoryCapture(area);
        print(
          '✅ [TERRITÓRIO] _updateAchievementsAfterTerritoryCapture concluído com sucesso',
        );
      } catch (e, stackTrace) {
        print('❌ [TERRITÓRIO] Erro ao atualizar conquistas (não crítico): $e');
        print('   Stack trace: $stackTrace');
        // Não relança o erro - não deve impedir o salvamento do território
      }

      // Para a corrida automaticamente após capturar o território
      if (!skipStopRun) {
        print(
          '🛑 [TERRITÓRIO] Parando corrida automaticamente após capturar território...',
        );
        try {
          await stopRun();
          print('✅ [TERRITÓRIO] Corrida parada com sucesso');
        } catch (e, stackTrace) {
          print('❌ [TERRITÓRIO] Erro ao parar corrida (não crítico): $e');
          print('   Stack trace: $stackTrace');
          // Garante que pelo menos isTracking seja definido como false
          isTracking.value = false;
        }
      }

      print(
        '🏁 [TERRITÓRIO] ========== FIM _saveTerritory (SUCESSO) ==========',
      );
    } catch (e) {
      print('❌ [TERRITÓRIO] ========== ERRO em _saveTerritory ==========');
      print('Erro ao salvar território: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível salvar o território: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Sempre reseta o flag, mesmo se houver erro
      _isSavingTerritory = false;
      print('🔄 [TERRITÓRIO] Flag _isSavingTerritory resetado');
    }
  }

  /// Atualiza conquistas após capturar um território
  /// Calcula estatísticas do usuário e atualiza progresso das conquistas
  Future<void> _updateAchievementsAfterTerritoryCapture(
    double territoryArea,
  ) async {
    print('🏆 [CONQUISTAS] Iniciando atualização após capturar território...');
    print(
      '   - Área do território capturado: ${territoryArea.toStringAsFixed(2)} m²',
    );

    try {
      // Verifica se AchievementService está registrado
      if (!Get.isRegistered<AchievementService>()) {
        print('❌ [CONQUISTAS] AchievementService não está registrado!');
        print('   Tentando registrar...');
        try {
          Get.put<AchievementService>(AchievementService(), permanent: true);
          print('✅ [CONQUISTAS] AchievementService registrado com sucesso');
        } catch (e) {
          print('❌ [CONQUISTAS] Erro ao registrar AchievementService: $e');
          return;
        }
      }

      final achievementService = Get.find<AchievementService>();
      print('✅ [CONQUISTAS] AchievementService encontrado');

      final user = _userService.currentUser.value;

      if (user == null) {
        print('❌ [CONQUISTAS] Usuário não autenticado');
        return;
      }

      print('✅ [CONQUISTAS] Usuário autenticado: ${user.id}');

      // Conta territórios do usuário atual
      // IMPORTANTE: O território recém-capturado pode ainda não estar na lista
      // então sempre adicionamos 1 ao count e a área ao total
      int territoryCount =
          1; // Começa com 1 (o território que acabamos de capturar)
      double totalArea =
          territoryArea; // Começa com a área do território capturado

      try {
        print('📊 [CONQUISTAS] Buscando territórios do usuário...');
        // Busca territórios do mapa e filtra pelo usuário atual
        final featureCollection = await _territoryService.getMapTerritories();
        print(
          '   - Total de features encontradas: ${featureCollection.features.length}',
        );

        // Conta territórios existentes (pode não incluir o recém-capturado ainda)
        int existingCount = 0;
        double existingArea = 0.0;

        for (final feature in featureCollection.features) {
          final featureUserId = feature.properties.userId?.toString();
          print('   - Feature userId: $featureUserId, User atual: ${user.id}');

          if (featureUserId == user.id) {
            existingCount++;
            if (feature.properties.areaM2 != null) {
              final area = (feature.properties.areaM2 as num).toDouble();
              existingArea += area;
              print(
                '   - Território existente encontrado! Área: ${area.toStringAsFixed(2)} m²',
              );
            }
          }
        }

        // Usa o maior valor entre o que encontramos e o que acabamos de capturar
        // Isso garante que mesmo se o território ainda não estiver na lista, contamos ele
        territoryCount = existingCount > 0 ? existingCount + 1 : 1;
        totalArea = existingArea > 0
            ? existingArea + territoryArea
            : territoryArea;

        print('📊 [CONQUISTAS] Estatísticas calculadas:');
        print('   - Territórios existentes na API: $existingCount');
        print(
          '   - Área existente na API: ${existingArea.toStringAsFixed(2)} m²',
        );
        print('   - Territórios totais (incluindo novo): $territoryCount');
        print(
          '   - Área total (incluindo novo): ${totalArea.toStringAsFixed(2)} m²',
        );
      } catch (e) {
        print(
          '⚠️ [CONQUISTAS] Erro ao buscar territórios para estatísticas: $e',
        );
        print('   Usando valores do território recém-capturado');
        // Se não conseguir buscar, usa os valores do território que acabamos de capturar
        territoryCount = 1;
        totalArea = territoryArea;
      }

      // Atualiza conquistas relacionadas a territórios
      print('🔄 [CONQUISTAS] Chamando checkAndUpdateAchievements...');
      print('   - territoryCount: $territoryCount');
      print('   - totalArea: ${totalArea.toStringAsFixed(2)} m²');

      await achievementService.checkAndUpdateAchievements(
        territoryCount: territoryCount,
        totalArea: totalArea,
      );

      print('✅ [CONQUISTAS] checkAndUpdateAchievements concluído');
      print('✅ [CONQUISTAS] Conquistas atualizadas após capturar território');
      print('   - Territórios: $territoryCount');
      print('   - Área total: ${totalArea.toStringAsFixed(2)} m²');

      // Notifica ProfileController para recarregar conquistas se estiver registrado
      try {
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          // Recarrega apenas as conquistas (não todo o perfil)
          // O método refresh() recarrega tudo, mas é melhor que nada
          profileController.refresh();
          print(
            '✅ [CONQUISTAS] ProfileController notificado para recarregar conquistas',
          );
        } else {
          print(
            'ℹ️ [CONQUISTAS] ProfileController não está registrado (normal se não estiver na tela de perfil)',
          );
        }
      } catch (e) {
        print('⚠️ [CONQUISTAS] Erro ao notificar ProfileController: $e');
        // Não é crítico - as conquistas já foram atualizadas
      }
    } catch (e, stackTrace) {
      print(
        '❌ [CONQUISTAS] Erro ao atualizar conquistas após capturar território: $e',
      );
      print('   Stack trace: $stackTrace');
      // Não lança erro - não deve interromper o fluxo principal
    }
  }

  /// Refina o caminho completo usando road snapping em segmentos
  /// Divide o caminho em segmentos estratégicos e aplica road snapping
  /// Isso garante que todas as curvas das ruas sejam capturadas suavemente
  /// [path] - Lista completa de pontos do caminho GPS
  /// Retorna uma lista de pontos que seguem as ruas com curvas suaves
  Future<List<mb.Position>> _refinePathWithRoadSnapping(
    List<mb.Position> path,
  ) async {
    if (path.isEmpty) return [];
    if (path.length == 1) return path;

    print('   📍 Refinando ${path.length} pontos do caminho...');

    // Se o caminho tem poucos pontos, usa a API Directions com todos os pontos
    if (path.length <= 25) {
      print('   📍 Caminho curto, refinando com todos os pontos...');
      try {
        final refinedPath = await _directionsService.getRouteThroughWaypoints(
          points: path,
          profile: 'walking',
        );

        // Garante que o caminho está fechado se o original estava fechado
        final firstPoint = path.first;
        final lastPoint = path.last;
        final isClosed =
            (firstPoint.lat - lastPoint.lat).abs() < 0.000001 &&
            (firstPoint.lng - lastPoint.lng).abs() < 0.000001;

        if (isClosed && refinedPath.isNotEmpty) {
          // Garante que o último ponto seja igual ao primeiro
          if (_calculateDistanceBetween(refinedPath.last, refinedPath.first) >
              0.5) {
            refinedPath.add(refinedPath.first);
          }
        }

        print('   ✅ Caminho refinado: ${refinedPath.length} pontos');
        return refinedPath;
      } catch (e) {
        print('   ⚠️  Erro ao refinar caminho completo: $e');
        return List.from(path);
      }
    }

    // Para caminhos maiores, divide em segmentos estratégicos
    // Seleciona pontos importantes (curvas, mudanças de direção)
    final waypoints = _selectStrategicWaypoints(path);
    print('   📍 ${waypoints.length} waypoints estratégicos selecionados');

    try {
      // Refina usando os waypoints estratégicos
      final refinedPath = await _directionsService.getRouteThroughWaypoints(
        points: waypoints,
        profile: 'walking',
      );

      // Garante que o caminho está fechado se o original estava fechado
      final firstPoint = path.first;
      final lastPoint = path.last;
      final isClosed =
          (firstPoint.lat - lastPoint.lat).abs() < 0.000001 &&
          (firstPoint.lng - lastPoint.lng).abs() < 0.000001;

      if (isClosed && refinedPath.isNotEmpty) {
        // Garante que o último ponto seja igual ao primeiro
        if (_calculateDistanceBetween(refinedPath.last, refinedPath.first) >
            0.5) {
          refinedPath.add(refinedPath.first);
        }
      }

      print('   ✅ Caminho refinado: ${refinedPath.length} pontos');
      return refinedPath;
    } catch (e) {
      print('   ⚠️  Erro ao refinar caminho: $e');
      return List.from(path);
    }
  }

  /// Seleciona waypoints estratégicos do caminho que capturam curvas e mudanças de direção
  /// [path] - Lista completa de pontos do caminho
  /// Retorna uma lista de waypoints estratégicos (máximo 25 para a API)
  List<mb.Position> _selectStrategicWaypoints(List<mb.Position> path) {
    if (path.length <= 25) return List.from(path);

    const int maxWaypoints = 25;
    final waypoints = <mb.Position>[];

    // Sempre inclui o primeiro ponto
    waypoints.add(path.first);

    // Seleciona pontos que representam mudanças significativas de direção
    // Calcula o ângulo entre segmentos consecutivos
    final angles = <double>[];
    for (int i = 1; i < path.length - 1; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final next = path[i + 1];

      // Calcula o ângulo de mudança de direção
      final bearing1 = _calculateBearing(prev, curr);
      final bearing2 = _calculateBearing(curr, next);
      final angleChange = (bearing2 - bearing1).abs();
      final normalizedAngle = angleChange > 180
          ? 360 - angleChange
          : angleChange;

      angles.add(normalizedAngle);
    }

    // Seleciona pontos com maior mudança de direção (curvas)
    final sortedIndices = List<int>.generate(angles.length, (i) => i);
    sortedIndices.sort((a, b) => angles[b].compareTo(angles[a]));

    // Seleciona os top N pontos com maiores curvas
    final selectedIndices = <int>{0}; // Primeiro ponto sempre incluído
    final numCurvesToSelect = (maxWaypoints - 2).clamp(0, sortedIndices.length);

    for (int i = 0; i < numCurvesToSelect && i < sortedIndices.length; i++) {
      selectedIndices.add(
        sortedIndices[i] + 1,
      ); // +1 porque angles[i] corresponde a path[i+1]
    }

    // Adiciona pontos selecionados mantendo a ordem
    final sortedSelected = selectedIndices.toList()..sort();
    for (final index in sortedSelected) {
      if (index < path.length) {
        waypoints.add(path[index]);
      }
    }

    // Sempre inclui o último ponto se ainda não estiver incluído
    if (!selectedIndices.contains(path.length - 1)) {
      waypoints.add(path.last);
    }

    // Garante que o caminho está fechado se o original estava fechado
    final firstPoint = path.first;
    final lastPoint = path.last;
    final isClosed =
        (firstPoint.lat - lastPoint.lat).abs() < 0.000001 &&
        (firstPoint.lng - lastPoint.lng).abs() < 0.000001;

    if (isClosed && waypoints.isNotEmpty) {
      // Garante que o último ponto seja igual ao primeiro
      waypoints[waypoints.length - 1] = firstPoint;
    }

    return waypoints;
  }

  /// Calcula o bearing (direção) entre dois pontos em graus (0-360)
  /// [from] - Ponto de origem
  /// [to] - Ponto de destino
  /// Retorna o bearing em graus (0 = Norte, 90 = Leste, 180 = Sul, 270 = Oeste)
  double _calculateBearing(mb.Position from, mb.Position to) {
    final lat1 = from.lat * (math.pi / 180);
    final lat2 = to.lat * (math.pi / 180);
    final dLon = (to.lng - from.lng) * (math.pi / 180);

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    final bearingDegrees = (bearing * (180 / math.pi) + 360) % 360;

    return bearingDegrees;
  }

  /// Calcula a área aproximada de um polígono usando o algoritmo Shoelace
  /// [points] - Lista de pontos que formam o polígono
  /// Retorna a área em metros quadrados
  double _calculatePolygonArea(List<PositionPoint> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    const double earthRadius = 6371000; // Raio da Terra em metros

    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      final lat1 = points[i].latitude * (math.pi / 180);
      final lat2 = points[j].latitude * (math.pi / 180);
      final lon1 = points[i].longitude * (math.pi / 180);
      final lon2 = points[j].longitude * (math.pi / 180);

      area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }

    area = area * earthRadius * earthRadius / 2.0;
    return area.abs();
  }

  /// Formata a distância para exibição (km ou m)
  String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  /// Formata a área atual do território (km²) para exibição
  String formatCurrentTerritoryAreaKm2() {
    if (currentRunPath.length < 3) return '--';
    final points = currentRunPath
        .map(
          (p) => PositionPoint(
            latitude: p.lat.toDouble(),
            longitude: p.lng.toDouble(),
            timestamp: DateTime.now(),
          ),
        )
        .toList();
    final areaM2 = _calculatePolygonArea(points);
    if (areaM2 <= 0) return '--';
    final areaKm2 = areaM2 / 1000000;
    return '${areaKm2.toStringAsFixed(2)} km²';
  }

  /// Formata a duração para exibição (HH:MM:SS)
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formata o pace (minutos por km)
  String formatPace(Duration duration, double meters) {
    if (meters == 0) return '--:--';
    final km = meters / 1000;
    final minutesPerKm = duration.inSeconds / 60 / km;
    final minutes = minutesPerKm.floor();
    final seconds = ((minutesPerKm - minutes) * 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Inicia o timer do cronômetro
  /// Atualiza a duração a cada segundo enquanto a corrida estiver ativa
  void _startRunTimer() {
    _runTimer?.cancel(); // Cancela timer anterior se existir

    _runTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isTracking.value && startTime.value != null) {
        // Atualiza a duração a cada segundo
        currentDuration.value = DateTime.now().difference(startTime.value!);
      } else {
        // Se a corrida parou, cancela o timer
        timer.cancel();
      }
    });
  }

  /// Inicializa a LineLayer para o trajeto em tempo real (estilo Strava)
  /// Cria um GeoJsonSource e uma LineLayer dedicada que será atualizada em tempo real
  Future<void> _initializeTrailLayer() async {
    if (mapboxMap == null) {
      print('ERRO: mapboxMap é null ao inicializar trail layer');
      return;
    }

    try {
      print(
        '🏃 Inicializando LineLayer para trajeto em tempo real (estilo Strava)...',
      );

      // 1. Cria o Source GeoJSON vazio inicialmente
      final emptyGeoJson = {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      };

      _trailGeoJsonSource = mb.GeoJsonSource(
        id: _trailSourceId,
        data: jsonEncode(emptyGeoJson),
      );

      await mapboxMap!.style.addSource(_trailGeoJsonSource!);
      print('✅ Trail Source criado: $_trailSourceId');

      // 2. Cria a LineLayer com a cor do usuário
      // - lineJoin: ROUND para curvas suaves (automático)
      // - lineCap: ROUND para extremidades arredondadas (automático)
      // - Cor do usuário (dinâmica)
      final userColor = _getUserColor();
      final lineLayer = mb.LineLayer(
        id: _trailLayerId,
        sourceId: _trailSourceId,
        lineColor: userColor.value, // Cor do usuário
        lineWidth: 5.0, // 5 pixels de largura para boa visibilidade
        lineOpacity: 0.9, // 90% de opacidade
        // Nota: lineJoin e lineCap são configurados automaticamente pelo Mapbox
        // para aparência suave quando a geometria tem muitos pontos
      );

      print('✅ Trail LineLayer criada com cor do usuário: ${userColor.value}');

      // 3. Adiciona a LineLayer acima dos territórios mas abaixo de labels
      try {
        await mapboxMap!.style.addLayerAt(
          lineLayer,
          mb.LayerPosition(above: _territoriesLayerId),
        );
        print('✅ Trail LineLayer criada acima dos territórios');
      } catch (e) {
        // Fallback: adiciona normalmente
        await mapboxMap!.style.addLayer(lineLayer);
        print('✅ Trail LineLayer criada (sem posicionamento específico)');
      }

      print('✅ Trail LineLayer inicializada com sucesso: $_trailLayerId');
    } catch (e, stackTrace) {
      print('❌ Erro ao inicializar Trail LineLayer: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Desenha ou atualiza o trajeto da corrida no mapa
  /// ESTILO STRAVA: Usa LineLayer com updateGeoJSON em tempo real
  /// Atualiza a geometria sem recriar a layer (performance otimizada)
  Future<void> _updateRunPathOnMap() async {
    if (mapboxMap == null || currentRunPath.length < 2) {
      return;
    }

    try {
      // Converte as posições para formato GeoJSON LineString
      final coordinates = currentRunPath
          .map((pos) => [pos.lng, pos.lat])
          .toList();

      // Cria a feature GeoJSON com a LineString
      final geoJsonFeature = {
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': coordinates},
        'properties': {},
      };

      final featureCollection = {
        'type': 'FeatureCollection',
        'features': [geoJsonFeature],
      };

      final geoJsonString = jsonEncode(featureCollection);

      // Atualiza o Source GeoJSON sem recriar a layer (estilo Strava)
      // Isso garante atualização suave em tempo real
      try {
        if (_trailGeoJsonSource != null) {
          await _trailGeoJsonSource!.updateGeoJSON(geoJsonString);
          // Log apenas a cada 50 pontos para não poluir o console
          if (currentRunPath.length % 50 == 0) {
            print(
              '🏃 Trajeto atualizado: ${currentRunPath.length} pontos (estilo Strava)',
            );
          }
        } else {
          // Se o source não foi inicializado, inicializa agora
          await _initializeTrailLayer();
          if (_trailGeoJsonSource != null) {
            await _trailGeoJsonSource!.updateGeoJSON(geoJsonString);
          }
        }
      } catch (e) {
        // Fallback: recria o source se updateGeoJSON falhar
        print('⚠️  Erro ao atualizar trail source, recriando: $e');
        _trailGeoJsonSource = mb.GeoJsonSource(
          id: _trailSourceId,
          data: geoJsonString,
        );
        try {
          await mapboxMap!.style.addSource(_trailGeoJsonSource!);
        } catch (e2) {
          print('❌ Erro ao recriar trail source: $e2');
        }
      }
    } catch (e) {
      print('❌ Erro ao atualizar trajeto no mapa: $e');
    }
  }

  /// Remove o trajeto do mapa
  /// Limpa a LineLayer quando a corrida termina ou é cancelada
  Future<void> _removeRunPathFromMap() async {
    if (mapboxMap == null) {
      return;
    }

    try {
      // Limpa o Source GeoJSON (remove a linha)
      if (_trailGeoJsonSource != null) {
        final emptyGeoJson = {
          'type': 'FeatureCollection',
          'features': <Map<String, dynamic>>[],
        };
        await _trailGeoJsonSource!.updateGeoJSON(jsonEncode(emptyGeoJson));
        print('✅ Trajeto removido do mapa (LineLayer limpa)');
      }

      // Também remove a polyline legada se existir (compatibilidade)
      if (_polylineAnnotationManager != null && _currentPolyline != null) {
        try {
          await _polylineAnnotationManager!.delete(_currentPolyline!);
          _currentPolyline = null;
        } catch (e) {
          // Ignora erro
        }
      }
    } catch (e) {
      print('⚠️  Erro ao remover trajeto do mapa: $e');
    }
  }

  /// Inicializa o Source e FillLayer para territórios
  /// OTIMIZADO para efeito "Paper.io": camada sempre abaixo de 'building'
  /// Isso garante que os territórios "pintem" o asfalto sem cobrir edifícios
  Future<void> _initializeTerritoriesLayer() async {
    if (mapboxMap == null) {
      print('ERRO: mapboxMap é null ao inicializar layer de territórios');
      return;
    }

    try {
      print(
        '🗺️  Inicializando FillLayer para territórios (estilo Paper.io)...',
      );

      // 1. Cria a fonte de dados (Source)
      final emptyGeoJson = {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      };

      _territoriesGeoJsonSource = mb.GeoJsonSource(
        id: _territoriesSourceId,
        data: jsonEncode(emptyGeoJson),
      );

      await mapboxMap!.style.addSource(_territoriesGeoJsonSource!);
      print('✅ Source criado: $_territoriesSourceId');

      // 2. Cria a camada de pintura (FillLayer) inicialmente com cor padrão
      // Depois aplicamos expressão para cores dinâmicas
      final fillLayer = mb.FillLayer(
        id: _territoriesLayerId,
        sourceId: _territoriesSourceId,
        fillColor: const Color(
          0xFF00E5FF, // Ciano (era 0xFF7B2CBF roxo)
        ).value, // Cor padrão temporária (ciano - era roxo)
        fillOpacity: 0.6, // 60% de opacidade para melhor visibilidade
        fillOutlineColor: const Color(
          0xFF00E5FF,
        ).value, // Outline temporário (ciano - era roxo 0xFF7B2CBF)
      );

      print(
        '   FillLayer criado: ID=$_territoriesLayerId, Source=$_territoriesSourceId',
      );

      // 3. O PULO DO GATO: Inserir ABAIXO dos prédios e nomes de ruas
      // 'building' é o ID padrão para as construções 3D do Mapbox
      try {
        await mapboxMap!.style.addLayerAt(
          fillLayer,
          mb.LayerPosition(below: 'building'),
        );
        print(
          '✅ Camada de territórios inserida abaixo dos edifícios (building)',
        );
      } catch (e) {
        // Se 'building' não existir, tenta outras camadas
        print('⚠️  Camada "building" não encontrada, tentando outras...');
        final fallbackLayers = [
          'building-extrusion',
          'settlement-label',
          'road-label',
        ];
        bool layerAdded = false;

        for (final layerId in fallbackLayers) {
          try {
            await mapboxMap!.style.addLayerAt(
              fillLayer,
              mb.LayerPosition(below: layerId),
            );
            print('✅ Camada de territórios inserida abaixo de "$layerId"');
            layerAdded = true;
            break;
          } catch (e2) {
            // Continua tentando
          }
        }

        if (!layerAdded) {
          // Fallback: adiciona normalmente
          await mapboxMap!.style.addLayer(fillLayer);
          print('⚠️  Camada adicionada sem posicionamento específico');
        }
      }

      // 4. Aplica expressão para cores dinâmicas após criar o layer
      // Usa data-driven styling: cada território usa a cor do seu owner
      // Expressão Mapbox: ['get', 'color'] lê a propriedade 'color' de cada feature
      try {
        // Expressão para ler a cor da propriedade 'color' de cada feature
        // ['coalesce', ...] retorna o primeiro valor não-null (cor da feature ou fallback ciano - era roxo)
        final fillColorExpression = [
          'coalesce', // Retorna o primeiro valor não-null
          ['get', 'color'], // Tenta pegar a propriedade 'color' da feature
          '#00E5FF', // Fallback: ciano se não houver cor (era roxo #7B2CBF)
        ];

        // Converte a expressão para JSON string (requisito do Mapbox SDK)
        final expressionJson = jsonEncode(fillColorExpression);

        // Atualiza o fillColor com a expressão (cores dinâmicas por feature)
        await mapboxMap!.style.setStyleLayerProperty(
          _territoriesLayerId,
          'fill-color',
          expressionJson,
        );

        // Atualiza o fillOutlineColor com a mesma expressão
        await mapboxMap!.style.setStyleLayerProperty(
          _territoriesLayerId,
          'fill-outline-color',
          expressionJson,
        );

        print('✅ Expressão de cores dinâmicas aplicada ao FillLayer');
        print(
          '   - Cada território usará a cor do seu owner (propriedade "color")',
        );
      } catch (e) {
        print('⚠️  Erro ao aplicar expressão de cores: $e');
        print(
          '   - Territórios serão desenhados com cor padrão ciano (era roxa)',
        );
      }

      print('✅ FillLayer inicializado com sucesso: $_territoriesLayerId');
    } catch (e, stackTrace) {
      print('❌ Erro ao inicializar FillLayer de territórios: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Atualiza o Source com os territórios para desenhar no FillLayer
  /// [features] - Lista de features GeoJSON para desenhar
  Future<void> _updateTerritoriesSource(
    List<Map<String, dynamic>> features,
  ) async {
    if (mapboxMap == null) {
      print('ERRO: mapboxMap é null ao atualizar source de territórios');
      return;
    }

    try {
      final featureCollection = {
        'type': 'FeatureCollection',
        'features': features,
      };

      final geoJsonString = jsonEncode(featureCollection);

      print('📊 Atualizando Source com ${features.length} features...');
      print(
        '   Primeira feature: ${features.isNotEmpty ? features.first.toString().substring(0, features.first.toString().length > 150 ? 150 : features.first.toString().length) : "vazio"}...',
      );
      print('   GeoJSON completo: ${geoJsonString.length} caracteres');

      // Atualização eficiente sem "piscar" o mapa
      // Tenta atualizar a geometria da fonte existente primeiro
      try {
        // Método otimizado: atualiza o GeoJSON da fonte existente usando updateGeoJSON
        if (_territoriesGeoJsonSource != null) {
          await _territoriesGeoJsonSource!.updateGeoJSON(geoJsonString);
          print('✅ Source atualizado com updateGeoJSON (sem recriar layer)');
        } else {
          throw Exception('Source não inicializado');
        }
      } catch (e) {
        // Se updateGeoJSON falhar (SDK antigo ou método não disponível), recria a source
        print('⚠️  updateGeoJSON falhou, recriando source: $e');

        // Recria o source com os novos dados
        _territoriesGeoJsonSource = mb.GeoJsonSource(
          id: _territoriesSourceId,
          data: geoJsonString,
        );

        try {
          // Tenta adicionar o source (pode sobrescrever se já existir)
          await mapboxMap!.style.addSource(_territoriesGeoJsonSource!);
          print(
            '✅ Source recriado/atualizado com ${features.length} territórios',
          );
        } catch (e2) {
          print('❌ Erro ao recriar source: $e2');
          print(
            '⚠️  Os territórios podem não aparecer. Verifique os logs acima.',
          );
        }
      }

      // Verifica se o layer existe e está ativo
      try {
        final layer = await mapboxMap!.style.getLayer(_territoriesLayerId);
        if (layer != null) {
          print('✅ Layer $_territoriesLayerId verificado e ativo');
        } else {
          print(
            '⚠️  Layer $_territoriesLayerId não encontrado após atualização',
          );
        }
      } catch (e) {
        print('⚠️  Erro ao verificar layer: $e');
      }

      // Valida os dados enviados
      print('🔍 Validação final dos dados:');
      print('   - Total de features no Source: ${features.length}');
      if (features.isNotEmpty) {
        final firstFeature = features.first;
        print('   - Primeira feature ID: ${firstFeature['id']}');
        if (firstFeature['geometry'] != null) {
          final geometry = firstFeature['geometry'] as Map<String, dynamic>;
          if (geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            if (coordinates.isNotEmpty && coordinates[0] is List) {
              final outerRing = coordinates[0] as List;
              print('   - Pontos no primeiro polígono: ${outerRing.length}');
              if (outerRing.isNotEmpty) {
                print('   - Primeiro ponto: ${outerRing.first}');
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao atualizar source de territórios: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Obtém o bounding box (bbox) da viewport atual do mapa
  /// Retorna [minLng, minLat, maxLng, maxLat] ou null se não conseguir obter
  Future<List<double>?> _getMapViewportBbox() async {
    if (mapboxMap == null) return null;

    try {
      // Obtém o estado atual da câmera
      final cameraState = await mapboxMap!.getCameraState();
      final center = cameraState.center.coordinates;
      final zoom = cameraState.zoom;

      // Calcula o tamanho aproximado da viewport em graus baseado no zoom
      // Fórmula: quanto maior o zoom, menor a área visível
      // Aproximação: zoom 10 = ~10km, zoom 15 = ~1km, zoom 20 = ~100m
      final degreesPerPixel = 360.0 / (256.0 * math.pow(2, zoom));
      // Assume uma viewport de aproximadamente 400x800 pixels (típico de smartphone)
      final widthDegrees = degreesPerPixel * 400;
      final heightDegrees = degreesPerPixel * 800;

      // Calcula o bbox (bounding box)
      final minLng = center.lng - widthDegrees / 2;
      final maxLng = center.lng + widthDegrees / 2;
      final minLat = center.lat - heightDegrees / 2;
      final maxLat = center.lat + heightDegrees / 2;

      // Adiciona um padding de 20% ao redor para carregar territórios próximos também
      final lngPadding = widthDegrees * 0.2;
      final latPadding = heightDegrees * 0.2;

      final bbox = [
        minLng - lngPadding,
        minLat - latPadding,
        maxLng + lngPadding,
        maxLat + latPadding,
      ];

      print(
        '📐 Bbox da viewport: [${bbox[0].toStringAsFixed(6)}, ${bbox[1].toStringAsFixed(6)}, ${bbox[2].toStringAsFixed(6)}, ${bbox[3].toStringAsFixed(6)}]',
      );
      return bbox;
    } catch (e) {
      print('❌ Erro ao obter bbox da viewport: $e');
      return null;
    }
  }

  /// Busca territórios baseado na viewport atual do mapa (bbox)
  /// [bbox] - Bounding box opcional. Se não fornecido, calcula baseado na viewport atual
  Future<void> _loadAndDrawTerritories({List<double>? bbox}) async {
    if (mapboxMap == null) {
      print('ERRO: mapboxMap é null');
      return;
    }

    if (_polygonAnnotationManager == null) {
      print('ERRO: _polygonAnnotationManager é null');
      return;
    }

    // Evita múltiplas requisições simultâneas
    if (_isLoadingTerritories) {
      print('⏳ Já está carregando territórios, aguardando...');
      return;
    }

    _isLoadingTerritories = true;

    try {
      print('🌍 Iniciando carregamento de territories no formato GeoJSON...');

      // Limpa os polígonos anteriores
      _clearTerritoryPolygons();

      // Obtém o bbox da viewport atual se não foi fornecido
      List<double>? viewportBbox = bbox;
      if (viewportBbox == null) {
        viewportBbox = await _getMapViewportBbox();
      }

      // Busca os territories no formato GeoJSON FeatureCollection
      print('📡 Buscando territories da API (endpoint /runs/map)...');
      if (viewportBbox != null) {
        print(
          '   📍 Usando bbox da viewport: [${viewportBbox[0].toStringAsFixed(6)}, ${viewportBbox[1].toStringAsFixed(6)}, ${viewportBbox[2].toStringAsFixed(6)}, ${viewportBbox[3].toStringAsFixed(6)}]',
        );
      } else {
        print('   ⚠️ Bbox não disponível, carregando todos os territórios');
      }
      final featureCollection = await _territoryService.getMapTerritories(
        bbox: viewportBbox,
      );

      print(
        '✅ API retornou FeatureCollection com ${featureCollection.features.length} features',
      );

      if (featureCollection.features.isEmpty) {
        print('ℹ️  Nenhum territory encontrado para desenhar');
        return;
      }

      print(
        '🎨 Carregando ${featureCollection.features.length} territories para desenhar no mapa',
      );

      // Limpa apenas os territórios fictícios anteriores (mantém os da API)
      // Remove apenas features com ID que começa com "fictional-"
      _territoriesFeatures.removeWhere((feature) {
        final id = feature['id']?.toString() ?? '';
        return id.startsWith('fictional-');
      });

      print('📋 Features existentes (API): ${_territoriesFeatures.length}');

      // Converte cada feature para o formato GeoJSON e adiciona à lista
      for (int i = 0; i < featureCollection.features.length; i++) {
        final feature = featureCollection.features[i];
        print(
          '📍 Processando territory ${i + 1}/${featureCollection.features.length}',
        );
        print('  - ID: ${feature.id}');
        print('  - Owner: ${feature.properties.owner}');
        print('  - Cor: ${feature.properties.color}');
        print('  - Tipo de geometria: ${feature.geometry.type}');

        if (feature.geometry.type == 'Polygon') {
          final outerRing = feature.geometry.outerRing;
          print('  - Pontos no polígono: ${outerRing.length}');

          if (outerRing.isNotEmpty) {
            // GeoJSON usa [lng, lat]
            print(
              '  - Primeiro ponto: [${outerRing.first[0]}, ${outerRing.first[1]}] (lng, lat)',
            );
            print(
              '  - Último ponto: [${outerRing.last[0]}, ${outerRing.last[1]}] (lng, lat)',
            );

            // Converte para formato GeoJSON Feature com todas as properties
            final geoJsonFeature = {
              'type': 'Feature',
              'id': feature.id,
              'geometry': {
                'type': 'Polygon',
                'coordinates': [outerRing],
              },
              'properties': {
                'owner': feature.properties.owner,
                'color': feature.properties.color,
                if (feature.properties.areaName != null)
                  'areaName': feature.properties.areaName,
                if (feature.properties.userId != null)
                  'userId': feature.properties.userId,
                if (feature.properties.userName != null)
                  'userName': feature.properties.userName,
                if (feature.properties.username != null)
                  'username': feature.properties.username,
                if (feature.properties.photoUrl != null)
                  'photoUrl': feature.properties.photoUrl,
                if (feature.properties.capturedAt != null)
                  'capturedAt': feature.properties.capturedAt,
                if (feature.properties.areaM2 != null)
                  'areaM2': feature.properties.areaM2,
              },
            };

            _territoriesFeatures.add(geoJsonFeature);
          }
        } else {
          print('  ⚠️  Geometria não é um Polygon, ignorando...');
        }
      }

      // Atualiza o Source com todos os territórios
      if (_territoriesFeatures.isEmpty) {
        print('⚠️  Nenhuma feature para atualizar no Source');
      } else {
        print(
          '📊 Atualizando Source com ${_territoriesFeatures.length} features...',
        );
        await _updateTerritoriesSource(_territoriesFeatures);
        print(
          '✅ Territories carregados no FillLayer! Total: ${_territoriesFeatures.length} territórios',
        );
      }

      // Salva o bbox atual para comparação futura
      if (viewportBbox != null) {
        _lastLoadedBbox = viewportBbox;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar territories: $e');
      print('Stack trace: $stackTrace');
      // Não mostra snackbar para evitar poluir a UI durante a inicialização
    } finally {
      _isLoadingTerritories = false;
    }
  }

  /// Desenha um territory no mapa a partir de um GeoJSON Feature
  /// [feature] - O GeoJSON Feature que representa o territory
  /*Future<void> _drawTerritoryFromGeoJson(GeoJsonFeature feature) async {
    if (_polygonAnnotationManager == null) {
      print(
        'ERRO: _polygonAnnotationManager é null ao desenhar "${feature.id}"',
      );
      return;
    }

    // Obtém o anel externo do polígono (primeiro array de coordenadas)
    final outerRing = feature.geometry.outerRing;

    if (outerRing.isEmpty) {
      print('AVISO: Territory "${feature.id}" não tem coordenadas');
      return;
    }

    if (outerRing.length < 3) {
      print(
        'AVISO: Territory "${feature.id}" precisa de pelo menos 3 pontos para formar um polígono (tem ${outerRing.length})',
      );
      return;
    }

    try {
      // GeoJSON usa formato [longitude, latitude] para coordenadas
      // Mapbox Maps Flutter usa mb.Position(lng, lat)
      // IMPORTANTE: Preserva a ordem dos pontos exatamente como retornado pelo backend
      // O backend DEVE retornar os pontos na ordem cronológica do caminho corrido
      // Isso garante que o polígono siga exatamente o formato das ruas percorridas
      final coordinates = <mb.Position>[];
      for (int i = 0; i < outerRing.length; i++) {
        final coord = outerRing[i];
        // coord é [lng, lat] no formato GeoJSON
        final lng = coord[0];
        final lat = coord[1];
        coordinates.add(mb.Position(lng, lat));
      }

      print('  - Coordenadas convertidas: ${coordinates.length} pontos');
      print(
        '  - Ordem dos pontos preservada: ${coordinates.length} pontos na sequência original',
      );

      // Validação: verifica se os pontos estão em sequência lógica (não aleatória)
      // Calcula distância média entre pontos consecutivos para detectar problemas
      if (coordinates.length > 3) {
        double totalDistance = 0;
        int validPairs = 0;
        double maxDistance = 0;

        for (int i = 1; i < coordinates.length; i++) {
          final prev = coordinates[i - 1];
          final curr = coordinates[i];
          final dist = _calculateDistanceBetween(prev, curr);
          totalDistance += dist;
          if (dist > maxDistance) maxDistance = dist;
          validPairs++;
        }

        if (validPairs > 0) {
          final avgDistance = totalDistance / validPairs;
          print(
            '  - Distância média entre pontos consecutivos: ${avgDistance.toStringAsFixed(2)} metros',
          );
          print(
            '  - Distância máxima entre pontos consecutivos: ${maxDistance.toStringAsFixed(2)} metros',
          );

          if (avgDistance > 100) {
            print(
              '  ⚠️ AVISO: Distância média muito alta (>100m). Pode indicar pontos fora de ordem ou simplificação excessiva.',
            );
          }
          if (maxDistance > 500) {
            print(
              '  ⚠️ AVISO: Alguns pontos estão muito distantes (>500m). Verifique se a ordem está correta.',
            );
          }
          if (avgDistance < 2) {
            print(
              '  ✅ Boa resolução: pontos muito próximos, formato do caminho deve ser fiel às ruas.',
            );
          }
        }
      }
      print(
        '  - Ordem dos pontos preservada: ${coordinates.length} pontos na sequência original',
      );

      // Validação: verifica se os pontos estão em sequência lógica (não aleatória)
      // Calcula distância média entre pontos consecutivos para detectar problemas
      if (coordinates.length > 3) {
        double totalDistance = 0;
        int validPairs = 0;
        double maxDistance = 0;

        for (int i = 1; i < coordinates.length; i++) {
          final prev = coordinates[i - 1];
          final curr = coordinates[i];
          final dist = _calculateDistanceBetween(prev, curr);
          totalDistance += dist;
          if (dist > maxDistance) maxDistance = dist;
          validPairs++;
        }

        if (validPairs > 0) {
          final avgDistance = totalDistance / validPairs;
          print(
            '  - Distância média entre pontos consecutivos: ${avgDistance.toStringAsFixed(2)} metros',
          );
          print(
            '  - Distância máxima entre pontos consecutivos: ${maxDistance.toStringAsFixed(2)} metros',
          );

          if (avgDistance > 100) {
            print(
              '  ⚠️ AVISO: Distância média muito alta (>100m). Pode indicar pontos fora de ordem ou simplificação excessiva.',
            );
          }
          if (maxDistance > 500) {
            print(
              '  ⚠️ AVISO: Alguns pontos estão muito distantes (>500m). Verifique se a ordem está correta.',
            );
          }
          if (avgDistance < 2) {
            print(
              '  ✅ Boa resolução: pontos muito próximos, formato do caminho deve ser fiel às ruas.',
            );
          }
        }
      }

      // GeoJSON já garante que o polígono está fechado (primeiro e último ponto iguais)
      // Mas verificamos mesmo assim para segurança
      final firstCoord = coordinates.first;
      final lastCoord = coordinates.last;
      final isClosed =
          (firstCoord.lat - lastCoord.lat).abs() < 0.000001 &&
          (firstCoord.lng - lastCoord.lng).abs() < 0.000001;

      if (!isClosed) {
        print(
          '  - Polígono não estava fechado, adicionando ponto de fechamento',
        );
        coordinates.add(mb.Position(firstCoord.lng, firstCoord.lat));
      } else {
        print('  - Polígono já estava fechado');
      }

      // Converte a cor hexadecimal do territory para Color
      final territoryColor = _hexToColor(feature.properties.color);
      print(
        '  - Cor convertida: ${territoryColor.value} (hex: ${feature.properties.color})',
      );

      // Cria as opções do polígono
      // O Polygon precisa de uma lista de anéis, onde o primeiro anel é o perímetro externo
      // Outros anéis são buracos (holes) - não usamos por enquanto
      final polygonOptions = mb.PolygonAnnotationOptions(
        geometry: mb.Polygon(
          coordinates: [coordinates], // Lista de anéis (outer ring + holes)
        ),
        fillColor: territoryColor.value, // Cor de preenchimento
        fillOpacity: 0.6, // 60% de opacidade para melhor visibilidade
        fillOutlineColor: territoryColor.value, // Cor da borda
      );

      print('  - Criando polígono no mapa...');

      // Cria o polígono no mapa
      final polygon = await _polygonAnnotationManager!.create(polygonOptions);
      _territoryPolygons.add(polygon);

      print(
        '  ✅ Territory "${feature.id}" (${feature.properties.owner}) desenhado com sucesso!',
      );
    } catch (e, stackTrace) {
      print('  ❌ Erro ao desenhar territory "${feature.id}": $e');
      print('  Stack trace: $stackTrace');
    }
  }
*/
  /// Desenha um território específico no mapa como polígono (método legado)
  /// [territory] - O território a ser desenhado
  /// NOTA: Este método é mantido para compatibilidade, mas prefira usar _drawTerritoryFromGeoJson
  /*Future<void> _drawTerritoryPolygon(TerritoryModel territory) async {
    if (_polygonAnnotationManager == null) {
      print(
        'ERRO: _polygonAnnotationManager é null ao desenhar "${territory.areaName}"',
      );
      return;
    }

    if (territory.boundary.isEmpty) {
      print(
        'AVISO: Território "${territory.areaName}" não tem pontos no boundary',
      );
      return;
    }

    if (territory.boundary.length < 3) {
      print(
        'AVISO: Território "${territory.areaName}" precisa de pelo menos 3 pontos para formar um polígono (tem ${territory.boundary.length})',
      );
      return;
    }

    try {
      // Converte os pontos do território para o formato Mapbox (Position)
      // O formato é [longitude, latitude]
      final coordinates = territory.boundary.map((point) {
        return mb.Position(point.longitude, point.latitude);
      }).toList();

      print('  - Coordenadas convertidas: ${coordinates.length} pontos');

      // Garante que o polígono está fechado (primeiro e último ponto iguais)
      final firstCoord = coordinates.first;
      final lastCoord = coordinates.last;
      final isClosed =
          (firstCoord.lat - lastCoord.lat).abs() < 0.000001 &&
          (firstCoord.lng - lastCoord.lng).abs() < 0.000001;

      if (!isClosed) {
        print(
          '  - Polígono não estava fechado, adicionando ponto de fechamento',
        );
        coordinates.add(mb.Position(firstCoord.lng, firstCoord.lat));
      } else {
        print('  - Polígono já estava fechado');
      }

      // Converte a cor hexadecimal do território para Color
      final territoryColor = _hexToColor(territory.userColor);
      print(
        '  - Cor convertida: ${territoryColor.value} (hex: ${territory.userColor})',
      );

      // Cria as opções do polígono
      final polygonOptions = mb.PolygonAnnotationOptions(
        geometry: mb.Polygon(
          coordinates: [coordinates], // Lista de anéis (outer ring + holes)
        ),
        fillColor: territoryColor.value, // Cor de preenchimento
        fillOpacity: 0.6, // 60% de opacidade
        fillOutlineColor: territoryColor.value, // Cor da borda
      );

      print('  - Criando polígono no mapa...');

      // Cria o polígono no mapa
      final polygon = await _polygonAnnotationManager!.create(polygonOptions);
      _territoryPolygons.add(polygon);

      print('  ✅ Território "${territory.areaName}" desenhado com sucesso!');
    } catch (e, stackTrace) {
      print('  ❌ Erro ao desenhar território "${territory.areaName}": $e');
      print('  Stack trace: $stackTrace');
    }
  }*/

  /// Limpa todos os polígonos de territórios do mapa
  /// Remove todas as anotações de polígonos criadas
  Future<void> _clearTerritoryPolygons() async {
    if (_polygonAnnotationManager == null) {
      print(
        'AVISO: _polygonAnnotationManager é null, não é possível limpar polígonos',
      );
      _territoryPolygons.clear();
      return;
    }

    if (_territoryPolygons.isEmpty) {
      print('Nenhum polígono para remover');
      return;
    }

    try {
      print('Limpando ${_territoryPolygons.length} polígonos do mapa...');

      // Deleta cada polígono
      int deletedCount = 0;
      for (final polygon in _territoryPolygons) {
        try {
          await _polygonAnnotationManager!.delete(polygon);
          deletedCount++;
        } catch (e) {
          print('Erro ao remover polígono: $e');
        }
      }

      // Limpa a lista
      _territoryPolygons.clear();
      print('✅ $deletedCount polígonos de territórios foram removidos do mapa');
    } catch (e) {
      print('❌ Erro ao limpar polígonos de territórios: $e');
      _territoryPolygons.clear(); // Limpa a lista mesmo em caso de erro
    }
  }

  /// Desenha um território específico usando waypoints de ruas
  /// Usa a API Directions do Mapbox para seguir as vias entre os pontos
  /// [waypoints] - Lista de pontos que representam o caminho pelas ruas
  /// [name] - Nome do território
  /// [color] - Cor do território (hexadecimal)
  Future<void> drawTerritoryFromWaypoints({
    required List<Map<String, dynamic>> waypoints,
    required String name,
    String color = '#00E5FF', // Padrão: Ciano (era roxo #7B2CBF)
  }) async {
    if (mapboxMap == null) {
      print('ERRO: mapboxMap é null');
      return;
    }

    if (_territoriesGeoJsonSource == null) {
      print(
        'ERRO: _territoriesGeoJsonSource não foi inicializado. Inicialize o FillLayer primeiro!',
      );
      return;
    }

    try {
      print(
        '🗺️  Desenhando território "$name" com ${waypoints.length} waypoints...',
      );

      // Converte os waypoints para mb.Position
      final positions = waypoints.map((wp) {
        final coords = wp['Coordenadas Aproximadas (Lng, Lat)'] as String;
        final parts = coords.split(',');
        final lng = double.parse(parts[0].trim());
        final lat = double.parse(parts[1].trim());
        return mb.Position(lng, lat);
      }).toList();

      print('📍 Waypoints convertidos: ${positions.length} pontos');

      // IMPORTANTE: Para seguir realmente as vias de tráfego (curvas, rotatórias, etc),
      // precisamos processar segmento por segmento e depois juntar tudo
      List<mb.Position> refinedCoordinates = [];

      try {
        print(
          '🛣️  Processando rota segmento por segmento para seguir as vias de tráfego...',
        );

        // Se temos apenas os pontos principais, precisamos conectá-los seguindo as ruas
        // Processa cada par de pontos consecutivos para capturar curvas e rotatórias
        // Para aumentar a densidade de pontos nas curvas, dividimos segmentos longos
        for (int i = 0; i < positions.length; i++) {
          final fromPoint = positions[i];
          final toPoint =
              positions[(i + 1) %
                  positions.length]; // Usa módulo para fechar o círculo

          print(
            '  📍 Segmento ${i + 1}/${positions.length}: [${fromPoint.lng}, ${fromPoint.lat}] -> [${toPoint.lng}, ${toPoint.lat}]',
          );

          try {
            // Calcula a distância do segmento para determinar se precisa dividir
            final segmentDistance = _calculateDistanceBetween(
              fromPoint,
              toPoint,
            );

            // Se o segmento for muito longo (> 500m), divide em sub-segmentos
            // Isso força a API a retornar mais pontos intermediários nas curvas
            if (segmentDistance > 500.0) {
              print(
                '    🔀 Segmento longo (${segmentDistance.toStringAsFixed(0)}m), dividindo em sub-segmentos para maior densidade de pontos...',
              );

              // Divide o segmento em múltiplos sub-segmentos
              final numSubSegments = (segmentDistance / 300.0)
                  .ceil(); // ~300m por sub-segmento
              print('    📊 Criando $numSubSegments sub-segmentos...');

              final subSegmentPoints = <mb.Position>[fromPoint];

              // Adiciona pontos intermediários ao longo do segmento
              for (int j = 1; j < numSubSegments; j++) {
                final ratio = j / numSubSegments;
                final intermediateLng =
                    fromPoint.lng + (toPoint.lng - fromPoint.lng) * ratio;
                final intermediateLat =
                    fromPoint.lat + (toPoint.lat - fromPoint.lat) * ratio;
                subSegmentPoints.add(
                  mb.Position(intermediateLng, intermediateLat),
                );
              }

              subSegmentPoints.add(toPoint);

              // Processa cada sub-segmento
              for (int j = 0; j < subSegmentPoints.length - 1; j++) {
                final subFrom = subSegmentPoints[j];
                final subTo = subSegmentPoints[j + 1];

                // Obtém a rota do sub-segmento usando perfil WALKING
                // O perfil WALKING com geometries=geojson e overview=full retorna alta densidade de pontos
                // Isso captura melhor curvas e rotatórias nas esquinas de Ribeirão Preto
                final subSegmentRoute = await _directionsService
                    .getRouteBetweenPoints(
                      from: subFrom,
                      to: subTo,
                      profile:
                          'walking', // WALKING com overview=full para máxima densidade de pontos
                    );

                if (subSegmentRoute.isNotEmpty) {
                  // Adiciona os pontos do sub-segmento (tratando duplicações)
                  if (refinedCoordinates.isNotEmpty) {
                    final lastAdded = refinedCoordinates.last;
                    final firstNew = subSegmentRoute.first;
                    final distance = _calculateDistanceBetween(
                      lastAdded,
                      firstNew,
                    );

                    if (distance > 5.0) {
                      refinedCoordinates.addAll(subSegmentRoute);
                    } else {
                      if (subSegmentRoute.length > 1) {
                        refinedCoordinates.addAll(subSegmentRoute.sublist(1));
                      }
                    }
                  } else {
                    refinedCoordinates.addAll(subSegmentRoute);
                  }
                } else {
                  // Fallback: adiciona ponto direto
                  if (refinedCoordinates.isEmpty ||
                      _calculateDistanceBetween(
                            refinedCoordinates.last,
                            subTo,
                          ) >
                          0.5) {
                    refinedCoordinates.add(subTo);
                  }
                }

                // Pequeno delay para não sobrecarregar a API
                await Future.delayed(const Duration(milliseconds: 100));
              }

              print(
                '    ✅ ${numSubSegments} sub-segmentos processados: total acumulado ${refinedCoordinates.length} pontos',
              );
            } else {
              // Segmento curto, processa normalmente
              // Obtém a rota entre estes dois pontos usando perfil WALKING
              // O perfil WALKING com geometries=geojson e overview=full retorna alta densidade de pontos
              // Isso captura melhor curvas e rotatórias nas esquinas de Ribeirão Preto
              final segmentRoute = await _directionsService.getRouteBetweenPoints(
                from: fromPoint,
                to: toPoint,
                profile:
                    'walking', // WALKING com overview=full para máxima densidade de pontos
              );

              if (segmentRoute.isNotEmpty) {
                // Adiciona todos os pontos do segmento (exceto o primeiro se for igual ao ponto anterior)
                if (refinedCoordinates.isNotEmpty) {
                  // Verifica se o primeiro ponto do novo segmento é muito próximo do último já adicionado
                  final lastAdded = refinedCoordinates.last;
                  final firstNew = segmentRoute.first;
                  final distance = _calculateDistanceBetween(
                    lastAdded,
                    firstNew,
                  );

                  if (distance > 5.0) {
                    // Se estiver a mais de 5 metros, adiciona
                    refinedCoordinates.addAll(segmentRoute);
                  } else {
                    // Se estiver muito próximo, pula o primeiro e adiciona o resto
                    if (segmentRoute.length > 1) {
                      refinedCoordinates.addAll(segmentRoute.sublist(1));
                    }
                  }
                } else {
                  // Primeiro segmento, adiciona todos os pontos
                  refinedCoordinates.addAll(segmentRoute);
                }

                print(
                  '    ✅ Segmento ${i + 1} adicionado: ${segmentRoute.length} pontos (total: ${refinedCoordinates.length})',
                );
              } else {
                print(
                  '    ⚠️  Segmento ${i + 1} retornou vazio, adicionando ponto direto',
                );
                if (refinedCoordinates.isEmpty ||
                    _calculateDistanceBetween(
                          refinedCoordinates.last,
                          toPoint,
                        ) >
                        0.5) {
                  refinedCoordinates.add(toPoint);
                }
              }

              // Pequeno delay para não sobrecarregar a API
              await Future.delayed(const Duration(milliseconds: 100));
            }
          } catch (e) {
            print('    ❌ Erro no segmento ${i + 1}: $e');
            // Em caso de erro, adiciona o ponto destino diretamente
            if (refinedCoordinates.isEmpty ||
                _calculateDistanceBetween(refinedCoordinates.last, toPoint) >
                    0.5) {
              refinedCoordinates.add(toPoint);
            }
          }
        }

        if (refinedCoordinates.isEmpty) {
          print('  ⚠️  Nenhuma rota refinada obtida, usando pontos originais');
          refinedCoordinates = positions;
        } else {
          print(
            '  ✅ Rota completa refinada: ${refinedCoordinates.length} pontos seguindo as vias de tráfego',
          );
        }

        // Garante que o polígono está fechado (primeiro ponto = último ponto)
        if (refinedCoordinates.isNotEmpty) {
          final firstPoint = refinedCoordinates.first;
          final lastPoint = refinedCoordinates.last;
          final distanceToClose = _calculateDistanceBetween(
            lastPoint,
            firstPoint,
          );

          if (distanceToClose > 10.0) {
            // Se estiver a mais de 10 metros do início
            print(
              '  - Fechando polígono: adicionando rota de retorno ao ponto inicial',
            );
            try {
              // Obtém a rota de fechamento também seguindo as ruas
              // Usa perfil WALKING para maior densidade de pontos nas curvas
              final closingRoute = await _directionsService.getRouteBetweenPoints(
                from: lastPoint,
                to: firstPoint,
                profile:
                    'walking', // WALKING com overview=full para máxima densidade
              );

              if (closingRoute.isNotEmpty) {
                // Remove o primeiro ponto se for muito próximo do último já adicionado
                if (_calculateDistanceBetween(
                      refinedCoordinates.last,
                      closingRoute.first,
                    ) <
                    5.0) {
                  refinedCoordinates.addAll(closingRoute.sublist(1));
                } else {
                  refinedCoordinates.addAll(closingRoute);
                }
                print(
                  '    ✅ Rota de fechamento adicionada: ${closingRoute.length} pontos',
                );
              } else {
                // Fallback: adiciona o primeiro ponto diretamente
                refinedCoordinates.add(firstPoint);
              }
            } catch (e) {
              print(
                '    ⚠️  Erro ao fechar polígono: $e, adicionando ponto direto',
              );
              refinedCoordinates.add(firstPoint);
            }
          } else {
            print(
              '  - Polígono já está fechado (distância: ${distanceToClose.toStringAsFixed(2)}m)',
            );
          }
        }
      } catch (e) {
        print('  ⚠️  Erro geral ao refinar rota com API Directions: $e');
        print('  Usando pontos originais como fallback');
        refinedCoordinates = positions;
        // Adiciona o primeiro ponto no final para fechar
        if (refinedCoordinates.isNotEmpty) {
          refinedCoordinates.add(
            mb.Position(
              refinedCoordinates.first.lng,
              refinedCoordinates.first.lat,
            ),
          );
        }
      }

      print('  - Total de pontos no polígono: ${refinedCoordinates.length}');

      // Converte para formato GeoJSON Feature com coordenadas refinadas
      final polygonCoordinates = refinedCoordinates.map((pos) {
        return [pos.lng, pos.lat]; // GeoJSON usa [lng, lat]
      }).toList();

      final geoJsonFeature = {
        'type': 'Feature',
        'id': 'territory-${DateTime.now().millisecondsSinceEpoch}',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [polygonCoordinates],
        },
        'properties': {'owner': 'Sistema', 'color': color, 'name': name},
      };

      // Adiciona à lista de features
      _territoriesFeatures.add(geoJsonFeature);

      // Atualiza o Source com a nova feature
      await _updateTerritoriesSource(_territoriesFeatures);

      print('  ✅ Território "$name" adicionado ao FillLayer!');
    } catch (e, stackTrace) {
      print('❌ Erro ao desenhar território "$name": $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Desenha um território específico usando os waypoints fornecidos
  /// Segue o caminho: Rua Arnaldo Victaliano -> Rua Atibaia -> Rua Itapira -> Rua Dr. Romeu Pereira -> Retorna
  Future<void> _drawTerritoryFromSpecificWaypoints() async {
    try {
      print('🗺️  Desenhando território específico com waypoints de ruas...');

      // Dados do território fornecidos pelo usuário
      final waypoints = [
        {
          'Ordem': 1,
          'Local de Passagem (Vias)': 'Início: Rua Arnaldo Victaliano',
          'Coordenadas Aproximadas (Lng, Lat)': '-47.7874, -21.1914',
        },
        {
          'Ordem': 2,
          'Local de Passagem (Vias)': 'Segue pela Rua Atibaia',
          'Coordenadas Aproximadas (Lng, Lat)': '-47.7895, -21.1882',
        },
        {
          'Ordem': 3,
          'Local de Passagem (Vias)': 'Vira na Rua Itapira',
          'Coordenadas Aproximadas (Lng, Lat)': '-47.7870, -21.1870',
        },
        {
          'Ordem': 4,
          'Local de Passagem (Vias)': 'Desce a Rua Dr. Romeu Pereira',
          'Coordenadas Aproximadas (Lng, Lat)': '-47.7858, -21.1902',
        },
        {
          'Ordem': 5,
          'Local de Passagem (Vias)': 'Retorna à Rua Arnaldo Victaliano',
          'Coordenadas Aproximadas (Lng, Lat)': '-47.7874, -21.1914',
        },
      ];

      // Usa o método para desenhar o território
      await drawTerritoryFromWaypoints(
        waypoints: waypoints,
        name: 'Jardim Paulista - Circuito Completo',
        color: '#00E5FF', // Padrão: Ciano (era roxo #7B2CBF)
      );

      print('✅ Território específico desenhado com sucesso!');
    } catch (e, stackTrace) {
      print('❌ Erro ao desenhar território específico: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Carrega e desenha os territórios fictícios de Ribeirão Preto
  /// Desenha 10 territórios grandes usando a cor roxa (#7B2CBF)
  Future<void> looadFictionalTerritories() async {
    if (mapboxMap == null) {
      print('ERRO: mapboxMap é null');
      return;
    }

    if (_polygonAnnotationManager == null) {
      print('ERRO: _polygonAnnotationManager é null');
      return;
    }

    try {
      print('🗺️  Carregando territórios fictícios de Ribeirão Preto...');

      // Cor roxa para todos os territórios fictícios
      const purpleColor = '#00E5FF'; // Ciano (era roxo #7B2CBF)

      // Dados dos territórios fictícios (coordenadas em [lng, lat])
      final fictionalTerritories = <Map<String, dynamic>>[
        {
          'name': 'Centro Histórico',
          'coordinates': <List<double>>[
            [-47.8100, -21.1780],
            [-47.8080, -21.1780],
            [-47.8080, -21.1760],
            [-47.8100, -21.1760],
            [-47.8100, -21.1780],
          ],
        },
        {
          'name': 'Jardim Paulista',
          'coordinates': <List<double>>[
            [-47.7874, -21.1914],
            [-47.7895, -21.1882],
            [-47.7870, -21.1870],
            [-47.7858, -21.1902],
            [-47.7874, -21.1914],
          ],
        },
        {
          'name': 'Nova Aliança',
          'coordinates': <List<double>>[
            [-47.8185, -21.2155],
            [-47.8160, -21.2170],
            [-47.8145, -21.2150],
            [-47.8170, -21.2135],
            [-47.8185, -21.2155],
          ],
        },
        {
          'name': 'Alto da Boa Vista',
          'coordinates': <List<double>>[
            [-47.8020, -21.2010],
            [-47.7990, -21.2010],
            [-47.7990, -21.1980],
            [-47.8020, -21.1980],
            [-47.8020, -21.2010],
          ],
        },
        {
          'name': 'Vila Seixas',
          'coordinates': <List<double>>[
            [-47.8050, -21.1880],
            [-47.8030, -21.1880],
            [-47.8030, -21.1860],
            [-47.8050, -21.1860],
            [-47.8050, -21.1880],
          ],
        },
        {
          'name': 'Santa Cruz',
          'coordinates': <List<double>>[
            [-47.7980, -21.1920],
            [-47.7950, -21.1920],
            [-47.7950, -21.1890],
            [-47.7980, -21.1890],
            [-47.7980, -21.1920],
          ],
        },
        {
          'name': 'Ipiranga',
          'coordinates': <List<double>>[
            [-47.8250, -21.1580],
            [-47.8220, -21.1580],
            [-47.8220, -21.1550],
            [-47.8250, -21.1550],
            [-47.8250, -21.1580],
          ],
        },
        {
          'name': 'Lagoinha',
          'coordinates': <List<double>>[
            [-47.7780, -21.1820],
            [-47.7740, -21.1820],
            [-47.7740, -21.1790],
            [-47.7780, -21.1790],
            [-47.7780, -21.1820],
          ],
        },
        {
          'name': 'Bonfim Paulista',
          'coordinates': <List<double>>[
            [-47.8200, -21.2350],
            [-47.8170, -21.2350],
            [-47.8170, -21.2320],
            [-47.8200, -21.2320],
            [-47.8200, -21.2350],
          ],
        },
        {
          'name': 'Campus USP',
          'coordinates': <List<double>>[
            [-47.8480, -21.1700],
            [-47.8420, -21.1700],
            [-47.8420, -21.1660],
            [-47.8480, -21.1660],
            [-47.8480, -21.1700],
          ],
        },
      ];

      print(
        '🎨 Desenhando ${fictionalTerritories.length} territórios fictícios...',
      );
      print(
        '🛣️  Usando API Directions do Mapbox para seguir as vias reais...',
      );

      // Desenha cada território fictício usando road snapping
      for (int i = 0; i < fictionalTerritories.length; i++) {
        final territory = fictionalTerritories[i];
        final name = territory['name'] as String;
        final coordinates = territory['coordinates'] as List<List<double>>;

        print(
          '📍 Desenhando território ${i + 1}/${fictionalTerritories.length}: $name',
        );

        try {
          // Converte as coordenadas para o formato Mapbox (Position)
          // Remove o último ponto duplicado (polígono fechado)
          final waypoints = <mb.Position>[];
          for (int j = 0; j < coordinates.length - 1; j++) {
            waypoints.add(mb.Position(coordinates[j][0], coordinates[j][1]));
          }

          print(
            '  - ${waypoints.length} waypoints para refinar com API Directions',
          );

          // Usa a API Directions do Mapbox para obter rota que segue as ruas
          // Isso garante que o polígono siga exatamente as vias disponíveis
          List<mb.Position> refinedCoordinates;

          try {
            // Obtém a rota refinada que conecta todos os waypoints seguindo as ruas
            refinedCoordinates = await _directionsService
                .getRouteThroughWaypoints(
                  points: waypoints,
                  profile: 'walking', // Usa perfil de caminhada
                );

            if (refinedCoordinates.isEmpty) {
              print(
                '  ⚠️  API Directions retornou rota vazia, usando pontos originais',
              );
              refinedCoordinates = waypoints;
            } else {
              print(
                '  ✅ Rota refinada: ${refinedCoordinates.length} pontos seguindo as ruas',
              );
            }

            // Garante que o polígono está fechado (primeiro ponto = último ponto)
            if (refinedCoordinates.isNotEmpty) {
              final firstPoint = refinedCoordinates.first;
              final lastPoint = refinedCoordinates.last;
              final isClosed =
                  (firstPoint.lat - lastPoint.lat).abs() < 0.000001 &&
                  (firstPoint.lng - lastPoint.lng).abs() < 0.000001;

              if (!isClosed) {
                print('  - Adicionando ponto de fechamento ao polígono');
                refinedCoordinates.add(
                  mb.Position(firstPoint.lng, firstPoint.lat),
                );
              }
            }
          } catch (e) {
            print('  ⚠️  Erro ao refinar rota com API Directions: $e');
            print('  Usando pontos originais como fallback');
            refinedCoordinates = waypoints;
            // Adiciona o primeiro ponto no final para fechar
            if (refinedCoordinates.isNotEmpty) {
              refinedCoordinates.add(
                mb.Position(
                  refinedCoordinates.first.lng,
                  refinedCoordinates.first.lat,
                ),
              );
            }
          }

          print(
            '  - Total de pontos no polígono: ${refinedCoordinates.length}',
          );

          // Converte para formato GeoJSON Feature com coordenadas refinadas
          final polygonCoordinates = refinedCoordinates.map((pos) {
            return [pos.lng, pos.lat]; // GeoJSON usa [lng, lat]
          }).toList();

          final geoJsonFeature = {
            'type': 'Feature',
            'id': 'fictional-${i + 1}',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [polygonCoordinates],
            },
            'properties': {
              'owner': 'Sistema',
              'color': purpleColor,
              'name': name,
            },
          };

          _territoriesFeatures.add(geoJsonFeature);

          print('  ✅ Território "$name" adicionado ao Source!');

          // Adiciona um pequeno delay entre requisições para não sobrecarregar a API
          if (i < fictionalTerritories.length - 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        } catch (e, stackTrace) {
          print('  ❌ Erro ao desenhar território "$name": $e');
          print('  Stack trace: $stackTrace');
        }
      }

      // Atualiza o Source com todos os territórios fictícios
      // Os territórios da API já estão em _territoriesFeatures de _loadAndDrawTerritories
      // Aqui apenas atualizamos o Source com todos os territórios (API + fictícios)
      print('📊 Total de features a atualizar: ${_territoriesFeatures.length}');

      // Atualiza o Source com todos os territórios
      await _updateTerritoriesSource(_territoriesFeatures);

      print(
        '✅ ${fictionalTerritories.length} territórios fictícios adicionados ao FillLayer na cor roxa!',
      );
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar territórios fictícios: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Método público para recarregar os territórios manualmente
  /// Útil para atualizar o mapa após capturar um novo território
  Future<void> reloadTerritories() async {
    print('🔄 Recarregando territórios manualmente...');
    await _loadAndDrawTerritories();
  }

  /// Verifica se dois bbox são significativamente diferentes
  /// Retorna true se a interseção for menor que 70% da área do novo bbox
  bool _bboxChangedSignificantly(List<double> bbox1, List<double> bbox2) {
    if (bbox1.length != 4 || bbox2.length != 4) return true;

    // Calcula a área do novo bbox (bbox2)
    final area2 = (bbox2[2] - bbox2[0]) * (bbox2[3] - bbox2[1]);

    // Calcula a interseção dos bbox
    final minLng = math.max(bbox1[0], bbox2[0]);
    final minLat = math.max(bbox1[1], bbox2[1]);
    final maxLng = math.min(bbox1[2], bbox2[2]);
    final maxLat = math.min(bbox1[3], bbox2[3]);

    if (minLng >= maxLng || minLat >= maxLat) {
      // Não há interseção, mudança significativa
      return true;
    }

    final intersectionArea = (maxLng - minLng) * (maxLat - minLat);

    // Se a interseção for menor que 70% da área do novo bbox, considera mudança significativa
    if (area2 == 0) return true;
    final overlapRatio = intersectionArea / area2;
    return overlapRatio < 0.7;
  }

  /// Verifica se a câmera mudou e recarrega territórios se necessário
  Future<void> _checkCameraChange() async {
    if (mapboxMap == null || _isLoadingTerritories) return;

    try {
      final currentBbox = await _getMapViewportBbox();
      if (currentBbox == null) return;

      // Se não há último bbox carregado ou mudou significativamente, recarrega
      if (_lastLoadedBbox == null ||
          _bboxChangedSignificantly(_lastLoadedBbox!, currentBbox)) {
        print(
          '🗺️  Câmera mudou significativamente, recarregando territórios...',
        );
        await _loadAndDrawTerritories(bbox: currentBbox);
      }
    } catch (e) {
      print('❌ Erro ao verificar mudança na câmera: $e');
    }
  }

  /// Inicia timer periódico para verificar mudanças na câmera do mapa
  /// Verifica a cada 2 segundos se a viewport mudou significativamente
  void _startCameraChangeCheckTimer() {
    _cameraChangeCheckTimer?.cancel();

    _cameraChangeCheckTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) {
      if (mapboxMap == null) {
        timer.cancel();
        return;
      }
      // Não verifica durante uma corrida (para não interferir)
      if (!isTracking.value) {
        _checkCameraChange();
      }
    });

    print('✅ Timer de verificação de mudanças na câmera iniciado');
  }
}
