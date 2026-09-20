import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Тёмная "подложка" раздела в стиле NFS Underground — карбоновая штриховка
/// + мягкое неоновое свечение акцентного цвета в углу. Кладётся первым слоем
/// в Stack позади обычного контента экрана, чтобы пустые места ожили,
/// а сам контент (карточки, поля) остаётся как есть — просто "парит" сверху.
class SectionBackground extends StatelessWidget {
  final Color accent;
  final Alignment glowAlignment;
  final String? imageAsset;

  const SectionBackground({
    Key? key,
    this.accent = AppColors.blue,
    this.glowAlignment = Alignment.topRight,
    this.imageAsset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null) {
      // Настоящее фото-фото раздела + тёмная дымка сверху/снизу, чтобы
      // контент (карточки, текст, поиск) оставался читаемым на любом фото.
      return Positioned.fill(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imageAsset!, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withOpacity(0.55),
                    AppColors.black.withOpacity(0.35),
                    AppColors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SectionBackgroundPainter(accent: accent, glowAlignment: glowAlignment),
        ),
      ),
    );
  }
}

class _SectionBackgroundPainter extends CustomPainter {
  final Color accent;
  final Alignment glowAlignment;

  _SectionBackgroundPainter({required this.accent, required this.glowAlignment});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = AppColors.black);

    final glowCenter = glowAlignment.alongSize(size);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [accent.withOpacity(0.28), accent.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: size.longestSide * 0.55));
    canvas.drawRect(rect, glowPaint);

    final linePaint = Paint()
      ..color = AppColors.surfaceDarkAlt.withOpacity(0.5)
      ..strokeWidth = 1;
    const step = 14.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }
    for (double x = 0; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), linePaint);
    }

    final dir = glowAlignment.x >= 0 ? 1.0 : -1.0;
    final speedPaint = Paint()
      ..color = accent.withOpacity(0.18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final dx = glowCenter.dx - i * 26 * dir;
      canvas.drawLine(
        Offset(dx, glowCenter.dy - 40 + i * 4),
        Offset(dx - 70 * dir, glowCenter.dy + 10 + i * 4),
        speedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SectionBackgroundPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.glowAlignment != glowAlignment;
  }
}
