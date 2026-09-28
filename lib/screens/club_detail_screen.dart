import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_room_screen.dart';
import 'club_form_screen.dart';
import '../widgets/report_dialog.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'user_profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import '../utils/event_date.dart';

class ClubDetailScreen extends StatefulWidget {
  final String clubId;

  const ClubDetailScreen({Key? key, required this.clubId}) : super(key: key);

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  Map<String, dynamic>? _club;
  List<dynamic> _members = [];
  List<dynamic> _pending = [];
  List<dynamic> _events = [];
  bool _isLoadingDetail = true;
  bool _isActionLoading = false;

  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];
  bool get _isMember => _club?['my_status'] == 'approved';
  bool get _isPending => _club?['my_status'] == 'pending';
  bool get _isAdmin => _club?['my_role'] == 'owner' || _club?['my_role'] == 'admin';
  bool get _isOwner => _club?['my_role'] == 'owner';
  bool get _isModerator => _club?['my_role'] == 'moderator';
  bool get _isFavorite => _club?['is_favorite'] == true;

  bool _canKick(String role, String? memberUserId) {
    if (memberUserId == null || memberUserId == _myId || role == 'owner') return false;
    if (_isAdmin) return true;
    return _isModerator && role == 'member';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return context.t('club_detail.owner');
      case 'admin':
        return context.t('club_detail.admin');
      case 'moderator':
        return context.t('club_detail.moderator');
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadClub();
    await _loadMembers();
    await _loadEvents();
    if (_isAdmin) await _loadPending();
  }

  Future<void> _loadClub() async {
    setState(() => _isLoadingDetail = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/clubs/${widget.clubId}', token: authProvider.accessToken);
      setState(() => _club = response);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/clubs/${widget.clubId}/members?member_status=approved&limit=100',
        token: authProvider.accessToken,
      );
      setState(() => _members = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _loadPending() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/clubs/${widget.clubId}/members?member_status=pending&limit=100',
        token: authProvider.accessToken,
      );
      setState(() => _pending = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/clubs/${widget.clubId}/events?limit=50',
        token: authProvider.accessToken,
      );
      setState(() => _events = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasFavorite = _isFavorite;
    try {
      if (wasFavorite) {
        await ApiService.delete('/api/clubs/${widget.clubId}/favorite', token: authProvider.accessToken);
      } else {
        await ApiService.post('/api/clubs/${widget.clubId}/favorite', {}, token: authProvider.accessToken);
      }
      if (mounted) setState(() => _club!['is_favorite'] = !wasFavorite);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    }
  }

  Future<void> _join() async {
    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post('/api/clubs/${widget.clubId}/join', {}, token: authProvider.accessToken);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? context.t('common.done'))));
      }
      await _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('club_detail.leave_confirm_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('club_detail.leave_confirm_action'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/clubs/${widget.clubId}/leave', {}, token: authProvider.accessToken);
      await _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _approve(String userId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/clubs/${widget.clubId}/members/$userId/approve',
        {},
        token: authProvider.accessToken,
      );
      await _loadMembers();
      await _loadPending();
      _refreshMembersCountLocal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    }
  }

  Future<void> _reject(String userId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete(
        '/api/clubs/${widget.clubId}/members/$userId',
        token: authProvider.accessToken,
      );
      await _loadPending();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    }
  }

  Future<void> _kick(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('club_detail.kick_confirm_title')),
        content: Text(context.tArgs('club_detail.kick_confirm_body', {'username': username})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('club_detail.kick_action'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete(
        '/api/clubs/${widget.clubId}/members/$userId',
        token: authProvider.accessToken,
      );
      await _loadMembers();
      _refreshMembersCountLocal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    }
  }

  Future<void> _changeRole(String userId, String username, String currentRole) async {
    String selected = currentRole == 'owner' ? 'admin' : currentRole;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tArgs('club_detail.role_picker_title', {'username': username})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in ['admin', 'moderator', 'member'])
                RadioListTile<String>(
                  value: role,
                  groupValue: selected,
                  title: Text(_roleLabel(role) == '' ? context.t('club_detail.member_role_label') : _roleLabel(role)),
                  onChanged: (v) => setDialogState(() => selected = v ?? selected),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('common.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, selected), child: Text(context.t('common.confirm'))),
          ],
        ),
      ),
    );
    if (result == null) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.patch(
        '/api/clubs/${widget.clubId}/members/$userId/role',
        {'role': result},
        token: authProvider.accessToken,
      );
      await _loadMembers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('club_detail.role_updated'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    }
  }

  Future<void> _setTitle(String userId, String username, String? currentTitle) async {
    final controller = TextEditingController(text: currentTitle ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tArgs('club_detail.title_dialog_title', {'username': username})),
        content: TextField(
          controller: controller,
          maxLength: 40,
          decoration: InputDecoration(labelText: context.t('club_detail.title_label')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('common.confirm'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final title = controller.text.trim();
      await ApiService.patch(
        '/api/clubs/${widget.clubId}/members/$userId/title',
        {'title': title.isEmpty ? null : title},
        token: authProvider.accessToken,
      );
      await _loadMembers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('club_detail.title_updated'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    }
  }

  void _refreshMembersCountLocal() {
    if (_club != null) {
      setState(() => _club!['members_count'] = _members.length);
    }
  }

  void _openChat() {
    final roomId = _club?['chat_room_id'];
    if (roomId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(roomId: roomId, title: context.tArgs('club_detail.chat_title', {'name': '${_club?['name'] ?? ''}'})),
      ),
    );
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubFormScreen(club: _club)),
    );
    if (result == true) _loadClub();
  }

  Future<void> _createClubEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEventScreen(clubId: widget.clubId)),
    );
    if (result == true) _loadEvents();
  }

  Future<void> _deleteClub() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('club_detail.delete_confirm_title')),
        content: Text(
          context.tArgs('club_detail.delete_confirm_body', {'name': '${_club?['name'] ?? ''}'}),
        ),
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

    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/clubs/${widget.clubId}', token: authProvider.accessToken);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('club_detail.club_deleted'))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('club_detail.error_with_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.groups, color: Colors.grey, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetail && _club == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('club_detail.title'), overflow: TextOverflow.ellipsis, maxLines: 1), backgroundColor: AppColors.black, elevation: 0),
        body: Center(child: AppFullLoader()),
      );
    }
    if (_club == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('club_detail.title'), overflow: TextOverflow.ellipsis, maxLines: 1), backgroundColor: AppColors.black, elevation: 0),
        body: Center(child: Text(context.t('club_detail.not_found'))),
      );
    }

    final club = _club!;
    final logoUrl = club['logo_url'] as String?;
    final tags = (club['tags'] as String? ?? '').split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(club['name'] ?? context.t('club_detail.title'), overflow: TextOverflow.ellipsis),
        elevation: 0,
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? AppColors.red : null),
            tooltip: context.t('club_detail.add_favorite_tooltip'),
            onPressed: _toggleFavorite,
          ),
          if (_isMember && club['chat_room_id'] != null)
            IconButton(icon: const Icon(Icons.chat_bubble), tooltip: context.t('club_detail.chat_tooltip'), onPressed: _openChat),
          if (_isAdmin) IconButton(icon: const Icon(Icons.edit), tooltip: context.t('common.edit'), onPressed: _openEdit),
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.t('club_detail.delete_club_tooltip'),
              onPressed: _isActionLoading ? null : _deleteClub,
            ),
          if (!_isOwner)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: context.t('club_detail.report_tooltip'),
              onPressed: () => showReportDialog(context, targetType: 'club', targetId: widget.clubId),
            ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _createClubEvent,
              backgroundColor: AppColors.red,
              tooltip: context.t('club_detail.create_event_tooltip'),
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? Image.network(
                            resolveImageUrl(logoUrl),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _logoPlaceholder(),
                          )
                        : _logoPlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                club['name'] ?? '',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (club['is_verified'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: AppColors.blue, size: 18),
                            ],
                          ],
                        ),
                        if ((club['city'] ?? '').toString().isNotEmpty || (club['country'] ?? '').toString().isNotEmpty)
                          Text(
                            [club['city'], club['country']].where((v) => v != null && v.toString().isNotEmpty).join(', '),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(context.tArgs('club_detail.members_count', {'count': '${club['members_count'] ?? 0}'})),
                            const SizedBox(width: 14),
                            const Icon(Icons.event, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(context.tArgs('club_detail.events_count', {'count': '${club['events_count'] ?? 0}'})),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map((t) => Chip(
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(t, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                            backgroundColor: AppColors.blue.withOpacity(0.1),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],

              if ((club['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(context.t('club_detail.about'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(club['description']),
              ],

              const SizedBox(height: 20),

              if (!_isOwner)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isActionLoading
                        ? null
                        : (_isMember ? _leave : (_isPending ? null : _join)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMember
                          ? AppColors.red
                          : (_isPending ? Colors.grey : AppColors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isActionLoading
                        ? AppLoader(size: 22, color: Colors.white)
                        : Text(
                            _isMember
                                ? context.t('club_detail.leave_club_button')
                                : (_isPending
                                    ? context.t('club_detail.pending_request')
                                    : (club['is_public'] == false ? context.t('club_detail.send_request') : context.t('club_detail.join_club'))),
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                  ),
                ),

              const SizedBox(height: 24),

              if (_isAdmin && _pending.isNotEmpty) ...[
                Text(context.tArgs('club_detail.pending_requests_count', {'count': '${_pending.length}'}),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(_pending.map((m) {
                  final user = m['user'] as Map<String, dynamic>?;
                  final username = user?['username'] as String? ?? context.t('club_detail.unknown_user');
                  final userId = m['user_id'] as String;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U')),
                      title: Text(username),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _approve(userId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: AppColors.red),
                            onPressed: () => _reject(userId),
                          ),
                        ],
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Flexible(
                    child: Text(context.t('club_detail.members'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text('(${_members.length})', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              _members.isEmpty
                  ? Text(context.t('club_detail.no_members'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final m = _members[index];
                        final user = m['user'] as Map<String, dynamic>?;
                        final username = user?['username'] as String? ?? context.t('club_detail.unknown_user');
                        final avatarUrl = user?['avatar_url'] as String?;
                        final role = m['role'] as String? ?? 'member';
                        final memberUserId = m['user_id'] as String?;
                        final customTitle = m['custom_title'] as String?;
                        final canKick = _canKick(role, memberUserId);
                        final canManage = _isAdmin && memberUserId != null && memberUserId != _myId && role != 'owner';
                        final roleLabel = _roleLabel(role);
                        final roleColor = role == 'owner'
                            ? Colors.orange
                            : role == 'moderator'
                                ? Colors.teal
                                : AppColors.blue;
                        final hasMenu = canKick || canManage;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(resolveImageUrl(avatarUrl)) : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U')
                                : null,
                          ),
                          title: Text(username),
                          subtitle: (roleLabel.isNotEmpty || (customTitle != null && customTitle.isNotEmpty))
                              ? Wrap(
                                  spacing: 6,
                                  children: [
                                    if (roleLabel.isNotEmpty)
                                      Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                    if (customTitle != null && customTitle.isNotEmpty)
                                      Text(customTitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                )
                              : null,
                          trailing: !hasMenu
                              ? null
                              : PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (action) {
                                    if (action == 'kick') {
                                      _kick(memberUserId!, username);
                                    } else if (action == 'role') {
                                      _changeRole(memberUserId!, username, role);
                                    } else if (action == 'title') {
                                      _setTitle(memberUserId!, username, customTitle);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    if (canManage) PopupMenuItem(value: 'role', child: Text(context.t('club_detail.change_role_action'))),
                                    if (canManage) PopupMenuItem(value: 'title', child: Text(context.t('club_detail.set_title_action'))),
                                    if (canKick)
                                      PopupMenuItem(
                                        value: 'kick',
                                        child: Text(context.t('club_detail.kick_action'), style: const TextStyle(color: AppColors.red)),
                                      ),
                                  ],
                                ),
                          onTap: memberUserId == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => UserProfileScreen(userId: memberUserId)),
                                  );
                                },
                        );
                      },
                    ),

              const SizedBox(height: 24),

              Text(context.t('club_detail.events_heading'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _events.isEmpty
                  ? Text(context.t('club_detail.no_events'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final e = _events[index] as Map<String, dynamic>;
                        final isPrivateEvent = e['is_private'] == true;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isPrivateEvent ? Icons.lock : Icons.directions_car,
                              color: isPrivateEvent ? Colors.orange : AppColors.blue,
                            ),
                            title: Row(
                              children: [
                                Flexible(child: Text(e['title'] ?? context.t('club_detail.untitled_event'), overflow: TextOverflow.ellipsis)),
                                if (isPrivateEvent) ...[
                                  const SizedBox(width: 6),
                                  Text(context.t('club_detail.private_tag'), style: const TextStyle(fontSize: 12, color: Colors.orange)),
                                ],
                              ],
                            ),
                            subtitle: Text('${e['city'] ?? ''} · ${formatEventDateTime(e['event_date'], e['event_time'] as String?)}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e)),
                              );
                            },
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
