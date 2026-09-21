import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../screens/story_viewer_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Лента историй сверху главного экрана: своя история/кнопка добавить + кольца
/// друзей (градиент — есть непросмотренные, серая рамка — уже всё видел).
class StoriesBar extends StatefulWidget {
  const StoriesBar({Key? key}) : super(key: key);

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _rings = [];
  bool _isLoading = true;
  bool _isUploading = false;

  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;
  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiService.get('/api/stories/feed', token: _token);
      final items = response is Map ? (response['items'] ?? []) : [];
      if (!mounted) return;
      setState(() {
        _rings = items is List ? items : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadStory() async {
    if (_isUploading) return;
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('stories_bar.gallery_open_failed', {'error': '$e'}))));
      }
      return;
    }
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await ApiService.uploadImage(
        '/api/stories/upload',
        bytes,
        picked.name.isNotEmpty ? picked.name : 'story.jpg',
        token: _token,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('stories_bar.story_published'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('stories_bar.publish_failed', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewerScreen(rings: _rings, initialIndex: index)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 94);
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final myAvatar = auth.user?['avatar_url'] as String?;
    final myUsername = (auth.user?['username'] as String?) ?? '?';
    final myRingIndex = _rings.indexWhere((r) => r['user']?['id'] == _myId);

    final friendRings = <Widget>[];
    for (var i = 0; i < _rings.length; i++) {
      final ring = _rings[i] as Map<String, dynamic>;
      final user = ring['user'] as Map<String, dynamic>?;
      if (user?['id'] == _myId) continue;

      final avatarUrl = user?['avatar_url'] as String?;
      final username = (user?['username'] as String?) ?? '?';
      final hasUnseen = ring['has_unseen'] == true;

      friendRings.add(
        GestureDetector(
          onTap: () => _openViewer(i),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnseen
                        ? const LinearGradient(
                            colors: [AppColors.red, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasUnseen ? null : Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: CircleAvatar(
                      backgroundColor: AppColors.blue.withOpacity(0.15),
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?')
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 62,
                  child: Text(
                    username,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 94,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        children: [
          GestureDetector(
            onTap: myRingIndex >= 0 ? () => _openViewer(myRingIndex) : _uploadStory,
            onLongPress: myRingIndex >= 0 ? _uploadStory : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: myRingIndex >= 0 ? AppColors.red : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColors.blue.withOpacity(0.15),
                          backgroundImage: (myAvatar != null && myAvatar.isNotEmpty) ? NetworkImage(myAvatar) : null,
                          child: (myAvatar == null || myAvatar.isEmpty)
                              ? Text(myUsername.isNotEmpty ? myUsername[0].toUpperCase() : '?')
                              : null,
                        ),
                      ),
                      if (myRingIndex < 0)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: _isUploading
                                ? const Padding(
                                    padding: EdgeInsets.all(3),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(context.t('stories_bar.you_label'), style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
          ...friendRings,
        ],
      ),
    );
  }
}
