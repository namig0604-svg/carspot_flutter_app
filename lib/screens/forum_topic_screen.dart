import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/forum_category.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Tema foruma: pervoe soobshchenie + spisok otvetov + pole otveta vnizu
/// (kak "Otvetit v teme" v prilozheniyah-referensah).
/// GET /api/forum/topics/{id}, POST /api/forum/topics/{id}/replies
class ForumTopicScreen extends StatefulWidget {
  final String topicId;

  const ForumTopicScreen({Key? key, required this.topicId}) : super(key: key);

  @override
  State<ForumTopicScreen> createState() => _ForumTopicScreenState();
}

class _ForumTopicScreenState extends State<ForumTopicScreen> {
  Map<String, dynamic>? _topic;
  bool _isLoading = true;
  bool _isSending = false;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/forum/topics/${widget.topicId}', token: authProvider.accessToken);
      if (mounted) setState(() => _topic = response as Map<String, dynamic>);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('forum.error_message', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/forum/topics/${widget.topicId}/replies', {'body': text}, token: authProvider.accessToken);
      _replyController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('forum.error_message', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _authorRow(Map<String, dynamic>? author) {
    final username = (author?['username'] as String?) ?? '?';
    final avatarUrl = author?['avatar_url'] as String?;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.blue.withOpacity(0.2),
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(resolveImageUrl(avatarUrl)) : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 8),
        Text(username, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _formatTime(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    final style = forumCategoryByValue(topic?['category']);
    final replies = (topic?['replies'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(topic?['title'] ?? '', overflow: TextOverflow.ellipsis, maxLines: 1)),
      body: _isLoading || topic == null
          ? const Center(child: AppLoader())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.blue.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _authorRow(topic['author'] as Map<String, dynamic>?)),
                                  Text(
                                    _formatTime(topic['created_at']),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_note, size: 14, color: AppColors.blueBright),
                                    const SizedBox(width: 4),
                                    Text(context.t('forum.topic_author_badge'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blueBright)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(topic['body'] ?? '', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (replies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.14), shape: BoxShape.circle),
                                child: const Icon(Icons.forum_outlined, size: 28, color: AppColors.blueBright),
                              ),
                              const SizedBox(height: 10),
                              Text(context.t('forum.no_replies_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(context.t('forum.no_replies_subtitle'), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      else
                        ...replies.map((r) {
                          final reply = r as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.steel),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _authorRow(reply['author'] as Map<String, dynamic>?)),
                                      Text(
                                        _formatTime(reply['created_at']),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(reply['body'] ?? ''),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(color: AppColors.textOnDark),
                            decoration: InputDecoration(
                              hintText: context.t('forum.reply_hint'),
                              hintStyle: const TextStyle(color: AppColors.textMutedDark),
                              filled: true,
                              fillColor: AppColors.surfaceDarkAlt,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: AppColors.blue.withOpacity(0.35)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: AppColors.blue.withOpacity(0.35)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(24)),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppColors.blue,
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: AppLoader(size: 18, color: Colors.white),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                  onPressed: _sendReply,
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
