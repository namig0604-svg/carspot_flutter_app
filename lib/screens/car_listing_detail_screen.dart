import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../utils/image_url.dart';
import '../l10n/l10n_extensions.dart';
import 'chat_room_screen.dart';

class CarListingDetailScreen extends StatefulWidget {
  final String listingId;

  const CarListingDetailScreen({Key? key, required this.listingId}) : super(key: key);

  @override
  State<CarListingDetailScreen> createState() => _CarListingDetailScreenState();
}

class _CarListingDetailScreenState extends State<CarListingDetailScreen> {
  Map<String, dynamic>? _listing;
  bool _isLoading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/car-listings/${widget.listingId}', token: authProvider.accessToken);
      setState(() => _listing = response as Map<String, dynamic>);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post(
        '/api/car-listings/${widget.listingId}/status',
        {'status': status},
        token: authProvider.accessToken,
      );
      _changed = true;
      if (mounted) setState(() => _listing = response as Map<String, dynamic>);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('car_listing_detail.delete_confirm_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('carpool.cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('car_listing_detail.delete_action'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/car-listings/${widget.listingId}', token: authProvider.accessToken);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
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
          builder: (_) => ChatRoomScreen(roomId: room['id'], title: room['title'] ?? seller?['username'] ?? context.t('part_listing_detail.seller_fallback')),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t('car_listing_detail.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
          backgroundColor: AppColors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        backgroundColor: AppColors.scaffoldBg(context),
        body: _isLoading
            ? const Center(child: AppFullLoader())
            : _listing == null
                ? Center(child: Text(context.t('part_listing_detail.load_failed'), style: TextStyle(color: AppColors.textMuted(context))))
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
    final mileage = listing['mileage_km'] as num?;

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
                    color: AppColors.surfaceAlt(context),
                    child: Icon(Icons.directions_car, size: 48, color: AppColors.textMuted(context)),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${listing['make'] ?? ''} ${listing['model'] ?? ''}'.trim(),
          style: TextStyle(color: AppColors.onSurface(context), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text('${(listing['price'] as num?)?.toStringAsFixed(0) ?? '0'} ₽', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.deepPurple)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${listing['year'] ?? ''}')),
            if (mileage != null) Chip(label: Text(context.tArgs('car_listing_detail.mileage_chip', {'mileage': mileage.toStringAsFixed(0)}))),
            if (listing['city'] != null) Chip(avatar: const Icon(Icons.location_on, size: 16), label: Text(listing['city'])),
            if (status != 'active')
              Chip(
                backgroundColor: Colors.black87,
                label: Text(
                  status == 'sold'
                      ? context.t('car_listings.status_sold')
                      : (status == 'reserved' ? context.t('car_listings.status_reserved') : context.t('car_listings.status_removed')),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        if ((listing['description'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(listing['description'], style: TextStyle(color: AppColors.onSurface(context), fontSize: 14)),
        ],
        const SizedBox(height: 20),
        if (seller != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
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
                  child: Text(
                    seller['full_name'] ?? seller['username'] ?? context.t('part_listing_detail.seller_fallback'),
                    style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.w600),
                  ),
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
              label: Text(context.t('part_listing_detail.message_seller')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        if (isMine) ...[
          Text(
            context.t('part_listing_detail.status_section_title'),
            style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusButton(context, 'active', context.t('part_listing_detail.status_active')),
              _statusButton(context, 'reserved', context.t('part_listing_detail.status_reserved')),
              _statusButton(context, 'sold', context.t('car_listings.status_sold')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _delete,
              icon: Icon(Icons.delete_outline, color: AppColors.red),
              label: Text(context.t('car_listing_detail.delete_action'), style: TextStyle(color: AppColors.red)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.red)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusButton(BuildContext context, String value, String label) {
    final current = (_listing?['status'] as String?) ?? 'active';
    final selected = current == value;
    return OutlinedButton(
      onPressed: selected ? null : () => _setStatus(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Colors.deepPurple.withOpacity(0.2) : null,
        side: BorderSide(color: selected ? Colors.deepPurple : AppColors.border(context)),
      ),
      child: Text(label, style: TextStyle(color: AppColors.onSurface(context))),
    );
  }
}
