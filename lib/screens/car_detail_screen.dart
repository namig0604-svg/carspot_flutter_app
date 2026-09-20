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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
          title: const Text('Только для Premium'),
          content: const Text('Список тех, кто лайкнул машину, доступен только с CarSpot Premium.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Узнать больше')),
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
        MaterialPageRoute(builder: (_) => PeopleListScreen(title: 'Кто лайкнул машину', people: people)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить машину?'),
        content: const Text('Это нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.red)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
        title: Text(car != null ? '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim() : 'Машина'),
        backgroundColor: AppColors.black,
        elevation: 0,
        actions: [
          if (car != null && _isOwner) ...[
            IconButton(icon: const Icon(Icons.edit), tooltip: 'Изменить', onPressed: _openEdit),
            if (!(car['is_primary'] ?? false))
              IconButton(icon: const Icon(Icons.star_outline), tooltip: 'Сделать основной', onPressed: _setPrimary),
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Удалить', onPressed: _delete),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: AppLoader())
          : car == null
              ? const Center(child: Text('Машина не найдена'))
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
                          if (car['is_primary'] == true) _badge('Основная', Colors.orange),
                          if (car['is_for_sale'] == true) _badge('Продаётся', Colors.green),
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
                                label: Text('${car['likes_count'] ?? 0} · кто?'),
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
                                    title: 'Фото машины',
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Фото'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Характеристики', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _specRow('Двигатель', car['engine']),
                      _specRow('Объём', car['engine_volume']),
                      _specRow('Мощность', car['power_hp'] != null ? '${car['power_hp']} л.с.' : null),
                      _specRow('Крутящий момент', car['torque_nm'] != null ? '${car['torque_nm']} Нм' : null),
                      _specRow('Привод', car['drivetrain']),
                      _specRow('Трансмиссия', car['transmission']),
                      _specRow('Топливо', car['fuel_type']),
                      _specRow('Вес', car['weight_kg'] != null ? '${car['weight_kg']} кг' : null),
                      _specRow('0-100', car['zero_to_hundred'] != null ? '${car['zero_to_hundred']} с' : null),
                      _specRow('Цвет', car['color']),
                      _specRow('Госномер', car['license_plate']),
                      if ((car['mods'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Доработки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(car['mods']),
                      ],
                      if ((car['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Описание', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
