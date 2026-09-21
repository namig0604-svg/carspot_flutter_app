import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'people_list_screen.dart';
import '../theme/app_colors.dart';
import '../utils/sound_player.dart';

/// Экран CarSpot Premium: статус подписки, пробный период, реферальная
/// программа (10 друзей = месяц Premium) и список привилегий.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Map<String, dynamic>? _referral;
  bool _isLoadingReferral = false;
  bool _isActivatingTrial = false;

  // Покупка Premium через Trybit
  List<dynamic> _plans = [];
  bool _isLoadingPlans = false;
  String? _activePaymentId;
  Timer? _paymentPollTimer;
  int _pollAttempts = 0;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadReferral();
    _loadPlans();
  }

  @override
  void dispose() {
    _paymentPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReferral() async {
    setState(() => _isLoadingReferral = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/users/me/referral', token: authProvider.accessToken);
      if (mounted) setState(() => _referral = response is Map<String, dynamic> ? response : null);
    } catch (_) {
      // тихо игнорируем — реферальный блок необязателен для этого экрана
    } finally {
      if (mounted) setState(() => _isLoadingReferral = false);
    }
  }

  Future<void> _activateTrial() async {
    setState(() => _isActivatingTrial = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/users/me/premium-trial', {}, token: authProvider.accessToken);
      await authProvider.getCurrentUser();
      if (mounted) {
        SoundPlayer.play(context, AppSound.success);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пробный Premium активирован на 14 дней 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось активировать: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActivatingTrial = false);
    }
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoadingPlans = true);
    try {
      final response = await ApiService.get('/api/payments/plans');
      if (mounted) setState(() => _plans = response is List ? response : []);
    } catch (_) {
      // тихо игнорируем — тарифы не критичны для остального экрана
    } finally {
      if (mounted) setState(() => _isLoadingPlans = false);
    }
  }

  Future<void> _startCheckout(String planId) async {
    if (_isCheckingOut) return; // защита от двойного тапа — не открываем два счёта на оплату
    setState(() => _isCheckingOut = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post('/api/payments/checkout', {'plan': planId}, token: authProvider.accessToken);
      if (!mounted) return;
      final payUrl = result['pay_url'] as String?;
      final paymentId = result['payment_id'] as String?;
      if (payUrl == null || paymentId == null) {
        throw Exception('Не удалось создать счёт на оплату');
      }

      final opened = await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) throw Exception('Не удалось открыть страницу оплаты');

      setState(() => _activePaymentId = paymentId);
      _startPolling(paymentId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _startPolling(String paymentId) {
    _paymentPollTimer?.cancel();
    _pollAttempts = 0;
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollAttempts++;
      if (_pollAttempts > 60) {
        // 5 минут — дальше пользователь может нажать "Проверить сейчас" сам
        timer.cancel();
        return;
      }
      await _checkPaymentNow(paymentId, silent: true);
    });
  }

  Future<void> _checkPaymentNow(String paymentId, {bool silent = false}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.get('/api/payments/$paymentId/status', token: authProvider.accessToken);
      final status = result['status'] as String?;

      if (status == 'paid') {
        _paymentPollTimer?.cancel();
        await authProvider.getCurrentUser();
        if (mounted) {
          setState(() => _activePaymentId = null);
          SoundPlayer.play(context, AppSound.success);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оплата подтверждена — Premium активирован! 🎉')),
          );
        }
      } else if (status == 'canceled' || status == 'failed') {
        _paymentPollTimer?.cancel();
        if (mounted) {
          setState(() => _activePaymentId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оплата не прошла — попробуй ещё раз')),
          );
        }
      } else if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пока не оплачено — оплати по открытой ссылке и попробуй снова')),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  void _cancelPolling() {
    _paymentPollTimer?.cancel();
    setState(() => _activePaymentId = null);
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _openLikers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.user?['is_premium'] == true;
    if (!isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Список тех, кто лайкнул профиль, доступен с Premium')),
      );
      return;
    }
    try {
      final response = await ApiService.get('/api/users/me/likers', token: authProvider.accessToken);
      final people = response is List ? response : [];
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PeopleListScreen(title: 'Кто лайкнул профиль', people: people)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _openProfileViews() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.user?['is_premium'] == true;
    if (!isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Список просмотров профиля доступен с Premium')),
      );
      return;
    }
    try {
      final response = await ApiService.get('/api/users/me/profile-views', token: authProvider.accessToken);
      final rows = response is List ? response : [];
      final people = rows.map<Map<String, dynamic>>((row) {
        final user = Map<String, dynamic>.from(row['user'] as Map);
        user['subtitle_override'] = 'Смотрел ${_formatDate(row['viewed_at'].toString())}';
        return user;
      }).toList();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PeopleListScreen(title: 'Кто смотрел профиль', people: people)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Widget _perkTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.amber.withOpacity(0.15),
        child: Icon(icon, color: Colors.amber.shade800),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isPremium = user?['is_premium'] == true;
    final trialUsed = user?['premium_trial_used'] == true;
    final premiumUntil = user?['premium_until'] as String?;

    final referralsCount = (_referral?['referrals_count'] ?? 0) as int;
    final perMonth = (_referral?['referrals_per_premium_month'] ?? 10) as int;
    final untilNext = (_referral?['referrals_until_next_reward'] ?? perMonth) as int;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final monthsEarned = (_referral?['premium_months_earned'] ?? 0) as int;
    final progress = perMonth == 0 ? 0.0 : ((perMonth - untilNext) / perMonth).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarSpot Premium'),
        backgroundColor: Colors.amber.shade800,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          await authProvider.getCurrentUser();
          await _loadReferral();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.amber.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                      const SizedBox(width: 10),
                      Text(
                        isPremium ? 'Premium активен' : 'Premium не активен',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isPremium && premiumUntil != null)
                    Text(
                      'Действует до ${_formatDate(premiumUntil)}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    )
                  else
                    const Text(
                      'Открой автосервисы, больше машин в гараже и другие возможности',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (!trialUsed && !isPremium)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isActivatingTrial ? null : _activateTrial,
                  icon: _isActivatingTrial
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.card_giftcard),
                  label: const Text('Попробовать 14 дней бесплатно'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else if (trialUsed && !isPremium)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Пробный период уже использован. Получи Premium снова через реферальную программу ниже.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 20),

            Text(isPremium ? 'Продлить Premium' : 'Купить Premium', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Оплата через Trybit — картой или криптовалютой, работает в любой стране СНГ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            if (_isLoadingPlans)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_activePaymentId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(AppColors.blue.withOpacity(0.18), cardSurface),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Ждём подтверждения оплаты...', style: TextStyle(color: cardText)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _checkPaymentNow(_activePaymentId!),
                            child: const Text('Проверить сейчас'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelPolling,
                          child: const Text('Отмена'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              ..._plans.map<Widget>((p) {
                final plan = p as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isCheckingOut ? null : () => _startCheckout(plan['id'] as String),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(plan['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '\$${plan['amount_usd']}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color.alphaBlend(Colors.green.withOpacity(0.28), cardSurface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text('Реферальная программа', style: TextStyle(fontWeight: FontWeight.bold, color: cardText)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_referral?['code'] != null)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${_referral!['code']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.green),
                          tooltip: 'Скопировать код',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${_referral!['code']}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Код скопирован')),
                            );
                          },
                        ),
                      ],
                    )
                  else if (_isLoadingReferral)
                    const Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Загружаем код...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Приглашено друзей: $referralsCount · заработано месяцев Premium: $monthsEarned',
                    style: TextStyle(color: cardText, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.green.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    untilNext == perMonth
                        ? 'Пригласи $perMonth друзей — получи месяц Premium'
                        : 'Ещё $untilNext друзей до следующего месяца Premium',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Твоя популярность', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.red,
                      child: Icon(Icons.favorite, color: Colors.white, size: 18),
                    ),
                    title: Text('${user?['likes_count'] ?? 0} лайков профиля'),
                    subtitle: Text(isPremium ? 'Смотри, кто лайкнул' : 'Оформи Premium, чтобы увидеть кто'),
                    trailing: Icon(isPremium ? Icons.chevron_right : Icons.lock_outline, color: Colors.grey),
                    onTap: _openLikers,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.blue,
                      child: Icon(Icons.visibility, color: Colors.white, size: 18),
                    ),
                    title: Text('${user?['profile_views_count'] ?? 0} просмотров профиля'),
                    subtitle: Text(isPremium ? 'Смотри, кто заходил' : 'Оформи Premium, чтобы увидеть кто'),
                    trailing: Icon(isPremium ? Icons.chevron_right : Icons.lock_outline, color: Colors.grey),
                    onTap: _openProfileViews,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Что даёт Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _perkTile(Icons.favorite, 'Кто лайкнул и кто смотрел',
                      'Полные списки тех, кто лайкнул профиль/машину и кто заходил к тебе в профиль'),
                  const Divider(height: 1),
                  _perkTile(Icons.rocket_launch, 'Буст сходок и заведений',
                      'Поднимай свою сходку или автосервис в топ ленты и каталога на 24 часа'),
                  const Divider(height: 1),
                  _perkTile(Icons.storefront, 'Добавление автосервисов',
                      'Только подписчики Premium могут размещать свои автосервисы и ателье в CarSpot'),
                  const Divider(height: 1),
                  _perkTile(Icons.directions_car, 'Больше машин в гараже',
                      'До 25 машин вместо 10 на обычном аккаунте'),
                  const Divider(height: 1),
                  _perkTile(Icons.push_pin, 'Закреплённые фото',
                      'Закрепляй свои лучшие фото сверху галереи сходки или машины'),
                  const Divider(height: 1),
                  _perkTile(Icons.workspace_premium, 'Premium-значок',
                      'Золотая корона рядом с именем в профиле и на сходках'),
                  const Divider(height: 1),
                  _perkTile(Icons.emoji_events, 'Эксклюзивное достижение',
                      'Отдельное достижение «Premium» в списке наград профиля'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
