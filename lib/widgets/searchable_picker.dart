import 'package:flutter/material.dart';

/// Универсальный боттомшит с полем поиска для выбора одного значения
/// из списка строк (например марка/модель машины).
///
/// Возвращает выбранное значение или null, если пользователь закрыл шит
/// без выбора.
Future<String?> showSearchablePicker(
  BuildContext context, {
  required String title,
  required List<String> items,
  String? searchHint,
  String? emptyText,
  String? currentValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _SearchablePickerSheet(
      title: title,
      items: items,
      searchHint: searchHint,
      emptyText: emptyText,
      currentValue: currentValue,
    ),
  );
}

class _SearchablePickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? searchHint;
  final String? emptyText;
  final String? currentValue;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    this.searchHint,
    this.emptyText,
    this.currentValue,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((i) => i.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          widget.emptyText ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = _filtered[i];
                          final selected = item == widget.currentValue;
                          return ListTile(
                            title: Text(item),
                            trailing: selected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
