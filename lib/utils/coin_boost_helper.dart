import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/auth_provider.dart';
import '../screens/coins_screen.dart';
import '../screens/premium_screen.dart';
import '../services/api_service.dart';
import 'sound_player.dart';

/// Общий диалог "буст за Premium или за монеты CarSpot Coins" — используется
/// и на экране сходки, и на экране автосервиса, отличается только endpoint
/// и ключи переводов заголовка/описания.
///
/// [costField] — какое поле стоимости брать из ответа GET /api/coins/balance:
/// "boost_cost_event" или "boost_cost_business".
Future<void> showBoostChoiceAndExecute(
  BuildContext context, {
  required AuthProvider authProvider,
  required String coinsBoostEndpoint,
  required String costField,
  required String premiumOnlyTitleKey,
  required String premiumOnlyBodyKey,
  required String boostedSuccessKey,
  required void Function(dynamic response) onBoosted,
}) async {
  Map<String, dynamic>? wallet;
  try {
    final resp = await ApiService.get('/api/coins/balance', token: authProvider.accessToken);
    if (resp is Map<String, dynamic>) wallet = resp;
  } catch (_) {
    // Баланс не критичен для диалога — просто не покажем строку с монетами,
    // кнопка "Premium" всё равно останется доступна.
  }

  final balance = (wallet?['balance'] as num?)?.toInt() ?? 0;
  final cost = (wallet?[costField] as num?)?.toInt() ?? 0;
  final canAffordCoins = wallet != null && cost > 0 && balance >= cost;

  if (!context.mounted) return;

  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.t(premiumOnlyTitleKey)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dialogContext.t(premiumOnlyBodyKey)),
          if (wallet != null) ...[
            const SizedBox(height: 12),
            Text(
              dialogContext.tArgs('boost.coins_balance_line', {'balance': '$balance', 'cost': '$cost'}),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: canAffordCoins ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, 'cancel'),
          child: Text(dialogContext.t('common.cancel')),
        ),
        if (wallet != null)
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, canAffordCoins ? 'coins' : 'topup'),
            child: Text(
              canAffordCoins
                  ? dialogContext.tArgs('boost.pay_with_coins_button', {'cost': '$cost'})
                  : dialogContext.t('boost.top_up_button'),
            ),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, 'premium'),
          child: Text(dialogContext.t('event_details.learn_more')),
        ),
      ],
    ),
  );

  if (choice == 'premium') {
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
    }
    return;
  }
  if (choice == 'topup') {
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));
    }
    return;
  }
  if (choice != 'coins') return;

  try {
    final response = await ApiService.post(coinsBoostEndpoint, {}, token: authProvider.accessToken);
    onBoosted(response);
    if (context.mounted) {
      SoundPlayer.play(context, AppSound.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t(boostedSuccessKey))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
