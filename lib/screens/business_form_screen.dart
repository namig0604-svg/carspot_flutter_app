import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/business_category.dart';
import 'location_picker_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Форма заведения: добавление нового (business == null) или редактирование (владелец).
class BusinessFormScreen extends StatefulWidget {
  final Map<String, dynamic>? business;

  const BusinessFormScreen({Key? key, this.business}) : super(key: key);

  @override
  State<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends State<BusinessFormScreen> {
  bool get _isEditing => widget.business != null;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servicesController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _workHoursController = TextEditingController();

  String _category = 'service';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    if (b != null) {
      _nameController.text = b['name'] ?? '';
      _category = (b['category'] as String?) ?? 'service';
      _descriptionController.text = b['description'] ?? '';
      _servicesController.text = b['services'] ?? '';
      _logoUrlController.text = b['logo_url'] ?? '';
      _coverUrlController.text = b['cover_url'] ?? '';
      _countryController.text = b['country'] ?? '';
      _cityController.text = b['city'] ?? '';
      _addressController.text = b['address'] ?? '';
      _latController.text = b['latitude'] != null ? b['latitude'].toString() : '';
      _lonController.text = b['longitude'] != null ? b['longitude'].toString() : '';
      _phoneController.text = b['phone'] ?? '';
      _websiteController.text = b['website'] ?? '';
      _instagramController.text = b['instagram'] ?? '';
      _workHoursController.text = b['work_hours'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servicesController.dispose();
    _logoUrlController.dispose();
    _coverUrlController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _workHoursController.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  double? _number(TextEditingController c) => c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _number(_latController),
          initialLongitude: _number(_lonController),
        ),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        _latController.text = (result['latitude'] as num).toStringAsFixed(6);
        _lonController.text = (result['longitude'] as num).toStringAsFixed(6);
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().length < 2) {
      setState(() => _errorMessage = context.t('business_form.name_too_short'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final body = {
      'name': _nameController.text.trim(),
      'category': _category,
      'description': _text(_descriptionController),
      'services': _text(_servicesController),
      'logo_url': _text(_logoUrlController),
      'cover_url': _text(_coverUrlController),
      'country': _text(_countryController),
      'city': _text(_cityController),
      'address': _text(_addressController),
      'latitude': _number(_latController),
      'longitude': _number(_lonController),
      'phone': _text(_phoneController),
      'website': _text(_websiteController),
      'instagram': _text(_instagramController),
      'work_hours': _text(_workHoursController),
    };

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isEditing) {
        await ApiService.patch(
          '/api/businesses/${widget.business!['id']}',
          body,
          token: authProvider.accessToken,
        );
      } else {
        await ApiService.post('/api/businesses/', body, token: authProvider.accessToken);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? context.t('business_form.updated_success') : context.t('business_form.created_success'))),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = context.tArgs('business_form.error_message', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? context.t('business_form.edit_business_title') : context.t('business_form.add_business'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_nameController, context.t('business_form.label_name'), required: true),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: context.t('business_form.label_category'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: businessCategories
                  .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 15),

            _field(_descriptionController, context.t('business_form.label_description'), maxLines: 3),
            _field(_servicesController, context.t('business_form.label_services')),
            _field(_logoUrlController, context.t('business_form.label_logo_url')),
            _field(_coverUrlController, context.t('business_form.label_cover_url')),
            _field(_countryController, context.t('business_form.label_country')),
            _field(_cityController, context.t('business_form.label_city')),
            _field(_addressController, context.t('business_form.label_address')),

            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map_outlined),
              label: Text(context.t('business_form.pick_location_button')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _field(
                    _latController,
                    context.t('business_form.label_latitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    _lonController,
                    context.t('business_form.label_longitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ),

            _field(_phoneController, context.t('business_form.label_phone'), keyboardType: TextInputType.phone),
            _field(_websiteController, context.t('business_form.label_website')),
            _field(_instagramController, 'Instagram'),
            _field(_workHoursController, context.t('business_form.label_work_hours')),

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
                        _isEditing ? context.t('common.save') : context.t('business_form.add_business'),
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
