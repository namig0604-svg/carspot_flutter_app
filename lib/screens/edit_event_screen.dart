import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/event_duration.dart';
import 'location_picker_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/country_city_picker.dart';
import '../widgets/image_url_picker.dart';
import '../l10n/l10n_extensions.dart';

/// Редактирование существующей сходки — доступно только создателю.
/// Дата/время, продолжительность и точка на карте настраиваются здесь же:
/// когда event_date + duration_minutes истекает, сервер сам скрывает сходку.
class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EditEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late final _titleController = TextEditingController(text: widget.event['title'] ?? '');
  late final _coverUrlController = TextEditingController(text: widget.event['cover_url'] ?? '');
  late final _descriptionController = TextEditingController(text: widget.event['description'] ?? '');
  late final _locationController =
      TextEditingController(text: widget.event['location_name'] ?? widget.event['address'] ?? '');
  late final _cityController = TextEditingController(text: widget.event['city'] ?? '');
  late final _countryController = TextEditingController(text: widget.event['country'] ?? '');
  late final _dateController = TextEditingController();
  late final _timeController = TextEditingController(text: widget.event['event_time'] ?? '');

  late String _selectedType = (widget.event['event_type'] as String?) ?? 'meetup';
  late int _durationMinutes = closestEventDuration((widget.event['duration_minutes'] as int?) ?? 120);
  late bool _isPrivate = widget.event['is_private'] == true;
  late double? _latitude = (widget.event['latitude'] as num?)?.toDouble();
  late double? _longitude = (widget.event['longitude'] as num?)?.toDouble();

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _eventTypes = [
    'meetup', 'racing', 'drift', 'drag', 'offroad', 'show', 'cruise', 'track_day', 'charity'
  ];

  bool get _isClubEvent => widget.event['club_id'] != null;

  @override
  void initState() {
    super.initState();
    try {
      final parsed = DateTime.parse(widget.event['event_date'].toString());
      _dateController.text = parsed.toString().split(' ')[0];
    } catch (_) {
      _dateController.text = '';
    }
  }

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
    DateTime initial;
    try {
      initial = DateTime.parse(_dateController.text);
    } catch (_) {
      initial = DateTime.now();
    }
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
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
    TimeOfDay initial = TimeOfDay.now();
    final parts = _timeController.text.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
    }
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: initial);
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

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      setState(() => _errorMessage = context.t('edit_event.fill_required_fields'));
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _errorMessage = context.t('edit_event.pick_location_on_map'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dateTime = '${_dateController.text}T${_timeController.text}:00';

      final body = {
        'title': _titleController.text.trim(),
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
        if (_isClubEvent) 'is_private': _isPrivate,
      };

      await ApiService.patch('/api/events/${widget.event['id']}', body, token: authProvider.accessToken);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('edit_event.event_updated'))),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = context.tArgs('edit_event.error_prefix', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('edit_event.delete_confirm_title')),
        content: Text(context.t('edit_event.delete_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('common.delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/events/${widget.event['id']}', token: authProvider.accessToken);
      if (mounted) {
        Navigator.pop(context, 'deleted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('edit_event.event_deleted'))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('edit_event.error_prefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('edit_event.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: context.t('edit_event.delete_tooltip'),
            onPressed: _isLoading ? null : _delete,
          ),
        ],
      ),
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
                galleryLabel: context.t('edit_event.pick_from_gallery'),
                cameraLabel: context.t('edit_event.pick_from_camera'),
                errorTextBuilder: (e) => context.tArgs('edit_event.cover_upload_error', {'error': '$e'}),
                onChanged: () => setState(() {}),
              ),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.t('edit_event.title_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.t('edit_event.description_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: context.t('edit_event.type_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _eventTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 15),

            CountryPickerField(
              controller: _countryController,
              label: context.t('edit_event.country_label'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),

            CityPickerField(
              controller: _cityController,
              label: context.t('edit_event.city_label'),
              country: _countryController.text.isEmpty ? null : _countryController.text,
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: context.t('edit_event.location_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: Icon(_latitude == null ? Icons.map_outlined : Icons.check_circle, color: _latitude == null ? null : Colors.green),
              label: Text(
                _latitude == null
                    ? context.t('edit_event.pick_location_button')
                    : context.tArgs('edit_event.location_point', {
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
                  labelText: context.t('edit_event.date_label'),
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
                  labelText: context.t('edit_event.time_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: const Icon(Icons.access_time),
                ),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<int>(
              value: _durationMinutes,
              decoration: InputDecoration(
                labelText: context.t('edit_event.duration_label'),
                helperText: context.t('edit_event.duration_helper'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: eventDurationOptions
                  .map((o) => DropdownMenuItem(value: o.minutes, child: Text(o.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _durationMinutes = value);
              },
            ),

            if (_isClubEvent) ...[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.lock_outline, color: Colors.blueGrey),
                title: Text(context.t('edit_event.private_event_title')),
                subtitle: Text(context.t('edit_event.private_event_subtitle')),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
            ],

            const SizedBox(height: 20),

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
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? AppLoader(size: 22, color: Colors.white)
                    : Text(context.t('common.save'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
