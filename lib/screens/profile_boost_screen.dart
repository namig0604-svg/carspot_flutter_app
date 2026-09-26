import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/cosmetics.dart';
import 'coins_screen.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';

/// "Прокачка профиля" — куда уходят монеты CarSpot Coins сверх бустов
/// сходок/автосервисов: разовая покупка бонусного XP (плюсуется к уровню,
/// который приложение и так считает из статистики), временный буст профиля
/// в топ поиска и косметика (рамка аватара, значок, цвет имени).
class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({Key? key}) : super(key: key);

  @override
  State<ProfileBoostScreen> createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen> {
  Map<String, dynamic>? _status;
  int _balance = 0;
  List<dynamic> _catalog = [];
  bool _isLoading = false;
  String? _busyAction; // id косметики/действия, которое сейчас в процессе

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await Future.wait([
        ApiService.get('/api/coins/profile/status', token: authProvider.accessToken),
        ApiService.get('/api/coins/balance', token: authProvider.accessToken),
        ApiService.get('/api/coins/cosmetics/catalog', token: authProvider.accessToken),
      ]);
      if (!mounted) return;
      setState(() {
        _status = results[0] is Map<String, dynamic> ? results[0] as Map<String, dynamic> : null;
        _balance = (results[1] is Map && (results[1] as Map)['balance'] != null) ? (results[1]['balance'] as num).toInt() : 0;
        _catalog = results[2] is List ? results[2] as List : [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.getCurrentUser();
  }

  Future<void> _buyXpBoost() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = 'xp_boost');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/coins/profile/xp-boost', {}, token: authProvider.accessToken);
      await _refreshUser();
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('profile_boost.xp_bought_snackbar'))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _buySearchBoost() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = 'search_boost');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/coins/profile/boost', {}, token: authProvider.accessToken);
      await _refreshUser();
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('profile_boost.search_boost_bought_snackbar'))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _handleCosmeticTap(Map<String, dynamic> item) async {
    if (_busyAction != null) return;
    final id = item['id'] as String;
    final owned = item['owned'] == true;
    final equipped = item['equipped'] == true;
    setState(() => _busyAction = id);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!owned) {
        await ApiService.post('/api/coins/cosmetics/buy', {'cosmetic_id': id}, token: authProvider.accessToken);
      } else if (!equipped) {
        await ApiService.post('/api/coins/cosmetics/equip', {'cosmetic_id': id}, token: authProvider.accessToken);
      } else {
        await ApiService.post('/api/coins/cosmetics/unequip', {'slot': item['type']}, token: authProvider.accessToken);
      }
      await _refreshUser();
      await _loadAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Widget _cosmeticPreview(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final id = item['id'] as String;
    if (type == 'frame') {
      final color = frameColorFor(id) ?? Colors.grey;
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 4)),
      );
    }
    if (type == 'badge') {
      final icon = badgeIconFor(id) ?? Icons.star;
      return Icon(icon, color: Colors.amber, size: 28);
    }
    final color = nameColorFor(id) ?? Colors.grey;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _cosmeticSection(String titleKey, String type, Color cardSurface, Color cardText) {
    final items = _catalog.where((c) => c is Map && c['type'] == type).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t(titleKey), style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final raw in items)
                if (raw is Map<String, dynamic>) _cosmeticCard(raw, cardSurface, cardText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cosmeticCard(Map<String, dynamic> item, Color cardSurface, Color cardText) {
    final owned = item['owned'] == true;
    final equipped = item['equipped'] == true;
    final busy = _busyAction == item['id'];
    final borderColor = equipped ? AppColors.blue : (owned ? Colors.green.withOpacity(0.5) : AppColors.steel);

    String actionLabel;
    if (!owned) {
      actionLabel = context.tArgs('profile_boost.cosmetic_buy', {'cost': '${item['cost']}'});
    } else if (!equipped) {
      actionLabel = context.t('profile_boost.cosmetic_equip');
    } else {
      actionLabel = context.t('profile_boost.cosmetic_unequip');
    }

    return InkWell(
      onTap: busy ? null : () => _handleCosmeticTap(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: equipped ? 2 : 1),
        ),
        child: Column(
          children: [
            if (busy)
              const AppLoader(size: 24)
            else
              _cosmeticPreview(item),
            const SizedBox(height: 6),
            Text(
              item['title']?.toString() ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cardText, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              actionLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: equipped ? AppColors.blue : (owned ? Colors.green : cardText.withOpacity(0.7)),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    final bonusXp = (_status?['bonus_xp'] ?? 0) as int;
    final xpBoostCost = (_status?['xp_boost_cost'] ?? 0) as int;
    final xpBoostGrant = (_status?['xp_boost_grant_amount'] ?? 0) as int;
    final searchBoostCost = (_status?['profile_boost_cost'] ?? 0) as int;
    final boostHours = (_status?['boost_duration_hours'] ?? 0) as int;
    final boostedUntilRaw = _status?['profile_boosted_until'] as String?;
    DateTime? boostedUntil;
    if (boostedUntilRaw != null) {
      try {
        boostedUntil = DateTime.parse(boostedUntilRaw);
      } catch (_) {}
    }
    final isBoosted = boostedUntil != null && boostedUntil.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('profile_boost.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.blueDark,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: _loadAll,
        child: _isLoading && _status == null
            ? const Center(child: AppFullLoader())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('coins.balance_label'), style: TextStyle(color: cardText.withOpacity(0.7), fontSize: 13)),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('$_balance', style: TextStyle(color: cardText, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen())),
                            child: Text(context.t('boost.top_up_button'), style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Бонусный XP ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.steel),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(context.t('profile_boost.xp_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tArgs('profile_boost.xp_body', {'bonus': '$bonusXp'}),
                          style: TextStyle(color: cardText.withOpacity(0.75), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busyAction == null ? _buyXpBoost : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                            child: _busyAction == 'xp_boost'
                                ? const AppLoader(size: 18, color: Colors.white)
                                : Text(context.tArgs('profile_boost.xp_buy_button', {'grant': '$xpBoostGrant', 'cost': '$xpBoostCost'})),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Буст профиля в поиске ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.steel),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.rocket_launch, color: AppColors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(context.t('profile_boost.search_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tArgs('profile_boost.search_body', {'hours': '$boostHours'}),
                          style: TextStyle(color: cardText.withOpacity(0.75), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_busyAction == null && !isBoosted) ? _buySearchBoost : null,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
                            child: _busyAction == 'search_boost'
                                ? const AppLoader(size: 18, color: Colors.white)
                                : Text(
                                    isBoosted
                                        ? context.t('profile_boost.search_active')
                                        : context.tArgs('profile_boost.search_buy_button', {'cost': '$searchBoostCost'}),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Косметика ---
                  _cosmeticSection('profile_boost.frames_title', 'frame', cardSurface, cardText),
                  _cosmeticSection('profile_boost.badges_title', 'badge', cardSurface, cardText),
                  _cosmeticSection('profile_boost.colors_title', 'name_color', cardSurface, cardText),
                ],
              ),
      ),
    );
  }
}
