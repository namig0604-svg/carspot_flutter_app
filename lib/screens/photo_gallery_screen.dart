import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/comments_section.dart';
import '../utils/sound_player.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Общая фото-галерея — для сходки (eventId) или машины (carId).
/// Ровно один из двух должен быть задан.
class PhotoGalleryScreen extends StatefulWidget {
  final String? eventId;
  final String? carId;
  final String title;

  const PhotoGalleryScreen({Key? key, this.eventId, this.carId, this.title = 'Фото'})
      : assert(eventId != null || carId != null, 'Нужен eventId или carId'),
        super(key: key);

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final _picker = ImagePicker();
  List<dynamic> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;

  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];
  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.eventId != null
          ? '/api/photos/event/${widget.eventId}'
          : '/api/photos/car/${widget.carId}';
      final response = await ApiService.get(endpoint, token: _token);
      setState(() => _photos = response is Map ? (response['items'] as List? ?? []) : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('photo_gallery.error_prefix', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _upload() async {
    if (_isUploading) return;
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('photo_gallery.gallery_open_error', {'error': '$e'}))));
      return;
    }
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final fields = <String, String>{
        if (widget.eventId != null) 'event_id': widget.eventId!,
        if (widget.carId != null) 'car_id': widget.carId!,
      };
      await ApiService.uploadImage(
        '/api/photos/upload',
        bytes,
        picked.name.isNotEmpty ? picked.name : 'photo.jpg',
        token: _token,
        fields: fields,
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('photo_gallery.upload_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> photo) async {
    try {
      final result = await ApiService.post('/api/photos/${photo['id']}/like', {}, token: _token);
      setState(() {
        photo['likes_count'] = result['likes_count'];
        photo['is_liked'] = result['liked'];
      });
      if (mounted) SoundPlayer.play(context, AppSound.click);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('photo_gallery.error_prefix', {'error': '$e'}))));
    }
  }

  Future<void> _toggleFeature(Map<String, dynamic> photo) async {
    try {
      final result = await ApiService.post('/api/photos/${photo['id']}/feature', {}, token: _token);
      setState(() => photo['is_featured'] = result['is_featured']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('photo_gallery.error_prefix', {'error': '$e'}))));
    }
  }

  Future<void> _delete(Map<String, dynamic> photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('photo_gallery.delete_photo_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('common.delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.delete('/api/photos/${photo['id']}', token: _token);
      if (mounted) Navigator.pop(context);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('photo_gallery.error_prefix', {'error': '$e'}))));
    }
  }

  void _openViewer(Map<String, dynamic> photo) {
    final isMine = photo['user_id'] == _myId;
    final isPremium = Provider.of<AuthProvider>(context, listen: false).user?['is_premium'] == true;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          actions: [
            if (isMine && isPremium)
              StatefulBuilder(
                builder: (ctx2, setLocal) => IconButton(
                  icon: Icon(
                    photo['is_featured'] == true ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.amber,
                  ),
                  tooltip: photo['is_featured'] == true ? context.t('photo_gallery.unpin') : context.t('photo_gallery.pin_premium'),
                  onPressed: () async {
                    await _toggleFeature(photo);
                    setLocal(() {});
                  },
                ),
              ),
            if (isMine)
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(photo)),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: InteractiveViewer(
                child: Center(child: Image.network(resolveImageUrl(photo['photo_url'] ?? ''), fit: BoxFit.contain)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  StatefulBuilder(
                    builder: (ctx2, setLocal) => IconButton(
                      icon: AnimatedScale(
                        scale: photo['is_liked'] == true ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        child: Icon(
                          photo['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                          color: AppColors.red,
                        ),
                      ),
                      onPressed: () async {
                        await _toggleLike(photo);
                        setLocal(() {});
                      },
                    ),
                  ),
                  Text('${photo['likes_count'] ?? 0}', style: const TextStyle(color: Colors.white)),
                  if ((photo['caption'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(photo['caption'], style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: CommentsSection(
                  targetType: 'photo',
                  targetId: photo['id'].toString(),
                  dark: true,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _upload,
        backgroundColor: AppColors.red,
        child: _isUploading
            ? const AppLoader(size: 22, color: Colors.white)
            : const Icon(Icons.add_a_photo),
      ),
      body: _isLoading
          ? Center(child: AppFullLoader())
          : RefreshIndicator(
              color: AppColors.red,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _load,
              child: _photos.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Center(child: Text(context.t('photo_gallery.empty_title'), style: const TextStyle(color: Colors.grey, fontSize: 16))),
                        const SizedBox(height: 8),
                        Center(child: Text(context.t('photo_gallery.empty_subtitle'), style: const TextStyle(color: Colors.grey))),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _photos.length,
                      itemBuilder: (context, i) {
                        final photo = _photos[i] as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => _openViewer(photo),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  resolveImageUrl(photo['photo_url'] ?? ''),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                ),
                              ),
                              if (photo['is_featured'] == true)
                                const Positioned(
                                  left: 4,
                                  top: 4,
                                  child: Icon(Icons.push_pin, color: Colors.amber, size: 16),
                                ),
                              if ((photo['likes_count'] ?? 0) > 0)
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.favorite, color: AppColors.red, size: 11),
                                        const SizedBox(width: 2),
                                        Text('${photo['likes_count']}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
