import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/car_picker_field.dart';
import '../l10n/l10n_extensions.dart';

const Map<String, String> _forecastTypeLabelKeys = {
  'oil': 'maintenance.type_oil',
  'tires': 'maintenance.type_tires',
  'brakes': 'part_listings.cat_brakes',
  'filters': 'maintenance.type_filters',
  'inspection': 'maintenance.type_inspection',
  'insurance': 'car_expenses.cat_insurance',
};

const Map<String, IconData> _forecastTypeIcons = {
  'oil': Icons.oil_barrel,
  'tires': Icons.tire_repair,
  'brakes': Icons.disc_full,
  'filters': Icons.filter_alt,
  'inspection': Icons.fact_check,
  'insurance': Icons.shield,
};

String _fmtDate(dynamic raw) {
  if (raw == null) return '—';
  final dt = DateTime.tryParse(raw.toString());
  if (dt == null) return raw.toString();
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

Color _urgencyColor(String urgency) {
  switch (urgency) {
    case 'overdue':
      return Colors.redAccent;
    case 'soon':
      return Colors.orange;
    default:
      return Colors.green;
  }
}

/// Прогноз следующего ТО — CarSpot Max. Считает по истории «Сервисного
/// дневника» (интервалы между записями одного типа по дате/пробегу), когда
/// примерно понадобится следующая замена масла/шин/фильтров и т.д. Если
/// пользователь сам указал дату/пробег следующего ТО в записи — используется
/// это значение (source == manual), иначе — статистическая оценка (estimated).
class MaintenanceForecastScreen extends StatefulWidget {
  const MaintenanceForecastScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceForecastScreen> createState() => _MaintenanceForecastScreenState();
}

class _MaintenanceForecastScreenState extends State<MaintenanceForecastScreen> {
  Map<String, dynamic>? _selectedCar;
  bool _isLoading = false;
  int? _currentMileage;
  List<dynamic> _items = [];

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
      final response = await ApiService.get(
        '/api/maintenance/forecast/${car['id']}',
        token: authProvider.accessToken,
      );
      setState(() {
        _currentMileage = response is Map ? response['current_mileage_km'] as int? : null;
        _items = response is Map && response['items'] is List ? response['items'] as List : [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('maintenance_forecast.title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t('maintenance_forecast.hint'),
              style: TextStyle(fontSize: 12.5, color: cardText.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            CarPickerField(onSelected: _onCarSelected),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: AppFullLoader()))
            else if (_selectedCar == null)
              const SizedBox.shrink()
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  context.t('maintenance_forecast.empty'),
                  style: TextStyle(color: cardText.withOpacity(0.6)),
                ),
              )
            else ...[
              if (_currentMileage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    context.tArgs('maintenance_forecast.current_mileage', {'km': '$_currentMileage'}),
                    style: TextStyle(fontSize: 13, color: cardText.withOpacity(0.7), fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _forecastCard(context, _items[i] as Map, cardText, isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _forecastCard(BuildContext context, Map item, Color cardText, bool isDark) {
    final type = item['type']?.toString() ?? '';
    final urgency = item['urgency']?.toString() ?? 'ok';
    final source = item['source']?.toString() ?? 'estimated';
    final color = _urgencyColor(urgency);
    final labelKey = _forecastTypeLabelKeys[type];
    final icon = _forecastTypeIcons[type] ?? Icons.build;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelKey != null ? context.t(labelKey) : type,
                        style: TextStyle(fontWeight: FontWeight.bold, color: cardText),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        context.t('maintenance_forecast.urgency_$urgency'),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (item['predicted_next_at'] != null)
                  Text(
                    context.tArgs('maintenance_forecast.predicted_date', {'date': _fmtDate(item['predicted_next_at'])}),
                    style: TextStyle(fontSize: 12.5, color: cardText.withOpacity(0.8)),
                  ),
                if (item['predicted_next_mileage_km'] != null)
                  Text(
                    context.tArgs('maintenance_forecast.predicted_mileage', {'km': '${item['predicted_next_mileage_km']}'}),
                    style: TextStyle(fontSize: 12.5, color: cardText.withOpacity(0.8)),
                  ),
                const SizedBox(height: 2),
                Text(
                  context.t('maintenance_forecast.source_$source'),
                  style: TextStyle(fontSize: 11, color: cardText.withOpacity(0.5), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
