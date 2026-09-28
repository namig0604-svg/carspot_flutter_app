import 'package:flutter/material.dart';
import 'category_filter_bar.dart' show FilterChipData;
import '../theme/app_colors.dart';

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
    // Раньше цвета неактивной карточки (фон/рамка/подпись) были жёстко
    // зашиты под тёмную тему (Colors.white с малой непрозрачностью,
    // Colors.white70 для текста) — в светлой теме подпись получалась почти
    // невидимой бледно-серой на белом. Берём theme-aware цвета из AppColors,
    // как это уже сделано в остальном приложении.
    final unselectedText = AppColors.onSurface(context);
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
              color: isSelected ? item.color.withOpacity(0.22) : AppColors.surfaceAlt(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? item.color : AppColors.border(context),
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
                    color: isSelected ? Colors.white : unselectedText.withOpacity(0.75),
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
