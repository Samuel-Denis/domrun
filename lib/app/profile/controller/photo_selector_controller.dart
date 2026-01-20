import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

/// Controller para seleção de fotos da galeria
/// Gerencia álbuns, paginação, cache de thumbnails e seleção de imagens
class PhotoSelectorController extends GetxController {
  // Lista de fotos do álbum atual
  final RxList<AssetEntity> photos = <AssetEntity>[].obs;

  // Lista de álbuns disponíveis
  final RxList<AssetPathEntity> albums = <AssetPathEntity>[].obs;

  // Álbum atualmente selecionado
  final Rxn<AssetPathEntity> currentAlbum = Rxn<AssetPathEntity>();

  // Bytes da imagem selecionada (para preview e crop)
  final Rxn<Uint8List> selectedImageBytes = Rxn<Uint8List>();

  // Cache de thumbnails para melhor performance
  final Map<String, Future<Uint8List?>> _thumbnailCache = {};

  // Controle de paginação
  static const int _pageSize = 80;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasNoMorePages = false;

  // Índice da foto selecionada
  final RxInt selectedIndex = (-1).obs;

  // Estado de carregamento
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAlbums();
  }

  /// Carrega todos os álbuns disponíveis
  Future<void> _loadAlbums() async {
    try {
      isLoading.value = true;

      // Solicita permissão de acesso à galeria
      final permission = await PhotoManager.requestPermissionExtend();

      // Verifica se a permissão foi concedida
      // No Android 11+, permissão limitada (limited) ainda permite acesso básico
      // No Android 10 e anteriores, apenas authorized permite acesso
      final hasAccess =
          permission == PermissionState.authorized ||
          permission == PermissionState.limited ||
          permission.isAuth;

      if (!hasAccess) {
        isLoading.value = false;

        // Verifica o status da permissão
        if (permission == PermissionState.denied) {
          // Permissão negada - mostra mensagem e tenta novamente
          Get.snackbar(
            'Permissão Necessária',
            'Precisamos de acesso à sua galeria para selecionar fotos. Por favor, permita o acesso.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            mainButton: TextButton(
              onPressed: () async {
                // Tenta solicitar permissão novamente
                final newPermission =
                    await PhotoManager.requestPermissionExtend();
                final newHasAccess =
                    newPermission == PermissionState.authorized ||
                    newPermission == PermissionState.limited;
                if (newHasAccess) {
                  await _loadAlbums();
                } else {
                  Get.snackbar(
                    'Permissão Negada',
                    'Para acessar suas fotos, habilite a permissão nas configurações do dispositivo.',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  await Future.delayed(const Duration(seconds: 1));
                  await PhotoManager.openSetting();
                }
              },
              child: const Text(
                'Permitir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
          return;
        } else {
          // Permissão negada permanentemente - abre configurações
          Get.snackbar(
            'Permissão Negada',
            'O acesso à galeria foi negado. Por favor, habilite nas configurações do dispositivo.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
            colorText: Colors.white,
            mainButton: TextButton(
              onPressed: () async {
                await PhotoManager.openSetting();
              },
              child: const Text(
                'Abrir Configurações',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
          // Abre as configurações automaticamente após um breve delay
          await Future.delayed(const Duration(seconds: 1));
          await PhotoManager.openSetting();
          return;
        }
      }

      // Busca lista de álbuns
      final rawAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.updateDate,
              asc: false, // Mais recentes primeiro
            ),
          ],
        ),
      );

      // Busca contagem de fotos em cada álbum (em paralelo para melhor performance)
      final albumsWithCounts = await Future.wait(
        rawAlbums.map((album) async {
          final count = await album.assetCountAsync;
          return {'album': album, 'count': count};
        }),
      );

      // Remove álbuns vazios
      albumsWithCounts.removeWhere((item) => (item['count'] as int) == 0);

      // Ordena por quantidade de fotos (maior para menor)
      albumsWithCounts.sort(
        (a, b) => (b['count']! as int).compareTo(a['count']! as int),
      );

      // Atribui álbuns ordenados
      albums.assignAll(
        albumsWithCounts
            .map((item) => item['album'] as AssetPathEntity)
            .toList(),
      );

      // Carrega o primeiro álbum automaticamente
      if (albums.isNotEmpty) {
        await selectAlbum(albums.first);
      }

      isLoading.value = false;
    } catch (e) {
      print('Erro ao carregar álbuns: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar as fotos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Seleciona um álbum e carrega suas fotos
  Future<void> selectAlbum(AssetPathEntity album) async {
    try {
      currentAlbum.value = album;

      // Reseta paginação
      _currentPage = 0;
      _hasNoMorePages = false;
      photos.clear();
      selectedIndex.value = -1;
      selectedImageBytes.value = null;

      // Carrega primeira página
      final assets = await album.getAssetListPaged(page: 0, size: _pageSize);

      if (assets.isEmpty) {
        _hasNoMorePages = true;
        return;
      }

      photos.assignAll(assets);
      _currentPage = 1;

      // Seleciona automaticamente a primeira foto
      if (assets.isNotEmpty) {
        await selectPhoto(assets.first, 0);
      }
    } catch (e) {
      print('Erro ao selecionar álbum: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar as fotos do álbum',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Carrega a próxima página de fotos (paginação infinita)
  Future<void> loadNextPage() async {
    if (_isLoadingMore || _hasNoMorePages) return;

    final album = currentAlbum.value;
    if (album == null) return;

    try {
      _isLoadingMore = true;

      final assets = await album.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      if (assets.isEmpty) {
        _hasNoMorePages = true;
      } else {
        photos.addAll(assets);
        _currentPage++;
      }
    } catch (e) {
      print('Erro ao carregar próxima página: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Carrega thumbnail de uma foto (com cache)
  Future<Uint8List?> loadThumbnail(AssetEntity asset) {
    return _thumbnailCache.putIfAbsent(
      asset.id,
      () => asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 60,
      ),
    );
  }

  /// Seleciona uma foto e carrega seus bytes
  Future<void> selectPhoto(AssetEntity asset, int index) async {
    try {
      selectedIndex.value = index;

      // 1. Carrega thumbnail primeiro para feedback imediato
      final thumbnail = await loadThumbnail(asset);
      if (thumbnail != null) {
        selectedImageBytes.value = thumbnail;
        update(['crop']); // Atualiza a área de crop
      }

      // 2. Carrega imagem em resolução completa em background
      final file = await asset.file;
      if (file == null) return;

      final fullBytes = await file.readAsBytes();

      // 3. Atualiza apenas se ainda for a foto selecionada
      if (selectedIndex.value == index) {
        selectedImageBytes.value = fullBytes;
        update(['crop']); // Atualiza a área de crop com a imagem completa
      }
    } catch (e) {
      print('Erro ao selecionar foto: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar a foto',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Salva a imagem cropada em um arquivo temporário
  Future<File?> saveCroppedImage(Uint8List bytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Erro ao salvar imagem cropada: $e');
      return null;
    }
  }

  /// Limpa o cache de thumbnails
  void clearCache() {
    _thumbnailCache.clear();
  }

  @override
  void onClose() {
    clearCache();
    super.onClose();
  }
}
