import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/settings_provider.dart';
import '../utils/cities_data.dart';

/// Тап-поле в стиле обычного текстового поля формы, но вместо клавиатуры
/// открывает список стран ([kSupportedCountries]) с поиском. Держит значение
/// в переданном [controller], поэтому существующий код форм (чтение
/// `controller.text` при сабмите) можно не менять.
class CountryPickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final ValueChanged<String>? onChanged;

  const CountryPickerField({
    Key? key,
    required this.controller,
    required this.label,
    this.required = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return _PickerField(
          label: required ? '$label *' : label,
          value: controller.text.isEmpty ? null : controller.text,
          onTap: () => _open(context),
        );
      },
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SearchableListSheet(
        title: context.t('country_city_picker.select_country_title'),
        items: kSupportedCountries,
      ),
    );
    if (picked != null && picked != controller.text) {
      controller.text = picked;
      onChanged?.call(picked);
    }
  }
}

/// Тап-поле для выбора города. Список городов берётся из
/// [kCitiesByCountry] по переданной [country]. Если страна ещё не выбрана
/// или для неё нет списка городов (например, значение "Другая") — виджет не
/// блокирует пользователя и откатывается на обычный [TextField].
class CityPickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? country;
  final bool required;
  final ValueChanged<String>? onChanged;

  const CityPickerField({
    Key? key,
    required this.controller,
    required this.label,
    required this.country,
    this.required = false,
    this.onChanged,
  }) : super(key: key);

  List<String>? get _cities {
    final c = country;
    if (c == null || c.isEmpty) return null;
    final list = kCitiesByCountry[c];
    if (list == null || list.isEmpty) return null;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cities = _cities;
    if (cities == null) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return _PickerField(
          label: required ? '$label *' : label,
          value: controller.text.isEmpty ? null : controller.text,
          onTap: () => _open(context, cities),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, List<String> cities) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SearchableListSheet(
        title: context.t('country_city_picker.select_city_title'),
        items: [...cities, kOtherCityLabel],
      ),
    );
    if (picked == null) return;
    if (picked == kOtherCityLabel) {
      final custom = await _promptCustomCity(context);
      if (custom != null && custom.trim().isNotEmpty) {
        controller.text = custom.trim();
        onChanged?.call(custom.trim());
      }
      return;
    }
    if (picked != controller.text) {
      controller.text = picked;
      onChanged?.call(picked);
    }
  }

  Future<String?> _promptCustomCity(BuildContext context) {
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('country_city_picker.custom_city_title')),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: dialogContext.t('country_city_picker.custom_city_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: Text(dialogContext.t('common.ok')),
          ),
        ],
      ),
    );
  }
}

/// Общее тап-поле, выглядящее как [TextFormField], но вместо клавиатуры
/// вызывающее [onTap] (открытие списка).
class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _PickerField({Key? key, required this.label, required this.value, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value ?? ''),
      ),
    );
  }
}

/// Боттомшит со строкой поиска и отфильтрованным списком вариантов.
class _SearchableListSheet extends StatefulWidget {
  final String title;
  final List<String> items;

  const _SearchableListSheet({Key? key, required this.title, required this.items}) : super(key: key);

  @override
  State<_SearchableListSheet> createState() => _SearchableListSheetState();
}

class _SearchableListSheetState extends State<_SearchableListSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.items
        : widget.items.where((c) => c.toLowerCase().contains(query)).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.t('common.search'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.t('common.not_found')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
