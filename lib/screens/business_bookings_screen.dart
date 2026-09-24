import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';

const Map<String, String> _statusLabels = {
  'pending': 'Ожидает подтверждения',
  'confirmed': 'Подтверждена',
  'declined': 'Отклонена',
  'cancelled': 'Отменена',
  'completed': 'Выполнена',
};

const Map<String, Color> _statusColors = {
  'pending': Colors.amber,
  'confirmed': Colors.green,
  'declined': AppColors.red,
  'cancelled': Colors.grey,
  'completed': AppColors.blue,
};

/// Заявки на запись к заведению — видит и управляет только владелец.
/// GET /api/bookings/business/{id}, POST /api/bookings/{id}/status.
class BusinessBookingsScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  const BusinessBookingsScreen({Key? key, required this.businessId, required this.businessName}) : super(key: key);

  @override
  State<BusinessBookingsScreen> createState() => _BusinessBookingsScreenState();
}

class _BusinessBookingsScreenState extends State<BusinessBookingsScreen> {
  List<dynamic> _items = [];
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
      final response = await ApiService.get('/api/bookings/business/${widget.businessId}', token: authProvider.accessToken);
      final items = response is Map && response['items'] is List ? response['items'] as List : [];
      setState(() => _items = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setStatus(String bookingId, String status, {String? declineReason}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/bookings/$bookingId/status',
        {'status': status, if (declineReason != null) 'decline_reason': declineReason},
        token: authProvider.accessToken,
      );
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _declineWithReason(String bookingId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Отклонить запись'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'Причина (необязательно)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    _setStatus(bookingId, 'declined', declineReason: reason.isEmpty ? null : reason);
  }

  String _formatWhen(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd.$mm.${dt.year}, $hh:$min';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заявки — ${widget.businessName}', overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      body: _isLoading
          ? Center(child: AppLoader())
          : RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.event_note, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('Заявок на запись пока нет', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final b = _items[index] as Map<String, dynamic>;
                        final user = b['user'] as Map<String, dynamic>?;
                        final status = (b['status'] as String?) ?? 'pending';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                                  Expanded(
                                    child: Text(
                                      user?['username'] ?? 'Клиент',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (_statusColors[status] ?? Colors.grey).withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabels[status] ?? status,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColors[status] ?? Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if ((b['service'] ?? '').toString().isNotEmpty)
                                Text(b['service'], style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: AppColors.textMutedDark),
                                  const SizedBox(width: 4),
                                  Text(_formatWhen(b['requested_at'] as String? ?? ''), style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                                ],
                              ),
                              if ((b['note'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(b['note'], style: const TextStyle(fontSize: 12)),
                              ],
                              if (status == 'pending' || status == 'confirmed') ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (status == 'pending') ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _declineWithReason(b['id'] as String),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 40),
                                            side: const BorderSide(color: AppColors.red),
                                            foregroundColor: AppColors.red,
                                          ),
                                          child: const Text('Отклонить'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _setStatus(b['id'] as String, 'confirmed'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            minimumSize: const Size(0, 40),
                                          ),
                                          child: const Text('Подтвердить', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ] else if (status == 'confirmed')
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _setStatus(b['id'] as String, 'completed'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.blue,
                                            minimumSize: const Size(0, 40),
                                          ),
                                          child: const Text('Отметить выполненной', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
