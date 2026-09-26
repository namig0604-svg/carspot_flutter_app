import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/billing_service.dart';
import 'people_list_screen.dart';
import 'subscription_management_screen.dart';
import '../theme/app_colors.dart';
import '../utils/sound_player.dart';
import '../l10n/l10n_extensions.dart';

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

  bool _isBuyingGooglePlay = false;

  @override
  void initState() {
    super.initState();
    _loadReferral();
    _loadPlans();
    _initGooglePlayBilling();
  }

  @override
  void dispose() {
    _paymentPollTimer?.cancel();
    BillingService.instance.onPurchaseVerified = null;
    BillingService.instance.onPurchaseError = null;
    super.dispose();
  }

  /// Google Play Billing — если товары ещё не заведены в Play Console (или
  /// мы не на Android), просто ничего не покажется в интерфейсе, оплата
  /// через Trybit ниже продолжит работать как раньше.
  Future<void> _initGooglePlayBilling() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    BillingService.instance.onPurchaseVerified = (productId) async {
      await authProvider.getCurrentUser();
      if (!mounted) return;
      setState(() => _isBuyingGooglePlay = false);
      SoundPlayer.play(context, AppSound.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('premium.payment_confirmed_snackbar'))),
      );
    };
    BillingService.instance.onPurchaseError = (message) {
      if (!mounted) return;
      setState(() => _isBuyingGooglePlay = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tArgs('premium.generic_error', {'error': message}))),
      );
    };
    await BillingService.instance.initialize(() => authProvider.accessToken ?? '');
    if (mounted) setState(() {});
  }

  Future<void> _buyGooglePlay(ProductDetails product) async {
    if (_isBuyingGooglePlay) return;
    setState(() => _isBuyingGooglePlay = true);
    try {
      await BillingService.instance.buy(product);
      // Дальше подхватит покупку purchaseStream -> onPurchaseVerified/onPurchaseError
      // (см. _initGooglePlayBilling) — результат придёт асинхронно, не сразу.
    } catch (e) {
      if (mounted) {
        setState(() => _isBuyingGooglePlay = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('premium.generic_error', {'error': '$e'}))),
        );
      }
    }
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
          SnackBar(content: Text(context.t('premium.trial_activated_snackbar'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('premium.trial_activate_failed', {'error': '$e'}))),
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
        throw Exception(context.t('premium.checkout_no_invoice_error'));
      }

      final opened = await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) throw Exception(context.t('premium.checkout_open_failed_error'));

      setState(() => _activePaymentId = paymentId);
      _startPolling(paymentId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('premium.generic_error', {'error': '$e'}))));
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
            SnackBar(content: Text(context.t('premium.payment_confirmed_snackbar'))),
          );
        }
      } else if (status == 'canceled' || status == 'failed') {
        _paymentPollTimer?.cancel();
        if (mounted) {
          setState(() => _activePaymentId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('premium.payment_failed_snackbar'))),
          );
        }
      } else if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('premium.payment_pending_snackbar'))),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('premium.generic_error', {'error': '$e'}))));
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
        SnackBar(content: Text(context.t('premium.likers_locked_snackbar'))),
      );
      return;
    }
    try {
      final response = await ApiService.get('/api/users/me/likers', token: authProvider.accessToken);
      final people = response is List ? response : [];
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PeopleListScreen(title: context.t('premium.likers_screen_title'), people: people)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('premium.generic_error', {'error': '$e'}))));
    }
  }

  Future<void> _openProfileViews() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.user?['is_premium'] == true;
    if (!isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('premium.views_locked_snackbar'))),
      );
      return;
    }
    try {
      final response = await ApiService.get('/api/users/me/profile-views', token: authProvider.accessToken);
      final rows = response is List ? response : [];
      final people = rows.map<Map<String, dynamic>>((row) {
        final user = Map<String, dynamic>.from(row['user'] as Map);
        user['subtitle_override'] = context.tArgs('premium.viewed_on', {'date': _formatDate(row['viewed_at'].toString())});
        return user;
      }).toList();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PeopleListScreen(title: context.t('premium.viewers_screen_title'), people: people)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('premium.generic_error', {'error': '$e'}))));
    }
  }

  /// Кнопки оплаты через Google Play Billing. Пока в Play Console не
  /// заведены товары carspot_premium_month/carspot_premium_year (см.
  /// lib/services/billing_service.dart), список products пуст — секция
  /// просто не рисует ничего, и остаётся привычная оплата через Trybit
  /// ниже. Ничего не ломается до тех пор, пока приложение не попадёт в
  /// Google Play.
  Widget _buildGooglePlaySection(Color cardSurface, Color cardText) {
    final products = BillingService.instance.products;
    if (!BillingService.instance.isAvailable || products.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(Colors.green.withOpacity(0.10), cardSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shop, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text('Google Play', style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            for (final product in products)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBuyingGooglePlay ? null : () => _buyGooglePlay(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isBuyingGooglePlay
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(product.title, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Text(product.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
            TextButton(
              onPressed: () => BillingService.instance.restorePurchases(),
              child: const Text('Восстановить покупки'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansByTier(Color cardText) {
    final byTier = <String, List<Map<String, dynamic>>>{};
    for (final p in _plans) {
      final plan = p as Map<String, dynamic>;
      final tier = (plan['tier'] as String?) ?? 'pro';
      byTier.putIfAbsent(tier, () => []).add(plan);
    }
    // Max сверху — самый жирный план, Pro — золотая середина.
    final order = ['max', 'pro', 'basic'];
    final tierTitles = {'max': 'CarSpot Max', 'pro': 'CarSpot Pro', 'basic': 'CarSpot Basic'};
    final tierBadgeColors = {'max': Colors.purple.shade700, 'pro': Colors.amber.shade700};
    final tierBadgeKeys = {'max': 'premium.top_tier_badge', 'pro': 'premium.best_value_badge'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tier in order)
          if (byTier.containsKey(tier)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 4),
              child: Row(
                children: [
                  Text(
                    tierTitles[tier] ?? tier,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 14),
                  ),
                  if (tierBadgeKeys.containsKey(tier)) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierBadgeColors[tier],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.t(tierBadgeKeys[tier]!),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (final plan in byTier[tier]!)
              Padding(
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
                        Flexible(
                          child: Text(plan['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${plan['amount_usd']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _tierCompareRow(
    String label, {
    required bool basic,
    required bool pro,
    required bool max,
    String? basicNote,
    String? proNote,
    String? maxNote,
  }) {
    Widget cell(bool has, String? note) {
      return Expanded(
        child: Column(
          children: [
            Icon(has ? Icons.check_circle : Icons.remove_circle_outline,
                color: has ? Colors.green : Colors.grey, size: 18),
            if (note != null)
              Text(note, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13))),
          cell(basic, basicNote),
          cell(pro, proNote),
          cell(max, maxNote),
        ],
      ),
    );
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
    final premiumTier = user?['premium_tier'] as String?;
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
        title: const Text('CarSpot Premium', overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: Colors.amber.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: context.t('premium.subscription_management_tooltip'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionManagementScreen()),
            ),
          ),
        ],
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
                      Expanded(
                        child: Text(
                          isPremium
                              ? (premiumTier == 'basic'
                                  ? context.t('premium.status_active_basic')
                                  : premiumTier == 'max'
                                      ? context.t('premium.status_active_max')
                                      : context.t('premium.status_active_pro'))
                              : context.t('premium.status_inactive'),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isPremium && premiumUntil != null)
                    Text(
                      context.tArgs('premium.active_until', {'date': _formatDate(premiumUntil)}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    )
                  else
                    Text(
                      context.t('premium.hero_subtitle_inactive'),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
                  label: Text(context.t('premium.trial_button')),
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
                child: Text(
                  context.t('premium.trial_used_notice'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 20),

            Text(isPremium ? context.t('premium.renew_title') : context.t('premium.buy_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            // Google Play запрещает предлагать в Android-приложении оплату цифровых
            // товаров в обход Google Play Billing — поэтому упоминание Trybit и сами
            // кнопки оплаты через Trybit показываем только в веб-версии (kIsWeb).
            // На Android/iOS остаётся только секция Google Play ниже.
            if (kIsWeb)
              Text(
                context.t('premium.payment_method_note'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 10),

            _buildGooglePlaySection(cardSurface, cardText),

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
                          child: Text(context.t('premium.awaiting_payment'), style: TextStyle(color: cardText)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _checkPaymentNow(_activePaymentId!),
                            child: Text(context.t('premium.check_now_button')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelPolling,
                          child: Text(context.t('common.cancel')),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (kIsWeb)
              _buildPlansByTier(cardText)
            else if (!BillingService.instance.isAvailable || BillingService.instance.products.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.t('premium.google_play_setup_notice'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

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
                      Text(context.t('premium.referral_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText)),
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
                          tooltip: context.t('premium.copy_code_tooltip'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${_referral!['code']}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.t('premium.code_copied_snackbar'))),
                            );
                          },
                        ),
                      ],
                    )
                  else if (_isLoadingReferral)
                    Row(
                      children: [
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 8),
                        Text(context.t('premium.loading_code'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    context.tArgs('premium.referral_stats', {'count': '$referralsCount', 'months': '$monthsEarned'}),
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
                        ? context.tArgs('premium.referral_invite_prompt', {'count': '$perMonth'})
                        : context.tArgs('premium.referral_remaining', {'count': '$untilNext'}),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(context.t('premium.popularity_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    title: Text(context.tArgs('premium.likes_count_label', {'count': '${user?['likes_count'] ?? 0}'})),
                    subtitle: Text(isPremium ? context.t('premium.see_who_liked') : context.t('premium.subscribe_to_see_who')),
                    trailing: Icon(isPremium ? Icons.chevron_right : Icons.lock_outline, color: Colors.grey),
                    onTap: _openLikers,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.blue,
                      child: Icon(Icons.visibility, color: Colors.white, size: 18),
                    ),
                    title: Text(context.tArgs('premium.views_count_label', {'count': '${user?['profile_views_count'] ?? 0}'})),
                    subtitle: Text(isPremium ? context.t('premium.see_who_viewed') : context.t('premium.subscribe_to_see_who')),
                    trailing: Icon(isPremium ? Icons.chevron_right : Icons.lock_outline, color: Colors.grey),
                    onTap: _openProfileViews,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(context.t('premium.compare_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(flex: 3, child: SizedBox()),
                        Expanded(child: Text('Basic', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: cardText))),
                        Expanded(child: Text('Pro', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: cardText))),
                        Expanded(child: Text('Max', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: cardText))),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _tierCompareRow(context.t('premium.compare_garage'), basic: true, pro: true, max: true, basicNote: '15', proNote: '30', maxNote: '60'),
                  _tierCompareRow(context.t('premium.compare_insights'), basic: true, pro: true, max: true, basicNote: '15', proNote: '75', maxNote: '300'),
                  _tierCompareRow(context.t('premium.compare_business'), basic: true, pro: true, max: true, basicNote: '1', proNote: '8', maxNote: '25'),
                  _tierCompareRow(context.t('premium.compare_free_boost'), basic: false, pro: true, max: true, proNote: '24h', maxNote: '48h'),
                  _tierCompareRow(context.t('premium.compare_pinned_photos'), basic: false, pro: true, max: true),
                  _tierCompareRow(context.t('premium.compare_bonus_xp'), basic: false, pro: false, max: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(context.t('premium.perks_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _perkTile(Icons.favorite, context.t('premium.perk_likers_title'),
                      context.t('premium.perk_likers_subtitle')),
                  const Divider(height: 1),
                  _perkTile(Icons.rocket_launch, context.t('premium.perk_boost_title'),
                      context.t('premium.perk_boost_subtitle')),
                  const Divider(height: 1),
                  _perkTile(Icons.storefront, context.t('premium.perk_services_title'),
                      context.t('premium.perk_services_subtitle')),
                  const Divider(height: 1),
                  _perkTile(Icons.directions_car, context.t('premium.perk_garage_title'),
                      context.t('premium.perk_garage_subtitle')),
                  const Divider(height: 1),
                  _perkTile(Icons.push_pin, context.t('premium.perk_pinned_photos_title'),
                      context.t('premium.perk_pinned_photos_subtitle')),
                  const Divider(height: 1),
                  _perkTile(Icons.workspace_premium, context.t('premium.perk_badge_title'),
                      context.t('premium.perk_badge_subtitle')),
                  const Divider(height: 1),
                  _perkTile(Icons.emoji_events, context.t('premium.perk_achievement_title'),
                      context.t('premium.perk_achievement_subtitle')),
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
