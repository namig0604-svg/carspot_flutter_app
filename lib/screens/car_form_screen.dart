import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/image_url_picker.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/car_data.dart';
import '../widgets/searchable_picker.dart';

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
      setState(() => _errorMessage = context.t('car_form.error_required_fields'));
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
          SnackBar(content: Text(_isEditing ? context.t('car_form.updated_message') : context.t('car_form.added_message'))),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = context.tArgs('car_form.error', {'error': '$e'}));
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

  Future<void> _pickBrand() async {
    try {
      final brands = kCarModelsByBrand.keys.toList()..sort();
      brands.add(kOtherBrandLabel);
      final selected = await showSearchablePicker(
        context,
        title: context.t('car_form.select_brand'),
        items: brands,
        searchHint: context.t('common.search'),
        emptyText: context.t('common.not_found'),
        currentValue: _makeController.text.isEmpty ? null : _makeController.text,
      );
      if (selected != null) {
        setState(() {
          if (_makeController.text != selected) {
            // Марка поменялась — сбрасываем модель, т.к. старая может не подходить новой марке.
            _modelController.clear();
          }
          _makeController.text = selected;
        });
      }
    } catch (e, st) {
      debugPrint('CarForm._pickBrand error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('car_form.error', {'error': '$e'}))),
        );
      }
    }
  }

  Future<void> _pickModel() async {
    try {
      final brand = _makeController.text.trim();
      if (brand.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('car_form.select_brand_first'))),
        );
        return;
      }

      final models = List<String>.from(kCarModelsByBrand[brand] ?? <String>[])..sort();
      if (models.isEmpty) {
        // Марка без готового списка моделей (например "Другая марка") — вводим вручную.
        final typed = await _showTextInputDialog(
          title: context.t('car_form.select_model'),
          initialValue: _modelController.text,
        );
        if (typed != null) {
          setState(() => _modelController.text = typed.trim());
        }
        return;
      }

      final selected = await showSearchablePicker(
        context,
        title: context.t('car_form.select_model'),
        items: models,
        searchHint: context.t('common.search'),
        emptyText: context.t('common.not_found'),
        currentValue: _modelController.text.isEmpty ? null : _modelController.text,
      );
      if (selected != null) {
        setState(() => _modelController.text = selected);
      }
    } catch (e, st) {
      debugPrint('CarForm._pickModel error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('car_form.error', {'error': '$e'}))),
        );
      }
    }
  }

  Future<String?> _showTextInputDialog({required String title, String? initialValue}) {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(context.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.t('common.ok')),
          ),
        ],
      ),
    );
  }

  Widget _pickerField(
    String label,
    String value,
    VoidCallback onTap, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: (value != null && options.contains(value)) ? value : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options
            .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
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
      appBar: AppBar(title: Text(_isEditing ? context.t('car_form.title_edit') : context.t('car_form.title_add'), overflow: TextOverflow.ellipsis, maxLines: 1)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context.t('car_form.section_basic')),
            _pickerField(
              context.t('car_form.field_make'),
              _makeController.text,
              _pickBrand,
              required: true,
            ),
            _pickerField(
              context.t('car_form.field_model'),
              _modelController.text,
              _pickModel,
              required: true,
            ),
            _dropdownField(
              context.t('car_form.field_year'),
              _yearController.text.isEmpty ? null : _yearController.text,
              kCarYears,
              (v) => setState(() => _yearController.text = v ?? ''),
            ),
            _field(_generationController, context.t('car_form.field_generation')),
            _dropdownField(
              context.t('car_form.field_body_type'),
              _bodyTypeController.text.isEmpty ? null : _bodyTypeController.text,
              kBodyTypes,
              (v) => setState(() => _bodyTypeController.text = v ?? ''),
            ),

            _sectionTitle(context.t('car_form.section_specs')),
            _field(_engineController, context.t('car_form.field_engine')),
            _field(_engineVolumeController, context.t('car_form.field_engine_volume')),
            _field(_powerController, context.t('car_form.field_power'), keyboardType: TextInputType.number),
            _field(_torqueController, context.t('car_form.field_torque'), keyboardType: TextInputType.number),
            _field(_drivetrainController, context.t('car_form.field_drivetrain')),
            _dropdownField(
              context.t('car_form.field_transmission'),
              _transmissionController.text.isEmpty ? null : _transmissionController.text,
              kTransmissionTypes,
              (v) => setState(() => _transmissionController.text = v ?? ''),
            ),
            _dropdownField(
              context.t('car_form.field_fuel_type'),
              _fuelTypeController.text.isEmpty ? null : _fuelTypeController.text,
              kFuelTypes,
              (v) => setState(() => _fuelTypeController.text = v ?? ''),
            ),
            _field(_weightController, context.t('car_form.field_weight'), keyboardType: TextInputType.number),
            _field(_zeroToHundredController, context.t('car_form.field_zero_to_hundred')),

            _sectionTitle(context.t('car_form.section_appearance')),
            _field(_colorController, context.t('car_form.field_color')),
            _field(_plateController, context.t('car_form.field_plate')),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: ImageUrlPickerField(
                controller: _photoUrlController,
                token: Provider.of<AuthProvider>(context, listen: false).accessToken,
                height: 160,
                placeholderIcon: Icons.directions_car_outlined,
                galleryLabel: context.t('car_form.pick_from_gallery'),
                cameraLabel: context.t('car_form.pick_from_camera'),
                errorTextBuilder: (e) => context.tArgs('car_form.photo_upload_error', {'error': '$e'}),
                onChanged: () => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                controller: _modsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.t('car_form.field_mods'),
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
                  labelText: context.t('car_form.field_description'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('car_form.for_sale_label')),
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
                        _isEditing ? context.t('common.save') : context.t('car_form.submit_add'),
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
