import 'package:flutter/material.dart';
import 'category_filter_bar.dart' show FilterChipData;

/// Setka tsvetnyh kartochek kategorii dlya vybora ODNOY kategorii (forma
/// sozdaniya sobytiya/servisa) - vizualno tot zhe stil, chto i
/// CategoryFilterBar nad kartoy, no v vide setki s podpisyu i ramkoy vokrug
/// vybrannoy kartochki (zdes vazhna odnoznachnost vybora, ne prosto tsvet).
class CategoryPickerGrid extends StatelessWidget {
  final List<FilterChipData> items;
  final String selected;
  final ValueChanged<String> onSelect;

  const CategoryPickerGrid({
    Key? key,
    required this.items,
    required this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = item.value == selected;
        return GestureDetector(
          onTap: () => onSelect(item.value),
          child: Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? item.color.withOpacity(0.22) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? item.color : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                  child: Icon(item.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
