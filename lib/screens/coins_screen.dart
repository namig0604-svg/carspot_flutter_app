import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/coin_billing_service.dart';
import '../theme/app_colors.dart';
import '../utils/sound_player.dart';

/// Экран CarSpot Coins — внутренняя валюта: баланс, покупка пакетов монет
/// через Google Play Billing и история операций (покупки и списания на
/// бусты сходок/автосервисов).
class CoinsScreen extends StatefulWidget {
  const CoinsScreen({Key? key}) : super(key: key);

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  int? _balance;
  bool _isLoadingBalance = false;
  List<dynamic> _transactions = [];
  bool _isLoadingTransactions = false;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadTransactions();
    _initBilling();
  }

  @override
  void dispose() {
    CoinBillingService.instance.onPurchaseVerified = null;
    CoinBillingService.instance.onPurchaseError = null;
    super.dispose();
  }

  Future<void> _initBilling() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    CoinBillingService.instance.onPurchaseVerified = (newBalance) async {
      if (!mounted) return;
      setState(() {
        _balance = newBalance;
        _isBuying = false;
      });
      SoundPlayer.play(context, AppSound.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('coins.purchase_confirmed_snackbar'))),
      );
      _loadTransactions();
    };
    CoinBillingService.instance.onPurchaseError = (message) {
      if (!mounted) return;
      setState(() => _isBuying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tArgs('coins.generic_error', {'error': message}))),
      );
    };
    await CoinBillingService.instance.initialize(() => authProvider.accessToken ?? '');
    if (mounted) setState(() {});
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/coins/balance', token: authProvider.accessToken);
      if (mounted && response is Map<String, dynamic>) {
        setState(() => _balance = (response['balance'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {
      // не критично — просто не покажем баланс, экран останется рабочим
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/coins/transactions', token: authProvider.accessToken);
      if (mounted) setState(() => _transactions = response is List ? response : []);
    } catch (_) {
      // история необязательна для остального экрана
    } finally {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _buy(ProductDetails product) async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    try {
      await CoinBillingService.instance.buy(product);
      // Дальше подхватит покупку purchaseStream -> onPurchaseVerified/onPurchaseError.
    } catch (e) {
      if (mounted) {
        setState(() => _isBuying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('coins.generic_error', {'error': '$e'}))),
        );
      }
    }
  }

  String _txLabel(BuildContext context, Map<String, dynamic> tx) {
    switch (tx['type']) {
      case 'purchase':
        return context.t('coins.tx_purchase');
      case 'boost_event':
        return context.t('coins.tx_boost_event');
      case 'boost_business':
        return context.t('coins.tx_boost_business');
      default:
        return tx['type']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final products = CoinBillingService.instance.products;
    final billingAvailable = CoinBillingService.instance.isAvailable && products.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarSpot Coins', overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.amberDark,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          await _loadBalance();
          await _loadTransactions();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.amber, AppColors.amberDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('coins.balance_label'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        _isLoadingBalance && _balance == null
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                '${_balance ?? 0}',
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(context.t('coins.what_for_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 15)),
            const SizedBox(height: 8),
            Text(
              context.t('coins.what_for_body'),
              style: TextStyle(color: cardText.withOpacity(0.75), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Text(context.t('coins.buy_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 15)),
            const SizedBox(height: 10),
            if (!billingAvailable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.steel),
                ),
                child: Text(
                  context.t('coins.buy_unavailable'),
                  style: TextStyle(color: cardText.withOpacity(0.7), fontSize: 13),
                ),
              )
            else
              for (final product in products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBuying ? null : () => _buy(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      child: _isBuying
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text(product.title, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                Text(product.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            Text(context.t('coins.history_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText, fontSize: 15)),
            const SizedBox(height: 8),
            if (_isLoadingTransactions && _transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.t('coins.history_empty'),
                  style: TextStyle(color: cardText.withOpacity(0.6), fontSize: 13),
                ),
              )
            else
              for (final raw in _transactions)
                if (raw is Map<String, dynamic>)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.steel),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (raw['amount'] as num?) != null && (raw['amount'] as num) > 0
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: ((raw['amount'] as num?) ?? 0) > 0 ? Colors.green : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_txLabel(context, raw), style: TextStyle(color: cardText, fontSize: 13)),
                        ),
                        Text(
                          '${((raw['amount'] as num?) ?? 0) > 0 ? '+' : ''}${raw['amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ((raw['amount'] as num?) ?? 0) > 0 ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
