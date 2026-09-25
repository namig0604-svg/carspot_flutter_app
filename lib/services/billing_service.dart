import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_service.dart';

/// Оплата CarSpot Premium через Google Play Billing.
///
/// Работает только на Android (на вебе Google Play Billing в принципе не
/// существует, поэтому initialize() там сразу выходит без действий) — на
/// остальных платформах на экране Premium остаётся прежняя оплата через
/// Trybit как запасной вариант.
///
/// ВАЖНО: id товаров здесь должны СОВПАДАТЬ 1-в-1 с тем, что заведено в
/// Google Play Console (Монетизация -> Продукты -> Подписки) и с тем, что
/// бэкенд ожидает в /api/payments/google-play/verify (см. PREMIUM_PLANS в
/// app/api/payments.py на бэкенде). Пока эти товары не созданы в Play
/// Console, queryProductDetails() просто не найдёт их — isAvailable
/// останется true, но products будет пустым, и кнопки покупки в интерфейсе
/// сами не появятся (см. premium_screen.dart), ничего не сломается.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  static const String monthlyProductId = 'carspot_premium_month';
  static const String yearlyProductId = 'carspot_premium_year';
  static const Set<String> _productIds = {monthlyProductId, yearlyProductId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  String Function()? _accessTokenGetter;

  bool _available = false;
  List<ProductDetails> _products = [];

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;

  /// Вызывается, когда покупка успешно подтверждена на бэкенде — экран
  /// должен обновить статус Premium у пользователя.
  void Function(String productId)? onPurchaseVerified;
  void Function(String message)? onPurchaseError;

  bool _initialized = false;

  /// [accessTokenGetter] — функция, возвращающая актуальный токен входа на
  /// момент покупки (а не захваченный один раз при инициализации), т.к.
  /// покупка может завершиться значительно позже вызова initialize().
  Future<void> initialize(String Function() accessTokenGetter) async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    _accessTokenGetter = accessTokenGetter;

    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[Billing] Google Play Billing недоступен: $e');
      _available = false;
    }
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => debugPrint('[Billing] Ошибка потока покупок: $e'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);
      _products = response.productDetails;
      if (response.notFoundIDs.isNotEmpty) {
        // Ожидаемо, пока товары не созданы в Google Play Console — не ошибка.
        debugPrint('[Billing] Товары ещё не заведены в Play Console: ${response.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('[Billing] Ошибка загрузки товаров Google Play: $e');
    }
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
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
          await ApiService.post(
            '/api/payments/google-play/verify',
            {
              'product_id': purchase.productID,
              'purchase_token': token,
            },
            token: accessToken,
          );
          onPurchaseVerified?.call(purchase.productID);
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
