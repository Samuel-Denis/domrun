import 'package:flutter/material.dart';
import 'package:domrun/core/theme/app_colors.dart';

/// Widget que exibe uma imagem de mapa como fundo
/// Use este widget se você tiver uma imagem real do mapa
/// Para usar, coloque a imagem em assets/images/map_background.png
/// e use MapImageBackground() ao invés de MapBackground()
class MapImageBackground extends StatelessWidget {
  /// Caminho da imagem (opcional, padrão: assets/images/map_background.png)
  final String? imagePath;

  /// Opacidade da imagem (0.0 a 1.0)
  final double opacity;

  const MapImageBackground({super.key, this.imagePath, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    // Se não houver imagem, retorna o padrão gerado
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withValues(alpha: 0.1),
            AppColors.surface.withValues(alpha: 0.3),
            AppColors.surface,
            AppColors.surface,
          ],
        ),
      ),
      child: imagePath != null
          ? Opacity(
              opacity: opacity,
              child: Image.asset(
                imagePath!,
                fit: BoxFit.cover, // Cobre toda a área mantendo proporção
                alignment: Alignment.topCenter, // Alinha no topo
                repeat: ImageRepeat.noRepeat, // Não repete a imagem
                // Se a imagem não for encontrada, mostra um placeholder
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.accentBlue,
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        color: AppColors.white,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
            )
          : Container(color: AppColors.white),
    );
  }
}
