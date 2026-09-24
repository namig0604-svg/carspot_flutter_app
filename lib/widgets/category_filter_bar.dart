import 'package:flutter/material.dart';

/// Odin punkt filtra: znachenie kategorii, podpis, ikonka i tsvet.
class FilterChipData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const FilterChipData(this.value, this.label, this.icon, this.color);
}

/// Gorizontalnyy ryad tsvetnyh krugly ikonok-filtrov nad kartoy - kazhdaya
/// kategoriya svoim tsvetom, kak v prilozheniyah-referensah. Pusto vydeleno =
/// pokazyvat vse; vybor odnoy ili neskolkih kategoriy suzhaet spisok metok.
class CategoryFilterBar extends StatelessWidget {
  final List<FilterChipData> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const CategoryFilterBar({
    Key? key,
    required this.items,
    required this.selected,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final isActive = selected.isEmpty || selected.contains(item.value);
          return GestureDetector(
            onTap: () => onToggle(item.value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? item.color : item.color.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: selected.contains(item.value)
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isActive
                        ? [BoxShadow(color: item.color.withOpacity(0.45), blurRadius: 8)]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: isActive ? Colors.white : item.color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.white54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
