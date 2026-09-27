import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

/// Режим тайлов карты: тёмная / светлая / авто (следовать за темой
/// приложения). См. lib/utils/map_config.dart — именно этот режим
/// решает, какой urlTemplate использует TileLayer.
enum MapThemeMode { dark, light, auto }

/// Пилюля-переключатель темы карты (как "CCS Dark / CCS Light / Auto" в
/// приложениях-референсах) — ставится над картой одним из overlay-слоёв.
class MapThemeToggle extends StatelessWidget {
  final MapThemeMode value;
  final ValueChanged<MapThemeMode> onChanged;

  const MapThemeToggle({Key? key, required this.value, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <(MapThemeMode, IconData, String)>[
      (MapThemeMode.dark, Icons.dark_mode, 'map_theme.dark'),
      (MapThemeMode.light, Icons.light_mode, 'map_theme.light'),
      (MapThemeMode.auto, Icons.brightness_auto, 'map_theme.auto'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final selected = value == item.$1;
          return GestureDetector(
            onTap: () => onChanged(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.blue.withOpacity(0.22) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: selected ? Border.all(color: AppColors.blue, width: 1.2) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$2, size: 14, color: selected ? AppColors.blueBright : Colors.white60),
                  const SizedBox(width: 4),
                  Text(
                    context.t(item.$3),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
