import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'category_filter_bar.dart';
import '../l10n/l10n_extensions.dart';

/// Bottom-sheet "Фильтры карты" — список категорий с чекбоксами (цветной
/// кружок + подпись), как модалка "Map filters" в референсе CCS. Открывается
/// по нажатию на иконку слайдеров рядом с переключателем темы карты, вместо
/// прежнего постоянного ряда круглых иконок прямо над картой (тот ряд не
/// помещался по высоте на части экранов — см. фикс overflow).
Future<void> showMapFiltersSheet({
  required BuildContext context,
  required List<FilterChipData> items,
  required Set<String> selected,
  required ValueChanged<String> onToggle,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.steelStrong,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sheetContext.t('map_filters.title'),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          sheetContext.tArgs('map_filters.count_label', {'count': selected.isEmpty ? sheetContext.t('map_filters.count_all') : '${selected.length}'}),
                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final checked = selected.isEmpty || selected.contains(item.value);
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              onToggle(item.value);
                              setSheetState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(item.icon, size: 18, color: item.color),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Checkbox(
                                    value: checked,
                                    activeColor: AppColors.blue,
                                    onChanged: (_) {
                                      onToggle(item.value);
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  onClear();
                                  setSheetState(() {});
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  side: const BorderSide(color: AppColors.steel),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(sheetContext.t('map_filters.reset')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.tune, size: 18),
                                label: Text(sheetContext.t('map_filters.apply')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
