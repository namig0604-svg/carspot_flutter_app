import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/image_url_picker.dart' show ImageUrlPickerField;
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

class CarListingFormScreen extends StatefulWidget {
  const CarListingFormScreen({Key? key}) : super(key: key);

  @override
  State<CarListingFormScreen> createState() => _CarListingFormScreenState();
}

class _CarListingFormScreenState extends State<CarListingFormScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _mileageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _photoUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _mileageController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final year = int.tryParse(_yearController.text.trim());
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    if (make.isEmpty || model.isEmpty || year == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('car_listing_form.required_fields_hint'))));
      return;
    }
    final mileage = double.tryParse(_mileageController.text.trim().replaceAll(',', '.'));

    setState(() => _isSaving = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/car-listings',
        {
          'make': make,
          'model': model,
          'year': year,
          'price': price,
          if (mileage != null) 'mileage_km': mileage,
          'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'photo_url': _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
          'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('car_listing_form.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ImageUrlPickerField(
            controller: _photoUrlController,
            token: authProvider.accessToken,
            galleryLabel: context.t('part_listing_form.gallery_label'),
            cameraLabel: context.t('hazards.type_camera'),
            errorTextBuilder: (e) => context.tArgs('part_listing_form.upload_error', {'error': '$e'}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: TextField(controller: _makeController, decoration: InputDecoration(labelText: context.t('car_listing_form.make_label')))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _modelController, decoration: InputDecoration(labelText: context.t('car_listing_form.model_label')))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: context.t('car_listing_form.year_label')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _mileageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: context.t('car_listing_form.mileage_label')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: context.t('car_listing_form.price_label')),
          ),
          const SizedBox(height: 10),
          TextField(controller: _cityController, decoration: InputDecoration(labelText: context.t('part_listing_form.city_label'))),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.t('part_listing_form.description_label')),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isSaving
                  ? const AppLoader(size: 20, color: Colors.white)
                  : Text(context.t('carpool.publish')),
            ),
          ),
        ],
      ),
    );
  }
}
