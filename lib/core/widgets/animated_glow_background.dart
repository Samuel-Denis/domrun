import 'dart:math';
import 'package:flutter/material.dart';

class GlowParticlesBackground extends StatefulWidget {
  const GlowParticlesBackground({super.key});

  @override
  State<GlowParticlesBackground> createState() =>
      _GlowParticlesBackgroundState();
}

class _GlowParticlesBackgroundState extends State<GlowParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          children: [
            // Fundo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1929), Color(0xFF020B13)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Glow grande difuso
            _bigGlow(
              x: 0.25,
              y: 0.3,
              size: 350,
              color: const Color(0xFF00E5FF),
            ),

            _bigGlow(
              x: 0.8,
              y: 0.75,
              size: 300,
              color: const Color(0xFFAA00FF),
            ),

            // Partículas
            CustomPaint(
              painter: _GlowParticlePainter(_controller.value),
              size: Size.infinite,
            ),
          ],
        );
      },
    );
  }

  Widget _bigGlow({
    required double x,
    required double y,
    required double size,
    required Color color,
  }) {
    final screen = MediaQuery.of(context).size;

    return Positioned(
      left: screen.width * x - size / 2,
      top: screen.height * y - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: size,
              spreadRadius: size / 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowParticlePainter extends CustomPainter {
  final double t;
  final Random random = Random(42);

  _GlowParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.plus;

    for (int i = 0; i < 45; i++) {
      final dx =
          size.width * (0.1 + (i * 37 % 100) / 100) + sin(t * 2 * pi + i) * 20;

      final dy =
          size.height * (0.1 + (i * 53 % 100) / 100) + cos(t * 2 * pi + i) * 20;

      final radius = 1.5 + (i % 3);
      final opacity = 0.15 + (i % 5) * 0.05;

      paint.color =
          (i % 2 == 0 ? const Color(0xFF00E5FF) : const Color(0xFFAA00FF))
              .withOpacity(opacity);

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
