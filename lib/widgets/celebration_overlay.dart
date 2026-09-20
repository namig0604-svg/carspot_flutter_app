import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Праздничный оверлей для нового уровня / нового достижения — большой эмодзи
/// с "выстрелом" конфетти вместо обычного SnackBar. Закрывается по тапу или
/// сам через несколько секунд.
Future<void> showCelebration(
  BuildContext context, {
  required String emoji,
  required String title,
  required String subtitle,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => _CelebrationDialog(emoji: emoji, title: title, subtitle: subtitle),
    transitionBuilder: (ctx, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        ),
      );
    },
  );
}

class _CelebrationDialog extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _CelebrationDialog({required this.emoji, required this.title, required this.subtitle});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final List<_ConfettiSpec> _confetti;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
    final rand = Random();
    _confetti = List.generate(16, (i) {
      final angle = (i / 16) * 2 * pi + rand.nextDouble() * 0.3;
      final distance = 70.0 + rand.nextDouble() * 60;
      final colors = [AppColors.blue, AppColors.red, Colors.amber, Colors.white];
      return _ConfettiSpec(
        dx: cos(angle) * distance,
        dy: sin(angle) * distance,
        color: colors[i % colors.length],
        size: 6.0 + rand.nextDouble() * 6,
      );
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  final t = Curves.easeOut.transform(_confettiController.value);
                  final fade = 1.0 - _confettiController.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: _confetti.map((c) {
                      return Positioned(
                        left: c.dx * t,
                        top: c.dy * t,
                        child: Opacity(
                          opacity: fade.clamp(0.0, 1.0),
                          child: Container(
                            width: c.size,
                            height: c.size,
                            decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.blue, width: 1.4),
                  boxShadow: [
                    BoxShadow(color: AppColors.blue.withOpacity(0.4), blurRadius: 30, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiSpec {
  final double dx;
  final double dy;
  final Color color;
  final double size;

  _ConfettiSpec({required this.dx, required this.dy, required this.color, required this.size});
}
