import 'package:flutter/material.dart';
import 'user_profile_screen.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Общий список людей — используется для "кто лайкнул" и "кто смотрел профиль" (Premium).
/// Каждый элемент people — карта пользователя, опционально с ключом 'subtitle_override'
/// (например, время просмотра) — если его нет, показывается @username.
class PeopleListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> people;
  final String? emptyText;

  const PeopleListScreen({
    Key? key,
    required this.title,
    required this.people,
    this.emptyText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1), backgroundColor: Colors.amber.shade800),
      body: people.isEmpty
          ? Center(child: Text(emptyText ?? context.t('people_list.empty_default'), style: const TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: people.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final person = people[i] as Map<String, dynamic>;
                final avatarUrl = person['avatar_url'] as String?;
                final subtitle = person['subtitle_override'] as String? ?? '@${person['username'] ?? ''}';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(resolveImageUrl(avatarUrl)) : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(((person['full_name'] ?? person['username'] ?? 'U') as String).substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(person['full_name'] ?? person['username'] ?? ''),
                  subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                  trailing: person['is_premium'] == true
                      ? const Icon(Icons.workspace_premium, color: Colors.amber, size: 18)
                      : null,
                  onTap: () {
                    final id = person['id'] as String?;
                    if (id == null) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: id)));
                  },
                );
              },
            ),
    );
  }
}
