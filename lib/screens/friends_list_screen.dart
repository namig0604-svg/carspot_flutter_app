import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import 'user_profile_screen.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Друзья: список друзей + входящие/исходящие заявки в друзья.
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  List<dynamic> _friends = [];
  List<dynamic> _incoming = [];
  List<dynamic> _sent = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await Future.wait([
        ApiService.get('/api/friends/', token: authProvider.accessToken),
        ApiService.get('/api/friends/requests', token: authProvider.accessToken),
        ApiService.get('/api/friends/requests/sent', token: authProvider.accessToken),
      ]);
      setState(() {
        _friends = results[0] is List ? results[0] as List : [];
        _incoming = results[1] is List ? results[1] as List : [];
        _sent = results[2] is List ? results[2] as List : [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('friends_list.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/friends/$friendshipId/accept', {}, token: authProvider.accessToken);
      await _loadAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('friends_list.error', {'error': '$e'}))));
    }
  }

  Future<void> _decline(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/friends/$friendshipId/decline', {}, token: authProvider.accessToken);
      await _loadAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('friends_list.error', {'error': '$e'}))));
    }
  }

  Future<void> _removeFriend(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/friends/$friendshipId', token: authProvider.accessToken);
      await _loadAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('friends_list.error', {'error': '$e'}))));
    }
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    ).then((_) => _loadAll());
  }

  Widget _userAvatar(Map<String, dynamic> user) {
    final avatarUrl = user['avatar_url'] as String?;
    final username = (user['username'] as String?) ?? '?';
    return CircleAvatar(
      backgroundColor: AppColors.blue.withOpacity(0.15),
      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(resolveImageUrl(avatarUrl)) : null,
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?')
          : null,
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey))),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _friendsTab() {
    if (_friends.isEmpty) {
      return _emptyState(
        Icons.people_outline,
        context.t('friends_list.no_friends_title'),
        context.t('friends_list.no_friends_subtitle'),
      );
    }
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final user = _friends[index] as Map<String, dynamic>;
        return ListTile(
          leading: _userAvatar(user),
          title: Text(user['full_name'] ?? user['username'] ?? ''),
          subtitle: Text('@${user['username'] ?? ''}', style: const TextStyle(color: Colors.grey)),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _openProfile(user['id'] as String),
          ),
          onTap: () => _openProfile(user['id'] as String),
        );
      },
    );
  }

  Widget _requestsTab() {
    if (_incoming.isEmpty && _sent.isEmpty) {
      return _emptyState(
        Icons.person_add_alt_1,
        context.t('friends_list.no_requests_title'),
        context.t('friends_list.no_requests_subtitle'),
      );
    }
    return ListView(
      children: [
        if (_incoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(context.t('friends_list.incoming'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ..._incoming.map((r) {
            final req = r as Map<String, dynamic>;
            final user = req['user'] as Map<String, dynamic>;
            final fid = req['id'] as String;
            return ListTile(
              leading: _userAvatar(user),
              title: Text(user['full_name'] ?? user['username'] ?? ''),
              subtitle: Text('@${user['username'] ?? ''}', style: const TextStyle(color: Colors.grey)),
              onTap: () => _openProfile(user['id'] as String),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: context.t('friends_list.accept'),
                    onPressed: () => _accept(fid),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.red),
                    tooltip: context.t('friends_list.decline'),
                    onPressed: () => _decline(fid),
                  ),
                ],
              ),
            );
          }),
        ],
        if (_sent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(context.t('friends_list.sent'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ..._sent.map((r) {
            final req = r as Map<String, dynamic>;
            final user = req['user'] as Map<String, dynamic>;
            final fid = req['id'] as String;
            return ListTile(
              leading: _userAvatar(user),
              title: Text(user['full_name'] ?? user['username'] ?? ''),
              subtitle: Text(context.t('friends_list.request_sent_pending'), style: const TextStyle(color: Colors.grey)),
              onTap: () => _openProfile(user['id'] as String),
              trailing: TextButton(
                onPressed: () => _decline(fid),
                child: Text(context.t('friends_list.cancel_request')),
              ),
            );
          }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('friends_list.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.t('friends_list.tab_friends')),
            Tab(
              text: _incoming.isEmpty
                  ? context.t('friends_list.tab_requests')
                  : context.tArgs('friends_list.tab_requests_count', {'count': '${_incoming.length}'}),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/chats.jpg'),
          Theme(
            data: AppTheme.dark,
            child: _isLoading
                ? Center(child: AppLoader())
                : RefreshIndicator(
                    color: AppColors.red,
                    backgroundColor: AppColors.surfaceDark,
                    onRefresh: _loadAll,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _friendsTab(),
                        _requestsTab(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
