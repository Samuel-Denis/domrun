import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cropperx/cropperx.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:domrun/app/profile/controller/photo_selector_controller.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';

/// Tela de seleção de fotos da galeria com crop integrado
/// Permite escolher uma foto, fazer crop circular e retornar o arquivo
class PhotoSelectorPage extends GetView<PhotoSelectorController> {
  PhotoSelectorPage({super.key});

  final GlobalKey cropperKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final responsive = Responsive(context);

    return Container(
      decoration: BoxDecoration(color: AppColors.surface),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: GestureDetector(
            onTap: () => _showAlbumSelector(context, c, responsive),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  return Text(
                    c.currentAlbum.value?.name ?? 'Álbuns',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
                SizedBox(width: responsive.spacing(6)),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: responsive.iconSize(24),
                ),
              ],
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: responsive.iconSize(24),
            ),
            onPressed: () => Get.back(),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final Uint8List? png = await Cropper.crop(
                  cropperKey: cropperKey,
                  pixelRatio: 3,
                );
                if (png == null) return;

                final file = await c.saveCroppedImage(png);
                if (file != null) {
                  Get.back(result: file);
                }
              },
              child: Text(
                'Concluir',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (c.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.iconActive),
              ),
            );
          }

          return Column(
            children: [
              // Área de crop
              _buildCropArea(context, c, responsive),
              SizedBox(height: responsive.spacing(20)),

              // Grid de fotos
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scroll) {
                    if (scroll.metrics.pixels >=
                        scroll.metrics.maxScrollExtent - 200) {
                      c.loadNextPage();
                    }
                    return false;
                  },
                  child: Obx(
                    () => GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: responsive.spacing(2),
                        crossAxisSpacing: responsive.spacing(2),
                      ),
                      itemCount: c.photos.length,
                      itemBuilder: (_, i) {
                        final asset = c.photos[i];
                        // Usa Obx para reagir às mudanças do selectedIndex
                        return Obx(() {
                          final isSelected = c.selectedIndex.value == i;

                          return GestureDetector(
                            onTap: () => c.selectPhoto(asset, i),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FutureBuilder<Uint8List?>(
                                  future: c.loadThumbnail(asset),
                                  builder: (_, snap) {
                                    if (!snap.hasData) {
                                      return Container(
                                        color: const Color(0xFF2A2A2A),
                                      );
                                    }
                                    return Image.memory(
                                      snap.data!,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                                // Overlay de seleção
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withOpacity(0.3),
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.white,
                                      size: responsive.iconSize(24),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Constrói a área de crop circular
  Widget _buildCropArea(
    BuildContext context,
    PhotoSelectorController c,
    Responsive responsive,
  ) {
    return GetBuilder<PhotoSelectorController>(
      id: 'crop',
      builder: (_) {
        final bytes = c.selectedImageBytes.value;
        if (bytes == null) {
          return SizedBox(
            height: responsive.hp(40),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: responsive.wp(260),
            height: responsive.hp(260),
            child: ClipOval(
              child: Cropper(
                backgroundColor: AppColors.accentBlue,
                cropperKey: cropperKey,
                image: Image.memory(bytes),
                overlayType: OverlayType.circle,
                overlayColor: Colors.black54,
                aspectRatio: 1,
                zoomScale: 4.0,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Mostra o bottom sheet para seleção de álbuns
  void _showAlbumSelector(
    BuildContext context,
    PhotoSelectorController c,
    Responsive responsive,
  ) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.symmetric(horizontal: responsive.paddingHorizontal),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,

          borderRadius: BorderRadius.vertical(
            top: Radius.circular(responsive.spacing(22)),
          ),
        ),
        child: Column(
          children: [
            // Handle do bottom sheet
            Container(
              width: responsive.wp(45),
              height: responsive.hp(5),
              margin: EdgeInsets.all(responsive.spacing(14)),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(responsive.spacing(10)),
              ),
            ),

            Text(
              'Selecione um álbum',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.fontSize(17),
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: responsive.spacing(14)),

            Expanded(
              child: Obx(() {
                return GridView.builder(
                  padding: EdgeInsets.only(top: responsive.spacing(10)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: responsive.spacing(8),
                    crossAxisSpacing: responsive.spacing(8),
                    childAspectRatio: 0.8,
                  ),
                  itemCount: c.albums.length,
                  itemBuilder: (_, i) {
                    final album = c.albums[i];
                    final isSelected = c.currentAlbum.value?.id == album.id;

                    return GestureDetector(
                      onTap: () async {
                        await c.selectAlbum(album);
                        Get.back();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Preview da primeira foto do álbum
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 0.67,
                              child: FutureBuilder<List<AssetEntity>>(
                                future: album.getAssetListRange(
                                  start: 0,
                                  end: 1,
                                ),
                                builder: (_, snap) {
                                  if (!snap.hasData || snap.data!.isEmpty) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          responsive.spacing(8),
                                        ),
                                        border: isSelected
                                            ? Border.all(
                                                color: AppColors.white,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                    );
                                  }

                                  final firstAsset = snap.data!.first;

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      responsive.spacing(8),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        FutureBuilder<Uint8List?>(
                                          future: c.loadThumbnail(firstAsset),
                                          builder: (_, thumbSnap) {
                                            if (!thumbSnap.hasData) {
                                              return Container(
                                                color: Colors.white10,
                                              );
                                            }
                                            return Image.memory(
                                              thumbSnap.data!,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                        // Overlay de seleção
                                        if (isSelected)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    responsive.spacing(8),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: responsive.spacing(2)),

                          // Nome do álbum
                          Text(
                            album.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsive.fontSize(12),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Contagem de fotos
                          FutureBuilder<int>(
                            future: album.assetCountAsync,
                            builder: (_, snapCount) {
                              final count = snapCount.data ?? 0;
                              return Text(
                                '$count fotos',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: responsive.fontSize(10),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
