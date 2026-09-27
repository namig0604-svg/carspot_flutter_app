import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Форма онлайн-записи в автосервис/ателье: выбор услуги (из списка
/// заведения), даты и времени, комментарий. POST /api/bookings/business/{id}.
class CreateBookingScreen extends StatefulWidget {
  final Map<String, dynamic> business;
  const CreateBookingScreen({Key? key, required this.business}) : super(key: key);

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  String? _selectedService;
  DateTime? _date;
  TimeOfDay? _time;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  List<String> get _services => (widget.business['services'] as String? ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('create_booking.pick_datetime'))));
      return;
    }
    final requestedAt = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/bookings/business/${widget.business['id']}',
        {
          if (_selectedService != null) 'service': _selectedService,
          'requested_at': requestedAt.toIso8601String(),
          if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('create_booking.submitted'))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tArgs('create_booking.title', {'name': '${widget.business['name'] ?? ''}'}), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (services.isNotEmpty) ...[
            Text(context.t('create_booking.service_label'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((s) {
                final selected = _selectedService == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  selectedColor: AppColors.blue.withOpacity(0.25),
                  onSelected: (_) => setState(() => _selectedService = selected ? null : s),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          Text(context.t('create_booking.date_time_label'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _date == null
                        ? context.t('create_booking.pick_date')
                        : '${_date!.day.toString().padLeft(2, '0')}.${_date!.month.toString().padLeft(2, '0')}.${_date!.year}',
                  ),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_time == null ? context.t('create_booking.pick_time') : _time!.format(context)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.t('carpool.comment_label'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: context.t('create_booking.note_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const AppLoader(size: 22, color: Colors.white)
                  : Text(context.t('create_booking.submit'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
