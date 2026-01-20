import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/profile/controller/photo_selector_controller.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';

/// Widget de grid de fotos com scroll infinito
class PhotoGridWidget extends StatefulWidget {
  final PhotoSelectorController controller;
  final Responsive responsive;

  const PhotoGridWidget({
    super.key,
    required this.controller,
    required this.responsive,
  });

  @override
  State<PhotoGridWidget> createState() => _PhotoGridWidgetState();
}

class _PhotoGridWidgetState extends State<PhotoGridWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Detecta quando o scroll chega perto do fim para carregar mais fotos
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Carrega próxima página quando chega a 80% do scroll
      widget.controller.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.photos.isEmpty) {
        return Center(
          child: Text(
            'Nenhuma foto encontrada',
            style: TextStyle(
              color: Colors.white70,
              fontSize: widget.responsive.fontSize(16),
            ),
          ),
        );
      }

      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(widget.responsive.spacing(10)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: widget.responsive.spacing(5),
          mainAxisSpacing: widget.responsive.spacing(5),
        ),
        itemCount: widget.controller.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.controller.photos[index];
          final isSelected = widget.controller.selectedIndex.value == index;

          return GestureDetector(
            onTap: () => widget.controller.selectPhoto(photo, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail da foto
                FutureBuilder<Uint8List?>(
                  future: widget.controller.loadThumbnail(photo),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.responsive.spacing(4),
                        ),
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      );
                    }
                    return Container(
                      color: const Color(0xFF2A2A2A),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentBlue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Overlay de seleção
                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.3),
                      border: Border.all(color: AppColors.accentBlue, width: 3),
                      borderRadius: BorderRadius.circular(
                        widget.responsive.spacing(4),
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.white,
                      size: widget.responsive.iconSize(24),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}
