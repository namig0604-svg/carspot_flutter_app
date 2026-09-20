import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';

/// Форма машины: добавление новой (car == null) или редактирование существующей.
class CarFormScreen extends StatefulWidget {
  final Map<String, dynamic>? car;

  const CarFormScreen({Key? key, this.car}) : super(key: key);

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  bool get _isEditing => widget.car != null;

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _generationController = TextEditingController();
  final _bodyTypeController = TextEditingController();
  final _engineController = TextEditingController();
  final _engineVolumeController = TextEditingController();
  final _powerController = TextEditingController();
  final _torqueController = TextEditingController();
  final _drivetrainController = TextEditingController();
  final _transmissionController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _weightController = TextEditingController();
  final _zeroToHundredController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  final _modsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _isForSale = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final car = widget.car;
    if (car != null) {
      _makeController.text = car['make'] ?? '';
      _modelController.text = car['model'] ?? '';
      _yearController.text = car['year']?.toString() ?? '';
      _generationController.text = car['generation'] ?? '';
      _bodyTypeController.text = car['body_type'] ?? '';
      _engineController.text = car['engine'] ?? '';
      _engineVolumeController.text = car['engine_volume'] ?? '';
      _powerController.text = car['power_hp']?.toString() ?? '';
      _torqueController.text = car['torque_nm']?.toString() ?? '';
      _drivetrainController.text = car['drivetrain'] ?? '';
      _transmissionController.text = car['transmission'] ?? '';
      _fuelTypeController.text = car['fuel_type'] ?? '';
      _weightController.text = car['weight_kg']?.toString() ?? '';
      _zeroToHundredController.text = car['zero_to_hundred'] ?? '';
      _colorController.text = car['color'] ?? '';
      _plateController.text = car['license_plate'] ?? '';
      _modsController.text = car['mods'] ?? '';
      _descriptionController.text = car['description'] ?? '';
      _photoUrlController.text = car['photo_url'] ?? '';
      _isForSale = car['is_for_sale'] ?? false;
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _generationController.dispose();
    _bodyTypeController.dispose();
    _engineController.dispose();
    _engineVolumeController.dispose();
    _powerController.dispose();
    _torqueController.dispose();
    _drivetrainController.dispose();
    _transmissionController.dispose();
    _fuelTypeController.dispose();
    _weightController.dispose();
    _zeroToHundredController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _modsController.dispose();
    _descriptionController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _submit() async {
    if (_makeController.text.trim().isEmpty || _modelController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Укажи марку и модель');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final body = {
      'make': _makeController.text.trim(),
      'model': _modelController.text.trim(),
      'year': _int(_yearController),
      'generation': _text(_generationController),
      'body_type': _text(_bodyTypeController),
      'engine': _text(_engineController),
      'engine_volume': _text(_engineVolumeController),
      'power_hp': _int(_powerController),
      'torque_nm': _int(_torqueController),
      'drivetrain': _text(_drivetrainController),
      'transmission': _text(_transmissionController),
      'fuel_type': _text(_fuelTypeController),
      'weight_kg': _int(_weightController),
      'zero_to_hundred': _text(_zeroToHundredController),
      'color': _text(_colorController),
      'license_plate': _text(_plateController),
      'mods': _text(_modsController),
      'description': _text(_descriptionController),
      'photo_url': _text(_photoUrlController),
      'is_for_sale': _isForSale,
    };

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isEditing) {
        await ApiService.patch(
          '/api/cars/${widget.car!['id']}',
          body,
          token: authProvider.accessToken,
        );
      } else {
        await ApiService.post('/api/cars/', body, token: authProvider.accessToken);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Машина обновлена' : 'Машина добавлена в гараж 🚗')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Изменить машину' : 'Добавить машину')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Основное'),
            _field(_makeController, 'Марка', required: true),
            _field(_modelController, 'Модель', required: true),
            _field(_yearController, 'Год выпуска', keyboardType: TextInputType.number),
            _field(_generationController, 'Поколение (например S15)'),
            _field(_bodyTypeController, 'Тип кузова (coupe / sedan / suv...)'),

            _sectionTitle('Характеристики'),
            _field(_engineController, 'Двигатель (например SR20DET)'),
            _field(_engineVolumeController, 'Объём (л)'),
            _field(_powerController, 'Мощность (л.с.)', keyboardType: TextInputType.number),
            _field(_torqueController, 'Крутящий момент (Нм)', keyboardType: TextInputType.number),
            _field(_drivetrainController, 'Привод (RWD / FWD / AWD)'),
            _field(_transmissionController, 'Трансмиссия (manual / automatic)'),
            _field(_fuelTypeController, 'Тип топлива (petrol / diesel / electric)'),
            _field(_weightController, 'Вес (кг)', keyboardType: TextInputType.number),
            _field(_zeroToHundredController, 'Разгон 0-100 (сек)'),

            _sectionTitle('Внешний вид'),
            _field(_colorController, 'Цвет'),
            _field(_plateController, 'Гос. номер'),
            _field(_photoUrlController, 'Ссылка на фото (URL)'),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                controller: _modsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Доработки (тюнинг)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Продаётся'),
              value: _isForSale,
              onChanged: (v) => setState(() => _isForSale = v),
            ),

            const SizedBox(height: 10),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? AppLoader(size: 22, color: Colors.white)
                    : Text(
                        _isEditing ? 'Сохранить' : 'Добавить в гараж',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
