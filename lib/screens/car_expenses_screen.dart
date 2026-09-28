import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/car_picker_field.dart';
import '../l10n/l10n_extensions.dart';

// Значения — ключи переводов, переводятся через context.t() в местах
// использования (эта карта — не готовый текст для отображения).
const Map<String, String> _categoryLabels = {
  'fuel': 'car_expenses.cat_fuel',
  'service': 'car_expenses.cat_service',
  'insurance': 'car_expenses.cat_insurance',
  'parking': 'home.menu_parking',
  'carwash': 'car_expenses.cat_carwash',
  'fines': 'car_expenses.cat_fines',
  'other': 'hazards.type_other',
};

const Map<String, IconData> _categoryIcons = {
  'fuel': Icons.local_gas_station,
  'service': Icons.build,
  'insurance': Icons.shield,
  'parking': Icons.local_parking,
  'carwash': Icons.local_car_wash,
  'fines': Icons.receipt_long,
  'other': Icons.more_horiz,
};

/// Учёт расходов на авто: топливо, ТО, страховка, штрафы и т.д. + сводка по месяцу.
/// GET/POST/DELETE /api/car-expenses.
class CarExpensesScreen extends StatefulWidget {
  const CarExpensesScreen({Key? key}) : super(key: key);

  @override
  State<CarExpensesScreen> createState() => _CarExpensesScreenState();
}

class _CarExpensesScreenState extends State<CarExpensesScreen> {
  Map<String, dynamic>? _selectedCar;
  List<dynamic> _items = [];
  Map<String, dynamic> _byCategory = {};
  double _totalAmount = 0;
  bool _isLoading = false;

  Future<void> _onCarSelected(Map<String, dynamic> car) async {
    setState(() => _selectedCar = car);
    await _load();
  }

  Future<void> _load() async {
    final car = _selectedCar;
    if (car == null) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/car-expenses/car/${car['id']}', token: authProvider.accessToken);
      if (response is Map<String, dynamic>) {
        setState(() {
          _items = response['items'] is List ? response['items'] as List : [];
          _byCategory = response['by_category'] is Map ? response['by_category'] as Map<String, dynamic> : {};
          _totalAmount = (response['total_amount'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addExpense() async {
    final car = _selectedCar;
    if (car == null) return;

    String category = 'fuel';
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.t('car_expenses.new_expense_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: dialogContext.t('car_expenses.category_label')),
                items: _categoryLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(dialogContext.t(e.value)))).toList(),
                onChanged: (v) => setDialogState(() => category = v ?? 'fuel'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: dialogContext.t('car_expenses.amount_label')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dialogContext.tArgs('car_expenses.date_label', {'date': '${date.day}.${date.month}.${date.year}'})),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
              TextField(controller: noteController, decoration: InputDecoration(labelText: dialogContext.t('car_expenses.note_label'))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('carpool.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('car_expenses.save'))),
          ],
        ),
      ),
    );

    final amount = double.tryParse(amountController.text.trim());
    if (saved != true || amount == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/car-expenses',
        {
          'car_id': car['id'],
          'category': category,
          'amount': amount,
          'date': date.toIso8601String(),
          if (noteController.text.trim().isNotEmpty) 'note': noteController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('car_expenses.title')), backgroundColor: AppColors.black),
      floatingActionButton: _selectedCar == null
          ? null
          : FloatingActionButton(onPressed: _addExpense, backgroundColor: AppColors.blue, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarPickerField(onSelected: _onCarSelected),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: AppFullLoader()))
            else if (_selectedCar == null)
              const Expanded(child: SizedBox.shrink())
            else ...[
              Container(
                padding: const EdgeInsets.all(14),
                // Было жёстко AppColors.surfaceDarkAlt (тёмная плашка) без
                // цвета текста — в светлой теме получался тёмный текст на
                // тёмном фоне. surfaceAlt(context) сам выбирает тёмный/светлый
                // вариант под текущую тему, а onSurface(context) — читаемый
                // текст под него.
                decoration: BoxDecoration(color: AppColors.surfaceAlt(context), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tArgs('car_expenses.total', {'amount': _totalAmount.toStringAsFixed(0)}),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface(context)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: _byCategory.entries
                          .map((e) => Chip(label: Text(context.tArgs('car_expenses.chip_category_amount', {'category': context.t(_categoryLabels[e.key] ?? e.key), 'amount': (e.value as num).toStringAsFixed(0)}))))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _items.isEmpty
                    ? Center(child: Text(context.t('car_expenses.empty'), style: const TextStyle(color: AppColors.textMutedDark)))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final e = _items[index] as Map<String, dynamic>;
                          final category = (e['category'] as String?) ?? 'other';
                          return ListTile(
                            leading: Icon(_categoryIcons[category] ?? Icons.more_horiz, color: AppColors.blue),
                            title: Text(context.tArgs('car_expenses.list_item', {'amount': '${(e['amount'] as num?)?.toStringAsFixed(0) ?? 0}', 'category': context.t(_categoryLabels[category] ?? category)})),
                            subtitle: Text(_formatDate(e['date'] as String?)),
                          );
                        },
                      ),
              ),
            ],
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
