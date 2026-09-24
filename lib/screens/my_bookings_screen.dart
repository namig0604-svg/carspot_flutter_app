import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import 'business_detail_screen.dart';

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

/// Мои записи в автосервисы/ателье (как клиента) — GET /api/bookings/mine.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
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
      final response = await ApiService.get('/api/bookings/mine', token: authProvider.accessToken);
      final items = response is Map && response['items'] is List ? response['items'] as List : [];
      setState(() => _items = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel(String bookingId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/bookings/$bookingId/status', {'status': 'cancelled'}, token: authProvider.accessToken);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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
        title: const Text('Мои записи'),
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
                        const Icon(Icons.event_available, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('У вас пока нет записей', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final b = _items[index] as Map<String, dynamic>;
                        final business = b['business'] as Map<String, dynamic>?;
                        final status = (b['status'] as String?) ?? 'pending';
                        final canCancel = status == 'pending' || status == 'confirmed';
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
                                    child: GestureDetector(
                                      onTap: business == null
                                          ? null
                                          : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: business['id'])),
                                            ),
                                      child: Text(
                                        business?['name'] ?? 'Заведение',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                              if (status == 'declined' && (b['decline_reason'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Причина: ${b['decline_reason']}', style: const TextStyle(fontSize: 12, color: AppColors.red)),
                              ],
                              if (canCancel) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton(
                                    onPressed: () => _cancel(b['id'] as String),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 34),
                                      side: const BorderSide(color: AppColors.steel),
                                    ),
                                    child: const Text('Отменить'),
                                  ),
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
