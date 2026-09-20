import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/report_dialog.dart';
import 'user_profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';

/// Простая админ-панель: рассмотрение жалоб и блокировка пользователей.
/// Пункт меню, ведущий сюда, показывается только если is_admin == true —
/// но реальная проверка прав всегда на бэкенде (app.deps.require_admin).
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _reports = [];
  bool _isLoadingReports = false;
  String _statusFilter = 'pending';

  List<dynamic> _users = [];
  bool _isLoadingUsers = false;
  bool _bannedOnly = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final query = _statusFilter == 'all' ? '' : '?status=$_statusFilter';
      final response = await ApiService.get('/api/admin/reports$query', token: _token);
      setState(() => _reports = response is Map ? (response['items'] as List? ?? []) : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final q = _searchController.text.trim();
      final params = <String>[];
      if (q.isNotEmpty) params.add('q=${Uri.encodeQueryComponent(q)}');
      if (_bannedOnly) params.add('banned_only=true');
      final query = params.isEmpty ? '' : '?${params.join('&')}';
      final response = await ApiService.get('/api/admin/users$query', token: _token);
      setState(() => _users = response is List ? response : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _resolveReport(Map<String, dynamic> report, String status) async {
    try {
      await ApiService.post(
        '/api/admin/reports/${report['id']}/resolve',
        {'status': status},
        token: _token,
      );
      _loadReports();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _banUser(String userId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Заблокировать пользователя?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Причина (необязательно)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.post(
        '/api/admin/users/$userId/ban',
        {if (reasonController.text.trim().isNotEmpty) 'reason': reasonController.text.trim()},
        token: _token,
      );
      _loadUsers();
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь заблокирован')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _unbanUser(String userId) async {
    try {
      await ApiService.post('/api/admin/users/$userId/unban', {}, token: _token);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь разблокирован')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'resolved':
        return 'Решено';
      case 'dismissed':
        return 'Отклонено';
      default:
        return 'Ожидает';
    }
  }

  String _targetTypeLabel(String type) {
    switch (type) {
      case 'user':
        return 'Пользователь';
      case 'event':
        return 'Сходка';
      case 'club':
        return 'Клуб';
      case 'business':
        return 'Автосервис';
      case 'message':
        return 'Сообщение в чате';
      case 'photo':
        return 'Фото';
      default:
        return type;
    }
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status'] as String? ?? 'pending';
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final targetUser = report['target_user'] as Map<String, dynamic>?;
    final reason = reportReasonLabels[report['reason']] ?? (report['reason']?.toString() ?? '');
    final description = report['description'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_targetTypeLabel(report['target_type']?.toString() ?? ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(reason, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description),
            ],
            const SizedBox(height: 8),
            if (reporter != null)
              Text('От: @${reporter['username']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (targetUser != null)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: targetUser['id'])),
                ),
                child: Text(
                  'На пользователя: @${targetUser['username']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.blue),
                ),
              ),
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(onPressed: () => _resolveReport(report, 'dismissed'), child: const Text('Отклонить')),
                  ElevatedButton(onPressed: () => _resolveReport(report, 'resolved'), child: const Text('Решено')),
                  if (targetUser != null)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                      onPressed: () => _banUser(targetUser['id']),
                      child: const Text('Заблокировать'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final isBanned = user['is_active'] == false;
    final username = (user['username'] as String?) ?? 'user';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (user['avatar_url'] != null && (user['avatar_url'] as String).isNotEmpty)
              ? NetworkImage(user['avatar_url'])
              : null,
          child: (user['avatar_url'] == null || (user['avatar_url'] as String).isEmpty)
              ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U')
              : null,
        ),
        title: Text('@$username'),
        subtitle: Text(
          [
            user['email']?.toString() ?? '',
            if (isBanned)
              'Заблокирован${(user['ban_reason'] ?? '').toString().isNotEmpty ? ': ${user['ban_reason']}' : ''}',
          ].where((s) => s.isNotEmpty).join(' • '),
          style: TextStyle(color: isBanned ? AppColors.red : Colors.grey, fontSize: 12),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])),
        ),
        trailing: user['is_admin'] == true
            ? const Icon(Icons.verified_user, color: AppColors.blue)
            : TextButton(
                onPressed: () => isBanned ? _unbanUser(user['id']) : _banUser(user['id']),
                child: Text(
                  isBanned ? 'Разблок.' : 'Блок.',
                  style: TextStyle(color: isBanned ? Colors.green : AppColors.red),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        backgroundColor: AppColors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Жалобы'), Tab(text: 'Пользователи')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Ожидают')),
                    DropdownMenuItem(value: 'resolved', child: Text('Решённые')),
                    DropdownMenuItem(value: 'dismissed', child: Text('Отклонённые')),
                    DropdownMenuItem(value: 'all', child: Text('Все')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v!);
                    _loadReports();
                  },
                ),
              ),
              Expanded(
                child: _isLoadingReports
                    ? Center(child: AppLoader())
                    : RefreshIndicator(
                        color: AppColors.red,
                        backgroundColor: AppColors.surfaceDark,
                        onRefresh: _loadReports,
                        child: _reports.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Text('Жалоб нет', style: TextStyle(color: Colors.grey))),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _reports.length,
                                itemBuilder: (context, i) => _buildReportCard(_reports[i] as Map<String, dynamic>),
                              ),
                      ),
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Поиск по логину/email',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _loadUsers(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.search), onPressed: _loadUsers),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Только заблокированные'),
                value: _bannedOnly,
                onChanged: (v) {
                  setState(() => _bannedOnly = v);
                  _loadUsers();
                },
              ),
              Expanded(
                child: _isLoadingUsers
                    ? Center(child: AppLoader())
                    : RefreshIndicator(
                        color: AppColors.red,
                        backgroundColor: AppColors.surfaceDark,
                        onRefresh: _loadUsers,
                        child: _users.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Text('Никого не найдено', style: TextStyle(color: Colors.grey))),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _users.length,
                                itemBuilder: (context, i) => _buildUserRow(_users[i] as Map<String, dynamic>),
                              ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
