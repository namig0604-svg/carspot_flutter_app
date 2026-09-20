import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/sound_player.dart';

class NavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavBarItem({required this.icon, this.activeIcon, required this.label});
}

/// Нижняя навигация с тактильной анимацией нажатия (сжатие иконки + вибро +
/// звук) и плавной подсветкой активного раздела — замена стандартному
/// BottomNavigationBar, который не даёт покадрового контроля над анимацией
/// нажатия отдельных пунктов.
class AnimatedBottomNav extends StatelessWidget {
  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNav({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.red.withOpacity(0.35), width: 1)),
        boxShadow: [
          BoxShadow(color: AppColors.red.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavBarButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatefulWidget {
  final NavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarButton({required this.item, required this.selected, required this.onTap});

  @override
  State<_NavBarButton> createState() => _NavBarButtonState();
}

class _NavBarButtonState extends State<_NavBarButton> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (!mounted) return;
    setState(() => _scale = pressed ? 0.85 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected ? AppColors.red : Colors.white38;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.selectionClick();
        if (!selected) SoundPlayer.play(context, AppSound.click);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.red.withOpacity(0.16) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? (widget.item.activeIcon ?? widget.item.icon) : widget.item.icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
