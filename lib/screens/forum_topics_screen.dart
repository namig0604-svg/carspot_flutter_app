import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/forum_category.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import 'forum_create_topic_screen.dart';
import 'forum_topic_screen.dart';

/// Spisok tem odnoy kategorii (GET /api/forum/topics?category=...), s
/// filtrom po strane i poiskom po zagolovku. Knopka "Novaya tema" vnizu.
class ForumTopicsScreen extends StatefulWidget {
  final String category;

  const ForumTopicsScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<ForumTopicsScreen> createState() => _ForumTopicsScreenState();
}

class _ForumTopicsScreenState extends State<ForumTopicsScreen> {
  List<dynamic> _topics = [];
  bool _isLoading = true;
  String? _country;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      var endpoint = '/api/forum/topics?category=${widget.category}&limit=100';
      if (_country != null && _country!.isNotEmpty) {
        endpoint += '&country=${Uri.encodeQueryComponent(_country!)}';
      }
      if (_search.trim().isNotEmpty) {
        endpoint += '&search=${Uri.encodeQueryComponent(_search.trim())}';
      }
      final response = await ApiService.get(endpoint, token: authProvider.accessToken);
      if (mounted) setState(() => _topics = response['items'] ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('forum.error_message', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(context.t('forum.all_countries')),
              leading: const Icon(Icons.public),
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(height: 1),
            ...kSupportedCountries.map((c) => ListTile(
                  title: Text(c),
                  onTap: () => Navigator.pop(context, c),
                )),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _country = picked.isEmpty ? null : picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = forumCategoryByValue(widget.category);
    return Scaffold(
      appBar: AppBar(title: Text(forumCategoryLabel(context, widget.category), overflow: TextOverflow.ellipsis, maxLines: 1)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: AppColors.surfaceDarkAlt,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _pickCountry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.steel),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public, size: 16, color: AppColors.blue),
                        const SizedBox(width: 8),
                        Text(_country ?? context.t('forum.all_countries'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 18, color: AppColors.textMutedDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              onChanged: (v) {
                _search = v;
                _load();
              },
              decoration: InputDecoration(
                hintText: context.t('forum.search_topics_hint'),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMutedDark),
                filled: true,
                fillColor: AppColors.surfaceDarkAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.blue.withOpacity(0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.blue.withOpacity(0.35)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppColors.blue, width: 1.6),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoader())
                : _topics.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(context.t('forum.no_topics'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                          itemCount: _topics.length,
                          itemBuilder: (context, i) {
                            final t = _topics[i] as Map<String, dynamic>;
                            final author = t['author'] as Map<String, dynamic>?;
                            final avatarUrl = author?['avatar_url'] as String?;
                            final username = (author?['username'] ?? '?').toString();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.steel),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ForumTopicScreen(topicId: t['id'])),
                                  ).then((_) => _load()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: style.color.withOpacity(0.2),
                                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                              ? NetworkImage(resolveImageUrl(avatarUrl))
                                              : null,
                                          child: (avatarUrl == null || avatarUrl.isEmpty)
                                              ? Text(
                                                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                                                  style: TextStyle(color: style.color, fontWeight: FontWeight.w800),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t['title'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                t['body'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMutedDark),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    username,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                  ),
                                                  const Spacer(),
                                                  const Icon(Icons.forum_outlined, size: 15, color: AppColors.textMutedDark),
                                                  const SizedBox(width: 4),
                                                  Text('${t['replies_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textMutedDark),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: style.color,
        icon: const Icon(Icons.add),
        label: Text(context.t('forum.new_topic_button')),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ForumCreateTopicScreen(category: widget.category)),
          );
          if (created == true) _load();
        },
      ),
    );
  }
}
