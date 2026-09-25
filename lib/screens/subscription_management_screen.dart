import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Управление подпиской CarSpot Premium: текущий статус, история платежей,
/// отмена (для Google Play — открывает страницу управления подпиской в Play
/// Store, т.к. отменить подписку Google Play можно только там; для Trybit
/// автопродления нет вообще — это разовая оплата на выбранный срок).
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/payments/history', token: authProvider.accessToken);
      if (mounted) setState(() => _history = response is List ? response : []);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
      case 'overpaid':
        return context.t('subscription_mgmt.status_paid');
      case 'pending':
        return context.t('subscription_mgmt.status_pending');
      default:
        return context.t('subscription_mgmt.status_failed');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'overpaid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return AppColors.red;
    }
  }

  Future<void> _openPlayStoreSubscriptions() async {
    // packageName фиксирован на бэкенде (GOOGLE_PLAY_PACKAGE_NAME) — тут
    // достаточно общей ссылки на список подписок аккаунта в Play Store.
    final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('subscription_mgmt.play_store_open_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPremium = user?['is_premium'] == true;
    final tier = user?['premium_tier'] as String?;
    final premiumUntil = user?['premium_until'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('subscription_mgmt.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: Colors.amber.shade800,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium
                        ? (tier == 'basic' ? 'CarSpot Basic' : 'CarSpot Pro')
                        : context.t('subscription_mgmt.no_active_plan'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cardText),
                  ),
                  if (isPremium) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.tArgs('subscription_mgmt.active_until', {'date': _formatDate(premiumUntil)}),
                      style: TextStyle(fontSize: 13, color: cardText.withOpacity(0.7)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openPlayStoreSubscriptions,
                icon: const Icon(Icons.open_in_new),
                label: Text(context.t('subscription_mgmt.manage_in_play_store')),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.t('subscription_mgmt.trybit_note'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(context.t('subscription_mgmt.history_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cardText)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: AppLoader())
            else if (_error != null)
              Text(context.tArgs('subscription_mgmt.load_error', {'error': _error!}), style: const TextStyle(color: AppColors.red))
            else if (_history.isEmpty)
              Text(context.t('subscription_mgmt.no_payments'), style: TextStyle(color: cardText.withOpacity(0.6)))
            else
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    for (var i = 0; i < _history.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Builder(builder: (context) {
                        final item = _history[i] as Map<String, dynamic>;
                        final status = item['status'] as String? ?? 'pending';
                        final tierLabel = (item['tier'] as String?) == 'basic' ? 'Basic' : 'Pro';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(status).withOpacity(0.15),
                            child: Icon(Icons.receipt, color: _statusColor(status), size: 18),
                          ),
                          title: Text('CarSpot $tierLabel · \$${item['amount_usd']}'),
                          subtitle: Text(
                            '${_statusLabel(status)} · ${_formatDate(item['paid_at'] as String? ?? item['created_at'] as String?)}',
                            style: TextStyle(color: _statusColor(status), fontSize: 12),
                          ),
                          trailing: Text('${item['days']} ${context.t('subscription_mgmt.days_suffix')}'),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
