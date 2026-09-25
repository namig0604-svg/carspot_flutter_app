import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../utils/image_url.dart';
import 'chat_room_screen.dart';
import 'part_listings_screen.dart' show partCategoryLabels, partCategoryIcons;

class PartListingDetailScreen extends StatefulWidget {
  final String listingId;

  const PartListingDetailScreen({Key? key, required this.listingId}) : super(key: key);

  @override
  State<PartListingDetailScreen> createState() => _PartListingDetailScreenState();
}

class _PartListingDetailScreenState extends State<PartListingDetailScreen> {
  Map<String, dynamic>? _listing;
  bool _isLoading = true;
  bool _statusChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/part-listings/${widget.listingId}', token: authProvider.accessToken);
      setState(() => _listing = response as Map<String, dynamic>);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post(
        '/api/part-listings/${widget.listingId}/status',
        {'status': status},
        token: authProvider.accessToken,
      );
      _statusChanged = true;
      if (mounted) setState(() => _listing = response as Map<String, dynamic>);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _messageSeller() async {
    final sellerId = _listing?['seller_id'];
    if (sellerId == null) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final room = await ApiService.post(
        '/api/chats/direct',
        {'user_id': sellerId},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      final seller = _listing?['seller'] as Map<String, dynamic>?;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(roomId: room['id'], title: room['title'] ?? seller?['username'] ?? 'Продавец'),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _statusChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Объявление'),
          backgroundColor: AppColors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _statusChanged),
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoader())
            : _listing == null
                ? const Center(child: Text('Не удалось загрузить', style: TextStyle(color: AppColors.textMutedDark)))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final listing = _listing!;
    final photoUrl = listing['photo_url'] as String?;
    final seller = listing['seller'] as Map<String, dynamic>?;
    final isMine = seller != null && seller['id'] == authProvider.user?['id'];
    final status = (listing['status'] as String?) ?? 'active';
    final category = (listing['category'] as String?) ?? 'other';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? Image.network(resolveImageUrl(photoUrl), fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceDarkAlt,
                    child: Icon(partCategoryIcons[category] ?? Icons.category, size: 48, color: AppColors.textMutedDark),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(listing['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('${(listing['price'] as num?)?.toStringAsFixed(0) ?? '0'} ₽', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.blue)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(partCategoryLabels[category] ?? category), avatar: Icon(partCategoryIcons[category], size: 16)),
            if (listing['car_brand'] != null)
              Chip(label: Text('${listing['car_brand']} ${listing['car_model'] ?? ''}'.trim())),
            if (listing['city'] != null) Chip(avatar: const Icon(Icons.location_on, size: 16), label: Text(listing['city'])),
            if (status != 'active')
              Chip(
                backgroundColor: Colors.black87,
                label: Text(
                  status == 'sold' ? 'Продано' : (status == 'reserved' ? 'В резерве' : 'Снято с продажи'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        if ((listing['description'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(listing['description'], style: const TextStyle(fontSize: 14)),
        ],
        const SizedBox(height: 20),
        if (seller != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.steel),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: (seller['avatar_url'] != null && (seller['avatar_url'] as String).isNotEmpty)
                      ? NetworkImage(resolveImageUrl(seller['avatar_url']))
                      : null,
                  child: (seller['avatar_url'] == null || (seller['avatar_url'] as String).isEmpty)
                      ? Text((seller['full_name'] ?? seller['username'] ?? '?').toString().substring(0, 1))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(seller['full_name'] ?? seller['username'] ?? 'Продавец', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (!isMine)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: status == 'active' ? _messageSeller : null,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Написать продавцу'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        if (isMine) ...[
          const Text('Статус объявления', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusButton('active', 'Активно'),
              _statusButton('reserved', 'В резерве'),
              _statusButton('sold', 'Продано'),
              _statusButton('removed', 'Снять с продажи'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statusButton(String value, String label) {
    final current = (_listing?['status'] as String?) ?? 'active';
    final selected = current == value;
    return OutlinedButton(
      onPressed: selected ? null : () => _setStatus(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.blue.withOpacity(0.2) : null,
        side: BorderSide(color: selected ? AppColors.blue : AppColors.steel),
      ),
      child: Text(label),
    );
  }
}
