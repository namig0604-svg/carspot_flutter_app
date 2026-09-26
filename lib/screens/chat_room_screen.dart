import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/report_dialog.dart';
import 'user_profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import '../utils/premium_status.dart';

/// Экран одного чата (личный / чат сходки / чат клуба).
/// Обновляется по таймеру каждые несколько секунд — без WebSocket,
/// чтобы не тащить лишнюю зависимость и не ловить веб-специфичные баги.
class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;

  const ChatRoomScreen({Key? key, required this.roomId, required this.title}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<dynamic> _messages = [];
  Map<String, dynamic>? _roomDetail;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingImage = false;
  Timer? _pollTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadRoomDetail();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(silent: true);
      _loadRoomDetail(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/chats/${widget.roomId}/messages?limit=100',
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      final items = response['items'] ?? [];
      final grew = items.length != _messages.length;
      setState(() => _messages = items);
      if (grew) _scrollToBottom();
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('chat_room.error_prefix', {'error': '$e'}))));
      }
    } finally {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  /// Онлайн-статус собеседника (личный чат) или число участников онлайн
  /// (чат сходки/клуба) — обновляется вместе с сообщениями по таймеру.
  Future<void> _loadRoomDetail({bool silent = false}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/chats/${widget.roomId}', token: authProvider.accessToken);
      if (mounted) setState(() => _roomDetail = response is Map<String, dynamic> ? response : null);
    } catch (e) {
      if (!silent) print('Ошибка: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post(
        '/api/chats/${widget.roomId}/messages',
        {'text': text},
        token: authProvider.accessToken,
      );
      setState(() => _messages = [..._messages, result]);
      _scrollToBottom();
    } catch (e) {
      _textController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('chat_room.error_prefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingImage) return;
    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('chat_room.gallery_open_error', {'error': '$e'}))));
      return;
    }
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bytes = await picked.readAsBytes();
      final uploadResult = await ApiService.uploadImage(
        '/api/chats/${widget.roomId}/upload-image',
        bytes,
        picked.name.isNotEmpty ? picked.name : 'photo.jpg',
        token: authProvider.accessToken,
      );
      final imageUrl = uploadResult['image_url'] as String?;
      if (imageUrl == null) throw Exception(context.t('chat_room.no_image_url_error'));

      final message = await ApiService.post(
        '/api/chats/${widget.roomId}/messages',
        {'image_url': imageUrl, 'message_type': 'image'},
        token: authProvider.accessToken,
      );
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('chat_room.image_send_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('chat_room.delete_message_title')),
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete(
        '/api/chats/${widget.roomId}/messages/${msg['id']}',
        token: authProvider.accessToken,
      );
      setState(() => _messages = _messages.where((m) => m['id'] != msg['id']).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('chat_room.error_prefix', {'error': '$e'}))));
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _imageUrl(String url) => url.startsWith('http') ? url : '${ApiService.baseUrl}$url';

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.network(_imageUrl(url)),
        ),
      ),
    );
  }

  /// Подзаголовок под названием чата: онлайн-статус собеседника (личный чат)
  /// или сколько участников сейчас онлайн (чат сходки/клуба).
  Widget? _buildSubtitle() {
    final detail = _roomDetail;
    if (detail == null) return null;

    if (detail['room_type'] == 'direct') {
      final members = (detail['members'] as List?) ?? [];
      final other = members.firstWhere(
        (m) => m['id'] != _myId,
        orElse: () => null,
      );
      if (other == null) return null;
      final isOnline = other['is_online'] == true;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.greenAccent : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? context.t('chat_room.online') : context.t('chat_room.offline'),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      );
    }

    final membersCount = (detail['members_count'] as int?) ?? 0;
    final onlineCount = (detail['other_online_count'] as int?) ?? 0;
    final othersTotal = membersCount > 0 ? membersCount - 1 : 0;
    if (othersTotal <= 0) return null;
    return Text(
      context.tArgs('chat_room.online_count', {'online': '$onlineCount', 'total': '$othersTotal'}),
      style: const TextStyle(fontSize: 12, color: Colors.white70),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['user_id'] == _myId;
    final user = msg['user'] as Map<String, dynamic>?;
    final username = user?['username'] as String? ?? context.t('chat_room.default_username');
    final nameColor = premiumNameColor(user?['premium_tier'] as String?);
    final avatarUrl = user?['avatar_url'] as String?;
    final text = msg['text'] as String? ?? '';
    final imageUrl = msg['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onLongPress: isMe
          ? () => _deleteMessage(msg)
          : () => showReportDialog(context, targetType: 'message', targetId: msg['id']),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              GestureDetector(
                onTap: user?['id'] == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user!['id'])),
                        );
                      },
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(resolveImageUrl(avatarUrl)) : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 12))
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              child: Container(
                padding: EdgeInsets.all(hasImage && text.isEmpty ? 4 : 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.blue : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 6, top: 2),
                        child: Text(
                          username,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: nameColor ?? Colors.blueGrey),
                        ),
                      ),
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _openImageViewer(imageUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _imageUrl(imageUrl!),
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 200,
                              height: 120,
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    if (text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: hasImage ? 6 : 0, top: hasImage ? 6 : 0),
                        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: hasImage ? 6 : 0, top: 2, bottom: hasImage ? 4 : 0),
                      child: Text(
                        _formatTime(msg['created_at'] as String?),
                        style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, overflow: TextOverflow.ellipsis),
            if (subtitle != null) subtitle,
          ],
        ),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: AppLoader())
                : _messages.isEmpty
                    ? Center(
                        child: Text(context.t('chat_room.no_messages_yet'), style: const TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessage(_messages[index]),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _isUploadingImage
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.image_outlined, color: AppColors.blue),
                          tooltip: context.t('chat_room.send_photo_tooltip'),
                          onPressed: _pickAndSendImage,
                        ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.t('chat_room.message_hint'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.blue,
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _send,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
