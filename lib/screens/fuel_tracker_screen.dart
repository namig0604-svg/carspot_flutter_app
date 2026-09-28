import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/car_picker_field.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';

/// Топливный трекер: заправки по выбранной машине + средний расход и
/// средняя цена литра, посчитанные сервером (GET /api/fuel-entries/car/{id}).
class FuelTrackerScreen extends StatefulWidget {
  const FuelTrackerScreen({Key? key}) : super(key: key);

  @override
  State<FuelTrackerScreen> createState() => _FuelTrackerScreenState();
}

class _FuelTrackerScreenState extends State<FuelTrackerScreen> {
  Map<String, dynamic>? _selectedCar;
  List<dynamic> _items = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  bool _isSaving = false;

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
      final response = await ApiService.get('/api/fuel-entries/car/${car['id']}', token: authProvider.accessToken);
      if (response is Map<String, dynamic>) {
        setState(() {
          _items = response['items'] is List ? response['items'] as List : [];
          _stats = response['stats'] is Map ? response['stats'] as Map<String, dynamic> : {};
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final car = _selectedCar;
    if (car == null) return;

    final litersController = TextEditingController();
    final costController = TextEditingController();
    final odometerController = TextEditingController();
    final stationController = TextEditingController();
    bool fullTank = true;
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.t('fuel_tracker.new_entry_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: litersController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: dialogContext.t('fuel_tracker.liters_label')),
                ),
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: dialogContext.t('fuel_tracker.cost_label')),
                ),
                TextField(
                  controller: odometerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: dialogContext.t('fuel_tracker.odometer_label')),
                ),
                TextField(
                  controller: stationController,
                  decoration: InputDecoration(labelText: dialogContext.t('fuel_tracker.station_label')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: fullTank,
                  title: Text(dialogContext.t('fuel_tracker.full_tank_label')),
                  subtitle: Text(dialogContext.t('fuel_tracker.full_tank_hint'), style: const TextStyle(fontSize: 11)),
                  onChanged: (v) => setDialogState(() => fullTank = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dialogContext.tArgs('fuel_tracker.date_label', {'date': '${date.day}.${date.month}.${date.year}'})),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('carpool.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('fuel_tracker.save'))),
          ],
        ),
      ),
    );

    final liters = double.tryParse(litersController.text.trim().replaceAll(',', '.'));
    final cost = double.tryParse(costController.text.trim().replaceAll(',', '.'));
    final odometer = double.tryParse(odometerController.text.trim().replaceAll(',', '.'));
    if (saved != true || liters == null || liters <= 0 || cost == null || cost < 0) return;

    setState(() => _isSaving = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/fuel-entries',
        {
          'car_id': car['id'],
          'date': date.toIso8601String(),
          'liters': liters,
          'total_cost': cost,
          'full_tank': fullTank,
          if (odometer != null) 'odometer_km': odometer,
          if (stationController.text.trim().isNotEmpty) 'station': stationController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEntry(String id) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/fuel-entries/$id', token: authProvider.accessToken);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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

  @override
  Widget build(BuildContext context) {
    final avgConsumption = _stats['avg_consumption_l_100km'];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('fuel_tracker.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      floatingActionButton: _selectedCar == null || _isSaving
          ? null
          : FloatingActionButton(
              onPressed: _addEntry,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            ),
      body: Stack(
        children: [
          const SectionBackground(
            accent: Colors.teal,
            glowAlignment: Alignment.topRight,
            imageAsset: 'assets/backgrounds/garage.jpg',
          ),
          Padding(
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
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _statTile(
                                context,
                                Icons.local_gas_station,
                                context.t('fuel_tracker.stat_total_cost'),
                                '${(_stats['total_cost'] as num?)?.toStringAsFixed(0) ?? 0}',
                              ),
                            ),
                            Expanded(
                              child: _statTile(
                                context,
                                Icons.sell_outlined,
                                context.t('fuel_tracker.stat_avg_price'),
                                '${(_stats['avg_price_per_liter'] as num?)?.toStringAsFixed(2) ?? 0}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _statTile(
                                context,
                                Icons.speed,
                                context.t('fuel_tracker.stat_consumption'),
                                avgConsumption == null
                                    ? '—'
                                    : '${(avgConsumption as num).toStringAsFixed(1)} ' '${context.t('fuel_tracker.unit_l_100km')}',
                              ),
                            ),
                            Expanded(
                              child: _statTile(
                                context,
                                Icons.opacity,
                                context.t('fuel_tracker.stat_total_liters'),
                                '${(_stats['total_liters'] as num?)?.toStringAsFixed(0) ?? 0}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _items.isEmpty
                        ? Center(
                            child: Text(
                              context.t('fuel_tracker.empty'),
                              style: TextStyle(color: AppColors.textMuted(context)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final e = _items[index] as Map<String, dynamic>;
                              final id = e['id'] as String;
                              return Dismissible(
                                key: ValueKey(id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: AppColors.red,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteEntry(id),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      e['full_tank'] == true ? Icons.local_gas_station : Icons.local_gas_station_outlined,
                                      color: Colors.teal,
                                    ),
                                    title: Text(
                                      context.tArgs('fuel_tracker.list_item', {
                                        'liters': '${(e['liters'] as num?)?.toStringAsFixed(1) ?? 0}',
                                        'cost': '${(e['total_cost'] as num?)?.toStringAsFixed(0) ?? 0}',
                                      }),
                                      style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      [
                                        _formatDate(e['date'] as String?),
                                        if (e['odometer_km'] != null) '${(e['odometer_km'] as num).toStringAsFixed(0)} ' '${context.t('fuel_tracker.unit_km')}',
                                        if ((e['station'] as String?)?.isNotEmpty == true) e['station'] as String,
                                      ].join(' • '),
                                      style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
