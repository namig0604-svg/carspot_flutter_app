import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bottom_nav_prefs_provider.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

/// Настройка нижней панели: пользователь сам выбирает, какие 4 раздела
/// показывать внизу (из 6 кандидатов — см. kBottomNavCandidates), в их
/// каноническом порядке. "Добавить" сюда не входит — она всегда отдельной
/// кнопкой по центру панели (см. home_screen.dart).
class BottomNavSettingsScreen extends StatefulWidget {
  const BottomNavSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavSettingsScreen> createState() => _BottomNavSettingsScreenState();
}

class _BottomNavSettingsScreenState extends State<BottomNavSettingsScreen> {
  late Set<String> _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selected = Provider.of<BottomNavPrefsProvider>(context, listen: false).sections.toSet();
  }

  void _toggle(String id, bool? checked) {
    setState(() {
      if (checked == true) {
        if (_selected.length < 4) _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  Future<void> _save() async {
    if (_selected.length != 4) return;
    setState(() => _isSaving = true);
    // Сохраняем в каноническом порядке kBottomNavCandidates, а не в порядке
    // тапов — так порядок пунктов в панели предсказуем и не зависит от
    // того, в какой последовательности пользователь их отмечал.
    final ordered = kBottomNavCandidates.map((s) => s.id).where(_selected.contains).toList();
    await Provider.of<BottomNavPrefsProvider>(context, listen: false).setSections(ordered);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(context.t('bottom_nav_settings.title')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.t('bottom_nav_settings.intro'),
              style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: kBottomNavCandidates.map((section) {
                final checked = _selected.contains(section.id);
                final disabled = !checked && count >= 4;
                return CheckboxListTile(
                  value: checked,
                  onChanged: disabled ? null : (v) => _toggle(section.id, v),
                  secondary: Icon(section.icon, color: disabled ? AppColors.textMutedDark : AppColors.blue),
                  title: Text(
                    context.t(section.labelKey),
                    style: TextStyle(color: disabled ? AppColors.textMutedDark : AppColors.textOnDark),
                  ),
                );
              }).toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      context.tArgs('bottom_nav_settings.selected_count', {'count': '$count'}),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: count == 4 ? AppColors.textOnDark : AppColors.amber, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (count == 4 && !_isSaving) ? _save : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                      child: Text(context.t('bottom_nav_settings.save')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
