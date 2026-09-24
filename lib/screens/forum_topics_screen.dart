import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/forum_category.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
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
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickCountry,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 18),
                      const SizedBox(width: 8),
                      Text(_country ?? context.t('forum.all_countries')),
                      const Spacer(),
                      const Icon(Icons.expand_more),
                    ],
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
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(t['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  (author?['username'] ?? '') + ((t['country'] ?? '').toString().isNotEmpty ? ' • ${t['country']}' : ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.forum_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${t['replies_count'] ?? 0}'),
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ForumTopicScreen(topicId: t['id'])),
                                ).then((_) => _load()),
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
