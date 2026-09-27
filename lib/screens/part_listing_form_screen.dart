import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/image_url_picker.dart' show ImageUrlPickerField;
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
import 'part_listings_screen.dart' show partCategoryLabels;

class PartListingFormScreen extends StatefulWidget {
  const PartListingFormScreen({Key? key}) : super(key: key);

  @override
  State<PartListingFormScreen> createState() => _PartListingFormScreenState();
}

class _PartListingFormScreenState extends State<PartListingFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _carBrandController = TextEditingController();
  final _carModelController = TextEditingController();
  final _cityController = TextEditingController();
  final _photoUrlController = TextEditingController();
  String _category = 'other';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _carBrandController.dispose();
    _carModelController.dispose();
    _cityController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);
    if (title.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('part_listing_form.name_price_required'))));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/part-listings',
        {
          'title': title,
          'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'price': price,
          'category': _category,
          'car_brand': _carBrandController.text.trim().isEmpty ? null : _carBrandController.text.trim(),
          'car_model': _carModelController.text.trim().isEmpty ? null : _carModelController.text.trim(),
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
      appBar: AppBar(title: Text(context.t('part_listing_form.title')), backgroundColor: AppColors.black),
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
          TextField(controller: _titleController, decoration: InputDecoration(labelText: context.t('part_listing_form.name_label'))),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.t('part_listing_form.description_label')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: context.t('part_listing_form.price_label')),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(labelText: context.t('car_expenses.category_label')),
            items: partCategoryLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(context.t(e.value))))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'other'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _carBrandController, decoration: InputDecoration(labelText: context.t('part_listing_form.brand_label')))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _carModelController, decoration: InputDecoration(labelText: context.t('part_listing_form.model_label')))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _cityController, decoration: InputDecoration(labelText: context.t('part_listing_form.city_label'))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(vertical: 14)),
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
