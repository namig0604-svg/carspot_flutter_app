import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/image_url.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../l10n/l10n_extensions.dart';

class CarpoolScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const CarpoolScreen({Key? key, required this.eventId, required this.eventTitle}) : super(key: key);

  @override
  State<CarpoolScreen> createState() => _CarpoolScreenState();
}

class _CarpoolScreenState extends State<CarpoolScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/carpool/event/${widget.eventId}', token: authProvider.accessToken);
      setState(() => _offers = (response is Map && response['items'] is List) ? response['items'] : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _book(String offerId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/carpool/$offerId/book', {}, token: authProvider.accessToken);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  Future<void> _cancelBooking(String offerId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/carpool/$offerId/book', token: authProvider.accessToken);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  Future<void> _deleteOffer(String offerId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/carpool/$offerId', token: authProvider.accessToken);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  Future<void> _openCreateDialog() async {
    final pointController = TextEditingController();
    final noteController = TextEditingController();
    int seats = 3;
    DateTime? departureTime;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDarkAlt,
          title: Text(ctx.t('carpool.dialog_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: pointController,
                  decoration: InputDecoration(labelText: ctx.t('carpool.from_label')),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(departureTime == null
                      ? ctx.t('carpool.departure_not_set')
                      : ctx.tArgs('carpool.departure_time_label', {'value': '${departureTime!.day}.${departureTime!.month}.${departureTime!.year} ${departureTime!.hour.toString().padLeft(2, '0')}:${departureTime!.minute.toString().padLeft(2, '0')}'})),
                  trailing: const Icon(Icons.schedule, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;
                    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    setDialogState(() {
                      departureTime = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
                    });
                  },
                ),
                Row(
                  children: [
                    Text(ctx.t('carpool.seats_label')),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: seats > 1 ? () => setDialogState(() => seats--) : null,
                    ),
                    Text('$seats', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: seats < 8 ? () => setDialogState(() => seats++) : null,
                    ),
                  ],
                ),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: ctx.t('carpool.comment_label')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('carpool.cancel'))),
            ElevatedButton(
              onPressed: () async {
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await ApiService.post(
                    '/api/carpool',
                    {
                      'event_id': widget.eventId,
                      'departure_point': pointController.text.trim().isEmpty ? null : pointController.text.trim(),
                      'departure_time': departureTime?.toIso8601String(),
                      'seats_total': seats,
                      'note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    },
                    token: authProvider.accessToken,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ctx.tArgs('carpool.error', {'error': '$e'}))));
                }
              },
              child: Text(ctx.t('carpool.publish')),
            ),
          ],
        ),
      ),
    );

    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?['id'];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tArgs('carpool.title', {'title': widget.eventTitle}), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.add),
        label: Text(context.t('carpool.offer_seat')),
      ),
      body: _isLoading
          ? const Center(child: AppFullLoader())
          : _offers.isEmpty
              ? Center(child: Text(context.t('carpool.empty_state'), style: const TextStyle(color: AppColors.textMutedDark)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index] as Map<String, dynamic>;
                      final driver = offer['driver'] as Map<String, dynamic>?;
                      final seatsTotal = (offer['seats_total'] as num?)?.toInt() ?? 1;
                      final seatsTaken = (offer['seats_taken'] as num?)?.toInt() ?? 0;
                      final seatsLeft = seatsTotal - seatsTaken;
                      final isMine = driver != null && driver['id'] == myId;
                      final iBooked = offer['i_booked'] == true;
                      final departureTime = offer['departure_time'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.steel),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: (driver?['avatar_url'] != null && (driver!['avatar_url'] as String).isNotEmpty)
                                      ? NetworkImage(resolveImageUrl(driver['avatar_url']))
                                      : null,
                                  child: (driver?['avatar_url'] == null || (driver!['avatar_url'] as String).isEmpty)
                                      ? Text((driver?['full_name'] ?? driver?['username'] ?? '?').toString().substring(0, 1))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    driver?['full_name'] ?? driver?['username'] ?? context.t('carpool.driver_fallback'),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: seatsLeft > 0 ? AppColors.blue.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    seatsLeft > 0 ? context.tArgs('carpool.seats_free', {'left': '$seatsLeft', 'total': '$seatsTotal'}) : context.t('carpool.no_seats'),
                                    style: TextStyle(fontSize: 11, color: seatsLeft > 0 ? AppColors.blue : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            if (offer['departure_point'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.place, size: 16, color: AppColors.textMutedDark),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(offer['departure_point'], style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ],
                            if (departureTime != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: AppColors.textMutedDark),
                                  const SizedBox(width: 4),
                                  Text(_formatDateTime(context, departureTime), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ],
                            if ((offer['note'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(offer['note'], style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (isMine)
                                  TextButton.icon(
                                    onPressed: () => _deleteOffer(offer['id']),
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    label: Text(context.t('carpool.delete'), style: const TextStyle(color: Colors.red)),
                                  )
                                else if (iBooked)
                                  TextButton.icon(
                                    onPressed: () => _cancelBooking(offer['id']),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: Text(context.t('carpool.cancel_booking')),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: seatsLeft > 0 ? () => _book(offer['id']) : null,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                                    child: Text(context.t('carpool.book_seat')),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDateTime(BuildContext context, String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return context.tArgs('carpool.datetime_format', {
        'date': '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}',
        'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      });
    } catch (_) {
      return iso;
    }
  }
}
