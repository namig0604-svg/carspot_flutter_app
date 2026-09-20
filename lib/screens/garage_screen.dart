import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'car_detail_screen.dart';
import 'car_form_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  List<dynamic> _cars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGarage();
  }

  Future<void> _loadGarage() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/cars/my', token: authProvider.accessToken);
      setState(() {
        _cars = response['cars'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? car}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CarFormScreen(car: car)),
    );
    if (result == true) _loadGarage();
  }

  Future<void> _setPrimary(Map<String, dynamic> car) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/cars/${car['id']}/primary', {}, token: authProvider.accessToken);
      _loadGarage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteCar(Map<String, dynamic> car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить машину?'),
        content: Text('${car['make']} ${car['model']} будет удалена из гаража. Это нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/cars/${car['id']}', token: authProvider.accessToken);
      _loadGarage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _showActions(Map<String, dynamic> car) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.blue),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _openForm(car: car);
              },
            ),
            if (!(car['is_primary'] ?? false))
              ListTile(
                leading: const Icon(Icons.star, color: Colors.orange),
                title: const Text('Сделать основной'),
                onTap: () {
                  Navigator.pop(context);
                  _setPrimary(car);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.red),
              title: const Text('Удалить', style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteCar(car);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final photoUrl = car['photo_url'] as String?;
    final isPrimary = car['is_primary'] ?? false;
    final isForSale = car['is_for_sale'] ?? false;

    final subtitleParts = <String>[];
    if (car['engine'] != null) subtitleParts.add(car['engine']);
    if (car['power_hp'] != null) subtitleParts.add('${car['power_hp']} л.с.');
    if (car['drivetrain'] != null) subtitleParts.add(car['drivetrain']);
    if ((car['license_plate'] ?? '').toString().isNotEmpty) subtitleParts.add(car['license_plate']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car['id'])),
          );
          if (changed == true) _loadGarage();
        },
        onLongPress: () => _showActions(car),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        photoUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _carIconPlaceholder(),
                      )
                    : _carIconPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${car['make'] ?? ''} ${car['model'] ?? ''}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (car['year'] != null)
                          Text('${car['year']}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isPrimary || isForSale) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (isPrimary) _badge('Основная', Colors.orange),
                          if (isForSale) _badge('Продаётся', Colors.green),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carIconPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: const Icon(Icons.directions_car, color: Colors.grey, size: 32),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой гараж'),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.red.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _openForm(),
          backgroundColor: AppColors.red,
          child: const Icon(Icons.add),
        ),
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topLeft, imageAsset: 'assets/backgrounds/garage.jpg'),
          Theme(data: AppTheme.dark, child: _isLoading
          ? Center(child: AppLoader())
          : RefreshIndicator(
              color: AppColors.red,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _loadGarage,
              child: _cars.isEmpty
                  ? ListView(
                      // ListView, чтобы RefreshIndicator работал даже на пустом гараже
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('Гараж пуст', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Добавь свою первую машину',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cars.length,
                      itemBuilder: (context, index) => _buildCarCard(_cars[index]),
                    ),
            )),
        ],
      ),
    );
  }
}
