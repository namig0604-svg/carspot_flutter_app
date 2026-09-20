import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Неоновая "таблетка"-фильтр в стиле NFS Underground — замена стандартным
/// FilterChip/ChoiceChip, которые выглядели как обычный Material 2 виджет.
class NeonChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const NeonChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = AppColors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected
                ? LinearGradient(
                    colors: [color, Color.lerp(color, AppColors.black, 0.35)!],
                  )
                : null,
            color: selected ? null : AppColors.surfaceDark,
            border: Border.all(
              color: selected ? color : color.withOpacity(0.35),
              width: selected ? 0 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(0.55), blurRadius: 14, spreadRadius: 0.5)]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textOnDark.withOpacity(0.85),
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
