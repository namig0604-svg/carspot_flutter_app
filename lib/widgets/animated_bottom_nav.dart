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
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.steel, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
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
    final color = selected ? AppColors.blue : AppColors.textMutedDark;
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
            Icon(
              selected ? (widget.item.activeIcon ?? widget.item.icon) : widget.item.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
