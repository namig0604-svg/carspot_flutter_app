import 'package:flutter/material.dart';

/// Rezhim taylov karty: temnaya / svetlaya / avto (sledovat za temoy
/// prilozheniya). Sm. lib/utils/map_config.dart - imenno etot rezhim
/// reshaet, kakoy urlTemplate ispolzuet TileLayer.
enum MapThemeMode { dark, light, auto }

/// Pilyulya-perekluchatel temy karty (kak "CCS Dark / CCS Light / Auto" v
/// prilozheniyah-referensah) - stavitsya nad kartoy odnim iz overlay-slojov.
class MapThemeToggle extends StatelessWidget {
  final MapThemeMode value;
  final ValueChanged<MapThemeMode> onChanged;

  const MapThemeToggle({Key? key, required this.value, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <(MapThemeMode, IconData, String)>[
      (MapThemeMode.dark, Icons.dark_mode, 'Тёмная'),
      (MapThemeMode.light, Icons.light_mode, 'Светлая'),
      (MapThemeMode.auto, Icons.brightness_auto, 'Авто'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.blueAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$2, size: 14, color: selected ? Colors.white : Colors.white70),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    Text(item.$3, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
