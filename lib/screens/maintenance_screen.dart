import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_picker_field.dart';

const Map<String, String> _typeLabels = {
  'oil': 'Замена масла',
  'tires': 'Шиномонтаж',
  'brakes': 'Тормоза',
  'filters': 'Фильтры',
  'inspection': 'ТО / диагностика',
  'repair': 'Ремонт',
  'insurance': 'Страховка',
  'other': 'Другое',
};

const Map<String, IconData> _typeIcons = {
  'oil': Icons.oil_barrel,
  'tires': Icons.tire_repair,
  'brakes': Icons.disc_full,
  'filters': Icons.filter_alt,
  'inspection': Icons.fact_check,
  'repair': Icons.build,
  'insurance': Icons.shield,
  'other': Icons.more_horiz,
};

/// Сервисный дневник авто: история ТО/ремонтов + напоминание о следующем разе.
/// GET/POST /api/maintenance.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Map<String, dynamic>? _selectedCar;
  List<dynamic> _records = [];
  bool _isLoading = false;

  Future<void> _onCarSelected(Map<String, dynamic> car) async {
    setState(() => _selectedCar = car);
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    final car = _selectedCar;
    if (car == null) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/maintenance/car/${car['id']}', token: authProvider.accessToken);
      final items = response is Map && response['items'] is List ? response['items'] as List : [];
      setState(() => _records = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addRecord() async {
    final car = _selectedCar;
    if (car == null) return;

    String type = 'oil';
    final titleController = TextEditingController();
    final mileageController = TextEditingController();
    final costController = TextEditingController();
    final noteController = TextEditingController();
    DateTime doneAt = DateTime.now();
    DateTime? nextDueAt;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Новая запись'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Тип'),
                  items: _typeLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v ?? 'oil'),
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Что сделали')),
                TextField(
                  controller: mileageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Пробег, км (необязательно)'),
                ),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Стоимость (необязательно)'),
                ),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Дата: ${doneAt.day}.${doneAt.month}.${doneAt.year}'),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked =
                      await showDatePicker(
                      context: dialogContext,
                      initialDate: doneAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => doneAt = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(nextDueAt == null
                      ? 'Напомнить в следующий раз:  не задано'
                      : 'Напомнить: ${nextDueAt!.day}.${nextDueAt!.month}.${nextDueAt!.year}'),
                  trailing: const Icon(Icons.notifications_active_outlined, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setDialogState(() => nextDueAt = picked);
                  },
                ),
                TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Заметка')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сохранить')),
          ],
        ),
      ),
    );

    if (saved != true || titleController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/maintenance',
        {
          'car_id': car['id'],
          'type': type,
          'title': titleController.text.trim(),
          'done_at': doneAt.toIso8601String(),
          if (mileageController.text.trim().isNotEmpty) 'mileage_km': int.tryParse(mileageController.text.trim()),
          if (costController.text.trim().isNotEmpty) 'cost': double.tryParse(costController.text.trim()),
          if (noteController.text.trim().isNotEmpty) 'note': noteController.text.trim(),
          if (nextDueAt != null) 'next_due_at': nextDueAt!.toIso8601String(),
        },
        token: authProvider.accessToken,
      );
      _loadRecords();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сервисныщ дневник'), backgroundColor: AppColors.black),
      floatingActionButton: _selectedCar == null
          ? null
          : FloatingActionButton(onPressed: _addRecord, backgroundColor: AppColors.blue, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarPickerField(onSelected: _onCarSelected),
            const SizedBox(height: 16),
            if (_isLoading) const Expanded(child: Center(child: AppLoader()))
            else if (_selectedCar == null)
              const Expanded(child: SizedBox.shrink())
            else if (_records.isEmpty)
              const Expanded(
                child: Center(child: Text('Записей пока нет — нажмите + чтобы добавить', style: TextStyle(color: AppColors.textMutedDark))),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index] as Map<String, dynamic>;
                    final type = (r['type'] as String?) ?? 'other';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.steel),
                      ),
                      child: Row(
                        children: [
                          Icon(_typeIcons[type] ?? Icons.build, color: AppColors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDate(r['done_at'] as String?)}'
                                  '${r['mileage_km'] != null ? ' · ${r['mileage_km']} км' : ''}'
                                  '${r['cost'] != null ? ' · ${r['cost']} ₽' : ''}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                                ),
                                if (r['next_due_at'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Напоминание: ${_formatDate(r['next_due_at'] as String?)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.amber),
                                  ),
                                  ),
                            ],
                          ),
                      ),
                    ],
                  ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
