import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:domrun/core/theme/app_colors.dart';

/// Widget que desenha um fundo decorativo com padrão de mapa
/// Simula linhas de estradas brilhantes em roxo/magenta sobre fundo escuro
/// Cria um efeito visual futurista de rede urbana
class MapBackground extends StatelessWidget {
  /// Opacidade das linhas (0.0 a 1.0)
  final double opacity;

  /// Intensidade do brilho das linhas
  final double glowIntensity;

  const MapBackground({
    super.key,
    this.opacity = 0.3,
    this.glowIntensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MapBackgroundPainter(
        opacity: opacity,
        glowIntensity: glowIntensity,
      ),
      size: Size.infinite,
    );
  }
}

/// Classe que desenha o padrão de mapa
/// Cria linhas radiais e concêntricas em roxo/magenta brilhante
class MapBackgroundPainter extends CustomPainter {
  final double opacity;
  final double glowIntensity;

  MapBackgroundPainter({required this.opacity, required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Cor das linhas (roxo/magenta brilhante)
    final lineColor = Color.lerp(
      AppColors.accentBlue,
      AppColors.accentPurple,
      0.5,
    )!.withOpacity(opacity);

    // Cor do brilho (mais clara e brilhante)
    final glowColor = AppColors.accentPurple.withOpacity(opacity * 0.5);

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Centro do canvas (centralizado)
    final center = Offset(size.width / 2, size.height / 2);

    // Tamanho fixo para o padrão (sem zoom) - tamanho original fixo
    // O padrão será desenhado sempre no mesmo tamanho, independente do tamanho da tela
    // Ajuste este valor para controlar o tamanho do padrão (em pixels)
    const double maxRadius = 400.0; // Raio fixo - sem zoom ou escala

    // Desenha linhas radiais (como raios saindo do centro)
    _drawRadialLines(canvas, center, maxRadius, paint, glowPaint);

    // Desenha círculos concêntricos
    _drawConcentricCircles(canvas, center, maxRadius, paint, glowPaint);

    // Desenha linhas de grade adicionais
    _drawGridLines(canvas, size, paint, glowPaint);
  }

  /// Desenha linhas radiais saindo do centro
  /// Cria um padrão de estrela/teia de aranha
  void _drawRadialLines(
    Canvas canvas,
    Offset center,
    double maxRadius,
    Paint paint,
    Paint glowPaint,
  ) {
    // Número de linhas radiais
    const int numLines = 12;

    for (int i = 0; i < numLines; i++) {
      // Calcula o ângulo para cada linha
      final angle = (2 * math.pi * i) / numLines;

      // Calcula o ponto final da linha
      final endX = center.dx + maxRadius * math.cos(angle);
      final endY = center.dy + maxRadius * math.sin(angle);

      final endPoint = Offset(endX, endY);

      // Desenha o brilho primeiro (mais largo)
      canvas.drawLine(center, endPoint, glowPaint);

      // Desenha a linha principal por cima
      canvas.drawLine(center, endPoint, paint);
    }
  }

  /// Desenha círculos concêntricos ao redor do centro
  /// Cria anéis que cruzam com as linhas radiais
  void _drawConcentricCircles(
    Canvas canvas,
    Offset center,
    double maxRadius,
    Paint paint,
    Paint glowPaint,
  ) {
    // Número de círculos concêntricos
    const int numCircles = 8;

    for (int i = 1; i <= numCircles; i++) {
      final radius = (maxRadius * i) / numCircles;

      // Desenha o brilho primeiro
      canvas.drawCircle(center, radius, glowPaint);

      // Desenha o círculo principal
      canvas.drawCircle(center, radius, paint);
    }
  }

  /// Desenha linhas de grade adicionais
  /// Cria um padrão de grade irregular nas bordas
  void _drawGridLines(Canvas canvas, Size size, Paint paint, Paint glowPaint) {
    // Linhas horizontais
    for (int i = 0; i < 15; i++) {
      final y = (size.height * i) / 15;
      final startX = size.width * 0.2;
      final endX = size.width * 0.8;

      // Desenha apenas algumas linhas para não sobrecarregar
      if (i % 3 == 0) {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), glowPaint);
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      }
    }

    // Linhas verticais
    for (int i = 0; i < 15; i++) {
      final x = (size.width * i) / 15;
      final startY = size.height * 0.2;
      final endY = size.height * 0.8;

      // Desenha apenas algumas linhas para não sobrecarregar
      if (i % 3 == 0) {
        canvas.drawLine(Offset(x, startY), Offset(x, endY), glowPaint);
        canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
