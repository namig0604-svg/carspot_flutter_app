import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_service.dart';

/// Покупка пакетов CarSpot Coins (внутренней валюты) через Google Play
/// Billing — те же принципы, что и в billing_service.dart (оплата Premium),
/// но товары здесь consumable (можно покупать многократно), а не подписки.
///
/// id товаров здесь должны СОВПАДАТЬ 1-в-1 с тем, что заведено в Google Play
/// Console (Монетизация -> Продукты -> Товары в приложении, тип "Расходуемый")
/// и с COIN_PACKAGES в app/api/coins.py на бэкенде. Пока эти товары не
/// созданы в Play Console, queryProductDetails() их не найдёт — экран монет
/// просто не покажет кнопки покупки, ничего не сломается.
class CoinBillingService {
  CoinBillingService._();
  static final CoinBillingService instance = CoinBillingService._();

  static const Set<String> productIds = {
    'carspot_coins_100',
    'carspot_coins_550',
    'carspot_coins_1200',
    'carspot_coins_2600',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  String Function()? _accessTokenGetter;

  bool _available = false;
  List<ProductDetails> _products = [];

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;

  /// Вызывается, когда покупка подтверждена на бэкенде и монеты зачислены —
  /// параметр int это новый баланс после зачисления.
  void Function(int newBalance)? onPurchaseVerified;
  void Function(String message)? onPurchaseError;

  bool _initialized = false;

  Future<void> initialize(String Function() accessTokenGetter) async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    _accessTokenGetter = accessTokenGetter;

    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[CoinBilling] Google Play Billing недоступен: $e');
      _available = false;
    }
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => debugPrint('[CoinBilling] Ошибка потока покупок: $e'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(productIds);
      _products = response.productDetails
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      if (response.notFoundIDs.isNotEmpty) {
        // Ожидаемо, пока товары не заведены в Play Console — не ошибка.
        debugPrint('[CoinBilling] Товары ещё не заведены в Play Console: ${response.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('[CoinBilling] Ошибка загрузки пакетов монет: $e');
    }
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    // autoConsume: true — Play Billing на устройстве сразу разрешает купить
    // товар повторно; окончательное зачисление монет всё равно решает
    // бэкенд через серверную проверку ниже (verify + consume через Play
    // Developer API), клиентскому состоянию покупки мы не доверяем.
    await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchase.error?.message ?? 'Ошибка покупки Google Play');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        final token = purchase.verificationData.serverVerificationData;
        final accessToken = _accessTokenGetter?.call();
        try {
          if (accessToken == null) {
            throw Exception('Нет входа в аккаунт');
          }
          final result = await ApiService.post(
            '/api/coins/google-play/verify',
            {
              'product_id': purchase.productID,
              'purchase_token': token,
            },
            token: accessToken,
          );
          final newBalance = (result is Map && result['balance'] != null) ? (result['balance'] as num).toInt() : 0;
          onPurchaseVerified?.call(newBalance);
        } catch (e) {
          onPurchaseError?.call('Не удалось подтвердить покупку на сервере: $e');
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
