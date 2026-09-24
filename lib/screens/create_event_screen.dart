import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/event_duration.dart';
import '../utils/event_type_style.dart';
import '../widgets/category_filter_bar.dart' show FilterChipData;
import '../widgets/category_picker_grid.dart';
import 'location_picker_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/country_city_picker.dart';
import '../widgets/image_url_picker.dart';
import '../l10n/l10n_extensions.dart';

class CreateEventScreen extends StatefulWidget {
  /// Если передан — сходка создаётся как событие клуба (только владелец/админ
  /// клуба может сюда попасть). В этом случае доступен переключатель
  /// "закрытая сходка" (видна и доступна только участникам клуба).
  final String? clubId;

  const CreateEventScreen({Key? key, this.clubId}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String _selectedType = 'meetup';
  int _durationMinutes = 120;
  bool _isLoading = false;
  bool _isPrivate = false;
  String? _errorMessage;


  // Координаты выбираются на карте — без метки создать сходку нельзя,
  // иначе она не попадёт ни в поиск рядом, ни на карту.
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLatitude: _latitude, initialLongitude: _longitude),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        _latitude = (result['latitude'] as num).toDouble();
        _longitude = (result['longitude'] as num).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clubId != null ? context.t('create_event.title_club') : context.t('create_event.title'), overflow: TextOverflow.ellipsis, maxLines: 1)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: ImageUrlPickerField(
                controller: _coverUrlController,
                token: Provider.of<AuthProvider>(context, listen: false).accessToken,
                height: 150,
                placeholderIcon: Icons.image_outlined,
                galleryLabel: context.t('create_event.pick_from_gallery'),
                cameraLabel: context.t('create_event.pick_from_camera'),
                errorTextBuilder: (e) => context.tArgs('create_event.cover_upload_error', {'error': '$e'}),
                onChanged: () => setState(() {}),
              ),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.t('create_event.title_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.t('create_event.description_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(context.t('create_event.type_label'), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            CategoryPickerGrid(
              items: eventTypeStyles
                  .map((t) => FilterChipData(t.value, t.label, t.icon, t.color))
                  .toList(),
              selected: _selectedType,
              onSelect: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 15),

            CountryPickerField(
              controller: _countryController,
              label: context.t('create_event.country_label'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),

            CityPickerField(
              controller: _cityController,
              label: context.t('create_event.city_label'),
              country: _countryController.text.isEmpty ? null : _countryController.text,
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: context.t('create_event.location_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: Icon(_latitude == null ? Icons.map_outlined : Icons.check_circle, color: _latitude == null ? null : Colors.green),
              label: Text(
                _latitude == null
                    ? context.t('create_event.pick_location_button')
                    : context.tArgs('create_event.location_point_selected', {
                        'lat': _latitude!.toStringAsFixed(4),
                        'lng': _longitude!.toStringAsFixed(4),
                      }),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: _selectDate,
              child: TextField(
                controller: _dateController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: context.t('create_event.date_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: _selectTime,
              child: TextField(
                controller: _timeController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: context.t('create_event.time_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: const Icon(Icons.access_time),
                ),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<int>(
              value: _durationMinutes,
              decoration: InputDecoration(
                labelText: context.t('create_event.duration_label'),
                helperText: context.t('create_event.duration_helper'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: eventDurationOptions
                  .map((o) => DropdownMenuItem(value: o.minutes, child: Text(o.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _durationMinutes = value);
              },
            ),

            if (widget.clubId != null) ...[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.lock_outline, color: Colors.blueGrey),
                title: Text(context.t('create_event.private_event_title')),
                subtitle: Text(context.t('create_event.private_event_subtitle')),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
            ],

            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                  ? AppLoader(size: 22, color: Colors.white)
                  : Text(context.t('create_event.title'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createEvent() async {
    if (_titleController.text.isEmpty || _cityController.text.isEmpty ||
        _dateController.text.isEmpty || _timeController.text.isEmpty) {
      setState(() => _errorMessage = context.t('create_event.fill_required_fields'));
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _errorMessage = context.t('create_event.pick_location_on_map'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String dateTime = '${_dateController.text}T${_timeController.text}:00';

      final body = {
        'title': _titleController.text,
        'cover_url': _coverUrlController.text.trim().isEmpty ? null : _coverUrlController.text.trim(),
        'description': _descriptionController.text,
        'event_type': _selectedType,
        'country': _countryController.text,
        'city': _cityController.text,
        'location_name': _locationController.text,
        'address': _locationController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'event_date': dateTime,
        'event_time': _timeController.text,
        'duration_minutes': _durationMinutes,
        'max_participants': null,
        'is_private': widget.clubId != null ? _isPrivate : false,
      };
      if (widget.clubId != null) {
        body['club_id'] = widget.clubId;
      }

      final response = await ApiService.post('/api/events/', body, token: authProvider.accessToken);

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('create_event.event_created'))),
      );
    } catch (e) {
      setState(() => _errorMessage = context.tArgs('create_event.error_prefix', {'error': e.toString()}));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
