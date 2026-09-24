import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/forum_category.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
import 'forum_topics_screen.dart';

/// Spisok kategoriy foruma so schetchikom tem v kazhdoy (GET /api/forum/categories).
/// Tap na kategoriyu otkryvaet forum_topics_screen.dart s temami etoy kategorii.
class ForumCategoriesScreen extends StatefulWidget {
  const ForumCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<ForumCategoriesScreen> createState() => _ForumCategoriesScreenState();
}

class _ForumCategoriesScreenState extends State<ForumCategoriesScreen> {
  List<dynamic> _counts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/forum/categories', token: authProvider.accessToken);
      if (mounted) setState(() => _counts = response is List ? response : []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('forum.error_message', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _countFor(String category) {
    final row = _counts.firstWhere(
      (r) => r['category'] == category,
      orElse: () => null,
    );
    return row == null ? 0 : ((row['topics_count'] as num?)?.toInt() ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('forum.categories_title'), overflow: TextOverflow.ellipsis, maxLines: 1)),
      body: _isLoading
          ? const Center(child: AppLoader())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      context.t('forum.categories_hint'),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...forumCategories.map((c) {
                    final count = _countFor(c.value);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ForumTopicsScreen(category: c.value)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: c.color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: c.color.withOpacity(0.5)),
                                ),
                                child: Icon(c.icon, color: c.color, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      forumCategoryLabel(context, c.value),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      forumCategoryDescription(context, c.value),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  Text(context.t('forum.topics_word'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
