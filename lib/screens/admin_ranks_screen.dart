import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/admin_ranks.dart';
import '../utils/image_url.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';

/// Выдача монет вручную и назначение рангов администрации — доступно только
/// пользователям с назначенным admin_rank (см. app/ranks.py на бэкенде).
/// Реальная проверка прав всегда на сервере: этот экран просто прячет то,
/// что всё равно вернёт 403, чтобы не путать пользователя лишними кнопками.
class AdminRanksScreen extends StatefulWidget {
  const AdminRanksScreen({Key? key}) : super(key: key);

  @override
  State<AdminRanksScreen> createState() => _AdminRanksScreenState();
}

class _AdminRanksScreenState extends State<AdminRanksScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  List<dynamic> _currentAdmins = [];
  bool _isLoadingAdmins = false;

  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;
  int get _myLevel => adminRankLevel(Provider.of<AuthProvider>(context, listen: false).user?['admin_rank'] as String?);

  @override
  void initState() {
    super.initState();
    if (_myLevel >= kTechAdminLevel) _loadCurrentAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAdmins() async {
    setState(() => _isLoadingAdmins = true);
    try {
      final response = await ApiService.get('/api/admin/ranks', token: _token);
      if (mounted) setState(() => _currentAdmins = response is List ? response : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoadingAdmins = false);
    }
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await ApiService.get('/api/admin/users?q=${Uri.encodeQueryComponent(q)}', token: _token);
      if (mounted) setState(() => _searchResults = response is List ? response : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _grantCoins(Map<String, dynamic> user) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tArgs('admin_ranks.grant_coins_title', {'username': '@${user['username']}'})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.t('admin_ranks.amount_label')),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: context.t('admin_ranks.reason_label_optional')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('common.confirm'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = int.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('admin_ranks.invalid_amount'))));
      return;
    }
    try {
      final body = <String, dynamic>{'amount': amount};
      if (reasonController.text.trim().isNotEmpty) body['reason'] = reasonController.text.trim();
      final response = await ApiService.post('/api/admin/coins/grant/${user['id']}', body, token: _token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('admin_ranks.grant_coins_success', {'amount': '$amount', 'balance': '${response['balance']}'}))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _grantPremium(Map<String, dynamic> user) async {
    final daysController = TextEditingController(text: '30');
    String selectedTier = 'pro';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tArgs('admin_ranks.grant_premium_title', {'username': '@${user['username']}'})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.t('admin_ranks.days_label')),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'basic',
                groupValue: selectedTier,
                title: const Text('CarSpot Basic'),
                onChanged: (v) => setDialogState(() => selectedTier = v ?? selectedTier),
              ),
              RadioListTile<String>(
                value: 'pro',
                groupValue: selectedTier,
                title: const Text('CarSpot Pro'),
                onChanged: (v) => setDialogState(() => selectedTier = v ?? selectedTier),
              ),
              RadioListTile<String>(
                value: 'max',
                groupValue: selectedTier,
                title: const Text('CarSpot Max'),
                onChanged: (v) => setDialogState(() => selectedTier = v ?? selectedTier),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('common.confirm'))),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final days = int.tryParse(daysController.text.trim());
    if (days == null || days <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('admin_ranks.invalid_days'))));
      return;
    }
    try {
      final response = await ApiService.post(
        '/api/admin/premium/grant/${user['id']}',
        {'days': days, 'tier': selectedTier},
        token: _token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('admin_ranks.grant_premium_success', {'tier': '${response['premium_tier']}'}))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _setRank(Map<String, dynamic> user) async {
    String? selected = user['admin_rank'] as String?;
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tArgs('admin_ranks.set_rank_title', {'username': '@${user['username']}'})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<String?>(
                value: null,
                groupValue: selected,
                title: Text(context.t('admin_ranks.no_rank')),
                onChanged: (v) => setDialogState(() => selected = v),
              ),
              for (final rank in kAdminRanks)
                RadioListTile<String?>(
                  value: rank,
                  groupValue: selected,
                  title: Text(adminRankTitle(rank)),
                  onChanged: (v) => setDialogState(() => selected = v),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(context.t('common.cancel'))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected ?? '__none__'),
              child: Text(context.t('common.confirm')),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final rank = result == '__none__' ? null : result;
    try {
      await ApiService.post('/api/admin/ranks/${user['id']}', {'rank': rank}, token: _token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('admin_ranks.rank_updated'))));
      }
      _search();
      _loadCurrentAdmins();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _openUserActions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: ((user['avatar_url'] as String?) ?? '').isNotEmpty
                    ? NetworkImage(resolveImageUrl(user['avatar_url']))
                    : null,
                child: ((user['avatar_url'] as String?) ?? '').isEmpty ? Text((user['username'] as String).substring(0, 1).toUpperCase()) : null,
              ),
              title: Text('@${user['username']}'),
              subtitle: Text(adminRankTitle(user['admin_rank'] as String?)),
            ),
            const Divider(height: 1),
            if (_myLevel >= kTechAdminLevel)
              ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.amber),
                title: Text(context.t('admin_ranks.grant_coins_action')),
                onTap: () {
                  Navigator.pop(ctx);
                  _grantCoins(user);
                },
              ),
            if (_myLevel >= kTechAdminLevel)
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                title: Text(context.t('admin_ranks.grant_premium_action')),
                onTap: () {
                  Navigator.pop(ctx);
                  _grantPremium(user);
                },
              ),
            if (_myLevel >= kDeveloperLevel)
              ListTile(
                leading: const Icon(Icons.military_tech, color: AppColors.blue),
                title: Text(context.t('admin_ranks.set_rank_action')),
                onTap: () {
                  Navigator.pop(ctx);
                  _setRank(user);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user, Color cardText) {
    final rank = user['admin_rank'] as String?;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: ((user['avatar_url'] as String?) ?? '').isNotEmpty ? NetworkImage(resolveImageUrl(user['avatar_url'])) : null,
        child: ((user['avatar_url'] as String?) ?? '').isEmpty ? Text((user['username'] as String).substring(0, 1).toUpperCase()) : null,
      ),
      title: Text('@${user['username']}', style: TextStyle(color: cardText)),
      subtitle: rank != null ? Text(adminRankTitle(rank), style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)) : null,
      trailing: const Icon(Icons.more_vert),
      onTap: () => _openUserActions(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('admin_ranks.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.blueDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.t('admin_ranks.search_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: AppLoader(size: 16)) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _search, child: Text(context.t('common.search'))),
          ),
          for (final raw in _searchResults)
            if (raw is Map<String, dynamic>) _userTile(raw, cardText),
          if (_myLevel >= kTechAdminLevel) ...[
            const SizedBox(height: 20),
            Text(context.t('admin_ranks.current_admins_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 15)),
            const SizedBox(height: 8),
            if (_isLoadingAdmins)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: AppFullLoader(size: 48)))
            else if (_currentAdmins.isEmpty)
              Text(context.t('admin_ranks.no_admins'), style: TextStyle(color: cardText.withOpacity(0.6)))
            else
              for (final raw in _currentAdmins)
                if (raw is Map<String, dynamic>) _userTile(raw, cardText),
          ],
        ],
      ),
    );
  }
}
