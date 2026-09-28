import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'club_detail_screen.dart';
import 'club_form_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

class ClubsListScreen extends StatefulWidget {
  const ClubsListScreen({Key? key}) : super(key: key);

  @override
  State<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends State<ClubsListScreen> {
  List<dynamic> _clubs = [];
  bool _isLoading = false;
  bool _showMyOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_showMyOnly) {
        final response = await ApiService.get('/api/clubs/my', token: authProvider.accessToken);
        setState(() => _clubs = response is List ? response : []);
      } else {
        final q = _searchController.text.trim();
        final query = q.isEmpty ? '' : '&q=${Uri.encodeQueryComponent(q)}';
        final response = await ApiService.get('/api/clubs/?limit=100$query', token: authProvider.accessToken);
        setState(() => _clubs = response['items'] ?? []);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('clubs_list.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _logoPlaceholder() {
    return CircleAvatar(
      backgroundColor: AppColors.blue.withOpacity(0.15),
      child: const Icon(Icons.groups, color: AppColors.blue),
    );
  }

  Future<void> _toggleFavorite(Map<String, dynamic> club) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFav = club['is_favorite'] == true;
    setState(() => club['is_favorite'] = !isFav);
    try {
      if (isFav) {
        await ApiService.delete('/api/clubs/${club['id']}/favorite', token: authProvider.accessToken);
      } else {
        await ApiService.post('/api/clubs/${club['id']}/favorite', {}, token: authProvider.accessToken);
      }
    } catch (e) {
      if (mounted) {
        setState(() => club['is_favorite'] = isFav);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('clubs_list.error_message', {'error': '$e'}))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('clubs_list.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.blue.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClubFormScreen()),
            );
            if (result == true) _load();
          },
          backgroundColor: AppColors.blue,
          child: const Icon(Icons.add),
        ),
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topLeft, imageAsset: 'assets/backgrounds/clubs.jpg'),
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                FilterChip(
                  label: Text(context.t('clubs_list.all_clubs')),
                  selected: !_showMyOnly,
                  onSelected: (_) {
                    setState(() => _showMyOnly = false);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(context.t('clubs_list.my_clubs')),
                  selected: _showMyOnly,
                  onSelected: (_) {
                    setState(() => _showMyOnly = true);
                    _load();
                  },
                ),
              ],
            ),
          ),
          if (!_showMyOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  hintText: context.t('clubs_list.search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _load),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: AppFullLoader())
                : RefreshIndicator(
                    color: AppColors.red,
                    backgroundColor: AppColors.surface(context),
                    onRefresh: _load,
                    child: _clubs.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  _showMyOnly ? context.t('clubs_list.no_my_clubs') : context.t('clubs_list.no_clubs_found'),
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _clubs.length,
                            itemBuilder: (context, index) {
                              final club = _clubs[index] as Map<String, dynamic>;
                              final logoUrl = club['logo_url'] as String?;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: (logoUrl != null && logoUrl.isNotEmpty)
                                      ? CircleAvatar(backgroundImage: NetworkImage(resolveImageUrl(logoUrl)))
                                      : _logoPlaceholder(),
                                  title: Row(
                                    children: [
                                      Flexible(child: Text(club['name'] ?? '', overflow: TextOverflow.ellipsis)),
                                      if (club['is_verified'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: AppColors.blue, size: 14),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    [
                                      if ((club['city'] ?? '').toString().isNotEmpty) club['city'],
                                      context.tArgs('clubs_list.members_count', {'count': '${club['members_count'] ?? 0}'}),
                                    ].join(' · '),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          club['is_favorite'] == true ? Icons.favorite : Icons.favorite_border,
                                          color: club['is_favorite'] == true ? AppColors.red : Colors.grey,
                                          size: 20,
                                        ),
                                        tooltip: context.t('clubs_list.favorite_tooltip'),
                                        onPressed: () => _toggleFavorite(club),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ClubDetailScreen(clubId: club['id']),
                                      ),
                                    ).then((_) => _load());
                                  },
                                ),
                              );
                            },
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
