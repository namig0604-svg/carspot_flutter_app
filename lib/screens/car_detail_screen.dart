import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'car_form_screen.dart';
import 'photo_gallery_screen.dart';
import 'people_list_screen.dart';
import 'premium_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../utils/sound_player.dart';
import '../l10n/l10n_extensions.dart';

/// Карточка машины: полные характеристики, лайк (для чужой машины),
/// быстрый доступ к фото-галерее и — для владельца — редактирование/удаление.
class CarDetailScreen extends StatefulWidget {
  final String carId;

  const CarDetailScreen({Key? key, required this.carId}) : super(key: key);

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  Map<String, dynamic>? _car;
  bool _isLoading = true;
  bool _isActionLoading = false;

  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];
  bool get _isOwner => _car != null && _car!['user_id'] == _myId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/cars/${widget.carId}', token: authProvider.accessToken);
      setState(() => _car = response as Map<String, dynamic>);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('car_detail.generic_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openLikers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.user?['is_premium'] == true;
    if (!isPremium) {
      final goPremium = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.t('car_detail.premium_only_title')),
          content: Text(context.t('car_detail.premium_only_content')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.t('car_detail.learn_more_button'))),
          ],
        ),
      );
      if (goPremium == true && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
      }
      return;
    }
    try {
      final response = await ApiService.get('/api/cars/${widget.carId}/likers', token: authProvider.accessToken);
      final people = response is List ? response : [];
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PeopleListScreen(title: context.t('car_detail.likers_title'), people: people)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('car_detail.generic_error', {'error': '$e'}))));
    }
  }

  Future<void> _toggleLike() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post('/api/cars/${widget.carId}/like', {}, token: authProvider.accessToken);
      setState(() {
        _car!['is_liked'] = result['liked'];
        _car!['likes_count'] = result['likes_count'];
      });
      if (mounted) SoundPlayer.play(context, AppSound.click);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('car_detail.generic_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CarFormScreen(car: _car)),
    );
    if (result == true) _load();
  }

  Future<void> _setPrimary() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/cars/${widget.carId}/primary', {}, token: authProvider.accessToken);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('car_detail.generic_error', {'error': '$e'}))));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('car_detail.delete_confirm_title')),
        content: Text(context.t('car_detail.delete_confirm_content')),
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/cars/${widget.carId}', token: authProvider.accessToken);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('car_detail.generic_error', {'error': '$e'}))));
    }
  }

  Widget _specRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    return Scaffold(
      appBar: AppBar(
        title: Text(car != null ? '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim() : context.t('car_detail.title_fallback')),
        backgroundColor: AppColors.black,
        elevation: 0,
        actions: [
          if (car != null && _isOwner) ...[
            IconButton(icon: const Icon(Icons.edit), tooltip: context.t('common.edit'), onPressed: _openEdit),
            if (!(car['is_primary'] ?? false))
              IconButton(icon: const Icon(Icons.star_outline), tooltip: context.t('car_detail.set_primary_tooltip'), onPressed: _setPrimary),
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: context.t('common.delete'), onPressed: _delete),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: AppLoader())
          : car == null
              ? Center(child: Text(context.t('car_detail.not_found')))
              : RefreshIndicator(
                  color: AppColors.red,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (car['photo_url'] != null && (car['photo_url'] as String).isNotEmpty)
                            ? Image.network(car['photo_url'], height: 200, width: double.infinity, fit: BoxFit.cover)
                            : Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim(),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (car['year'] != null)
                            Text('${car['year']}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (car['is_primary'] == true) _badge(context.t('car_detail.badge_primary'), Colors.orange),
                          if (car['is_for_sale'] == true) _badge(context.t('car_detail.badge_for_sale'), Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!_isOwner)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _toggleLike,
                                icon: AnimatedScale(
                                  scale: car['is_liked'] == true ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.elasticOut,
                                  child: Icon(
                                    car['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                                    color: AppColors.red,
                                  ),
                                ),
                                label: Text('${car['likes_count'] ?? 0}'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openLikers,
                                icon: const Icon(Icons.favorite, color: AppColors.red),
                                label: Text(context.tArgs('car_detail.likes_who_label', {'count': '${car['likes_count'] ?? 0}'})),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhotoGalleryScreen(
                                    carId: widget.carId,
                                    title: context.t('car_detail.photo_gallery_title'),
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(context.t('car_detail.photo_button')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(context.t('car_detail.specs_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _specRow(context.t('car_detail.spec_engine'), car['engine']),
                      _specRow(context.t('car_detail.spec_volume'), car['engine_volume']),
                      _specRow(context.t('car_detail.spec_power'), car['power_hp'] != null ? context.tArgs('car_detail.unit_hp', {'value': '${car['power_hp']}'}) : null),
                      _specRow(context.t('car_detail.spec_torque'), car['torque_nm'] != null ? context.tArgs('car_detail.unit_nm', {'value': '${car['torque_nm']}'}) : null),
                      _specRow(context.t('car_detail.spec_drivetrain'), car['drivetrain']),
                      _specRow(context.t('car_detail.spec_transmission'), car['transmission']),
                      _specRow(context.t('car_detail.spec_fuel'), car['fuel_type']),
                      _specRow(context.t('car_detail.spec_weight'), car['weight_kg'] != null ? context.tArgs('car_detail.unit_kg', {'value': '${car['weight_kg']}'}) : null),
                      _specRow(context.t('car_detail.spec_zero_to_hundred'), car['zero_to_hundred'] != null ? context.tArgs('car_detail.unit_sec', {'value': '${car['zero_to_hundred']}'}) : null),
                      _specRow(context.t('car_detail.spec_color'), car['color']),
                      _specRow(context.t('car_detail.spec_plate'), car['license_plate']),
                      if ((car['mods'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(context.t('car_detail.mods_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(car['mods']),
                      ],
                      if ((car['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(context.t('car_detail.description_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(car['description']),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
