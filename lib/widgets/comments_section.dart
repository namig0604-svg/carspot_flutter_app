import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../screens/user_profile_screen.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Универсальный блок комментариев — используется и на странице сходки,
/// и в просмотрщике фото. Нужен ограниченный по высоте родитель
/// (Expanded / SizedBox с фиксированной высотой), так как внутри — свой
/// скролл (ListView) плюс поле ввода снизу.
class CommentsSection extends StatefulWidget {
  final String targetType; // 'event' | 'photo'
  final String targetId;
  final bool dark; // тёмная тема — для фото-вьювера на чёрном фоне

  const CommentsSection({
    Key? key,
    required this.targetType,
    required this.targetId,
    this.dark = false,
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;
  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiService.get(
        '/api/comments/${widget.targetType}/${widget.targetId}?limit=100',
        token: _token,
      );
      final items = response is Map ? (response['items'] ?? []) : [];
      if (!mounted) return;
      setState(() {
        _comments = items is List ? items : [];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = context.t('comments_section.load_error');
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      final created = await ApiService.post(
        '/api/comments/${widget.targetType}/${widget.targetId}',
        {'text': text},
        token: _token,
      );
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _comments.add(created);
        _isSending = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('comments_section.send_error'))),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('comments_section.delete_confirm_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('common.delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.delete('/api/comments/${comment['id']}', token: _token);
      if (!mounted) return;
      setState(() => _comments.removeWhere((c) => c['id'] == comment['id']));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('comments_section.delete_error'))),
      );
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return context.t('comments_section.time_now');
      if (diff.inMinutes < 60) return context.tArgs('comments_section.time_minutes_ago', {'n': '${diff.inMinutes}'});
      if (diff.inHours < 24) return context.tArgs('comments_section.time_hours_ago', {'n': '${diff.inHours}'});
      if (diff.inDays < 7) return context.tArgs('comments_section.time_days_ago', {'n': '${diff.inDays}'});
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.dark ? Colors.white : AppColors.textOnLight;
    final subColor = widget.dark ? Colors.white60 : Colors.grey;
    final dividerColor = widget.dark ? Colors.white24 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 18, color: subColor),
            const SizedBox(width: 6),
            Text(
              '${context.t('comments_section.title')}${_comments.isNotEmpty ? ' (${_comments.length})' : ''}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? Center(child: AppLoader(size: 26, color: widget.dark ? Colors.white : AppColors.blue))
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: subColor)))
                  : _comments.isEmpty
                      ? Center(child: Text(context.t('comments_section.empty'), style: TextStyle(color: subColor)))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index] as Map<String, dynamic>;
                            final user = c['user'] as Map<String, dynamic>?;
                            final isMine = c['is_mine'] == true || (user != null && user['id'] == _myId);
                            final avatarUrl = (user?['avatar_url'] ?? '').toString();
                            final username = (user?['username'] ?? '?').toString();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: user == null || user['id'] == null
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => UserProfileScreen(userId: user['id']),
                                              ),
                                            ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.blue,
                                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(resolveImageUrl(avatarUrl)) : null,
                                      child: avatarUrl.isEmpty
                                          ? Text(
                                              username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                username.isNotEmpty ? username : context.t('comments_section.default_username'),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(_formatTime(c['created_at']?.toString()), style: TextStyle(fontSize: 11, color: subColor)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(c['text'] ?? '', style: TextStyle(fontSize: 13, color: textColor)),
                                      ],
                                    ),
                                  ),
                                  if (isMine)
                                    IconButton(
                                      icon: Icon(Icons.close, size: 16, color: subColor),
                                      onPressed: () => _delete(c),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
        Divider(color: dividerColor, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 1000,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: context.t('comments_section.input_hint'),
                    hintStyle: TextStyle(color: subColor),
                    isDense: true,
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(child: AppLoader(size: 20, color: widget.dark ? Colors.white : AppColors.blue)),
                    )
                  : IconButton(
                      icon: Icon(Icons.send, color: AppColors.blue),
                      onPressed: _send,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
