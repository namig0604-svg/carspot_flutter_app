import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

const String carsMineEndpoint = '/api/cars/my';

/// Переиспользуемый выбор машины пользователя — для сервисного дневника,
/// бардачка документов и учёта расходов. Если машин нет — показывает подсказку.
class CarPickerField extends StatefulWidget {
  final void Function(Map<String, dynamic> car) onSelected;
  final String? initialCarId;

  const CarPickerField({Key? key, required this.onSelected, this.initialCarId}) : super(key: key);

  @override
  State<CarPickerField> createState() => _CarPickerFieldState();
}

class _CarPickerFieldState extends State<CarPickerField> {
  List<dynamic> _cars = [];
  bool _isLoading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialCarId;
    _load();
  }

  Future<void> _load() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(carsMineEndpoint, token: authProvider.accessToken);
      final items = response is Map && response['cars'] is List
          ? response['cars'] as List
          : (response is List ? response : []);
      setState(() => _cars = items);
      if (_selectedId == null && _cars.isNotEmpty) {
        _selectedId = _cars.first['id'] as String?;
        final car = _cars.first as Map<String, dynamic>;
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSelected(car));
      }
    } catch (_) {
      // Тихо — ниже покажем подсказку "машин нет".
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: AppLoader(size: 24));
    if (_cars.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(context.t('car_picker.no_cars_hint'), style: const TextStyle(color: AppColors.textMutedDark)),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedId,
      decoration: InputDecoration(labelText: context.t('car_picker.label'), border: const OutlineInputBorder()),
      items: _cars.map((c) {
        final car = c as Map<String, dynamic>;
        final label = '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim();
        return DropdownMenuItem<String>(value: car['id'] as String, child: Text(label.isEmpty ? context.t('car_picker.label') : label));
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedId = value);
        final car = _cars.firstWhere((c) => c['id'] == value, orElse: () => null);
        if (car != null) widget.onSelected(car as Map<String, dynamic>);
      },
    );
  }
}
