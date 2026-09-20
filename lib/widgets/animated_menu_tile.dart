import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/sound_player.dart';

/// Плитка меню с тактильной анимацией нажатия (лёгкое сжатие + вибро-отклик
/// + звук) — используется в сетке быстрых действий профиля и в нижней
/// навигации, чтобы взаимодействие ощущалось "живым", а не плоским тапом.
class AnimatedMenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final bool dense;

  const AnimatedMenuTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.blue,
    this.badge,
    this.dense = false,
  }) : super(key: key);

  @override
  State<AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<AnimatedMenuTile> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (!mounted) return;
    setState(() => _scale = pressed ? 0.90 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.selectionClick();
        SoundPlayer.play(context, AppSound.click);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: widget.dense ? 10 : 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: widget.dense ? 38 : 44,
                    height: widget.dense ? 38 : 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(0.15),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.color, size: widget.dense ? 19 : 21),
                  ),
                  if (widget.badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 16),
                        child: Text(
                          widget.badge!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: widget.dense ? 10.5 : 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
